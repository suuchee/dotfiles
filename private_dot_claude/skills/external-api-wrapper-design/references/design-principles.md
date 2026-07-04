# 設計原則（5 原則）

外部 HTTP API ラッパーを書くときに守る原則。なぜこの原則が要るかと、違反した時の代表的な失敗パターンを併記する。

## 1. DI 境界を最初から作る

副作用を持つ依存（`fetch` / 環境変数 / stdout / 時刻 / 乱数）は、関数の引数として外から注入できる形にする。グローバル参照を直接掴まない。

### 良い例

```ts
export interface ClientOptions {
  apiKey: string;                  // 環境変数を直接読まない
  baseUrl?: string;                // デフォルト持ちつつ差し替え可能
  fetch?: typeof globalThis.fetch; // テスト時に mock を注入
}

export function createClient(opts: ClientOptions) {
  const apiKey = opts.apiKey;
  const baseUrl = opts.baseUrl ?? "https://api.example.com/v1";
  const httpFetch = opts.fetch ?? globalThis.fetch;
  // ...
}
```

### 悪い例

```ts
async function listCustomers(name: string) {
  const apiKey = process.env.API_KEY!;       // 環境変数を直接読む
  const res = await fetch(...);              // global fetch を直接使う
  return res.json();
}
```

### なぜこの原則が要るか

- テストで実 API を叩かずに済む（mock fetch を注入できる）
- 環境変数の読み出しを集中管理できる（複数箇所での `process.env` 直読みを防ぐ）
- `process.env` 直読みが各所に散らばると、後で「テスト用の値を入れたい」場面で詰む
- これは TDD の儀式ではなく「テストを書ける状態を維持することが、業務ロジックを副作用から切り離す原動力になる」という構造原則

詳細: `~/.claude/rules/testing.md` の「テスタビリティ ⇄ レイヤー分離」セクション。

## 2. 型の「出所」と「公開型」を分離する

API ラッパーが内部で扱う型（出所は **SDK が export している型 / OpenAPI 生成型 / 手書き型** のいずれか）と、利用側に見せる公開型は分けて考える。出所の型をそのまま外部に export しない。

| 型の出所 | 例 | 扱い |
| --- | --- | --- |
| SDK 型 | `Stripe.Customer`, `OpenAI.Chat.Completion` | 公開してよいケースが多い（SDK 型は SDK が責任を持つ）。ただし社内固有 field を足したい時は extend |
| OpenAPI 生成型 | `paths["/customers"]["get"]...` | そのまま公開しない。narrow した公開型を別途定義 |
| 手書き型 | ドキュメントから自分で起こした `RawArticle` | そのまま公開しない。`Article` 等の narrow した公開型を別途定義 |

下記サンプルは OpenAPI 生成型のケース：

### 良い例

```ts
// client/types.ts
import type { paths } from "./generated/schema.js";

type RawCustomer = NonNullable<
  paths["/customers"]["get"]["responses"][200]["content"]["application/json"]
>["customers"][number];

// 公開型: id と name の存在を呼び出し側に保証する
export interface Customer {
  id: number;
  name: string;
  raw: RawCustomer;  // 生データへのエスケープハッチ
}
```

### 悪い例

```ts
// 生成型をそのまま export
export type Customer = paths["/customers"]["get"]["responses"][200]
  ["content"]["application/json"]["customers"][number];
// → id も name も optional のまま呼び出し側に染み出す
```

### なぜこの原則が要るか

- OpenAPI / SDK の型宣言と実 API の挙動はしばしばズレる（後述 common-pitfalls 参照）
- 出所の型を直接公開すると、API spec / SDK バージョン更新の度に呼び出し側が壊れる
- 「id は必ず来る」「name は必ず来る」のような実運用での暗黙の保証を、公開型で明示できる
- `raw` フィールドを残すことで、必要なら生データにアクセスできるエスケープハッチを提供

**SDK 型の場合の例外**: SDK が自分のメジャーバージョン管理で互換性を保っているなら、SDK 型をそのまま再 export してもよい（社内ラッパーが SDK の semver に乗る形）。ただしレスポンスを「実運用では必須」として narrow したい場合は、手書きの公開型を別途定義する。

## 3. silent failure を作らない

データを欠落・除外・スキップしたら、その事実を呼び出し側に観測可能な形で伝える。「親切な処理」が情報損失になる。

### 良い例

```ts
export interface ListCustomersResult {
  customers: Customer[];
  warnings: ClientWarning[];   // 除外・欠落の事実を運ぶ
}

const customers: Customer[] = [];
let excludedCount = 0;
for (const raw of rawCustomers) {
  if (typeof raw.id !== "number" || typeof raw.name !== "string") {
    excludedCount += 1;
    continue;
  }
  customers.push({ id: raw.id, name: raw.name, raw });
}

const warnings = excludedCount > 0
  ? [{ code: "incomplete_record_excluded", message: `${excludedCount} 件除外`, count: excludedCount }]
  : [];
```

### 悪い例

```ts
// 除外したことが呼び出し側に伝わらない
const customers = rawCustomers.filter(
  (c) => typeof c.id === "number" && typeof c.name === "string"
);
return { customers };
```

### なぜこの原則が要るか

- 呼び出し側が「totalCount 100 だが配列は 95 件」のような不整合に気付ける
- ログに警告を出せる（運用観測性が上がる）
- API 側の異常を早期発見できる（普段 0 件だった excludedCount が突然増えたら異常検知）
- silent failure は「動いてるように見えるが情報が消える」最も保守困難な負債

## 4. HTTP メソッドごとに別 contract を持つ

GET / POST / PUT / PATCH / DELETE のレスポンスは意味論が違う。GET の前提を他メソッドに一般化しない。

### 例: GET と PUT で「省略」の意味が違う

```
GET /customers (リスト取得)
  - response.customers が省略 → 「0 件ヒット」相当として安全に扱える

PUT /customers/{id} (一括更新)
  - response.customers が省略 → 「変更なし」と「全削除」を区別できない
  - GET と同じ「省略 = 空配列」ロジックを使うと致命的
```

### なぜこの原則が要るか

- 各メソッドのレスポンス契約をテストで明示すると、後から別メソッドを追加するときの取り違えが減る
- 「customer 操作の挙動」と「customer リソースの API 契約」を混ぜない
- 同じ resource でもメソッド別に test ファイルを分けるか、describe で明確に区切る

## 5. 過剰抽象を避ける（早すぎる抽象化禁止）

テスタビリティを口実にした不要な間接層を作らない。

### 作らないもの

- 実装が 1 つしかない `IFoo` のようなインターフェース（「将来 swap するかも」では作らない）
- 中身が「他のメソッドへの単純委譲」しかない service 関数
- 単一リソース・単一メソッドのために作る Use Case 層

### 作る判断基準

- DI 境界は **既に複数の入力 / mock が必要なポイント** にだけ置く（`fetch`, `env`, `stdout` のような副作用境界）
- service 層は **多段オーケストレーション**（検索 → 重複確認 → dry-run → 確定）が出てきた時点で立ち上げる
- 抽象は「2 度目に同じパターンを書くとき」に作る（YAGNI）

### なぜこの原則が要るか

- 抽象 1 個のコストは「読む人の認知負荷」+「実装が増えた時の合致性維持」+「変更時の波及範囲」
- 「将来のため」の抽象は当たらないことが多く、当たらない抽象は負債になる
- 後から抽象を追加するのは、誤った抽象を解体するより遥かに楽

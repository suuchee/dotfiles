# パターン: 公式 SDK も OpenAPI も無い

公式 SDK が無く、OpenAPI/Swagger 仕様書も無い API（断片的なドキュメントだけ、レガシー API、社内の SSE エンドポイント、ベンダーが独自フォーマットでドキュメントを公開しているケース）を扱う場合の方針。

## 基本方針

**手書きで型を作り、必要なエンドポイントだけ漸進的に実装する。** 全エンドポイントを最初に網羅しようとしない。実際に呼び出すものだけをテストとセットで足していく。

## ステップ

### 1. ドキュメントから「使うエンドポイント」を選ぶ

API ベンダーの HTML ドキュメント / Markdown / PDF / Postman collection 等から、**今必要なエンドポイントだけ**ピックアップ。残りは後で追加する前提で。

### 2. 型を手書きする

OpenAPI が無いので生成は不可能。手書きで型を起こす：

```ts
// types.ts
export interface RawArticle {
  id: number;
  title: string;
  body?: string;
  author?: { id: number; name: string };
  // ドキュメントを見ながら最低限の field を書く
}

export interface Article {
  id: number;
  title: string;
  raw: RawArticle;
}

export interface ListArticlesParams {
  query?: string;
  page?: number;
  limit?: number;
}
```

ポイント：
- **ドキュメントに書いてあっても optional 扱いにする**（実 API で来ないことがあるため）
- 公開型で「必ず存在することを保証したい field」だけ required にする
- `raw` フィールドで生データへのエスケープハッチを残す（後でドキュメント外の field を発見した時のため）

### 3. fetch wrapper を最小構成で書く

```ts
// client.ts
export interface MyApiClientOptions {
  apiKey: string;
  baseUrl?: string;
  fetch?: typeof globalThis.fetch;
}

export function createClient(opts: MyApiClientOptions) {
  const http = {
    apiKey: opts.apiKey,
    baseUrl: opts.baseUrl ?? "https://api.example.com",
    fetch: opts.fetch ?? globalThis.fetch,
  };
  return {
    articles: {
      list: (params?) => listArticles(http, params),
    },
  };
}
```

`openapi-no-sdk.md` パターンと構造は同じ。違いは「型が生成物ではなく手書き」というだけ。

### 4. smoke test 駆動で型を育てる

ドキュメントが断片的なので、**smoke test で実 API のレスポンスを観察し、型を補完する**フローになる：

```bash
# 1. 仮の型で client を実装
# 2. smoke test を 1 リクエスト走らせて生レスポンスを取得
node -e "console.log(JSON.stringify(await client.articles.list(), null, 2))"
# 3. 観察結果から型を補正
# 4. テストを書きながら narrow ロジックを実装
```

`research/smoke-test_YYYY-MM-DD.md` に「観察したレスポンスの実体」を記録する。次のリソース実装時の予測材料になる。

### 5. contract test は同じ網羅性で

型が手書きでも、契約は同じく test で固定する。`../contract-test-checklist.md` の 5 セクション（Request / Response / Error / 副作用 / 入力境界）は SDK なし・OpenAPI なしでも適用される。

### 6. 漸進的に追加する

1 つのエンドポイントを実装 → contract test → smoke test → コミット、を 1 単位とする。「全エンドポイント実装してから merge」を目指さない（網羅は実 API で確認しないと意味が薄い）。

## ドキュメント情報の自前 OpenAPI 化（オプション）

リソースが 5〜10 個を超えてきたら、**自前で OpenAPI YAML を起こす** 選択肢もある：

メリット：
- 型生成 (`openapi-typescript`) に乗れる → `openapi-no-sdk.md` パターンに移行
- ベンダーへの仕様書フィードバックの叩き台になる
- 社内ドキュメントとして再利用できる

デメリット：
- 初期コストが大きい
- ベンダー側の仕様変更への追従が必要

「同じ API を社内で複数プロジェクトから使う」予定があるなら投資対効果が出る。1 プロジェクトでしか使わないなら手書き型のままでよい。

## 共通原則（refresh）

- DI 境界を最初から作る
- 手書き型でも、生型と公開型は概念上分ける（`Article` vs `RawArticle`）
- silent failure 禁止
- HTTP メソッドごとに別 contract
- 過剰抽象禁止

詳細は `../design-principles.md`。

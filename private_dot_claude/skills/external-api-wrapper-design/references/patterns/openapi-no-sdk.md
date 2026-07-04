# パターン: OpenAPI あり / 公式 SDK なし

公式 SDK が無く、OpenAPI/Swagger 仕様書が提供されている API（自社 Open API、Mazrica、Sansan、kintone の一部、社内 API 等）を扱う場合の方針。

このパターンが Phase 1 で実際に取った構成。Mazrica Sales API のラッパー (`@plainnovation/mazrica-client`) はこのパターンの典型例。

## 基本方針

`openapi-typescript` で型生成し、自前で **薄い fetch wrapper** を書く。生成型はそのまま外に出さず、公開型に narrow してから利用側に渡す。

## ステップ

### 1. OpenAPI 仕様の入手

- 公式が JSON / YAML 形式で提供しているか確認
- ダウンロード URL がない場合は Redocly 等の SPA からバンドル抽出するか、サポートに直接問い合わせる
- 入手したファイルは `docs/references/openapi.json` 等にコミットする（再現性確保）

### 2. 型生成

```bash
pnpm add -D openapi-typescript
pnpm exec openapi-typescript docs/references/openapi.json \
  -o packages/<api>-client/src/generated/schema.d.ts
```

生成物 (`schema.d.ts`) は **git 管理する**（CI で再生成しない）。バージョン更新時のみ再生成 → diff レビュー。

### 3. ディレクトリ構成

```text
packages/<api>-client/
├── package.json
├── tsconfig.json
├── src/
│   ├── index.ts           # 公開 re-exports
│   ├── client.ts          # createClient() factory
│   ├── http.ts            # fetch wrapper、ヘッダ・query 処理
│   ├── errors.ts          # ApiError / RateLimitError / NetworkError
│   ├── types.ts           # 公開型（generated 型から narrow）
│   ├── generated/
│   │   └── schema.d.ts    # openapi-typescript の生成物
│   └── <resource>.ts      # 各リソース (customers / actions / ...)
└── tests/
    └── <resource>.test.ts # contract test
```

### 4. 公開型の narrow

```ts
// types.ts
import type { paths } from "./generated/schema.js";

type RawCustomer = NonNullable<
  paths["/customers"]["get"]["responses"][200]["content"]["application/json"]
>["customers"][number];

// 公開型: id と name の存在を保証
export interface Customer {
  id: number;
  name: string;
  raw: RawCustomer;  // 生データへのエスケープハッチ
}
```

### 5. fetch wrapper

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
    baseUrl: opts.baseUrl ?? "https://api.example.com/v1",
    fetch: opts.fetch ?? globalThis.fetch,
  };
  return {
    customers: {
      list: (params?) => listCustomers(http, params),
      // ...
    },
  };
}
```

DI 境界 (`apiKey` / `baseUrl` / `fetch`) は引数注入。詳細は `../design-principles.md`。

### 6. リソース実装

各リソース ([resource].ts) で：
- 生成型を取得 → 公開型に narrow
- 欠落要素は除外、件数を `warnings` に乗せる
- HTTP メソッド別に contract を分離

### 7. エラー変換

`http.ts` で 4xx / 401・403 / 404 / 429 / 5xx / network / 非 JSON を独自エラー型に変換。詳細は `../contract-test-checklist.md`。

### 8. contract test

`../contract-test-checklist.md` の全 5 セクションを実装：
- Request 側（ヘッダ・URL・メソッド・クエリ）
- Response 側（200 ボディのマッピング、欠落要素の除外、warnings）
- Error 変換（4xx / 429 / network / 非 JSON）
- 副作用（API キーがログに出ない、x-request-id 伝搬）
- 入力境界（undefined / 空文字 / null）

`MyApiClientOptions.fetch` に mock を注入してテストする（実 API は叩かない）。

### 9. smoke test

`../smoke-test-template.md` の手順で実 API を叩く（PR 直前）。OpenAPI と実 API のズレ（optional 宣言の field が `null` で返る等）を発見・記録する。

## OpenAPI と実 API のズレへの備え

OpenAPI は「型の宣言」であって「実 API の保証」ではない。よくあるズレ：

| 観察される現象 | 原因 | 対策 |
| --- | --- | --- |
| `field?: T` 型なのに実 API は `null` を返す | OpenAPI に `nullable: true` の宣言が無い | 公開型で `\| null` を追加するか、null → undefined 正規化 |
| `required` でない field が実は常に来る | OpenAPI 仕様が古い・不正確 | 公開型で必須として narrow（`raw` で生データへ） |
| 仕様書にないエンドポイントが返ってくる | 仕様書が部分的 | 必要なら追加で型を手書き |

これらは smoke test で観察し、`research/smoke-test_YYYY-MM-DD.md` に記録する。

## 共通原則（refresh）

- DI 境界を最初から作る
- 公開型と生成型を分離する
- silent failure 禁止（warnings で除外件数を伝える）
- HTTP メソッドごとに別 contract
- 過剰抽象禁止

詳細は `../design-principles.md`。

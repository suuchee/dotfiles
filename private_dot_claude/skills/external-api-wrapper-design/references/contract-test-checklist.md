# Contract test チェックリスト

外部 HTTP API ラッパーの contract test に最低限含めるべき項目。これは「網羅率を上げるためのリスト」ではなく、「壊れると高くつく契約」を deterministic に固定するためのもの（`~/.claude/rules/testing.md` の Contract-first 原則準拠）。

「クエリパラメータの送信を test しただけで安心している」という典型的な漏れを防ぐためのチェックリスト。

## 使い方

新しい API 操作（例: `listCustomers`, `createAction`）を実装するたびに、以下のセクションを順に読み、必要な test を書く。

セクションは **Request 側 / Response 側 / Error 変換 / 副作用 / 入力境界** の 5 つに分けている。

## パターン別の適用範囲

| パターン | 適用範囲 |
| --- | --- |
| **OpenAPI あり / SDK なし** | 全 5 セクションを実装（自前 fetch wrapper の責任範囲） |
| **OpenAPI なし / SDK なし** | 全 5 セクションを実装（同上） |
| **SDK 利用 / 薄いラップ** | **「自前ラップ層の境界」のみテスト**: §3 の社内固有エラー変換、§4 の API キー注入経路 / ロガー、§5 の入力境界。HTTP リクエスト形やレスポンスマッピングは SDK の責任なので test しない（`patterns/sdk-wrap.md` 参照） |

## 1. Request 側

HTTP リクエストの発信が契約通りか。mock fetch を注入して、**第一引数 url と第二引数 init を捕捉**してチェックする。

| 項目 | 確認すること |
| --- | --- |
| 認証ヘッダ | API key / Bearer token / その他、正しいヘッダ名 + 値で送信されているか |
| Accept ヘッダ | `application/json` 等、サーバが HTML を返さないようにする指定 |
| Content-Type ヘッダ | POST/PATCH 時の body 形式の宣言 |
| URL の base | デフォルトで公式 base URL、`baseUrl` 引数で差し替え可能 |
| URL の path | `/customers/{id}` の `{id}` 展開が正しい、URL encoding が漏れない |
| URL の query | 各パラメータが API が期待する name で送られる（例: CLI の `--name` を内部で `searchWord` に変換） |
| HTTP メソッド | GET / POST / PATCH / PUT / DELETE が正しい |
| Body | POST/PATCH 時に正しい JSON が送られる、不要なフィールドが付かない |
| Cookie / セッション | 付与されないこと（PII 漏れ防止のネガティブテスト） |

### 重要なネガティブテスト

「**送られないこと**」を test するのは見落とされがち：

- `Cookie` ヘッダが付かない
- API キーがログ・URL クエリに混入しない
- 不要な default ヘッダ（`User-Agent` 改ざん等）が付かない

## 2. Response 側

成功時のレスポンスを公開型に変換する契約。

| 項目 | 確認すること |
| --- | --- |
| 200 ボディ → 公開型 | フィールド名のマッピング、ネスト解凍 |
| optional → required の narrow | OpenAPI で optional な field を「実運用では必須」として narrow するロジック |
| 欠落要素の除外戦略 | id / name 等の必須前提が欠けたら除外、ただし `warnings` で件数を伝える |
| 配列フィールドの省略 | レスポンスから配列 field が omit された時の扱い（**メソッド別に明示**） |
| 数値・日付の型 | 文字列で来た数値を Number に直すか、ISO 文字列のまま保持するか |
| pagination 情報 | `totalCount`, `page`, `nextCursor` 等を公開型に運ぶか |

### メソッド別の挙動を明示する

GET と PUT/PATCH/DELETE で「省略」「空配列」の意味は変わる。test 名・describe で **GET のみ前提** であることを明示しておかないと、後で他メソッド実装時に流用されて事故る。

```ts
// 良い例
describe("contract: GET レスポンスのマッピング", () => {
  it("GET レスポンスで customers が省略されたら空配列として扱う (0 件ヒット相当)", ...)
});

// 悪い例
describe("contract: response mapping", () => {
  it("customers フィールドが省略されたら空配列として扱う", ...)  // メソッドが曖昧
});
```

## 3. Error 変換

HTTP のエラーレスポンスを独自エラー型に変換する契約。

| status | 推奨マッピング |
| --- | --- |
| 4xx (default) | `ApiError` として throw、status / body / requestId を保持 |
| 401 / 403 | `permission_denied` 系のサブタイプ（retryable: false） |
| 404 | `not_found` 系のサブタイプ |
| 429 | `RateLimitError` (retryable: true、可能なら `Retry-After` を保持) |
| 5xx | `ApiError` (retryable は API の冪等性次第) |
| Network failure | `NetworkError` (retryable: true) |
| 200 + 非 JSON | `ApiError` に変換（WAF 介入や CDN エラーページが透過するのを防ぐ） |
| 4xx/5xx + 非 JSON | エラー型に保存するが body は文字列として保持 |

### 各エラーが保持すべき情報

- `status` / `statusText`
- `body`（パース後の object か、パース失敗なら生文字列）
- `requestId`（あれば、`x-request-id` ヘッダから抽出）
- `cause`（network error の場合の元 Error）

### test の書き方

```ts
it("4xx は ApiError になる", async () => {
  const { fetch } = createMockFetch({ status: 400, body: { message: "..." } });
  const client = createClient({ apiKey: "k", fetch });
  await expect(client.foo.bar()).rejects.toBeInstanceOf(ApiError);
});

it("ApiError は status / body / requestId を保持する", async () => {
  // status, body, x-request-id ヘッダがそのまま err に乗ることを確認
});
```

## 4. 副作用

ログ・標準出力・ファイル等への副作用。

| 項目 | 確認すること |
| --- | --- |
| API キーがログに出ない | `--verbose` モードでも `apiKey` の内容を出力しない |
| `x-request-id` 伝搬 | エラー時、レスポンスの `x-request-id` ヘッダがエラーオブジェクトに乗る |
| stdout への直接出力なし | client 層は stdout / stderr に直接書かない（CLI 層の責任） |
| 例外で原因情報が消えない | `cause` フィールドで元エラーへのトレースが保たれる |

## 5. 入力境界

呼び出し側から受け取る入力の扱い。

| 入力値 | 期待する挙動 |
| --- | --- |
| `undefined` | クエリ・body から omit |
| 空文字 `""` | クエリから omit（API 側仕様に依存しない安全側） |
| `null` | TypeScript 型で受けないが、any で混入した場合の挙動を決める |
| 0 / `false` | omit しない（valid な値として送る） |
| 巨大配列 / 巨大文字列 | サイズ制限のチェック（API 側 limit を超えたら `invalid_input` で reject） |
| 不正な enum 値 | TypeScript で型チェック、ランタイムでも防衛的に reject |

### よくある漏れ

- 空文字 `""` を `undefined` 扱いにしないと、`searchWord=` が送られて API 側仕様に依存することになる
- TypeScript 型の `string | undefined` だけだと、空文字は通過する
- 数値の `0` を `if (!value)` で除外すると valid な値が落ちる

## 6. factory レベルの validation

`createClient` を呼ぶ時点でのバリデーション。

```ts
it("apiKey 未指定だと createClient は throw する", () => {
  expect(() => createClient({ apiKey: "" })).toThrowError(/apiKey is required/);
});
```

これは「fail-fast」原則で、不正な状態の client が後段で爆発するより、生成時点で reject する方が運用観測性が上がる。

## 7. test のまとめ方

1 リソース 1 ファイル（例: `tests/customers.test.ts`）で、describe を以下の階層で組む：

```ts
describe("createClient.customers.list", () => {
  describe("contract: HTTP request shape", () => { /* §1 */ });
  describe("contract: GET レスポンスのマッピング", () => { /* §2 */ });
  describe("contract: error mapping", () => { /* §3 */ });
  describe("contract: factory validation", () => { /* §6 */ });
});
```

メソッドが増えたら（POST / PATCH 等）、describe を resource 単位ではなく **operation 単位**に分けて、各操作のメソッド別 contract を独立して固定する。

# パターン: 公式 SDK あり / 利用 or 薄いラップ

公式 SDK が提供されている API（Stripe / Notion / Slack / GitHub / OpenAI / Anthropic 等）を扱う場合の方針。

## 基本方針

**SDK を直接使えるなら、ラッパーは作らない。** 不要な抽象を増やすだけになる。
ラッパーが必要になるのは、以下のいずれかが当てはまる時だけ：

| 必要性 | 例 |
| --- | --- |
| 社内固有の認証層 | テナントごとに API キーを切り替える、社内 Vault から取得する |
| 社内固有のロギング・観測 | OpenTelemetry / DataDog 等への trace 送信、構造化ログ統一 |
| エラー型の統一 | 各 SDK のエラーを社内アプリの統一エラー型に変換 |
| リトライ戦略の統一 | 全 API 呼び出しで指数バックオフ + jitter を共通化 |
| SDK の隙間を埋める | SDK が未対応のエンドポイントを補完 |
| テスト境界の確保 | SDK が global state を持っていてテストしづらい時の wrapping |

これらに**当てはまらない**なら、SDK を直接 import して使えばよい。`new Stripe(apiKey)` や `new OpenAI({ apiKey })` をそのまま service / use case 層から呼ぶ。

## いつ「薄いラップ層」を被せるか

上記の必要性が **1 つでも当てはまる** 場合。ただし以下の判断軸でラップの厚みを決める：

```text
[ラップの厚みの決定]

ほぼなし  ─────────────  薄いラップ  ─────────────  厚いラップ
直接 import       社内認証 + ロギング        全エンドポイントを             別の API に差し替え可能
                  + エラー型変換             独自シグネチャで再公開         な抽象 (overkill)
                                              ← ここまでは妥当 →             ← 早すぎる抽象化 →
```

**推奨は「薄いラップ」で止める**：
- SDK の生のメソッドはそのまま見せる（隠さない）
- 社内固有のフィールド (apiKey 取得 / ログ送信 / エラー変換) だけ追加する
- 「将来 SDK を別のものに差し替える」を理由にしない（YAGNI、加担禁止）

## 実装テンプレ（薄いラップ）

```ts
import Stripe from "stripe";

export interface StripeClientOptions {
  apiKey: string;                  // 社内 Vault 等から取得した値を注入
  logger?: Logger;                 // ロギング層を注入
  fetch?: typeof globalThis.fetch; // テスト・カスタム retry のため
  appInfo?: { name: string; version: string };
}

export interface StripeClient {
  raw: Stripe;                     // SDK 本体へのエスケープハッチ
  customers: {
    create(params: Stripe.CustomerCreateParams): Promise<Stripe.Customer>;
    // 社内で使う操作だけ public。残りは raw 経由で
  };
}

export function createStripeClient(opts: StripeClientOptions): StripeClient {
  const sdk = new Stripe(opts.apiKey, {
    appInfo: opts.appInfo,
    httpClient: opts.fetch ? Stripe.createFetchHttpClient(opts.fetch) : undefined,
  });

  return {
    raw: sdk,
    customers: {
      create: async (params) => {
        opts.logger?.debug("stripe.customers.create", { hasEmail: !!params.email });
        try {
          return await sdk.customers.create(params);
        } catch (err) {
          throw mapStripeError(err);  // 社内統一エラーへ変換
        }
      },
    },
  };
}
```

ポイント：
- **`raw` フィールドで SDK 本体を露出する**。ラッパーが網羅していない機能でも生 SDK で叩けるエスケープハッチ
- 公開メソッドは「社内で実際に使うもの」だけ追加する（網羅しない）
- SDK の型 (`Stripe.CustomerCreateParams` 等) はそのまま再利用する（自前で再定義しない）

## やらないこと

- ❌ SDK の全メソッドをミラーする独自インターフェース
- ❌ SDK の戻り値型を独自型に narrow（`raw` で十分）
- ❌ 「将来別の決済 API に差し替えるかも」を理由にした `IPaymentClient` インターフェース
- ❌ SDK のドキュメントと別のドキュメントを書く（重複保守）

## SDK と一緒に書く時の contract test

`references/contract-test-checklist.md` の項目のうち、SDK ラップでは以下に絞る：

| 項目 | SDK ラップでも test するか |
| --- | --- |
| HTTP リクエスト形 | ✗（SDK が責任を持つ） |
| レスポンス形 | ✗（SDK が責任を持つ） |
| 社内固有のエラー変換 | ✓（`mapStripeError` 等） |
| ロガー呼び出し | ✓（key field だけ確認） |
| 認証情報の注入経路 | ✓（apiKey が SDK に正しく渡る） |
| API キーがログに混入しない | ✓（ネガティブテスト） |
| `raw` で SDK 本体にアクセスできる | ✓ |

つまり contract test の対象は「**SDK との境界の自前部分のみ**」。SDK の挙動そのものを test するのは SDK の責任で、こちらでやらない。

## smoke test

SDK ラップの場合、smoke test は**社内固有の振る舞いに絞って実行**すれば十分：

- 社内 Vault 経由で apiKey が取得できて SDK が初期化される
- ロガーに記録されている
- エラー時に社内統一エラー型で返る

SDK そのものの挙動（実 API との通信）は SDK 側の責任なので、smoke は不要。

## 共通原則（refresh）

SDK ラップの場合でも以下は守る：

- DI 境界（`apiKey` / `logger` / `fetch` を引数注入）
- silent failure 禁止（エラー変換時、情報を捨てない）
- 過剰抽象禁止（実装が 1 つしかない interface を切らない）

詳細は `../design-principles.md`。

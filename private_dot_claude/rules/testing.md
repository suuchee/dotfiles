# テストの方針

## Contract-first / Regression-first

ideology-first の TDD は採らない。テストを置く / 増やすときは次の優先順で考える。

1. **test-first にする箇所**: バグ再現 / 境界仕様 / 構造制約 / 外部契約
   壊れると高くつく場所に test-first を適用する。
2. **薄く抑える箇所**: 変更が激しい UI 仕様 — screenshot diff / broader integration で代替する。
3. **手前に置く箇所**: lint / typecheck / structural test / dependency scan / secret scan を deterministic に先行させる。

## やらないこと

- 「網羅率を上げるため」だけのテストを新規追加しない
- 振る舞いの変更を伴わないテストの大量リライトを目的化しない
- 「テストも一緒に書いて」を AI に丸投げして、どこを test-first にするかの判定まで委ねない（人間がカテゴリを決めてから依頼する）

## テスタビリティ ⇄ レイヤー分離

「test-first にする箇所」を機能させるには、**そもそもテストを書ける構造**になっている必要がある。テスタビリティはアーキテクチャの強制装置として働く。双方向の関係を意識する。

- **テストが書ける形にする** → グローバル参照（`process.env`, top-level fetch / db client, 直接の console.log / stdout）を関数引数や DI に追い出す → 純粋関数と I/O が自然に分離される
- 逆に **レイヤー（Use Case / Gateway / Controller など）が分かれている** → 各レイヤーは外部依存をポートとして受け取るので、テストでは fake / mock を渡せる

つまり「テスト先で書くこと」自体が目的ではなく、**「テストを書ける状態を維持する」ことが業務ロジックを副作用から切り離す原動力**になる。Contract-first は構造への副作用も含んでいる。

### Phase 1 / 小規模実装で守ること

実装が薄くてレイヤーを切るほどではない段階でも、**DI 境界そのものは最初から作る**：

```ts
// 悪い例: 副作用が直接埋め込まれていてテスト不能
async function listCustomers(name: string) {
  const apiKey = process.env.API_KEY!;            // env 直読み
  const res = await fetch(`https://...?name=${name}`, {
    headers: { "X-Api-Key": apiKey },
  });
  return res.json();
}

// 良い例: 依存が引数で注入されており contract test を書ける
interface ClientOptions {
  apiKey: string;
  fetch?: typeof globalThis.fetch;
}
function createClient(opts: ClientOptions) { /* ... */ }
```

CLI / handler 側も同様に `{ env, stdout, exit, createClient }` を deps として受け取り、`process.*` を直接触らない pure 関数にする。

### 過剰抽象は避ける（早すぎる抽象化の禁止）

テスタビリティを口実にした過剰抽象は別の害を生む：

- 実装が 1 つしかない `IFoo` のようなインターフェースを「将来 swap するかも」で切らない
- 中身が「他のメソッドへの単純委譲」しかない関数 / 層を作らない
- DI 境界は **既に複数の入力 / モックが必要なポイント** にだけ置く（`fetch`, `env`, `stdout` のような副作用境界）

### レイヤー間の境界違反は機械的に防ぐ

- Controller が直接 fetch / DB を触る、Gateway が UI 層の型を import する、といった逆流は人間レビューだけでは漏れる
- ある程度コード量が増えたら `eslint-plugin-import` の `no-restricted-imports`、`dependency-cruiser`、`madge` などで境界を機械的に強制する
- プロジェクトが小さいうちは test と code review で代替してよいが、「2 度同じ違反を見たら仕組みに落とす」（`failure-feedback.md` 準拠）

## テスト設計の3軸

テスト設計時は視点・視野・視座を分けて意識する（混同したまま「テストが薄い」と感じない）。

- **視点**: バグ・観点の種類（境界値 / 異常系 / 並行性 / セキュリティ / 性能…）
- **視野**: 対象範囲（unit / integration / e2e）
- **視座**: 誰の責任で書くか（モジュール作者 / API 利用者 / 運用者）

定義と使い分けの詳細・アンチパターンは `~/.claude/skills/perspective/` を参照。

## テスト設計の要因マトリクス

テストケースを単体で並べる前に、効きそうな**要因**と**水準**を明示し、要因×水準のカバレッジを意識する。要因が暗黙のまま混ざると、「テストが緑だから大丈夫」と誤認したり、失敗時に原因が切り分けられなくなる。

### なぜ要因マトリクスが要るか

- 失敗時に「どの要因の水準で精度が落ちているか」を切り分けられる
- 要因が偏ったまま局所的にテストしているのを発見できる
- 「ケースを追加する」判断の根拠が「カバレッジ表の空セル」になる（思いつきで増やさない）
- 直交表まで厳密にやらなくても、要因の存在を意識するだけで設計の質が上がる

### 適用範囲

- unit test の境界値（要因: 入力タイプ × 値の範囲 × 状態）
- integration test の状態空間（要因: 認証状態 × データ状態 × 並行性）
- e2e の操作シナリオ（要因: ユーザー種別 × 入力経路 × 例外状況）
- LLM の trigger eval（要因: 言語 × 文体 × 動詞 × キーワード明示性 × 期待動作）
- プロパティテストの input space 設計
- 契約テストの観点列挙（Request 側 / Response 側 / Error 変換 / 副作用 / 入力境界）

### 直交表との関係（要約）

直交表（L4 / L8 / L16 等）は要因の効果が独立で線形加算される前提のため、LLM eval や交互作用が大きいテストでは過剰になりやすい。**直交表をそのまま使うのではなく「要因を意識的に分散させ、空セルを潰す」程度が実用的**。

詳細な手順・典型要因例・直交表の使い分け・LLM trigger eval 特有の要因設計は skill `test-factor-design` を参照。

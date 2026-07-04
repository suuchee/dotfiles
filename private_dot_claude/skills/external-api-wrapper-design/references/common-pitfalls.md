# Common Pitfalls

実プロジェクトで実際に指摘された落とし穴の集積。書き手 (AI) が再発しがちなパターンなので、毎回 self-review で確認する。

このファイルは追記式：新しい落とし穴を観測したら最後に追記する（`~/.claude/rules/failure-feedback.md` の「2 度繰り返したら仕組みに戻す」準拠）。

## 1. OpenAPI optional 宣言と実 API の null 混入のズレ

### 観察された現象

OpenAPI で field が optional 宣言（`required` 配列に含まれない）の場合、`openapi-typescript` は `field?: T` として生成する。だが実 API は **`null` を返す** ことが多い。

例: `openapi.json` で `closingMonth` が optional 宣言 → 生成型は `closingMonth?: number`。だが実 API は `closingMonth: null` で返す。

### 影響

- `closingMonth` を扱うコードで `value | undefined` のみ想定して null チェックが漏れる
- `Object.keys()` で field が常に存在する前提でループすると、`null` が混入して下流で爆発

### 対策

- 公開型を narrow する時に `| null` を含めるか、null を undefined に正規化する明示的な変換を入れる
- 実 API の smoke test で `null` で来る field を観察してリスト化（`smoke-test-template.md` で実施）
- ADR に「公開型と生成型を分離する」決定として記録

## 2. 引数なし呼び出しが意図せず全件取得になる

### 観察された現象

`client.customers.list()` を引数なしで呼ぶと、API 側のデフォルトで全件 listing が走る。CLI から `mazrica customers search` を引数なしで実行できると、Skill 経由で意図せず大量データを引く可能性がある。

### 影響

- レート制限を一気に消費
- 機密情報を意図せず引っ張る
- リソースによっては数万件級のデータが返る

### 対策（プロジェクト判断による）

- **client 層では許容**: 生 API と同じ動作を残す（library として柔軟性を保つ）
- **CLI / interface 層で判断**: 「最低 1 つの絞り込み」を必須化する選択肢もある（プロジェクトの方針による）
- **どちらの選択をするか自体は ADR に記録**: 安易にどちらかに決めつけず、要件と照らして判断する

`~/.claude/rules/neutral-evaluation.md` の通り、片方に加担しないこと。「全件取得は害悪」「全件取得を許可すべき」のどちらも勝手に断定しない。

## 3. 欠落要素を silent に除外する

### 観察された現象

OpenAPI で全 field が optional な resource を公開型として narrow するとき、`id` や `name` を欠いた要素を `filter` で silent に除外している。

### 影響

- 呼び出し側が「totalCount は 100 だが配列は 95 件」のような不整合に気付けない
- 運用で「最近データが減った気がする」と気付くまで負債が見えない
- API 側のバグや仕様変更を早期発見できない

### 対策

- 除外したら **件数を `warnings` で呼び出し側に伝える**
- `ListResult.warnings: ClientWarning[]` を公開型に含める
- CLI 出力では `meta.warnings` に伝搬し、Skill 経由の利用者にも見える形にする

## 4. メソッド別 contract の取り違え

### 観察された現象

GET `/customers` のレスポンスで `customers` field が省略されたら「0 件ヒット」相当として安全に扱える。だがこの「省略 = 空配列」ロジックを PUT/PATCH のレスポンスマッピングに流用すると、「変更なし」と「全削除」を区別できなくなる。

### 影響

- 同じ resource の異なるメソッドで再利用された response mapping が、メソッド固有の意味論を破壊する
- bulk 操作系の API で特に致命的

### 対策

- test 名・describe で **GET 限定** を明示する: 「GET レスポンスで customers が省略されたら空配列として扱う」
- 各メソッドの response contract は **独立した describe** で test を書く
- 共通ヘルパーに切り出す時は、そのヘルパーがどのメソッド前提かを命名で示す（`mapGetListResponse` のように）

## 5. クエリパラメータだけ test すれば十分という思い込み

### 観察された現象

contract test で「クエリパラメータが正しく送られるか」だけを test して、ヘッダ・URL base・メソッド・Accept・x-request-id 伝搬・非 JSON レスポンス等が漏れる。

### 影響

- 本番デプロイ後に「`Accept` ヘッダが無いから WAF が HTML を返してきた」ような事故
- エラー時に `requestId` が取れず、API 提供元への問い合わせができない
- 200 で HTML が返ってきた時に `body.items` で爆発する

### 対策

- `contract-test-checklist.md` の 5 セクション（Request 側 / Response 側 / Error 変換 / 副作用 / 入力境界）を順に確認
- 「送られないこと」のネガティブテストも書く（Cookie / API キー漏れ等）

## 6. 空文字 `""` を query から omit していない

### 観察された現象

`undefined` のクエリパラメータは omit するロジックがあるが、空文字 `""` はそのまま `searchWord=` として送られる。Mazrica API がこれをどう解釈するかは仕様未確認。

### 影響

- API 側仕様に依存することになる（仕様変更で挙動が変わる）
- 「空文字は全件」と扱う API と「空文字はエラー」と扱う API で挙動がブレる

### 対策

- 空文字は `undefined` 同様に omit する（安全側）
- contract test に「空文字クエリは送信されないこと」のケースを追加

## 7. 200 で非 JSON が返ってきた時に爆発する

### 観察された現象

WAF や CDN がエラーページ（HTML）を 200 で返すケースがある。`response.json()` を素朴に呼ぶと parse エラー、または `body.items` 等で undefined access になる。

### 影響

- 「API は 200 を返したのに client がクラッシュした」という不可解な状況
- WAF 介入は本番でだけ起きるので、staging で検出できない

### 対策

- 200 + 非 JSON は `ApiError` に変換する（`status`, `body` を生文字列で保持）
- contract test に「200 + HTML レスポンスで ApiError になる」ケースを追加

## 8. 早すぎる抽象化（`IClient` interface 等）

### 観察された現象

「将来 swap するかも」を理由に、実装が 1 つしかないインターフェース（`IMazricaClient`）を切る。中身が単純委譲しかない service 関数を作る。

### 影響

- 認知負荷が増える（読む人は実装を 2 つ追わないといけない）
- 抽象が当たらないことが多く（実際に swap されない）、無駄な間接層になる
- 後から抽象を解体する方が、後から抽象を追加するより遥かに大変

### 対策

- DI 境界は **既に複数の入力 / mock が必要なポイント** にだけ置く
- service 層は **多段オーケストレーション** が出てきた時点で立ち上げる（YAGNI）
- 「2 度目に同じパターンを書くとき」に抽象を作る

## 9. mock の限界を忘れる

### 観察された現象

contract test がすべて緑だから「動く」と思い込み、実 API を一度も叩かずに PR を出す。

### 影響

- OpenAPI と実 API のズレで本番で爆発
- 認証ヘッダの typo など、mock では検出できない致命的バグの見逃し

### 対策

- PR を立てる前に必ず smoke test を実行（`smoke-test-template.md`）
- `contract test 緑 ≠ 動く` を肝に銘じる
- mock では検出不能な項目を smoke test 計画書に明示

## 10. 公式 SDK の存在確認を怠り、自前で client を書く

### 観察された現象

外部 API のラッパーを書く時、公式 SDK の有無を確認せずに OpenAPI から自前で fetch wrapper を書いてしまう。Stripe / Notion / Slack / GitHub / OpenAI / Anthropic 等は公式 SDK が充実しているのに、生 API を直接叩く client を再発明する。

### 影響

- SDK が解決済みのエッジケース（リトライ、バックオフ、idempotency key、pagination iterator 等）を再実装
- メンテナンス対象が増える
- SDK 側の改善や型修正の恩恵を受けられない
- API spec 変更時に手動追従が必要

### 対策

- SKILL.md の「選定フロー」で **最初に** 公式 SDK の有無を確認する
- npm レジストリで `<vendor>/<service>` 系パッケージを検索（例: `stripe`, `@notionhq/client`, `@slack/web-api`, `@octokit/rest`, `openai`, `@anthropic-ai/sdk`）
- 公式 SDK があるなら、まず直接利用を検討。`patterns/sdk-wrap.md` の方針に従う
- 「自前で書く方が学習になる」「自社にコントロールが欲しい」だけで再発明しない

## 11. SDK ラッパーで SDK の全機能をミラーする

### 観察された現象

SDK の上に薄いラップ層を被せる時、SDK の全メソッドをミラーする独自インターフェース (`IPaymentClient.charge()`, `.refund()`, ...) を作ってしまう。

### 影響

- SDK が機能追加するたびにラッパーも追従が必要
- 利用側は SDK のドキュメントとラッパーのドキュメントの両方を読む必要がある
- SDK 型情報の損失（独自シグネチャに変換した時点で SDK 型の便益が消える）

### 対策

- ラッパーには `raw: SDK` フィールドで SDK 本体へのエスケープハッチを残す
- 公開メソッドは「社内で実際に使うもの + 社内固有処理が必要なもの」だけ追加
- 残りの操作は `client.raw.charge(...)` で生 SDK を呼ぶ
- 「将来別 SDK に差し替えるかも」を理由にした完全ラップは作らない（YAGNI、過剰抽象）

## 12. CLI vs MCP vs その他 interface の中立評価を怠る

### 観察された現象

「CLI は重い、MCP の方が楽」のような利点指摘を、ユーザーが言っていない結論（「MCP を主力にすべき」）に勝手に拡張する。

### 影響

- ユーザーが意図していない方針変更を提案してしまう
- 信頼を損なう

### 対策

- `~/.claude/rules/neutral-evaluation.md` に従い、利点・欠点の整理に留める
- 「中核は client、interface は付け替え可能」という本質を保ち、interface 選定はプロジェクトの要件次第と認識する
- 「主力候補に昇格」「採用しない」のような決定を勝手に下さない

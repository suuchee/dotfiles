# Smoke test テンプレ

contract test (mock fetch を注入する unit test) では検証不能な項目を、実 API で確認するためのテンプレ。

## なぜ smoke test が要るか

contract test は「コード内部の契約」を deterministic に固定する。だが、それだけでは以下のズレを検出できない：

- **型宣言と実 API の挙動のズレ**（OpenAPI / SDK 型 / 手書き型 のいずれの場合でも、optional 宣言の field が実は常に来る、`required` でない field が実は `null` で返る等が起きる）
- **認証フローが本当に通るか**（headers の組み立てミス、URL の typo、SDK ラップ時の社内 Vault 連携）
- **Pagination が仕様通りか**（page 切り替えで実際にデータがズレる）
- **Rate limit の実挙動**（`Retry-After` ヘッダの有無、burst 制限の動き）
- **エラーレスポンスの body 形**（仕様書に書かれていない実態）

これらは PR マージ前に 1 回だけでも実 API を叩いておくと早期発見できる。

## パターン別の適用範囲

| パターン | smoke test の重点 |
| --- | --- |
| **OpenAPI あり / SDK なし** | 全項目（自前 fetch wrapper の責任範囲のため） |
| **OpenAPI なし / SDK なし** | 全項目 + ドキュメント外 field の発見・記録 |
| **SDK 利用 / 薄いラップ** | 社内固有部分のみ（apiKey 注入、ロガー、エラー型変換）。SDK 自体の挙動は SDK の責任 |

## 実行タイミング

- 新リソース実装後の PR を立てる**直前**
- API spec の更新を取り込んだ後
- API 提供元から「仕様変更しました」と通知があった後

頻度を上げる必要はない（CI で毎回叩くのは API キーと rate limit を考えると非現実的）。マイルストーン単位でよい。

## 安全に行うために

- 本番 API キーではなく **staging / dev 環境の API キー** を使う（あれば）
- 書き込み系 API は **dry-run / test mode** があれば必ずそれを使う
- 結果に PII が含まれる可能性があるので、保存ファイルは `.gitignore` に追加（または `data/` 配下を ignore する慣習にする）
- 結果ログを共有する時は ID / メールアドレス / 電話番号等を `*****` でマスク

## チェック項目テンプレ

各 API 操作について、以下を実行・確認する：

### 1. 認証フロー

```bash
export API_KEY=<実 staging キー>

# 正常な認証で 200 が返るか
<your-cli> <resource> list --limit 1 --json
# 期待: { "ok": true, "data": {...} }

# 不正な認証で 401 / 403 が返るか
API_KEY=invalid <your-cli> <resource> list --limit 1 --json
# 期待: { "ok": false, "error": { "code": "permission_denied" } }
```

確認したいこと：
- ヘッダ名が正しい（`X-Api-Key` / `Authorization: Bearer ...` 等）
- 不正キーで返る status (401? 403?) と body 形を記録
- error code のマッピングが意図通り

### 2. レスポンス実体の観察

```bash
<your-cli> <resource> list --limit 2 --json | jq .
```

確認したいこと：
- レスポンス JSON の **トップレベル構造**（`{ items, total, page }` か `{ data, meta }` か等）
- 各 record の **どの field が実運用で常に来るか**（OpenAPI optional だが実は必須相当）
- `null` が返る field（OpenAPI 型に `| null` が抜けている可能性）
- ネストされた object / 配列の構造
- 日付・数値の型（string で来るか、number で来るか）

### 3. Pagination の動作

```bash
<your-cli> <resource> list --limit 2 --page 1 --json | jq '.data.items[].id'
<your-cli> <resource> list --limit 2 --page 2 --json | jq '.data.items[].id'
```

確認したいこと：
- page 切り替えで実際にデータが変わる
- `totalCount` / `total` / `nextCursor` のような pagination 情報の意味
- 範囲外 page の挙動（空配列か、エラーか）
- `limit` の上限超え（API 仕様の最大値超過）の挙動

### 4. 検索・絞り込み

```bash
<your-cli> <resource> list --search "<実在するクエリ>" --json | jq '.data.totalCount'
```

確認したいこと：
- 検索パラメータが意図通りの照合範囲を持つ（部分一致 vs 完全一致、対象 field）
- 空文字検索の挙動（全件か、エラーか）
- 大文字小文字の区別
- 全角・半角・大文字小文字の正規化

### 5. Rate limit の挙動

`limit` を上げて連続リクエストを試す（**慎重に**、本番 API なら避ける）：

```bash
for i in 1 2 3 4 5; do
  <your-cli> <resource> list --limit 1 --json &
done
wait
```

確認したいこと：
- 429 が返るタイミング（実際の req/sec が仕様通りか）
- 429 レスポンスの body と headers（`Retry-After` ヘッダの有無）

### 6. エラー body の実体

意図的にバリデーションエラーを起こす：

```bash
<your-cli> <resource> create --invalid-field "..." --json
```

確認したいこと：
- エラー body の構造（`{ message }` / `{ error: { code, message, details } }` / その他）
- `requestId` ヘッダの有無（`x-request-id` / `request-id`）

## 結果の記録

smoke test の結果は `.notes/<NNN>_<context>/research/smoke-test_YYYY-MM-DD.md` に記録する。テンプレ：

```markdown
# 実 API smoke test 結果メモ

実施日: YYYY-MM-DD
実施者: <名前>
対象: <resource> / <branch / commit>

## 確認できたこと

### 認証
- 正常: <status> + <body 概要>
- 不正キー: <status> + マッピング先 error code

### レスポンス実体
- トップレベル構造: <構造>
- 実運用で常に来る field: <list>
- null で返る field: <list>（OpenAPI 型に追加が必要）

### Pagination
- <観察>

### その他
- <観察>

## 検証していないが Phase X までに確認したいこと

- ...
```

## 結果が予想と違ったら

- **OpenAPI 型と実 API のズレ**: 公開型を narrow するロジックを修正、ADR に記録
- **エラー body 形が予想と違う**: client のエラー変換ロジックを修正、test を追加
- **Rate limit が想定より厳しい**: client にリトライ層を追加検討
- **認証フローのヘッダミス**: 即座に contract test を追加して deterministic に固定

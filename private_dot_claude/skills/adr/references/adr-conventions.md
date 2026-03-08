# ADR Conventions

ADRの規約とライフサイクル管理。

## 保存先ディレクトリ

### 検出順序

プロジェクトのADR保存ディレクトリを以下の順序で検出する:

1. `docs/adr/`
2. `docs/decisions/`
3. `doc/arch/`
4. `adr/`

いずれも見つからない場合、`docs/adr/` をデフォルトとしてユーザーに確認する。

### ディレクトリ初期化

新しいプロジェクトでADRを始める場合:

```
docs/adr/
├── 0000-use-madr-for-adr-format.md  # ADR #0: ADR形式自体の決定
├── 0001-first-decision.md
└── ...
```

## ファイル命名規則

`NNNN-title-in-kebab-case.md`

- **NNNN**: 4桁ゼロ埋め連番（0000から開始）
- **title**: ケバブケース（小文字、ハイフン区切り）
- **拡張子**: `.md`

### 連番の決定

1. ADRディレクトリ内の既存ファイルをスキャン
2. 最大の連番を取得
3. +1 した番号を使用

### タイトルの付け方

- 問題と解決策を要約する短い名詞句
- 動詞で始めるのが一般的: 「use-redis-for-caching」「choose-jwt-over-session」
- 日本語でも可（ただしファイル名は英語のケバブケース推奨）

## ライフサイクル

### ステータス遷移図

```
proposed ──┬──→ accepted ──┬──→ deprecated
           │               └──→ superseded (by new ADR)
           └──→ rejected
```

### 各ステータスの意味

| ステータス | 意味 | 次の遷移 |
| --- | --- | --- |
| proposed | 提案中。レビュー・議論待ち | accepted, rejected |
| accepted | 承認済み。チームが従うべき決定 | deprecated, superseded |
| rejected | 却下。理由を明記して保存 | なし（終了状態） |
| deprecated | 非推奨。もう適用しないが歴史的記録として残す | なし（終了状態） |
| superseded | 新しいADRに置き換え済み | なし（終了状態） |

### 不変性の原則

ADRは「追記のみ（append-only）」で運用する:

- 一度 accepted になったADRの本文を書き換えない
- 誤字脱字の修正は可（意味を変えない範囲）
- 決定内容の変更には新しいADRを作成し、Supersedeする

### Supersedeプロセス

1. **新ADRを作成**: 新しい決定を通常のADR作成プロセスで記録
2. **新ADRに supersedes を追加**: フロントマターに `supersedes: "NNNN-old-title.md"`
3. **旧ADRのステータス変更**: `status: superseded` に更新
4. **旧ADRに superseded-by を追加**: フロントマターに `superseded-by: "NNNN-new-title.md"`

## ADR #0 について

プロジェクトで最初に作成するADR（0000番）は、「ADR形式にMADRを使用する」という決定自体を記録することが推奨される。これにより:

- チームがADRの存在と形式を認識する
- ADRディレクトリの初期化が行われる
- ADRプラクティスの採用が明示的に記録される

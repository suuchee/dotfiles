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

公式 MADR の status フィールド書式: `proposed | rejected | accepted | deprecated | … | superseded by ADR-NNNN`

| ステータス | 意味 | 次の遷移 |
| --- | --- | --- |
| `proposed` | 提案中。レビュー・議論待ち | accepted, rejected |
| `accepted` | 承認済み。チームが従うべき決定 | deprecated, superseded by ADR-NNNN |
| `rejected` | 却下。理由を明記して保存 | なし（終了状態） |
| `deprecated` | 非推奨。もう適用しないが歴史的記録として残す | なし（終了状態） |
| `superseded by ADR-NNNN` | 新ADRに置き換え済み（NNNN は新ADRの番号） | なし（終了状態） |

### 不変性の原則

ADRは「追記のみ（append-only）」で運用する:

- 一度 accepted になったADRの本文を書き換えない
- 誤字脱字の修正は可（意味を変えない範囲）
- 決定内容の変更には新しいADRを作成し、Supersedeする

### Supersedeプロセス

公式 MADR では `status` フィールド自体に置き換え関係を記録する形式を採用している:

1. **新ADRを作成**: 新しい決定を通常のADR作成プロセスで記録（`status: "proposed"`）
2. **旧ADRのステータス変更**: `status: "superseded by ADR-NNNN"` に書き換える（NNNN は新ADRの番号）
3. **新ADRから旧ADRへのリンク（推奨）**: 新ADRの More Information セクションに旧ADRへのリンクを記載する

## ADR #0 について

プロジェクトで最初に作成するADR（0000番）は、「ADRフォーマットの採用」という決定自体を記録する。これにより:

- チームがADRの存在と形式を認識する
- ADRディレクトリの初期化が行われる
- ADRプラクティスの採用が明示的に記録される
- そのプロジェクトでの**書式選択**（Y-Statement / Confirmation 等）が明示される

### ADR-0000 自動生成フロー

ADR保存ディレクトリに既存ADRがない場合、ADR-0000 をスキル側で自動生成する。生成時に `AskUserQuestion` で以下の書式選択を確認する。

#### 質問項目

1. **Y-Statement を使うか**
   - はい — すべてのADRの frontmatter に `y-statement` を含める
   - いいえ — `y-statement` は使わない

frontmatter に入る要素のため、プロジェクト内で一貫性を保つ目的で ADR-0000 で確定する。本文の任意セクション（Confirmation / Revisit Triggers 等）は ADR ごとの書き手判断に委ねるため、ここでは聞かない。

#### 回答の記録

ADR-0000 の本文に、選択した書式を明示的に記録する:

```markdown
## Decision Outcome

Chosen option: "MADR形式 + 本スキルのカスタマイズ", because ...

### このプロジェクトでの書式選択

- Y-Statement: 使う / 使わない
```

#### 以降のADRへの適用

ADR-0001以降を新規作成する際は、**必ず最初に ADR-0000 を読み**、Y-Statement の採用設定を取得してから frontmatter を組む。

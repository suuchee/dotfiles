---
name: adr
description: This skill should be used when the user asks to "ADR作成", "アーキテクチャ決定記録", "設計判断を記録", "技術選定を文書化", "ADR一覧", "ADR確認", "決定を置き換え", or when making architecturally significant decisions like choosing frameworks, databases, API designs, authentication strategies, deployment patterns, or data models. Also use when the user mentions "ADR", "architecture decision", "design decision", discusses technology trade-offs, or asks about past architectural decisions in the project. Use this skill proactively when you detect the user is making an important design choice that should be recorded.
---

# Architecture Decision Record (ADR)

アーキテクチャ上の重要な決定を記録・管理するためのスキル。

## Purpose

- アーキテクチャ上重要な決定（ASR: Architecturally Significant Requirement）を検知し、ADR作成を提案する
- MADR形式でADRを作成する
- 既存ADRのライフサイクル管理（ステータス変更、置き換え）
- ADRの一覧表示と検索

## 運用原則

1. **粒度をアトミックに保つ** — 1つのADRが扱う判断は1件のみ。複数の判断を束ねたい場合はそれぞれ別のADRに分割する
2. **受理済みは追記のみ（append-only）** — `accepted` になったADRの本文は書き換えない。決定を覆す場合は新ADRを起票し、旧ADRの `status` を `superseded by ADR-NNNN` に切り替える
3. **AI生成は `proposed` で固定** — AI が作るADRのステータスは常に `proposed`。`accepted` への昇格は人間の判断に限定する。ステータス変更を依頼されても AI 側で書き換えず「人間が確認のうえ変更してください」と返す
4. **却下した選択肢も保存する** — 採用しなかった案こそ、将来の再検討時に「なぜそちらにしなかったか」を補う文脈になる。Considered Options / Pros and Cons of the Options に残す

## ADR保存先の決定

プロジェクトのADR保存ディレクトリを以下の順序で検出する:

1. 既存ディレクトリの検索: `docs/adr/`, `docs/decisions/`, `doc/arch/`, `adr/`
2. CLAUDE.mdやREADMEにADRパスの記述がないか確認
3. いずれも見つからない場合、`docs/adr/` をデフォルトとしてユーザーに確認

## ADR-0000 の生成（初回のみ）

ADR保存ディレクトリに既存ADRがない場合、ADR-0000「ADRフォーマットの採用」を生成する。これによりプロジェクト固有の書式選択を明示的に記録する。

`AskUserQuestion` で以下を確認する:

- **Y-Statement を使うか**（はい / いいえ）

回答を踏まえて ADR-0000 を作成し、本文に Y-Statement の採用可否を記録する。

Confirmation セクションと Revisit Triggers セクションは公式 MADR / 本スキルの任意セクションとして書き手判断に委ねる（ADR-0000 で制御しない）。

詳細な手順は `references/adr-conventions.md` を参照。

## アーキテクチャ上重要な決定（ASR）の検知

以下のシグナルを検知した場合、ADR作成を提案する。

### 技術選定

- フレームワーク、ライブラリ、データベースの選択
- 認証・認可方式の決定
- APIプロトコル・設計方針の決定（REST vs GraphQL等）
- メッセージング・キューイング方式の選択

### アーキテクチャパターン

- マイクロサービス vs モノリスの決定
- データモデリングの設計判断
- キャッシュ戦略の選択
- デプロイメント・インフラ構成の決定

### 非機能要件

- パフォーマンス最適化のアプローチ
- セキュリティ対策の方針
- スケーラビリティ戦略
- 可用性・耐障害性の設計

### 検知のガイドライン

- 「〜にした」「〜を使うことにした」「〜を採用する」などの決定を示す表現
- 複数の選択肢を比較検討している議論
- トレードオフの議論（「〜の方が速いが、〜の方が保守しやすい」）
- 将来の開発に影響を与える構造的な変更

## ADR作成プロセス

### Step 1: コンテキストの収集

ユーザーとの対話で以下の情報を収集する:

1. **問題の背景**: 何が起きていて、なぜ決定が必要か。決定の対象範囲も明示する
2. **決定の推進要因（Decision Drivers）**: 判断に影響する品質要件・制約・force等
3. **検討した選択肢**: 比較した代替案（最低2つ）
4. **選ばれた選択肢と理由**: なぜその選択肢を選んだか
5. **トレードオフ**: 受け入れる欠点やリスク
6. **見直しトリガー**: この決定を再考すべき条件

### Step 2: ADRの作成

公式 [MADR v4.0.0](https://adr.github.io/madr/) のテンプレートに従ってADRを作成する。本スキルは公式テンプレに `y-statement` フィールド（frontmatter）と `## Revisit Triggers` セクションを追加した拡張版を使用する。完全なテンプレートは `references/madr-template.md` を参照。

**ファイル命名**: `NNNN-title-in-kebab-case.md`（4桁ゼロ埋め連番）

**frontmatter**:

```yaml
---
status: "proposed"
date: YYYY-MM-DD
decision-makers: [name1]
consulted: []           # optional
informed: []            # optional
# 本スキル独自フィールド（ADR-0000 で「使う」を選んだ場合のみ）:
y-statement: >
  <ユースケース>の文脈において、
  <懸念事項>に直面したため、
  <品質目標>を達成するために、
  <欠点>を受け入れ、
  <選択肢>を採用することを決定した。
---
```

Y-Statementの詳細は `references/y-statement-guide.md` を参照。

Supersede の場合、status は `"superseded by ADR-NNNN"` の形式で記載する（公式 MADR の推奨形式）。

### セクション構成

公式 MADR に従う。`<!-- This is an optional element. -->` のコメントが付いているセクションが任意。

| セクション | 必須/任意 | 内容 |
| --- | --- | --- |
| Title | 必須 | 問題と解決策を要約する短い名詞句 |
| Context and Problem Statement | 必須 | 状況・問題（散文）。決定の対象範囲も明示する |
| Decision Drivers | 任意 | 判断に影響する要因（品質要件、制約、force等） |
| Considered Options | 必須 | 検討した選択肢の見出し列挙（最低2つ） |
| Decision Outcome | 必須 | 採用する選択肢 + 1-2文の理由 |
| Consequences (h3) | 任意 | Decision Outcome のサブ。Good/Bad で結果を記述 |
| Confirmation (h3) | 任意 | Decision Outcome のサブ。書き手判断で記載 |
| Pros and Cons of the Options | 任意 | 各選択肢の詳細分析（Good/Bad/Neutral） |
| Revisit Triggers | 任意 | **本スキル独自セクション**。決定を見直すべき条件。書き手判断で記載 |
| More Information | 任意 | 関連ADR、参照リンク、チーム合意の記録等 |

### Step 3: 既存ADRとの関連付け

新しいADRを作成する際:

1. **ADR-0000 を必ず読む**: そのプロジェクトの Y-Statement 採用設定を取得し、frontmatter を組む際に従う
2. 既存ADRのディレクトリを確認する
3. 関連するADRがあれば「More Information」セクションにリンクを記載
4. 既存の決定を置き換える場合は Supersede プロセスに従う

## ライフサイクル管理

### ステータス一覧

公式 MADR の status フィールド書式: `proposed | rejected | accepted | deprecated | … | superseded by ADR-NNNN`

| ステータス | 意味 | 遷移 |
| --- | --- | --- |
| `proposed` | 提案中（レビュー待ち） | → accepted / rejected |
| `accepted` | 承認済み | → deprecated / superseded by ADR-NNNN |
| `rejected` | 却下（理由を明記） | 終了状態 |
| `deprecated` | 非推奨（もう適用しない） | 終了状態 |
| `superseded by ADR-NNNN` | 新ADRに置き換え済み（NNNN は新ADRの番号） | 終了状態 |

### Supersede（置き換え）プロセス

公式 MADR では `status` フィールド自体に置き換え関係を記録する形式を採用している:

1. 新しいADRを通常通り `status: "proposed"` で作成する
2. 旧ADRの `status` を `"superseded by ADR-NNNN"` に書き換える（NNNN は新ADRの番号）
3. 必要に応じて新ADRの More Information セクションに旧ADRへのリンクを記載する

## ADR一覧表示

既存ADRのディレクトリを検索し、以下の形式で一覧表示する:

| # | タイトル | ステータス | 日付 |
| --- | --- | --- | --- |
| 0001 | Use MADR for ADR format | accepted | 2026-03-08 |
| 0002 | Use Redis for caching | superseded by ADR-0005 | 2026-03-10 |

## Important Guidelines

### 品質ガードレール

1. **事実に基づく記録**: 推測や仮定ではなく、実際の議論や決定に基づいて記録する
2. **トレードオフの明記**: 選ばれた選択肢の欠点も客観的に記録する
3. **代替案の公平な評価**: 採用されなかった選択肢も、それぞれの長所・短所を記録する
4. **断定的な言語**: 決定セクションは「〜を使用する」「〜を採用する」など断定形で記述する

### ADRを作成しない場面

- 一時的な修正やワークアラウンド
- 明白な実装詳細（変数名の選択等）
- 既存の決定に従った実装

## Additional Resources

### Reference Files

- **`references/madr-template.md`** - MADRテンプレートと各セクションの記述ガイド
- **`references/adr-conventions.md`** - ADR規約（保存先、命名、連番、ライフサイクル、ADR-0000生成）
- **`references/y-statement-guide.md`** - Y-Statement形式の作成ガイド

### Example Files

- **`examples/example-adr.md`** - ADRの完成例

### Commands

対話的なADR操作には以下のコマンドも利用可能:

- `/adr:create` - 対話形式でADRを新規作成
- `/adr:list` - 既存ADRの一覧表示
- `/adr:supersede` - 既存ADRの置き換え

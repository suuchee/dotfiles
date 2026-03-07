---
name: adr
description: This skill should be used when the user asks to "ADR作成", "アーキテクチャ決定記録", "設計判断を記録", "技術選定を文書化", "ADR一覧", "ADR確認", "決定を置き換え", or when making architecturally significant decisions like choosing frameworks, databases, API designs, authentication strategies, deployment patterns, or data models. Also use when the user mentions "ADR", "architecture decision", "design decision", discusses technology trade-offs, or asks about past architectural decisions in the project. Use this skill proactively when you detect the user is making an important design choice that should be recorded.
---

# Architecture Decision Record (ADR)

アーキテクチャ上の重要な決定を記録・管理するためのスキル。

## Purpose

- アーキテクチャ上重要な決定（ASR: Architecturally Significant Requirement）を検知し、ADR作成を提案する
- MADR形式でADRを作成する
- Y-Statementによる決定の要約をフロントマターに含める
- 既存ADRのライフサイクル管理（ステータス変更、置き換え）
- ADRの一覧表示と検索

## ADR保存先の決定

プロジェクトのADR保存ディレクトリを以下の順序で検出する:

1. 既存ディレクトリの検索: `docs/adr/`, `docs/decisions/`, `doc/arch/`, `adr/`
2. CLAUDE.mdやREADMEにADRパスの記述がないか確認
3. いずれも見つからない場合、`docs/adr/` をデフォルトとしてユーザーに確認

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

1. **問題の背景**: 何が起きていて、なぜ決定が必要か
2. **決定の推進要因（Decision Drivers）**: 決定に影響を与える要素
3. **検討した選択肢**: 比較した代替案（最低2つ）
4. **選ばれた選択肢と理由**: なぜその選択肢を選んだか
5. **トレードオフ**: 受け入れる欠点やリスク

### Step 2: ADRの作成

MADR形式でADRを作成する。テンプレートの詳細は `references/madr-template.md` を参照。

**ファイル命名**: `NNNN-title-in-kebab-case.md`（4桁ゼロ埋め連番）

**フロントマター（必須）**:

```yaml
---
status: proposed
date: YYYY-MM-DD
decision-makers: []
y-statement: >
  <ユースケース>の文脈において、
  <懸念事項>に直面したため、
  <品質目標>を達成するために、
  <欠点>を受け入れ、
  <選択肢>を採用することを決定した。
---
```

Y-Statementの詳細は `references/y-statement-guide.md` を参照。

### Step 3: 既存ADRとの関連付け

新しいADRを作成する際:

1. 既存ADRのディレクトリを確認する
2. 関連するADRがあれば「More Information」セクションにリンクを記載
3. 既存の決定を置き換える場合は Supersede プロセスに従う

## ライフサイクル管理

### ステータス一覧

| ステータス | 意味 | 遷移 |
| --- | --- | --- |
| proposed | 提案中（レビュー待ち） | → accepted / rejected |
| accepted | 承認済み | → deprecated / superseded |
| rejected | 却下（理由を明記） | 終了状態 |
| deprecated | 非推奨（もう適用しない） | 終了状態 |
| superseded | 置き換え済み（新ADRあり） | 終了状態 |

### 不変性の原則

- 一度承認されたADRの内容は直接変更しない
- 決定を変更する場合は新しいADRを作成し、古いADRを superseded にする
- 却下されたADRも削除せず記録として残す（同じ議論の繰り返しを防ぐ）

### Supersede（置き換え）プロセス

1. 新しいADRを作成する
2. 新ADRのフロントマターに `supersedes: "NNNN-old-title.md"` を追加
3. 旧ADRのステータスを `superseded` に変更
4. 旧ADRのフロントマターに `superseded-by: "NNNN-new-title.md"` を追加

## ADR一覧表示

既存ADRのディレクトリを検索し、以下の形式で一覧表示する:

| # | タイトル | ステータス | 日付 |
| --- | --- | --- | --- |
| 0001 | Use MADR for ADR format | accepted | 2026-03-08 |
| 0002 | Use Redis for caching | superseded | 2026-03-10 |

## Important Guidelines

### 品質ガードレール

1. **事実に基づく記録**: 推測や仮定ではなく、実際の議論や決定に基づいて記録する
2. **トレードオフの明記**: 選ばれた選択肢の欠点も客観的に記録する
3. **代替案の公平な評価**: 採用されなかった選択肢も、それぞれの長所・短所を記録する
4. **簡潔さ**: ADRは1つの決定に対して1つ作成する（アトミック性）
5. **断定的な言語**: 決定セクションは「〜を使用する」「〜を採用する」など断定形で記述する

### ADRを作成しない場面

以下の場合はADRを作成する必要はない:

- 一時的な修正やワークアラウンド
- 明白な実装詳細（変数名の選択等）
- 既存の決定に従った実装

## Additional Resources

### Reference Files

- **`references/madr-template.md`** - MADR v4.0.0テンプレートと各セクションの記述ガイド
- **`references/adr-conventions.md`** - ADR規約（保存先、命名、連番、ライフサイクル）
- **`references/y-statement-guide.md`** - Y-Statement形式の作成ガイド

### Example Files

- **`examples/example-adr.md`** - ADRの完成例

### Commands

対話的なADR操作には以下のコマンドも利用可能:

- `/adr:create` - 対話形式でADRを新規作成
- `/adr:list` - 既存ADRの一覧表示
- `/adr:supersede` - 既存ADRの置き換え

---
description: 対話形式でADRを新規作成します。
allowed-tools:
  - "Read"
  - "Write"
  - "Glob"
  - "Grep"
  - "Bash(mkdir:*)"
  - "Bash(ls:*)"
---

## Context

- **現在のブランチ**: `!git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "not a git repo"`
- **既存ADRディレクトリ**: `!ls -d docs/adr/ docs/decisions/ doc/arch/ adr/ 2>/dev/null | head -1`
- **既存ADR一覧**: `!ls docs/adr/*.md docs/decisions/*.md doc/arch/*.md adr/*.md 2>/dev/null | sort`
- **追加情報**: $ARGUMENTS

## 参照資料

ADRのテンプレート・規約の詳細は以下を参照:

- **`~/.claude/skills/adr/references/madr-template.md`** - MADR v4.0.0テンプレート
- **`~/.claude/skills/adr/references/adr-conventions.md`** - ADR規約
- **`~/.claude/skills/adr/references/y-statement-guide.md`** - Y-Statement作成ガイド
- **`~/.claude/skills/adr/examples/example-adr.md`** - ADR完成例

## Your task

対話形式でADRを新規作成してください。

### 1. ADR保存先の確定

既存ADRディレクトリを確認する:

1. `docs/adr/`, `docs/decisions/`, `doc/arch/`, `adr/` のいずれかが存在するか
2. 存在する場合 → そのディレクトリを使用
3. 存在しない場合 → `docs/adr/` をデフォルトとしてユーザーに確認し、ディレクトリを作成

### 2. コンテキストの収集

ユーザーと対話して以下の情報を収集する（$ARGUMENTS に一部含まれている場合あり）:

1. **問題の背景**: 何が起きていて、なぜ決定が必要か
2. **決定の推進要因**: 決定に影響を与える主な要素
3. **検討した選択肢**: 比較した代替案（最低2つ）
4. **選ばれた選択肢と理由**: なぜその選択肢を選んだか
5. **トレードオフ**: 受け入れる欠点やリスク

情報が不足している場合は質問して補完する。すべての情報が揃ってから次のステップに進む。

### 3. 連番の決定

ADRディレクトリ内の既存ファイルから最大の連番を取得し、+1 した番号を使用する。
ファイルが存在しない場合は `0000` から開始する。

### 4. ADRファイルの作成

MADR形式で以下の構成のADRファイルを作成する:

- **ファイル名**: `NNNN-title-in-kebab-case.md`
- **フロントマター**: status, date, decision-makers, y-statement を必ず含める
- **本文セクション**: MADR v4.0.0テンプレートに従う

Y-Statementは収集した情報から短縮形で自動生成する。

### 5. 既存ADRとの関連

- 関連する既存ADRがあれば「More Information」セクションにリンクする
- 既存の決定を置き換える場合は `/adr:supersede` コマンドの使用を案内する

### 6. 確認

作成したADRをユーザーに提示し、修正の要望を確認する。

## 出力

```
ADR作成完了:
- ファイル: <ADRディレクトリ>/NNNN-title.md
- ステータス: proposed
- Y-Statement: <生成したY-Statement>
```

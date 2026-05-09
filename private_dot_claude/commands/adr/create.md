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

- **`~/.claude/skills/adr/SKILL.md`** - 本スキル全体の方針と運用原則
- **`~/.claude/skills/adr/references/madr-template.md`** - MADRテンプレート
- **`~/.claude/skills/adr/references/adr-conventions.md`** - ADR規約・ADR-0000生成フロー
- **`~/.claude/skills/adr/references/y-statement-guide.md`** - Y-Statement作成ガイド
- **`~/.claude/skills/adr/examples/example-adr.md`** - ADR完成例

## 運用原則

1. **粒度をアトミックに保つ** — 1つのADRが扱う判断は1件のみ
2. **AI生成は `proposed` で固定** — AI が作るADRのステータスは常に `proposed`。`accepted` への昇格は人間の判断に限定する
3. **却下した選択肢も保存する** — 採用しなかった案こそ将来の再検討時の文脈になる

## Your task

対話形式でADRを新規作成してください。

### 1. ADR保存先の確定と ADR-0000 の確認

既存ADRディレクトリを確認する:

1. `docs/adr/`, `docs/decisions/`, `doc/arch/`, `adr/` のいずれかが存在するか
2. 存在する場合 → そのディレクトリを使用
3. 存在しない場合 → `docs/adr/` をデフォルトとしてユーザーに確認し、ディレクトリを作成

次に **ADR-0000 の存在を確認**する:

- **ADR-0000 が存在する** → 読み込んで「このプロジェクトでの書式選択」（Y-Statement の使用可否）を取得
- **ADR-0000 が存在しない** → ADR-0000 を先に生成する。`AskUserQuestion` で以下を確認:
  - **Y-Statement を使うか**（はい / いいえ）

  回答に基づいて ADR-0000 「ADRフォーマットの採用」を作成する（詳細は `references/adr-conventions.md` を参照）。

### 2. コンテキストの収集

ユーザーと対話して以下の情報を収集する（$ARGUMENTS に一部含まれている場合あり）:

1. **問題の背景**: 何が起きていて、なぜ決定が必要か。決定の対象範囲も明示
2. **決定の推進要因（Decision Drivers）**: 判断に影響する品質要件・制約・force等
3. **検討した選択肢**: 比較した代替案（最低2つ）
4. **選ばれた選択肢と理由**: なぜその選択肢を選んだか
5. **トレードオフ**: 受け入れる欠点やリスク

情報が不足している場合は質問して補完する。すべての情報が揃ってから次のステップに進む。

### 3. 連番の決定

ADRディレクトリ内の既存ファイルから最大の連番を取得し、+1 した番号を使用する。

### 4. ADRファイルの作成

公式 MADR v4.0.0 に従って以下の構成のADRファイルを作成する:

- **ファイル名**: `NNNN-title-in-kebab-case.md`
- **frontmatter**: `status: "proposed"`, `date`, `decision-makers` を含める
  - **ADR-0000 で「Y-Statement を使う」が選択されている場合**は、収集した情報から短縮形 Y-Statement を生成して `y-statement` フィールドに含める
  - 選択されていない場合は `y-statement` を含めない
- **本文セクション**:
  - 必須: Title / Context and Problem Statement / Considered Options / Decision Outcome
  - 任意（書き手判断で記載）: Decision Drivers / Consequences / Confirmation / Pros and Cons of the Options / Revisit Triggers / More Information

### 5. 既存ADRとの関連

- 関連する既存ADRがあれば「More Information」セクションにリンクする
- 既存の決定を置き換える場合は `/adr:supersede` コマンドの使用を案内する

### 6. 確認

作成したADRをユーザーに提示し、修正の要望を確認する。ステータスは必ず `proposed` のまま提示し、`accepted` への変更は人間が行うよう案内する。

## 出力

```
ADR作成完了:
- ファイル: <ADRディレクトリ>/NNNN-title.md
- ステータス: proposed（accepted への変更は人間が行ってください）
- Y-Statement: <生成したY-Statement または "未使用">
```

---
description: 既存ADRを新しいADRで置き換えます（Supersede）。
allowed-tools:
  - "Read"
  - "Write"
  - "Edit"
  - "Glob"
  - "Grep"
  - "Bash(ls:*)"
  - "Bash(mkdir:*)"
---

## Context

- **既存ADRディレクトリ**: `!ls -d docs/adr/ docs/decisions/ doc/arch/ adr/ 2>/dev/null | head -1`
- **既存ADR一覧**: `!ls docs/adr/*.md docs/decisions/*.md doc/arch/*.md adr/*.md 2>/dev/null | sort`
- **対象ADR**: $ARGUMENTS

## 参照資料

- **`~/.claude/skills/adr/references/adr-conventions.md`** - Supersedeプロセスの詳細

## Your task

既存ADRを新しいADRで置き換えてください。

公式 MADR では `status` フィールド自体に置き換え関係を記録する形式（`status: "superseded by ADR-NNNN"`）を採用している。本スキルもこれに従う。

### 1. 置き換え対象の特定

$ARGUMENTS で指定された、または対話で特定された旧ADRを確認する。

対象が不明な場合:
1. 既存ADRの一覧を表示する
2. ユーザーに置き換え対象を選択してもらう

### 2. 旧ADRの内容確認

旧ADRを読み取り、以下を確認する:

- 現在のステータスが `accepted` であること（proposed の場合は直接編集を提案）
- 決定内容とその背景

### 3. 新ADRの作成

`/adr:create` と同じプロセスで新しいADRを作成する。ただし以下を追加する:

- 「Context and Problem Statement」に旧ADRの決定がなぜ変更されるかを記述
- 「More Information」に旧ADRへのリンクを記載
- ステータスは通常通り `proposed` で作成（accepted への変更は人間が行う）

### 4. 旧ADRの更新

旧ADRの frontmatter の `status` フィールドを以下に書き換える:

```yaml
status: "superseded by ADR-NNNN"
```

NNNN は新ADRの4桁ゼロ埋め番号。本文は変更しない（不変性の原則）。

### 5. 確認

変更内容をユーザーに提示する:

```
Supersede完了:
- 旧ADR: <旧ファイル名> → status: "superseded by ADR-NNNN"
- 新ADR: <新ファイル名> → status: "proposed"
- 新ADRの「More Information」に旧ADRへのリンクを記載済み
```

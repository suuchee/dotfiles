---
description: 既存ADRの一覧をステータスとともに表示します。
allowed-tools:
  - "Read"
  - "Glob"
  - "Grep"
  - "Bash(ls:*)"
---

## Context

- **既存ADRディレクトリ**: `!ls -d docs/adr/ docs/decisions/ doc/arch/ adr/ 2>/dev/null | head -1`
- **フィルタ条件**: $ARGUMENTS

## Your task

プロジェクト内の既存ADRを一覧表示してください。

### 1. ADRディレクトリの検出

以下の順序でADRディレクトリを検索する:

1. `docs/adr/`
2. `docs/decisions/`
3. `doc/arch/`
4. `adr/`

見つからない場合は「ADRディレクトリが見つかりません。`/adr:create` でADRを作成してください。」と案内する。

### 2. ADRファイルの読み取り

検出したディレクトリ内のすべての `.md` ファイルを読み取り、YAMLフロントマターから以下の情報を抽出する:

- `status`
- `date`
- `y-statement`（あれば）

### 3. 一覧の表示

以下の形式でテーブルを出力する:

| # | タイトル | ステータス | 日付 | Y-Statement要約 |
| --- | --- | --- | --- | --- |
| 0000 | ... | accepted | 2026-03-08 | ... |

### 4. フィルタリング（オプション）

$ARGUMENTS にステータスが指定されている場合（例: `accepted`, `proposed`）、そのステータスのADRのみ表示する。

### 5. サマリー

一覧の末尾に以下の集計を表示する:

```
合計: N件（proposed: X, accepted: Y, superseded: Z, ...）
```

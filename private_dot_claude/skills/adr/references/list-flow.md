# ADR 一覧表示フロー

プロジェクト内の既存ADRを一覧表示する対話フロー。

## Context（実行前に取得する情報）

```bash
# 既存ADRディレクトリ
ls -d docs/adr/ docs/decisions/ doc/arch/ adr/ 2>/dev/null | head -1
```

ユーザーがフィルタ条件（status 指定など）を指定している場合は、それを Step 4 で適用する。

## Step 1: ADRディレクトリの検出

以下の順序でADRディレクトリを検索する：

1. `docs/adr/`
2. `docs/decisions/`
3. `doc/arch/`
4. `adr/`

見つからない場合は「ADRディレクトリが見つかりません。新規にADRを作成する場合は `create-flow.md` のフローへ。」と案内する。

## Step 2: ADRファイルの読み取り

検出したディレクトリ内のすべての `.md` ファイルを読み取り、YAML frontmatter から以下の情報を抽出する：

- `status` — 公式 MADR の書式 `proposed | rejected | accepted | deprecated | superseded by ADR-NNNN` のいずれか
- `date`
- `y-statement`（あれば）

## Step 3: 一覧の表示

以下の形式でテーブルを出力する：

| # | タイトル | ステータス | 日付 | Y-Statement要約 |
| --- | --- | --- | --- | --- |
| 0000 | ... | accepted | 2026-03-08 | ... |
| 0002 | ... | superseded by ADR-0005 | 2026-03-10 | ... |

ステータス列は frontmatter の値をそのまま表示する（`superseded by ADR-NNNN` の形式を維持）。

## Step 4: フィルタリング（オプション）

ユーザーがステータスを指定している場合、そのステータスのADRのみ表示する：

- `proposed`, `accepted`, `rejected`, `deprecated` — 完全一致
- `superseded` — `superseded by ADR-` で始まる全てのADRをマッチ

## Step 5: サマリー集計

一覧の末尾に以下の集計を表示する。`superseded by ADR-NNNN` は集計上 `superseded` としてカウントする：

```
合計: N件（proposed: X, accepted: Y, superseded: Z, deprecated: W, rejected: V）
```

---
name: notes-context-init
description: notes worktree に新規の `context/<NNN>_<prefix>_<name>/` コンテキストを CONTEXT.md 付きで作成する。ユーザーが「コンテキスト作成」「notes コンテキスト初期化」「新しい作業を始める」「notes に新規作成」等と依頼したときに使用する。
allowed-tools: "Read,Write,Bash,Glob"
disable-model-invocation: true
---

# notes-context-init

notes worktree の `context/` 配下に新規コンテキストディレクトリを CONTEXT.md 付きで作成する。

## 前提

- `.worktrees/notes/` が展開済みであること（未展開なら `~/.claude/rules/notes.md` のセットアップ手順に従う）
- 作業対象は notes worktree の **content ルート**（以下 `<ROOT>`）配下。新規フラット構成なら `<ROOT>` = `.worktrees/notes/`、旧構成の repo に `.worktrees/notes/.notes/` があればその内側が `<ROOT>`（詳細は `notes-system` スキル）

## 手順

### 1. ヒアリング

ユーザーから以下を取得する：

- **prefix**: ブランチの種別セグメント。git skill の「ブランチ命名規則」に従う（その repo が Git-Flow なら `feature` / `bugfix` 等、それ以外なら `feat` / `fix` / `refactor` / `docs` / `chore` 等）
- **name**: kebab-case の短い名前
- **目的・背景**: 1〜2文

### 2. 連番を決定

`<ROOT>/context/` を `Glob` で走査し、既存の最大連番 + 1（3桁ゼロ埋め）を採番。

### 3. ディレクトリと CONTEXT.md を作成

コンテキストディレクトリを作成し、その直下に CONTEXT.md を置く。

```text
<ROOT>/context/<NNN>_<prefix>_<name>/
└── CONTEXT.md
```

**サブレイヤー（intent/ plan/ research/ requirements/ deliberation/ conversation/ spec/ evidence/ assets/）は事前に作らない。** 必要になった時点で都度作る。

CONTEXT.md のフォーマット（frontmatter と 目的 / 背景 セクション）は `notes-system` スキルの「CONTEXT.md フォーマット」セクションを参照する（二重管理を避けるため本文には転記しない）。初期値は `status: not_started`、`branch: <prefix>/<name>`、`created_at` / `updated_at` は当日の日付とし、目的・背景はヒアリング内容で埋める。

### 4. コミット

worktree 内（`.worktrees/notes/`）で `git add` / `git commit` する。コミットメッセージ例：

```text
chore(notes): <NNN>_<prefix>_<name> コンテキストを初期化
```

## 注意

- 作るのは CONTEXT.md のみ。各サブレイヤーは必要になった時点で都度作る
- ブランチを切るかは別判断（コンテキスト作成 ≠ ブランチ作成）
- 既存コンテキストへの追記なら、このスキルではなく該当番号のディレクトリに直接追記する

---
name: notes-context-init
description: 新規の `.notes/<NNN>_<prefix>_<name>/` コンテキストを意思決定レイヤー（intent/）と検証レイヤー（evidence/）のスケルトン付きで作成する。ユーザーが「コンテキスト作成」「notes コンテキスト初期化」「新しい作業を始める」「.notes に新規作成」等と依頼したときに使用する。
allowed-tools: "Read,Write,Bash,Glob"
disable-model-invocation: true
---

# notes-context-init

`.notes/` 配下に新規コンテキストディレクトリを intent/ と evidence/ のスケルトン付きで作成する。

## 前提

- `.worktrees/notes/` が展開済みであること（未展開なら `~/.claude/rules/notes.md` のセットアップ手順に従う）
- 作業対象パスは `.worktrees/notes/.notes/` 配下

## 手順

### 1. ヒアリング

ユーザーから以下を取得する：

- **prefix**: `feature` / `fix` / `refactor` / `docs` / `chore` のいずれか
- **name**: kebab-case の短い名前
- **目的・背景**: 1〜2文

### 2. 連番を決定

`.worktrees/notes/.notes/` を `Glob` で走査し、既存の最大連番 + 1（3桁ゼロ埋め）を採番。

### 3. ディレクトリ作成

以下のスケルトンを作成する。空ディレクトリは `.gitkeep` で保持する。

```text
.worktrees/notes/.notes/<NNN>_<prefix>_<name>/
├── CONTEXT.md
├── intent/
│   ├── goal.md
│   ├── constraints.md
│   └── decisions/.gitkeep
└── evidence/
    ├── tests/.gitkeep
    ├── incidents/.gitkeep
    └── ops-learnings.md
```

**Execution 系（plan/ research/ requirements/ deliberation/ conversation/ spec/）は事前に作らない。** 必要になった時点で都度作る。軽いタスクで Intent / Evidence が不要なら、それらも省略してよい。

### 4. CONTEXT.md の初期内容

CONTEXT.md のフォーマット（frontmatter と 目的 / 背景 セクション）は `notes-system` スキルの「CONTEXT.md フォーマット」セクションを参照する（二重管理を避けるため本文には転記しない）。初期値は `status: not_started`、`branch: <prefix>/<name>`、`created_at` / `updated_at` は当日の日付とし、目的・背景はヒアリング内容で埋める。

### 5. intent/goal.md の初期内容

```markdown
# Goal

## Outcome（達成したい成果）

<TBD>

## Opportunities（解決すべき機会・問題）

- <TBD>

## スコープ（視点・視野・視座・ペルソナ）

- 主語（視座）: <TBD>
- カバー範囲（視野）: <TBD>
- 主な評価観点（視点）: <TBD>
- 想定する受け手（ペルソナ）: <TBD>

軸の定義と使い分けは `~/.claude/skills/perspective/` を参照。
```

### 6. intent/constraints.md の初期内容

```markdown
# Constraints

## 不変条件（変えてはいけないもの）

- <TBD>

## 前提（検証済み）

- <TBD>

## 仮説（未検証）

- <TBD>
```

### 7. evidence/ops-learnings.md の初期内容

```markdown
# Ops Learnings

このコンテキストで得られた、運用・実装上の知見を蓄積する。
普遍化すべきものが見えたら、機能完了時に `intent/decisions/` の軽量 ADR、
あるいは `~/.claude/rules/` への昇格を検討する（archive-to-canonical skill）。
```

### 8. コミット

worktree 内（`.worktrees/notes/`）で `git add` / `git commit` する。コミットメッセージ例：

```text
chore(notes): <NNN>_<prefix>_<name> コンテキストを初期化
```

## 注意

- **すべてのファイルを必ず作る義務はない**。最小は CONTEXT.md のみ。Intent / Evidence は必要に応じて
- ブランチを切るかは別判断（コンテキスト作成 ≠ ブランチ作成）
- 既存コンテキストへの追記なら、このスキルではなく該当番号のディレクトリに直接追記する

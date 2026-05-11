# .notes

作業コンテキスト（ブランチ相当の作業単位）を管理するディレクトリ。
`.notes/` は専用の `notes` ブランチ上で管理し、worktree 経由でアクセスする。

正式なドキュメントは `docs/` 配下に配置し、検討中・個人作業のメモ・ノート類はこの `.notes/` 配下にコンテキスト単位で集約する。
メモ・research・deliberation 等もすべてこのコンテキスト配下に集約する（コンテキストとの紐づきを切らないため、別ディレクトリには切り出さない）。

## セットアップ

`.notes/` ディレクトリを使う前に、以下の手順で環境を準備する。
既にセットアップ済みの場合はスキップする。

### 1. notes ブランチの作成（存在しない場合）

```bash
# orphan ブランチとして作成（コードの履歴と完全に分離）
git switch --orphan notes
git commit --allow-empty -m "chore: notes ブランチを初期化"

# 元のブランチに戻る
git switch -
```

### 2. .gitignore への追加（現在のブランチで）

`.worktrees/` がまだ `.gitignore` に含まれていない場合は、worktree 展開前に追加しておく。
これは現在の作業ブランチ（main 等）で行う。

```bash
echo '.worktrees/' >> .gitignore
```

### 3. worktree の展開

```bash
# .worktrees/notes に worktree を展開
git worktree add .worktrees/notes notes
```

### セットアップ後のパス

- **worktree ルート**: `.worktrees/notes/`
- **コンテキスト格納先**: `.worktrees/notes/.notes/context/`
- CLAUDE.md 等で `.notes/...` と記載されているパスは、すべて `.worktrees/notes/.notes/...` に読み替える

## 構造

```text
.notes/
└── context/
    └── <NNN>_<prefix>_<name>/
        ├── CONTEXT.md           # メタ情報（目的、背景、ステータス等）
        ├── intent/              # 意思決定レイヤー
        │   ├── goal.md          #   outcome / opportunities
        │   ├── constraints.md   #   制約
        │   └── decisions/       #   軽量ADR（YYYY-MM-DD-<topic>.md）
        ├── plan/                # 計画・実装設計
        ├── research/            # 調査・技術検証
        ├── requirements/        # 要望・要件
        ├── deliberation/        # 検討・比較
        ├── conversation/        # 会話ログ
        ├── spec/                # 仕様（検討中。正式版は docs/ へ）
        └── evidence/            # 検証・学びの集積レイヤー
            ├── tests/           #   eval task 群（実失敗 20–50 件）
            ├── incidents/       #   失敗ログ
            └── ops-learnings.md #   運用知見
```

コンテキストは必ず `.notes/context/` 配下に置く。`.notes/` 直下にコンテキストディレクトリを作らない（将来 `.notes/` 直下を別用途に使えるよう、中間層 `context/` を維持する）。

`intent/` と `evidence/` は必要に応じて追加するもので、すべてのコンテキストで揃える必要はない（軽いタスクなら従来通り plan/ や research/ だけでよい）。

## CONTEXT.md フォーマット

```markdown
---
status: not_started  # not_started | in_progress | done | on_hold | canceled
branch: feature/add-auth
issue: "#123"
pr: "#456"
tags: [auth, security]
created_at: 2026-02-15
updated_at: 2026-02-15
---

## 目的

このコンテキストで達成したいこと。

## 背景

なぜこの作業が必要になったか。
```

## 命名規則

- **コンテキスト**: `<連番>_<prefix>_<name>`（例: `.notes/context/001_feature_add-auth`）
- **ファイル**: `<対象名>_YYYY-MM-DD.md`

### prefix 一覧

| prefix | 用途 |
| --- | --- |
| `feature` | 新機能 |
| `fix` | バグ修正 |
| `refactor` | リファクタリング |
| `docs` | ドキュメント |
| `chore` | その他 |

## 運用

- 新しい作業を始める際、連番を振ってコンテキストを作成
- ブランチを作成する場合、コンテキスト名とブランチ名を一致させる
- ブランチを作成しない場合でも、同じ形式で命名
- 既存コンテキストへの追記は、その番号のディレクトリに行う
- plan 確定後、plan ファイルを該当コンテキストの `plan/` に保存
- コンテキストへの変更は notes ブランチ上でコミットする（worktree 内で `git add` / `git commit`）
- worktree が展開されていない場合（`.worktrees/notes/` が存在しない場合）は、セットアップ手順に従って展開してから作業する
- 検討が固まり正式化する内容は `docs/` 配下へ昇格させる

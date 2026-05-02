# .workspace/context

作業コンテキスト（ブランチ相当の作業単位）を管理するディレクトリ。
`.workspace/` は専用の `workspace` ブランチ上で管理し、worktree 経由でアクセスする。

## セットアップ

`.workspace/` ディレクトリを使う前に、以下の手順で環境を準備する。
既にセットアップ済みの場合はスキップする。

### 1. workspace ブランチの作成（存在しない場合）

```bash
# orphan ブランチとして作成（コードの履歴と完全に分離）
git switch --orphan workspace
git commit --allow-empty -m "chore: workspace ブランチを初期化"

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
# .worktrees/workspace に worktree を展開
git worktree add .worktrees/workspace workspace
```

### セットアップ後のパス

- **worktree ルート**: `.worktrees/workspace/`
- **コンテキスト格納先**: `.worktrees/workspace/.workspace/context/`
- CLAUDE.md 等で `.workspace/context/...` と記載されているパスは、すべて `.worktrees/workspace/.workspace/context/...` に読み替える

## 構造

```text
.workspace/context/<NNN>_<prefix>_<name>/
├── CONTEXT.md           # メタ情報（目的、背景、ステータス等）
├── plan/                # 計画・実装設計
├── research/            # 調査・技術検証
├── requirements/        # 要望・要件
├── deliberation/        # 検討・比較
├── conversation/        # 会話ログ
└── spec/                # 仕様
```

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

- **コンテキスト**: `<連番>_<prefix>_<name>`（例: `001_feature_add-auth`）
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
- plan確定後、planファイルを該当コンテキストの `plan/` に保存
- コンテキストへの変更は workspace ブランチ上でコミットする（worktree 内で `git add` / `git commit`）
- worktree が展開されていない場合（`.worktrees/workspace/` が存在しない場合）は、セットアップ手順に従って展開してから作業する

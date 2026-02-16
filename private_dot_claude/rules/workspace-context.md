# .workspace/context

作業コンテキスト（ブランチ相当の作業単位）を管理するディレクトリ。

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

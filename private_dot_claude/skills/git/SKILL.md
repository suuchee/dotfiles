---
name: git
description: This skill should be used when the user asks to "commit", "git commit", "コミット", "git init", "リポジトリ初期化", "ブランチ作成", "amend", "ステージング", "git add", or mentions Git operations like staging, committing, branching, or amending commits.
---

# Git Workflow

Git操作における規約とワークフローを定義する。

## 概要

このスキルは以下の場面で使用する：
- コミットの作成
- リポジトリの初期化
- ブランチの作成・管理
- ステージングとコミット設計
- amend操作

## Git 初期化

新しいリポジトリを初期化する場合：

```sh
git init
git branch -m main
git commit --allow-empty -m "first commit"
```

## ステージング

無関係の変更がコミットに入り込まないよう、必ずそのタスク内での変更ファイルのみを対象としてステージングする。

**推奨**: `git add -A` や `git add .` ではなく、ファイルを個別に指定する。

## コミット前の確認

コミット前に必ず以下を確認する：

1. **現在のブランチを確認** - 適切なブランチにいるか
   - main/master/develop ブランチや、変更内容と異なるブランチの場合は、新規ブランチ作成または適切なブランチへの移動を提案
2. **変更範囲の確認** - タスクに関連する変更のみか
3. **コミット粒度の確認** - revert可能な段階的設計か
4. **不要ファイルの有無** - 意図しないファイルが含まれていないか

## コミット設計

一貫性のある履歴を残すため、**revert 可能な段階的コミット設計** を行う。

コミット設計時にユーザーと確認する項目：
- 変更範囲
- コミット粒度
- 不要ファイルの有無

未コミットの変更はそのままにしておき、コミット時はそのタスク内で変更したファイルのみをコミットする。

## コミットメッセージ

コミットメッセージは `references/commit-conventions.md` の規約に従う。

主要なルール：
- 可能な限り、その変更の理由を記述する
- 日本語の場合は文章の途中に改行を入れない
- フォーマット: `<type>(<scope>): <description>`

## ファイルの移動・名前変更

Git管理下にあるファイルやディレクトリの名前の変更・移動は `git mv` コマンドを使う。

```sh
git mv old-name.txt new-name.txt
```

## amend 操作

amend は以下の条件を満たす場合のみ使用する：

1. ユーザーが明示的に amend を指示した場合
2. この会話内で作成したコミットである（author名ではなく会話の文脈で判断）
3. リモートに push 済みでない（force push が必要になるため）

## 参考資料

### References

詳細な規約は以下を参照：
- **`references/commit-conventions.md`** - コミットメッセージのプレフィックスとフォーマット

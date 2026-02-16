---
name: github
description: This skill should be used when the user asks to "create PR", "PR作成", "create issue", "Issue作成", "gh コマンド", "GitHub CLI", "ラベル付け", "PRレビュー", or mentions GitHub operations like creating issues, pull requests, or using gh CLI.
---

# GitHub Workflow

GitHub操作における規約とワークフローを定義する。

## 概要

このスキルは以下の場面で使用する：
- Issue の作成・管理
- Pull Request の作成・レビュー
- GitHub CLI（gh コマンド）の使用
- ラベル付け

## 基本方針

GitHub の操作は、可能な限り **gh コマンドで統一** する。

Issue も PR も **原則 gh を使う**。

```sh
# Issue 作成
gh issue create --title "タイトル" --body "説明"

# PR 作成
gh pr create --title "タイトル" --body "説明"

# PR 一覧
gh pr list

# Issue 一覧
gh issue list
```

## Issue ラベル

Issue 発行時は適切なラベルを付与する。

詳細なラベル定義は `references/github-labels.md` を参照。

主要なラベル：
- `bug` - 仕様に反する不具合
- `enhancement` - 新機能・改善
- `documentation` - ドキュメントのみ

**注意**: ラベル付けの前に、リポジトリの性質（アプリケーション / インフラ / ライブラリ等）を把握すること。

## Pull Request

### PR レビュー基準

- 設計の妥当性
- 責務分離
- 破壊的変更の有無
- テストの有無

### PR 説明の編集

PR の body（説明）を変更する場合は、現在の状態を確認してから編集する。

理由：CodeRabbit AI などが既に編集している可能性があるため。

```sh
# 現在のPR情報を確認
gh pr view <number>

# PR説明を編集
gh pr edit <number> --body "新しい説明"
```

## 参考資料

### References

詳細な規約は以下を参照：
- **`references/github-labels.md`** - Issue ラベルの定義と使用条件

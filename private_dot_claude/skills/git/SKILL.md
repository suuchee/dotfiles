---
name: git
description: Git 操作全般（commit / branch / staging / amend / rebase / merge / cherry-pick など）で使用する。
allowed-tools: "Read,Grep,Glob"
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

新しいリポジトリを初期化する場合は `references/init-checklist.md` に従う。

## .gitignore の置き場所

無視したいパスは以下の 3 層から選ぶ：

| パターンの性質 | 置き場所 | 共有 |
| --- | --- | --- |
| プロジェクトに必須・全 contributor 共有 | リポジトリの `.gitignore` | コミット対象 |
| 個人の全 repo 共通 | global ignore (`~/.config/git/ignore`) | しない |
| 個人かつこの clone 限定 | `.git/info/exclude` | しない |

個人パターン（`.DS_Store`、`.worktrees/`、個人スクラッチディレクトリ等）は `.gitignore` に書かない。後から入った contributor のエディタ・ローカル運用を強制することになるため。

## ブランチ戦略

ブランチの選択・切替・性格変更の判断と操作。状況に応じて以下を参照する。

- 既存ブランチで作業を始めるか、新ブランチを切るか
- 作業ブランチの性格が当初想定と変わった場合のリカバリ
- 既コミットを別ブランチに分離する手段 (cherry-pick / 部分リセット 等)

詳細な判断フロー・操作・具体例は `references/branch-strategy.md` を参照。

## ステージング

無関係の変更がコミットに入り込まないよう、必ずそのタスク内での変更ファイルのみを対象としてステージングする。

**推奨**: `git add -A` や `git add .` ではなく、ファイルを個別に指定する。

### 既にステージング済みの変更がある場合

index に今回のコミット対象外の変更が残っている場合、勝手に `git restore --staged` 等で解除しない。

**なぜ**: 残っている staged 変更はユーザーまたは別セッションが意図的にステージした可能性がある。解除するとその意図を破壊する。

コミット対象の切り分け・検出・対処は `references/commit-isolation.md` を参照。

## コミット前の確認

コミット前に必ず以下を確認する：

1. **現在のブランチを確認** - 適切なブランチにいるか
   - main/master/develop ブランチや、変更内容と異なるブランチの場合は、新規ブランチ作成または適切なブランチへの移動を提案
2. **変更範囲の確認** - タスクに関連する変更のみか
   - `git status --short` の **index 列**（左列）を確認する
   - タスク外 path があれば pathspec 指定コミットを検討する
   - 同一ファイル内の混在があれば hunk 数を確認する（`git diff --cached <file> | grep -c '^@@'`）
   - 判断フロー・対処の詳細は `references/commit-isolation.md` を参照
3. **コミット粒度の確認** - revert 可能な段階的設計か（判断基準は「[コミット粒度の判断基準](#コミット粒度の判断基準)」を参照）
4. **不要ファイルの有無** - 意図しないファイルが含まれていないか

## コミット設計

一貫性のある履歴を残すため、**revert 可能な段階的コミット設計** を行う。

コミット設計時にユーザーと確認する項目：
- 変更範囲
- コミット粒度
- 不要ファイルの有無

未コミットの変更はそのままにしておき、コミット時はそのタスク内で変更したファイルのみをコミットする（pathspec による切り分けは `references/commit-isolation.md` を参照）。

### コミット粒度の判断基準

粒度設計の原則（1 ブランチ = 1 単位）と例外（複数単位が混ざる場合のコミット統合）、および「戻しやすさを目的とする」理由は `references/revert-granularity.md` を参照。

## コミットメッセージ

コミットメッセージは `references/commit-rules.md` の運用ルールに従う。

### 起点とする差分

コミットメッセージは **そのコミットに含まれる差分（最終状態の差分）を起点に書く**。過去の経緯、当初の意図、セッション内の作業の流れではなく、「このコミットを後から見た人が、`git show` の差分とメッセージを照合して誤解しないか」で判断する。

| 状況 | 起点とする差分 |
| --- | --- |
| 通常コミット | `git diff --cached`（staged 差分） |
| amend | `git diff HEAD~1`（amend 後の最終差分） |
| 統合コミット（`git reset --soft` → commit） | `git diff <統合ベース>`（統合後の最終差分） |

差分を見ずにメッセージを書くと、過去の意図やセッション内の経緯に引っ張られて、最終状態と乖離した説明になる。amend や統合コミットで特に起きやすい。

### 主要なルール

- 可能な限り、その変更の理由を記述する
- 日本語の場合は文章の途中に改行を入れない
- フォーマット: `<type>(<scope>): <description>`（作業途中は `wip(<scope>): <description>`。ドラフトはブランチ名の `-draft` サフィックス）

## ファイルの移動・名前変更

Git管理下にあるファイルやディレクトリの名前の変更・移動は `git mv` コマンドを使う。

```sh
git mv old-name.txt new-name.txt
```

## push 操作

コミットと push は**常に別の操作として実行**する。1つのコマンドで `git commit && git push` のようにチェインしない。

### push 時の注意

- PR が既に発行されているブランチでは `--force-with-lease` や `--force` を**使用しない**
  - レビュー中のコミット履歴が書き換わり、レビュアーに混乱を与えるため
  - 修正が必要な場合は新しいコミットを追加する
- force push が許容されるのは、PR 発行前のローカルブランチのみ

## amend 操作

直前コミットへの追記・修正の判断と操作。状況に応じて以下を参照する。

- amend を使う条件（明示指示・スコープ同一性・未 push）
- amend 時のコミットメッセージの起点
- `--no-edit` を使ってよい場面・使ってはいけない場面

詳細な条件・使い分け・典型的な失敗パターンは `references/amend.md` を参照。

## cherry-pick 後のブランチ整理

feature ブランチのコミットを別ブランチ（develop 等）に cherry-pick した場合、feature ブランチ側の該当コミットを除去する。

### 除去対象が先頭（HEAD）にある場合 → `git reset`

```sh
git reset --soft HEAD~1   # 変更をステージに残す（内容確認用）
git restore --staged .     # ステージを解除
git checkout -- .          # 作業ツリーもクリーンに
```

シンプルかつ確実。rebase は不要。

### 除去対象が中間にある場合 → `git rebase -i`

```
A - B - C(除去したい) - D - E (HEAD)
```

`reset` は HEAD から巻き戻すだけなので、中間のコミットだけを除去することはできない。この場合は `git rebase -i` で対象コミットを `drop` する。

```sh
git rebase -i HEAD~3   # C を含む範囲を指定
# エディタで C の行を削除または `drop` に変更して保存
```

## マージ戦略

作業ブランチを統合する際の `--no-ff` / `--ff-only` / `--squash` / rebase + ff の選択指針。

詳細は `references/merge-strategy.md` を参照。

## Worktree のリネーム

worktree のディレクトリ名・ブランチ名を変更する手順は `references/worktree-rename.md` を参照。

## 参考資料

### References

詳細な運用ルールは以下を参照：
- **`references/commit-rules.md`** - コミットメッセージ・ブランチ命名の運用ルール
- **`references/commit-isolation.md`** - コミット対象の切り分け・隔離（index 確認、pathspec コミット、混入時の対処）

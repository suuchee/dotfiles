# Git リポジトリ初期化チェックリスト

新しいリポジトリを初期化する場合、以下を順番に実施する。

## 1. リポジトリ作成

```sh
git init
git branch -m main
```

## 2. Git LFS のセットアップ

バイナリファイルが後からコミットされると LFS 移行が困難になるため、最初のコミット前に LFS を設定する。
LFS 導入前の確認事項は `~/.claude/rules/git-tips.md` の「Git LFS（Large File Storage）」セクションを参照。

```sh
git lfs install --local
git lfs track "*.mp4" "*.mov" "*.mp3" "*.m4a" "*.wav" "*.png" "*.jpg" "*.jpeg" "*.pdf"
```

## 3. .gitignore の基本設定

プロジェクト固有・全 contributor 共有のパターンのみ書く（言語/フレームワークの生成物、ビルド成果物、依存物等）。個人パターン（`.DS_Store`、`.worktrees/` 等）は書かない。判断基準は `../SKILL.md` の「.gitignore の置き場所」参照。

init 直後でプロジェクト固有の ignore がまだ無い場合はこの手順をスキップする。

## 4. 最初のコミット

`.gitattributes` はメディアファイルを `git add` する前にコミットすること。

```sh
git add .gitattributes .gitignore  # 存在するもののみ
git commit --allow-empty -m "first commit"
```

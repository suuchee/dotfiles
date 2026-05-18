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

```sh
echo '.worktrees/' >> .gitignore
```

## 4. 最初のコミット

`.gitattributes` はメディアファイルを `git add` する前にコミットすること。

```sh
git add .gitattributes .gitignore
git commit --allow-empty -m "first commit"
```

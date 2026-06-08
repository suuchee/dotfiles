# Worktree のリネーム

既存 worktree のディレクトリ名や、worktree が checkout しているブランチ名を変更する手順。

## 基本方針: `git worktree move` を使う

ディレクトリ名だけ変えたい場合は単純に `git worktree move` でリネームする。`mv` で物理ディレクトリだけ動かすと内部の `.git` ファイルが古い gitdir パスを指したままになり手動修復が必要になるため、**必ず `git worktree move` を使う**。

```bash
git worktree move <old-path> <new-path>
```

**例**:

```bash
git worktree move .worktrees/workspace .worktrees/notes
```

## ブランチ名と worktree パスを同時に変えたい場合

「ブランチ `workspace` を `notes` にリネーム → worktree も `.worktrees/workspace/` から `.worktrees/notes/` にリネーム」のような同時リネームでは、**`git worktree add` を先に呼んではいけない**。リネーム後の `notes` ブランチは既存 worktree が checkout 中のため `fatal: 'notes' is already used by worktree at ...` で失敗する。

正しい順序:

```bash
# 1. ブランチをリネーム
git branch -m workspace notes

# 2. worktree ディレクトリも合わせてリネーム
git worktree move .worktrees/workspace .worktrees/notes
```

`git worktree move` は内部 `.git` ファイル（`gitdir:` 行）も自動で書き換えるため、手動の編集は不要。

## 補足: `.git/worktrees/<name>/` メタデータ名

`git worktree move` は worktree のパスは変えるが、`.git/worktrees/<name>/` 内部メタデータディレクトリ名はそのまま維持する。機能には影響しないが、命名の整合を取りたい場合のみ手動で:

```bash
mv .git/worktrees/<old-name> .git/worktrees/<new-name>
printf 'gitdir: %s/.git/worktrees/<new-name>\n' "$(git rev-parse --show-toplevel)" \
  > <worktree-path>/.git
```

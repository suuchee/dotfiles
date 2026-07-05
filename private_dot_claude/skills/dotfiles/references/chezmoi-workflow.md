# chezmoi 作業フロー

## リポジトリの場所

| 項目 | パス |
| --- | --- |
| chezmoi ソース（デフォルト） | `~/.local/share/chezmoi` |
| worktree の置き場 | `<repo>/.worktrees/<topic>/` |

`.worktrees/` は global gitignore（`~/.config/git/ignore`）で除外する。リポジトリの `.gitignore` には書かない。

## どのリポジトリからでもメンテできる

ユーザーが別プロジェクトのセッションから dotfiles 変更を依頼しても、**編集対象は chezmoi ソース**である。

1. chezmoi リポに worktree を用意する（未作成なら下記）
2. その worktree でブランチを切り、ソースを編集・コミット
3. `chezmoi apply` でホームへ反映
4. 必要なら PR（github skill 参照）

## worktree の作成（main から）

```bash
cd ~/.local/share/chezmoi

# 例: feat/my-dotfiles-change ブランチを worktree に
git worktree add -b feat/my-dotfiles-change .worktrees/my-dotfiles-change main
cd .worktrees/my-dotfiles-change
```

既存ブランチを worktree に載せる場合:

```bash
git worktree add .worktrees/my-dotfiles-change feat/my-dotfiles-change
```

worktree のリネームは `git worktree move` を使う（`mv` だけは禁止）。詳細は git skill の `references/worktree-rename.md`。

## ブランチ方針

- dotfiles の機能追加・設定改善は **`main` から** feature / chore ブランチを切る
- 他の作業ブランチ（例: `docs/commit-isolation`）に無関係な変更を混ぜない
- 並行セッションがあるときは **必ず worktree** で分離する

## 変更 → 反映の流れ

```bash
# 1. ソースを編集（worktree 内）
$EDITOR private_dot_claude/settings.json

# 2. 差分確認（ターゲットパスでも可）
chezmoi diff private_dot_claude/settings.json
chezmoi diff ~/.claude/settings.json

# 3. ドライラン
chezmoi apply -nv ~/.claude/settings.json

# 4. 適用
chezmoi apply -v ~/.claude/settings.json
```

ホームで直接直した場合は、ソースへ取り込む:

```bash
chezmoi add ~/.claude/settings.json
# または chezmoi add --force（既存ソースを上書き）
```

## apply 前の確認

- `chezmoi diff` で意図しないファイルが含まれていないか
- 秘密情報（トークン、鍵）がソースに入っていないか
- テンプレート（`.tmpl`）は `chezmoi execute-template` で展開結果を確認

## Bash で worktree を行き来するとき

Claude Code の Bash は **CWD がコマンド間で持続**する。

- 既に `.worktrees/foo/` 内にいるなら、再度 `cd .worktrees/foo` しない
- worktree 外に出たあと戻るときは、リポジトリルートから `cd .worktrees/foo` または絶対パスを使う

## コミット

- git skill の規約に従う（Conventional Commits、コミット分離）

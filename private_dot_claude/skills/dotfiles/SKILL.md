---
name: dotfiles
description: chezmoi で管理する dotfiles（~/.local/share/chezmoi）の変更・追加・適用を行うときに使用する。ユーザーが「dotfiles」「chezmoi」「chezmoi apply」「設定をホームに反映」「~/.claude や ~/.cursor の設定を直す」「エージェント設定のメンテ」「~/.agents のレイアウト」と言ったとき、またはどのリポジトリからでも個人設定の改善を依頼したときに読む。
allowed-tools: "Read,Grep,Glob,Bash"
---

# Dotfiles（chezmoi）

個人 dotfiles を chezmoi で管理するためのスキル。**作業対象は常に chezmoi ソースリポジトリ**（`~/.local/share/chezmoi`）である。今いるプロジェクトリポジトリとは別。

## いつ使うか

- ホームディレクトリ配下の設定（`~/.claude`、`~/.cursor`、`~/.agents`、`~/.zshrc` 等）を変えたい
- chezmoi のソースにファイルを追加・更新したい
- エージェント横断設定（hooks / skills）の置き場所を決めたい
- `chezmoi diff` / `chezmoi apply` の手順を踏みたい

通常のプロジェクト開発だけならこのスキルは不要。

## 作業の入口

1. **chezmoi リポへ移動** — `cd ~/.local/share/chezmoi`（または既に checkout 済み worktree）
2. **worktree で作業** — 他ブランチと並行する、または別リポから依頼された場合は `references/chezmoi-workflow.md` の worktree 手順に従う
3. **main からブランチ** — dotfiles 変更用ブランチは `main` から切る（例: `feat/...`、`chore/...`）
4. **詳細を読む** — 手順は `references/`、エージェント設定の正本ルールは `references/agent-layout.md`

## 原則

- **`chezmoi diff` を先に見る**。`chezmoi apply` は元に戻せない
- **`chezmoi add` はソースへ取り込む方向**（ホーム → ソース）、**`chezmoi apply` は展開**（ソース → ホーム）
- 変更は **chezmoi ソースツリー上のファイル**を編集する。ホームだけ直して終わらない（`chezmoi add` またはソース直編集 → apply）
- コミットは **変更の性格ごとに分離**（git skill の commit-isolation 参照）
- エージェント横断の正本は **`~/.agents/`**（chezmoi では `private_dot_agents/`）。詳細は `references/agent-layout.md`

## chezmoi ソースの命名（要点）

| プレフィックス | 展開先の例 |
| --- | --- |
| `dot_` | `~/.zshrc` |
| `private_dot_` | `~/.claude/...` |
| `private_dot_agents/` | `~/.agents/` |
| `executable_` | 実行ビット付きで展開 |
| `*.tmpl` | テンプレート（`chezmoi execute-template`） |

詳細は `references/source-naming.md`。

## よく使うコマンド

```bash
# リポジトリルート（worktree ならそのパス）
CHEZMOI_SRC=~/.local/share/chezmoi

chezmoi diff
chezmoi diff ~/.claude
chezmoi apply -nv ~/.claude    # ドライラン
chezmoi apply -v ~/.claude     # 適用

chezmoi add ~/.zshrc           # ホームの現状をソースへ
chezmoi add --force ~/.zshrc   # 既存ソースを上書き

chezmoi source-path private_dot_claude/settings.json
chezmoi target-path private_dot_claude/settings.json
```

対話付き apply にはリポジトリの `scripts/chezmoi-apply-source.sh` も使える。

## Additional Resources

- **`references/chezmoi-workflow.md`** — worktree 作成、ブランチ、apply 前チェック、並行セッション
- **`references/agent-layout.md`** — `~/.agents` 正本、hooks / skills の配置、ツール別ラッパー
- **`references/source-naming.md`** — chezmoi ソースのプレフィックスとディレクトリ対応
- リポジトリ内 **`docs/agent-config.md`** — メンテ用のソースツリー対応表（存在する場合）
- リポジトリ内 **`README.md`** — chezmoi 基本コマンド

# chezmoi ソースの命名

このリポジトリ（`~/.local/share/chezmoi`）での主なプレフィックスと展開先。

## プレフィックス

| パターン | 意味 |
| --- | --- |
| `dot_` | ホーム直下のドットファイル（`dot_zshrc` → `~/.zshrc`） |
| `private_dot_` | ホーム直下のプライベートディレクトリ（`private_dot_claude` → `~/.claude`） |
| `dot_config/` | `~/.config/` 配下 |
| `private_Library/` | macOS `~/Library/` 配下 |
| `executable_` | 実行権限付きで展開（`executable_safe-rm.sh` → `safe-rm.sh`） |
| `*.tmpl` | Go テンプレート。`chezmoi execute-template` で確認 |
| `run_once_*.tmpl` | 初回 apply 時のみ実行されるスクリプト |

## よく触るディレクトリ

| ソース | 展開先 |
| --- | --- |
| `private_dot_claude/` | `~/.claude/` |
| `private_dot_cursor/` | `~/.cursor/` |
| `private_dot_agents/` | `~/.agents/` |
| `dot_config/git/ignore` | `~/.config/git/ignore` |
| `scripts/` | chezmoi リポ内のみ（ホームへは展開しない） |
| `docs/` | chezmoi リポ内のみ |
| `.notes/` | chezmoi リポ内のみ（`dot_` なしのためホームへ展開されない） |

## パスの確認コマンド

```bash
chezmoi source-path private_dot_claude/settings.json
chezmoi target-path private_dot_claude/settings.json
chezmoi managed | grep claude
```

## .chezmoiignore

テンプレートや OS 条件でソースから除外する。編集前に対象ファイルが ignore されていないか確認する。

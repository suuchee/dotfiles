# ~/.agents — エージェント横断設定の正本

Claude Code / Cursor / Codex など複数ツールで共有する設定の**正本**は `~/.agents/` に置く。

各ツールは自前の dot-dir（`~/.claude/`、`~/.cursor/`、`~/.codex/`）からここを参照する。ツール固有の設定だけを各 dot-dir に残す。

## ディレクトリ

| パス | 用途 | 読み手 |
| --- | --- | --- |
| `hooks/` | 共有フックスクリプト本体 | 各ツールの `hooks/` ラッパー経由 |
| `skills/` | Agent Skills（`SKILL.md`） | Codex / Cursor は直接。Claude Code は `~/.claude/skills` 経由（下記） |

## ツール別の参照関係

| 種別 | 正本 | ツール側（薄いラッパーまたは symlink） |
| --- | --- | --- |
| hooks | `~/.agents/hooks/` | `~/.claude/hooks/`、`~/.cursor/hooks/`、`~/.codex/hooks/` |
| skills | `~/.agents/skills/` | `~/.claude/skills/` → symlink 推奨。`~/.cursor/skills/` も同様可 |

フックは JSON のイベント名・フィールド名がツールごとに異なるため、**本体は共有・登録は各ツール**とする。ラッパーは `HOOK_FORMAT` など環境変数だけを渡す。

## chezmoi での管理

| 展開先 | chezmoi ソース |
| --- | --- |
| `~/.agents/` | `private_dot_agents/` |
| `~/.claude/hooks/` 等 | `private_dot_claude/`（ラッパーのみ） |
| `~/.cursor/hooks/` 等 | `private_dot_cursor/`（ラッパーのみ） |

メンテナンス手順の詳細は chezmoi リポジトリの `docs/agent-config.md` を参照。

## 外部インストールとの共存

`npx skills add` などは `~/.agents/skills/` に入る。chezmoi 管理のスキルと混在する場合は、名前の衝突に注意する。

## 関連標準

- [Agent Skills](https://agentskills.io/) — `SKILL.md` フォーマット
- [Codex skills](https://developers.openai.com/codex/skills/) — `~/.agents/skills` を USER スコープとして公式サポート
- [Cursor skills](https://cursor.com/docs/context/skills) — `~/.agents/skills` と `~/.cursor/skills` の両方をサポート

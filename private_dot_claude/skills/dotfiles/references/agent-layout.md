# エージェント横断設定のレイアウト

## 方針

Claude Code / Cursor / Codex など**複数ツールで共有**する設定の正本は `~/.agents/` に置く。

各ツールは自前の dot-dir（`~/.claude/`、`~/.cursor/`、`~/.codex/`）からここを参照する。ツール固有の登録だけ各 dot-dir に残す。

## ディレクトリ

| パス | 用途 |
| --- | --- |
| `~/.agents/hooks/` | 共有フックスクリプト本体 |
| `~/.agents/skills/` | Agent Skills 正本（Codex / Cursor は直接読む） |

## ツール別

| 種別 | 正本 | ツール側 |
| --- | --- | --- |
| hooks | `~/.agents/hooks/` | `~/.claude/hooks/`、`~/.cursor/hooks/`、`~/.codex/hooks/`（ラッパー） |
| skills | `~/.agents/skills/` | `~/.claude/skills/` → symlink 推奨 |

フックはイベント名・JSON フィールドがツールごとに異なる。**本体は共有・登録は各ツール**。ラッパーは `HOOK_FORMAT` 等の環境変数だけ渡す。

## chezmoi ソース対応

```
private_dot_agents/          → ~/.agents/
  hooks/                       共有フック本体
  skills/                      （移行後）共有スキル正本

private_dot_claude/          → ~/.claude/
  hooks/                       ラッパーのみ
  skills/                      現状はここが正本（移行後は symlink）

private_dot_cursor/          → ~/.cursor/
  hooks.json                   hook 登録
  hooks/                       ラッパーのみ
```

## 共有フックの追加手順

1. 本体を `private_dot_agents/hooks/executable_<name>.sh` に追加
2. ラッパーを `private_dot_{claude,cursor}/hooks/executable_<name>.sh` に追加

   ```bash
   #!/usr/bin/env bash
   exec env HOOK_FORMAT=claude "$HOME/.agents/hooks/<name>.sh"
   ```

3. 各ツールの hook 登録（`settings.json` / `hooks.json` / `~/.codex/hooks.json`）にエントリ追加
4. `chezmoi apply` で `~/.agents/hooks/` と各ラッパーを反映

## 外部インストールとの共存

`npx skills add` は `~/.agents/skills/` に入る。chezmoi 管理スキルと**名前の衝突**に注意。

## 参照

- `~/.agents/README.md`（展開後）— 正本の自己説明
- chezmoi リポ `docs/agent-config.md` — メンテ用対応表

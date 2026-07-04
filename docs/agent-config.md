# エージェント設定のレイアウト（chezmoi）

dotfiles メンテ時は **`dotfiles` skill**（`~/.claude/skills/dotfiles/`）を読む。

## 方針

ツール横断の設定は **`~/.agents/` を正本**とする。chezmoi ソースは `private_dot_agents/`。

ツール固有の登録（`hooks.json`、`settings.json` の hook 定義など）は各 `private_dot_{claude,cursor,codex}/` に置き、実体は `~/.agents/` を指すラッパーまたは symlink にする。

## ソースツリー対応

```
private_dot_agents/          → ~/.agents/
  README.md                    方針（正本の自己説明）
  hooks/                       共有フック本体
  skills/                      （将来）共有スキル正本

private_dot_claude/          → ~/.claude/
  hooks/                       HOOK_FORMAT=claude のラッパーのみ
  skills/                      現状はここが正本。移行後は ~/.agents/skills への symlink

private_dot_cursor/          → ~/.cursor/
  hooks.json                   Cursor 用 hook 登録
  hooks/                       HOOK_FORMAT=cursor のラッパーのみ

private_dot_local/           → 廃止予定（~/.agents へ統合済みのものは削除）
```

## 新規追加時の手順

### 共有フック

1. 本体を `private_dot_agents/hooks/executable_<name>.sh` に追加
2. 各ツール用ラッパーを `private_dot_{claude,cursor}/hooks/executable_<name>.sh` に追加（`exec` で `~/.agents/hooks/<name>.sh` を呼ぶ）
3. 各ツールの hook 登録ファイルにエントリを追加

### 共有スキル（移行後）

1. `private_dot_agents/skills/<skill>/SKILL.md` に正本を置く
2. `~/.claude/skills/<skill>` を `~/.agents/skills/<skill>` への symlink にする（chezmoi の `link_` プレフィックス等を検討）
3. `npx skills` で入れたスキルと名前が被らないか確認

## 参照

- 正本の説明: `~/.agents/README.md`（`private_dot_agents/README.md`）
- 作業手順: `private_dot_claude/skills/dotfiles/SKILL.md`

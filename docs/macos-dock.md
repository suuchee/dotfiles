# macOS Dock 設定

## スクリプト

| スクリプト | 説明 |
|---|---|
| `scripts/dock/backup-dock.sh` | Dock設定をバックアップ |
| `scripts/dock/setup-dock.sh` | Dock設定を適用（実行前に自動バックアップ） |
| `scripts/dock/restore-dock.sh` | バックアップから復元 |

## 使い方

```bash
# バックアップ
task dock:backup

# 適用 (要: brew install dockutil)
task dock:setup

# 復元（最新のバックアップから）
task dock:restore
```

## 設定を更新するとき

1. `defaults read com.apple.dock > dock.txt` で現在の設定をエクスポート
   - Dockアプリ一覧だけでなく、ホットコーナー (`wvous-*`) 等の設定もすべて含まれる
2. `dock.txt` の内容をClaudeに渡して `setup-dock.sh` を更新してもらう
3. 動作確認後 `dock.txt` は削除してOK

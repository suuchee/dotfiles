#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/bak"

if [ $# -ge 1 ]; then
  BACKUP_FILE="$1"
else
  # 引数なしの場合、最新のバックアップを使用
  BACKUP_FILE="$(ls -t "$BACKUP_DIR"/dock-*.plist 2>/dev/null | head -1)"
  if [ -z "$BACKUP_FILE" ]; then
    echo "Error: バックアップが見つかりません"
    echo "Usage: $0 [backup.plist]"
    exit 1
  fi
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Error: ファイルが見つかりません: $BACKUP_FILE"
  exit 1
fi

defaults import com.apple.dock "$BACKUP_FILE"
killall Dock

echo "Dock設定を復元しました: $BACKUP_FILE"

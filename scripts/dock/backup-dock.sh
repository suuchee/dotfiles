#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/bak"

mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/dock-$(date +%Y%m%d-%H%M%S).plist"
defaults export com.apple.dock "$BACKUP_FILE"
echo "Dock設定をバックアップしました: $BACKUP_FILE"

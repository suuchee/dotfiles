#!/bin/bash
# chezmoi apply をソースパスのまま実行するユーティリティ
# 使い方: ./scripts/chezmoi-apply-source.sh <ソースパス>...
# 例: ./scripts/chezmoi-apply-source.sh private_Library/private_Application\ Support/private_Code/User/settings.json

set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <source-path>..." >&2
  exit 1
fi

target="$(chezmoi target-path "$@")"

diff_output="$(chezmoi diff "$target" 2>&1)" || true
if [[ -z "$diff_output" ]]; then
  echo "変更がないためスキップします"
  exit 0
fi

echo "$diff_output"
echo ""
read -rp "適用しますか？ [y/N] " answer
if [[ "$answer" =~ ^[yY]$ ]]; then
  chezmoi apply "$target"
else
  echo "キャンセルしました"
fi

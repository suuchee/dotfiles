#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- dockutil チェック ---
if ! command -v dockutil &>/dev/null; then
  echo "Error: dockutil がインストールされていません"
  echo "  brew install dockutil"
  exit 1
fi

# --- バックアップ ---
bash "$SCRIPT_DIR/backup-dock.sh"

# --- Dock全体の設定 ---
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock largesize -int 56
defaults write com.apple.dock tilesize -int 35
defaults write com.apple.dock orientation -string left
defaults write com.apple.dock mineffect -string suck
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock expose-group-apps -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock showDesktopGestureEnabled -bool false
defaults write com.apple.dock showLaunchpadGestureEnabled -bool false

# ホットコーナー (tl=11:Launchpad, tr=2:MissionControl, bl=4:Desktop, br=5:ScreenSaver)
defaults write com.apple.dock wvous-tl-corner -int 11
defaults write com.apple.dock wvous-tl-modifier -int 0
defaults write com.apple.dock wvous-tr-corner -int 2
defaults write com.apple.dock wvous-tr-modifier -int 0
defaults write com.apple.dock wvous-bl-corner -int 4
defaults write com.apple.dock wvous-bl-modifier -int 0
defaults write com.apple.dock wvous-br-corner -int 5
defaults write com.apple.dock wvous-br-modifier -int 0

# --- persistent-apps を設定 ---
apps=()
APPS_CONF="$SCRIPT_DIR/dock-apps.conf"
if [ ! -f "$APPS_CONF" ]; then
  echo "Error: $APPS_CONF が見つかりません"
  exit 1
fi

while IFS= read -r app; do
  [[ -z "$app" || "$app" == \#* ]] && continue
  apps+=("$app")
done < "$APPS_CONF"

if [ ${#apps[@]} -eq 0 ]; then
  echo "Error: $APPS_CONF にアプリが定義されていません。Dockの変更を中止します"
  exit 1
fi

dockutil --remove all --no-restart

for app in "${apps[@]}"; do
  if [ -d "$app" ]; then
    dockutil --add "$app" --no-restart
  else
    echo "Warning: $app が見つかりません。スキップします"
  fi
done

# --- persistent-others (ダウンロードフォルダ) ---
dockutil --add ~/Downloads --view list --sort datemodified --no-restart

# --- Dock再起動 ---
killall Dock

echo "Dock設定を適用しました"
echo "復元するには: bash $SCRIPT_DIR/restore-dock.sh $SCRIPT_DIR/bak/<バックアップファイル>"

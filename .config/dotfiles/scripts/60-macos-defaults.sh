#!/usr/bin/env bash
# macOS preferences. Re-run any time: every write is idempotent.
set -euo pipefail
# shellcheck source=../lib/helpers.sh
. "${DOTFILES_DIR:-$HOME/.config/dotfiles}/lib/helpers.sh"
require_macos

w() { run defaults write "$@"; }

log "Keyboard and text"
w NSGlobalDomain AppleShowAllExtensions -bool true
w NSGlobalDomain KeyRepeat -int 2
w NSGlobalDomain InitialKeyRepeat -int 15
w NSGlobalDomain ApplePressAndHoldEnabled -bool false
w NSGlobalDomain AppleKeyboardUIMode -int 3
w NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
w NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
w NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
w NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

log "Trackpad"
w com.apple.AppleMultitouchTrackpad Clicking -bool true
w com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
w NSGlobalDomain com.apple.mouse.tapBehavior -int 1

log "Finder"
w com.apple.finder AppleShowAllFiles -bool true
w com.apple.finder ShowPathbar -bool true
w com.apple.finder ShowStatusBar -bool true
w com.apple.finder FXPreferredViewStyle -string "Nlsv"
w com.apple.finder FXDefaultSearchScope -string "SCcf"
w com.apple.finder _FXSortFoldersFirst -bool true
w com.apple.finder FXEnableExtensionChangeWarning -bool false
w com.apple.finder NewWindowTarget -string "PfHm"
w com.apple.desktopservices DSDontWriteNetworkStores -bool true
w com.apple.desktopservices DSDontWriteUSBStores -bool true

log "Screenshots"
run mkdir -p "$HOME/Pictures/Screenshots"
w com.apple.screencapture location -string "$HOME/Pictures/Screenshots"
w com.apple.screencapture type -string "png"
w com.apple.screencapture disable-shadow -bool true

log "Dock behaviour"
w com.apple.dock autohide -bool true
w com.apple.dock autohide-delay -float 0
w com.apple.dock show-recents -bool false
w com.apple.dock mru-spaces -bool false
w com.apple.dock tilesize -int 48

if [ "$DRY_RUN" != "1" ]; then
  for app in Finder Dock SystemUIServer; do killall "$app" >/dev/null 2>&1 || true; done
fi
ok "macOS defaults applied (some need a log out to take effect)"

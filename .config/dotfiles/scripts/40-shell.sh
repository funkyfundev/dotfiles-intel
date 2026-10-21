#!/usr/bin/env bash
# zsh as login shell, plugin cache, iTerm2 profile.
set -euo pipefail
# shellcheck source=../lib/helpers.sh
. "${DOTFILES_DIR:-$HOME/.config/dotfiles}/lib/helpers.sh"
require_macos
load_brew

# Login shell: macOS already defaults to zsh.
if [ "$(basename "${SHELL:-}")" != "zsh" ]; then
  log "Switching login shell to /bin/zsh"
  run chsh -s /bin/zsh
else
  skip "login shell is already zsh"
fi

# Warm the antidote plugin cache so the first prompt is fast.
if have antidote && [ -f "$HOME/.config/zsh/.zshrc" ]; then
  log "Warming zsh plugin cache"
  run env ZDOTDIR="$HOME/.config/zsh" /bin/zsh -i -c 'exit' || warn "zsh warm-up reported an error"
fi

# iTerm2: make the tracked dynamic profile the default.
GUID="6E1D2F8A-5C3B-4D7E-9A41-DF0715C0DE01"
PROFILE_JSON="$HOME/Library/Application Support/iTerm2/DynamicProfiles/dotfiles.json"
if [ -f "$PROFILE_JSON" ]; then
  run defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "$GUID"
  run defaults write com.googlecode.iterm2 NoSyncNeverRemindPrompt -bool true
  ok "iTerm2 default profile set (restart iTerm2 to apply)"
else
  warn "iTerm2 profile not found at $PROFILE_JSON"
fi

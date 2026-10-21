#!/usr/bin/env bash
# Rebuild the Dock once. Re-run on purpose with: DOCK_FORCE=1 install.sh --only 70
set -euo pipefail
# shellcheck source=../lib/helpers.sh
. "${DOTFILES_DIR:-$HOME/.config/dotfiles}/lib/helpers.sh"
require_macos
load_brew

MARKER="$DOTFILES_DIR/.dock-done"
if [ -f "$MARKER" ] && [ "${DOCK_FORCE:-0}" != "1" ]; then
  skip "Dock already set up (use DOCK_FORCE=1 to rebuild)"
  exit 0
fi
have dockutil || { warn "dockutil not found; skipping Dock"; exit 0; }

APPS=(
  "/Applications/iTerm.app"
  "/Applications/Visual Studio Code.app"
  "/Applications/Google Chrome.app"
  "/Applications/Microsoft Edge.app"
  "/Applications/Microsoft Teams.app"
  "/Applications/Microsoft Word.app"
  "/Applications/Microsoft Excel.app"
  "/Applications/Claude.app"
  "/Applications/ChatGPT.app"
  "/System/Applications/System Settings.app"
)

log "Rebuilding the Dock"
run dockutil --remove all --no-restart
for app in "${APPS[@]}"; do
  if [ -d "$app" ]; then
    run dockutil --add "$app" --no-restart
  else
    skip "not installed: $(basename "$app")"
  fi
done
[ "$DRY_RUN" = "1" ] || { killall Dock >/dev/null 2>&1 || true; touch "$MARKER"; }
ok "Dock rebuilt"

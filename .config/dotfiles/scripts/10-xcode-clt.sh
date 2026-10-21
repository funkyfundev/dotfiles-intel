#!/usr/bin/env bash
# Xcode Command Line Tools (git, clang, make).
set -euo pipefail
# shellcheck source=../lib/helpers.sh
. "${DOTFILES_DIR:-$HOME/.config/dotfiles}/lib/helpers.sh"
require_macos

if xcode-select -p >/dev/null 2>&1; then
  skip "Command Line Tools already installed"
  exit 0
fi
log "Installing Command Line Tools (accept the dialog that appears)"
run xcode-select --install || true
if [ "$DRY_RUN" != "1" ]; then
  until xcode-select -p >/dev/null 2>&1; do sleep 10; done
fi
ok "Command Line Tools installed"

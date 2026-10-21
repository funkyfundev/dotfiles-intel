#!/usr/bin/env bash
# Install packages from the Brewfiles in ~/.config/dotfiles/brew.
# Apps are installed only if missing, so apps pushed by device management are left alone.
set -euo pipefail
# shellcheck source=../lib/helpers.sh
. "${DOTFILES_DIR:-$HOME/.config/dotfiles}/lib/helpers.sh"
require_macos
load_brew
if ! have brew; then
  [ "$DRY_RUN" = "1" ] && { skip "Homebrew not installed yet (dry-run); packages would be installed here"; exit 0; }
  die "Homebrew not found. Run: install.sh --only 20"
fi

if is_intel; then
  log "Intel Mac: CLI tools that Homebrew would compile are installed by mise in step 50"
  [ "$(macos_major)" -lt 14 ] && warn "macOS $(macos_major) is too old for Docker Desktop; Colima + docker CLI are installed instead"
fi

PROFILE="${PROFILE:-$(profile_get PROFILE)}"
export PROFILE="${PROFILE:-work}"
# Brewfiles read these through ENV[...]
export HOMEBREW_NO_AUTO_UPDATE=1

failed=()
for name in core dev ops apps; do
  file="$DOTFILES_DIR/brew/Brewfile.$name"
  [ -f "$file" ] || continue
  log "brew bundle: $name"
  if [ "$DRY_RUN" = "1" ]; then
    brew bundle list --all --file="$file" | sed 's/^/    /' || true
    continue
  fi
  if ! brew bundle --file="$file"; then
    warn "Some items in Brewfile.$name failed (for example App Store apps need you to be signed in)"
    failed+=("$name")
  fi
done

if [ "${#failed[@]}" -gt 0 ]; then
  warn "Brewfiles with failures: ${failed[*]}. Fix and re-run: install.sh --only 30"
  exit 1
fi
ok "Packages installed"

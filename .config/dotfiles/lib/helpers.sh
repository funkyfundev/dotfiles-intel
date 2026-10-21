#!/usr/bin/env bash
# Shared helpers for the dotfiles installer. Source this file; do not run it.

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.config/dotfiles}"
LOCAL_PROFILE="$DOTFILES_DIR/profile.local"
DRY_RUN="${DRY_RUN:-0}"

if [ -t 1 ]; then
  C_RESET=$'\033[0m'; C_BLUE=$'\033[34m'; C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'; C_DIM=$'\033[2m'
else
  C_RESET=""; C_BLUE=""; C_GREEN=""; C_YELLOW=""; C_RED=""; C_DIM=""
fi

log()  { printf '%s==>%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
ok()   { printf '%s ok%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
skip() { printf '%s -- %s%s\n' "$C_DIM" "$*" "$C_RESET"; }
warn() { printf '%s !!%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
err()  { printf '%s xx%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
die()  { err "$*"; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# Run a command, or only print it when --dry-run is set.
run() {
  if [ "$DRY_RUN" = "1" ]; then
    printf '%s[dry-run]%s %s\n' "$C_DIM" "$C_RESET" "$*"
    return 0
  fi
  "$@"
}

# True when a terminal is available for questions (also works under curl | bash).
have_tty() { ( : </dev/tty ) 2>/dev/null; }

# confirm "Question?" [default y|n]
confirm() {
  local prompt="$1" default="${2:-n}" reply hint="[y/N]"
  [ "$default" = "y" ] && hint="[Y/n]"
  if ! have_tty || [ "${ASSUME_YES:-0}" = "1" ]; then
    [ "$default" = "y" ]; return
  fi
  printf '%s %s ' "$prompt" "$hint" >/dev/tty
  read -r reply </dev/tty || reply=""
  reply="${reply:-$default}"
  case "$reply" in [Yy]*) return 0 ;; *) return 1 ;; esac
}

# ask VAR "Question" "default"  -> sets VAR
ask() {
  local var="$1" prompt="$2" default="${3:-}" reply=""
  if have_tty; then
    printf '%s [%s]: ' "$prompt" "$default" >/dev/tty
    read -r reply </dev/tty || reply=""
  fi
  printf -v "$var" '%s' "${reply:-$default}"
}

# Read KEY from profile.local (empty when missing).
profile_get() {
  [ -f "$LOCAL_PROFILE" ] || return 0
  sed -n "s/^$1=//p" "$LOCAL_PROFILE" | tail -n 1 | tr -d '"'
}

# Set or replace KEY=value in profile.local.
profile_set() {
  local key="$1" value="$2"
  [ "$DRY_RUN" = "1" ] && { skip "would set $key=$value in profile.local"; return 0; }
  mkdir -p "$DOTFILES_DIR"
  touch "$LOCAL_PROFILE"
  if grep -q "^$key=" "$LOCAL_PROFILE"; then
    sed -i.bak "s|^$key=.*|$key=$value|" "$LOCAL_PROFILE" && rm -f "$LOCAL_PROFILE.bak"
  else
    printf '%s=%s\n' "$key" "$value" >>"$LOCAL_PROFILE"
  fi
}

# Is an app bundle present in /Applications or ~/Applications?
app_installed() { [ -d "/Applications/$1.app" ] || [ -d "$HOME/Applications/$1.app" ]; }

# Put Homebrew on PATH for this process (Apple Silicon or Intel).
load_brew() {
  if have brew; then return 0; fi
  if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then eval "$(/usr/local/bin/brew shellenv)"
  fi
}

# Load pinned versions (AZ_CLI_VERSION etc.).
load_versions() {
  # shellcheck source=/dev/null
  [ -f "$DOTFILES_DIR/versions.env" ] && . "$DOTFILES_DIR/versions.env"
  return 0
}

# CPU of the real hardware: arm64 (Apple Silicon) or x86_64 (Intel).
# A Terminal running under Rosetta reports x86_64 from uname, so ask the kernel first.
detect_arch() {
  if [ "$(sysctl -n hw.optional.arm64 2>/dev/null || true)" = "1" ]; then echo arm64; else uname -m; fi
}
is_intel() { [ "${DOTFILES_ARCH:-}" = "x86_64" ]; }

# Major macOS version (14, 15, 26 ...). Prints 0 when unknown.
macos_major() { sw_vers -productVersion 2>/dev/null | cut -d. -f1 | grep -E '^[0-9]+$' || echo 0; }

# Homebrew prefix for this CPU, used only when brew is not on PATH yet.
brew_prefix_default() { if is_intel; then echo /usr/local; else echo /opt/homebrew; fi; }

# Intel Macs get a second mise config (config.intel.toml) with prebuilt binaries,
# because Homebrew only supports Intel as a best-effort "Tier 3" platform.
DOTFILES_ARCH="${DOTFILES_ARCH:-$(detect_arch)}"
export DOTFILES_ARCH
if is_intel; then export MISE_ENV=intel; fi

# Make mise-installed tools usable inside installer scripts (no shell hook there).
load_mise() {
  export PATH="$HOME/.local/share/mise/shims:$PATH"
}

require_macos() {
  [ "$(uname -s)" = "Darwin" ] || die "This installer only runs on macOS."
}

# Keep sudo alive while the installer runs.
sudo_keepalive() {
  [ "$DRY_RUN" = "1" ] && return 0
  have_tty || return 0
  sudo -v </dev/tty || { warn "sudo not available; admin-only steps will be skipped"; return 0; }
  ( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &
}

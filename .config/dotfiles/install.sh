#!/usr/bin/env bash
# Run the numbered install scripts in order. Safe to re-run.
#
#   install.sh [--profile work|personal] [--only N[,N]] [--skip N[,N]] [--dry-run] [--yes]
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.config/dotfiles}"
export DOTFILES_DIR
# shellcheck source=lib/helpers.sh
. "$DOTFILES_DIR/lib/helpers.sh"

ONLY=""; SKIP=""; PROFILE_ARG=""
DRY_RUN=0; ASSUME_YES=0

usage() {
  sed -n '2,4p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --only)    ONLY="$2"; shift 2 ;;
    --skip)    SKIP="$2"; shift 2 ;;
    --profile) PROFILE_ARG="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --yes|-y)  ASSUME_YES=1; shift ;;
    -h|--help) usage 0 ;;
    *) err "Unknown option: $1"; usage 1 ;;
  esac
done
export DRY_RUN ASSUME_YES

require_macos
LOG="$HOME/Library/Logs/dotfiles-install.log"
mkdir -p "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1
log "Dotfiles install started $(date '+%Y-%m-%d %H:%M:%S') (dry-run=$DRY_RUN)"

# --- local, untracked files -------------------------------------------------
ensure_local_files() {
  local t="$DOTFILES_DIR/templates"
  [ "$DRY_RUN" = "1" ] && { skip "would create missing *.local files from templates"; return 0; }
  mkdir -p "$HOME/.config/git" "$HOME/.ssh"; chmod 700 "$HOME/.ssh"
  [ -f "$LOCAL_PROFILE" ]             || cp "$t/profile.local.example"    "$LOCAL_PROFILE"
  [ -f "$HOME/.zshrc.local" ]         || cp "$t/zshrc.local.example"      "$HOME/.zshrc.local"
  [ -f "$HOME/.config/git/config.local" ] || cp "$t/gitconfig.local.example" "$HOME/.config/git/config.local"
  [ -f "$HOME/.ssh/config.local" ]    || { cp "$t/ssh_config.local.example" "$HOME/.ssh/config.local"; chmod 600 "$HOME/.ssh/config.local"; }
}
ensure_local_files

# --- profile ----------------------------------------------------------------
PROFILE="${PROFILE_ARG:-$(profile_get PROFILE)}"
if [ -z "$PROFILE" ]; then
  ask PROFILE "Profile (work or personal)" "work"
fi
case "$PROFILE" in work|personal) ;; *) die "Profile must be 'work' or 'personal' (got '$PROFILE')." ;; esac
profile_set PROFILE "$PROFILE"
export PROFILE
log "Profile: $PROFILE"

# --- git identity (only asked once) ------------------------------------------
GIT_LOCAL="$HOME/.config/git/config.local"
if [ "$DRY_RUN" != "1" ] && ! grep -q '^\s*email\s*=' "$GIT_LOCAL" 2>/dev/null; then
  ask GIT_NAME  "Git name"  "${GIT_NAME:-}"
  ask GIT_EMAIL "Git email" "${GIT_EMAIL:-}"
  if [ -n "$GIT_NAME" ] && [ -n "$GIT_EMAIL" ]; then
    printf '[user]\n\tname = %s\n\temail = %s\n' "$GIT_NAME" "$GIT_EMAIL" >"$GIT_LOCAL"
  else
    warn "Git name/email not set; edit $GIT_LOCAL later."
  fi
fi

sudo_keepalive

# --- run steps --------------------------------------------------------------
in_list() { case ",$2," in *",$1,"*) return 0 ;; *) return 1 ;; esac; }

failed=()
for script in "$DOTFILES_DIR"/scripts/[0-9][0-9]-*.sh; do
  base="$(basename "$script")"; num="${base%%-*}"
  if [ -n "$ONLY" ] && ! in_list "$num" "$ONLY"; then continue; fi
  if [ -n "$SKIP" ] && in_list "$num" "$SKIP"; then skip "skipping $base"; continue; fi
  log "[$num] $base"
  if ! bash "$script"; then
    err "$base failed"; failed+=("$base")
  fi
done

if [ "${#failed[@]}" -gt 0 ]; then
  err "These steps failed: ${failed[*]}"
  err "Fix the cause and re-run, e.g.: install.sh --only ${failed[0]%%-*}"
  exit 1
fi
ok "All steps finished. Log: $LOG"

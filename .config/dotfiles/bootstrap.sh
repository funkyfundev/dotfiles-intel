#!/usr/bin/env bash
# Bootstrap a new Mac from the dotfiles repo.
#
#   curl -fsSL https://raw.githubusercontent.com/funkyfundev/dotfiles/main/.config/dotfiles/bootstrap.sh | bash
#
# Options (pass after "bash -s --"):  --profile work|personal  --dry-run  --only N  --skip N
# Environment: DOTFILES_REPO (clone URL), DOTFILES_BRANCH (default main)
set -euo pipefail

REPO="${DOTFILES_REPO:-https://github.com/funkyfundev/dotfiles.git}"
BRANCH="${DOTFILES_BRANCH:-main}"
GIT_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

say()  { printf '\033[34m==>\033[0m %s\n' "$*"; }
fail() { printf '\033[31m xx\033[0m %s\n' "$*" >&2; exit 1; }
dot()  { /usr/bin/git --git-dir="$GIT_DIR" --work-tree="$HOME" "$@"; }

[ "$(uname -s)" = "Darwin" ] || fail "This bootstrap only runs on macOS."
[ "$(id -u)" -ne 0 ] || fail "Run as your normal user, not root."

# 1. Xcode Command Line Tools (provide git)
if ! xcode-select -p >/dev/null 2>&1; then
  say "Installing Xcode Command Line Tools (a dialog will appear; click Install)"
  xcode-select --install >/dev/null 2>&1 || true
  until xcode-select -p >/dev/null 2>&1; do sleep 10; done
fi
[ -x /usr/bin/git ] || fail "git not found after installing the Command Line Tools."

# 2. Clone the bare repository
if [ -d "$GIT_DIR" ]; then
  say "$GIT_DIR already exists; fetching updates"
  dot fetch origin "$BRANCH"
else
  say "Cloning $REPO into $GIT_DIR"
  /usr/bin/git clone --bare --branch "$BRANCH" "$REPO" "$GIT_DIR"
fi
dot config status.showUntrackedFiles no

# 3. Back up files that would be overwritten, then check out
say "Checking out dotfiles into $HOME"
backed_up=0
while IFS= read -r f; do
  if [ -e "$HOME/$f" ] || [ -L "$HOME/$f" ]; then
    # Leave files that already match the repo copy exactly.
    if [ -f "$HOME/$f" ] && dot show "$BRANCH:$f" 2>/dev/null | cmp -s - "$HOME/$f"; then continue; fi
    mkdir -p "$BACKUP_DIR/$(dirname "$f")"
    mv "$HOME/$f" "$BACKUP_DIR/$f"
    backed_up=1
  fi
done < <(dot ls-tree -r --name-only "$BRANCH")
[ "$backed_up" -eq 0 ] || say "Existing files moved to $BACKUP_DIR"
dot checkout -f "$BRANCH" 2>/dev/null || dot checkout "$BRANCH"

# 4. Hand over to the installer (stdin is the pipe, so read answers from the terminal)
INSTALL="$HOME/.config/dotfiles/install.sh"
[ -f "$INSTALL" ] || fail "install.sh missing after checkout."
say "Running the installer"
if ( : </dev/tty ) 2>/dev/null; then
  exec bash "$INSTALL" "$@" </dev/tty
else
  exec bash "$INSTALL" "$@"
fi

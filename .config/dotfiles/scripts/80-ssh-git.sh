#!/usr/bin/env bash
# SSH key in the macOS Keychain, GitHub sign-in, SSH remote for the dotfiles repo.
set -euo pipefail
# shellcheck source=../lib/helpers.sh
. "${DOTFILES_DIR:-$HOME/.config/dotfiles}/lib/helpers.sh"
require_macos
load_brew

KEY="$HOME/.ssh/id_ed25519"
GIT_LOCAL="$HOME/.config/git/config.local"
mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"

email="$(git config --file "$GIT_LOCAL" user.email 2>/dev/null || true)"
if [ -f "$KEY" ]; then
  skip "SSH key already exists ($KEY)"
else
  log "Creating an ed25519 SSH key (you will be asked for a passphrase; it is stored in the Keychain)"
  if [ "$DRY_RUN" = "1" ]; then
    skip "would run: ssh-keygen -t ed25519"
  elif have_tty; then
    ssh-keygen -t ed25519 -C "${email:-$(whoami)@$(hostname -s)}" -f "$KEY" </dev/tty
  else
    warn "No terminal available; create the key later with: ssh-keygen -t ed25519"
  fi
fi
[ -f "$KEY" ] && run ssh-add --apple-use-keychain "$KEY" >/dev/null 2>&1 || true

# Use the key to sign commits.
if [ -f "$KEY.pub" ] && ! git config --file "$GIT_LOCAL" user.signingkey >/dev/null 2>&1; then
  run git config --file "$GIT_LOCAL" user.signingkey "$KEY.pub"
  run git config --file "$GIT_LOCAL" commit.gpgsign true
fi

# GitHub: sign in, upload the key for auth and for signing.
if have gh && [ -f "$KEY.pub" ]; then
  if ! gh auth status >/dev/null 2>&1; then
    if confirm "Sign in to GitHub now (opens a browser)?" y; then
      run gh auth login --hostname github.com --git-protocol ssh --web \
        --scopes admin:public_key,admin:ssh_signing_key
    fi
  fi
  if gh auth status >/dev/null 2>&1; then
    title="$(scutil --get ComputerName 2>/dev/null || hostname -s)"
    run gh ssh-key add "$KEY.pub" --title "$title" 2>/dev/null || skip "auth key already on GitHub"
    run gh ssh-key add "$KEY.pub" --type signing --title "$title (signing)" 2>/dev/null || skip "signing key already on GitHub"
    # Switch the dotfiles remote from HTTPS to SSH so you can push.
    if [ -d "$HOME/.dotfiles" ]; then
      run git --git-dir="$HOME/.dotfiles" remote set-url origin git@github.com:funkyfundev/dotfiles.git
      ok "dotfiles remote now uses SSH"
    fi
  else
    warn "Not signed in to GitHub; run: gh auth login   then: install.sh --only 80"
  fi
fi
ok "SSH and git ready"

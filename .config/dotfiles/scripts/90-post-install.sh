#!/usr/bin/env bash
# Touch ID for sudo, security checks, manual checklist.
set -euo pipefail
# shellcheck source=../lib/helpers.sh
. "${DOTFILES_DIR:-$HOME/.config/dotfiles}/lib/helpers.sh"
require_macos

# Touch ID for sudo (survives macOS updates via /etc/pam.d/sudo_local).
if [ -f /etc/pam.d/sudo_local ] && grep -q pam_tid.so /etc/pam.d/sudo_local; then
  skip "Touch ID for sudo already enabled"
elif confirm "Enable Touch ID for sudo?" y; then
  run sudo sh -c 'printf "auth       sufficient     pam_tid.so\n" > /etc/pam.d/sudo_local' \
    || warn "could not enable Touch ID for sudo (device management may block it)"
fi

# Report only; these may be managed by your organisation.
log "Security status (report only)"
fdesetup status 2>/dev/null | sed 's/^/    FileVault: /' || true
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | sed 's/^/    /' || true

cat <<'CHECKLIST'

==> Manual steps (cannot be automated)
  1. Restart the Mac once, so Dock, Finder and keyboard settings fully apply.
  2. Open iTerm2: the "Dotfiles" profile should be the default (Tokyo Night, Nerd Font).
  3. Sign in: 1Password, Microsoft 365 (Teams, Word, Excel), Edge, Chrome, Adobe Creative Cloud,
     Claude, ChatGPT, GitHub Copilot (VS Code), Claude Code (VS Code).
  4. OpenVPN Connect: import your .ovpn profile by hand (never commit it).
  5. UniFi endpoint (Ubiquiti): install it from IT / Ubiquiti, it is not in Homebrew.
  6. Amphetamine: if it was skipped, sign in to the App Store and run: install.sh --only 30
  7. Docker Desktop: open it once and accept the terms (free personal tier).
  8. Grant permissions when prompted: Rectangle and iTerm2 need Accessibility / Full Disk Access.
  9. 1Password: enable the CLI integration (Settings > Developer) and, optionally, the SSH agent.
 10. Azure: run  az login
 11. Optional aliases: run  dot-aliases enable   (or  dot-aliases enable git docker)
 12. Optional: switch the main editor with  dot-editor nvim

CHECKLIST
if is_intel; then
  cat <<'INTEL'
==> Intel Mac notes
  - Homebrew treats Intel as best-effort (Tier 3): new packages may build from source.
    Support is planned to end in September 2027, and macOS 26 (Tahoe) is the last Intel macOS.
  - CLI tools such as starship, fzf, ripgrep and neovim are managed by mise, not Homebrew.
    Update them with  dot-update  (it runs mise upgrade).
  - Brew-installed tools still update with  brew upgrade.

INTEL
fi
ok "Done"

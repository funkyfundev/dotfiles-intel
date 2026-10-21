#!/usr/bin/env bash
# Language runtimes from mise, then Azure CLI pinned to AZ_CLI_VERSION.
set -euo pipefail
# shellcheck source=../lib/helpers.sh
. "${DOTFILES_DIR:-$HOME/.config/dotfiles}/lib/helpers.sh"
require_macos
load_brew
load_versions
export PATH="$HOME/.local/bin:$PATH"
load_mise

if ! have mise; then
  [ "$DRY_RUN" = "1" ] && { skip "mise not installed yet (dry-run); runtimes and Azure CLI would be installed here"; exit 0; }
  die "mise not found. Run: install.sh --only 30"
fi
if is_intel; then
  log "Installing runtimes and Intel prebuilt tools (config.toml + config.intel.toml)"
else
  log "Installing runtimes from ~/.config/mise/config.toml"
fi
run mise install --yes

# --- Azure CLI (Homebrew only offers the latest, so pin through pipx) ---------
want="${AZ_CLI_VERSION:?AZ_CLI_VERSION missing from versions.env}"
have pipx || die "pipx not found. Run: install.sh --only 30"

current=""
if have az; then
  current="$(az version --query '"azure-cli"' -o tsv 2>/dev/null || true)"
fi
if [ "$current" = "$want" ]; then
  skip "Azure CLI $want already installed"
else
  log "Installing Azure CLI $want (found: ${current:-none})"
  if [ "$DRY_RUN" = "1" ]; then
    skip "would run: pipx install --force --python <mise python> azure-cli==$want"
  else
    py="$(mise which python 2>/dev/null || true)"
    [ -n "$py" ] || die "mise python not found"
    pipx install --force --python "$py" "azure-cli==$want"
    got="$(az version --query '"azure-cli"' -o tsv 2>/dev/null || true)"
    [ "$got" = "$want" ] || warn "az reports '$got', expected '$want'"
  fi
fi
ok "Runtimes ready"

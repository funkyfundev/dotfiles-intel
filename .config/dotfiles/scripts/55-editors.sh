#!/usr/bin/env bash
# VS Code extensions, Neovim plugins, command-line launchers, main editor.
set -euo pipefail
# shellcheck source=../lib/helpers.sh
. "${DOTFILES_DIR:-$HOME/.config/dotfiles}/lib/helpers.sh"
require_macos
load_brew
load_mise

BIN="$(brew --prefix 2>/dev/null || brew_prefix_default)/bin"
VSCODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
SUBL_BIN="/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl"

link_cli() {  # link_cli <source> <name>
  if [ -x "$1" ] && ! have "$2"; then
    run ln -sf "$1" "$BIN/$2" && ok "linked $2 into $BIN"
  fi
}
link_cli "$VSCODE_BIN" code
link_cli "$SUBL_BIN" subl

# --- VS Code extensions --------------------------------------------------------
LIST="$DOTFILES_DIR/editors/vscode-extensions.txt"
if have code && [ -f "$LIST" ]; then
  installed="$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')"
  while IFS= read -r line; do
    id="${line%%#*}"; id="$(echo "$id" | tr -d '[:space:]')"
    [ -n "$id" ] || continue
    if echo "$installed" | grep -qx "$(echo "$id" | tr '[:upper:]' '[:lower:]')"; then
      skip "$id already installed"
    else
      log "Installing VS Code extension $id"
      run code --install-extension "$id" >/dev/null || warn "could not install $id (check the ID)"
    fi
  done <"$LIST"
else
  warn "VS Code not found; skipping extensions"
fi

# --- Neovim plugins ------------------------------------------------------------
if have nvim; then
  log "Syncing Neovim plugins"
  run nvim --headless "+Lazy! sync" +qa || warn "Neovim plugin sync reported an error"
fi

# --- Main editor ---------------------------------------------------------------
if [ -z "$(profile_get MAIN_EDITOR)" ]; then
  profile_set MAIN_EDITOR code
  ok "MAIN_EDITOR=code (change later with: dot-editor nvim)"
fi

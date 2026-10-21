# Environment. Machine settings come from ~/.config/dotfiles/profile.local (not tracked).
export DOTFILES_DIR="$HOME/.config/dotfiles"
if [[ -f "$DOTFILES_DIR/profile.local" ]]; then
  set -a; source "$DOTFILES_DIR/profile.local"; set +a
fi

typeset -U path PATH
path=("$HOME/.local/bin" $path)

# Intel Macs (Homebrew lives in /usr/local): load the extra mise config and put mise shims on PATH,
# so tools installed by mise work before the mise hook runs. See mise/config.intel.toml.
if [[ "${HOMEBREW_PREFIX:-}" == "/usr/local" ]]; then
  export DOTFILES_ARCH="x86_64" MISE_ENV="intel"
  path=("$HOME/.local/share/mise/shims" $path)
fi

# Main editor: code (default) or nvim. Switch with: dot-editor nvim
export MAIN_EDITOR="${MAIN_EDITOR:-code}"
case "$MAIN_EDITOR" in
  nvim) export EDITOR="nvim" VISUAL="nvim" ;;
  *)    export EDITOR="code --wait" VISUAL="code --wait" ;;
esac

# Prompt: nerd (icons) or ascii. A bare Linux console cannot show icons.
if [[ "${PROMPT_STYLE:-nerd}" == "ascii" || "$TERM" == "linux" ]]; then
  export STARSHIP_CONFIG="$HOME/.config/starship-ascii.toml"
else
  export STARSHIP_CONFIG="$HOME/.config/starship.toml"
fi

export HOMEBREW_NO_ANALYTICS=1
export BAT_THEME="ansi"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border \
--color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7,fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff \
--color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff,marker:#9ece6a,spinner:#9ece6a,header:#9ece6a"
export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d --hidden --exclude .git"

# --- colours for file listings (Tokyo Night) ------------------------------------------------------
# CLICOLOR makes the stock macOS ls coloured. LS_COLORS (from vivid, cached) is read by eza, fd and
# zsh tab-completion.
export CLICOLOR=1
_ls_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/ls_colors"
if [[ ! -s "$_ls_cache" ]] && (( $+commands[vivid] )); then
  mkdir -p "${_ls_cache:h}" && vivid generate tokyonight-night > "$_ls_cache" 2>/dev/null
fi
[[ -s "$_ls_cache" ]] && export LS_COLORS="$(<"$_ls_cache")"
unset _ls_cache

# man pages through bat (coloured); falls back to the normal pager when bat is missing.
if (( $+commands[bat] )); then
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

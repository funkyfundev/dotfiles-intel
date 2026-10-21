# Interactive zsh. Order matters: exports, history, completion, plugins, tools, prompt, local.
ZSH_CFG="${ZDOTDIR:-$HOME/.config/zsh}"

source "$ZSH_CFG/exports.zsh"
source "$ZSH_CFG/functions.zsh"

# --- history -----------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY SHARE_HISTORY INC_APPEND_HISTORY \
       HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS INTERACTIVE_COMMENTS NO_BEEP

# --- completion (rebuild the dump at most once a day) -------------------------
autoload -Uz compinit
_zcd="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
mkdir -p "${_zcd:h}"
if [[ -n ${_zcd}(#qN.mh+24) ]]; then compinit -d "$_zcd"; else compinit -C -d "$_zcd"; fi
unset _zcd
source "$ZSH_CFG/completions.zsh"

# --- plugins (antidote) ---------------------------------------------------------
if [[ -r "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/antidote/share/antidote/antidote.zsh" ]]; then
  source "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/antidote/share/antidote/antidote.zsh"
  antidote load "$ZSH_CFG/.zsh_plugins.txt"
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey '^P' history-substring-search-up
  bindkey '^N' history-substring-search-down
fi

# --- tools -----------------------------------------------------------------------
(( $+commands[fzf] ))     && source <(fzf --zsh)       # Ctrl-R history, Ctrl-T files, Alt-C folders
(( $+commands[zoxide] ))  && eval "$(zoxide init zsh)" # z <name>, zi
(( $+commands[mise] ))    && eval "$(mise activate zsh)"
(( $+commands[starship] )) && eval "$(starship init zsh)"

# --- machine-specific (not tracked); optional aliases are enabled from here ---------
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

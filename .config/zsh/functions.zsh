# Core helpers. These are always on (not optional): the dotfiles repo cannot be managed without them.

# --- managing the dotfiles repo (bare repo in ~/.dotfiles, work tree = $HOME) ------------------
alias dot='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

# dot-add <file>...  Track files on purpose (the repo ignores everything by default) after a secret scan.
dot-add() {
  (( $# )) || { print -u2 "usage: dot-add <file>..."; return 1; }
  local f
  for f in "$@"; do
    if (( $+commands[gitleaks] )); then
      gitleaks detect --no-git --no-banner --source "$f" >/dev/null 2>&1 || {
        print -u2 "dot-add: possible secret found in $f; not added. Check it with: gitleaks detect --no-git --source $f"
        return 1
      }
    fi
    dot add -f -- "$f" && print "tracked: $f"
  done
}

# dot-sync ["message"]  Commit tracked changes, rebase on the remote, push.
dot-sync() {
  dot add -u || return
  if ! dot diff --cached --quiet; then
    dot commit -m "${1:-Update dotfiles}" || return
  fi
  dot pull --rebase && dot push
}

# dot-update  Pull the repo, then update packages, runtimes and plugins.
dot-update() {
  dot pull --rebase || return
  if (( $+commands[brew] )); then
    brew update && brew upgrade && brew bundle --file="$DOTFILES_DIR/brew/Brewfile.core" \
      && brew bundle --file="$DOTFILES_DIR/brew/Brewfile.dev" \
      && brew bundle --file="$DOTFILES_DIR/brew/Brewfile.ops"
  fi
  (( $+commands[mise] )) && mise upgrade
  (( $+commands[antidote] )) && antidote update
  print "Azure CLI is pinned (versions.env) and is not upgraded here. Change the pin, then run: install.sh --only 50"
}

# _dot_profile_set KEY VALUE  Write KEY=VALUE into profile.local.
_dot_profile_set() {
  local f="$DOTFILES_DIR/profile.local"
  touch "$f"
  if grep -q "^$1=" "$f"; then
    sed -i '' "s|^$1=.*|$1=$2|" "$f"
  else
    print "$1=$2" >> "$f"
  fi
}

# dot-editor code|nvim  Choose the main editor (used for EDITOR, VISUAL and the e/fe/rgi helpers).
dot-editor() {
  case "$1" in
    code|nvim) _dot_profile_set MAIN_EDITOR "$1"; export MAIN_EDITOR="$1"
               source "$ZSH_CFG/exports.zsh"; print "Main editor: $1 (EDITOR=$EDITOR)" ;;
    "") print "Main editor: ${MAIN_EDITOR:-code}" ;;
    *) print -u2 "usage: dot-editor code|nvim"; return 1 ;;
  esac
}

# prompt-style nerd|ascii  Switch the Starship prompt (nerd = icons, ascii = plain).
prompt-style() {
  case "$1" in
    nerd|ascii) _dot_profile_set PROMPT_STYLE "$1"; export PROMPT_STYLE="$1"
                source "$ZSH_CFG/exports.zsh"; print "Prompt style: $1" ;;
    "") print "Prompt style: ${PROMPT_STYLE:-nerd}" ;;
    *) print -u2 "usage: prompt-style nerd|ascii"; return 1 ;;
  esac
}

# dot-aliases enable [group...] | disable | list  Optional aliases, off by default.
# Groups: nav files macos git editors docker azure k8s terraform system. No group = all groups.
dot-aliases() {
  local rc="$HOME/.zshrc.local" start="# >>> dot-aliases >>>" end="# <<< dot-aliases <<<"
  local cmd="${1:-list}"; (( $# )) && shift
  _strip() { [[ -f "$rc" ]] && sed -i '' "/$start/,/$end/d" "$rc"; }
  case "$cmd" in
    enable)
      _strip; touch "$rc"
      { print "$start"
        (( $# )) && print "DOT_ALIAS_GROUPS=($*)"
        print 'source "$HOME/.config/zsh/aliases.zsh"'
        print "$end"; } >> "$rc"
      print "Optional aliases enabled${*:+ ($*)}. Open a new shell or run: exec zsh" ;;
    disable)
      _strip; print "Optional aliases disabled. Open a new shell to apply." ;;
    list)
      if grep -q "$start" "$rc" 2>/dev/null; then
        print "enabled: ${$(grep '^DOT_ALIAS_GROUPS=' "$rc" | sed 's/.*(\(.*\)).*/\1/'):-all groups}"
      else
        print "disabled (enable with: dot-aliases enable [group...])"
      fi
      print "groups: nav files macos git editors docker azure k8s terraform system" ;;
    *) print -u2 "usage: dot-aliases enable [group...] | disable | list"; return 1 ;;
  esac
  unfunction _strip 2>/dev/null
}

# secret_get <name>  Read a secret from 1Password (when signed in), else the macOS Keychain.
#   1Password item convention:  op://${SECRET_OP_VAULT:-Private}/<name>/credential
#   Keychain item convention:   security add-generic-password -a "$USER" -s <name> -w
secret_get() {
  local name="$1"
  [[ -n "$name" ]] || { print -u2 "usage: secret_get <name>"; return 1; }
  if (( $+commands[op] )) && op whoami >/dev/null 2>&1; then
    op read "op://${SECRET_OP_VAULT:-Private}/$name/credential" 2>/dev/null && return 0
  fi
  security find-generic-password -a "$USER" -s "$name" -w 2>/dev/null
}

# OPTIONAL aliases and helpers. Nothing loads this file until you run: dot-aliases enable [group...]
# Groups: nav files macos git editors docker azure k8s terraform system
# DOT_ALIAS_GROUPS (set by dot-aliases) limits which groups load; empty means all.

_dot_group() { (( ${#DOT_ALIAS_GROUPS[@]} == 0 )) || (( ${DOT_ALIAS_GROUPS[(Ie)$1]} )) }

# Open a file at a line in the main editor.
_open_at() {
  case "${MAIN_EDITOR:-code}" in
    nvim) nvim "+$2" "$1" ;;
    *)    code -g "$1:$2" ;;
  esac
}

# --- nav ----------------------------------------------------------------------------------------
if _dot_group nav; then
  alias ..='cd ..'
  alias ...='cd ../..'
  alias ....='cd ../../..'
  alias -- -='cd -'
  mkcd() { mkdir -p -- "$1" && cd -- "$1"; }
  # y: yazi file manager; the shell moves to the folder you leave it in.
  y() {
    local tmp cwd; tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    yazi "$@" --cwd-file="$tmp"
    cwd="$(command cat -- "$tmp")"
    [[ -n "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
  }
  # fcd: pick a folder with fzf, then cd into it.
  fcd() { local d; d="$(fd --type d --hidden --exclude .git . "${1:-.}" | fzf)" && cd -- "$d"; }
fi

# --- files --------------------------------------------------------------------------------------
if _dot_group files; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -lah --git --group-directories-first --icons=auto'
  alias la='eza -a --group-directories-first --icons=auto'
  alias lt='eza --tree --level=2 --icons=auto'
  alias cat='bat --paging=never --style=plain'
  alias lessc='bat'
  alias grep='grep --color=auto'
  alias diff='diff --color=auto'
  # ff: pick a file (with preview). fe: pick a file and open it in the main editor.
  ff() { fd --type f --hidden --exclude .git | fzf --preview 'bat --color=always --style=numbers {}'; }
  fe() { local f; f="$(ff)" && [[ -n "$f" ]] && ${=EDITOR} "$f"; }
  # rgi <text>: ripgrep results in fzf; Enter opens the file at that line.
  rgi() {
    local sel file line
    sel="$(rg --line-number --no-heading --color=always "$@" \
      | fzf --ansi --delimiter : --preview 'bat --color=always --highlight-line {2} {1}')" || return
    file="${sel%%:*}"; line="${${sel#*:}%%:*}"
    _open_at "$file" "$line"
  }
fi

# --- macos --------------------------------------------------------------------------------------
if _dot_group macos; then
  alias o='open'
  alias oo='open .'
  alias copy='pbcopy'
  alias paste='pbpaste'
  alias cpwd='print -n "$PWD" | pbcopy'
  # cdf: cd to the front Finder window.
  cdf() { cd "$(osascript -e 'tell application "Finder" to POSIX path of (insertion location as alias)')"; }
fi

# --- git ----------------------------------------------------------------------------------------
if _dot_group git; then
  alias g='git'
  alias gs='git status -sb'
  alias ga='git add'
  alias gaa='git add --all'
  alias gc='git commit -v'
  gcm() { git commit -m "$*"; }
  alias gp='git push'
  alias gpf='git push --force-with-lease'
  alias gl='git pull'
  alias gco='git checkout'
  alias gcb='git switch -c'
  alias gd='git diff'
  alias glog='git log --oneline --graph --decorate'
  alias lg='lazygit'
fi

# --- editors ------------------------------------------------------------------------------------
if _dot_group editors; then
  e() { ${=EDITOR} "$@"; }
  alias c='code .'
  alias v='nvim'
  alias s='subl'
fi

# --- docker -------------------------------------------------------------------------------------
if _dot_group docker; then
  alias d='docker'
  alias dc='docker compose'
  alias dps="docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'"
  alias dl='docker logs -f'
  dex() { docker exec -it "$1" "${2:-sh}"; }
  alias dprune='docker system prune'
  alias lzd='lazydocker'
fi

# --- azure --------------------------------------------------------------------------------------
if _dot_group azure; then
  alias azs='az account show -o table'
  alias azl='az account list -o table'
  alias azlogin='az login'
  # azset: pick a subscription with fzf and switch to it.
  azset() {
    local id
    id="$(az account list --query '[].[name,id]' -o tsv | fzf --delimiter '\t' --with-nth=1 | cut -f2)" || return
    [[ -n "$id" ]] && az account set --subscription "$id" && az account show -o table
  }
fi

# --- k8s ----------------------------------------------------------------------------------------
if _dot_group k8s; then
  alias k='kubectl'
  alias kgp='kubectl get pods'
  alias k9='k9s'
  kctx() { local c; c="$(kubectl config get-contexts -o name | fzf)" && kubectl config use-context "$c"; }
  kns()  { local n; n="$(kubectl get namespaces -o name | sed 's|namespace/||' | fzf)" && kubectl config set-context --current --namespace "$n"; }
fi

# --- terraform ----------------------------------------------------------------------------------
if _dot_group terraform; then
  alias tf='terraform'
  alias tfp='terraform plan'
  alias tfa='terraform apply'
fi

# --- system -------------------------------------------------------------------------------------
if _dot_group system; then
  alias reload='exec zsh'
  alias path='print -l $path'
  alias ports='lsof -iTCP -sTCP:LISTEN -n -P'
  alias myip='curl -s https://ifconfig.me; echo'
  alias flushdns='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'
  alias awake='caffeinate -d'
fi

unfunction _dot_group 2>/dev/null

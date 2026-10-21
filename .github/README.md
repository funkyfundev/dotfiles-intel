# dotfiles

Personal macOS setup for `funkyfundev`: one command takes a clean Mac to a working dev, IT and productivity machine. Everything is a plain file in `$HOME`, tracked with a **bare git repo** (`~/.dotfiles`, work tree = `$HOME`), so there are no symlinks and no extra tools.

**Stack:** zsh + Starship (Tokyo Night theme, Nerd Font) · iTerm2 · VS Code (main), Sublime Text, Neovim · Docker Desktop · Azure CLI 2.65.0 · 1Password with Keychain fallback · Homebrew Brewfiles. Works on **Apple Silicon and Intel** Macs (see [Intel Macs](#intel-macs)).

## New Mac in one line

```bash
curl -fsSL https://raw.githubusercontent.com/funkyfundev/dotfiles/main/.config/dotfiles/bootstrap.sh | bash
```

Try it without changing anything first (it still clones the repo, but the installer only prints what it would do):

```bash
curl -fsSL https://raw.githubusercontent.com/funkyfundev/dotfiles/main/.config/dotfiles/bootstrap.sh | bash -s -- --dry-run
```

Options after `bash -s --`: `--profile work|personal`, `--only 30,55`, `--skip 70`, `--dry-run`, `--yes`.

## Step-by-step: setting up a new Mac

### Before you start

1. Finish macOS setup and install all system updates (System Settings > General > Software Update).
2. On a **work Mac**, let device management (MDM) finish enrolling first, so managed apps such as Office, Teams, Chrome and VPN arrive on their own. The installer skips any app that is already in `/Applications`.
3. Sign in to the **App Store** (Amphetamine installs from there) and connect to the internet.
4. Make sure your account is an **administrator** (sudo is needed once).

### Run the installer

1. Open **Terminal** (Spotlight: `Terminal`).
2. Paste the one-line command above and press Enter.
3. Answer the prompts as they appear:

   | Prompt | What to do |
   | --- | --- |
   | "Install Command Line Tools" dialog | Click **Install** and wait; the script continues by itself |
   | Profile | `work` for the work Mac, `personal` otherwise |
   | Git name / email | Your commit identity (stored in an untracked file) |
   | Password (sudo) | Your Mac login password, asked once |
   | SSH key passphrase | Choose one; it is saved in the Keychain |
   | GitHub sign-in | A browser opens; approve the device code |
   | Touch ID for sudo | `y` unless device management blocks it |

4. Wait for **"All steps finished"**. A first run takes roughly 20 to 40 minutes, mostly downloads. The log is in `~/Library/Logs/dotfiles-install.log`.
5. If one step fails, the installer carries on and lists failures at the end. Fix the cause and re-run just that step, for example `~/.config/dotfiles/install.sh --only 30`.

### After the installer

Work through the checklist the installer prints (also in `.config/dotfiles/scripts/90-post-install.sh`):

1. **Restart the Mac** once.
2. Open **iTerm2**. The "Dotfiles" profile (Tokyo Night, JetBrains Mono Nerd Font) is the default.
3. **Sign in** to 1Password, Microsoft 365 (Teams, Word, Excel), Edge, Chrome, Adobe Creative Cloud, Claude, ChatGPT, and the GitHub Copilot and Claude Code extensions in VS Code.
4. **OpenVPN Connect**: import your `.ovpn` profile by hand. Never commit it.
5. **UniFi endpoint (Ubiquiti)**: install from IT or Ubiquiti; it is not in Homebrew.
6. **Docker Desktop**: open it once and accept the terms (free personal tier).
7. **Permissions**: grant Accessibility to Rectangle and iTerm2 when macOS asks.
8. **1Password**: Settings > Developer > turn on CLI integration (and the SSH agent if you want it).
9. **Azure**: run `az login`.
10. **Optional**: `dot-aliases enable` for the keyboard-first aliases, `dot-editor nvim` to make Neovim the main editor.

### Verify

```bash
dot status                 # repo is healthy (no output means nothing changed)
az version                 # azure-cli 2.65.0
code --list-extensions     # your extensions
starship --version && docker --version && nvim --version | head -1
```

## Intel Macs

The same one-line command works on Intel Macs. The installer detects the CPU (even inside a Rosetta terminal) and adjusts:

| Area | Apple Silicon | Intel |
| --- | --- | --- |
| Homebrew location | `/opt/homebrew` | `/usr/local` |
| CLI tools (starship, fzf, ripgrep, fd, bat, vivid, zoxide, jq, yq, yazi, neovim, lazygit, lazydocker, delta, shellcheck, shfmt, gitleaks, kubectl, helm, k9s) | Homebrew | **mise** prebuilt binaries (`~/.config/mise/config.intel.toml`), because Homebrew builds Intel packages from source |
| Everything else (git, gh, eza, antidote, azcopy, kubelogin, ...) | Homebrew | Homebrew |
| Docker | Docker Desktop | Docker Desktop on macOS 14+; on older macOS, Colima + the docker CLI |

Things to know:

- Homebrew treats Intel as best-effort ("Tier 3"). Support is planned to end in September 2027, and macOS 26 (Tahoe) is the last macOS for Intel Macs.
- Intel tools from mise update with `dot-update` (runs `mise upgrade`); Homebrew ones with `brew upgrade`.
- A first run can take longer when Homebrew has to compile a package.
- `DOTFILES_ARCH=x86_64` and `MISE_ENV=intel` are set automatically; you never need to set them yourself.

## Layout

```
~/
├── .zshenv                     sets ZDOTDIR=~/.config/zsh
├── .gitignore                  ignore everything; track files on purpose
├── .ssh/config                 host defaults; Include config.local
├── .config/
│   ├── zsh/                    .zshrc .zprofile exports functions completions aliases(optional)
│   ├── starship.toml           Nerd Font prompt   (starship-ascii.toml = plain fallback)
│   ├── git/                    config + ignore (identity lives in config.local)
│   ├── nvim/init.lua           minimal Neovim, lazy.nvim
│   ├── mise/config.toml        node, python 3.12, go, java 21, terraform
│   │   └ config.intel.toml     extra prebuilt CLI tools, Intel Macs only
│   └── dotfiles/
│       ├── bootstrap.sh        entry point (curl | bash)
│       ├── install.sh          runs scripts/NN-*.sh in order
│       ├── versions.env        pinned versions (AZ_CLI_VERSION)
│       ├── scripts/            10 CLT · 20 Homebrew · 30 packages · 40 shell · 50 runtimes
│       │                       55 editors · 60 macOS defaults · 70 Dock · 80 SSH+git · 90 post-install
│       ├── brew/               Brewfile.core .dev .ops .apps
│       ├── editors/            vscode-extensions.txt
│       └── templates/          *.local.example, copied on first run
└── Library/Application Support/
    ├── Code/User/              VS Code settings + keybindings
    ├── Sublime Text/Packages/User/
    └── iTerm2/DynamicProfiles/ the "Dotfiles" profile
```

## Day to day

| Task | Command |
| --- | --- |
| See changes | `dot status` / `dot diff` |
| Track a new file | `dot-add ~/.config/foo/config` (secret-scans first) |
| Save and push | `dot-sync "message"` |
| Pull on another Mac | `dot pull` |
| Update everything | `dot-update` |
| Re-run one install step | `~/.config/dotfiles/install.sh --only 60` |
| Add a VS Code extension | append its ID to `editors/vscode-extensions.txt`, then `install.sh --only 55` |
| Add an app | add a line to the right `brew/Brewfile.*`, then `install.sh --only 30` |
| Main editor | `dot-editor code` or `dot-editor nvim` |
| Prompt | `prompt-style nerd` or `prompt-style ascii` |
| Optional aliases | `dot-aliases enable [group...]`, `dot-aliases disable`, `dot-aliases list`; then `exec zsh` |

## Public repo safety

This repo is public. Never commit secrets or employer details.

- `~/.gitignore` ignores everything; files are added on purpose with `dot add -f` (or `dot-add`, which scans first).
- Machine-specific values live in untracked files: `~/.zshrc.local`, `~/.config/git/config.local`, `~/.ssh/config.local`, `~/.config/dotfiles/profile.local`.
- Tokens come from a vault at runtime: `secret_get <name>` tries 1Password (`op://Private/<name>/credential`), then the macOS Keychain.
- CI runs `gitleaks` and `shellcheck` on every push; turn on GitHub push protection in the repo settings.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `brew: command not found` after the install | Open a new terminal (login shell loads `.zprofile`), or run `eval "$(/opt/homebrew/bin/brew shellenv)"` (Intel: `/usr/local/bin/brew`) |
| Intel: a tool such as `rg` or `starship` is missing | Run `install.sh --only 50` (mise installs it), then `exec zsh` |
| Intel: a Homebrew package takes very long | It is compiling from source; wait, or move the tool to `config.intel.toml` |
| No colours in `ls` | Run `exec zsh` so `exports.zsh` loads. It sets `CLICOLOR` and builds `LS_COLORS` with `vivid` (Tokyo Night). For icons and git status, `dot-aliases enable files` (uses `eza`) |
| Prompt icons show as boxes | Set the iTerm2 / VS Code font to JetBrainsMono Nerd Font, or run `prompt-style ascii` |
| An app did not install | `install.sh --only 30` shows which one failed; App Store apps need you signed in |
| Checkout complains about existing files | Bootstrap moves them to `~/.dotfiles-backup/<timestamp>/`; restore from there if needed |
| `dot push` asks for a password | Run `install.sh --only 80` to switch the remote to SSH |
| Azure CLI is the wrong version | Edit `versions.env`, then `install.sh --only 50` |
| Twig extension fails to install | Check the ID in the marketplace (it may be `mblode.twig-language-2`) |
| A Nerd Font icon looks wrong in the prompt | Adjust the code point in `~/.config/starship.toml` |

## Publish this repo (once)

From any machine with git, in the folder that holds these files:

```bash
git init -b main
git add -f .          # -f is needed because .gitignore ignores everything
git commit -m "Initial dotfiles"
git remote add origin git@github.com:funkyfundev/dotfiles.git
git push -u origin main
```

Create the empty public repo `funkyfundev/dotfiles` on GitHub first, and review the files for anything personal before pushing.

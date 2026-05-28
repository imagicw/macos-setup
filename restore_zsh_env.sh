#!/usr/bin/env bash
# macOS dev environment restore script
# Generated from imagic's setup on 2026-05-28
# Usage: bash restore_zsh_env.sh

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
section() { echo -e "\n${BOLD}==> $*${NC}"; }

# ─── 1. Homebrew ──────────────────────────────────────────────────────────────
section "Homebrew"
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Apple Silicon path
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  info "Homebrew already installed: $(brew --version | head -1)"
fi

# ─── 2. Core CLI tools (formulae) ─────────────────────────────────────────────
section "Brew formulae"
FORMULAE=(
  git
  gh           # GitHub CLI
  python@3.13  # stable Python; 3.14 is dev branch
  uv           # fast Python package manager
  deno
  go
  gemini-cli
  yarn
  pandoc
  ffmpeg
  yt-dlp
  mackup       # dotfiles backup/restore
)

for pkg in "${FORMULAE[@]}"; do
  if brew list --formula "$pkg" &>/dev/null 2>&1; then
    info "Already installed: $pkg"
  else
    info "Installing: $pkg"
    brew install "$pkg" || warn "Failed to install $pkg — skipping"
  fi
done

# ─── 3. GUI apps (casks) ──────────────────────────────────────────────────────
section "Brew casks"
CASKS=(
  raycast
  discord
  handbrake
  imageoptim
  input-source-pro
  squirrel           # Rime input method
  termius
  warp
  claude-code
  blackhole-2ch      # virtual audio driver
  # font-maple-mono-nf  # uncomment if you use Maple Mono Nerd Font
)

for cask in "${CASKS[@]}"; do
  if brew list --cask "$cask" &>/dev/null 2>&1; then
    info "Already installed: $cask"
  else
    info "Installing cask: $cask"
    brew install --cask "$cask" || warn "Failed to install cask $cask — skipping"
  fi
done

# Install manually (require separate accounts / installers):
warn "Install manually: JetBrains Toolbox (jetbrains.com/toolbox)"
warn "Install manually: OrbStack (orbstack.dev)"

# ─── 4. oh-my-zsh ─────────────────────────────────────────────────────────────
section "oh-my-zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then
  info "oh-my-zsh already installed"
else
  info "Installing oh-my-zsh..."
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# ─── 5. zsh plugins (third-party) ─────────────────────────────────────────────
section "zsh plugins"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  info "Installing zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
  info "zsh-autosuggestions already present"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  info "Installing zsh-syntax-highlighting..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
else
  info "zsh-syntax-highlighting already present"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ]; then
  info "Installing zsh-history-substring-search..."
  git clone https://github.com/zsh-users/zsh-history-substring-search \
    "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
else
  info "zsh-history-substring-search already present"
fi

if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
  info "Installing powerlevel10k theme..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$ZSH_CUSTOM/themes/powerlevel10k"
else
  info "powerlevel10k already present"
fi

# ─── 6. nvm + Node.js ─────────────────────────────────────────────────────────
section "nvm + Node.js"
NVM_VERSION="0.40.1"

if [ ! -d "$HOME/.nvm" ]; then
  info "Installing nvm $NVM_VERSION..."
  curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash
fi

export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1090
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

if command -v nvm &>/dev/null; then
  NODE_VERSION="24"   # LTS major; nvm will pick latest 24.x
  if nvm ls "$NODE_VERSION" 2>/dev/null | grep -q "v$NODE_VERSION"; then
    info "Node $NODE_VERSION already installed"
  else
    info "Installing Node.js $NODE_VERSION..."
    nvm install "$NODE_VERSION"
    nvm alias default "$NODE_VERSION"
  fi
else
  warn "nvm command not found after install — reload shell and run: nvm install 24"
fi

# ─── 7. pnpm ──────────────────────────────────────────────────────────────────
section "pnpm"
if command -v pnpm &>/dev/null; then
  info "pnpm already installed: $(pnpm --version)"
else
  info "Installing pnpm via corepack..."
  corepack enable
  corepack prepare pnpm@latest --activate
fi

# ─── 8. Write .zshrc ──────────────────────────────────────────────────────────
section ".zshrc"
ZSHRC="$HOME/.zshrc"

if [ -f "$ZSHRC" ]; then
  warn ".zshrc already exists — backing up to .zshrc.bak"
  cp "$ZSHRC" "${ZSHRC}.bak"
fi

cat > "$ZSHRC" << 'ZSHRC_EOF'
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
	git
	zsh-autosuggestions
	zsh-syntax-highlighting
	zsh-history-substring-search
)

source $ZSH/oh-my-zsh.sh

# history-substring-search: bind ↑↓ to prefix-aware search (must be after source)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

export PATH="$HOME/.local/bin:$PATH"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
ZSHRC_EOF

info ".zshrc written"

# ─── 9. Write .zprofile ───────────────────────────────────────────────────────
section ".zprofile"
ZPROFILE="$HOME/.zprofile"

if [ -f "$ZPROFILE" ]; then
  warn ".zprofile already exists — backing up to .zprofile.bak"
  cp "$ZPROFILE" "${ZPROFILE}.bak"
fi

cat > "$ZPROFILE" << 'ZPROFILE_EOF'
# Homebrew (Apple Silicon)
eval "$(/opt/homebrew/bin/brew shellenv)"

# JetBrains Toolbox scripts
export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# OrbStack
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
ZPROFILE_EOF

info ".zprofile written"

# ─── 10. Git config ───────────────────────────────────────────────────────────
section "Git config"
GIT_NAME="imagicw"    # Note: original config had a stray \n — fixed here
GIT_EMAIL="wyw310@gmail.com"

git config --global user.name  "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global core.autocrlf input
git config --global pull.rebase false

info "Git configured for $GIT_NAME <$GIT_EMAIL>"

# ─── Done ─────────────────────────────────────────────────────────────────────
section "Done"
echo ""
info "All tools installed. Next steps:"
echo ""
echo "  1. Sign in to iCloud and wait for Mackup folder to finish syncing."
echo ""
echo "  2. Remove the bootstrap config files written by this script"
echo "     (mackup restore will skip files that already exist):"
echo ""
echo "       rm ~/.zshrc ~/.zprofile ~/.gitconfig"
echo ""
echo "  3. Run mackup restore:"
echo ""
echo "       mackup restore"
echo ""
echo "  4. Restart your terminal — p10k configuration wizard will launch automatically."
echo ""
warn "SSH keys: copy ~/.ssh/id_rsa* and other keys manually from your old machine."
warn "Raycast: use Raycast's built-in Export / Import (Settings → Advanced → Export)."
warn "JetBrains Toolbox and OrbStack require manual installation."

#!/usr/bin/env bash
# macOS dev environment restore script
# Generated from imagic's setup on 2026-05-28
# Usage: bash restore_zsh_env.sh

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
section() { echo -e "\n${BOLD}==> $*${NC}"; }

# ─── contains: check if $1 equals any of the remaining args ──────────────────
contains() {
    local needle="$1"; shift
    for x in "$@"; do [[ "$x" == "$needle" ]] && return 0; done
    return 1
}

# ─── multiselect ──────────────────────────────────────────────────────────────
# Items prefixed with "---" are non-selectable section headers.
# All other items default to selected (checked).
# Result stored in global _MS_RESULT array.
# Usage: multiselect "item1" "---Header" "item2" ...
_MS_RESULT=()
multiselect() {
    local -a _items=("$@")
    local -a _item_idx=()  # indices in _items of selectable items
    local -a _checked=()   # 1=checked per selectable item

    for i in "${!_items[@]}"; do
        [[ "${_items[i]}" != ---* ]] && { _item_idx+=("$i"); _checked+=(1); }
    done

    local n=${#_item_idx[@]}
    local cur=0
    local total=${#_items[@]}

    _ms_draw() {
        local si=0
        for i in "${!_items[@]}"; do
            local item="${_items[i]}"
            if [[ "$item" == ---* ]]; then
                printf "  \033[1;36m%s\033[0m\n" "${item#---}"
            else
                local box mark
                [[ ${_checked[si]} -eq 1 ]] && box="\033[0;32m[✓]\033[0m" || box="\033[2m[ ]\033[0m"
                [[ $si -eq $cur ]]           && mark="\033[1m❯\033[0m " || mark="  "
                printf "  %b%b %s\n" "$mark" "$box" "$item"
                si=$(( si + 1 ))
            fi
        done
    }

    # Restore cursor on Ctrl-C
    trap 'tput cnorm 2>/dev/null || true; echo; exit 130' INT TERM

    tput civis 2>/dev/null || true
    printf "\n  \033[1mSelect components to install\033[0m \033[2m(all selected by default)\033[0m\n"
    printf "  \033[2m↑↓ navigate   Space toggle   a all   n none   Enter confirm\033[0m\n\n"
    _ms_draw

    local key esc
    while true; do
        tput cuu "$total" 2>/dev/null || true

        key=''
        IFS= read -rsn1 key || true

        if [[ "$key" == $'\x1b' ]]; then
            esc=''
            IFS= read -rsn2 -t 1 esc || true
            key="${key}${esc}"
        fi

        case "$key" in
            $'\x1b[A')  # Up arrow
                [[ $cur -gt 0 ]] && cur=$(( cur - 1 ))
                ;;
            $'\x1b[B')  # Down arrow
                [[ $cur -lt $(( n - 1 )) ]] && cur=$(( cur + 1 ))
                ;;
            ' ')
                _checked[$cur]=$(( 1 - _checked[$cur] ))
                ;;
            'a')
                for (( i=0; i<n; i++ )); do _checked[$i]=1; done
                ;;
            'n')
                for (( i=0; i<n; i++ )); do _checked[$i]=0; done
                ;;
            '')  # Enter
                break
                ;;
        esac

        _ms_draw
    done

    tput cnorm 2>/dev/null || true
    trap - INT TERM

    # Clear the selection UI (4 header lines + item lines)
    tput cuu $(( total + 4 )) 2>/dev/null || true
    tput ed 2>/dev/null || true

    _MS_RESULT=()
    for (( si=0; si<n; si++ )); do
        [[ ${_checked[si]} -eq 1 ]] && _MS_RESULT+=("${_items[${_item_idx[si]}]}")
    done

    unset -f _ms_draw
}

# ─── All installable items ────────────────────────────────────────────────────
ALL_ITEMS=(
    "---── CLI Tools (brew formulae)"
    "git"
    "gh"
    "uv"
    "deno"
    "gemini-cli"
    "pandoc"
    "ffmpeg"
    "yt-dlp"
    "mackup"
    "claude-code"
    "---── Fonts"
    "font-maple-mono-nf"
    "---── GUI Apps (brew casks)"
    "raycast"
    "discord"
    "handbrake"
    "imageoptim"
    "input-source-pro"
    "squirrel"
    "termius"
    "warp"
    "blackhole-2ch"
    "orbstack"
    "obsidian"
    "---── Shell Environment"
    "oh-my-zsh + plugins + powerlevel10k"
    "nvm + Node.js 24"
    "---── Config Files"
    "Write ~/.zshrc"
    "Write ~/.zprofile"
    "Git config (imagicw)"
)

# ─── 1. Homebrew (prerequisite, always installed) ─────────────────────────────
section "Homebrew"
if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    info "Homebrew already installed: $(brew --version | head -1)"
fi

# ─── 2. Interactive selection ─────────────────────────────────────────────────
multiselect "${ALL_ITEMS[@]}"

SELECTED=()
[[ ${#_MS_RESULT[@]} -gt 0 ]] && SELECTED=("${_MS_RESULT[@]}")

if [[ ${#SELECTED[@]} -eq 0 ]]; then
    warn "Nothing selected — exiting."
    exit 0
fi

info "Installing ${#SELECTED[@]} selected components..."

# ─── 3. Brew formulae ─────────────────────────────────────────────────────────
FORMULAE=(git gh uv deno gemini-cli pandoc ffmpeg yt-dlp mackup claude-code)
TO_INSTALL=()
for pkg in "${FORMULAE[@]}"; do
    contains "$pkg" "${SELECTED[@]}" && TO_INSTALL+=("$pkg") || true
done

if [[ ${#TO_INSTALL[@]} -gt 0 ]]; then
    section "Brew formulae"
    for pkg in "${TO_INSTALL[@]}"; do
        if brew list --formula "$pkg" &>/dev/null 2>&1; then
            info "Already installed: $pkg"
        else
            info "Installing: $pkg"
            brew install "$pkg" || warn "Failed to install $pkg — skipping"
        fi
    done
fi

# ─── 4. Fonts ─────────────────────────────────────────────────────────────────
FONTS=(font-maple-mono-nf)
TO_INSTALL=()
for font in "${FONTS[@]}"; do
    contains "$font" "${SELECTED[@]}" && TO_INSTALL+=("$font") || true
done

if [[ ${#TO_INSTALL[@]} -gt 0 ]]; then
    section "Fonts"
    brew tap homebrew/cask-fonts 2>/dev/null || true
    for font in "${TO_INSTALL[@]}"; do
        if brew list --cask "$font" &>/dev/null 2>&1; then
            info "Already installed: $font"
        else
            info "Installing font: $font"
            brew install --cask "$font" || warn "Failed to install font $font — skipping"
        fi
    done
fi

# ─── 5. Brew casks ────────────────────────────────────────────────────────────
CASKS=(raycast discord handbrake imageoptim input-source-pro squirrel termius warp blackhole-2ch orbstack obsidian)
TO_INSTALL=()
for cask in "${CASKS[@]}"; do
    contains "$cask" "${SELECTED[@]}" && TO_INSTALL+=("$cask") || true
done

if [[ ${#TO_INSTALL[@]} -gt 0 ]]; then
    section "Brew casks"
    for cask in "${TO_INSTALL[@]}"; do
        if brew list --cask "$cask" &>/dev/null 2>&1; then
            info "Already installed: $cask"
        else
            info "Installing cask: $cask"
            brew install --cask "$cask" || warn "Failed to install cask $cask — skipping"
        fi
    done

fi

# ─── 5. oh-my-zsh + plugins + powerlevel10k ───────────────────────────────────
if contains "oh-my-zsh + plugins + powerlevel10k" "${SELECTED[@]}"; then
    section "oh-my-zsh"
    if [ -d "$HOME/.oh-my-zsh" ]; then
        info "oh-my-zsh already installed"
    else
        info "Installing oh-my-zsh..."
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi

    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

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
fi

# ─── 6. nvm + Node.js ─────────────────────────────────────────────────────────
if contains "nvm + Node.js 24" "${SELECTED[@]}"; then
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
        NODE_VERSION="24"
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
fi

# ─── 7. Write .zshrc ──────────────────────────────────────────────────────────
if contains "Write ~/.zshrc" "${SELECTED[@]}"; then
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

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

export PATH="$HOME/.local/bin:$PATH"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
ZSHRC_EOF

    info ".zshrc written"
fi

# ─── 8. Write .zprofile ───────────────────────────────────────────────────────
if contains "Write ~/.zprofile" "${SELECTED[@]}"; then
    section ".zprofile"
    ZPROFILE="$HOME/.zprofile"

    if [ -f "$ZPROFILE" ]; then
        warn ".zprofile already exists — backing up to .zprofile.bak"
        cp "$ZPROFILE" "${ZPROFILE}.bak"
    fi

    cat > "$ZPROFILE" << 'ZPROFILE_EOF'
# Homebrew (Apple Silicon)
eval "$(/opt/homebrew/bin/brew shellenv)"

# OrbStack
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
ZPROFILE_EOF

    info ".zprofile written"
fi

# ─── 9. Git config ───────────────────────────────────────────────────────────
if contains "Git config (imagicw)" "${SELECTED[@]}"; then
    section "Git config"
    GIT_NAME="imagicw"
    GIT_EMAIL="wyw310@gmail.com"

    git config --global user.name  "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    git config --global core.autocrlf input
    git config --global pull.rebase false

    info "Git configured for $GIT_NAME <$GIT_EMAIL>"
fi

# ─── 10. Mackup config + custom app rules ────────────────────────────────────
section "Mackup config"
MACKUP_DIR="$HOME/.mackup"
mkdir -p "$MACKUP_DIR"

MACKUP_CFG="$HOME/.mackup.cfg"
if [ ! -f "$MACKUP_CFG" ]; then
    cat > "$MACKUP_CFG" << 'MACKUP_EOF'
[storage]
engine = icloud

[applications_to_ignore]
capture-one
MACKUP_EOF
    info "Written ~/.mackup.cfg (engine = icloud)"
else
    info "~/.mackup.cfg already exists — skipping"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -d "$SCRIPT_DIR/.mackup" ]; then
    cp "$SCRIPT_DIR"/.mackup/*.cfg "$MACKUP_DIR/"
    info "Installed mackup custom rules from .mackup/"
else
    warn ".mackup/ directory not found next to script — skipping"
fi

# ─── Done ─────────────────────────────────────────────────────────────────────
section "Done"
echo ""
info "Selected tools installed. Next steps:"
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
echo "  4. Restart your terminal — p10k will load your restored ~/.p10k.zsh config."
echo ""
warn "SSH keys: copy ~/.ssh/id_rsa* and other keys manually from your old machine."
warn "Raycast: use Raycast's built-in Export / Import (Settings → Advanced → Export)."

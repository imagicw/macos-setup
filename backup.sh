#!/usr/bin/env bash
# macOS dev environment backup script
# Usage: bash backup.sh

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
section() { echo -e "\n${BOLD}==> $*${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESTORE_SCRIPT="$SCRIPT_DIR/restore_zsh_env.sh"

# Parse a single-line array definition from the restore script
# Usage: parse_array VARNAME  → prints one item per line
parse_array() {
    local varname="$1"
    grep "^${varname}=(" "$RESTORE_SCRIPT" \
        | sed "s/^${varname}=(//;s/)$//" \
        | tr ' ' '\n' \
        | grep -v '^$'
}

# Check if item exists in a list (one item per line)
in_list() {
    local needle="$1" item
    while IFS= read -r item; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

# ─── 1. mackup backup ─────────────────────────────────────────────────────────
section "mackup backup"
if command -v mackup &>/dev/null; then
    mackup backup --force
    info "mackup backup complete"
else
    warn "mackup not found — skipping"
fi

# ─── 2. Diff brew formulae ────────────────────────────────────────────────────
section "Brew formulae diff"

TRACKED_FORMULAE="$(parse_array FORMULAE)"
LEAF_FORMULAE="$(brew leaves)"          # top-level, for detecting new untracked installs
ALL_FORMULAE="$(brew list --formula)"   # all installed, for checking tracked packages exist

NEW_FORMULAE=()
while IFS= read -r pkg; do
    echo "$TRACKED_FORMULAE" | in_list "$pkg" || NEW_FORMULAE+=("$pkg")
done <<< "$LEAF_FORMULAE"

MISSING_FORMULAE=()
while IFS= read -r pkg; do
    echo "$ALL_FORMULAE" | in_list "$pkg" || MISSING_FORMULAE+=("$pkg")
done <<< "$TRACKED_FORMULAE"

if [[ ${#NEW_FORMULAE[@]} -gt 0 ]]; then
    echo -e "${CYAN}Installed but not tracked in restore script:${NC}"
    for pkg in "${NEW_FORMULAE[@]}"; do
        echo -e "  ${GREEN}+${NC} $pkg"
    done
else
    info "No untracked formulae"
fi

if [[ ${#MISSING_FORMULAE[@]} -gt 0 ]]; then
    echo -e "${CYAN}In restore script but not installed:${NC}"
    for pkg in "${MISSING_FORMULAE[@]}"; do
        echo -e "  ${RED}-${NC} $pkg"
    done
fi

# ─── 3. Diff brew casks ───────────────────────────────────────────────────────
section "Brew casks diff"

TRACKED_CASKS="$(printf '%s\n%s' "$(parse_array CASKS)" "$(parse_array FONTS)")"
INSTALLED_CASKS="$(brew list --cask)"

NEW_CASKS=()
while IFS= read -r cask; do
    echo "$TRACKED_CASKS" | in_list "$cask" || NEW_CASKS+=("$cask")
done <<< "$INSTALLED_CASKS"

MISSING_CASKS=()
while IFS= read -r cask; do
    echo "$INSTALLED_CASKS" | in_list "$cask" || MISSING_CASKS+=("$cask")
done <<< "$TRACKED_CASKS"

if [[ ${#NEW_CASKS[@]} -gt 0 ]]; then
    echo -e "${CYAN}Installed but not tracked in restore script:${NC}"
    for cask in "${NEW_CASKS[@]}"; do
        echo -e "  ${GREEN}+${NC} $cask"
    done
else
    info "No untracked casks"
fi

if [[ ${#MISSING_CASKS[@]} -gt 0 ]]; then
    echo -e "${CYAN}In restore script but not installed:${NC}"
    for cask in "${MISSING_CASKS[@]}"; do
        echo -e "  ${RED}-${NC} $cask"
    done
fi

# ─── Done ─────────────────────────────────────────────────────────────────────
section "Done"
if [[ ${#NEW_FORMULAE[@]} -gt 0 || ${#NEW_CASKS[@]} -gt 0 ]]; then
    echo ""
    warn "Some packages are not tracked in restore_zsh_env.sh."
    echo "  Edit the script manually to add them if needed."
fi
echo ""
info "Backup complete."

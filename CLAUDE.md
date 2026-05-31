# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo does

A macOS dev environment bootstrap. `restore_zsh_env.sh` installs everything from scratch on a new machine; `backup.sh` syncs current state and diffs it against the restore script.

## Running the scripts

```bash
bash restore_zsh_env.sh   # interactive install on a new machine
bash backup.sh            # mackup backup + diff installed vs tracked packages
```

## Architecture

### restore_zsh_env.sh — install flow

1. Always installs Homebrew first (prerequisite, no selection needed).
2. Presents an interactive TUI (`multiselect`) — all items default to checked. Result stored in `SELECTED`.
3. Each install section checks `contains "$item" "${SELECTED[@]}"` before acting; skips silently if not selected.
4. Sections in order: brew formulae → fonts → brew casks → oh-my-zsh+plugins+p10k → nvm+Node → write `.zshrc` → write `.zprofile` → git config → mackup config + custom rules.
5. After install, prints next-steps (iCloud sync → delete bootstrap dotfiles → `mackup restore` → restart terminal).

### backup.sh — diff logic

Parses the `FORMULAE`, `CASKS`, and `FONTS` arrays directly out of `restore_zsh_env.sh` using `grep`/`sed`. Compares against live `brew list` output to show:
- packages installed locally but **not** tracked in the restore script (`+`)
- packages tracked in the restore script but **not** installed (`-`)

### Adding a new package

Three places must stay in sync:

| Location | What to update |
|---|---|
| `ALL_ITEMS` array (selection menu, ~line 122) | Add display name under the right `---` header |
| `FORMULAE` / `CASKS` / `FONTS` array (~line 181/200/220) | Add the brew formula/cask name |
| `README.md` table | Add a row describing the tool |

`backup.sh` parses `FORMULAE`, `CASKS`, and `FONTS` as single-line arrays — keep each on one line.

### mackup custom rules

`.mackup/` contains per-app `.cfg` files that extend mackup's built-in app list. The restore script copies them to `~/.mackup/` at the end of every run. Add a new `<appname>.cfg` file here when an app's config path isn't natively supported by mackup.

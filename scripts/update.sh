#!/usr/bin/env bash
# Update everything install.sh set up: Homebrew/apt packages, downloaded
# tools in ~/.local, oh-my-zsh + plugins, the tmux theme, nvim plugins and
# Mason tools. Run it whenever (alias: update). Safe to re-run.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
S="$DOTFILES/scripts"
export DOTFILES_UPGRADE=1

if [[ $OS == macos ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || brew shellenv)"
  log "brew update"
  brew update -q
  bash "$S/packages-macos.sh"   # brew bundle installs/upgrades the Brewfile
  log "brew upgrade (everything else)"
  brew upgrade -q
  brew cleanup -q
else
  log "apt upgrade"
  $SUDO apt-get update -qq
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get upgrade -y -qq >/dev/null
  bash "$S/packages-linux.sh"
fi
bash "$S/shell.sh"
bash "$S/nvim.sh"

if ! git -C "$DOTFILES" diff --quiet -- nvim/lazy-lock.json; then
  log "nvim/lazy-lock.json changed: try nvim, then commit it"
fi
log "done"

#!/usr/bin/env bash
# oh-my-zsh + plugins, tmux theme, login shell. Same on macOS and Linux.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# clone <repo> <dir> [tag]: shallow clone if missing; when upgrading, pull
# (or move to the given tag) instead.
clone() {
  local repo=$1 dir=$2 tag=${3:-}
  if [[ ! -d $dir ]]; then
    log "clone $repo"
    git clone -q --depth 1 ${tag:+--branch "$tag"} "https://github.com/$repo" "$dir"
  elif upgrading; then
    log "update $repo"
    if [[ -n $tag ]]; then
      git -C "$dir" fetch -q --depth 1 origin tag "$tag"
      git -C "$dir" -c advice.detachedHead=false checkout -q "$tag"
    else
      git -C "$dir" pull -q --ff-only
    fi
  fi
}

clone ohmyzsh/ohmyzsh                  "$HOME/.oh-my-zsh"
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
clone zsh-users/zsh-autosuggestions    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone catppuccin/tmux "$HOME/.config/tmux/plugins/catppuccin/tmux" "$(gh_latest_tag catppuccin/tmux)"

zsh_path="$(command -v zsh)"
if [[ $(basename "${SHELL:-}") != zsh ]]; then
  log "default shell -> $zsh_path"
  grep -qx "$zsh_path" /etc/shells || echo "$zsh_path" | $SUDO tee -a /etc/shells >/dev/null
  $SUDO chsh -s "$zsh_path" "$(id -un)" || warn "chsh failed; set your shell to zsh manually"
fi

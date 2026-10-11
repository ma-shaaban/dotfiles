#!/usr/bin/env bash
# Symlink configs into place. Existing files (not already our symlinks) are
# moved to ~/.dotfiles-backup/<timestamp>/ first.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

link() {
  local src="$DOTFILES/$1" dst="$2"
  if [[ -L $dst && $(readlink "$dst") == "$src" ]]; then return; fi
  if [[ -e $dst || -L $dst ]]; then
    mkdir -p "$BACKUP"
    mv "$dst" "$BACKUP/"
    warn "backed up $dst -> $BACKUP/"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  log "linked $dst"
}

link zsh/zshrc               "$HOME/.zshrc"
link tmux/tmux.conf          "$HOME/.config/tmux/tmux.conf"
link nvim                    "$HOME/.config/nvim"
link starship/starship.toml  "$HOME/.config/starship.toml"
link git/gitconfig           "$HOME/.gitconfig"
[[ $OS == macos ]] && link wezterm/wezterm.lua "$HOME/.config/wezterm/wezterm.lua"
link claude/statusline.sh    "$HOME/.claude/statusline.sh"

# Claude Code rewrites settings.json itself, so merge in the status line
# instead of linking the whole file.
claude_settings="$HOME/.claude/settings.json"
[[ -s $claude_settings ]] || echo '{}' >"$claude_settings"
if ! jq -e '.statusLine.command == "~/.claude/statusline.sh"' "$claude_settings" >/dev/null; then
  tmp="$(mktemp)"
  jq '.statusLine = {type: "command", command: "~/.claude/statusline.sh"}' "$claude_settings" >"$tmp" && mv "$tmp" "$claude_settings"
  log "set statusLine in $claude_settings"
fi

# tmux reads ~/.tmux.conf before ~/.config/tmux/tmux.conf; move it aside.
if [[ -e $HOME/.tmux.conf && ! -L $HOME/.tmux.conf ]]; then
  mkdir -p "$BACKUP" && mv "$HOME/.tmux.conf" "$BACKUP/"
  warn "backed up ~/.tmux.conf -> $BACKUP/"
fi

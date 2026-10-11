#!/usr/bin/env bash
# Remove SSH keys from ssh-agent (the counterpart of ssh-unlock).
#
#   ssh-lock                  remove every key from the agent
#   ssh-lock <item> [...]     remove only these keys (~/.ssh/<item>.pub)
#
# Git identities stay configured; ssh-unlock loads the keys again. To remove
# an identity, delete it from ~/.config/dotfiles/identities.conf and run
# scripts/git-identities.sh (or --clean for all of them).
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if [[ $# -eq 0 ]]; then
  ssh-add -D
  exit
fi
for name in "$@"; do
  ssh-add -d "$HOME/.ssh/$name.pub" || warn "could not remove $name"
done

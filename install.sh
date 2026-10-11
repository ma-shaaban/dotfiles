#!/usr/bin/env bash
# Bootstrap this machine from ~/dotfiles. Idempotent: safe to re-run.
#
#   ./install.sh               packages + links + shell + nvim plugins
#   ./install.sh --links-only  just (re)create the symlinks
#   DOTFILES_SKIP_OPS=1 ./install.sh   skip kubectl/helm/k9s/terraform (Linux)
#
# SSH keys and git identities need a Bitwarden login, so they are separate:
#   scripts/ssh-unlock.sh   (also applies the git identities)
source "$(dirname "${BASH_SOURCE[0]}")/scripts/lib.sh"
S="$DOTFILES/scripts"

if [[ ${1:-} == --links-only ]]; then
  bash "$S/link.sh"
  exit
fi

bash "$S/packages-$OS.sh"
bash "$S/link.sh"
bash "$S/shell.sh"
bash "$S/nvim.sh"

log 'done. Next: open a new shell, then: ssh-unlock'

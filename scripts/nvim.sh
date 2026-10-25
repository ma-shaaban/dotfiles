#!/usr/bin/env bash
# Install nvim plugins at the versions pinned in nvim/lazy-lock.json.
# Mason tools (LSPs, formatters, tree-sitter CLI) and treesitter parsers
# install themselves in the background on the first real launch.
# When upgrading: update plugins (rewrites lazy-lock.json) and Mason tools.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
export PATH="$LOCAL_BIN:$LOCAL_OPT/node/bin:$PATH"

if upgrading; then
  log "nvim plugins (lazy sync)"
  nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 || die "lazy sync failed; run nvim and check :Lazy"
  log "mason tools"
  nvim --headless -c "luafile $DOTFILES/scripts/mason-update.lua" -c qa 2>&1 | grep '^mason:' || true
else
  log "nvim plugins (lazy restore)"
  nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 || die "lazy restore failed; run nvim and check :Lazy"
fi

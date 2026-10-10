#!/usr/bin/env bash
# Install nvim plugins at the versions pinned in nvim/lazy-lock.json.
# Mason tools (LSPs, formatters, tree-sitter CLI) and treesitter parsers
# install themselves in the background on the first real launch.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
export PATH="$LOCAL_BIN:$LOCAL_OPT/node/bin:$PATH"

log "nvim plugins (lazy restore)"
nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 || die "lazy restore failed; run nvim and check :Lazy"

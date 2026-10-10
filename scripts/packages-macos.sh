#!/usr/bin/env bash
# macOS packages via Homebrew + the Brewfile.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if ! have brew && [[ ! -x /opt/homebrew/bin/brew ]]; then
  log "homebrew (installs Xcode Command Line Tools too)"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || brew shellenv)"

log "brew bundle"
brew bundle --file "$DOTFILES/Brewfile"

# Not in Homebrew core.
if ! have mermaid-ascii; then
  log "mermaid-ascii"
  tmp="$(fetch_tgz "https://github.com/AlexanderGrooff/mermaid-ascii/releases/latest/download/mermaid-ascii_Darwin_$ARCH.tar.gz")"
  mv "$tmp/mermaid-ascii" "$LOCAL_BIN/"
fi

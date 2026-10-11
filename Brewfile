# macOS packages: brew bundle --file Brewfile

# Shell + editor
brew "git"
brew "tmux"
brew "neovim"
brew "starship"
brew "fzf"
brew "zoxide"
brew "ripgrep"
brew "fd"
brew "jq"
brew "node"           # mason (prettier, markdown-toc)
brew "bitwarden-cli"  # bw, used by scripts/ssh-unlock.sh
brew "gh"             # GitHub API (repos, PRs); git itself still uses SSH

# Ops
brew "kubernetes-cli"
brew "helm"
brew "k9s"
tap "hashicorp/tap"
brew "hashicorp/tap/terraform"

# Containers (run `colima start` once)
brew "colima"
brew "docker"
brew "docker-compose"

# Apps + fonts
cask "wezterm"
cask "bitwarden" unless File.exist?("/Applications/Bitwarden.app")  # may be the App Store build
cask "font-fira-code-nerd-font"

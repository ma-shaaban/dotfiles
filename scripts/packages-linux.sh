#!/usr/bin/env bash
# Ubuntu/Debian packages. apt for the basics, upstream release binaries into
# ~/.local for anything where apt is too old. Each tool is skipped if present.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

grep -qiE '^(ID|ID_LIKE)=.*(debian|ubuntu)' /etc/os-release || die "only Debian/Ubuntu is supported on Linux"

log "apt packages"
$SUDO apt-get update -qq
DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq \
  zsh tmux git curl ca-certificates unzip xz-utils ripgrep fd-find jq zoxide build-essential >/dev/null
# Debian names the fd binary fdfind.
have fd || ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"

install_nvim() {
  # LazyVim needs a recent nvim; apt's is too old.
  if ! upgrading && have nvim && nvim --headless -c 'if has("nvim-0.11") | qa | else | cq | endif' 2>/dev/null; then return; fi
  log "neovim"
  local tmp; tmp="$(fetch_tgz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-$ARCH.tar.gz")"
  rm -rf "$LOCAL_OPT/nvim" && mv "$tmp"/nvim-linux-* "$LOCAL_OPT/nvim"
  ln -sf "$LOCAL_OPT/nvim/bin/nvim" "$LOCAL_BIN/nvim"
}

install_fzf() {
  # fzf --zsh needs >= 0.48; apt's is older.
  if ! upgrading && have fzf && fzf --zsh >/dev/null 2>&1; then return; fi
  log "fzf"
  local tag tmp; tag="$(gh_latest_tag junegunn/fzf)"
  tmp="$(fetch_tgz "https://github.com/junegunn/fzf/releases/download/$tag/fzf-${tag#v}-linux_$ARCH_GO.tar.gz")"
  mv "$tmp/fzf" "$LOCAL_BIN/fzf"
}

install_starship() {
  present starship && return
  log "starship"
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$LOCAL_BIN" >/dev/null
}

install_mermaid_ascii() {
  present mermaid-ascii && return
  log "mermaid-ascii"
  local tmp; tmp="$(fetch_tgz "https://github.com/AlexanderGrooff/mermaid-ascii/releases/latest/download/mermaid-ascii_Linux_$ARCH.tar.gz")"
  mv "$tmp/mermaid-ascii" "$LOCAL_BIN/"
}

install_node() {
  # Needed by mason (prettier, markdown-toc) and the Bitwarden CLI.
  present node && return
  log "node (LTS)"
  local ver tmp
  ver="$(curl -fsSL https://nodejs.org/dist/index.json | jq -r '[.[] | select(.lts)][0].version')"
  tmp="$(mktemp -d)"
  curl -fsSL "https://nodejs.org/dist/$ver/node-$ver-linux-${ARCH_GO/amd64/x64}.tar.xz" | tar -xJ -C "$tmp"
  rm -rf "$LOCAL_OPT/node" && mv "$tmp"/node-* "$LOCAL_OPT/node"
  export PATH="$LOCAL_OPT/node/bin:$PATH"
}

install_bw() {
  present bw && return
  log "bitwarden cli"
  npm install -g --silent --prefix "$HOME/.local" @bitwarden/cli
}

install_gh() {
  present gh && return
  log "gh"
  local tag tmp; tag="$(gh_latest_tag cli/cli)"
  tmp="$(fetch_tgz "https://github.com/cli/cli/releases/download/$tag/gh_${tag#v}_linux_$ARCH_GO.tar.gz")"
  mv "$tmp"/gh_*/bin/gh "$LOCAL_BIN/"
}

install_aws() {
  present aws && return
  log "aws cli"
  local tmp; tmp="$(mktemp -d)"
  curl -fsSLo "$tmp/aws.zip" "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH/arm64/aarch64}.zip"
  unzip -q "$tmp/aws.zip" -d "$tmp"
  "$tmp/aws/install" -i "$LOCAL_OPT/aws-cli" -b "$LOCAL_BIN" --update >/dev/null
}

install_kubectl() {
  present kubectl && return
  log "kubectl"
  curl -fsSLo "$LOCAL_BIN/kubectl" "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/$ARCH_GO/kubectl"
  chmod +x "$LOCAL_BIN/kubectl"
}

install_helm() {
  present helm && return
  log "helm"
  local tmp; tmp="$(fetch_tgz "https://get.helm.sh/helm-$(gh_latest_tag helm/helm)-linux-$ARCH_GO.tar.gz")"
  mv "$tmp/linux-$ARCH_GO/helm" "$LOCAL_BIN/"
}

install_k9s() {
  present k9s && return
  log "k9s"
  local tmp; tmp="$(fetch_tgz "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_$ARCH_GO.tar.gz")"
  mv "$tmp/k9s" "$LOCAL_BIN/"
}

install_terraform() {
  present terraform && return
  log "terraform"
  local ver tmp
  ver="$(curl -fsSL https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r .current_version)"
  tmp="$(mktemp -d)"
  curl -fsSLo "$tmp/tf.zip" "https://releases.hashicorp.com/terraform/$ver/terraform_${ver}_linux_$ARCH_GO.zip"
  unzip -qo "$tmp/tf.zip" terraform -d "$LOCAL_BIN"
}

install_nvim
install_fzf
install_starship
install_mermaid_ascii
install_node
install_bw
install_gh
if [[ ${DOTFILES_SKIP_OPS:-0} != 1 ]]; then
  install_aws
  install_kubectl
  install_helm
  install_k9s
  install_terraform
fi

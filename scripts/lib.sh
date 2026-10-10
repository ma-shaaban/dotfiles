# Shared helpers, sourced by the other scripts.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_BIN="$HOME/.local/bin"
LOCAL_OPT="$HOME/.local/opt"
mkdir -p "$LOCAL_BIN" "$LOCAL_OPT"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux)  OS=linux ;;
  *) die "unsupported OS: $(uname -s)" ;;
esac

case "$(uname -m)" in
  x86_64 | amd64)  ARCH=x86_64; ARCH_GO=amd64 ;;
  arm64 | aarch64) ARCH=arm64;  ARCH_GO=arm64 ;;
  *) die "unsupported arch: $(uname -m)" ;;
esac

# Root in many containers, sudo elsewhere.
if [[ $(id -u) -eq 0 ]]; then SUDO=""; else SUDO="sudo"; fi

# Latest release tag of a GitHub repo, without needing the API (no rate limit).
gh_latest_tag() {
  curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" | sed 's|.*/tag/||'
}

# Download a .tar.gz and extract it into a fresh temp dir; prints the dir.
fetch_tgz() {
  local tmp
  tmp="$(mktemp -d)"
  curl -fsSL "$1" | tar -xz -C "$tmp"
  echo "$tmp"
}

# Real git/SSH identities: local only, never in the repo (see git/identities.example.conf).
IDENTITIES="$HOME/.config/dotfiles/identities.conf"
IDENTITIES_NOTE="dotfiles-identities"

# Print "dir|name|email|auth|sign" for each identity, whitespace trimmed.
read_identities() {
  [[ -f $IDENTITIES ]] || die "$IDENTITIES missing; run ssh-unlock (fetches it from Bitwarden note '$IDENTITIES_NOTE')"
  sed -e 's/#.*//' -e 's/[[:space:]]*|[[:space:]]*/|/g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$IDENTITIES" | grep -v '^$' || true
}

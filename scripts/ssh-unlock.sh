#!/usr/bin/env bash
# Load SSH keys from Bitwarden into ssh-agent. Private keys never touch disk:
# they go from `bw` straight into the agent's memory and expire after
# SSH_KEY_TTL (default 12h). Only the public keys are written, to
# ~/.ssh/<name>.pub, so ssh/git can tell the agent which key to use.
#
#   ssh-unlock                  keys named in ~/.config/dotfiles/identities.conf
#   ssh-unlock <item> [...]     ...plus these Bitwarden "SSH key" items
#
# If the identities file is missing, it is fetched from the Bitwarden secure
# note "dotfiles-identities".
#
# Uses the current agent if one is reachable (macOS launchd agent, forwarded
# agent); otherwise starts one at ~/.ssh/agent.local.sock, which zshrc picks up.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
export PATH="$LOCAL_BIN:$LOCAL_OPT/node/bin:$PATH"

have bw || die "bw not installed; run ./install.sh first"
TTL="${SSH_KEY_TTL:-12h}"
LOCAL_SOCK="$HOME/.ssh/agent.local.sock"

# ssh-add -l: 0 = has keys, 1 = no keys, 2 = no agent reachable.
agent_rc() { local rc=0; ssh-add -l >/dev/null 2>&1 || rc=$?; echo "$rc"; }

mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"

# Agent: reuse a reachable one, else start our own at a fixed path.
if [[ $(agent_rc) == 2 ]]; then
  export SSH_AUTH_SOCK="$LOCAL_SOCK"
  if [[ $(agent_rc) == 2 ]]; then
    rm -f "$LOCAL_SOCK"
    agent_env="$(ssh-agent -a "$LOCAL_SOCK" -s)" || die "could not start ssh-agent"
    eval "$agent_env" >/dev/null
    log "started ssh-agent at $LOCAL_SOCK"
  fi
fi

# Bitwarden: reuse an exported BW_SESSION, otherwise unlock and re-lock after.
we_unlocked=0
case "$(bw status | jq -r .status)" in
  unauthenticated) bw login >/dev/null; BW_SESSION="$(bw unlock --raw)"; we_unlocked=1 ;;
  locked)          BW_SESSION="$(bw unlock --raw)"; we_unlocked=1 ;;
esac
export BW_SESSION
relock() { if [[ $we_unlocked == 1 ]]; then bw lock >/dev/null; fi; }
trap relock EXIT
bw sync >/dev/null

if [[ ! -f $IDENTITIES ]]; then
  note="$(bw list items --search "$IDENTITIES_NOTE" | jq -r --arg n "$IDENTITIES_NOTE" 'map(select(.name == $n)) | first | .notes // empty')"
  if [[ -n $note ]]; then
    mkdir -p "$(dirname "$IDENTITIES")"
    printf '%s\n' "$note" >"$IDENTITIES"
    log "wrote $IDENTITIES from Bitwarden note '$IDENTITIES_NOTE'"
  else
    warn "no $IDENTITIES and no Bitwarden note '$IDENTITIES_NOTE'; loading only named keys"
  fi
fi

# Keys: auth + signing columns of the identities file, then any arguments.
names=()
if [[ -f $IDENTITIES ]]; then
  while IFS='|' read -r _ _ _ auth sign; do names+=("$auth" "$sign"); done < <(read_identities)
fi
names+=("$@")
mapfile -t names < <(printf '%s\n' "${names[@]}" | awk 'NF && !seen[$0]++')
[[ ${#names[@]} -gt 0 ]] || die "no keys to load"

items="$(bw list items | jq -c '[.[] | select(.type == 5)]')"
for name in "${names[@]}"; do
  item="$(jq -c --arg n "$name" 'map(select(.name == $n)) | first' <<<"$items")"
  if [[ $item == null ]]; then warn "no Bitwarden SSH key item named '$name'"; continue; fi
  priv="$(jq -r .sshKey.privateKey <<<"$item")"
  pub="$(jq -r '.sshKey.publicKey // empty' <<<"$item")"
  [[ -n $pub ]] || pub="$(ssh-keygen -y -f /dev/stdin <<<"$priv")"
  printf '%s\n' "$pub" >"$HOME/.ssh/$name.pub"
  chmod 644 "$HOME/.ssh/$name.pub"
  ssh-add -q -t "$TTL" - <<<"$priv" && log "loaded $name for $TTL"
done
unset priv

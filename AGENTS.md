# Dotfiles — agent instructions

Personal dev environment for **macOS (WezTerm)** and **Ubuntu/Debian dev containers**.
Everything needed is already scripted; don't re-derive it. Read this file, then run the scripts.

## Set up a machine

```sh
git clone https://github.com/ma-shaaban/dotfiles ~/dotfiles
~/dotfiles/install.sh                 # packages, symlinks, oh-my-zsh, tmux theme, nvim plugins
exec zsh
ssh-unlock                            # interactive: Bitwarden unlock, keys -> ssh-agent,
                                      # then git-identities.sh (per-dir identities + allowed_signers)
```

- **Steps only the user can do** (an agent can't type passwords). Ask them to run these with the `!` prefix:
  - macOS, before `install.sh`: `! sudo -v` (Homebrew's installer needs sudo) — or have them run `! ~/dotfiles/install.sh` directly.
  - `! ~/dotfiles/scripts/ssh-unlock.sh`: Bitwarden login/unlock (email, master password, 2FA).
- `install.sh` is idempotent: it skips installed tools and backs up replaced files to `~/.dotfiles-backup/<ts>/`.
- Never ask the user to paste a Bitwarden session key or password into the chat.
- SSH keys expire from the agent after `SSH_KEY_TTL` (12h); the user re-runs `ssh-unlock` daily. `ssh-lock [name...]` removes keys from the agent early.
- Identities: `~/.config/dotfiles/identities.conf` is the source of truth. After editing it, run `scripts/git-identities.sh` (or `ssh-unlock`); identities removed since the last run are cleaned up (their `~/<dir>/.gitconfig`, `.pub` files, agent keys). `git-identities.sh --clean` removes all of them. The Bitwarden note is only read when the file is missing, so update it too.
- On Linux, `DOTFILES_SKIP_OPS=1` skips kubectl/helm/k9s/terraform.
- After install on macOS: `colima start` once for Docker.
- Verify: `nvim --headless "+checkhealth lazyvim" +qa`, `tmux new -d && tmux kill-server`, `zsh -ic exit`.

## Layout

| Repo path | Linked to | Notes |
|---|---|---|
| `zsh/zshrc` | `~/.zshrc` | oh-my-zsh + starship + zoxide + fzf. Sources `~/.zshrc.local` |
| `tmux/tmux.conf` | `~/.config/tmux/tmux.conf` | prefix `C-a`, catppuccin plugin cloned by `scripts/shell.sh`. Sources `~/.config/tmux/local.conf` |
| `nvim/` | `~/.config/nvim` | LazyVim. Plugin versions pinned in `lazy-lock.json` |
| `starship/starship.toml` | `~/.config/starship.toml` | |
| `git/gitconfig` | `~/.gitconfig` | SSH signing; pushes to GitHub/GitLab/Bitbucket always go over SSH (`pushInsteadOf`). Includes `~/.gitconfig.local` |
| `git/identities.example.conf` | — | Format of the real `~/.config/dotfiles/identities.conf` (local only; fetched from Bitwarden note `dotfiles-identities`) |
| `wezterm/wezterm.lua` | `~/.config/wezterm/wezterm.lua` | macOS only. Loads `~/.config/wezterm/local.lua` (ssh_domains etc.) |
| `Brewfile` | — | macOS packages |
| `scripts/packages-linux.sh` | — | apt + upstream binaries into `~/.local/{bin,opt}` |

## Conventions

- **Public repo.** Never commit secrets, hostnames/IPs, or anything client/employer-specific (company names, work emails, key names, paths). Put them in the `*.local` files above or `~/.config/dotfiles/identities.conf`.
- **SSH keys live in Bitwarden** as items of type *SSH key*. Private keys are never written to disk: `scripts/ssh-unlock.sh` pipes them into ssh-agent (reachable agent, else its own at `~/.ssh/agent.local.sock`) and writes only `~/.ssh/<item name>.pub`. It loads the keys named in `~/.config/dotfiles/identities.conf` (fetched from the Bitwarden secure note `dotfiles-identities` if missing); extra keys by name: `ssh-unlock <item name>`. Reference keys in ssh config/git as `~/.ssh/<name>` (ssh finds `<name>.pub` and uses the agent) and signing keys as `~/.ssh/<name>.pub`.
- **Forge-agnostic git.** Auth and signing are plain SSH keys via ssh-agent; no `gh`/`glab` credential helpers or HTTPS tokens. Self-hosted forges get a `pushInsteadOf` line in `~/.gitconfig.local`.
- **Theme**: Catppuccin Macchiato everywhere (WezTerm, tmux, nvim, starship).
- **Keep it minimal.** The base is intentionally small; per-project tools get installed in that environment, not here.
- **Ask the user before adding** these previously removed tools: yazi, glow (or other markdown viewers), lazygit, codeium/windsurf, copilot, ghostty, chafa.
- nvim markdown rendering is `nvim/lua/plugins/markdown.lua` (render-markdown.nvim + `<leader>mm` mermaid preview via `mermaid-ascii`). It patches a private render-markdown API; recheck after plugin updates.
- Adding a tool: add it to both `Brewfile` and `scripts/packages-linux.sh` (skip-if-present function), add any config dir + a `link` line in `scripts/link.sh`, and update the table above.
- After `:Lazy update` in nvim, commit `nvim/lazy-lock.json`.

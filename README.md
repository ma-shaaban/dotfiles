# dotfiles

My dev environment for macOS (WezTerm) and Ubuntu/Debian dev containers:
zsh (oh-my-zsh + starship), tmux, LazyVim with in-editor markdown rendering, and git with per-directory SSH-signed identities. SSH keys are loaded from Bitwarden straight into ssh-agent.

```sh
git clone https://github.com/ma-shaaban/dotfiles ~/dotfiles
~/dotfiles/install.sh
exec zsh
ssh-unlock && ~/dotfiles/scripts/git-identities.sh   # Bitwarden -> ssh-agent, never to disk
```

Details, layout and conventions are in [AGENTS.md](AGENTS.md), written so an AI agent can set up a new machine from it.

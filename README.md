# dotfiles

WSL2 dotfiles managed with [chezmoi](https://chezmoi.io) for neovim (LazyVim), tmux (catppuccin), ghostty, and shell config.

## Install

```bash
chezmoi init --apply git@github.com:DougLiberis/dotfiles.git
```

This will:
- Apply all configs as managed files (no symlinks)
- Run the bootstrap script to install TPM and the catppuccin tmux theme

After applying, open tmux and press `<prefix>+I` to install remaining plugins via TPM.

## Update

```bash
chezmoi update
```

Pulls latest changes from GitHub and applies them.

## Contents

| Chezmoi source | Target |
|---|---|
| `dot_bashrc` | `~/.bashrc` |
| `dot_zshrc` | `~/.zshrc` |
| `dot_gitconfig` | `~/.gitconfig` |
| `dot_tmux.conf` | `~/.tmux.conf` |
| `dot_config/nvim/` | `~/.config/nvim/` (LazyVim) |
| `dot_config/ghostty/` | `~/.config/ghostty/` |

## Day-to-day workflow

```bash
chezmoi edit ~/.bashrc      # edit a managed file
chezmoi diff                # preview what would change
chezmoi apply               # apply changes to home dir
chezmoi cd                  # jump into the source repo
git add . && git commit && git push   # save to GitHub
```

## Secrets / local config

Put machine-specific env vars in `~/.zshrc.local` (not tracked):

```bash
# ~/.zshrc.local
export SOME_TOKEN=secret
```

## Neovim

Built on [LazyVim](https://lazyvim.org). Plugin config lives in `dot_config/nvim/lua/plugins/`.

`lazy-lock.json` and `lazyvim.json` are excluded — run `:Lazy sync` after a fresh install.

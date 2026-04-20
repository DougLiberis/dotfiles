# dotfiles

WSL2 dotfiles for neovim (LazyVim), tmux (catppuccin), lazygit, ghostty, and shell config.

## Contents

| Path | Target |
|------|--------|
| `.bashrc` | `~/.bashrc` |
| `.zshrc` | `~/.zshrc` |
| `.gitconfig` | `~/.gitconfig` |
| `.tmux.conf` | `~/.tmux.conf` |
| `.config/nvim/` | `~/.config/nvim/` (LazyVim) |
| `.config/ghostty/` | `~/.config/ghostty/` |

## Install

```bash
git clone git@github.com:DougLiberis/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

The script creates symlinks from `~` into this repo and installs:
- [TPM](https://github.com/tmux-plugins/tpm) — Tmux Plugin Manager
- [catppuccin/tmux](https://github.com/catppuccin/tmux) — tmux theme

After running, open tmux and press `<prefix>+I` to install remaining plugins.

## Secrets / local config

Machine-specific env vars and secrets live in `~/.zshrc.local` (not tracked).

```bash
# ~/.zshrc.local
export ANTHROPIC_BASE_URL=http://localhost:11434
export ANTHROPIC_AUTH_TOKEN=your-token-here
```

## Neovim

Built on [LazyVim](https://lazyvim.org). Plugin config lives in `.config/nvim/lua/plugins/`.

`lazy-lock.json` and `lazyvim.json` are excluded (runtime-generated). Run `:Lazy sync` after a fresh install.

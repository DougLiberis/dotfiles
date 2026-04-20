#!/usr/bin/env bash
# Runs once on first `chezmoi apply` to bootstrap tmux plugin manager and catppuccin theme.

set -e

# TPM (Tmux Plugin Manager)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "Installing TPM..."
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# Catppuccin tmux theme
CATPPUCCIN_DIR="$HOME/.config/tmux/plugins/catppuccin/tmux"
if [ ! -d "$CATPPUCCIN_DIR" ]; then
  echo "Installing catppuccin tmux plugin..."
  mkdir -p "$(dirname "$CATPPUCCIN_DIR")"
  git clone --depth=1 https://github.com/catppuccin/tmux "$CATPPUCCIN_DIR"
fi

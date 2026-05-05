#!/usr/bin/env bash
# Runs once on first `chezmoi apply` to bootstrap tmux plugin manager and plugins.
# Updating this script's content causes chezmoi to re-run it on next apply.

set -e

# TPM (Tmux Plugin Manager)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "Installing TPM..."
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# Catppuccin tmux theme (loaded directly, not via TPM)
CATPPUCCIN_DIR="$HOME/.config/tmux/plugins/catppuccin/tmux"
if [ ! -d "$CATPPUCCIN_DIR" ]; then
  echo "Installing catppuccin tmux plugin..."
  mkdir -p "$(dirname "$CATPPUCCIN_DIR")"
  git clone --depth=1 https://github.com/catppuccin/tmux "$CATPPUCCIN_DIR"
fi

# Install all TPM-managed plugins headlessly (includes resurrect + continuum)
echo "Installing tmux plugins via TPM..."
"$HOME/.tmux/plugins/tpm/bin/install_plugins"

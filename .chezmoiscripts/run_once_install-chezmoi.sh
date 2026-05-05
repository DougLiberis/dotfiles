#!/usr/bin/env bash
# Installs chezmoi if not already present, then applies dotfiles.
# Run this on a fresh machine to bootstrap the full environment:
#   sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply DougLiberis

set -e

if command -v chezmoi &>/dev/null; then
  echo "chezmoi already installed at $(which chezmoi)"
  exit 0
fi

echo "Installing chezmoi..."
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
echo "chezmoi installed: $(chezmoi --version)"

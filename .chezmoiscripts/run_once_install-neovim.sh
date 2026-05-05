#!/usr/bin/env bash
# Installs Neovim stable to /opt/nvim-linux-x86_64 (matching PATH in .bashrc)

set -e

if [ -f "/opt/nvim-linux-x86_64/bin/nvim" ]; then
  echo "Neovim already installed, skipping."
  exit 0
fi

echo "Installing Neovim..."
TMPDIR=$(mktemp -d)
curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz" \
  -o "$TMPDIR/nvim.tar.gz"

sudo tar -C /opt -xzf "$TMPDIR/nvim.tar.gz"
rm -rf "$TMPDIR"

echo "Neovim installed: $(/opt/nvim-linux-x86_64/bin/nvim --version | head -1)"

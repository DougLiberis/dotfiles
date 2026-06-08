#!/usr/bin/env bash
set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"

# Colour helpers
info()    { printf '\033[0;34m[INFO]\033[0m  %s\n' "$1"; }
success() { printf '\033[0;32m[OK]\033[0m    %s\n' "$1"; }
warn()    { printf '\033[0;33m[WARN]\033[0m  %s\n' "$1"; }

# Create a symlink, backing up any existing file first
link() {
  local src="$DOTFILES/$1"
  local dst="$HOME_DIR/$1"

  if [ ! -e "$src" ]; then
    warn "Source not found, skipping: $src"
    return
  fi

  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    info "Already linked: $dst"
    return
  fi

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    warn "Backing up existing: $dst -> $dst.bak"
    mv "$dst" "$dst.bak"
  fi

  mkdir -p "$(dirname "$dst")"
  ln -sf "$src" "$dst"
  success "Linked: $dst -> $src"
}

# ── Shell ────────────────────────────────────────────────────────────────────
link .bashrc
link .zshrc

# ── Git ──────────────────────────────────────────────────────────────────────
link .gitconfig

# ── Tmux ─────────────────────────────────────────────────────────────────────
link .tmux.conf

# Install TPM (Tmux Plugin Manager) if not present
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  info "Installing TPM..."
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  success "TPM installed"
fi

# Install catppuccin tmux plugin if not present
CATPPUCCIN_DIR="$HOME/.config/tmux/plugins/catppuccin/tmux"
if [ ! -d "$CATPPUCCIN_DIR" ]; then
  info "Installing catppuccin tmux plugin..."
  mkdir -p "$(dirname "$CATPPUCCIN_DIR")"
  git clone --depth=1 https://github.com/catppuccin/tmux "$CATPPUCCIN_DIR"
  success "Catppuccin tmux plugin installed"
fi

# ── Neovim (LazyVim) ─────────────────────────────────────────────────────────
link .config/nvim

# ── Ghostty ──────────────────────────────────────────────────────────────────
link .config/ghostty

# ── Secrets reminder ─────────────────────────────────────────────────────────
if [ ! -f "$HOME/.zshrc.local" ]; then
  warn "No ~/.zshrc.local found. Create one for machine-specific env vars / secrets."
  info "Example: echo 'export ANTHROPIC_BASE_URL=http://localhost:11434' >> ~/.zshrc.local"
fi

echo ""
success "Dotfiles installed! Open a new shell or run: source ~/.bashrc"
info "Tmux: start a session and press <prefix>+I to install plugins via TPM."

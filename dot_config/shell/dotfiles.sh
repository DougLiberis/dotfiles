# Portable shell env + PATH customizations.
#
# Sourced by ~/.bashrc and ~/.zshrc on personal machines, and by ~/.bashrc in
# Coder workspaces (appended by install.sh). Keep this POSIX-sh compatible and
# free of anything that auto-attaches or replaces the shell (no `exec tmux`).

# Fix TERM outside tmux — tmux-256color leaks DA escape sequences to stdin.
if [ -z "${TMUX:-}" ] && [ "${TERM:-}" = "tmux-256color" ]; then
  export TERM=xterm-256color
fi

# Rust toolchain.
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# nvm.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# Neovim (installed under /opt by the chezmoi bootstrap on personal machines).
case ":$PATH:" in
  *":/opt/nvim-linux-x86_64/bin:"*) ;;
  *) [ -d /opt/nvim-linux-x86_64/bin ] && export PATH="$PATH:/opt/nvim-linux-x86_64/bin" ;;
esac

# Personal bin dirs (guard against duplicate entries on re-source).
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$PATH:$HOME/.local/bin:$HOME/bin" ;;
esac

export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
. "$HOME/.cargo/env"

# Load local overrides (secrets, machine-specific env vars — not committed)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

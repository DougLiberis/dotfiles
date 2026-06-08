#!/usr/bin/env bash
#
# Coder workspace dotfiles entry point.
#
# Coder clones this repo and runs ./install.sh on every workspace start and on
# "Refresh Dotfiles". This bootstraps chezmoi (no root required) and applies the
# dotfiles from THIS clone. Personal machines keep using chezmoi directly
# (`chezmoi init --apply ...`); this script only adapts the repo to Coder's
# "run install.sh" model.
#
# Constraints honoured (see LiberisFinance/coder-workspaces docs/dotfiles.md):
#   - ~/.bashrc, ~/.npmrc, ~/.config/gh, ~/.claude/settings.json are managed by
#     the workspace entrypoint. We never overwrite them. chezmoi is told (via
#     the DOTFILES_CODER branch in .chezmoiignore) to skip the shell rc files
#     and .gitconfig here; we only do guarded appends / `git config` writes.
#   - Idempotent: safe to run on every boot and on manual refresh.
#
set -euo pipefail

# Repo root = the directory containing this script (Coder clones to a temp dir).
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Marker so .chezmoiignore can branch on the Coder environment.
export DOTFILES_CODER=1

BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

# ---------- 1. chezmoi (install to ~/.local/bin, no root) ----------
if ! command -v chezmoi >/dev/null 2>&1; then
  echo "[dotfiles] installing chezmoi -> $BIN_DIR"
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$BIN_DIR"
fi

# ---------- 2. apply dotfiles from this clone ----------
# --source points chezmoi at the already-cloned repo: no second clone, no extra
# network round-trip, and it picks up the DOTFILES_CODER ignore branch.
# --force makes changes without prompting: the Coder agent has no TTY, and the
# entrypoint modifies ~/.claude after chezmoi last wrote it, which would
# otherwise trigger an interactive "overwrite?" prompt and abort.
echo "[dotfiles] applying chezmoi from $SOURCE_DIR"
chezmoi init --apply --force --source="$SOURCE_DIR"

# ---------- 3. shell fragment (append-only, guarded) ----------
# chezmoi deploys ~/.config/shell/dotfiles.sh but must NOT touch the
# entrypoint-managed ~/.bashrc. Source the fragment from ~/.bashrc exactly once.
FRAGMENT='[ -f "$HOME/.config/shell/dotfiles.sh" ] && . "$HOME/.config/shell/dotfiles.sh"'
if ! grep -qF "$FRAGMENT" "$HOME/.bashrc" 2>/dev/null; then
  printf '\n# dotfiles: portable shell customizations\n%s\n' "$FRAGMENT" >> "$HOME/.bashrc"
fi

# ---------- 4. safe git identity ----------
# git config writes are explicitly blessed as safe by the workspace docs. We
# deliberately do NOT enable SSH commit signing or git-lfs here (no signing key
# in the workspace; the git proxy owns github.com credentials).
git config --global user.name  "Doug Finnie"
git config --global user.email "doug.finnie@liberis.com"

echo "[dotfiles] done"

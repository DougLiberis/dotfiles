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

### Coder workspaces (no chezmoi pre-installed)

Liberis Coder engineer workspaces don't use chezmoi directly — they clone this
repo and run **`install.sh`** at the repo root on every start (and on *Refresh
Dotfiles*). Point the workspace's **Dotfiles URI** parameter at this repo and
`install.sh` does the rest: it installs chezmoi into `~/.local/bin` (no root)
and applies from the clone.

It exports `DOTFILES_CODER=1`, which switches on a branch in `.chezmoiignore`
so chezmoi does **not** overwrite workspace-entrypoint–managed files. In a
workspace:

- `~/.bashrc` is left to the entrypoint; `install.sh` appends a single guarded
  line sourcing `~/.config/shell/dotfiles.sh` (the portable env/PATH config).
- `.gitconfig` is skipped (no SSH signing key, and its credential helper would
  fight the git proxy); `install.sh` sets only a safe `user.name`/`user.email`.
- tmux auto-attach, the `.sh` bootstrap scripts (neovim needs `sudo`), and
  terminal-emulator configs are skipped.

`install.sh` must keep its executable bit and LF endings (enforced via
`.gitattributes`) or Coder silently skips it.

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
| `dot_config/gh-dash/config.yml` | `~/.config/gh-dash/config.yml` |

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

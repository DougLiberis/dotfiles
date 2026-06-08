# Repo role: edit clone, not live source

This directory (`D:\dotfiles`) is the **working clone** used to author and commit
changes. It is **not** the source chezmoi reads from on this machine.

- Live chezmoi source: `~/.local/share/chezmoi/` (verify with `chezmoi source-path`)
- Both directories are independent git clones of the same remote.

## Workflow

1. Edit files here (`D:\dotfiles`).
2. Commit and push from here.
3. Sync the live source: `chezmoi update` (pulls + applies), or `git -C ~/.local/share/chezmoi pull && chezmoi apply`.

## Don'ts

- Do not run `chezmoi apply` expecting it to read from `D:\dotfiles` — it won't.
- Do not edit `~/.local/share/chezmoi/` directly for anything you want to keep; those changes won't be in git history unless you commit them there.
- If a quick test requires bypassing the push/pull cycle, copy the touched files into `~/.local/share/chezmoi/` and run `chezmoi apply`, then mirror the edits back here before committing.

## Two consumption modes

- **chezmoi (personal machines)** — `chezmoi init --apply` reads `dot_*` source
  names directly. This is the primary mode.
- **Coder workspaces (no chezmoi)** — Coder clones the repo and runs root
  `install.sh`, which bootstraps chezmoi into `~/.local/bin` and applies from
  the clone. It exports `DOTFILES_CODER=1` to activate a branch in
  `.chezmoiignore` that skips entrypoint-managed files (`.bashrc`, `.gitconfig`,
  tmux, `.sh` bootstrap scripts). `install.sh` must stay `chmod +x` and LF
  (enforced by `.gitattributes`) or Coder silently skips it. Portable shell
  env/PATH lives in `dot_config/shell/dotfiles.sh`, sourced by both rc files.

## Layout notes

- `dot_*` / `dot_config/` — chezmoi source names; rendered to `~/.*` / `~/.config/*` on apply.
- `.chezmoiscripts/run_*` — chezmoi hooks. `*.tmpl` files are templated; the rendered name (without `.tmpl`) is what appears in `.chezmoiignore`.
- `.chezmoiignore` gates files per OS via Go templates (`{{ if eq .chezmoi.os "windows" }}`).

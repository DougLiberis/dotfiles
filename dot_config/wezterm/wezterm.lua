-- WezTerm configuration — managed by chezmoi
-- Source of truth: $HOME\.config\wezterm\wezterm.lua
-- WezTerm searches ~/.config/wezterm/wezterm.lua on all platforms, and this
-- machine also sets XDG_CONFIG_HOME=~/.config, so this file is picked up
-- without needing the legacy ~/.wezterm.lua location.
--
-- Reload: WezTerm watches this file and reloads automatically on save.
-- Docs: https://wezfurlong.org/wezterm/config/files.html

local wezterm = require 'wezterm'
local act = wezterm.action

-- config_builder gives clearer error messages for unknown options.
local config = wezterm.config_builder()

-- ── Shell ────────────────────────────────────────────────────────────────────
-- Default to PowerShell 7 (pwsh), matching the chezmoi-managed pwsh profile.
config.default_prog = { 'pwsh.exe', '-NoLogo' }

-- ── Fonts ────────────────────────────────────────────────────────────────────
-- JetBrains Mono ships bundled with WezTerm, so this renders out of the box.
-- WezTerm also auto-appends its bundled "Symbols Nerd Font Mono", which supplies
-- the powerline/Nerd-Font glyphs that oh-my-posh relies on.
config.font = wezterm.font_with_fallback {
  'JetBrains Mono',
  'Symbols Nerd Font Mono',
}
config.font_size = 11.0
config.warn_about_missing_glyphs = false

-- ── Colour scheme ──────────────────────────────────────────────────────────--
-- Browse built-ins at https://wezfurlong.org/wezterm/colorschemes/
config.color_scheme = 'Catppuccin Mocha'

-- ── Window ─────────────────────────────────────────────────────────────────--
config.window_background_opacity = 0.97
config.window_decorations = 'RESIZE'           -- thin border, native resize
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.adjust_window_size_when_changing_font_size = false
config.initial_cols = 120
config.initial_rows = 32

-- ── Tab bar ──────────────────────────────────────────────────────────────────
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = false
config.show_new_tab_button_in_tab_bar = true

-- ── Behaviour ──────────────────────────────────────────────────────────────--
config.scrollback_lines = 10000
config.default_cursor_style = 'BlinkingBar'
config.audible_bell = 'Disabled'
config.check_for_updates = false

-- ── Rendering ──────────────────────────────────────────────────────────────--
-- WebGpu is the fastest backend on modern Windows GPUs. Fall back to 'OpenGL'
-- here if you hit rendering glitches on older hardware / RDP sessions.
config.front_end = 'WebGpu'
config.max_fps = 120

-- ── Launch menu (right-click the new-tab '+' button) ─────────────────────────
config.launch_menu = {
  { label = 'PowerShell 7',       args = { 'pwsh.exe', '-NoLogo' } },
  { label = 'Windows PowerShell', args = { 'powershell.exe' } },
  { label = 'Command Prompt',     args = { 'cmd.exe' } },
}

-- ── Key bindings ─────────────────────────────────────────────────────────────
-- Pane splits and vim-style navigation, layered on top of the defaults.
config.keys = {
  { key = 'd', mods = 'CTRL|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'e', mods = 'CTRL|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentPane { confirm = true } },
  { key = 'h', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Left' },
  { key = 'l', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Right' },
  { key = 'k', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Up' },
  { key = 'j', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Down' },
  { key = 'Enter', mods = 'ALT', action = act.ToggleFullScreen },
}

return config

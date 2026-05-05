# PowerShell 7 profile — managed by chezmoi
# Source of truth: $HOME\.config\powershell\profile.ps1
# A stub at $PROFILE dot-sources this file (installed by chezmoi run_once script).

# ── PSReadLine ───────────────────────────────────────────────────────────────
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -HistoryNoDuplicates
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}

# ── Aliases (mirrors .bashrc style) ──────────────────────────────────────────
Set-Alias -Name ll -Value Get-ChildItem
function la { Get-ChildItem -Force @args }
function l  { Get-ChildItem @args }

# ── Tooling on PATH ──────────────────────────────────────────────────────────
if (Test-Path "$HOME\.cargo\bin")    { $env:PATH = "$HOME\.cargo\bin;$env:PATH" }
if (Test-Path "$HOME\.dotnet\tools") { $env:PATH = "$HOME\.dotnet\tools;$env:PATH" }

# ── Env vars (mirror .bashrc) ────────────────────────────────────────────────
$env:SF_ORG_MAX_QUERY_LIMIT = "100000"

# ── Local / secret overrides (not tracked) ───────────────────────────────────
$LocalProfile = Join-Path $HOME ".config\powershell\profile.local.ps1"
if (Test-Path $LocalProfile) { . $LocalProfile }

# ── oh-my-posh prompt (optional — uncomment if installed) ────────────────────
# if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
#     oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\catppuccin_mocha.omp.json" | Invoke-Expression
# }

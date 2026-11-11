# PowerShell 7 profile — managed by chezmoi
# Source of truth: $HOME\.config\powershell\profile.ps1
# A stub at $PROFILE dot-sources this file (installed by chezmoi run_once script).

# ── Interactive session detection ────────────────────────────────────────────
# Agent/automation terminals typically run with stdin and/or stdout redirected;
# skip line-editing and prompt theming there so they stay fast and undecorated.
$IsInteractiveSession = -not ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected)

# ── PSReadLine ───────────────────────────────────────────────────────────────
if ($IsInteractiveSession -and (Get-Module -ListAvailable -Name PSReadLine)) {
    Import-Module PSReadLine
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -HistoryNoDuplicates
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

    # Source - https://stackoverflow.com/a/77959050
    # Posted by Santiago Squarzon, modified by community. See post 'Timeline' for change history
    # Retrieved 2026-06-26, License - CC BY-SA 4.0
    Set-PSReadLineKeyHandler -Chord Ctrl+Shift+Delete -ScriptBlock {
        $in = ''
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref] $in, [ref] $null)

        if ([string]::IsNullOrWhiteSpace($in)) {
            return
        }

        $historyPath = (Get-PSReadLineOption).HistorySavePath

        # only way to "refresh" the history in the current session is to clear it
        [Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory()
        $content = [System.IO.File]::ReadAllLines($historyPath)
        Clear-Content $historyPath

        foreach ($line in $content) {
            if ($line.StartsWith($in, [System.StringComparison]::InvariantCultureIgnoreCase)) {
                continue
            }

            # and re-add it (excluding the line to remove)
            [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($line)
        }

        [Microsoft.PowerShell.PSConsoleReadLine]::DeleteLine()
    }
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

# ── Prompt: starship (config: ~/.config/starship.toml), oh-my-posh fallback ──
# The full init script is cached and only regenerated when starship.exe changes;
# `starship init powershell` would otherwise spawn starship twice per launch.
$starshipCmd = if ($IsInteractiveSession) { Get-Command starship -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1 }
if ($starshipCmd) {
    $starshipInit = Join-Path $env:LOCALAPPDATA 'starship\init.ps1'
    if (-not (Test-Path $starshipInit) -or
        (Get-Item $starshipCmd.Source).LastWriteTimeUtc -gt (Get-Item $starshipInit).LastWriteTimeUtc) {
        New-Item -ItemType Directory -Force -Path (Split-Path $starshipInit) | Out-Null
        & $starshipCmd.Source init powershell --print-full-init | Set-Content -Path $starshipInit -Encoding utf8
    }
    . $starshipInit

    # Report the cwd to Windows Terminal (OSC 9;9) so "duplicate" splits/tabs open
    # in the same folder. Starship calls this hook before each prompt.
    function Invoke-Starship-PreCommand {
        $loc = $executionContext.SessionState.Path.CurrentLocation
        if ($loc.Provider.Name -eq 'FileSystem') {
            $host.UI.Write("`e]9;9;`"$($loc.ProviderPath)`"`e\")
        }
    }
}
elseif ($IsInteractiveSession -and (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    $ompConfig = Join-Path $HOME '.oh-my-posh-theme.omp.json'
    if (Test-Path $ompConfig) {
        oh-my-posh init pwsh --config $ompConfig | Invoke-Expression
    }
}

$ErrorActionPreference = 'Stop'

$installRoot = Join-Path $HOME '.terminal-ninja'
$cmdScriptPath = Join-Path (Join-Path $env:LocalAppData 'clink') 'terminalninja.lua'

Write-Host 'Uninstalling TerminalNinja from PowerShell, cmd, bash, zsh, and WSL...' -ForegroundColor Cyan

function Remove-ManagedBlock {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return
    }

    $content = Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) {
        return
    }

    $pattern = '(?s)\r?\n?# >>> TerminalNinja >>>.*?# <<< TerminalNinja <<<\r?\n?'
    $updated = [regex]::Replace($content, $pattern, '')
    Set-Content -Path $Path -Value $updated
}

function Get-WslDistros {
    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
        return @()
    }

    try {
        $raw = (& wsl.exe -l -q 2>$null | Out-String)
        return @(
            $raw -split "`r?`n" |
                ForEach-Object { $_ -replace "`0", '' } |
                ForEach-Object { "$($_)".Trim() } |
                Where-Object {
                    -not [string]::IsNullOrWhiteSpace($_) -and
                    $_ -notlike 'docker-desktop*'
                }
        )
    } catch {
        Write-Warning "Unable to enumerate WSL distributions: $_"
        return @()
    }
}

function Remove-WslManagedBlock {
    param(
        [string]$Distro,
        [string]$TargetFile
    )

    $script = @"
if [ -f $TargetFile ]; then
    sed -i '/# >>> TerminalNinja >>>/,/# <<< TerminalNinja <<</d' $TargetFile
fi
"@

    & wsl.exe -d $Distro sh -lc $script | Out-Null
}

Remove-ManagedBlock -Path $PROFILE
Remove-ManagedBlock -Path (Join-Path $HOME '.bashrc')
Remove-ManagedBlock -Path (Join-Path $HOME '.zshrc')

if (Test-Path $cmdScriptPath) {
    Remove-Item $cmdScriptPath -Force
    Write-Host "Removed cmd Clink script: $cmdScriptPath" -ForegroundColor Green
}

$wslDistros = Get-WslDistros
foreach ($distro in $wslDistros) {
    try {
        Remove-WslManagedBlock -Distro $distro -TargetFile '~/.bashrc'
        Remove-WslManagedBlock -Distro $distro -TargetFile '~/.zshrc'
        Write-Host "Removed WSL profile blocks from: $distro" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to update WSL distro '$distro': $_"
    }
}

if (Test-Path $installRoot) {
    Remove-Item $installRoot -Recurse -Force
    Write-Host "Removed $installRoot" -ForegroundColor Green
}

Write-Host 'Uninstallation complete. Restart your shell sessions to finish cleanup.' -ForegroundColor Cyan

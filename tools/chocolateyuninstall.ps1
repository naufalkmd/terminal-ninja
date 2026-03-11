$ErrorActionPreference = 'Stop'

$installRoot = Join-Path $HOME '.terminal-ninja'
$statePath = Join-Path $installRoot 'install-state.json'
$cmdScriptPath = Join-Path (Join-Path $env:LocalAppData 'clink') 'terminalninja.lua'
$managedVsCodeFontFamily = 'FiraCode Nerd Font'

Write-Host 'Uninstalling TerminalNinja from PowerShell, cmd, bash, zsh, and WSL...' -ForegroundColor Cyan

function Get-StateProperty {
    param(
        [object]$Object,
        [string]$Name
    )

    if ($null -eq $Object) {
        return $null
    }

    $property = $Object.PSObject.Properties[$Name]
    if ($property) {
        return $property.Value
    }

    return $null
}

function Get-InstallState {
    if (-not (Test-Path $statePath)) {
        return [pscustomobject]@{}
    }

    try {
        $raw = Get-Content -Path $statePath -Raw -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($raw)) {
            return [pscustomobject]@{}
        }

        return $raw | ConvertFrom-Json
    } catch {
        Write-Warning "Unable to read TerminalNinja install state at '$statePath': $_"
        return [pscustomobject]@{}
    }
}

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

function Restore-VSCodeTerminalFontFamily {
    param([object]$State)

    if (-not [bool](Get-StateProperty -Object $State -Name 'VSCodeTerminalFontFamilyManaged')) {
        return
    }

    $settingsPath = Get-StateProperty -Object $State -Name 'VSCodeSettingsPath'
    if (-not $settingsPath -and $env:APPDATA) {
        $settingsPath = Join-Path $env:APPDATA 'Code\User\settings.json'
    }

    if (-not $settingsPath -or -not (Test-Path $settingsPath)) {
        return
    }

    try {
        $raw = Get-Content -Path $settingsPath -Raw -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($raw)) {
            $settings = [pscustomobject]@{}
        } else {
            $settings = $raw | ConvertFrom-Json
        }
    } catch {
        Write-Warning "Unable to restore VS Code terminal font setting: $_"
        return
    }

    $managedFontFamily = Get-StateProperty -Object $State -Name 'VSCodeTerminalFontFamilyManagedValue'
    if (-not $managedFontFamily) {
        $managedFontFamily = $managedVsCodeFontFamily
    }

    $fontFamilyProperty = $settings.PSObject.Properties['terminal.integrated.fontFamily']
    $currentFontFamily = if ($fontFamilyProperty) { [string]$fontFamilyProperty.Value } else { $null }

    if ($currentFontFamily -ne $managedFontFamily) {
        Write-Host 'Skipping VS Code terminal font restore because it was changed after TerminalNinja install.' -ForegroundColor DarkYellow
        return
    }

    $hadValue = [bool](Get-StateProperty -Object $State -Name 'VSCodeTerminalFontFamilyHadValue')
    if ($hadValue) {
        $originalFontFamily = Get-StateProperty -Object $State -Name 'VSCodeTerminalFontFamilyOriginalValue'
        $settings | Add-Member -MemberType NoteProperty -Name 'terminal.integrated.fontFamily' -Value $originalFontFamily -Force
    } else {
        $null = $settings.PSObject.Properties.Remove('terminal.integrated.fontFamily')
    }

    $settings | ConvertTo-Json -Depth 100 | Set-Content -Path $settingsPath
    Write-Host 'Restored VS Code terminal font setting.' -ForegroundColor Green
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

Restore-VSCodeTerminalFontFamily -State (Get-InstallState)

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

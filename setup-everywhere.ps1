param(
    [Alias('InstallWslOhMyPosh')]
    [switch]$InstallWslStarship,
    [switch]$VerifyOnly,
    [switch]$SkipVerification,
    [switch]$UseChocolatey,
    [string[]]$Targets
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$installerPath = Join-Path $repoRoot 'tools\chocolateyinstall.ps1'
$markerStart = '# >>> TerminalNinja >>>'
$installRoot = Join-Path $HOME '.terminal-ninja'
$cmdScriptPath = Join-Path (Join-Path $env:LocalAppData 'clink') 'terminalninja.lua'

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

function Invoke-WslShell {
    param(
        [string]$Distro,
        [string]$Command
    )

    & wsl.exe -d $Distro sh -lc $Command *> $null
    return $LASTEXITCODE
}

function Get-WindowsStarshipCommand {
    $starship = Get-Command starship.exe -ErrorAction SilentlyContinue
    if (-not $starship) {
        $starship = Get-Command starship -ErrorAction SilentlyContinue
    }

    return $starship
}

function Get-WindowsClinkCommand {
    foreach ($commandName in @('clink_x64.exe', 'clink.exe', 'clink.bat', 'clink')) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($command) {
            return $command
        }
    }

    foreach ($path in @(
        (Join-Path $env:LocalAppData 'clink\clink_x64.exe'),
        (Join-Path $env:LocalAppData 'clink\clink.bat'),
        (Join-Path $HOME 'scoop\apps\clink\current\clink_x64.exe'),
        (Join-Path $HOME 'scoop\apps\clink\current\clink.bat'),
        (Join-Path $env:ProgramFiles 'clink\clink_x64.exe'),
        (Join-Path $env:ProgramFiles 'clink\clink.bat')
    )) {
        if ($path -and (Test-Path $path)) {
            return Get-Item $path
        }
    }

    return $null
}

function Get-DetectedTargets {
    $detected = [System.Collections.Generic.List[object]]::new()

    $detected.Add([pscustomobject]@{ Id = 'powershell'; Label = 'PowerShell / pwsh'; Supported = $true })

    if ((Get-Command bash -ErrorAction SilentlyContinue) -or (Test-Path (Join-Path $HOME '.bashrc'))) {
        $detected.Add([pscustomobject]@{ Id = 'bash'; Label = 'bash (Windows home rc)'; Supported = $true })
    }

    if ((Get-Command zsh -ErrorAction SilentlyContinue) -or (Test-Path (Join-Path $HOME '.zshrc'))) {
        $detected.Add([pscustomobject]@{ Id = 'zsh'; Label = 'zsh (Windows home rc)'; Supported = $true })
    }

    foreach ($distro in Get-WslDistros) {
        $detected.Add([pscustomobject]@{ Id = "wsl:$distro"; Label = "WSL $distro"; Supported = $true })
    }

    if (Get-Command cmd.exe -ErrorAction SilentlyContinue) {
        $detected.Add([pscustomobject]@{ Id = 'cmd'; Label = 'cmd (via Clink)'; Supported = $true })
    }

    return $detected
}

function Select-TargetsInteractively {
    param([object[]]$DetectedTargets)

    $supportedTargets = @($DetectedTargets | Where-Object { $_.Supported })
    if ($supportedTargets.Count -eq 0) {
        return @()
    }

    Write-Host 'Detected terminal targets:' -ForegroundColor Cyan
    for ($index = 0; $index -lt $DetectedTargets.Count; $index++) {
        $target = $DetectedTargets[$index]
        $suffix = if ($target.Supported) { '' } else { ' [unsupported]' }
        Write-Host ("  {0}. {1}{2}" -f ($index + 1), $target.Label, $suffix) -ForegroundColor White
    }

    $selection = Read-Host 'Enter A for all supported targets, or numbers separated by commas [A]'
    if ([string]::IsNullOrWhiteSpace($selection) -or $selection.Trim().Equals('A', [System.StringComparison]::OrdinalIgnoreCase)) {
        return @($supportedTargets.Id)
    }

    $selectedIds = [System.Collections.Generic.List[string]]::new()
    foreach ($token in ($selection -split ',')) {
        $trimmed = $token.Trim()
        if (-not $trimmed) {
            continue
        }

        $parsedNumber = 0
        if (-not [int]::TryParse($trimmed, [ref]$parsedNumber)) {
            throw "Invalid selection '$trimmed'. Enter A or comma-separated numbers."
        }

        if ($parsedNumber -lt 1 -or $parsedNumber -gt $DetectedTargets.Count) {
            throw "Selection '$trimmed' is out of range."
        }

        $target = $DetectedTargets[$parsedNumber - 1]
        if (-not $target.Supported) {
            Write-Warning "Skipping unsupported target: $($target.Label)"
            continue
        }

        if (-not $selectedIds.Contains($target.Id)) {
            $selectedIds.Add($target.Id)
        }
    }

    if ($selectedIds.Count -eq 0) {
        throw 'No supported targets were selected.'
    }

    return @($selectedIds)
}

function Test-TargetSelected {
    param(
        [string]$TargetId,
        [string[]]$SelectedTargets
    )

    if (-not $SelectedTargets -or $SelectedTargets.Count -eq 0) {
        return $true
    }

    return [bool]($SelectedTargets | Where-Object { $_.Equals($TargetId, [System.StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1)
}

function Test-ManagedBlock {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return $false
    }

    $content = Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) {
        return $false
    }

    return $content.Contains($markerStart)
}

function Install-WslStarship {
    param([string]$Distro)

    $existingPath = & wsl.exe -d $Distro sh -lc 'PATH="$HOME/.local/bin:$PATH"; command -v starship 2>/dev/null || true'
    $existingPath = ($existingPath | Out-String).Trim()
    if ($existingPath) {
        Write-Host "WSL distro '$Distro': starship ready" -ForegroundColor Green
        return
    }

        $script = 'set -e; export PATH="$HOME/.local/bin:$PATH"; if command -v starship >/dev/null 2>&1; then exit 0; fi; if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then echo missing-downloader; exit 12; fi; mkdir -p "$HOME/.local/bin"; if command -v curl >/dev/null 2>&1; then curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"; else wget -qO- https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"; fi'

    $exitCode = Invoke-WslShell -Distro $Distro -Command $script
    if ($exitCode -eq 0) {
        Write-Host "WSL distro '$Distro': starship ready" -ForegroundColor Green
        return
    }

    $installedPath = & wsl.exe -d $Distro sh -lc 'PATH="$HOME/.local/bin:$PATH"; command -v starship 2>/dev/null || true'
    $installedPath = ($installedPath | Out-String).Trim()
    if ($installedPath) {
        Write-Host "WSL distro '$Distro': starship ready" -ForegroundColor Green
        return
    }

    if ($exitCode -eq 12) {
        Write-Warning "WSL distro '$Distro' is missing curl/wget; cannot auto-install starship."
        return
    }

    Write-Warning "WSL distro '$Distro': starship install failed with exit code $exitCode"
}

function Get-PowerShellVerification {
    $profilePath = $PROFILE
    $managedBlock = Test-ManagedBlock -Path $profilePath
    $sharedConfig = (Test-Path (Join-Path $installRoot 'terminalninja.ps1')) -and (Test-Path (Join-Path $installRoot 'starship.toml'))
    $starship = Get-WindowsStarshipCommand

    [pscustomobject]@{
        Shell = 'PowerShell'
        ManagedBlock = $managedBlock
        SharedConfig = $sharedConfig
        PromptBinary = [bool]$starship
        Details = if ($starship) { $starship.Source } else { 'starship not found in Windows PATH' }
    }
}

function Get-WindowsRcVerification {
    param(
        [string]$Shell,
        [string]$Path,
        [string]$ScriptName
    )

    [pscustomobject]@{
        Shell = $Shell
        ManagedBlock = Test-ManagedBlock -Path $Path
        SharedConfig = (Test-Path (Join-Path $installRoot $ScriptName)) -and (Test-Path (Join-Path $installRoot 'starship.toml'))
        PromptBinary = [bool](Get-WindowsStarshipCommand)
        Details = $Path
    }
}

function Get-WslVerification {
    param([string]$Distro)

    $bashBlockExit = Invoke-WslShell -Distro $Distro -Command "grep -q '# >>> TerminalNinja >>>' ~/.bashrc 2>/dev/null"
    $zshBlockExit = Invoke-WslShell -Distro $Distro -Command "grep -q '# >>> TerminalNinja >>>' ~/.zshrc 2>/dev/null"
    $starshipPath = & wsl.exe -d $Distro sh -lc 'PATH="$HOME/.local/bin:$PATH"; command -v starship 2>/dev/null || true'
    $starshipPath = ($starshipPath | Out-String).Trim()

    [pscustomobject]@{
        Shell = "WSL:$Distro"
        ManagedBlock = ($bashBlockExit -eq 0 -or $zshBlockExit -eq 0)
        SharedConfig = (Test-Path (Join-Path $installRoot 'terminalninja.bash')) -and (Test-Path (Join-Path $installRoot 'terminalninja.zsh')) -and (Test-Path (Join-Path $installRoot 'starship.toml'))
        PromptBinary = [bool]$starshipPath
        Details = if ($starshipPath) { $starshipPath } else { 'starship not found in distro PATH' }
    }
}

function Get-CmdVerification {
    $starship = Get-WindowsStarshipCommand
    $clink = Get-WindowsClinkCommand

    [pscustomobject]@{
        Shell = 'cmd'
        ManagedBlock = Test-Path $cmdScriptPath
        SharedConfig = Test-Path (Join-Path $installRoot 'starship.toml')
        PromptBinary = [bool]($starship -and $clink)
        Details = if (-not $clink) { 'Clink not found in Windows PATH or standard install locations' } elseif (-not $starship) { 'starship not found in Windows PATH' } else { $cmdScriptPath }
    }
}

$detectedTargets = @(Get-DetectedTargets)
$selectedTargets = @($Targets)

if (-not $VerifyOnly -and (-not $selectedTargets -or $selectedTargets.Count -eq 0)) {
    $selectedTargets = @(Select-TargetsInteractively -DetectedTargets $detectedTargets)
}

if ($selectedTargets.Count -gt 0) {
    Write-Host ("Selected targets: {0}" -f ($selectedTargets -join ', ')) -ForegroundColor Cyan
}

if (-not $VerifyOnly) {
    if ($UseChocolatey) {
        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            throw 'Chocolatey is not installed. Re-run without -UseChocolatey to use the local installer script.'
        }

        Write-Host 'Running Chocolatey package install...' -ForegroundColor Cyan
        $previousTargetsEnv = $env:TERMINALNINJA_TARGETS
        if ($selectedTargets.Count -gt 0) {
            $env:TERMINALNINJA_TARGETS = $selectedTargets -join ','
        }

        choco upgrade terminalninja -y --source .

        if ($null -ne $previousTargetsEnv) {
            $env:TERMINALNINJA_TARGETS = $previousTargetsEnv
        } else {
            Remove-Item Env:TERMINALNINJA_TARGETS -ErrorAction SilentlyContinue
        }

        if ($LASTEXITCODE -ne 0) {
            throw "Chocolatey install failed with exit code $LASTEXITCODE"
        }
    } else {
        Write-Host 'Running local TerminalNinja installer...' -ForegroundColor Cyan
        & $installerPath -Targets $selectedTargets
    }
}

$wslDistros = Get-WslDistros
if ($InstallWslStarship -and $wslDistros.Count -gt 0) {
    Write-Host 'Installing starship into WSL distros...' -ForegroundColor Cyan
    foreach ($distro in $wslDistros) {
        if (-not (Test-TargetSelected -TargetId ("wsl:$distro") -SelectedTargets $selectedTargets)) {
            continue
        }
        Install-WslStarship -Distro $distro
    }
}

if (-not $SkipVerification) {
    Write-Host 'Verifying managed blocks and prompt dependencies...' -ForegroundColor Cyan

    $results = @()

    if (Test-TargetSelected -TargetId 'powershell' -SelectedTargets $selectedTargets) {
        $results += Get-PowerShellVerification
    }

    if (Test-TargetSelected -TargetId 'cmd' -SelectedTargets $selectedTargets) {
        $results += Get-CmdVerification
    }

    if (Test-TargetSelected -TargetId 'bash' -SelectedTargets $selectedTargets) {
        $results += Get-WindowsRcVerification -Shell 'bash(rc)' -Path (Join-Path $HOME '.bashrc') -ScriptName 'terminalninja.bash'
    }

    if (Test-TargetSelected -TargetId 'zsh' -SelectedTargets $selectedTargets) {
        $results += Get-WindowsRcVerification -Shell 'zsh(rc)' -Path (Join-Path $HOME '.zshrc') -ScriptName 'terminalninja.zsh'
    }

    foreach ($distro in $wslDistros) {
        if (Test-TargetSelected -TargetId ("wsl:$distro") -SelectedTargets $selectedTargets) {
            $results += Get-WslVerification -Distro $distro
        }
    }

    $results | Format-Table -AutoSize

    $failed = $results | Where-Object {
        ($_.ManagedBlock -eq $false) -or ($_.SharedConfig -eq $false) -or ($_.PromptBinary -eq $false)
    }

    if ($failed) {
        Write-Warning 'One or more shells are missing a managed block, shared config, or Starship binary.'
        exit 1
    }

    Write-Host 'Verification passed.' -ForegroundColor Green
}
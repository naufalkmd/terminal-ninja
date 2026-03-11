param(
    [string[]]$Targets
)

$ErrorActionPreference = 'Stop'

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$installRoot = Join-Path $HOME '.terminal-ninja'
$clinkScriptsDir = Join-Path $env:LocalAppData 'clink'
$cmdScriptPath = Join-Path $clinkScriptsDir 'terminalninja.lua'
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$markerStart = '# >>> TerminalNinja >>>'
$markerEnd = '# <<< TerminalNinja <<<'
$backups = [System.Collections.Generic.List[string]]::new()

if ((-not $Targets -or $Targets.Count -eq 0) -and $env:TERMINALNINJA_TARGETS) {
    $Targets = @(
        $env:TERMINALNINJA_TARGETS -split ',' |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ }
    )
}

$selectedTargets = @($Targets)

function Test-TargetSelected {
    param([string]$TargetId)

    if (-not $selectedTargets -or $selectedTargets.Count -eq 0) {
        return $true
    }

    return [bool]($selectedTargets | Where-Object { $_.Equals($TargetId, [System.StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1)
}

if ($selectedTargets.Count -gt 0) {
    Write-Host ("Installing TerminalNinja for selected targets: {0}" -f ($selectedTargets -join ', ')) -ForegroundColor Cyan
} else {
    Write-Host 'Installing TerminalNinja across PowerShell, bash, zsh, and WSL...' -ForegroundColor Cyan
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

function Install-WindowsStarship {
    if (Get-WindowsStarshipCommand) {
        Write-Host 'Starship already installed on Windows.' -ForegroundColor Green
        return
    }

    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Write-Host 'Installing Starship with Scoop...' -ForegroundColor Cyan
        scoop install starship
        if ($LASTEXITCODE -eq 0 -or (Get-WindowsStarshipCommand)) {
            return
        }
    }

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host 'Installing Starship with winget...' -ForegroundColor Cyan
        winget install --id Starship.Starship -e --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0 -or (Get-WindowsStarshipCommand)) {
            return
        }
    }

    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host 'Installing Starship with Chocolatey...' -ForegroundColor Cyan
        choco install starship -y --no-progress
        if ($LASTEXITCODE -eq 0 -or (Get-WindowsStarshipCommand)) {
            return
        }
    }

    Write-Warning 'Unable to install Starship automatically on Windows. Install it manually and rerun verification.'
}

function Install-WindowsClink {
    if (Get-WindowsClinkCommand) {
        Write-Host 'Clink already installed on Windows.' -ForegroundColor Green
        return
    }

    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Write-Host 'Installing Clink with Scoop...' -ForegroundColor Cyan
        scoop install clink
        if ($LASTEXITCODE -eq 0 -or (Get-WindowsClinkCommand)) {
            return
        }
    }

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host 'Installing Clink with winget...' -ForegroundColor Cyan
        winget install --id chrisant996.Clink -e --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0 -or (Get-WindowsClinkCommand)) {
            return
        }
    }

    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host 'Installing Clink with Chocolatey...' -ForegroundColor Cyan
        choco install clink -y --no-progress
        if ($LASTEXITCODE -eq 0 -or (Get-WindowsClinkCommand)) {
            return
        }
    }

    Write-Warning 'Unable to install Clink automatically on Windows. Install it manually and rerun verification.'
}

function Backup-File {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return
    }

    $backupPath = "$Path.terminalninja.backup.$timestamp"
    Copy-Item $Path $backupPath -Force
    $backups.Add($backupPath)
}

function Ensure-ParentDirectory {
    param([string]$Path)

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
}

function Set-ManagedBlock {
    param(
        [string]$Path,
        [string]$Block
    )

    Ensure-ParentDirectory -Path $Path

    if (-not (Test-Path $Path)) {
        Set-Content -Path $Path -Value ""
    }

    Backup-File -Path $Path
    $existing = Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue
    if ($null -eq $existing) {
        $existing = ''
    }

    $pattern = '(?s)\r?\n?# >>> TerminalNinja >>>.*?# <<< TerminalNinja <<<\r?\n?'
    $updated = [regex]::Replace($existing, $pattern, '')

    if ($updated.Length -gt 0 -and -not $updated.EndsWith("`r`n")) {
        $updated += "`r`n"
    }

    $updated += $Block.Trim() + "`r`n"
    Set-Content -Path $Path -Value $updated
}

function Set-CmdManagedScript {
    param([string]$Path)

    $content = @'
local install_root = os.getenv('USERPROFILE') .. '\\.terminal-ninja'
os.setenv('STARSHIP_CONFIG', install_root .. '\\starship.toml')
load(io.popen('starship init cmd'):read("*a"))()
'@

    Ensure-ParentDirectory -Path $Path
    if (Test-Path $Path) {
        Backup-File -Path $Path
    }

    Set-Content -Path $Path -Value $content
}

function Convert-ToWslPath {
    param([string]$WindowsPath)

    $normalized = $WindowsPath -replace '\\', '/'
    if ($normalized -match '^([A-Za-z]):/(.*)$') {
        return "/mnt/$($matches[1].ToLower())/$($matches[2])"
    }

    throw "Unsupported Windows path for WSL conversion: $WindowsPath"
}

function Install-WslAssets {
    param(
        [string]$Distro,
        [string]$WindowsInstallRoot
    )

    $wslInstallRoot = Convert-ToWslPath -WindowsPath $WindowsInstallRoot
    $script = @(
        'install_root="$HOME/.terminal-ninja"',
        'mkdir -p "$install_root"',
        ('cp "' + $wslInstallRoot + '/terminalninja.bash" "$install_root/terminalninja.bash"'),
        ('cp "' + $wslInstallRoot + '/terminalninja.zsh" "$install_root/terminalninja.zsh"'),
        ('cp "' + $wslInstallRoot + '/starship.toml" "$install_root/starship.toml"'),
        'chmod 0644 "$install_root/terminalninja.bash" "$install_root/terminalninja.zsh" "$install_root/starship.toml"'
    ) -join "`n"

    & wsl.exe -d $Distro sh -lc $script | Out-Null
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

function Set-WslManagedBlock {
    param(
        [string]$Distro,
        [string]$TargetFile,
        [string]$SourceFile
    )

    $script = @(
        ('mkdir -p "$(dirname ' + $TargetFile + ')"'),
        ('touch ' + $TargetFile),
        ('sed -i ''/# >>> TerminalNinja >>>/,/# <<< TerminalNinja <<</d'' ' + $TargetFile),
        ('cat >> ' + $TargetFile + ' <<''EOF'''),
        '# >>> TerminalNinja >>>',
        ('[ -f "' + $SourceFile + '" ] && . "' + $SourceFile + '"'),
        '# <<< TerminalNinja <<<',
        'EOF'
    ) -join "`n"

    & wsl.exe -d $Distro sh -lc $script | Out-Null
}

New-Item -ItemType Directory -Path $installRoot -Force | Out-Null

$assets = @(
    'terminalninja.ps1',
    'starship.toml',
    'terminalninja.bash',
    'terminalninja.zsh',
    'FiraCodeNerdFont-Medium.ttf'
)

foreach ($asset in $assets) {
    $source = Join-Path $toolsDir $asset
    if (Test-Path $source) {
        Copy-Item $source (Join-Path $installRoot $asset) -Force
    }
}

if ((Test-TargetSelected 'powershell') -or (Test-TargetSelected 'bash') -or (Test-TargetSelected 'zsh')) {
    Install-WindowsStarship
}

if (Test-TargetSelected 'cmd') {
    Install-WindowsStarship
    Install-WindowsClink
}

$pwshBlock = @'
# >>> TerminalNinja >>>
$terminalNinjaHome = Join-Path $HOME '.terminal-ninja'
$terminalNinjaProfile = Join-Path $terminalNinjaHome 'terminalninja.ps1'
if (Test-Path $terminalNinjaProfile) {
    . $terminalNinjaProfile
}
# <<< TerminalNinja <<<
'@

$bashBlock = @'
# >>> TerminalNinja >>>
[ -f "$HOME/.terminal-ninja/terminalninja.bash" ] && . "$HOME/.terminal-ninja/terminalninja.bash"
# <<< TerminalNinja <<<
'@

$zshBlock = @'
# >>> TerminalNinja >>>
[ -f "$HOME/.terminal-ninja/terminalninja.zsh" ] && . "$HOME/.terminal-ninja/terminalninja.zsh"
# <<< TerminalNinja <<<
'@

if (Test-TargetSelected 'powershell') {
    Set-ManagedBlock -Path $PROFILE -Block $pwshBlock
}

if (Test-TargetSelected 'bash') {
    Set-ManagedBlock -Path (Join-Path $HOME '.bashrc') -Block $bashBlock
}

if (Test-TargetSelected 'zsh') {
    Set-ManagedBlock -Path (Join-Path $HOME '.zshrc') -Block $zshBlock
}

if (Test-TargetSelected 'cmd') {
    Set-CmdManagedScript -Path $cmdScriptPath
}

Write-Host 'Checking PSReadLine version...' -ForegroundColor Cyan
$psReadLine = Get-Module -Name PSReadLine -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1

if (-not $psReadLine -or $psReadLine.Version -lt [Version]'2.1.0') {
    Write-Host 'Installing PSReadLine 2.4.5+...' -ForegroundColor Yellow
    Install-Module -Name PSReadLine -Force -SkipPublisherCheck -Scope CurrentUser
    Write-Host 'PSReadLine installed.' -ForegroundColor Green
} else {
    Write-Host "PSReadLine $($psReadLine.Version) already installed" -ForegroundColor Green
}

$wslDistros = Get-WslDistros
if ($wslDistros.Count -gt 0) {
    foreach ($distro in $wslDistros) {
        if (-not (Test-TargetSelected ("wsl:$distro"))) {
            continue
        }

        try {
            Install-WslAssets -Distro $distro -WindowsInstallRoot $installRoot
            Set-WslManagedBlock -Distro $distro -TargetFile '~/.bashrc' -SourceFile '$HOME/.terminal-ninja/terminalninja.bash'
            Set-WslManagedBlock -Distro $distro -TargetFile '~/.zshrc' -SourceFile '$HOME/.terminal-ninja/terminalninja.zsh'
            Write-Host "Configured WSL distro: $distro" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to configure WSL distro '$distro': $_"
        }
    }
} else {
    Write-Host 'No WSL distributions detected. Skipping WSL profile wiring.' -ForegroundColor DarkYellow
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host 'Installation Complete' -ForegroundColor Green
Write-Host '========================================' -ForegroundColor Cyan
Write-Host 'Restart your shell sessions to load TerminalNinja everywhere.' -ForegroundColor Yellow
Write-Host "`nInstalled shells:" -ForegroundColor Cyan
if (Test-TargetSelected 'powershell') {
    Write-Host '  - PowerShell / pwsh' -ForegroundColor White
}
if (Test-TargetSelected 'bash') {
    Write-Host '  - bash profiles in Windows home' -ForegroundColor White
}
if (Test-TargetSelected 'zsh') {
    Write-Host '  - zsh profiles in Windows home' -ForegroundColor White
}
if (Test-TargetSelected 'cmd') {
    Write-Host '  - cmd via Clink scripts' -ForegroundColor White
}
foreach ($distro in $wslDistros) {
    if (Test-TargetSelected ("wsl:$distro")) {
        Write-Host "  - WSL $distro" -ForegroundColor White
    }
}
Write-Host "`nNotes:" -ForegroundColor Cyan
Write-Host '  - Starship provides the shared prompt visuals across shells.' -ForegroundColor White
Write-Host '  - Shared aliases and helper functions are sourced from ~/.terminal-ninja.' -ForegroundColor White

if ($backups.Count -gt 0) {
    Write-Host "`nBackups created:" -ForegroundColor Yellow
    $backups | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
}

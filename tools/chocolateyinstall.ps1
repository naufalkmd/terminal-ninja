$ErrorActionPreference = 'Stop'

$packageName = 'terminalninja'
$profileUrl = 'https://raw.githubusercontent.com/YOUR_USERNAME/terminalninja/main/Microsoft.PowerShell_profile.ps1'

Write-Host "Installing TerminalNinja 🥷..." -ForegroundColor Cyan

# Backup existing profile if it exists
if (Test-Path $PROFILE) {
    $backupPath = "$PROFILE.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Write-Host "Backing up existing profile to: $backupPath" -ForegroundColor Yellow
    Copy-Item $PROFILE $backupPath
}

# Create profile directory if it doesn't exist
$profileDir = Split-Path $PROFILE
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# Download profile
Write-Host "Downloading profile from GitHub..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $profileUrl -OutFile $PROFILE -UseBasicParsing
    Write-Host "Profile installed successfully!" -ForegroundColor Green
} catch {
    Write-Error "Failed to download profile: $_"
    exit 1
}

# Install PSReadLine 2.4.5+ if needed
Write-Host "Checking PSReadLine version..." -ForegroundColor Cyan
$psReadLine = Get-Module -Name PSReadLine -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1

if (-not $psReadLine -or $psReadLine.Version -lt [Version]"2.1.0") {
    Write-Host "Installing PSReadLine 2.4.5+..." -ForegroundColor Yellow
    Install-Module -Name PSReadLine -Force -SkipPublisherCheck -Scope CurrentUser
    Write-Host "PSReadLine installed!" -ForegroundColor Green
} else {
    Write-Host "PSReadLine $($psReadLine.Version) already installed" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Please RESTART your PowerShell terminal to apply changes." -ForegroundColor Yellow
Write-Host "`nFeatures:" -ForegroundColor Cyan
Write-Host "  - Auto-suggestions and completions" -ForegroundColor White
Write-Host "  - Git, NPM, Docker, Choco, Brew completions" -ForegroundColor White
Write-Host "  - Auto-correct for common typos" -ForegroundColor White
Write-Host "  - Custom aliases (ll, gs, gaa, gc, gp)" -ForegroundColor White
Write-Host "`nYour old profile was backed up to:" -ForegroundColor Yellow
Write-Host "  $backupPath" -ForegroundColor Gray

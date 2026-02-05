$ErrorActionPreference = 'Stop'

Write-Host "Uninstalling TerminalNinja 🥷..." -ForegroundColor Cyan

# Find the most recent backup
$backups = Get-ChildItem "$PROFILE.backup.*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending

if ($backups) {
    $latestBackup = $backups[0]
    Write-Host "Restoring backup from: $($latestBackup.Name)" -ForegroundColor Yellow
    Copy-Item $latestBackup.FullName $PROFILE -Force
    Write-Host "Profile restored from backup!" -ForegroundColor Green
} else {
    Write-Host "No backup found. Removing profile..." -ForegroundColor Yellow
    if (Test-Path $PROFILE) {
        Remove-Item $PROFILE -Force
        Write-Host "Profile removed!" -ForegroundColor Green
    }
}

Write-Host "Uninstallation complete. Please restart your PowerShell terminal." -ForegroundColor Cyan

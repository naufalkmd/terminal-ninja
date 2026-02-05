# Setup Script for Package Publishing
# This script helps you prepare your package for publishing

Write-Host "TerminalNinja 🥷 - Publishing Setup" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

# Get user information
Write-Host "`nPlease provide the following information:" -ForegroundColor Yellow
$githubUsername = Read-Host "GitHub Username"
$authorName = Read-Host "Your Name"
$repoName = Read-Host "Repository Name (default: terminalninja)"

if ([string]::IsNullOrWhiteSpace($repoName)) {
    $repoName = "terminalninja"
}

Write-Host "`nUpdating files..." -ForegroundColor Cyan

# Update nuspec file
$nuspecPath = ".\terminalninja.nuspec"
if (Test-Path $nuspecPath) {
    $content = Get-Content $nuspecPath -Raw
    $content = $content -replace 'YOUR_USERNAME', $githubUsername
    $content = $content -replace 'YOUR_NAME', $authorName
    $content = $content -replace 'YOUR_REPO', $repoName
    Set-Content $nuspecPath $content
    Write-Host "✓ Updated $nuspecPath" -ForegroundColor Green
}

# Update chocolatey install script
$installPath = ".\tools\chocolateyinstall.ps1"
if (Test-Path $installPath) {
    $content = Get-Content $installPath -Raw
    $content = $content -replace 'YOUR_USERNAME', $githubUsername
    $content = $content -replace 'enhanced-powershell-profile', $repoName
    Set-Content $installPath $content
    Write-Host "✓ Updated $installPath" -ForegroundColor Green
}

# Update Homebrew formula
$formulaPath = ".\terminalninja.rb"
if (Test-Path $formulaPath) {
    $content = Get-Content $formulaPath -Raw
    $content = $content -replace 'YOUR_USERNAME', $githubUsername
    Set-Content $formulaPath $content
    Write-Host "✓ Updated $formulaPath" -ForegroundColor Green
}

# Update LICENSE
$licensePath = ".\LICENSE"
if (Test-Path $licensePath) {
    $content = Get-Content $licensePath -Raw
    $content = $content -replace 'YOUR_NAME', $authorName
    Set-Content $licensePath $content
    Write-Host "✓ Updated $licensePath" -ForegroundColor Green
}

Write-Host "`nSetup complete!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Create a GitHub repository named '$repoName'" -ForegroundColor White
Write-Host "2. Initialize git and push your code:" -ForegroundColor White
Write-Host "   git init" -ForegroundColor Gray
Write-Host "   git add ." -ForegroundColor Gray
Write-Host "   git commit -m 'Initial commit'" -ForegroundColor Gray
Write-Host "   git remote add origin https://github.com/$githubUsername/$repoName.git" -ForegroundColor Gray
Write-Host "   git push -u origin main" -ForegroundColor Gray
Write-Host "`n3. Follow PUBLISHING.md for Chocolatey and Homebrew publishing" -ForegroundColor White
Write-Host "`nGood luck! 🚀" -ForegroundColor Green

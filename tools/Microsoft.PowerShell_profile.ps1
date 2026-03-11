$terminalNinjaHome = Join-Path $HOME '.terminal-ninja'
$terminalNinjaProfile = Join-Path $terminalNinjaHome 'terminalninja.ps1'

if (Test-Path $terminalNinjaProfile) {
    . $terminalNinjaProfile
}

# PowerShell Profile Configuration
# Enhanced terminal with auto-fill, history, aliases, and functions

# ============ Force PSReadLine 2.4.5 ============
# Import the latest version of PSReadLine
Import-Module PSReadLine -RequiredVersion 2.4.5 -ErrorAction SilentlyContinue

# ============ Oh My Posh Initialization ============
# Initialize Oh My Posh with custom TerminalNinja theme
$scoop = $env:SCOOP
if (-not $scoop) { $scoop = "$env:USERPROFILE\scoop" }
$omp = "$scoop\apps\oh-my-posh\current\oh-my-posh.exe"

# Use custom TerminalNinja theme from profile directory
$customTheme = Join-Path $PSScriptRoot "terminalninja.omp.json"

if (Test-Path $omp) {
    if (Test-Path $customTheme) {
        & $omp init pwsh --config $customTheme | Out-String | Invoke-Expression
    } else {
        # Fallback to Montys theme if custom theme not found
        & $omp init pwsh --config "$scoop\apps\oh-my-posh\current\themes\montys.omp.json" | Out-String | Invoke-Expression
    }
} else {
    Write-Host "Oh My Posh not found at $omp" -ForegroundColor Red
}

# ============ FiraCode Nerd Font Auto-Installation ============
# Install the included FiraCode Nerd Font automatically (runs only once)
$fontInstalledMarker = "$env:TEMP\.firacode_nerd_installed"

if (-not (Test-Path $fontInstalledMarker)) {
    $fontPath = Join-Path $PSScriptRoot "FiraCodeNerdFont-Medium.ttf"
    if (Test-Path $fontPath) {
        $fontFileName = Split-Path $fontPath -Leaf
        $installedFontPath = Join-Path $env:WINDIR "Fonts\$fontFileName"
        
        if (-not (Test-Path $installedFontPath)) {
            try {
                $fontsFolder = (New-Object -ComObject Shell.Application).Namespace(0x14)
                $fontsFolder.CopyHere($fontPath, 0x10 + 0x4)
            } catch { }
        }
        New-Item -ItemType File -Path $fontInstalledMarker -Force | Out-Null
    }
}

# Auto-configure VS Code terminal to use FiraCode Nerd Font
$settingsPath = "$env:APPDATA\Code\User\settings.json"
if (Test-Path $settingsPath) {
    try {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        
        # Set FiraCode Nerd Font if not already configured
        if ($settings.'terminal.integrated.fontFamily' -ne "FiraCode Nerd Font") {
            $settings | Add-Member -MemberType NoteProperty -Name "terminal.integrated.fontFamily" -Value "FiraCode Nerd Font" -Force
            $settings | ConvertTo-Json -Depth 100 | Set-Content $settingsPath
        }
    } catch {
        # Silently fail if VS Code settings can't be updated
    }
}

# ============ PSReadLine Configuration ============
# Enable PSReadLine features for better terminal experience
$PSReadLineOptions = @{
    HistorySearchCursorMovesToEnd = $true
    AddToHistoryHandler           = {
        param([string]$line)
        # Don't add to history if it's the same as the last command
        $LastHistoryItem = Get-History -Count 1 -ErrorAction SilentlyContinue
        if ($LastHistoryItem.CommandLine -ne $line) {
            return $true
        }
        return $false
    }
}

Set-PSReadLineOption @PSReadLineOptions

# ============ PSReadLine Predictive IntelliSense ============
# Enable auto suggestions based on command history (requires PSReadLine 2.1.0+)
try {
    # Use ListView to show multiple suggestions in a dropdown
    Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction Stop
    
    # Show predictions from history AND plugins (includes all commands)
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin -ErrorAction Stop
    
    # Enable additional autocorrect-like features
    Set-PSReadLineOption -HistoryNoDuplicates -ErrorAction Stop
    Set-PSReadLineOption -MaximumHistoryCount 10000 -ErrorAction Stop
    
    # Show tooltips and enable better command completion
    Set-PSReadLineOption -ShowToolTips -ErrorAction Stop
    
    # Increase the number of completions shown (more items in dropdown)
    Set-PSReadLineOption -CompletionQueryItems 200 -ErrorAction Stop
    Set-PSReadLineOption -MaximumCompletionCount 200 -ErrorAction Stop
    
    # Colors for better visibility
    Set-PSReadLineOption -Colors @{
        InlinePrediction = '#8A8A8A'
        ListPrediction = '#00BFFF'
        Command = '#00FF00'
        Parameter = '#FFD700'
    }
} catch {
    # Silently skip if PSReadLine version doesn't support predictions
}

# ============ PSReadLine Key Bindings ============
# Tab for auto-complete (shows ALL matching commands in a menu)
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# Shift+Tab for reverse menu complete
Set-PSReadLineKeyHandler -Key Shift+Tab -Function MenuComplete

# Ctrl+Space to show ALL possible completions
Set-PSReadLineKeyHandler -Key Ctrl+Spacebar -Function Complete

# Ctrl+R for reverse history search
Set-PSReadLineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory
Set-PSReadLineKeyHandler -Key Ctrl+s -Function ForwardSearchHistory

# Ctrl+l to clear the screen
Set-PSReadLineKeyHandler -Key Ctrl+l -Function ClearScreen

# Alt+F for ForwardWord
Set-PSReadLineKeyHandler -Key Alt+f -Function ForwardWord

# Alt+B for BackwardWord
Set-PSReadLineKeyHandler -Key Alt+b -Function BackwardWord

# Ctrl+RightArrow to accept next word of suggestion
Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function ForwardWord

# Accept suggestion with RightArrow or End key
Set-PSReadLineKeyHandler -Key RightArrow -Function ForwardChar
Set-PSReadLineKeyHandler -Key End -Function EndOfLine

# ============ Command Completions - Deferred Loading ============
# Load completions on first use for faster startup
$global:CompletionsLoaded = $false

# Git commands
$gitCommands = @(
    'add', 'am', 'archive', 'bisect', 'branch', 'bundle', 'checkout', 'cherry-pick',
    'citool', 'clean', 'clone', 'commit', 'describe', 'diff', 'fetch', 'format-patch',
    'gc', 'gitk', 'grep', 'gui', 'init', 'log', 'merge', 'mv', 'notes', 'pull', 'push',
    'range-diff', 'rebase', 'reset', 'restore', 'revert', 'rm', 'shortlog', 'show',
    'sparse-checkout', 'stash', 'status', 'submodule', 'switch', 'tag', 'worktree',
    'config', 'help', 'remote', 'reflog', 'cherry', 'apply', 'blame', 'show-branch'
)

Register-ArgumentCompleter -Native -CommandName git -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    $gitCommands | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}.GetNewClosure()

# NPM commands
$npmCommands = @('install', 'init', 'run', 'start', 'test', 'build', 'publish', 'update', 'uninstall', 'list', 'search', 'help', 'version', 'config', 'cache', 'audit', 'doctor', 'fund')
Register-ArgumentCompleter -Native -CommandName npm -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    $npmCommands | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}.GetNewClosure()

# Docker commands
$dockerCommands = @('build', 'run', 'ps', 'images', 'pull', 'push', 'start', 'stop', 'restart', 'rm', 'rmi', 'logs', 'exec', 'inspect', 'commit', 'tag', 'network', 'volume', 'compose')
Register-ArgumentCompleter -Native -CommandName docker -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    $dockerCommands | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}.GetNewClosure()

# Chocolatey commands
$chocoCommands = @('install', 'upgrade', 'uninstall', 'list', 'search', 'info', 'outdated', 'pin', 'source', 'config', 'feature', 'help', 'version', 'update')
Register-ArgumentCompleter -Native -CommandName choco -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    $chocoCommands | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}.GetNewClosure()

# Homebrew commands
$brewCommands = @('install', 'uninstall', 'upgrade', 'update', 'list', 'search', 'info', 'doctor', 'cleanup', 'config', 'deps', 'uses', 'outdated', 'pin', 'unpin', 'tap', 'untap', 'help', 'services', 'bundle', 'cask', 'reinstall', 'link', 'unlink')
Register-ArgumentCompleter -Native -CommandName brew -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    $brewCommands | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}.GetNewClosure()

# ============ Command Autocorrect ============
# Common typo corrections
$CommandCorrections = @{
    'gti' = 'git'
    'gt' = 'git'
    'claer' = 'clear'
    'celar' = 'clear'
    'cler' = 'clear'
    'cd..' = 'cd ..'
    'sl' = 'ls'
    'coce' = 'code'
    'pyhton' = 'python'
    'pytohn' = 'python'
    'ndoe' = 'node'
    'naem' = 'name'
    'mkdri' = 'mkdir'
    'mkidr' = 'mkdir'
}

# Register command not found handler
$ExecutionContext.InvokeCommand.CommandNotFoundAction = {
    param($CommandName, $CommandLookupEventArgs)
    
    # Check if we have a correction for this typo
    if ($CommandCorrections.ContainsKey($CommandName)) {
        $Correction = $CommandCorrections[$CommandName]
        Write-Host "Autocorrecting '$CommandName' to '$Correction'" -ForegroundColor Yellow
        $CommandLookupEventArgs.CommandScriptBlock = {
            & $Correction @args
        }.GetNewClosure()
    }
}

# ============ Useful Aliases ============
New-Alias -Name ll -Value Get-ChildItem -Force -ErrorAction SilentlyContinue
New-Alias -Name la -Value Get-ChildItem -Force -ErrorAction SilentlyContinue
New-Alias -Name c -Value Clear-Host -Force -ErrorAction SilentlyContinue
New-Alias -Name touch -Value New-Item -Force -ErrorAction SilentlyContinue
New-Alias -Name grep -Value Select-String -Force -ErrorAction SilentlyContinue
New-Alias -Name which -Value Get-Command -Force -ErrorAction SilentlyContinue

# ============ Custom Functions ============

# List files with color coding
function ll {
    Get-ChildItem -Path $args -Force | Format-Table -AutoSize
}

# Go up directories quickly
function .. {
    Set-Location ..
}

function ... {
    Set-Location ../..
}

function .... {
    Set-Location ../../..
}

# Create directory and enter it
function mkcd {
    param([string]$Name)
    New-Item -ItemType Directory -Name $Name -Force | Out-Null
    Set-Location -Path $Name
}

# Open current directory in explorer
function explore {
    Invoke-Item .
}

# Get public IP address
function Get-PublicIP {
    (Invoke-WebRequest -Uri 'https://api.ipify.org?format=json' -UseBasicParsing | ConvertFrom-Json).ip
}

# Find file by name
function Find-File {
    param([string]$Name)
    Get-ChildItem -Recurse -Filter "*$Name*" -ErrorAction SilentlyContinue
}

# Search content in files
function Find-InFiles {
    param(
        [string]$Pattern,
        [string]$Path = '.'
    )
    Select-String -Path "$Path\*" -Pattern $Pattern -Recurse
}

# List processes by memory usage
function Get-MemoryProcesses {
    Get-Process | Sort-Object -Property WS -Descending | Select-Object -First 10 Name, @{Label="Memory(MB)"; Expression={[math]::Round($_.WS/1MB, 2)}}
}

# Quick git status
function gs {
    git status
}

function gaa {
    git add .
}

function gc {
    git commit -m $args
}

function gp {
    git push
}

# ============ Prompt Customization ============
# Prompt is now handled by Oh My Posh with custom TerminalNinja theme
# Commenting out the custom prompt function

<# Custom prompt (disabled - using Oh My Posh instead)
function prompt {
    $GitBranch = ""
    $GitStatus = ""
    
    # Check if we're in a git repository
    if (Test-Path .git) {
        $GitBranch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($GitBranch) {
            $GitStatus = " ($GitBranch)"
        }
    }
    
    $CurrentDirectory = Split-Path -Leaf -Path (Get-Location)
    
    # Color-coded prompt
    Write-Host "$CurrentDirectory" -ForegroundColor Cyan -NoNewline
    Write-Host "$GitStatus" -ForegroundColor Yellow -NoNewline
    Write-Host "> " -ForegroundColor Green -NoNewline
    return " "
}
#>

# ============ Initialization Messages ============
# Uncomment below to see startup messages
# Write-Host "TerminalNinja Profile Loaded! 🥷" -ForegroundColor Green
# Write-Host "Oh My Posh (TerminalNinja Theme) Enabled!" -ForegroundColor Cyan
# Write-Host "Useful commands: ll, mkcd, explore, Find-File, Get-PublicIP" -ForegroundColor Gray


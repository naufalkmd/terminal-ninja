# TerminalNinja PowerShell configuration
# Enhanced terminal with auto-fill, history, aliases, and functions

# ============ Force PSReadLine 2.4.5 ============
Import-Module PSReadLine -RequiredVersion 2.4.5 -ErrorAction SilentlyContinue

# ============ Starship Initialization ============
$env:STARSHIP_CONFIG = Join-Path $PSScriptRoot 'starship.toml'
$starship = Get-Command starship.exe -ErrorAction SilentlyContinue
if (-not $starship) {
    $starship = Get-Command starship -ErrorAction SilentlyContinue
}

if ($starship -and (Test-Path $env:STARSHIP_CONFIG)) {
    & $starship.Source init powershell | Out-String | Invoke-Expression
} else {
    Write-Host 'Starship not found in PATH. Prompt will use the default shell prompt.' -ForegroundColor Yellow
}

# ============ FiraCode Nerd Font Auto-Installation ============
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

        if ($settings.'terminal.integrated.fontFamily' -ne "FiraCode Nerd Font") {
            $settings | Add-Member -MemberType NoteProperty -Name "terminal.integrated.fontFamily" -Value "FiraCode Nerd Font" -Force
            $settings | ConvertTo-Json -Depth 100 | Set-Content $settingsPath
        }
    } catch {
    }
}

# ============ PSReadLine Configuration ============
$PSReadLineOptions = @{
    HistorySearchCursorMovesToEnd = $true
    AddToHistoryHandler           = {
        param([string]$line)
        $LastHistoryItem = Get-History -Count 1 -ErrorAction SilentlyContinue
        if ($LastHistoryItem.CommandLine -ne $line) {
            return $true
        }
        return $false
    }
}

Set-PSReadLineOption @PSReadLineOptions

# ============ PSReadLine Predictive IntelliSense ============
try {
    Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction Stop
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin -ErrorAction Stop
    Set-PSReadLineOption -HistoryNoDuplicates -ErrorAction Stop
    Set-PSReadLineOption -MaximumHistoryCount 10000 -ErrorAction Stop
    Set-PSReadLineOption -ShowToolTips -ErrorAction Stop
    Set-PSReadLineOption -CompletionQueryItems 200 -ErrorAction Stop
    Set-PSReadLineOption -MaximumCompletionCount 200 -ErrorAction Stop
    Set-PSReadLineOption -Colors @{
        InlinePrediction = '#8A8A8A'
        ListPrediction   = '#00BFFF'
        Command          = '#00FF00'
        Parameter        = '#FFD700'
    }
} catch {
}

# ============ PSReadLine Key Bindings ============
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key Shift+Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key Ctrl+Spacebar -Function Complete
Set-PSReadLineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory
Set-PSReadLineKeyHandler -Key Ctrl+s -Function ForwardSearchHistory
Set-PSReadLineKeyHandler -Key Ctrl+l -Function ClearScreen
Set-PSReadLineKeyHandler -Key Alt+f -Function ForwardWord
Set-PSReadLineKeyHandler -Key Alt+b -Function BackwardWord
Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function ForwardWord
Set-PSReadLineKeyHandler -Key RightArrow -Function ForwardChar
Set-PSReadLineKeyHandler -Key End -Function EndOfLine

# ============ Command Completions ============
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

$npmCommands = @('install', 'init', 'run', 'start', 'test', 'build', 'publish', 'update', 'uninstall', 'list', 'search', 'help', 'version', 'config', 'cache', 'audit', 'doctor', 'fund')
Register-ArgumentCompleter -Native -CommandName npm -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    $npmCommands | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}.GetNewClosure()

$dockerCommands = @('build', 'run', 'ps', 'images', 'pull', 'push', 'start', 'stop', 'restart', 'rm', 'rmi', 'logs', 'exec', 'inspect', 'commit', 'tag', 'network', 'volume', 'compose')
Register-ArgumentCompleter -Native -CommandName docker -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    $dockerCommands | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}.GetNewClosure()

$chocoCommands = @('install', 'upgrade', 'uninstall', 'list', 'search', 'info', 'outdated', 'pin', 'source', 'config', 'feature', 'help', 'version', 'update')
Register-ArgumentCompleter -Native -CommandName choco -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    $chocoCommands | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}.GetNewClosure()

$brewCommands = @('install', 'uninstall', 'upgrade', 'update', 'list', 'search', 'info', 'doctor', 'cleanup', 'config', 'deps', 'uses', 'outdated', 'pin', 'unpin', 'tap', 'untap', 'help', 'services', 'bundle', 'cask', 'reinstall', 'link', 'unlink')
Register-ArgumentCompleter -Native -CommandName brew -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    $brewCommands | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}.GetNewClosure()

# ============ Command Autocorrect ============
$CommandCorrections = @{
    'gti'   = 'git'
    'gt'    = 'git'
    'claer' = 'clear'
    'celar' = 'clear'
    'cler'  = 'clear'
    'cd..'  = 'cd ..'
    'sl'    = 'ls'
    'coce'  = 'code'
    'pyhton' = 'python'
    'pytohn' = 'python'
    'ndoe'   = 'node'
    'naem'   = 'name'
    'mkdri'  = 'mkdir'
    'mkidr'  = 'mkdir'
}

$ExecutionContext.InvokeCommand.CommandNotFoundAction = {
    param($CommandName, $CommandLookupEventArgs)

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
function ll {
    Get-ChildItem -Path $args -Force | Format-Table -AutoSize
}

function .. {
    Set-Location ..
}

function ... {
    Set-Location ../..
}

function .... {
    Set-Location ../../..
}

function mkcd {
    param([string]$Name)
    New-Item -ItemType Directory -Name $Name -Force | Out-Null
    Set-Location -Path $Name
}

function explore {
    Invoke-Item .
}

function Get-PublicIP {
    (Invoke-WebRequest -Uri 'https://api.ipify.org?format=json' -UseBasicParsing | ConvertFrom-Json).ip
}

function Find-File {
    param([string]$Name)
    Get-ChildItem -Recurse -Filter "*$Name*" -ErrorAction SilentlyContinue
}

function Find-InFiles {
    param(
        [string]$Pattern,
        [string]$Path = '.'
    )
    Select-String -Path "$Path\*" -Pattern $Pattern -Recurse
}

function Get-MemoryProcesses {
    Get-Process | Sort-Object -Property WS -Descending | Select-Object -First 10 Name, @{Label = 'Memory(MB)'; Expression = { [math]::Round($_.WS / 1MB, 2) }}
}

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
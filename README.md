# PowerShell Profile Configuration

A comprehensive PowerShell profile configuration that enhances your terminal experience with Oh My Posh theming, PSReadLine features, useful aliases, and custom functions.

## Description

This PowerShell profile (`Microsoft.PowerShell_profile.ps1`) provides a modern, user-friendly terminal experience with:

- **Oh My Posh Integration**: Beautiful Montys theme for an enhanced visual prompt
- **PSReadLine Configuration**: Advanced command-line editing with intelligent history management
- **Smart Key Bindings**: Familiar keyboard shortcuts for improved productivity
- **Useful Aliases**: Unix-like commands (ll, grep, which, etc.) for cross-platform compatibility
- **Custom Functions**: Helper functions for common tasks (navigation, git operations, file search)

## Features

### 🎨 Oh My Posh Theming
- Montys theme with a clean, informative prompt
- Git branch integration
- Visual indicators for command status
- **FiraCode Nerd Font included** - automatically installed on first run

### ⌨️ Key Bindings
- `Tab`: Menu-based auto-completion
- `Ctrl+R`: Reverse history search
- `Ctrl+S`: Forward history search
- `Ctrl+L`: Clear screen
- `Alt+F`: Move forward one word
- `Alt+B`: Move backward one word

### 📁 Aliases
- `ll`, `la`: List files and directories
- `c`: Clear screen
- `touch`: Create new file
- `grep`: Search text
- `which`: Find command location

### 🛠️ Custom Functions

#### Navigation
- `..`, `...`, `....`: Navigate up directories quickly
- `mkcd <name>`: Create and enter a new directory
- `explore`: Open current directory in File Explorer

#### Git Shortcuts
- `gs`: Git status
- `gaa`: Git add all
- `gc <message>`: Git commit with message
- `gp`: Git push

#### Utilities
- `Get-PublicIP`: Get your public IP address
- `Find-File <name>`: Search for files by name recursively
- `Find-InFiles <pattern> [path]`: Search for text within files
- `Get-MemoryProcesses`: Display top 10 processes by memory usage

## Installation

1. **Install Scoop** (if not already installed):
   ```powershell
   irm get.scoop.sh | iex
   ```

2. **Install Oh My Posh**:
   ```powershell
   scoop install oh-my-posh
   ```

3. **Clone or download this repository**:
   ```powershell
   git clone https://github.com/YOUR_USERNAME/Just_My_Favourite_Terminal_Setup.git
   cd Just_My_Favourite_Terminal_Setup
   ```

4. **Copy the profile and font**:
   ```powershell
   # Create the WindowsPowerShell directory if it doesn't exist
   New-Item -ItemType Directory -Force -Path "$HOME\Documents\WindowsPowerShell"
   
   # Copy both the profile and font file
   Copy-Item Microsoft.PowerShell_profile.ps1 -Destination "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
   Copy-Item FiraCodeNerdFont-Medium.ttf -Destination "$HOME\Documents\WindowsPowerShell\FiraCodeNerdFont-Medium.ttf"
   ```
   
   **Note**: The FiraCode Nerd Font will be automatically installed the first time you load the profile!

5. **Restart PowerShell** or reload the profile:
   ```powershell
   . $PROFILE
   ```

## Troubleshooting

### Oh My Posh Not Found
**Symptom**: Error message "Oh My Posh not found at..." on PowerShell startup

**Solution**:
```powershell
# Verify Scoop installation
scoop --version

# Install Oh My Posh
scoop install oh-my-posh

# Verify installation
oh-my-posh --version
```

### Icons/Glyphs Not Displaying Correctly
The FiraCode Nerd Font should be automatically installed when you first load the profile. If you still see display issues:

1. **Verify the font was installed**:
   - Check `C:\Windows\Fonts` for `FiraCodeNerdFont-Medium.ttf`
   
2. **Manually install the font** (if auto-install failed):
   - Right-click `FiraCodeNerdFont-Medium.ttf` in the repository folder
   - Select "Install" or "Install for all users"

3. **Configure your terminal** to use the font:
   - **Windows Terminal**: Settings → Profiles → Defaults → Appearance → Font face → "FiraCode Nerd Font"
   - **VS Code**: Automatically configured, but you can verify in Settings → Terminal → Font Family
   - **Other terminals**: Set font to "FiraCode Nerd Font"
2. Configure your terminal to use the installed font:
   - **Windows Terminal**: Settings → Profiles → Defaults → Appearance → Font face → Select Nerd Font
   - **VS Code**: Settings → Terminal → Font Family → Add the Nerd Font name

### Execution Policy Error
**Symptom**: "cannot be loaded because running scripts is disabled on this system"

**Solution**:
```powershell
# Run as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### PSReadLine Errors
**Symptom**: Errors related to PSReadLine module on startup

**Solution**:
```powershell
# Update PSReadLine module
Install-Module PSReadLine -Force -SkipPublisherCheck
```

### Profile Not Loading Automatically
**Symptom**: Profile features don't work when opening PowerShell

**Solution**:
```powershell
# Check if profile exists
Test-Path $PROFILE

# Verify correct location
$PROFILE

# If false, the profile is in the wrong location or doesn't exist
# Copy it to the correct location shown by $PROFILE
```

### Git Functions Not Working
**Symptom**: `gs`, `gaa`, `gc`, or `gp` commands not recognized

**Solution**:
```powershell
# Verify Git is installed
git --version

# If not installed, install via Scoop
scoop install git
```

### Scoop Path Issues
**Symptom**: Oh My Posh can't be found even after installation

**Solution**:
```powershell
# Check Scoop environment variable
$env:SCOOP

# If empty, set it manually (add to your profile before Oh My Posh initialization)
$env:SCOOP = "$env:USERPROFILE\scoop"

# Or reinstall Scoop in the default location
```

### Function Name Conflicts
**Symptom**: Some functions or aliases don't work as expected

**Solution**:
The profile uses `-Force` on aliases to override defaults. If you experience issues:
```powershell
# Check if alias exists
Get-Alias <alias-name>

# Check if function exists
Get-Command <function-name>

# Remove conflicting alias/function
Remove-Alias <alias-name> -Force
# or
Remove-Item Function:\<function-name>
```

## Customization

### Change Oh My Posh Theme
Edit the profile and change the theme path:
```powershell
& $omp init pwsh --config "$scoop\apps\oh-my-posh\current\themes\YOUR_THEME.omp.json" | Out-String | Invoke-Expression
```

Browse available themes:
```powershell
Get-ChildItem "$env:SCOOP\apps\oh-my-posh\current\themes\"
```

### Add Your Own Functions
Add custom functions to the "Custom Functions" section:
```powershell
function MyFunction {
    param([string]$Parameter)
    # Your code here
}
```

## Requirements

- Windows PowerShell 5.1+ or PowerShell 7+
- Scoop package manager
- Oh My Posh
- PSReadLine module (usually pre-installed)
- **FiraCode Nerd Font** (included in this repository - auto-installs on first run)

## License

Feel free to use, modify, and distribute this configuration as needed.

## Contributing

Contributions are welcome! If you have suggestions for improvements or additional features, feel free to open an issue or submit a pull request.

---

**Author**: naufalkmd  
**Last Updated**: February 2026

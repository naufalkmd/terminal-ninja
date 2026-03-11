# TerminalNinja

TerminalNinja is a cross-shell terminal setup that applies a shared Starship prompt plus shell-native quality-of-life features across PowerShell, bash, zsh, and WSL.

<img width="764" height="88" alt="image" src="https://github.com/user-attachments/assets/0d8294dc-9035-4965-bda3-c1700500fee4" />

## Quick Start

Recommended install paths:

- Windows: Scoop
- macOS and Linux: Homebrew
- Local repo checkout: `setup-everywhere.ps1`

Windows with Scoop:

```powershell
scoop bucket add naufalkmd https://github.com/naufalkmd/scoop-bucket
scoop install terminalninja
```

macOS or Linux with Homebrew:

```bash
brew tap naufalkmd/tap
brew install terminalninja
terminalninja-install
```

To remove it later and reset the managed shell config:

```bash
~/.terminal-ninja/terminalninja-uninstall
brew uninstall terminalninja
```

If you are running from a local checkout instead of a package manager:

```powershell
.\setup-everywhere.ps1 -InstallWslStarship
```

## Description

TerminalNinja installs a managed shell config under `~/.terminal-ninja` and wires your shell startup files to source it. That keeps the visuals consistent everywhere while letting each shell use the features it supports best.

Included shell coverage:

- PowerShell / pwsh: Starship, PSReadLine, completions, aliases, and helper functions
- bash: Starship, history tuning, completion loading, aliases, and helper functions
- zsh: Starship, history tuning, compinit bindings, aliases, and helper functions
- WSL: automatic sourcing of the same bash/zsh configs from your Windows home directory

This repository provides:

- **Shared prompt theme**: one `starship.toml` prompt config reused across shells
- **Shell-native behavior**: PowerShell keeps PSReadLine, bash/zsh get their own history and completion setup
- **Managed installation**: startup files receive a small TerminalNinja block instead of being fully replaced
- **Portable helpers**: common navigation, git shortcuts, search helpers, and utility commands

## Features

### Prompt and visuals

- Shared Starship prompt for PowerShell, bash, zsh, and WSL
- Git branch and working tree indicators
- Execution time, clock, host, and status segments
- Folder separator updated to `/` so the path reads cleanly across shells
- FiraCode Nerd Font can still be installed from the packaged assets on Windows

### Shell behavior

- PowerShell: PSReadLine predictive suggestions, menu completion, and typo correction
- bash: history search bindings, menu completion, and bash-completion loading when available
- zsh: history search bindings, `compinit`, and shared history options

### Shared shortcuts

- `ll`, `la`: List files and directories
- `c`: Clear screen
- `gs`, `gaa`, `gc`, `gp`: Git shortcuts
- `..`, `...`, `....`: Jump up directories quickly
- `mkcd`, `explore`, `findfile`, `findinfiles`, `publicip`, `memorytop`

## Installation

### Recommended package managers

#### Windows: Scoop

```powershell
scoop bucket add naufalkmd https://github.com/naufalkmd/scoop-bucket
scoop install terminalninja
```

Why Scoop is recommended on Windows:

- Simple user-scoped install
- Good fit for PowerShell-first tooling
- Works cleanly with Starship and TerminalNinja updates

#### macOS and Linux: Homebrew

```bash
brew tap naufalkmd/tap
brew install terminalninja
terminalninja-install
```

Why Homebrew is recommended on macOS and Linux:

- Familiar install path for shell tools
- Easy upgrades through `brew upgrade`
- Clean integration with the packaged `terminalninja-install` flow
- Does not require PowerShell just to install TerminalNinja for bash or zsh

After install, run `terminalninja-install`, then restart PowerShell, bash, zsh, and any WSL sessions. The Homebrew installer now detects supported shells and asks whether to apply TerminalNinja everywhere or only to the targets you select, using the same numbered selection style as the PowerShell setup flow.

If you also use PowerShell on macOS or Linux, install PowerShell separately, then run `pwsh` after `terminalninja-install` has written the profile file.

### Alternative: Chocolatey

1. Install Starship in every environment where you want the TerminalNinja prompt to render, or let the installer do it automatically.
2. Install the package:
   ```powershell
   choco install terminalninja
   ```
3. Restart PowerShell, bash, zsh, and any WSL sessions.

What the installer does:

- Copies TerminalNinja assets into `~/.terminal-ninja`
- Adds a managed TerminalNinja block to PowerShell profile files
- Adds a managed TerminalNinja block to common bash and zsh startup files, including login-shell files on macOS
- Detects WSL distros and adds the same managed block to Linux `~/.bashrc` and `~/.zshrc`
- Leaves the rest of your profile content intact

### Uninstall and reset

Windows package-manager uninstalls now remove the managed profile blocks, delete `~/.terminal-ninja`, and restore VS Code's `terminal.integrated.fontFamily` if TerminalNinja set it during install.

Use these commands:

```powershell
scoop uninstall terminalninja
# or
choco uninstall terminalninja
```

For Homebrew, run the persisted uninstaller first, then remove the formula:

```bash
~/.terminal-ninja/terminalninja-uninstall
brew uninstall terminalninja
```

While the formula is still installed, the same helper is also on your `PATH` as `terminalninja-uninstall`.

### Local setup from this repository

If you want the repo to do the full local setup for you, including optional WSL `starship` installation and a post-install verification pass, run:

```powershell
.\setup-everywhere.ps1 -InstallWslStarship
```

Useful modes:

- `./setup-everywhere.ps1 -VerifyOnly`: verify managed blocks and prompt dependencies without reinstalling
- `./setup-everywhere.ps1 -SkipVerification`: install without the verification pass
- `./setup-everywhere.ps1 -UseChocolatey -InstallWslStarship`: use the Chocolatey package path instead of the local installer script
- `./setup-everywhere.ps1 -Uninstall`: remove TerminalNinja and restore managed settings from a local repo checkout

### Manual install

1. Copy these files into `~/.terminal-ninja`:
   - `terminalninja.ps1`
   - `terminalninja.bash`
   - `terminalninja.zsh`
   - `starship.toml`
2. Source the matching file from your shell startup file:

   PowerShell:

   ```powershell
   $terminalNinjaHome = Join-Path $HOME '.terminal-ninja'
   $terminalNinjaProfile = Join-Path $terminalNinjaHome 'terminalninja.ps1'
   if (Test-Path $terminalNinjaProfile) { . $terminalNinjaProfile }
   ```

   bash:

   ```bash
   [ -f "$HOME/.terminal-ninja/terminalninja.bash" ] && . "$HOME/.terminal-ninja/terminalninja.bash"
   ```

   zsh:

   ```zsh
   [ -f "$HOME/.terminal-ninja/terminalninja.zsh" ] && . "$HOME/.terminal-ninja/terminalninja.zsh"
   ```

## Troubleshooting

### Starship Not Found

**Symptom**: Prompt loads without TerminalNinja styling in PowerShell, bash, zsh, or WSL

**Solution**:

```powershell
# Verify Starship exists in the current shell environment
starship --version
```

For WSL, install `starship` inside the Linux distro as well. The prompt config is shared from Windows, but the executable still has to exist in the shell that is rendering the prompt.

### Icons/Glyphs Not Displaying Correctly

The FiraCode Nerd Font should be automatically installed when you first load the profile. If you still see display issues:

1. **Verify the font was installed**:
   - Check `C:\Windows\Fonts` for `FiraCodeNerdFont-Medium.ttf`
2. **Manually install the font** (if auto-install failed):
   - Right-click `FiraCodeNerdFont-Medium.ttf` in the TerminalNinja asset folder
   - Select "Install" or "Install for all users"

3. **Configure your terminal** to use the font:
   - **Windows Terminal**: Settings → Profiles → Defaults → Appearance → Font face → "FiraCode Nerd Font"
   - **VS Code**: Automatically configured, but you can verify in Settings → Terminal → Font Family
   - **Other terminals**: Set font to "FiraCode Nerd Font"

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

### Shell Config Not Loading Automatically

**Symptom**: features work in one shell but not another

**Solution**:

```powershell
# PowerShell
$PROFILE

# bash / zsh on Windows
Join-Path $HOME '.bashrc'
Join-Path $HOME '.zshrc'
```

Check that the file contains the managed TerminalNinja block and that `~/.terminal-ninja` exists.

For WSL, verify the Linux startup files also contain the TerminalNinja block:

```bash
grep -n "TerminalNinja" ~/.bashrc ~/.zshrc
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

### Windows Starship Path Issues

**Symptom**: PowerShell cannot find Starship on Windows even though it is installed

**Solution**:

```powershell
# Verify Starship is in PATH
Get-Command starship.exe -ErrorAction SilentlyContinue
Get-Command starship -ErrorAction SilentlyContinue
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

### Change Starship Prompt

Edit the shared prompt config:

```toml
# starship.toml
format = "$directory$git_branch$git_status$character"
```

Apply the updated config by restarting your shell or rerunning verification.

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
- Starship in each shell environment where you want the prompt theme
- PSReadLine for PowerShell features
- bash or zsh for non-PowerShell shells
- WSL optional, but supported by the installer when available

## License

Feel free to use, modify, and distribute this configuration as needed.

## Contributing

Contributions are welcome! If you have suggestions for improvements or additional features, feel free to open an issue or submit a pull request.

---

**Author**: naufalkmd  
**Last Updated**: February 2026

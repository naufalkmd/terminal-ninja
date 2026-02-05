# Publishing Guide

This guide explains how to publish TerminalNinja 🥷 to Chocolatey and Homebrew.

## Prerequisites

1. GitHub account and repository
2. Chocolatey account (for Windows distribution)
3. Homebrew tap (for macOS/Linux distribution)

## Publishing to Chocolatey (Windows)

### 1. Create Chocolatey Account
- Go to https://community.chocolatey.org/
- Create an account
- Get your API key from https://community.chocolatey.org/account

### 2. Update Files
Edit these files in your repository:
- `terminalninja.nuspec`: Update `YOUR_NAME`, `YOUR_USERNAME`
- `tools/chocolateyinstall.ps1`: Update `YOUR_USERNAME` in the URL

### 3. Package the Application
```powershell
# Navigate to your project directory
cd C:\Users\naufalkmd\Documents\WindowsPowerShell

# Create the .nupkg file
choco pack terminalninja.nuspec
```

### 4. Test Locally
```powershell
# Install locally to test
choco install terminalninja -source .

# Test it works
# Restart PowerShell and verify features

# Uninstall if needed
choco uninstall terminalninja
```

### 5. Push to Chocolatey
```powershell
# Push to Chocolatey community repository
choco push terminalninja.1.0.0.nupkg --source https://push.chocolatey.org/ --api-key YOUR_API_KEY
```

### 6. Wait for Approval
- Chocolatey moderators will review your package (first submission takes 1-2 days)
- Once approved, users can install with: `choco install terminalninja`

## Publishing to Homebrew (macOS/Linux)

### 1. Create GitHub Release
```bash
# Tag your release
git tag -a v1.0.0 -m "Initial release"
git push origin v1.0.0

# GitHub will create a tar.gz automatically at:
# https://github.com/YOUR_USERNAME/terminalninja/archive/refs/tags/v1.0.0.tar.gz
```

### 2. Calculate SHA256
```bash
# Download the release tarball
curl -L https://github.com/YOUR_USERNAME/terminalninja/archive/refs/tags/v1.0.0.tar.gz -o release.tar.gz

# Calculate SHA256
sha256sum release.tar.gz  # Linux
shasum -a 256 release.tar.gz  # macOS
```

### 3. Update Homebrew Formula
Edit `terminalninja.rb`:
- Replace `YOUR_USERNAME` with your GitHub username
- Replace `YOUR_SHA256_HASH_HERE` with the SHA256 from step 2

### 4. Create a Homebrew Tap
```bash
# Create a tap repository on GitHub named: homebrew-tap
# Clone it locally
git clone https://github.com/YOUR_USERNAME/homebrew-tap
cd homebrew-tap

# Copy the formula
cp ../terminalninja.rb Formula/

# Commit and push
git add Formula/terminalninja.rb
git commit -m "Add terminalninja formula"
git push
```

### 5. Users Can Now Install
```bash
# Add your tap
brew tap YOUR_USERNAME/tap

# Install the formula
brew install terminalninja
```

## Alternative: Submit to Official Homebrew (Advanced)

To get into the official Homebrew repository:

1. Fork https://github.com/Homebrew/homebrew-core
2. Add your formula to `Formula/`
3. Submit a Pull Request
4. Wait for review (can take several days)

## File Structure Summary

```
terminalninja/
├── Microsoft.PowerShell_profile.ps1   # Main profile
├── README.md                          # Documentation
├── LICENSE                            # License file
├── terminalninja.nuspec              # Chocolatey package definition
├── terminalninja.rb                  # Homebrew formula
└── tools/
    ├── chocolateyinstall.ps1          # Chocolatey install script
    └── chocolateyuninstall.ps1        # Chocolatey uninstall script
```

## Post-Publishing

### Update README.md
Add installation instructions:
```markdown
## Installation

### Windows (Chocolatey)
choco install terminalninja

### macOS/Linux (Homebrew)
brew tap YOUR_USERNAME/tap
brew install terminalninja
```

### Version Updates
When releasing a new version:

1. **Chocolatey:**
   - Update version in `.nuspec` file
   - Run `choco pack`
   - Push new version: `choco push terminalninja.X.X.X.nupkg`

2. **Homebrew:**
   - Create new GitHub release tag
   - Calculate new SHA256
   - Update formula with new URL and SHA256
   - Commit and push to your tap

## Tips

- Test thoroughly before publishing
- Keep version numbers in sync across platforms
- Respond to user issues promptly
- Update documentation when adding features
- Consider adding CI/CD for automated testing

## Support

If you encounter issues:
- Chocolatey: https://github.com/chocolatey/choco/wiki
- Homebrew: https://docs.brew.sh/Formula-Cookbook

class Terminalninja < Formula
  desc "TerminalNinja - Master your terminal with auto-suggestions and smart completions"
  homepage "https://github.com/naufalkmd/terminalninja"
  url "https://github.com/naufalkmd/terminalninja/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "92dd24a05c350f315fa09904d105192d6cf7fe98f1ec6039f19e4acdf63d9566"
  license "MIT"

  depends_on "powershell"

  def install
    # Install the profile script
    (prefix/"profile").install "Microsoft.PowerShell_profile.ps1"
    
    # Create installation script
    (bin/"install-enhanced-profile").write <<~EOS
      #!/bin/bash
      
      PROFILE_PATH=""
      
      # Detect OS and set profile path
      if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        PROFILE_PATH="$HOME/.config/powershell/Microsoft.PowerShell_profile.ps1"
      elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        PROFILE_PATH="$HOME/.config/powershell/Microsoft.PowerShell_profile.ps1"
      else
        echo "Unsupported OS"
        exit 1
      fi
      
      # Create directory if it doesn't exist
      mkdir -p "$(dirname "$PROFILE_PATH")"
      
      # Backup existing profile
      if [ -f "$PROFILE_PATH" ]; then
        BACKUP="$PROFILE_PATH.backup.$(date +%Y%m%d_%H%M%S)"
        echo "Backing up existing profile to: $BACKUP"
        cp "$PROFILE_PATH" "$BACKUP"
      fi
      
      # Install new profile
      cp "#{prefix}/profile/Microsoft.PowerShell_profile.ps1" "$PROFILE_PATH"
      
      echo "Enhanced PowerShell Profile installed!"
      echo "Profile location: $PROFILE_PATH"
      echo ""
      echo "Installing PSReadLine 2.4.5+..."
      pwsh -NoProfile -Command "Install-Module -Name PSReadLine -Force -SkipPublisherCheck -Scope CurrentUser"
      
      echo ""
      echo "Installation complete! Please restart PowerShell."
    EOS
    
    chmod 0755, bin/"install-enhanced-profile"
  end

  def post_install
    system bin/"install-enhanced-profile"
  end

  def caveats
    <<~EOS
      TerminalNinja 🥷 has been installed!
      
      Features:
        - Auto-suggestions with ListView dropdown
        - Git, NPM, Docker, Choco, Brew completions
        - Auto-correct for common typos
        - Custom aliases and functions
      
      To complete installation:
        1. Restart your PowerShell terminal
        2. Type 'git m' and press Tab to test completions
      
      Your old profile was backed up with timestamp.
    EOS
  end

  test do
    assert_match "PowerShell Profile Configuration",
      shell_output("cat #{prefix}/profile/Microsoft.PowerShell_profile.ps1")
  end
end


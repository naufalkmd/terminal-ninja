class Terminalninja < Formula
  desc "Shared Starship prompt and shell-native terminal workflow across PowerShell, bash, zsh, and WSL"
  homepage "https://github.com/naufalkmd/terminal-ninja"
  url "https://github.com/naufalkmd/terminal-ninja/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "374c9ef0d9cfe40c1df690efbaa009b9c13ef5cdde90c09cf00e6765f5314646"
  license "MIT"

  def install
    libexec.install "terminalninja.ps1", "terminalninja.bash", "terminalninja.zsh", "starship.toml"

    (bin/"terminalninja-install").write <<~EOS
      #!/bin/bash
      set -euo pipefail

      set_managed_block() {
        local target_file="$1"
        local source_line="$2"
        local temp_file

        mkdir -p "$(dirname "$target_file")"
        touch "$target_file"
        temp_file="$(mktemp)"
        awk '
          BEGIN { skip = 0 }
          /^# >>> TerminalNinja >>>$/ { skip = 1; next }
          /^# <<< TerminalNinja <<</ { skip = 0; next }
          skip == 0 { print }
        ' "$target_file" > "$temp_file"
        mv "$temp_file" "$target_file"
        if [ -s "$target_file" ] && [ "$(tail -c 1 "$target_file" 2>/dev/null || true)" != "" ]; then
          printf '\n' >> "$target_file"
        fi
        cat >> "$target_file" <<EOF
# >>> TerminalNinja >>>
$source_line
# <<< TerminalNinja <<<
EOF
      }

      install_root="$HOME/.terminal-ninja"
      mkdir -p "$install_root"

      cp "#{libexec}/terminalninja.ps1" "$install_root/terminalninja.ps1"
      cp "#{libexec}/terminalninja.bash" "$install_root/terminalninja.bash"
      cp "#{libexec}/terminalninja.zsh" "$install_root/terminalninja.zsh"
      cp "#{libexec}/starship.toml" "$install_root/starship.toml"
      chmod 0644 "$install_root/terminalninja.ps1" "$install_root/terminalninja.bash" "$install_root/terminalninja.zsh" "$install_root/starship.toml"

      touch "$HOME/.bashrc"
      touch "$HOME/.bash_profile"
      touch "$HOME/.profile"
      touch "$HOME/.zshrc"
      touch "$HOME/.zprofile"
      touch "$HOME/.zlogin"

      set_managed_block "$HOME/.bashrc" '[ -f "$HOME/.terminal-ninja/terminalninja.bash" ] && . "$HOME/.terminal-ninja/terminalninja.bash"'
      set_managed_block "$HOME/.bash_profile" '[ -f "$HOME/.terminal-ninja/terminalninja.bash" ] && . "$HOME/.terminal-ninja/terminalninja.bash"'
      set_managed_block "$HOME/.profile" '[ -f "$HOME/.terminal-ninja/terminalninja.bash" ] && . "$HOME/.terminal-ninja/terminalninja.bash"'
      set_managed_block "$HOME/.zshrc" '[ -f "$HOME/.terminal-ninja/terminalninja.zsh" ] && . "$HOME/.terminal-ninja/terminalninja.zsh"'
      set_managed_block "$HOME/.zprofile" '[ -f "$HOME/.terminal-ninja/terminalninja.zsh" ] && . "$HOME/.terminal-ninja/terminalninja.zsh"'
      set_managed_block "$HOME/.zlogin" '[ -f "$HOME/.terminal-ninja/terminalninja.zsh" ] && . "$HOME/.terminal-ninja/terminalninja.zsh"'

      pwsh_profile_dir="${XDG_CONFIG_HOME:-$HOME/.config}/powershell"
      mkdir -p "$pwsh_profile_dir"
      pwsh_profile="$pwsh_profile_dir/Microsoft.PowerShell_profile.ps1"
      cat > "$pwsh_profile" <<'EOF'
$terminalNinjaHome = Join-Path $HOME '.terminal-ninja'
$terminalNinjaProfile = Join-Path $terminalNinjaHome 'terminalninja.ps1'
if (Test-Path $terminalNinjaProfile) {
    . $terminalNinjaProfile
}
EOF

      echo "TerminalNinja assets installed to $install_root"
      echo "Restart your shell sessions to apply the changes."
    EOS

    chmod 0755, bin/"terminalninja-install"
  end

  def caveats
    <<~EOS
      Run the installer once after brew install:
        terminalninja-install

      This copies TerminalNinja assets into ~/.terminal-ninja and wires bash, zsh,
      and PowerShell startup files to source them.

      If you want TerminalNinja inside PowerShell on macOS or Linux, install
      PowerShell separately and then start pwsh after running terminalninja-install.
    EOS
  end

  test do
    assert_predicate bin/"terminalninja-install", :exist?
    assert_match "terminalninja.ps1", (bin/"terminalninja-install").read
  end
end


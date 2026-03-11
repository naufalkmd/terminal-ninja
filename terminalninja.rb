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

      install_root="$HOME/.terminal-ninja"
      mkdir -p "$install_root"

      cp "#{libexec}/terminalninja.ps1" "$install_root/terminalninja.ps1"
      cp "#{libexec}/terminalninja.bash" "$install_root/terminalninja.bash"
      cp "#{libexec}/terminalninja.zsh" "$install_root/terminalninja.zsh"
      cp "#{libexec}/starship.toml" "$install_root/starship.toml"
      chmod 0644 "$install_root/terminalninja.ps1" "$install_root/terminalninja.bash" "$install_root/terminalninja.zsh" "$install_root/starship.toml"

      touch "$HOME/.bashrc"
      touch "$HOME/.zshrc"

      python3 - <<'PY'
from pathlib import Path

marker_start = '# >>> TerminalNinja >>>'
marker_end = '# <<< TerminalNinja <<<'
blocks = {
    Path.home() / '.bashrc': marker_start + '\n[ -f "$HOME/.terminal-ninja/terminalninja.bash" ] && . "$HOME/.terminal-ninja/terminalninja.bash"\n' + marker_end + '\n',
    Path.home() / '.zshrc': marker_start + '\n[ -f "$HOME/.terminal-ninja/terminalninja.zsh" ] && . "$HOME/.terminal-ninja/terminalninja.zsh"\n' + marker_end + '\n',
}

for path, block in blocks.items():
    content = path.read_text() if path.exists() else ''
    while True:
        start = content.find(marker_start)
        if start == -1:
            break
        end = content.find(marker_end, start)
        if end == -1:
            break
        end += len(marker_end)
        while end < len(content) and content[end] in '\r\n':
            end += 1
        content = content[:start].rstrip('\r\n') + ('\n' if content[:start].strip() else '') + content[end:]
    if content and not content.endswith('\n'):
        content += '\n'
    content += block
    path.write_text(content)
PY

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


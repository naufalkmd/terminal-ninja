class Terminalninja < Formula
  desc "Shared Starship prompt and shell-native terminal workflow across PowerShell, bash, zsh, and WSL"
  homepage "https://github.com/naufalkmd/terminal-ninja"
  url "https://github.com/naufalkmd/terminal-ninja/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "374c9ef0d9cfe40c1df690efbaa009b9c13ef5cdde90c09cf00e6765f5314646"
  license "MIT"

  def install
    libexec.install "terminalninja.ps1", "terminalninja.bash", "terminalninja.zsh", "starship.toml"

    (libexec/"terminalninja-install").write <<~EOS
      #!/bin/bash
      set -euo pipefail

      selected_targets=()
      detected_ids=()
      detected_labels=()
      detected_supported=()

      add_detected_target() {
        detected_ids+=("$1")
        detected_labels+=("$2")
        detected_supported+=("$3")
      }

      detect_targets() {
        detected_ids=()
        detected_labels=()
        detected_supported=()

        if command -v bash >/dev/null 2>&1 || [ -f "$HOME/.bashrc" ] || [ -f "$HOME/.bash_profile" ] || [ -f "$HOME/.profile" ]; then
          add_detected_target "bash" "bash" "true"
        fi

        if command -v zsh >/dev/null 2>&1 || [ -f "$HOME/.zshrc" ] || [ -f "$HOME/.zprofile" ] || [ -f "$HOME/.zlogin" ]; then
          add_detected_target "zsh" "zsh" "true"
        fi

        if command -v pwsh >/dev/null 2>&1 || command -v powershell >/dev/null 2>&1 || [ -d "${XDG_CONFIG_HOME:-$HOME/.config}/powershell" ]; then
          add_detected_target "powershell" "PowerShell / pwsh" "true"
        fi
      }

      parse_targets_csv() {
        local csv="$1"
        local old_ifs="$IFS"
        local token
        IFS=','
        read -r -a selected_targets <<< "$csv"
        IFS="$old_ifs"
        for token_index in "${!selected_targets[@]}"; do
          token="${selected_targets[$token_index]}"
          token="${token#${token%%[![:space:]]*}}"
          token="${token%${token##*[![:space:]]}}"
          selected_targets[$token_index]="$token"
        done
      }

      select_targets_interactively() {
        local supported_ids=()
        local index selection token trimmed parsed_index

        echo "Detected terminal targets:"
        for index in "${!detected_ids[@]}"; do
          if [ "${detected_supported[$index]}" = "true" ]; then
            supported_ids+=("${detected_ids[$index]}")
            printf '  %s. %s\n' "$((index + 1))" "${detected_labels[$index]}"
          else
            printf '  %s. %s [unsupported]\n' "$((index + 1))" "${detected_labels[$index]}"
          fi
        done

        if [ "${#supported_ids[@]}" -eq 0 ]; then
          selected_targets=()
          return
        fi

        read -r -p 'Enter A for all supported targets, or numbers separated by commas [A]: ' selection
        if [ -z "$selection" ] || [ "$selection" = "A" ] || [ "$selection" = "a" ]; then
          selected_targets=("${supported_ids[@]}")
          return
        fi

        selected_targets=()
        local old_ifs="$IFS"
        IFS=','
        read -r -a tokens <<< "$selection"
        IFS="$old_ifs"

        for token in "${tokens[@]}"; do
          trimmed="${token#${token%%[![:space:]]*}}"
          trimmed="${trimmed%${trimmed##*[![:space:]]}}"
          if [ -z "$trimmed" ]; then
            continue
          fi
          if ! [[ "$trimmed" =~ ^[0-9]+$ ]]; then
            echo "Invalid selection '$trimmed'. Enter A or comma-separated numbers." >&2
            exit 1
          fi
          parsed_index=$((trimmed - 1))
          if [ "$parsed_index" -lt 0 ] || [ "$parsed_index" -ge "${#detected_ids[@]}" ]; then
            echo "Selection '$trimmed' is out of range." >&2
            exit 1
          fi
          if [ "${detected_supported[$parsed_index]}" != "true" ]; then
            echo "Skipping unsupported target: ${detected_labels[$parsed_index]}" >&2
            continue
          fi
          if [[ " ${selected_targets[*]} " != *" ${detected_ids[$parsed_index]} "* ]]; then
            selected_targets+=("${detected_ids[$parsed_index]}")
          fi
        done

        if [ "${#selected_targets[@]}" -eq 0 ]; then
          echo 'No supported targets were selected.' >&2
          exit 1
        fi
      }

      target_selected() {
        local wanted="$1"
        local selected

        if [ "${#selected_targets[@]}" -eq 0 ]; then
          return 0
        fi

        for selected in "${selected_targets[@]}"; do
          if [ "$selected" = "$wanted" ]; then
            return 0
          fi
        done

        return 1
      }

      detect_targets

      if [ -n "${TERMINALNINJA_TARGETS:-}" ]; then
        parse_targets_csv "$TERMINALNINJA_TARGETS"
      elif [ -t 0 ]; then
        select_targets_interactively
      else
        selected_targets=()
        for target_index in "${!detected_ids[@]}"; do
          if [ "${detected_supported[$target_index]}" = "true" ]; then
            selected_targets+=("${detected_ids[$target_index]}")
          fi
        done
      fi

      if [ "${#selected_targets[@]}" -gt 0 ]; then
        printf 'Installing TerminalNinja for selected targets: %s\n' "$(IFS=', '; echo "${selected_targets[*]}")"
      fi

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

      if target_selected "bash"; then
        set_managed_block "$HOME/.bashrc" '[ -f "$HOME/.terminal-ninja/terminalninja.bash" ] && . "$HOME/.terminal-ninja/terminalninja.bash"'
        set_managed_block "$HOME/.bash_profile" '[ -f "$HOME/.terminal-ninja/terminalninja.bash" ] && . "$HOME/.terminal-ninja/terminalninja.bash"'
        set_managed_block "$HOME/.profile" '[ -f "$HOME/.terminal-ninja/terminalninja.bash" ] && . "$HOME/.terminal-ninja/terminalninja.bash"'
      fi

      if target_selected "zsh"; then
        set_managed_block "$HOME/.zshrc" '[ -f "$HOME/.terminal-ninja/terminalninja.zsh" ] && . "$HOME/.terminal-ninja/terminalninja.zsh"'
        set_managed_block "$HOME/.zprofile" '[ -f "$HOME/.terminal-ninja/terminalninja.zsh" ] && . "$HOME/.terminal-ninja/terminalninja.zsh"'
        set_managed_block "$HOME/.zlogin" '[ -f "$HOME/.terminal-ninja/terminalninja.zsh" ] && . "$HOME/.terminal-ninja/terminalninja.zsh"'
      fi

      pwsh_profile_dir="${XDG_CONFIG_HOME:-$HOME/.config}/powershell"
      if target_selected "powershell"; then
        mkdir -p "$pwsh_profile_dir"
        pwsh_profile="$pwsh_profile_dir/Microsoft.PowerShell_profile.ps1"
        cat > "$pwsh_profile" <<'EOF'
$terminalNinjaHome = Join-Path $HOME '.terminal-ninja'
$terminalNinjaProfile = Join-Path $terminalNinjaHome 'terminalninja.ps1'
if (Test-Path $terminalNinjaProfile) {
    . $terminalNinjaProfile
}
EOF
      fi

      echo "TerminalNinja assets installed to $install_root"
      echo "Restart your shell sessions to apply the changes."
    EOS

    chmod 0755, libexec/"terminalninja-install"
    bin.install_symlink libexec/"terminalninja-install"
  end

  def caveats
    <<~EOS
      Run the installer once after brew install:
        terminalninja-install

      The installer detects supported shell targets and prompts you to apply
      TerminalNinja to all of them or select specific ones by number.

      This copies TerminalNinja assets into ~/.terminal-ninja and wires bash, zsh,
      and PowerShell startup files to source them.

      If you want TerminalNinja inside PowerShell on macOS or Linux, install
      PowerShell separately and then start pwsh after running terminalninja-install.
    EOS
  end

  test do
    assert_predicate bin/"terminalninja-install", :exist?
    assert_predicate bin/"terminalninja-install", :executable?
    assert_match "terminalninja.ps1", (libexec/"terminalninja-install").read
  end
end


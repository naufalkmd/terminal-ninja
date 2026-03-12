from __future__ import annotations

from pathlib import Path
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]
ROOT_PS1 = REPO_ROOT / "terminalninja.ps1"
TOOLS_PS1 = REPO_ROOT / "tools" / "terminalninja.ps1"


class TerminalNinjaPowerShellTests(unittest.TestCase):
    def test_root_and_tools_powershell_files_match(self) -> None:
        self.assertEqual(ROOT_PS1.read_text(encoding="utf-8"), TOOLS_PS1.read_text(encoding="utf-8"))

    def test_command_not_found_handler_chains_previous_handler(self) -> None:
        content = ROOT_PS1.read_text(encoding="utf-8")

        self.assertIn("$script:TerminalNinjaPreviousCommandNotFoundAction = $ExecutionContext.InvokeCommand.CommandNotFoundAction", content)
        self.assertIn("if ($script:TerminalNinjaPreviousCommandNotFoundAction) {", content)
        self.assertIn("& $script:TerminalNinjaPreviousCommandNotFoundAction $CommandName $CommandLookupEventArgs", content)

    def test_command_corrections_use_scriptblocks_and_supported_commands(self) -> None:
        content = ROOT_PS1.read_text(encoding="utf-8")

        self.assertIn("ScriptBlock = { Set-Location .. }.GetNewClosure()", content)
        self.assertIn("ScriptBlock = { git @args }.GetNewClosure()", content)
        self.assertIn("if ($Correction -and (Get-Command $Correction.CommandName -ErrorAction SilentlyContinue)) {", content)

    def test_git_helpers_preserve_explicit_arguments(self) -> None:
        content = ROOT_PS1.read_text(encoding="utf-8")

        self.assertIn("git status @args", content)
        self.assertIn("git push @args", content)
        self.assertIn("if ($args.Count -eq 0) {", content)
        self.assertIn("if ($args | Where-Object { \"$_\".StartsWith('-') }) {", content)
        self.assertIn("git commit -m ($args -join ' ')", content)

    def test_psreadline_configuration_is_guarded(self) -> None:
        content = ROOT_PS1.read_text(encoding="utf-8")

        self.assertIn("$psReadLineOptionCommand = Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue", content)
        self.assertIn("$psReadLineKeyHandlerCommand = Get-Command Set-PSReadLineKeyHandler -ErrorAction SilentlyContinue", content)
        self.assertIn("if ($psReadLineOptionCommand) {", content)
        self.assertIn("if ($psReadLineKeyHandlerCommand) {", content)

    def test_font_install_is_windows_only_and_marks_success_after_verification(self) -> None:
        content = ROOT_PS1.read_text(encoding="utf-8")

        self.assertIn("if ($IsWindows -and -not (Test-Path $fontInstalledMarker)) {", content)
        self.assertIn("if (Test-Path $installedFontPath) {", content)
        self.assertIn("New-Item -ItemType File -Path $fontInstalledMarker -Force | Out-Null", content)


if __name__ == "__main__":
    unittest.main()

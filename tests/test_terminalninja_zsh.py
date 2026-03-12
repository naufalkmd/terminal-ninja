from __future__ import annotations

from pathlib import Path
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]
ROOT_ZSH = REPO_ROOT / "terminalninja.zsh"
TOOLS_ZSH = REPO_ROOT / "tools" / "terminalninja.zsh"


class TerminalNinjaZshTests(unittest.TestCase):
    def test_root_and_tools_zsh_files_match(self) -> None:
        self.assertEqual(ROOT_ZSH.read_text(encoding="utf-8"), TOOLS_ZSH.read_text(encoding="utf-8"))

    def test_starship_reset_uses_one_shot_hook_removal(self) -> None:
        content = ROOT_ZSH.read_text(encoding="utf-8")

        self.assertNotIn("while add-zsh-hook -d", content)
        self.assertIn('add-zsh-hook -d precmd prompt_starship_precmd >/dev/null 2>&1 || true', content)
        self.assertIn('add-zsh-hook -d preexec prompt_starship_preexec >/dev/null 2>&1 || true', content)

    def test_completion_menu_defaults_respect_existing_zstyle(self) -> None:
        content = ROOT_ZSH.read_text(encoding="utf-8")

        self.assertIn("_terminal_ninja_enable_zsh_completion_menu()", content)
        self.assertIn("if zmodload zsh/complist 2>/dev/null; then", content)
        self.assertIn("if ! zstyle -L ':completion:*' menu >/dev/null 2>&1; then", content)
        self.assertIn("zstyle ':completion:*' menu select", content)

    def test_autosuggestions_load_only_when_plugin_is_available(self) -> None:
        content = ROOT_ZSH.read_text(encoding="utf-8")

        self.assertIn("_terminal_ninja_load_zsh_autosuggestions()", content)
        self.assertIn('[[ -n "${HOMEBREW_PREFIX:-}" ]]', content)
        self.assertIn('/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh', content)
        self.assertIn('/usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh', content)
        self.assertIn('_terminal_ninja_load_zsh_autosuggestions >/dev/null 2>&1 || true', content)


if __name__ == "__main__":
    unittest.main()

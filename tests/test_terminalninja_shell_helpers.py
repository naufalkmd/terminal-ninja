from __future__ import annotations

from pathlib import Path
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]
ROOT_BASH = REPO_ROOT / "terminalninja.bash"
TOOLS_BASH = REPO_ROOT / "tools" / "terminalninja.bash"
ROOT_ZSH = REPO_ROOT / "terminalninja.zsh"
TOOLS_ZSH = REPO_ROOT / "tools" / "terminalninja.zsh"


class TerminalNinjaShellHelperTests(unittest.TestCase):
    def test_root_and_tools_bash_files_match(self) -> None:
        self.assertEqual(ROOT_BASH.read_text(encoding="utf-8"), TOOLS_BASH.read_text(encoding="utf-8"))

    def test_ll_alias_supports_gnu_and_bsd_ls(self) -> None:
        expected_fragments = (
            "if ls --color=auto -d . >/dev/null 2>&1; then",
            "elif ls -G -d . >/dev/null 2>&1; then",
            "alias ll='ls -lah --color=auto'",
            "alias ll='ls -lah -G'",
            "alias ll='ls -lah'",
        )

        for content in (
            ROOT_BASH.read_text(encoding="utf-8"),
            ROOT_ZSH.read_text(encoding="utf-8"),
        ):
            for fragment in expected_fragments:
                self.assertIn(fragment, content)

    def test_memorytop_has_bsd_fallback(self) -> None:
        expected_fragments = (
            "if ps -eo pid,comm,%mem,%cpu --sort=-%mem >/dev/null 2>&1; then",
            "output=\"$(ps -axo pid,comm,%mem,%cpu 2>/dev/null)\" || return 1",
            "printf '%s\\n' \"$output\" | head -n 1",
            "printf '%s\\n' \"$output\" | tail -n +2 | sort -k3,3nr | head -n 10",
        )

        for content in (
            ROOT_BASH.read_text(encoding="utf-8"),
            ROOT_ZSH.read_text(encoding="utf-8"),
        ):
            for fragment in expected_fragments:
                self.assertIn(fragment, content)


if __name__ == "__main__":
    unittest.main()

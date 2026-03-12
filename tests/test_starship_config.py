from __future__ import annotations

from pathlib import Path
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]
ROOT_STARSHIP = REPO_ROOT / "starship.toml"
TOOLS_STARSHIP = REPO_ROOT / "tools" / "starship.toml"


class StarshipConfigTests(unittest.TestCase):
    def test_root_and_tools_starship_configs_match(self) -> None:
        self.assertEqual(
            ROOT_STARSHIP.read_text(encoding="utf-8"),
            TOOLS_STARSHIP.read_text(encoding="utf-8"),
        )

    def test_supported_os_symbols_use_icons(self) -> None:
        content = ROOT_STARSHIP.read_text(encoding="utf-8")

        self.assertIn('Linux = "\\uE70F"', content)
        self.assertIn('Macos = "\\uE711"', content)
        self.assertIn('Windows = "\\uE70F"', content)
        self.assertIn('Ubuntu = "\\uE70F"', content)


if __name__ == "__main__":
    unittest.main()

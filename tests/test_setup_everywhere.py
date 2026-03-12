from __future__ import annotations

from pathlib import Path
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]
SETUP_EVERYWHERE = REPO_ROOT / "setup-everywhere.ps1"


class SetupEverywhereTests(unittest.TestCase):
    def test_wsl_starship_install_does_not_pipe_remote_script_to_shell(self) -> None:
        content = SETUP_EVERYWHERE.read_text(encoding="utf-8")

        self.assertNotIn("curl -fsSL https://starship.rs/install.sh | sh", content)
        self.assertNotIn("wget -qO- https://starship.rs/install.sh | sh", content)

    def test_wsl_starship_install_verifies_downloaded_release(self) -> None:
        content = SETUP_EVERYWHERE.read_text(encoding="utf-8")

        self.assertIn('base_url="https://github.com/starship/starship/releases/latest/download"', content)
        self.assertIn('checksum="${archive}.sha256"', content)
        self.assertIn('(cd "$tmpdir" && sha256sum -c "$checksum")', content)
        self.assertIn('install -m 0755 "$tmpdir/starship" "$HOME/.local/bin/starship"', content)
        self.assertIn('if ($exitCode -eq 15) {', content)
        self.assertIn('if ($exitCode -eq 16) {', content)


if __name__ == "__main__":
    unittest.main()

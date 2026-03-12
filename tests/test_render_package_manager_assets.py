from __future__ import annotations

import hashlib
import importlib.util
import io
from pathlib import Path
import unittest
from unittest import mock
from urllib.error import HTTPError


SCRIPT_PATH = Path(__file__).resolve().parents[1] / ".github" / "scripts" / "render_package_manager_assets.py"
SPEC = importlib.util.spec_from_file_location("render_package_manager_assets", SCRIPT_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC is not None
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class FakeResponse:
    def __init__(self, payload: bytes) -> None:
        self.buffer = io.BytesIO(payload)

    def __enter__(self) -> "FakeResponse":
        return self

    def __exit__(self, exc_type, exc, tb) -> None:
        self.buffer.close()

    def read(self, size: int = -1) -> bytes:
        return self.buffer.read(size)


class RenderPackageManagerAssetsTests(unittest.TestCase):
    def test_sha256_for_url_retries_after_404_then_succeeds(self) -> None:
        url = "https://example.invalid/archive.zip"
        not_found = HTTPError(url, 404, "Not Found", hdrs=None, fp=None)
        payload = b"terminal-ninja"
        responses = [not_found, not_found, FakeResponse(payload)]

        with mock.patch.object(MODULE, "urlopen", side_effect=responses) as mocked_urlopen:
            with mock.patch.object(MODULE.time, "sleep") as mocked_sleep:
                digest = MODULE.sha256_for_url(url, max_attempts=3, retry_delay_seconds=0)

        self.assertEqual(digest, hashlib.sha256(payload).hexdigest())
        self.assertEqual(mocked_urlopen.call_count, 3)
        self.assertEqual(mocked_sleep.call_count, 2)

    def test_sha256_for_url_raises_after_final_404(self) -> None:
        url = "https://example.invalid/archive.zip"
        not_found = HTTPError(url, 404, "Not Found", hdrs=None, fp=None)

        with mock.patch.object(MODULE, "urlopen", side_effect=[not_found, not_found]):
            with mock.patch.object(MODULE.time, "sleep") as mocked_sleep:
                with self.assertRaises(RuntimeError) as context:
                    MODULE.sha256_for_url(url, max_attempts=2, retry_delay_seconds=0)

        self.assertIn("Release archive not found", str(context.exception))
        self.assertEqual(mocked_sleep.call_count, 1)


if __name__ == "__main__":
    unittest.main()

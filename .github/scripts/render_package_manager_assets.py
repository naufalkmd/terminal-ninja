from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import sys
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


def sha256_for_url(url: str) -> str:
    digest = hashlib.sha256()
    request = Request(url, headers={"User-Agent": "terminalninja-release-renderer/1.0"})

    try:
        with urlopen(request) as response:
            while True:
                chunk = response.read(1024 * 1024)
                if not chunk:
                    break
                digest.update(chunk)
    except HTTPError as error:
        if error.code == 404:
            raise RuntimeError(
                f"Release archive not found: {url}. "
                "Ensure the tag exists and is pushed. For workflow_dispatch, either provide a tag explicitly or let the workflow create one."
            ) from error

        raise RuntimeError(f"Failed to download release archive {url}: HTTP {error.code}") from error
    except URLError as error:
        raise RuntimeError(f"Failed to download release archive {url}: {error.reason}") from error

    return digest.hexdigest()


def render_template(path: Path, replacements: dict[str, str]) -> str:
    content = path.read_text(encoding="utf-8")
    for key, value in replacements.items():
        content = content.replace(key, value)
    return content


def main() -> int:
    workspace = Path(os.environ["GITHUB_WORKSPACE"])
    output_dir = workspace / "dist-package-managers"
    output_dir.mkdir(exist_ok=True)

    owner = os.environ["RELEASE_OWNER"]
    repo = os.environ["RELEASE_REPO"]
    tag = os.environ["RELEASE_TAG"]
    version = tag[1:] if tag.startswith("v") else tag

    tarball_url = f"https://github.com/{owner}/{repo}/archive/refs/tags/{tag}.tar.gz"
    zip_url = f"https://github.com/{owner}/{repo}/archive/refs/tags/{tag}.zip"

    tarball_sha = sha256_for_url(tarball_url)
    zip_sha = sha256_for_url(zip_url)

    replacements = {
        "__OWNER__": owner,
        "__REPO__": repo,
        "__VERSION__": version,
        "__TARBALL_URL__": tarball_url,
        "__TARBALL_SHA256__": tarball_sha,
        "__ZIP_URL__": zip_url,
        "__ZIP_SHA256__": zip_sha,
    }

    formula = render_template(workspace / "packaging" / "terminalninja.rb.template", replacements)
    manifest = render_template(workspace / "packaging" / "terminalninja-scoop.json.template", replacements)

    formula_path = output_dir / "terminalninja.rb"
    manifest_path = output_dir / "terminalninja.json"
    formula_path.write_text(formula, encoding="utf-8")
    manifest_path.write_text(manifest, encoding="utf-8")

    metadata = {
        "owner": owner,
        "repo": repo,
        "tag": tag,
        "version": version,
        "tarball_url": tarball_url,
        "tarball_sha256": tarball_sha,
        "zip_url": zip_url,
        "zip_sha256": zip_sha,
        "formula_path": str(formula_path),
        "manifest_path": str(manifest_path),
    }
    (output_dir / "metadata.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")

    github_output = os.environ.get("GITHUB_OUTPUT")
    if github_output:
        with open(github_output, "a", encoding="utf-8") as handle:
            handle.write(f"version={version}\n")
            handle.write(f"tag={tag}\n")
            handle.write(f"formula_path={formula_path}\n")
            handle.write(f"manifest_path={manifest_path}\n")
            handle.write(f"tarball_sha256={tarball_sha}\n")
            handle.write(f"zip_sha256={zip_sha}\n")

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except RuntimeError as error:
        print(error, file=sys.stderr)
        raise SystemExit(1)

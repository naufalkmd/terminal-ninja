# Publishing Guide

This repository now supports release-driven package publishing for Homebrew and Scoop. Chocolatey remains a separate publish step.

## What Is Automated

The workflow in `.github/workflows/publish-scoop-homebrew.yml` does this when you publish a GitHub release, or when you run it manually with a tag:

1. Resolves the release tag and repository metadata.
2. Downloads the GitHub release source archives for that tag.
3. Computes SHA256 hashes for the `.tar.gz` and `.zip` archives.
4. Renders:
   - `dist-package-managers/terminalninja.rb`
   - `dist-package-managers/terminalninja.json`
5. Pushes the rendered formula to your Homebrew tap repository.
6. Pushes the rendered manifest to your Scoop bucket repository.

The source templates live in:

- `packaging/terminalninja.rb.template`
- `packaging/terminalninja-scoop.json.template`

The rendering logic lives in:

- `.github/scripts/render_package_manager_assets.py`

## Required GitHub Configuration

Configure these in the main TerminalNinja repository before expecting the workflow to publish anything.

### Secret

- `PACKAGE_REPO_TOKEN`

This token must be able to push to the external Homebrew tap and Scoop bucket repositories.

### Repository Variables

- `HOMEBREW_TAP_REPO`
  - Format: `owner/homebrew-tap`
- `SCOOP_BUCKET_REPO`
  - Format: `owner/scoop-bucket`

### Optional Repository Variables

- `HOMEBREW_FORMULA_PATH`
  - Default: `Formula/terminalninja.rb`
- `SCOOP_MANIFEST_PATH`
  - Default: `bucket/terminalninja.json`

If a target repository variable or the shared token is missing, that publish job is skipped and the workflow still completes the render stage.

## Release Flow

### Automatic on GitHub release

1. Create and push a tag such as `v1.2.3`.
2. Publish a GitHub release for that tag.
3. GitHub Actions renders the Homebrew and Scoop assets.
4. GitHub Actions commits the generated files into the configured tap and bucket repositories.

### Manual workflow dispatch

You can also run the workflow manually and provide an existing tag:

1. Open the Actions tab.
2. Run `Publish Scoop And Homebrew`.
3. Enter a tag such as `v1.2.3`.

## Homebrew Repository Layout

The workflow copies the rendered formula into the configured tap repository. By default it writes:

```text
Formula/terminalninja.rb
```

Users then install with:

```bash
brew tap YOUR_ORG/tap
brew install terminalninja
```

## Scoop Repository Layout

The workflow copies the rendered manifest into the configured bucket repository. By default it writes:

```text
bucket/terminalninja.json
```

Users then install with:

```powershell
scoop bucket add YOUR_BUCKET https://github.com/YOUR_ORG/YOUR_BUCKET
scoop install terminalninja
```

## Local Rendering Check

You can validate the generated package manager assets locally before cutting a release.

```powershell
$env:GITHUB_WORKSPACE = (Get-Location).Path
$env:RELEASE_OWNER = 'YOUR_ORG'
$env:RELEASE_REPO = 'terminal-ninja'
$env:RELEASE_TAG = 'v1.2.3'
python .github/scripts/render_package_manager_assets.py
```

This writes the rendered artifacts into `dist-package-managers`.

You can also use the helper script:

```powershell
.\setup-publishing.ps1 -ReleaseTag v1.2.3 -RenderAssets
```

## Chocolatey

Chocolatey is still published separately. The workflow in this repository does not push Chocolatey packages.

Typical publish flow:

```powershell
choco pack terminalninja.nuspec
choco push terminalninja.<version>.nupkg --source https://push.chocolatey.org/ --api-key YOUR_API_KEY
```

## Notes

- The generated Homebrew formula is based on `packaging/terminalninja.rb.template`; the root-level `terminalninja.rb` file is a checked-in rendered snapshot.
- The generated Scoop manifest is based on `packaging/terminalninja-scoop.json.template`.
- The workflow publishes source-archive based packages, so the release tag must exist before the job runs.
- If you change install behavior, update both templates and this guide.

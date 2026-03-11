param(
    [string]$ReleaseOwner = 'naufalkmd',
    [string]$ReleaseRepo = 'terminal-ninja',
    [string]$ReleaseTag,
    [switch]$RenderAssets,
    [switch]$ShowConfigOnly
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$renderScript = Join-Path $repoRoot '.github\scripts\render_package_manager_assets.py'

Write-Host 'TerminalNinja publishing setup' -ForegroundColor Cyan
Write-Host ('=' * 40) -ForegroundColor Cyan

if (-not $ReleaseTag -and -not $ShowConfigOnly) {
    $ReleaseTag = Read-Host 'Release tag to render (example: v1.2.3)'
}

Write-Host "`nGitHub Actions publishing configuration" -ForegroundColor Yellow
Write-Host 'Required secret:' -ForegroundColor White
Write-Host '  PACKAGE_REPO_TOKEN' -ForegroundColor Gray
Write-Host 'Required repository variables:' -ForegroundColor White
Write-Host '  HOMEBREW_TAP_REPO' -ForegroundColor Gray
Write-Host '  SCOOP_BUCKET_REPO' -ForegroundColor Gray
Write-Host 'Optional repository variables:' -ForegroundColor White
Write-Host '  HOMEBREW_FORMULA_PATH (default: Formula/terminalninja.rb)' -ForegroundColor Gray
Write-Host '  SCOOP_MANIFEST_PATH (default: bucket/terminalninja.json)' -ForegroundColor Gray

if ($ShowConfigOnly) {
    Write-Host "`nNo files rendered. Use -RenderAssets with a release tag to generate local publishing artifacts." -ForegroundColor Green
    return
}

if ([string]::IsNullOrWhiteSpace($ReleaseTag)) {
    throw 'ReleaseTag is required unless -ShowConfigOnly is used.'
}

if ($RenderAssets) {
    if (-not (Test-Path $renderScript)) {
        throw "Render script not found: $renderScript"
    }

    Write-Host "`nRendering Homebrew and Scoop assets for $ReleaseOwner/$ReleaseRepo $ReleaseTag..." -ForegroundColor Cyan

    $previousWorkspace = $env:GITHUB_WORKSPACE
    $previousOwner = $env:RELEASE_OWNER
    $previousRepo = $env:RELEASE_REPO
    $previousTag = $env:RELEASE_TAG

    try {
        $env:GITHUB_WORKSPACE = $repoRoot
        $env:RELEASE_OWNER = $ReleaseOwner
        $env:RELEASE_REPO = $ReleaseRepo
        $env:RELEASE_TAG = $ReleaseTag

        python $renderScript
        if ($LASTEXITCODE -ne 0) {
            throw "Rendering failed with exit code $LASTEXITCODE"
        }
    } finally {
        $env:GITHUB_WORKSPACE = $previousWorkspace
        $env:RELEASE_OWNER = $previousOwner
        $env:RELEASE_REPO = $previousRepo
        $env:RELEASE_TAG = $previousTag
    }

    Write-Host "`nRendered artifacts:" -ForegroundColor Yellow
    Write-Host '  dist-package-managers/terminalninja.rb' -ForegroundColor Gray
    Write-Host '  dist-package-managers/terminalninja.json' -ForegroundColor Gray
    Write-Host '  dist-package-managers/metadata.json' -ForegroundColor Gray
}

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host '1. Publish or verify the GitHub release tag exists.' -ForegroundColor White
Write-Host '2. Configure PACKAGE_REPO_TOKEN plus the tap and bucket repo variables in GitHub.' -ForegroundColor White
Write-Host '3. Run the Publish Scoop And Homebrew workflow, or publish the GitHub release to trigger it automatically.' -ForegroundColor White
Write-Host '4. Publish Chocolatey separately with choco pack and choco push.' -ForegroundColor White

param(
    [string]$BuildName,
    [string]$BuildNumber,
    [string]$BuildType = "release"
)

$ErrorActionPreference = "Stop"

Write-Host "=== MSIX packaging ==="

$bundleDir = "build/windows/x64/runner/$(
    if ($BuildType -eq "release") { "Release" } else { "Debug" }
)"

if (-not (Test-Path $bundleDir)) {
    Write-Error "Bundle not found: $bundleDir"
    exit 1
}

Write-Host "✓ Using existing build: $bundleDir"

# ─── Clean old msix ─────────────────────────────

Remove-Item ebalistyka*.msix -ErrorAction SilentlyContinue

# ─── Build MSIX ────────────────────────────────

dart run msix:create

# ─── Move to artifacts ─────────────────────────

$msixOut = "artifacts\msix"
New-Item -ItemType Directory -Force -Path $msixOut | Out-Null

$generated = Get-ChildItem -Path "." -Filter "*.msix" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $generated) {
    Write-Error "MSIX not generated"
    exit 1
}

Move-Item $generated.FullName "$msixOut\"

Write-Host "✓ MSIX stored in artifacts/msix/"
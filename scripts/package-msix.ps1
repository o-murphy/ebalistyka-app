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
Remove-Item "$bundleDir/*.msix" -ErrorAction SilentlyContinue

# ─── Build MSIX ────────────────────────────────
dart run msix:create --build-number $BuildNumber --build-name $BuildName

# ─── Move to artifacts ─────────────────────────
$msixOut = "artifacts\msix"
New-Item -ItemType Directory -Force -Path $msixOut | Out-Null

$possiblePaths = @(
    "*.msix",
    "$bundleDir/*.msix"
)

$generated = $null
foreach ($pattern in $possiblePaths) {
    $generated = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    
    if ($generated) {
        Write-Host "Found MSIX at: $($generated.FullName)"
        break
    }
}

if (-not $generated) {
    Write-Error "MSIX not generated. Checked patterns: $($possiblePaths -join ', ')"
    Write-Host "Current directory contents:"
    Get-ChildItem -Path "." | Format-Table
    Write-Host "Bundle directory contents:"
    Get-ChildItem -Path $bundleDir | Format-Table
    exit 1
}

Move-Item -Path $generated.FullName -Destination "$msixOut\" -Force

Write-Host "✓ MSIX stored in artifacts/msix/$($generated.Name)"

Write-Host "=== MSIX packaging completed successfully ==="

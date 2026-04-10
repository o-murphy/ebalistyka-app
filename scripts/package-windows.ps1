# Package a Flutter Windows bundle into the artifacts/ directory.
#
# Usage:
#   .\package-windows.ps1 -BundleDir <path> -BuildName <ver> -BuildNumber <n> [-BuildType release|debug]
#
# Collects: ebalistyka.exe, all DLLs, data/ directory, optional .pdb for debug.
# Outputs into ./artifacts/

param(
    [Parameter(Mandatory)][string]$BundleDir,
    [Parameter(Mandatory)][string]$BuildName,
    [Parameter(Mandatory)][string]$BuildNumber,
    [string]$BuildType = "release"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $BundleDir)) {
    Write-Error "Bundle directory not found: $BundleDir"
    Write-Host "Searching for ebalistyka.exe under build/:"
    Get-ChildItem -Path build -Recurse -Filter "ebalistyka.exe" -ErrorAction SilentlyContinue |
        ForEach-Object { Write-Host "  $($_.FullName)" }
    exit 1
}

New-Item -ItemType Directory -Force -Path artifacts | Out-Null

# Executable
$exePath = Join-Path $BundleDir "ebalistyka.exe"
if (-not (Test-Path $exePath)) {
    Write-Error "Executable not found: $exePath"
    Get-ChildItem $BundleDir | ForEach-Object { Write-Host "  $($_.Name)" }
    exit 1
}
Copy-Item $exePath "artifacts\"
Write-Host "✓ ebalistyka.exe"

# DLLs
$dlls = Get-ChildItem -Path $BundleDir -Filter "*.dll"
if ($dlls.Count -eq 0) {
    Write-Error "No .dll files found in $BundleDir — native libraries not bundled"
    exit 1
}
$dlls | Copy-Item -Destination "artifacts\"
Write-Host "✓ DLLs ($($dlls.Count) files):"
$dlls | ForEach-Object { Write-Host "    $($_.Name)" }

# Critical: bclibc_ffi
if (-not (Test-Path "artifacts\bclibc_ffi.dll")) {
    Write-Error "bclibc_ffi.dll not found — app will crash on startup"
    exit 1
}
Write-Host "✓ bclibc_ffi.dll present"

# Data directory (Flutter assets, fonts, etc.)
if (Test-Path "$BundleDir\data") {
    Copy-Item -Path "$BundleDir\data" -Destination "artifacts\data" -Recurse
    Write-Host "✓ data/"
}

# PDB for debug builds
if ($BuildType -eq "debug" -and (Test-Path "$BundleDir\ebalistyka.pdb")) {
    Copy-Item "$BundleDir\ebalistyka.pdb" "artifacts\"
    Write-Host "✓ ebalistyka.pdb (debug symbols)"
}

# Version info
$versionContent = "eBalistyka $BuildName (build $BuildNumber)`r`nWindows x86_64`r`n`r`nRun: ebalistyka.exe"
Set-Content -Path "artifacts\VERSION.txt" -Value $versionContent
Write-Host "✓ VERSION.txt"

Write-Host ""
Write-Host "Artifacts:"
Get-ChildItem artifacts | Format-Table Name, Length -AutoSize

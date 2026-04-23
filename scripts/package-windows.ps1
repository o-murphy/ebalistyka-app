# Package a Flutter Windows bundle into artifacts/portable/ebalistyka_windows_<arch>.zip
#
# Usage:
#   .\package-windows.ps1 -BundleDir <path> -BuildName <ver> -BuildNumber <n> [-BuildType release|debug] [-Arch x86_64|aarch64]

param(
    [Parameter(Mandatory)][string]$BundleDir,
    [Parameter(Mandatory)][string]$BuildName,
    [Parameter(Mandatory)][string]$BuildNumber,
    [string]$BuildType = "release",
    [string]$Arch = "x86_64"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $BundleDir)) {
    Write-Error "Bundle directory not found: $BundleDir"
    Get-ChildItem -Path build -Recurse -Filter "ebalistyka.exe" -ErrorAction SilentlyContinue |
        ForEach-Object { Write-Host "  $($_.FullName)" }
    exit 1
}

$staging = "artifacts\_staging_portable"
New-Item -ItemType Directory -Force -Path $staging | Out-Null

# Executable
$exePath = Join-Path $BundleDir "ebalistyka.exe"
if (-not (Test-Path $exePath)) {
    Write-Error "Executable not found: $exePath"
    Get-ChildItem $BundleDir | ForEach-Object { Write-Host "  $($_.Name)" }
    exit 1
}
Copy-Item $exePath "$staging\"
Write-Host "✓ ebalistyka.exe"

# DLLs
$dlls = Get-ChildItem -Path $BundleDir -Filter "*.dll"
if ($dlls.Count -eq 0) {
    Write-Error "No .dll files found in $BundleDir — native libraries not bundled"
    exit 1
}
$dlls | Copy-Item -Destination "$staging\"
Write-Host "✓ DLLs ($($dlls.Count) files):"
$dlls | ForEach-Object { Write-Host "    $($_.Name)" }

if (-not (Test-Path "$staging\bclibc_ffi.dll")) {
    Write-Error "bclibc_ffi.dll not found — app will crash on startup"
    exit 1
}
Write-Host "✓ bclibc_ffi.dll present"

# Data directory (Flutter assets, fonts, etc.)
if (Test-Path "$BundleDir\data") {
    Copy-Item -Path "$BundleDir\data" -Destination "$staging\data" -Recurse
    Write-Host "✓ data/"
}

# PDB for debug builds
if ($BuildType -eq "debug" -and (Test-Path "$BundleDir\ebalistyka.pdb")) {
    Copy-Item "$BundleDir\ebalistyka.pdb" "$staging\"
    Write-Host "✓ ebalistyka.pdb (debug symbols)"
}

# Zip
$outDir = "artifacts\portable"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$zipPath = "$outDir\ebalistyka_windows_${Arch}.zip"
Remove-Item $zipPath -ErrorAction SilentlyContinue
Compress-Archive -Path "$staging\*" -DestinationPath $zipPath
Remove-Item $staging -Recurse -Force

Write-Host ""
Write-Host "✓ $zipPath"
Write-Host "Size: $([math]::Round((Get-Item $zipPath).Length / 1MB, 1)) MB"

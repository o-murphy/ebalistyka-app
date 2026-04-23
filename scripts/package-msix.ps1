[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '',
    Justification = 'Password forwarded to msix tool via env var, not stored')]
param(
    [string]$BuildName,
    [string]$BuildNumber,
    [string]$BuildType = "release",
    [string]$Arch = "x86_64",
    [string]$CertificatePath = "certs\ebalistyka_cert.pfx",
    [string]$CertificatePassword = "YourStrongPassword123!",
    [string]$MsixVersion,
    [string]$GithubRepo  # e.g. "o-murphy/ebalistyka", used to generate .appinstaller
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

# Resolve to absolute path — msix package requires it
if (-not [System.IO.Path]::IsPathRooted($CertificatePath)) {
    $CertificatePath = Join-Path (Get-Location) $CertificatePath
}

if (-not (Test-Path $CertificatePath)) {
    Write-Error "Certificate not found: $CertificatePath`nRun first: .\scripts\generate-ca.ps1"
    exit 1
}

# Derive MSIX version from pubspec.yaml if not given explicitly
# pubspec format: "0.1.0+9"  ->  MSIX format: "0.1.0.9"
if (-not $MsixVersion) {
    $pubspecContent = Get-Content pubspec.yaml -Raw
    if ($pubspecContent -match '(?m)^version:\s+(\d+\.\d+\.\d+)(?:\+(\d+))?') {
        $build = if ($Matches[2]) { $Matches[2] } else { '0' }
        $MsixVersion = "$($Matches[1]).$build"
    } else {
        Write-Error "Cannot parse version from pubspec.yaml"
        exit 1
    }
}

Write-Host "Bundle:       $bundleDir"
Write-Host "Certificate:  $CertificatePath"
Write-Host "MSIX version: $MsixVersion"

# Import certificate into Windows trust stores so msix:create does not prompt interactively.
# CurrentUser\My   -- required for code signing
# TrustedPeople    -- required for the resulting MSIX to be installable without warnings
$securePassword = ConvertTo-SecureString -String $CertificatePassword -Force -AsPlainText
Import-PfxCertificate -FilePath $CertificatePath `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -Password $securePassword -Confirm:$false | Out-Null
Write-Host "Certificate imported to CurrentUser\My"

try {
    Import-PfxCertificate -FilePath $CertificatePath `
        -CertStoreLocation "Cert:\LocalMachine\TrustedPeople" `
        -Password $securePassword -Confirm:$false | Out-Null
    Write-Host "Certificate imported to LocalMachine\TrustedPeople"
} catch {
    Import-PfxCertificate -FilePath $CertificatePath `
        -CertStoreLocation "Cert:\CurrentUser\TrustedPeople" `
        -Password $securePassword -Confirm:$false | Out-Null
    Write-Host "Certificate imported to CurrentUser\TrustedPeople (no admin rights)"
}

# Clean old MSIX
Remove-Item "$bundleDir\ebalistyka*.msix" -ErrorAction SilentlyContinue

# Build MSIX -- pass cert via CLI args (pubspec.yaml ${env.X} syntax is not supported by msix package)
dart run msix:create `
    --certificate-path "$CertificatePath" `
    --certificate-password "$CertificatePassword" `
    --version "$MsixVersion"

# Move to artifacts
$msixOut = "artifacts\msix"
New-Item -ItemType Directory -Force -Path $msixOut | Out-Null
Remove-Item "$msixOut\ebalistyka*.msix" -ErrorAction SilentlyContinue
Remove-Item "$msixOut\ebalistyka*.appinstaller" -ErrorAction SilentlyContinue

$generated = Get-ChildItem -Path $bundleDir -Filter "*.msix" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $generated) {
    Write-Error "MSIX not generated"
    exit 1
}

$targetName = "ebalistyka_windows_${Arch}.msix"
Move-Item $generated.FullName "$msixOut\$targetName"
Write-Host "\nMSIX: $msixOut\$targetName"

# Generate .appinstaller for Windows native auto-update.
# Users install via .appinstaller -- Windows checks for updates on each launch.
# Closing "@  MUST be at column 0; use array join to avoid here-string indentation issues.
$repo = if ($GithubRepo) { $GithubRepo } else { $env:GITHUB_REPOSITORY }
if ($repo) {
    $procArch = if ($Arch -eq "x86_64") { "x64" } elseif ($Arch -eq "aarch64") { "arm64" } else { $Arch }
    $baseUrl = "https://github.com/$repo/releases/latest/download"

    $xml = (
        '<?xml version="1.0" encoding="utf-8"?>',
        '<AppInstaller',
        '  xmlns="http://schemas.microsoft.com/appx/appinstaller/2017/2"',
        "  Version=`"$MsixVersion`"",
        "  Uri=`"$baseUrl/ebalistyka.appinstaller`">",
        '',
        '  <MainPackage',
        '    Name="com.o.murphy.ebalistyka"',
        "    Version=`"$MsixVersion`"",
        '    Publisher="CN=o-murphy"',
        "    ProcessorArchitecture=`"$procArch`"",
        "    Uri=`"$baseUrl/ebalistyka_windows_${Arch}.msix`"/>",
        '',
        '  <UpdateSettings>',
        '    <OnLaunch',
        '      HoursBetweenUpdateChecks="24"',
        '      UpdateBlocksActivation="false"',
        '      ShowPrompt="true"/>',
        '  </UpdateSettings>',
        '</AppInstaller>'
    ) -join "`r`n"

    $appinstallerPath = "$msixOut\ebalistyka.appinstaller"
    [System.IO.File]::WriteAllText($appinstallerPath, $xml, [System.Text.Encoding]::UTF8)
    Write-Host ".appinstaller: $appinstallerPath"
} else {
    Write-Host "No GITHUB_REPO -- skipping .appinstaller"
}

Write-Host ""
Write-Host "Done."

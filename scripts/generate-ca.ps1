[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '',
    Justification = 'Plain text is intentional: printed so the user can set it as a CI secret')]
param(
    [string]$Password = "YourStrongPassword123!",
    [string]$OutputDir = "certs"
)

$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$pfxPath = Join-Path (Resolve-Path ".") "$OutputDir\ebalistyka_cert.pfx"
$base64Path = Join-Path (Resolve-Path ".") "$OutputDir\certificate_base64.txt"

# Create self-signed code-signing certificate
$cert = New-SelfSignedCertificate -Type CodeSigningCert `
    -Subject "CN=o-murphy" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -KeyUsage DigitalSignature `
    -KeySpec KeyExchange `
    -KeyLength 2048 `
    -NotAfter (Get-Date).AddYears(10)

$cerPath  = Join-Path (Resolve-Path ".") "$OutputDir\ebalistyka_cert.cer"
$securePassword = ConvertTo-SecureString -String $Password -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $securePassword | Out-Null
Export-Certificate   -Cert $cert -FilePath $cerPath  -Type CERT | Out-Null

Write-Host "Certificate (PFX): $pfxPath"
Write-Host "Certificate (CER): $cerPath  ← distribute to users for trust store install"

# Export Base64 for CI secrets
$pfxBytes = [System.IO.File]::ReadAllBytes($pfxPath)
$base64 = [System.Convert]::ToBase64String($pfxBytes)
[System.IO.File]::WriteAllText($base64Path, $base64, [System.Text.Encoding]::ASCII)

Write-Host "Base64:      $base64Path"
Write-Host ""
Write-Host "=== LOCAL BUILD ==="
Write-Host ".\scripts\package-msix.ps1"
Write-Host ""
Write-Host "=== GITHUB SECRETS ==="
Write-Host "CERTIFICATE_BASE64   = content of $base64Path"
Write-Host "CERTIFICATE_PASSWORD = $Password"

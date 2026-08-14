[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^https://')]
    [string]$ApiBaseUrl
)

$ErrorActionPreference = "Stop"
$appRoot = Split-Path -Parent $PSScriptRoot
$propertiesPath = Join-Path $appRoot "android/key.properties"
$apkPath = Join-Path $appRoot "build/app/outputs/flutter-apk/app-release.apk"

if (-not (Test-Path -LiteralPath $propertiesPath)) {
    throw "Falta android/key.properties. Ejecuta primero .\scripts\create-signing-key.ps1"
}
if (-not $ApiBaseUrl.EndsWith('/v1')) {
    throw "ApiBaseUrl debe terminar en /v1."
}
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "No se encontro Flutter en PATH."
}

Push-Location $appRoot
try {
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get fallo." }

    & flutter analyze
    if ($LASTEXITCODE -ne 0) { throw "flutter analyze encontro errores." }

    & flutter test
    if ($LASTEXITCODE -ne 0) { throw "Las pruebas de Flutter fallaron." }

    & flutter build apk --release "--dart-define=API_BASE_URL=$ApiBaseUrl"
    if ($LASTEXITCODE -ne 0) { throw "No se pudo compilar el APK release." }

    $hash = Get-FileHash -Algorithm SHA256 -LiteralPath $apkPath
    Write-Host "APK: $apkPath"
    Write-Host "SHA-256: $($hash.Hash)"
}
finally {
    Pop-Location
}

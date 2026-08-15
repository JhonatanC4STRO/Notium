[CmdletBinding()]
param(
    [string]$DistinguishedName = "CN=Jhonatan Castro, OU=Notium, O=Notium, L=Bogota, ST=Bogota, C=CO",
    [switch]$GeneratePassword
)

$ErrorActionPreference = "Stop"
$appRoot = Split-Path -Parent $PSScriptRoot
$androidDir = Join-Path $appRoot "android"
$keyStorePath = Join-Path $androidDir "upload-keystore.jks"
$propertiesPath = Join-Path $androidDir "key.properties"

if ((Test-Path -LiteralPath $keyStorePath) -or (Test-Path -LiteralPath $propertiesPath)) {
    throw "Ya existe una clave o key.properties. No se reemplazo ningun archivo."
}

if (-not (Get-Command keytool -ErrorAction SilentlyContinue)) {
    throw "No se encontro keytool. Instala un JDK y vuelve a ejecutar el script."
}

$generatedPassword = $null
if ($GeneratePassword) {
    $randomBytes = New-Object byte[] 32
    $randomNumberGenerator = [Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $randomNumberGenerator.GetBytes($randomBytes)
    }
    finally {
        $randomNumberGenerator.Dispose()
    }
    $generatedPassword = [Convert]::ToBase64String($randomBytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
    [Array]::Clear($randomBytes, 0, $randomBytes.Length)
    $securePassword = ConvertTo-SecureString $generatedPassword -AsPlainText -Force
    $confirmation = ConvertTo-SecureString $generatedPassword -AsPlainText -Force
}
else {
    $securePassword = Read-Host "Contrasena nueva para la clave de firma" -AsSecureString
    $confirmation = Read-Host "Repite la contrasena" -AsSecureString
}
$passwordPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
$confirmationPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($confirmation)

try {
    $password = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPtr)
    $confirmationText = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($confirmationPtr)

    if ($password.Length -lt 12) {
        throw "La contrasena debe tener al menos 12 caracteres."
    }
    if ($password -cne $confirmationText) {
        throw "Las contrasenas no coinciden."
    }

    $env:NOTIUM_SIGNING_PASSWORD = $password
    & keytool -genkeypair -v `
        -keystore $keyStorePath `
        -storepass:env NOTIUM_SIGNING_PASSWORD `
        -keypass:env NOTIUM_SIGNING_PASSWORD `
        -alias upload `
        -keyalg RSA `
        -keysize 2048 `
        -validity 10000 `
        -dname $DistinguishedName

    if ($LASTEXITCODE -ne 0) {
        throw "keytool no pudo crear la clave de firma."
    }

    $lines = @(
        "storePassword=$password"
        "keyPassword=$password"
        "keyAlias=upload"
        "storeFile=../upload-keystore.jks"
    )
    [IO.File]::WriteAllLines($propertiesPath, $lines, [Text.UTF8Encoding]::new($false))

    Write-Host "Clave creada correctamente. Haz una copia segura de android/upload-keystore.jks y android/key.properties."
}
catch {
    if (Test-Path -LiteralPath $keyStorePath) {
        Remove-Item -LiteralPath $keyStorePath -Force
    }
    throw
}
finally {
    Remove-Item Env:NOTIUM_SIGNING_PASSWORD -ErrorAction SilentlyContinue
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPtr)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($confirmationPtr)
    $password = $null
    $confirmationText = $null
    $generatedPassword = $null
}

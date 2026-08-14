# Firma y compilacion del APK de Notium

## 1. Crear la clave una sola vez

Desde `app/` en PowerShell:

```powershell
.\scripts\create-signing-key.ps1
```

El script solicita una contrasena sin mostrarla y crea:

- `android/upload-keystore.jks`
- `android/key.properties`

Ambos estan ignorados por Git. Guarda una copia segura de los dos archivos y
de la contrasena: sin la misma clave no podras publicar actualizaciones sobre
una version ya instalada.

## 2. Compilar para el backend publico

```powershell
.\scripts\build-release.ps1 -ApiBaseUrl "https://api.notium.midominio.com/v1"
```

El script exige HTTPS, ejecuta analisis y pruebas, genera el APK firmado y
muestra su hash SHA-256. El resultado queda en:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## 3. Verificar la firma

```powershell
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```

## 4. Distribuir

Renombra una copia como `notium-v1.0.0.apk` y adjuntala a una version de
GitHub Releases. El mismo APK se puede cargar en Appetize para la demostracion
interactiva del portafolio.

No publiques `key.properties`, `upload-keystore.jks` ni la contrasena.

# Desplegar Notium desde el panel de Dokploy

Dokploy ya incluye Traefik para dominios y certificados HTTPS. Este despliegue
usa `docker-compose.dokploy.yml`, que contiene la landing, la API y PostgreSQL;
no se debe agregar Caddy ni publicar directamente los puertos 80, 443 o 3000.

## Antes de entrar al panel

1. Sube el proyecto completo a un repositorio Git.
2. Crea dos registros DNS `A`, `notium.midominio.com` y
   `api.notium.midominio.com`, apuntando a la IPv4 del VPS donde esta Dokploy.
3. Espera a que el DNS resuelva antes de solicitar el certificado.

## 1. Crear el servicio Compose

1. Entra a **Projects** y crea o abre el proyecto `Notium`.
2. Dentro del environment de produccion, selecciona **Create Service** y
   despues **Compose**.
3. Nombre: `notium-backend`.
4. Compose Type: **Docker Compose**, no Docker Stack.
5. En **General**, selecciona el proveedor Git/GitHub, repositorio y rama.
6. Compose Path: `./backend/docker-compose.dokploy.yml`.
7. Guarda la configuracion.

Si aparece la opcion **Isolated Deployments** en Advanced, dejala activada.

## 2. Variables de entorno

Abre la pestana **Environment** del Compose y pega:

```dotenv
POSTGRES_PASSWORD=VALOR_HEXADECIMAL_1
JWT_SECRET=VALOR_HEXADECIMAL_2
JWT_REFRESH_SECRET=VALOR_HEXADECIMAL_3
```

Cada valor debe ser diferente. Puedes generar los tres en una terminal Linux:

```bash
openssl rand -hex 48
openssl rand -hex 48
openssl rand -hex 48
```

No agregues `DATABASE_URL`: el Compose la construye internamente usando el
servicio privado `db`.

## 3. Dominios y HTTPS

1. Abre **Domains** dentro del servicio Compose.
2. Crea el dominio de la landing: host `notium.midominio.com`, path `/`,
   Service Name `frontend`, Container Port `3000`, HTTPS activado y certificado
   **Let's Encrypt**.
3. Crea el dominio de la API: host `api.notium.midominio.com`, path `/`,
   Service Name `api`, Container Port `3000`, HTTPS activado y certificado
   **Let's Encrypt**.
4. Guarda ambos dominios y vuelve a desplegar el Compose.

No agregues nada en Advanced -> Ports. El puerto 3000 debe permanecer interno
y Traefik se encargara de dirigir las solicitudes HTTPS al servicio `api`.

Los cambios de dominio de un Compose requieren un nuevo despliegue.

## 4. Desplegar y comprobar

1. Usa **Preview Compose** para confirmar que Dokploy agrego las etiquetas de
   Traefik a `frontend` y `api`, pero no al servicio `db`.
2. Pulsa **Deploy**.
3. En **Deployments** o **Logs**, espera estos mensajes de la API:

```text
Migrations complete!
API de Notium escuchando en http://localhost:3000/v1
```

4. Abre la landing y el health check:

```text
https://notium.midominio.com
https://api.notium.midominio.com/v1/health
```

La respuesta correcta contiene:

```json
{"estado":"ok","base_datos":"ok"}
```

## 5. Compilar el APK

Cuando el health check funcione, en el equipo de desarrollo:

```powershell
cd app
.\scripts\create-signing-key.ps1
.\scripts\build-release.ps1 -ApiBaseUrl "https://api.notium.midominio.com/v1"
```

La clave de firma se crea una sola vez. Conserva una copia segura de
`android/upload-keystore.jks`, `android/key.properties` y su contrasena.

## Persistencia y actualizaciones

- `pgdata` conserva PostgreSQL.
- `uploads` conserva los archivos adjuntos.
- Un redeploy normal no elimina estos volumenes.
- Nunca marques una opcion que elimine volumes al reconstruir el servicio.
- Para actualizar, sube los cambios a la rama configurada y pulsa **Redeploy**,
  o activa Auto Deploy si deseas despliegues automaticos.

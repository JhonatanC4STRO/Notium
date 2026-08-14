# Desplegar Notium en un VPS

Este flujo levanta PostgreSQL, la API y Caddy en una red privada de Docker.
Solamente los puertos 80/443 quedan publicos; Caddy obtiene y renueva el
certificado HTTPS automaticamente.

## Requisitos

- VPS Linux con Docker Engine y Docker Compose.
- Un subdominio, por ejemplo `api.notium.midominio.com`, apuntando a la IP del VPS.
- Puertos TCP 80 y 443 abiertos. Se recomienda habilitar tambien UDP 443 para HTTP/3.
- Acceso SSH con un usuario autorizado para ejecutar Docker.

## 1. Copiar el backend

Desde la raiz del proyecto local:

```bash
scp -r backend usuario@IP_DEL_VPS:/opt/notium
ssh usuario@IP_DEL_VPS
cd /opt/notium/backend
```

Si el proyecto esta en GitHub, es preferible clonarlo en el VPS y entrar a
`backend/`.

## 2. Crear los secretos

```bash
cp .env.production.example .env.production
openssl rand -hex 48
openssl rand -hex 48
openssl rand -hex 48
nano .env.production
```

Pega un resultado distinto en `POSTGRES_PASSWORD`, `JWT_SECRET` y
`JWT_REFRESH_SECRET`. Configura tambien `NOTIUM_DOMAIN` y `ACME_EMAIL`.

## 3. Validar y desplegar

```bash
docker compose --env-file .env.production -f docker-compose.prod.yml config
docker compose --env-file .env.production -f docker-compose.prod.yml up -d --build
docker compose --env-file .env.production -f docker-compose.prod.yml ps
docker compose --env-file .env.production -f docker-compose.prod.yml logs --tail=100 api caddy
```

Prueba publica:

```bash
curl https://api.notium.midominio.com/v1/health
```

Debe responder con `estado: ok` y `base_datos: ok`.

## 4. Operacion habitual

Actualizar:

```bash
git pull
docker compose --env-file .env.production -f docker-compose.prod.yml up -d --build
```

Ver registros:

```bash
docker compose --env-file .env.production -f docker-compose.prod.yml logs -f --tail=200
```

Crear un respaldo de PostgreSQL:

```bash
docker compose --env-file .env.production -f docker-compose.prod.yml exec -T db pg_dump -U postgres notium > notium-backup.sql
```

Los volumenes `pgdata`, `uploads`, `caddy_data` y `caddy_config` sobreviven a
las actualizaciones. No uses `docker compose down -v`, porque elimina los datos.

## 5. Compilar la app contra produccion

En el equipo de desarrollo:

```powershell
cd app
.\scripts\build-release.ps1 -ApiBaseUrl "https://api.notium.midominio.com/v1"
```

No compiles el APK antes de que `/v1/health` responda correctamente por HTTPS.

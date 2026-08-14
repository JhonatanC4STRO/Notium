# Despliegue en VPS — Backend de Notium

Guía de la tarea 1.6 del roadmap, adaptada a un VPS propio en lugar de un
PaaS. El despliegue es `docker compose` con dos servicios (API + PostgreSQL)
y un reverse proxy con TLS delante (HTTPS es obligatorio, sección 8 del doc).

## Requisitos en el VPS

- Docker Engine + plugin compose (`docker compose version`).
- Un dominio (o subdominio) apuntando a la IP del VPS — necesario para el
  certificado TLS automático. Ejemplo usado abajo: `api.midominio.com`.
- Puertos 80 y 443 abiertos en el firewall; **no** abrir el 3000 (la API
  solo escucha en loopback y el tráfico entra por el proxy).

```bash
# firewall típico con ufw
ufw allow 80/tcp
ufw allow 443/tcp
```

## 1. Copiar el proyecto

```bash
# opción git (recomendada)
git clone <url-del-repo> && cd <repo>/backend

# u opción scp desde tu máquina
scp -r backend usuario@VPS:/opt/notium && ssh usuario@VPS && cd /opt/notium
```

## 2. Configurar secretos

Crear `backend/.env` (NO subirlo a git; ya está en `.gitignore`):

```bash
cat > .env <<'EOF'
JWT_SECRET=<64 hex aleatorios>
JWT_REFRESH_SECRET=<otros 64 hex aleatorios>
POSTGRES_PASSWORD=<contraseña fuerte para PostgreSQL>
EOF
```

Generar valores: `openssl rand -hex 48` (una vez por secreto).

## 3. Levantar API + base de datos

```bash
docker compose up -d --build
docker compose logs -f api   # debe mostrar "Migrations complete!" y "API de Notium escuchando"
curl http://127.0.0.1:3000/v1/health   # → {"estado":"ok",...,"base_datos":"ok"}
```

Las migraciones se aplican solas en cada arranque (solo las pendientes).
Los datos y los binarios de adjuntos viven en los volúmenes `pgdata` y
`uploads`, que sobreviven a `docker compose down` y a los redeploys.

## 4. TLS con Caddy (reverse proxy)

Caddy obtiene y renueva el certificado de Let's Encrypt automáticamente.

```bash
# /opt/notium/Caddyfile
cat > Caddyfile <<'EOF'
api.midominio.com {
    reverse_proxy 127.0.0.1:3000
}
EOF

docker run -d --name caddy --restart unless-stopped --network host \
  -v /opt/notium/Caddyfile:/etc/caddy/Caddyfile \
  -v caddy_data:/data caddy:2
```

(Si prefieres nginx + certbot, el proxy debe apuntar a `127.0.0.1:3000`.)

## 5. Smoke test (flujo register → login → push → pull)

Contra `https://api.midominio.com/v1` (o desde Bruno/Postman con la colección
de `openapi.yaml`, tarea 0.5):

```bash
BASE=https://api.midominio.com/v1
UUID=$(cat /proc/sys/kernel/random/uuid)
NOTA=$(cat /proc/sys/kernel/random/uuid)

# 1. Registro → guarda access_token de la respuesta
curl -s $BASE/auth/register -H 'content-type: application/json' \
  -d "{\"uuid\":\"$UUID\",\"nombre\":\"Smoke\",\"email\":\"smoke-$UUID@test.com\",\"contrasena\":\"clave12345\"}"

TOKEN=<access_token de la respuesta>

# 2. Push de una nota
curl -s $BASE/sync/push -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' \
  -d "{\"device_id\":\"smoke-1\",\"operaciones\":[{\"uuid\":\"$NOTA\",\"entidad\":\"NOTA\",\"operacion\":\"CREATE\",\"payload\":{\"titulo\":\"Smoke\"},\"updated_at\":\"2026-07-12T10:00:00Z\",\"version\":1}]}"

# 3. Pull desde "otro dispositivo" → debe devolver la nota
curl -s "$BASE/sync/pull?desde=1970-01-01T00:00:00Z&device_id=smoke-2" \
  -H "authorization: Bearer $TOKEN"
```

Para el criterio de salida de la fase 1 (CU-05 completo), repetir desde
Bruno/Postman el escenario del test `tests/e2e-convergencia.test.js`: editar
la misma nota con dos `device_id` y verificar el `409` + convergencia.

## Operación

```bash
docker compose logs -f api        # logs
docker compose up -d --build      # redeploy tras un cambio
docker compose down               # detener (los volúmenes persisten)
docker compose exec db pg_dump -U postgres notium > respaldo.sql   # backup
```

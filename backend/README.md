1# Notium — Backend de sincronización

API REST de Notium (Node.js + Express + PostgreSQL). Implementa el contrato de
[`../doc/openapi.yaml`](../doc/openapi.yaml). Referencias: secciones 5.5 y 6.1–6.3
del documento de arquitectura ([`../doc/doc.md`](../doc/doc.md)).

## Estructura por capas

```text
src/
  routes/        → definición de rutas Express (URL → controller)
  controllers/   → adaptan HTTP (req/res) a la capa de servicios
  services/      → lógica de negocio (sync, auth, conflictos, idempotencia)
  db/            → pool de PostgreSQL y acceso a datos
  middlewares/   → manejo de errores (esquema Error de openapi.yaml), auth JWT (fase 1.2)
  config/        → carga y validación de variables de entorno
migrations/      → migraciones SQL versionadas (node-pg-migrate)
```

## Puesta en marcha

1. **Dependencias:**

   ```bash
   npm install
   ```

2. **Variables de entorno:** copiar `.env.example` a `.env` y completar
   `DATABASE_URL`, `JWT_SECRET`, `JWT_REFRESH_SECRET` y `PORT`.

3. **Base de datos:** crear la BD (por ejemplo `createdb notium`) y aplicar migraciones:

   ```bash
   npm run migrate
   ```

4. **Servidor:**

   ```bash
   npm run dev    # desarrollo (nodemon)
   npm start      # producción
   ```

5. **Verificación:** `GET http://localhost:3000/v1/health` debe responder
   `{"estado":"ok", ..., "base_datos":"ok"}` (o `503` si PostgreSQL no está disponible).

## Autenticación (tarea 1.2)

Endpoints bajo `/v1/auth` según `openapi.yaml`:

- `POST /auth/register` — acepta el `uuid` del cliente (UUID v4), valida unicidad
  de email (`409 EMAIL_DUPLICADO`), guarda la contraseña con **bcrypt** y devuelve
  `SesionResponse` (usuario + tokens).
- `POST /auth/login` — emite par access (15 min) + refresh (30 días).
- `POST /auth/refresh` — acepta un access token **expirado** en `Authorization`
  (valida solo la firma) y **rota** el refresh token: el usado queda revocado y
  se emite un par nuevo. Reusar un refresh rotado responde `401`.
- `POST /auth/logout` — revoca el refresh token en servidor (mitigación de robo,
  sección 9). Idempotente (`204`).

Detalles de implementación:

- Los refresh tokens se persisten como **hash SHA-256** en la tabla `refresh_token`
  (nunca en claro); el logout/rotación marca `revocado_en`.
- El middleware [`src/middlewares/auth.js`](src/middlewares/auth.js)
  (`requerirAutenticacion`) protege toda ruta que lo use y deja el usuario en
  `req.usuario.uuid` — las rutas de sync de la 1.3 lo reutilizan tal cual.
- Los tokens llevan un claim `tipo` (`access`/`refresh`) para que uno no pueda
  usarse en el rol del otro.

## Sincronización — `POST /sync/push` (tarea 1.3)

Implementa el contrato de la sección 5.5 en
[`src/services/sync.service.js`](src/services/sync.service.js):

- Cada operación se procesa en **su propia transacción SQL**; un item inválido
  produce `ERROR` en el resultado sin abortar el lote.
- **Control de acceso** por `usuario_uuid` (el dueño de un adjunto es el dueño
  de su nota).
- **Sin conflicto** (`version` cliente == servidor): se aplica, la versión
  autoritativa se incrementa (solo el servidor incrementa) → `ACCEPTED`.
- **Conflicto** (versiones distintas): Last-Write-Wins por `updated_at`.
  Gana el cliente → se aplica y el estado descartado del servidor queda en
  `historial_cambio` como `CONFLICTO_DESCARTADO`. Gana el servidor →
  `CONFLICT` + `version_servidor` + `payload_servidor`. Empate exacto de
  `updated_at` → gana el servidor (determinista).
- **Tombstones**: `DELETE` marca `is_deleted = true`, nunca borra físicamente.
- Respuesta `200` sin conflictos, `409` si al menos un item es `CONFLICT`;
  siempre el array completo en el mismo orden del lote.

**⚠️ Desviación documentada de la sección 6.3** (anotar en doc.md v1.5): la
clave de idempotencia es `(uuid, version, operacion, device_id)`, no
`(uuid, version)` a secas. La clave del doc colisiona: el UPDATE que parte de
la versión base 1 comparte `(uuid, 1)` con el CREATE que la produjo, y una
edición concurrente de otro dispositivo se confundiría con un reintento en
lugar de entrar al flujo LWW. Los resultados `ERROR` no se persisten en
`operacion_procesada`: la corrección del usuario puede llegar con la misma
clave y quedaría bloqueada.

## Sincronización — `GET /sync/pull` (tarea 1.4)

- Devuelve los cambios del usuario con `server_updated_at` **posterior a `desde`**
  (reloj del servidor; el `updated_at` del cliente solo sirve para LWW).
- **Anti-eco:** `device_id` opcional excluye los cambios originados por el
  propio dispositivo consultante.
- **Paginación:** `limite` (1–500, default 100) + `hay_mas`. Se consulta
  `limite + 1` para detectar si quedan páginas sin una consulta extra.
- **Tombstones incluidos** (`is_deleted = true`, `payload = {}`).
- `timestamp_servidor` es el **cursor** de la siguiente consulta: el
  `server_updated_at` del último cambio devuelto, serializado en SQL con
  precisión de **microsegundos** (convertirlo a `Date` de JS lo truncaría a
  milisegundos y el último cambio se re-entregaría en la página siguiente).
  Sin cambios, se devuelve el mismo `desde` para no retroceder el cursor.
- La `operacion` de cada cambio se deriva del estado autoritativo:
  `is_deleted` → `DELETE`, `version = 1` → `CREATE`, resto → `UPDATE`.

## Adjuntos e historial (tarea 1.5)

- `POST /attachments` (multipart) — el binario viaja **fuera** del lote de
  sincronización. Límite **10 MB** → `413` (RNF-05). Idempotencia por
  contenido: reintento con el mismo binario (hash SHA-256 igual) → `201`;
  mismo `uuid` con contenido distinto → `409`. Tolera ambos órdenes: metadatos
  primero por push y luego el binario (flujo normal de la fase 3.5), o el
  binario primero (crea el registro de metadatos).
- `GET /attachments/{uuid}` — entrega el binario (`application/octet-stream`);
  `404` si no existe/no es del usuario/sin binario aún, `410` si es tombstone.
- `DELETE /attachments/{uuid}` — soft delete: marca `is_deleted`, incrementa
  `version` y toca `server_updated_at`, de modo que la eliminación **se
  propaga por `/sync/pull`** a los demás dispositivos. Idempotente.
- `GET /history/{nota_uuid}` (RF-05) — historial de auditoría en orden
  descendente, incluidas las entradas `CONFLICTO_DESCARTADO` con el
  dispositivo y el valor que no se aplicó.
- Los binarios se guardan en `uploads/<uuid>` (configurable con `UPLOADS_DIR`);
  en la BD solo metadatos (`contenido_sha256`, `tamano_bytes`, `mime_type`).
  `url_remota` es una URI relativa (`/v1/attachments/<uuid>`) que el cliente
  resuelve contra su `baseUrl`.

## Tests

```bash
npm test
```

Suite de integración (Jest + Supertest) contra la BD de desarrollo — requiere
PostgreSQL corriendo.

- [`tests/sync-push.test.js`](tests/sync-push.test.js) — los 7 pasos de la
  tarea 1.3: validación/acceso, idempotencia, camino sin conflicto, LWW en
  ambos sentidos, tombstone, códigos 200/409 y adjuntos.
- [`tests/sync-pull.test.js`](tests/sync-pull.test.js) — tarea 1.4: corte por
  `desde`, anti-eco por `device_id`, tombstones, aislamiento entre usuarios,
  paginación con `limite`/`hay_mas` y avance del cursor sin pérdidas ni
  repetidos.
- [`tests/attachments-history.test.js`](tests/attachments-history.test.js) —
  tarea 1.5: subida/descarga byte a byte, límite de 10 MB (413), idempotencia
  por contenido (201/409), control de acceso (404), soft delete (204/410) con
  propagación del tombstone por pull, e historial RF-05 con conflictos
  descartados.
- [`tests/contract-openapi.test.js`](tests/contract-openapi.test.js) — tarea
  1.6: toda respuesta de la API validada contra `doc/openapi.yaml` con
  `express-openapi-validator` (OpenAPI 3.1).
- [`tests/e2e-convergencia.test.js`](tests/e2e-convergencia.test.js) — tarea
  1.6: el flujo literal de CU-05 (dos dispositivos, conflicto LWW,
  convergencia y auditoría) y la propagación de tombstones de CU-06.

## Despliegue

Ver [DEPLOY.md](DEPLOY.md): `docker compose` (API + PostgreSQL) en un VPS,
con las migraciones aplicándose solas en el arranque y Caddy como reverse
proxy TLS delante. Los datos viven en los volúmenes `pgdata` y `uploads`.

## Esquema (migración inicial)

- `usuario`, `nota`, `adjunto`, `historial_cambio` — replican la sección 4.1 con los
  metadatos de sincronización de la 4.2. `sync_status` **no** se persiste en el
  servidor (es metadato local del cliente, según openapi.yaml).
- `operacion_procesada (uuid, version, resultado, procesada_en)` — clave de
  idempotencia `(uuid, version)` de `POST /sync/push` (sección 6.3), con PK única.
- `nota.server_updated_at` / `adjunto.server_updated_at` — marca temporal del
  servidor para el corte `desde` de `GET /sync/pull` (tarea 1.4 del roadmap);
  `updated_at` es del reloj del cliente y solo se usa para Last-Write-Wins.

## Comandos de migración

```bash
npm run migrate                      # aplicar pendientes (up)
npm run migrate:down                 # revertir la última
npm run migrate:create -- nombre     # crear una nueva migración SQL
```

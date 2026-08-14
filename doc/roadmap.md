# Roadmap de Construcción — Notium

**Proyecto:** Notium — Plataforma offline-first
**Basado en:** Propuesta de Arquitectura v1.4 (`doc.md`), Casos de Uso (`casos-de-uso.md`) y contrato `openapi.yaml`
**Autor:** Jhonatan Castro
**Fecha:** 11 de julio de 2026
**Equipo:** 1 desarrollador

## Estrategia general

Se construye **el backend primero** y el cliente después. Razones:

1. El contrato ya está formalizado en `openapi.yaml`: el backend es la implementación directa de ese contrato, sin decisiones abiertas.
2. El cliente Flutter necesita un servidor real contra el cual probar la sincronización; construirlo primero evita mocks desechables.
3. La lógica más delicada del sistema (idempotencia, LWW, tombstones) vive en el servidor; validarla temprano reduce el riesgo de las fases posteriores.

Dentro del cliente, el orden es **offline primero**: el CRUD local completo debe funcionar sin ninguna referencia a la red antes de escribir una sola línea de sincronización. Esto refleja el principio de Single Source of Truth (sección 3.1) y permite validar RNF-01 y RNF-03 de forma aislada.

Cada fase termina con un **hito verificable**. No avances de fase sin cumplir el criterio de salida.

---

## Fase 0 — Preparación del entorno (1–2 días)

| # | Tarea | Detalle |
|---|-------|---------|
| 0.1 | Instalar toolchain cliente | Flutter SDK (stable). **Editor: VS Code** con las extensiones oficiales *Flutter* y *Dart* (Android Studio ya instalado se usa solo como proveedor del SDK Android API 24+ y del emulador; no se codifica en él). Emulador creado desde Android Studio o dispositivo físico por USB con depuración activada. Verificar con `flutter doctor` sin errores. |
| 0.2 | Instalar toolchain backend | Node.js LTS, PostgreSQL local (recomendado: Docker con `docker compose` para reproducibilidad). |
| 0.3 | Crear repositorios | Un repo `notium-app` (Flutter) y un repo `notium-api` (Node), o monorepo con carpetas `app/` y `api/`. Incluir `.gitignore` y esta documentación en `doc/`. |
| 0.4 | Cuentas de servicio | Cuenta en el PaaS elegido (Render, Railway o Fly.io — sección 6.2) con PostgreSQL en capa gratuita. Solo crear la cuenta; el deploy es la tarea 1.8. |
| 0.5 | Herramienta de pruebas de API | Instalar Bruno/Insomnia/Postman e importar `openapi.yaml` como colección. |

**Criterio de salida:** `flutter doctor` limpio, `node --version` y PostgreSQL respondiendo, repos creados.

---

## Fase 1 — Backend: autoridad de sincronización (2–3 semanas)

Implementa `openapi.yaml` tal cual. Referencias: secciones 5.5, 6.1–6.3 del doc de arquitectura.

### 1.1 Scaffolding y base de datos (2–3 días)

- Proyecto Express con estructura por capas: `routes/ → controllers/ → services/ → db/`.
- Variables de entorno con `dotenv` (`DATABASE_URL`, `JWT_SECRET`, `JWT_REFRESH_SECRET`, `PORT`).
- Esquema PostgreSQL con migraciones SQL versionadas (por ejemplo `node-pg-migrate`): tablas `usuario`, `nota`, `adjunto`, `historial_cambio` (replican la sección 4.1 con los metadatos de 4.2) y `operacion_procesada` (`uuid`, `version`, `resultado`, `procesada_en` — sección 6.3, con índice único en `(uuid, version)`).
- Endpoint `GET /health` verificando la conexión a PostgreSQL.

### 1.2 Autenticación (3–4 días)

- `POST /auth/register`: acepta el `uuid` generado por el cliente, valida unicidad de email (409), hash bcrypt, devuelve `SesionResponse` (CU-01).
- `POST /auth/login`: emite par access + refresh.
- `POST /auth/refresh`: acepta access token expirado en el header (valida solo firma), rota el access token (CU-03).
- `POST /auth/logout`: invalida el refresh token en servidor (mitigación de robo, sección 9). Requiere persistir refresh tokens o su hash.
- Middleware de autenticación JWT para todas las rutas protegidas.

### 1.3 `POST /sync/push` — el corazón del sistema (4–5 días)

Implementar en este orden, con tests unitarios por paso:

1. **Validación y control de acceso:** cada operación pertenece al usuario autenticado (`usuario_uuid`, sección 8). Rechazo individual → `ERROR` en el resultado, sin abortar el lote.
2. **Idempotencia:** antes de aplicar, buscar `(uuid, version)` en `operacion_procesada`; si existe, devolver el resultado original sin re-aplicar (sección 6.3).
3. **Camino sin conflicto:** `version` enviada == `version` del servidor → aplicar, incrementar versión autoritativa, registrar en `historial_cambio` y en `operacion_procesada` → `ACCEPTED`.
4. **Conflicto (LWW):** versiones difieren → comparar `updated_at` (sección 5.3). Gana cliente → aplicar + versión del servidor al historial como `CONFLICTO_DESCARTADO` → `ACCEPTED`. Gana servidor → `CONFLICT` + `version_servidor` + `payload_servidor`.
5. **Tombstones:** `DELETE` marca `is_deleted = true`, nunca borra físicamente (sección 5.4).
6. **Código de respuesta:** `200` sin conflictos, `409` si al menos un item es `CONFLICT`; siempre array completo en el mismo orden.
7. Todo el procesamiento de una operación dentro de una **transacción** SQL.

### 1.4 `GET /sync/pull` (2 días)

- Cambios del usuario posteriores a `desde`, excluyendo los del `device_id` consultante (anti-eco), con paginación (`limite`, `hay_mas`) y `timestamp_servidor` en la respuesta.
- Incluir tombstones. Requiere una columna de marca temporal del servidor (no `updated_at` del cliente) para el corte de `desde`.

### 1.5 Adjuntos e historial (2–3 días)

- `POST /attachments` (multipart): límite 10 MB → `413` (CU-08); duplicado con contenido distinto → `409`; guarda binario en disco/objeto del PaaS y devuelve `url_remota`.
- `GET /attachments/{uuid}`, `DELETE /attachments/{uuid}` (soft delete, `410` si tombstone).
- `GET /history/{nota_uuid}` (RF-05).

### 1.6 Pruebas y despliegue (2–3 días)

- Suite de integración (Jest + Supertest) cubriendo: idempotencia por reenvío del mismo lote, conflicto LWW en ambos sentidos, tombstone, lote mixto con item inválido. Usar los escenarios de CU-05, CU-06, CU-07 y CU-08 como casos de prueba.
- Validar respuestas contra `openapi.yaml` (por ejemplo con `jest-openapi` o `express-openapi-validator`).
- Deploy al PaaS con PostgreSQL gestionado; smoke test de `/health` y flujo register→login→push→pull desde la colección de API.

**Criterio de salida:** todos los endpoints del `openapi.yaml` desplegados y verdes en la suite de integración; puedes ejecutar el flujo completo de CU-05 (conflicto) con dos `device_id` distintos desde Bruno/Postman.

---

## Fase 2 — Cliente Flutter: CRUD 100% offline (2–3 semanas)

Sin red en toda esta fase. Referencias: secciones 3.1, 3.3, 4, 5.1, 5.2.

### 2.1 Proyecto y arquitectura (1–2 días)

- `flutter create` con `minSdkVersion 24`. Estructura por capas: `presentation/` (widgets + notifiers), `data/` (repository, drift, dio), `domain/` (modelos).
- Dependencias iniciales: `flutter_riverpod`, `drift`, `sqlcipher_flutter_libs` + soporte SQLCipher para Drift, `uuid`, `flutter_secure_storage`.
- Configurar `build_runner` para la generación de código de Drift.

### 2.2 Base de datos local (3–4 días)

- Tablas Drift para `NOTA`, `ADJUNTO`, `HISTORIAL_CAMBIO` y caché de `USUARIO`, con los metadatos de la sección 4.2 (`sync_status` como enum Dart).
- Cifrado SQLCipher desde el día uno (clave gestionada vía `flutter_secure_storage`) — retrofitearlo después es doloroso.
- Migraciones versionadas de Drift configuradas aunque solo exista la v1.

### 2.3 Repository y CRUD local (3–4 días)

- `NotaRepository`: crear (UUID v4 + `version = 1` + `sync_status = PENDING` + `updated_at`), editar (→ `PENDING`), eliminar (soft delete, CU-06 fase 1). Todo en transacciones Drift.
- Registro en `HISTORIAL_CAMBIO` con `origen_cambio = LOCAL` en la misma transacción.
- Streams de Drift (`watch`) expuestos como `Stream<List<Nota>>`, filtrando `is_deleted = true`.
- Adjuntos: copia del archivo a almacenamiento de la app, validación de 10 MB **antes** de persistir (CU-08), relación por `nota_uuid`.
- Tests unitarios del repository con Drift en memoria (sin emulador).

### 2.4 UI de notas (4–5 días)

- Providers Riverpod: `StreamProvider` para la lista, `Notifier` para acciones.
- Pantallas: lista de notas, editor (crear/editar), adjuntar archivo, eliminar con confirmación.
- **Indicador de estado de sincronización por registro (RF-04):** icono/color según `PENDING / SYNCED / CONFLICT / ERROR`. Hazlo ahora aunque todo sea `PENDING`; es un requisito, no un adorno.
- Verificar RNF-03: el cambio es visible < 100 ms tras guardar.
- Validar CU-04 completo: crear nota + adjunto en modo avión, matar la app, reabrir → todo íntegro.

**Criterio de salida:** la app funciona indefinidamente en modo avión; CU-04 pasa manualmente; tests del repository verdes; la BD es ilegible sin la clave (verificar con un explorador de SQLite).

---

## Fase 3 — Autenticación y sincronización (3–4 semanas)

La fase de mayor riesgo técnico. Referencias: secciones 3.4b, 5.2–5.5, 8; CU-01, CU-02, CU-03, CU-05, CU-06, CU-07.

### 3.1 Capa HTTP y autenticación (4–5 días)

- Cliente Dio con `baseUrl` por entorno (`--dart-define`), timeout y logging.
- **Interceptor de refresh:** captura 401 → lee refresh token → `POST /auth/refresh` → guarda nuevo token → reintenta la petición original (CU-03). Cuidado con la reentrada: un solo refresh en vuelo a la vez.
- Pantallas de registro y login (CU-01, CU-02 con red).
- **Login offline** (CU-02 sin red): validación local de expiración del token cacheado; sesión degradada si expiró dentro de la ventana extendida; primer login siempre requiere red.

### 3.2 Push (5–6 días)

- Servicio `SyncService.push()` puro Dart, independiente de `workmanager` (así se prueba unitariamente): consulta `PENDING`, arma el lote según `SyncPushRequest` (con `device_id` a nivel de lote), envía, procesa el array de resultados:
  - `ACCEPTED` → `sync_status = SYNCED`, adoptar `version_servidor`.
  - `CONFLICT` → transacción única: insertar `HISTORIAL_CAMBIO` con `CONFLICTO_DESCARTADO` + sobrescribir con `payload_servidor` + `SYNCED` (CU-05 fase 3).
  - `ERROR` → `sync_status = ERROR`, sin reintento automático (sección 5.2).
- Fallo de red a mitad de lote: nada cambia de estado, los registros siguen `PENDING` (CU-07).
- `device_id` estable generado una vez y persistido.

### 3.3 Pull (3–4 días)

- `SyncService.pull()`: `GET /sync/pull?desde=<último timestamp_servidor persistido>&device_id=...`, paginando mientras `hay_mas`.
- Aplicar cambios remotos en transacción con `origen_cambio = REMOTO`; respetar tombstones remotos (borrar de la vista, conservar como tombstone local hasta purga).
- Persistir el nuevo `timestamp_servidor` **solo** tras aplicar la página completa.
- Regla local: si un registro está `PENDING` localmente y llega un cambio remoto para el mismo `uuid`, no lo pises — el push posterior resolverá el conflicto en el servidor.

### 3.4 Orquestación en segundo plano (4–5 días)

- Integrar `workmanager`: tarea periódica + disparo con restricción de red (`NetworkType.connected`); el callback ejecuta `push()` y luego `pull()`.
- `connectivity_plus` para disparar un sync inmediato en foreground al recuperar red.
- Backoff exponencial delegado a `workmanager` (CU-07): ante excepción de red, la tarea termina pidiendo reintento.
- Refresh de token dentro del ciclo de sync (CU-03): si el refresh también falla, los registros quedan `PENDING` y se marca la sesión para reautenticación.

### 3.5 Adjuntos y purga (3–4 días)

- Subida del binario a `POST /attachments` tras aceptarse los metadatos; guardar `url_remota`; `413` → `ERROR` (CU-08).
- Descarga de adjuntos remotos bajo demanda.
- Job de limpieza: purga física de tombstones `SYNCED` confirmados/vencidos de ventana de gracia, con borrado en cascada de adjuntos (CU-06 fase 3, RNF-05).

### 3.6 Prueba de convergencia end-to-end (2–3 días)

- Con dos emuladores (o emulador + dispositivo) contra el backend desplegado, ejecutar CU-05 literalmente: editar la misma nota offline en ambos, reconectar en orden, verificar convergencia y entrada `CONFLICTO_DESCARTADO` en el historial del perdedor.
- Verificar RNF-06: pendientes sincronizados < 30 s tras recuperar red.

**Criterio de salida:** CU-01 a CU-08 pasan manualmente de punta a punta; dos dispositivos convergen (RNF-02); ningún escenario de red intermitente duplica ni pierde datos.

---

## Fase 4 — Endurecimiento y calidad (1–2 semanas)

| # | Tarea | Referencia |
|---|-------|-----------|
| 4.1 | Pantalla de historial por nota (consume `HISTORIAL_CAMBIO` local + `GET /history/{nota_uuid}`), mostrando cambios descartados | RF-05 |
| 4.2 | UX de errores: registros en `ERROR` con acción de corregir/eliminar; aviso al acercarse a 500 MB de BD | RF-04, RNF-05, CU-08 |
| 4.3 | Suite automatizada: unit (repository, `SyncService` con Dio mockeado), widget tests de lista/editor, y un test de integración del ciclo push/pull contra backend local | CU-01–CU-08 |
| 4.4 | Revisión de seguridad: sin secretos hardcodeados (`--dart-define`), HTTPS forzado, logout remoto invalida refresh | Sección 8 |
| 4.5 | Medición de RNF: escritura < 100 ms, convergencia (RNF-06), tamaño de BD bajo uso prolongado | Sección 2.2 |

**Criterio de salida:** suite verde en CI (GitHub Actions: `flutter test` + tests del backend), checklist de seguridad de la sección 8 revisado punto por punto.

---

## Fase 5 — Entrega (3–5 días)

1. APK firmado en modo release (`flutter build apk --release`) probado en dispositivo físico con red móvil real e intermitente.
2. README de cada repo: setup, variables de entorno, cómo correr tests, cómo desplegar.
3. Actualizar `doc.md` a v1.5 con cualquier desviación entre lo diseñado y lo construido (el changelog ya tiene el formato).
4. Regenerar los PDF de la documentación.
5. Demo preparada: guion basado en CU-04 (offline total) y CU-05 (conflicto entre dos dispositivos) — son los dos casos que mejor demuestran el valor de la arquitectura.

---

## Resumen de tiempos

| Fase | Duración estimada | Acumulado |
|------|-------------------|-----------|
| 0 — Entorno | 1–2 días | ~2 días |
| 1 — Backend | 2–3 semanas | ~3.5 semanas |
| 2 — Cliente offline | 2–3 semanas | ~6.5 semanas |
| 3 — Sincronización | 3–4 semanas | ~10.5 semanas |
| 4 — Endurecimiento | 1–2 semanas | ~12.5 semanas |
| 5 — Entrega | 3–5 días | **~13 semanas** |

Estimaciones para un desarrollador con dedicación parcial, aprendiendo el stack sobre la marcha. Con dedicación completa y experiencia previa en Flutter/Node, puede comprimirse a 7–9 semanas.

## Riesgos de ejecución a vigilar

- **Fase 3 es la crítica:** si el CRUD offline (fase 2) no está sólido y probado, los bugs de sincronización serán indistinguibles de bugs de persistencia. No mezclar las fases.
- **`workmanager` en Android:** los fabricantes agresivos con batería (Xiaomi, Huawei) matan tareas en segundo plano; probar en hardware real temprano, no solo en emulador.
- **Relojes desincronizados** (riesgo conocido de LWW, sección 9): no intentar resolverlo ahora; el historial de auditoría es la mitigación aceptada.
- **Scope creep:** iOS, web y features de notas avanzadas están explícitamente fuera del alcance (sección 2.3). El roadmap termina con un APK Android que sincroniza correctamente.

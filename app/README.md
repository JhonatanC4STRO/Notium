# Notium — App Flutter (Android)

Cliente offline-first de Notium (fase 2 del roadmap). La UI consume
únicamente la base de datos local (Single Source of Truth, sección 3.1 del
doc de arquitectura); la red llega en la fase 3.

## Estructura por capas (tarea 2.1)

```text
lib/
  presentation/   → widgets + notifiers Riverpod (UI, tarea 2.4)
  data/
    db/           → Drift: tablas, base de datos cifrada, clave SQLCipher
    (repositorios/ y red llegan en 2.3 y fase 3)
  domain/         → enums del modelo (SyncStatus, OrigenCambio, Operacion)
drift_schemas/    → esquemas exportados por versión (migraciones verificables)
```

- `minSdkVersion 24` fijado en `android/app/build.gradle.kts`.
- Riverpod (`ProviderScope` en `main.dart`) como estado/DI (ADR-01).

## Base de datos local (tarea 2.2)

- Tablas Drift en [`lib/data/db/tablas.dart`](lib/data/db/tablas.dart):
  `Notas`, `Adjuntos`, `HistorialCambios` y caché de `Usuarios`, con los
  metadatos de sincronización de la sección 4.2 en un mixin común
  (`syncStatus` como enum Dart persistido por nombre, `isDeleted`, `version`,
  `deviceId`, fechas).
- Los nombres de los enums están en MAYÚSCULAS a propósito: deben coincidir
  con los valores del contrato `openapi.yaml`.

### Cifrado (SQLCipher desde el día uno)

- **Ojo, cambio respecto al doc de arquitectura** (anotar en doc.md v1.5):
  `sqlcipher_flutter_libs` quedó obsoleto — Zetetic descontinuó SQLCipher
  Community Edition y con `sqlite3` v3 el paquete es un no-op. El cifrado
  ahora se configura en `pubspec.yaml`:

  ```yaml
  hooks:
    user_defines:
      sqlite3:
        source: sqlcipher
  ```

  Con eso la librería nativa que compila el build ES SQLCipher.
- La clave (32 bytes aleatorios, formato hex crudo `x'…'`) se genera una vez
  y vive en `flutter_secure_storage` / Android Keystore
  ([`clave_cifrado.dart`](lib/data/db/clave_cifrado.dart)).
- Al abrir, se aplica `PRAGMA key` antes que nada y se verifica
  `PRAGMA cipher_version`: si la librería no fuese SQLCipher, la app falla
  ruidosamente en vez de escribir una BD sin cifrar.

### Generación de código y migraciones

```bash
dart run build_runner build                 # regenerar código Drift
dart run build_runner watch                 # en desarrollo

# Al cambiar el esquema: subir schemaVersion en app_database.dart y exportar
dart run drift_dev schema dump lib/data/db/app_database.dart drift_schemas/
```

`drift_schemas/drift_schema_v1.json` es la referencia de la v1; las
migraciones futuras se escriben en `MigrationStrategy.onUpgrade` y se
verifican contra estos volcados.

**Nota de versiones:** `drift` y `drift_dev` están fijados en `2.34.0` exacto:
`drift 2.34.1` rompe el comando `schema dump` de `drift_dev 2.34.0`, y
`drift_dev 2.34.3` exige un `analyzer` incompatible con el `flutter_test` del
SDK actual. Revisar al actualizar Flutter.

## Repositorios y CRUD local (tarea 2.3)

- [`nota_repository.dart`](lib/data/repositorios/nota_repository.dart) —
  crear (UUID v4 + `version 1` + `PENDING`), editar (→ `PENDING`, `version`
  intacta: solo el servidor la incrementa), eliminar (soft delete, CU-06
  fase 1). Cada escritura registra `HISTORIAL_CAMBIO` con `origen = LOCAL`
  en **la misma transacción** Drift. `watchNotas()` expone
  `Stream<List<Nota>>` filtrando tombstones y otros usuarios.
- [`adjunto_repository.dart`](lib/data/repositorios/adjunto_repository.dart) —
  copia el archivo al almacén de la app (el directorio se inyecta;
  la UI lo cablea con `path_provider`), valida los **10 MB ANTES de copiar o
  persistir** (CU-08: un rechazo no deja rastro), y hace soft delete
  conservando el binario hasta la purga (fase 3.5).
- Fechas como **texto ISO-8601 UTC** (`build.yaml`:
  `store_date_time_values_as_text`): `updated_at` es la base del LWW entre
  dispositivos y no puede depender de la zona horaria del teléfono.
- Tests con Drift en memoria (sin emulador): `test/repositorios/`.

## UI de notas (tarea 2.4)

- [`providers.dart`](lib/presentation/providers.dart) — `StreamProvider` para
  la lista/adjuntos (la UI se repinta sola con cada escritura, RNF-03) y el
  `Notifier` `AccionesNotas` para todas las escrituras; la UI nunca toca los
  repositorios directamente. En la fase 2 el dueño de los datos es la
  identidad local fija `usuario-local` (la fase 3.1 la reemplaza por el
  usuario autenticado).
- Pantallas: lista con estado vacío, editor crear/editar, sección de
  adjuntos con `file_picker` (el rechazo de 10 MB se avisa con SnackBar,
  CU-08) y eliminación con diálogo de confirmación.
- [`indicador_sync.dart`](lib/presentation/widgets/indicador_sync.dart) —
  **RF-04**: icono/color/tooltip por registro según
  `PENDING / SYNCED / CONFLICT / ERROR`. En la fase 2 todo estará en
  `PENDING`; los demás estados se activan con la sincronización.
- Widget tests en `test/widget_test.dart` (BD en memoria): crear → lista con
  indicador, título obligatorio, editar, eliminar con Cancelar/Confirmar.
  Nota técnica: cada test desmonta el árbol con un `pump` CON duración al
  final — los streams de drift agendan un timer de cierre que de otro modo
  queda pendiente y el framework lo marca como error.

## Capa HTTP y autenticación (tarea 3.1)

- **Dio por entorno** ([`api_cliente.dart`](lib/data/red/api_cliente.dart)):
  `--dart-define=API_BASE_URL=...`; el default `http://10.0.2.2:3000/v1`
  apunta al backend local visto desde el emulador Android. Timeouts y
  logging solo en debug (sin cuerpos: llevan credenciales/payloads).
- **Interceptor de refresh**
  ([`auth_interceptor.dart`](lib/data/red/auth_interceptor.dart), CU-03):
  401 → refresh → reintento transparente. La reentrada se resuelve con
  `QueuedInterceptor` (serializa handlers → un solo refresh en vuelo) +
  comparación de token (si otro handler ya refrescó, se reintenta sin
  refrescar de nuevo) — crítico porque el backend ROTA el refresh token y
  un doble refresh quemaría la sesión. Refresh definitivamente inválido →
  limpia sesión y la raíz vuelve al login.
- **Sesión local** ([`sesion.dart`](lib/domain/sesion.dart)): los tokens van
  SOLO a `flutter_secure_storage`. Validación local de expiración (CU-02 sin
  red): `activa` → uso normal; expirada < 7 días (`ventanaSesionDegradada`)
  → `degradada`: uso offline con aviso "Sesión por renovar"; más allá →
  `expirada`: reautenticación con red. El primer login siempre exige red.
- **Pantallas** login/registro (CU-01/CU-02): el uuid del usuario se genera
  en el cliente; al iniciar sesión, las notas creadas sin cuenta
  (`usuario-local`, fase 2) se adoptan por el usuario autenticado.
- Tests sin red: interceptor contra un adaptador HTTP falso que simula la
  rotación de tokens del backend (`test/red/`), repository y estados de
  sesión (`test/auth/`), y arranque con/sin sesión (`test/widget_test.dart`).

Para probar contra el backend real desde el emulador: `docker compose up`
en `backend/` y `flutter run` (el default ya apunta a `10.0.2.2:3000`).

## Sincronización — push (tarea 3.2)

- [`sync_service.dart`](lib/data/sync/sync_service.dart) — `SyncService.push()`
  puro Dart (independiente de `workmanager`, la orquestación es la 3.4):
  recolecta los `PENDING`, arma el lote `SyncPushRequest` (`device_id` a nivel
  de lote) y procesa el array de resultados:
  - `ACCEPTED` → `SYNCED` + adopta `version_servidor` + `sincronizado = true`.
  - `CONFLICT` (CU-05 fase 3) → en **una transacción**: `HISTORIAL_CAMBIO`
    con `CONFLICTO_DESCARTADO` + sobrescribe con `payload_servidor` + `SYNCED`.
  - `ERROR` → `ERROR`, sin reintento automático (sección 5.2).
  - **Fallo de red** (CU-07): el estado local no se toca; todo sigue `PENDING`.
- **CREATE vs UPDATE**: se decide con la columna nueva `sincronizado`
  (migración v2) — un registro `version = 1` puede ser una creación nunca
  sincronizada o una edición ya sincronizada, así que `version` sola no basta.
- **`device_id` estable** ([`identidad_dispositivo.dart`](lib/data/sync/identidad_dispositivo.dart)):
  se genera una vez y se persiste en el almacén seguro.
- Tombstones que nunca se sincronizaron se cierran localmente sin tocar la red.
- Tests sin red con una `SyncApi` falsa: `test/sync/sync_push_test.dart`
  (ACCEPTED/CONFLICT/ERROR, CU-07, CREATE→UPDATE, tombstone local, orden del lote).
- Test con `SyncApi` real sobre Dio mockeado por `HttpClientAdapter`:
  `test/sync/sync_service_dio_test.dart` valida el JSON de `/sync/push`, el
  `409` con conflicto, la query de `/sync/pull` y el fallo de red sin backend.

## Sincronización — pull (tarea 3.3)

- `SyncService.pull(usuarioUuid)` — `GET /sync/pull?desde=<cursor>&device_id=…`
  paginando mientras `hay_mas`. Aplica cada cambio remoto con
  `origen_cambio = REMOTO`, respetando tombstones (marca `is_deleted`, no borra).
- **Cursor atómico**: el `timestamp_servidor` de cada página se guarda en la
  tabla `sync_meta` (migración v3) DENTRO de la misma transacción que aplica la
  página — el cursor solo avanza si la página se aplicó. Si la red falla entre
  páginas, las ya aplicadas quedan firmes y el próximo pull retoma desde ahí.
- **Regla local**: si un registro está `PENDING` (cambio local sin sincronizar)
  y llega un cambio remoto para el mismo `uuid`, NO se pisa — el push posterior
  lo envía y el servidor resuelve el conflicto por LWW.
- Tests sin red: `test/sync/sync_pull_test.dart` (aplicar remoto, tombstone
  oculto de la vista, no-pisar-PENDING, paginación con avance de cursor, CU-07).

## Orquestación en segundo plano (tarea 3.4)

- [`sync_coordinator.dart`](lib/data/sync/sync_coordinator.dart) —
  `SyncCoordinator` ejecuta **push → pull** y traduce el resultado a un
  `DesenlaceSync` (`ok` / `sinRed` / `sesionExpirada` / `error`). Es agnóstico
  de plataforma/Riverpod/workmanager: lo usan tanto el foreground como el
  isolate de fondo, y es la pieza cubierta por tests.
- [`sync_background.dart`](lib/data/sync/sync_background.dart) — integración de
  **workmanager**: `callbackDispatcher` (`@pragma('vm:entry-point')`) corre en
  un isolate separado que arma las dependencias a mano (sin Riverpod). Tarea
  periódica cada 15 min con `NetworkType.connected` y **backoff exponencial**;
  al fallar la red devuelve `false` para que workmanager reintente (CU-07).
- [`sync_manager.dart`](lib/data/sync/sync_manager.dart) — foreground:
  `connectivity_plus` dispara un sync inmediato al **recuperar la red**; se
  registra la tarea periódica al iniciar sesión y se cancela al cerrarla.
- **Refresh en el ciclo (CU-03)**: el interceptor refresca el token dentro del
  sync; si el refresh falla, el ciclo termina en `sesionExpirada`, los
  registros siguen `PENDING` y la sesión se limpia → la raíz vuelve al login.
- `main()` llama `inicializarWorkmanager()`; `_Raiz` arranca/detiene el
  `SyncManager` según la sesión (guardado por `syncEnSegundoPlanoProvider`,
  que los widget tests ponen en `false` para no invocar plugins).
- **Limitación conocida**: el isolate de fondo abre su propia instancia de la
  BD cifrada; si coincidiera con un sync en foreground podrían competir. En la
  práctica (periódica ~15 min) rara vez se solapan. Una solución robusta
  usaría un isolate de drift compartido (fuera del alcance de esta fase).
- Test del coordinador: `test/sync/sync_coordinator_test.dart`.

## Adjuntos remotos y purga (tarea 3.5)

- [`attachment_service.dart`](lib/data/sync/attachment_service.dart) —
  **subida del binario** a `POST /attachments` tras aceptarse los metadatos
  por sync (el ciclo es push → **subir binarios** → pull → purga). Sube los
  adjuntos `sincronizado`, con archivo local y sin `url_remota`; guarda la
  `url_remota` que devuelve el servidor. Un `413` marca el adjunto en `ERROR`
  sin reintento (CU-08); un fallo de red detiene la pasada (se reintenta).
- **Descarga bajo demanda** (`descargar(uuid)`): si no hay copia local, trae
  el binario, lo guarda y persiste `ruta_local`; si ya existe, no va a la red.
- [`purga_service.dart`](lib/data/sync/purga_service.dart) — **purga física**
  de tombstones `SYNCED` que superaron la ventana de gracia (30 días por
  defecto, medida sobre `updated_at`), con **borrado en cascada** de los
  adjuntos de una nota purgada, su historial y los archivos físicos
  (CU-06 fase 3, RNF-05). Corre best-effort al final del ciclo de sync.
- Tests sin red: `test/sync/attachment_service_test.dart` (subida, 413→ERROR,
  descarga con caché) y `test/sync/purga_service_test.dart` (ventana de
  gracia, PENDING no se purga, cascada de adjuntos + archivos, huérfanos).

## UX de errores y almacenamiento (tarea 4.2)

- **Registros en `ERROR`** (RF-04, sección 5.2): un rechazo del servidor no se
  reintenta solo. Ahora se guarda **el motivo** en la columna `sync_error`
  (migración v4) y se muestra: en la lista, bajo la nota ("No se sincronizó:
  … Toca para corregir"); en el editor, como banner rojo con el motivo y la
  salida. **Corregir y guardar** devuelve la nota a `PENDING` y limpia el
  motivo, de modo que la SyncTask la reintente. **Eliminar** sigue disponible
  desde la lista.
- **Aviso de almacenamiento** (RNF-05):
  [`espacio_service.dart`](lib/data/almacenamiento/espacio_service.dart) mide
  la BD cifrada + las copias de adjuntos y avisa al superar el **90 % de los
  500 MB** de presupuesto, con un banner en la lista. Se calcula una vez por
  sesión (recorrer el directorio no es gratis y el uso crece despacio).
- Tests: `test/almacenamiento/espacio_service_test.dart` (medición, umbral,
  formato) y `test/errores/ux_errores_test.dart` (motivo visible, corrección
  ERROR → PENDING, aviso de espacio).

## Historial por nota (tarea 4.1, RF-05)

- [`pantalla_historial.dart`](lib/presentation/pantallas/pantalla_historial.dart)
  — accesible desde el icono ⟳ del editor. Muestra el **historial local**
  (reactivo, offline-first) con estilo por origen (`LOCAL` / `REMOTO` /
  `CONFLICTO_DESCARTADO`), **resaltando los cambios descartados** por conflicto
  y el valor que se perdió (RF-05).
- Sección **"Ver historial del servidor"**: carga bajo demanda
  `GET /history/{nota_uuid}` ([history_api.dart](lib/data/red/history_api.dart))
  para ver la vista autoritativa entre dispositivos, sin forzar red al abrir.
- Se muestran como dos secciones separadas (local vs servidor) a propósito: el
  mismo evento se registra en ambos con uuids distintos, así que mezclarlos
  duplicaría entradas.
- Tests: `test/historial/pantalla_historial_test.dart`.

## Convergencia end-to-end (tarea 3.6)

- [`test/integration/convergencia_cu05_test.dart`](test/integration/convergencia_cu05_test.dart)
  — test de integración que levanta **dos stacks de cliente completos** (dos BD,
  dos `device_id`, Dio real con interceptor) y ejecuta el flujo literal de CU-05
  **contra el backend real** (HTTP + Express + PostgreSQL de la fase 1): register
  → push A → pull B → editar en ambos offline → push A (ACCEPTED) → push B
  (CONFLICT) → convergencia. Verifica RNF-02 y la entrada `CONFLICTO_DESCARTADO`.
  Se **autosalta** si el backend no está disponible (la suite sigue verde
  offline). Ejecutarlo: `cd backend && npm run dev`, luego
  `flutter test test/integration/convergencia_cu05_test.dart`.
- Guion de las pruebas manuales de dos emuladores (CU-01..CU-08, RNF-06 y el
  criterio de salida de la fase 3): [PRUEBAS-MANUALES.md](PRUEBAS-MANUALES.md).

## Checklist manual en dispositivo (criterio de salida de la fase 2)

Con un emulador o dispositivo por USB (`flutter run` en `app/`):

1. **CU-04 completo:** activar modo avión → crear una nota con contenido →
   adjuntarle un archivo (< 10 MB) → forzar cierre de la app (deslizar en
   recientes) → reabrir **aún sin red** → la nota y su adjunto están
   íntegros, con el indicador ⏱ (PENDING).
2. **RNF-03:** al guardar una nota, el cambio aparece en la lista de forma
   inmediata (< 100 ms perceptible).
3. **CU-08:** intentar adjuntar un archivo > 10 MB → SnackBar de rechazo y
   nada queda persistido.
4. **BD ilegible sin la clave:** con el dispositivo/emulador,
   `adb shell run-as com.notium.notium cat databases/../app_flutter/notium.db | head -c 16 | xxd`
   — un SQLite sin cifrar empezaría con el texto `SQLite format 3`; el
   archivo cifrado con SQLCipher muestra bytes aleatorios. (Alternativa:
   extraer el archivo y abrirlo con DB Browser for SQLite → debe fallar.)
5. La app funciona indefinidamente en modo avión.

## Comandos

```bash
flutter analyze     # estático
flutter test        # tests (widget + unitarios de repository en 2.3)
flutter run         # en emulador o dispositivo con depuración USB
```

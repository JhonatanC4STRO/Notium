import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/almacenamiento/espacio_service.dart';
import '../data/auth/almacen_seguro.dart';
import '../data/auth/almacen_sesion.dart';
import '../data/auth/auth_repository.dart';
import '../data/db/app_database.dart';
import '../data/red/api_cliente.dart';
import '../data/red/auth_api.dart';
import '../data/red/auth_interceptor.dart';
import '../data/red/attachments_api.dart';
import '../data/red/history_api.dart';
import '../data/red/sync_api.dart';
import '../data/repositorios/adjunto_repository.dart';
import '../data/repositorios/historial_repository.dart';
import '../data/repositorios/nota_repository.dart';
import '../data/sync/attachment_service.dart';
import '../data/sync/identidad_dispositivo.dart';
import '../data/sync/purga_service.dart';
import '../data/sync/sync_coordinator.dart';
import '../data/sync/sync_manager.dart';
import '../data/sync/sync_service.dart';
import '../domain/sesion.dart';

/// Cableado Riverpod (tarea 2.4, ADR-01): la UI consume EXCLUSIVAMENTE la BD
/// local a través de estos providers (Single Source of Truth, sección 3.1).
/// Los tests los sobreescriben con una BD en memoria y un directorio temporal.

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Directorio donde viven las copias de los adjuntos. Se define en main()
/// (path_provider es asíncrono); los tests lo sobreescriben con un temporal.
final directorioAdjuntosProvider = Provider<Directory>(
  (ref) => throw UnimplementedError('Se sobreescribe en main() o en los tests'),
);

/// Archivo de la BD cifrada, para medir el uso de almacenamiento (RNF-05).
/// También se define en main() y se sobreescribe en tests.
final archivoBaseDatosProvider = Provider<File>(
  (ref) => throw UnimplementedError('Se sobreescribe en main() o en los tests'),
);

// ---------------------------------------------------------------------------
// Sesión y red (tarea 3.1)
// ---------------------------------------------------------------------------

final almacenSeguroProvider = Provider<AlmacenSeguro>(
  (ref) => const AlmacenSeguroDispositivo(),
);

final almacenSesionProvider = Provider<AlmacenSesion>(
  (ref) => AlmacenSesion(ref.watch(almacenSeguroProvider)),
);

/// Dio SIN interceptor de auth: lo usan login/register/refresh (no llevan
/// token automático) y los reintentos del interceptor.
final dioSinAuthProvider = Provider<Dio>((ref) => crearDioBase());

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(dioSinAuthProvider)),
);

/// Dio autenticado (refresh automático en 401, CU-03): es el que usará la
/// capa de sincronización de las tareas 3.2/3.3.
final dioProvider = Provider<Dio>((ref) {
  final dio = crearDioBase();
  dio.interceptors.add(
    AuthInterceptor(
      almacen: ref.watch(almacenSesionProvider),
      authApi: ref.watch(authApiProvider),
      dioSinAuth: ref.watch(dioSinAuthProvider),
      // Refresh definitivamente inválido → la sesión local ya fue limpiada;
      // se recarga el estado para que la raíz vuelva al login.
      alExpirarSesion: () => ref.invalidate(sesionProvider),
    ),
  );
  return dio;
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    api: ref.watch(authApiProvider),
    almacen: ref.watch(almacenSesionProvider),
    db: ref.watch(appDatabaseProvider),
  ),
);

// ---------------------------------------------------------------------------
// Sincronización (tarea 3.2: push)
// ---------------------------------------------------------------------------

final identidadDispositivoProvider = Provider<IdentidadDispositivo>(
  (ref) => IdentidadDispositivo(ref.watch(almacenSeguroProvider)),
);

final syncApiProvider = Provider<SyncApi>(
  (ref) => SyncApi(ref.watch(dioProvider)),
);

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(
    db: ref.watch(appDatabaseProvider),
    api: ref.watch(syncApiProvider),
    identidad: ref.watch(identidadDispositivoProvider),
  ),
);

final attachmentsApiProvider = Provider<AttachmentsApi>(
  (ref) => AttachmentsApi(ref.watch(dioProvider)),
);

final attachmentServiceProvider = Provider<AttachmentService>(
  (ref) => AttachmentService(
    db: ref.watch(appDatabaseProvider),
    api: ref.watch(attachmentsApiProvider),
    identidad: ref.watch(identidadDispositivoProvider),
    directorioAdjuntos: ref.watch(directorioAdjuntosProvider),
  ),
);

final purgaServiceProvider = Provider<PurgaService>(
  (ref) => PurgaService(db: ref.watch(appDatabaseProvider)),
);

/// Coordina un ciclo push → subir binarios → pull → purga en foreground. El
/// interceptor del `dioProvider` ya invalida `sesionProvider` si el refresh
/// falla (CU-03).
final syncCoordinatorProvider = Provider<SyncCoordinator>(
  (ref) => SyncCoordinator(
    sync: ref.watch(syncServiceProvider),
    almacenSesion: ref.watch(almacenSesionProvider),
    adjuntos: ref.watch(attachmentServiceProvider),
    purga: ref.watch(purgaServiceProvider),
  ),
);

final syncManagerProvider = Provider<SyncManager>((ref) {
  final manager = SyncManager(coordinator: ref.watch(syncCoordinatorProvider));
  ref.onDispose(manager.detener);
  return manager;
});

/// Interruptor de la orquestación en segundo plano. Real por defecto; los
/// widget tests lo ponen en `false` para no invocar workmanager/connectivity
/// (plugins de plataforma ausentes en el entorno de test).
final syncEnSegundoPlanoProvider = Provider<bool>((ref) => true);

/// Estado de sesión de la app. `build` es el login offline de CU-02:
/// restaura la sesión cacheada y la valida LOCALMENTE por expiración —
/// `expirada` (más allá de la ventana degradada) exige reautenticación.
final sesionProvider = AsyncNotifierProvider<SesionNotifier, Sesion?>(
  SesionNotifier.new,
);

class SesionNotifier extends AsyncNotifier<Sesion?> {
  @override
  Future<Sesion?> build() async {
    final sesion = await ref.watch(authRepositoryProvider).sesionGuardada();
    if (sesion == null) return null;
    final estado = sesion.estadoEn(DateTime.now().toUtc());
    return estado == EstadoSesion.expirada ? null : sesion;
  }

  Future<void> login({
    required String email,
    required String contrasena,
  }) async {
    final sesion = await ref
        .read(authRepositoryProvider)
        .login(email: email, contrasena: contrasena);
    state = AsyncData(sesion);
  }

  Future<void> registrar({
    required String nombre,
    required String email,
    required String contrasena,
  }) async {
    final sesion = await ref
        .read(authRepositoryProvider)
        .registrar(nombre: nombre, email: email, contrasena: contrasena);
    state = AsyncData(sesion);
  }

  Future<void> cerrarSesion() async {
    await ref.read(authRepositoryProvider).cerrarSesion();
    state = const AsyncData(null);
  }
}

/// Usuario dueño de los datos locales: el autenticado, o la identidad
/// provisional `usuario-local` mientras no exista sesión (los datos creados
/// así se adoptan al iniciar sesión — ver AuthRepository).
final usuarioActualUuidProvider = Provider<String>(
  (ref) =>
      ref.watch(sesionProvider).value?.usuario.uuid ??
      AuthRepository.usuarioLocalUuid,
);

final notaRepositoryProvider = Provider<NotaRepository>(
  (ref) => NotaRepository(ref.watch(appDatabaseProvider)),
);

final adjuntoRepositoryProvider = Provider<AdjuntoRepository>(
  (ref) => AdjuntoRepository(
    ref.watch(appDatabaseProvider),
    directorioAdjuntos: ref.watch(directorioAdjuntosProvider),
  ),
);

/// Lista reactiva de notas del usuario (sin tombstones): cada escritura en
/// la BD re-emite y la UI se repinta sola (RNF-03).
final notasProvider = StreamProvider<List<Nota>>((ref) {
  final repo = ref.watch(notaRepositoryProvider);
  return repo.watchNotas(ref.watch(usuarioActualUuidProvider));
});

/// Adjuntos visibles de una nota, reactivo.
final adjuntosDeNotaProvider = StreamProvider.family<List<Adjunto>, String>(
  (ref, notaUuid) =>
      ref.watch(adjuntoRepositoryProvider).watchAdjuntosDeNota(notaUuid),
);

// ---------------------------------------------------------------------------
// Almacenamiento local (tarea 4.2, RNF-05)
// ---------------------------------------------------------------------------

final espacioServiceProvider = Provider<EspacioService>(
  (ref) => EspacioService(
    archivoBaseDatos: ref.watch(archivoBaseDatosProvider),
    directorioAdjuntos: ref.watch(directorioAdjuntosProvider),
  ),
);

/// Uso de almacenamiento. Se calcula una vez por sesión (recorrer el
/// directorio de adjuntos no es gratis y el uso crece despacio); se puede
/// refrescar invalidando el provider.
final usoAlmacenamientoProvider = FutureProvider<UsoAlmacenamiento>(
  (ref) => ref.watch(espacioServiceProvider).medir(),
);

// ---------------------------------------------------------------------------
// Historial (tarea 4.1, RF-05)
// ---------------------------------------------------------------------------

final historialRepositoryProvider = Provider<HistorialRepository>(
  (ref) => HistorialRepository(ref.watch(appDatabaseProvider)),
);

/// Historial LOCAL de una nota, reactivo (offline-first).
final historialDeNotaProvider =
    StreamProvider.family<List<HistorialCambio>, String>(
      (ref, notaUuid) =>
          ref.watch(historialRepositoryProvider).watchHistorial(notaUuid),
    );

final historyApiProvider = Provider<HistoryApi>(
  (ref) => HistoryApi(ref.watch(dioProvider)),
);

/// Historial del SERVIDOR (otros dispositivos), bajo demanda. Se carga solo al
/// solicitarlo desde la pantalla, para no forzar red al abrir el historial.
final historialServidorProvider =
    FutureProvider.family<List<HistorialRemoto>, String>(
      (ref, notaUuid) => ref.watch(historyApiProvider).obtener(notaUuid),
    );

/// Acciones de escritura (crear/editar/eliminar/adjuntar). La UI nunca toca
/// los repositorios directamente: pasa por aquí.
final accionesNotasProvider = NotifierProvider<AccionesNotas, void>(
  AccionesNotas.new,
);

class AccionesNotas extends Notifier<void> {
  @override
  void build() {}

  NotaRepository get _notas => ref.read(notaRepositoryProvider);
  AdjuntoRepository get _adjuntos => ref.read(adjuntoRepositoryProvider);
  String get _usuario => ref.read(usuarioActualUuidProvider);

  void _sincronizarTrasCambio() {
    if (!ref.read(syncEnSegundoPlanoProvider)) return;
    ref.read(syncManagerProvider).notificarCambioLocal();
  }

  Future<Nota> crear({required String titulo, String? contenido}) async {
    final nota = await _notas.crear(
      usuarioUuid: _usuario,
      titulo: titulo,
      contenido: contenido,
    );
    _sincronizarTrasCambio();
    return nota;
  }

  Future<Nota> editar({
    required String uuid,
    String? titulo,
    String? contenido,
  }) async {
    final nota = await _notas.editar(
      uuid: uuid,
      titulo: titulo,
      contenido: contenido,
    );
    _sincronizarTrasCambio();
    return nota;
  }

  Future<void> eliminar(String uuid) async {
    await _notas.eliminar(uuid);
    _sincronizarTrasCambio();
  }

  Future<Adjunto> agregarAdjunto({
    required String notaUuid,
    required File archivo,
  }) async {
    final adjunto = await _adjuntos.agregar(
      notaUuid: notaUuid,
      archivo: archivo,
    );
    _sincronizarTrasCambio();
    return adjunto;
  }

  Future<void> eliminarAdjunto(String uuid) async {
    await _adjuntos.eliminar(uuid);
    _sincronizarTrasCambio();
  }
}

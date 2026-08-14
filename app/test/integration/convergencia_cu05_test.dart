@Tags(['integracion'])
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notium/data/auth/almacen_seguro.dart';
import 'package:notium/data/auth/almacen_sesion.dart';
import 'package:notium/data/db/app_database.dart';
import 'package:notium/data/red/api_cliente.dart';
import 'package:notium/data/red/auth_api.dart';
import 'package:notium/data/red/auth_interceptor.dart';
import 'package:notium/data/red/sync_api.dart';
import 'package:notium/data/repositorios/nota_repository.dart';
import 'package:notium/data/sync/identidad_dispositivo.dart';
import 'package:notium/data/sync/sync_service.dart';
import 'package:notium/domain/enums.dart';
import 'package:notium/domain/sesion.dart';
import 'package:uuid/uuid.dart';

/// Prueba de convergencia end-to-end de CU-05 (tarea 3.6) contra el BACKEND
/// REAL. A diferencia del resto de la suite (que usa dobles), este test
/// levanta dos stacks de cliente completos —dos BD, dos device_id, Dio real
/// con interceptor— y ejecuta el flujo literal de CU-05 atravesando HTTP y el
/// backend de la fase 1. Cubre todo salvo la UI/emulador (guion manual aparte).
///
/// Requiere el backend en marcha:
///   cd backend && npm run dev   (con Docker/PostgreSQL arriba)
/// Ejecutar con:
///   flutter test test/integration/convergencia_cu05_test.dart
void main() {
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/v1',
  );
  const uuid = Uuid();

  // Dos dispositivos = dos AppDatabase; el aviso de drift no aplica (nunca
  // comparten executor).
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<bool> backendVivo() async {
    try {
      final r = await crearDioBase(baseUrl: baseUrl).get<Map<String, Object?>>('/health');
      return r.data?['estado'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  test('CU-05: dos dispositivos convergen por LWW contra el backend real (RNF-02)',
      () async {
    if (!await backendVivo()) {
      // Sin backend el test se SALTA (no falla): así la suite completa sigue
      // verde offline. Para ejecutarlo: cd backend && npm run dev.
      markTestSkipped('Backend no disponible en $baseUrl — test E2E omitido.');
      return;
    }

    // Registro de una cuenta fresca (CU-01).
    final authApi = AuthApi(crearDioBase(baseUrl: baseUrl));
    final sesion = await authApi.registrar(
      uuid: uuid.v4(),
      nombre: 'Convergencia',
      email: 'conv-${DateTime.now().microsecondsSinceEpoch}@notium.test',
      contrasena: 'clave-segura-123',
    );

    final a = await _Dispositivo.crear(baseUrl, sesion);
    final b = await _Dispositivo.crear(baseUrl, sesion);
    addTearDown(a.cerrar);
    addTearDown(b.cerrar);

    // Precondición: la misma nota, sincronizada en ambos (version 1).
    final nota =
        await a.notas.crear(usuarioUuid: a.usuarioUuid, titulo: 'Original', contenido: 'base');
    final pushInicial = await a.sync.push();
    expect(pushInicial.aceptadas, 1);

    await b.sync.pull(b.usuarioUuid);
    expect((await b.nota(nota.uuid))!.titulo, 'Original');

    // Ambos editan OFFLINE. Se fijan los updated_at para un LWW determinista:
    // A a las 10:20 (más reciente), B a las 10:05 (más antigua).
    await a.notas.editar(uuid: nota.uuid, titulo: 'edición de A');
    await a.fijarUpdatedAt(nota.uuid, DateTime.utc(2026, 7, 20, 10, 20));
    await b.notas.editar(uuid: nota.uuid, titulo: 'edición de B');
    await b.fijarUpdatedAt(nota.uuid, DateTime.utc(2026, 7, 20, 10, 5));

    // Fase 1 — A sincroniza primero: sin conflicto → autoritativo.
    final crono = Stopwatch()..start();
    final pushA = await a.sync.push();
    expect(pushA.aceptadas, 1);
    expect(pushA.conflictos, 0);

    // Fase 2 — B sincroniza después: version desfasada → LWW; 10:20 > 10:05 →
    // gana A → B recibe CONFLICT y converge al estado del servidor.
    final pushB = await b.sync.push();
    crono.stop();
    expect(pushB.conflictos, 1);

    // Postcondición (RNF-02): ambos convergen a "edición de A".
    final finalA = await a.nota(nota.uuid);
    final finalB = await b.nota(nota.uuid);
    expect(finalA!.titulo, 'edición de A');
    expect(finalB!.titulo, 'edición de A');
    expect(finalA.version, finalB.version);
    expect(finalA.syncStatus, SyncStatus.SYNCED);
    expect(finalB.syncStatus, SyncStatus.SYNCED);

    // El cambio descartado de B queda auditado (RF-05).
    final descartes = await (b.db.select(b.db.historialCambios)
          ..where((h) => h.origenCambio.equalsValue(OrigenCambio.CONFLICTO_DESCARTADO)))
        .get();
    expect(descartes, isNotEmpty);

    // Un pull final en A no lo hace divergir (recibe su propio estado o nada).
    await a.sync.pull(a.usuarioUuid);
    expect((await a.nota(nota.uuid))!.titulo, 'edición de A');

    // RNF-06 (proxy): el ciclo de sincronización fue muy inferior a 30 s. La
    // latencia del scheduling de workmanager se valida a mano en dispositivo.
    expect(crono.elapsed.inSeconds, lessThan(30));
  });
}

/// Un stack de cliente completo apuntando al backend real.
class _Dispositivo {
  _Dispositivo({
    required this.db,
    required this.sync,
    required this.notas,
    required this.usuarioUuid,
  });

  final AppDatabase db;
  final SyncService sync;
  final NotaRepository notas;
  final String usuarioUuid;

  static Future<_Dispositivo> crear(String baseUrl, SesionRemota sesion) async {
    final db = AppDatabase.paraTests(NativeDatabase.memory());
    final almacenSeguro = AlmacenSeguroEnMemoria();
    final almacenSesion = AlmacenSesion(almacenSeguro);
    await almacenSesion.guardarSesion(Sesion(
      usuario: sesion.usuario,
      accessToken: sesion.tokens.accessToken,
      refreshToken: sesion.tokens.refreshToken,
      expiraEn: DateTime.now()
          .toUtc()
          .add(Duration(seconds: sesion.tokens.expiresInSegundos)),
    ));

    final dioSinAuth = crearDioBase(baseUrl: baseUrl);
    final dio = crearDioBase(baseUrl: baseUrl)
      ..interceptors.add(AuthInterceptor(
        almacen: almacenSesion,
        authApi: AuthApi(dioSinAuth),
        dioSinAuth: dioSinAuth,
      ));

    return _Dispositivo(
      db: db,
      sync: SyncService(
        db: db,
        api: SyncApi(dio),
        identidad: IdentidadDispositivo(almacenSeguro),
      ),
      notas: NotaRepository(db),
      usuarioUuid: sesion.usuario.uuid,
    );
  }

  Future<Nota?> nota(String uuidNota) =>
      (db.select(db.notas)..where((n) => n.uuid.equals(uuidNota))).getSingleOrNull();

  Future<void> fijarUpdatedAt(String uuidNota, DateTime cuando) => db.customStatement(
        'UPDATE notas SET updated_at = ? WHERE uuid = ?',
        [cuando.toUtc().toIso8601String(), uuidNota],
      );

  Future<void> cerrar() => db.close();
}

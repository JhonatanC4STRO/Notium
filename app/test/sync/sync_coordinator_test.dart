import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notium/data/auth/almacen_seguro.dart';
import 'package:notium/data/auth/almacen_sesion.dart';
import 'package:notium/data/db/app_database.dart';
import 'package:notium/data/red/auth_api.dart';
import 'package:notium/data/red/sync_api.dart';
import 'package:notium/data/repositorios/nota_repository.dart';
import 'package:notium/data/sync/identidad_dispositivo.dart';
import 'package:notium/data/sync/sync_coordinator.dart';
import 'package:notium/data/sync/sync_service.dart';
import 'package:notium/domain/sesion.dart';

/// Tests del SyncCoordinator (tarea 3.4): traduce el resultado de push→pull a
/// un DesenlaceSync. Sin red, sin workmanager, sin plataformas.
void main() {
  late AppDatabase db;
  late AlmacenSesion almacen;

  setUp(() {
    db = AppDatabase.paraTests(NativeDatabase.memory());
    almacen = AlmacenSesion(AlmacenSeguroEnMemoria());
  });

  tearDown(() => db.close());

  Future<void> sembrarSesion() => almacen.guardarSesion(Sesion(
        usuario: const UsuarioSesion(uuid: 'u-1', nombre: 'A', email: 'a@a.co'),
        accessToken: 'acc',
        refreshToken: 'ref',
        expiraEn: DateTime.now().toUtc().add(const Duration(hours: 1)),
      ));

  // Un cambio local pendiente, para que el push realmente golpee la red
  // (sin pendientes, push() no llama a la API).
  Future<void> sembrarNotaPendiente() =>
      NotaRepository(db).crear(usuarioUuid: 'u-1', titulo: 'pendiente');

  SyncCoordinator coord(_SyncApiFalsa api, {bool Function()? sesionExpiro}) =>
      SyncCoordinator(
        sync: SyncService(
          db: db,
          api: api,
          identidad: IdentidadDispositivo(AlmacenSeguroEnMemoria()),
        ),
        almacenSesion: almacen,
        sesionExpiro: sesionExpiro,
      );

  test('sin sesión guardada → sesionExpirada (no hay nada que sincronizar)', () async {
    final r = await coord(_SyncApiFalsa()).ejecutar();
    expect(r, DesenlaceSync.sesionExpirada);
  });

  test('push y pull sin novedades → ok', () async {
    await sembrarSesion();
    final r = await coord(_SyncApiFalsa()).ejecutar();
    expect(r, DesenlaceSync.ok);
  });

  test('sin red en el push → sinRed (para backoff de workmanager, CU-07)', () async {
    await sembrarSesion();
    await sembrarNotaPendiente();
    final r = await coord(_SyncApiFalsa()..sinRedEnPush = true).ejecutar();
    expect(r, DesenlaceSync.sinRed);
  });

  test('401 tras refresh fallido → sesionExpirada (CU-03)', () async {
    await sembrarSesion();
    await sembrarNotaPendiente();
    final r = await coord(_SyncApiFalsa()..lanzar401EnPush = true).ejecutar();
    expect(r, DesenlaceSync.sesionExpirada);
  });

  test('el flag sesionExpiro del interceptor también fuerza sesionExpirada', () async {
    await sembrarSesion();
    final r = await coord(_SyncApiFalsa(), sesionExpiro: () => true).ejecutar();
    expect(r, DesenlaceSync.sesionExpirada);
  });

  test('error inesperado del servidor → error (reintentable)', () async {
    await sembrarSesion();
    await sembrarNotaPendiente();
    final r = await coord(_SyncApiFalsa()..lanzar500EnPush = true).ejecutar();
    expect(r, DesenlaceSync.error);
  });
}

/// SyncApi falsa configurable para los distintos desenlaces.
class _SyncApiFalsa extends SyncApi {
  _SyncApiFalsa() : super(Dio());

  bool sinRedEnPush = false;
  bool lanzar401EnPush = false;
  bool lanzar500EnPush = false;

  @override
  Future<RespuestaPush> push({
    required String deviceId,
    required List<OperacionSync> operaciones,
  }) async {
    if (sinRedEnPush) throw SinConexionException();
    if (lanzar401EnPush) {
      throw ApiException(codigo: 'TOKEN_EXPIRADO', mensaje: 'x', status: 401);
    }
    if (lanzar500EnPush) {
      throw ApiException(codigo: 'HTTP_500', mensaje: 'x', status: 500);
    }
    return const RespuestaPush(resultados: [], huboConflicto: false);
  }

  @override
  Future<RespuestaPull> pull({
    required String desde,
    String? deviceId,
    int limite = 100,
  }) async {
    return RespuestaPull(cambios: const [], timestampServidor: desde, hayMas: false);
  }
}

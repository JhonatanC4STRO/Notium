import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notium/data/auth/almacen_seguro.dart';
import 'package:notium/data/db/app_database.dart';
import 'package:notium/data/red/auth_api.dart';
import 'package:notium/data/red/sync_api.dart';
import 'package:notium/data/repositorios/nota_repository.dart';
import 'package:notium/data/sync/identidad_dispositivo.dart';
import 'package:notium/data/sync/sync_service.dart';
import 'package:notium/domain/enums.dart';

/// Tests de SyncService.push() (tarea 3.2) con una SyncApi falsa: sin red.
/// Se ejercita la contraparte cliente del contrato de la sección 5.5.
void main() {
  late AppDatabase db;
  late NotaRepository notas;
  late _SyncApiFalsa api;
  late SyncService sync;

  const usuario = 'u-1';

  setUp(() {
    db = AppDatabase.paraTests(NativeDatabase.memory());
    notas = NotaRepository(db);
    api = _SyncApiFalsa();
    sync = SyncService(
      db: db,
      api: api,
      identidad: IdentidadDispositivo(AlmacenSeguroEnMemoria()),
    );
  });

  tearDown(() => db.close());

  Future<Nota> notaPorUuid(String uuid) =>
      (db.select(db.notas)..where((n) => n.uuid.equals(uuid))).getSingle();

  test('device_id estable: va a nivel de lote y no cambia entre pushes', () async {
    await notas.crear(usuarioUuid: usuario, titulo: 'A');
    await sync.push();
    await notas.crear(usuarioUuid: usuario, titulo: 'B');
    await sync.push();

    expect(api.deviceIdsVistos.toSet(), hasLength(1)); // el mismo siempre
    expect(api.deviceIdsVistos.first, startsWith('disp-'));
  });

  test('una nota nueva se envía como CREATE; sin cambios no hay push', () async {
    final creada = await notas.crear(usuarioUuid: usuario, titulo: 'Acta');
    api.respuestaFija = [_aceptado(creada.uuid, versionServidor: 1)];

    final r = await sync.push();

    expect(r.enviadas, 1);
    expect(api.ultimoLote.single.operacion, 'CREATE');
    expect(api.ultimoLote.single.payload['titulo'], 'Acta');

    // Un segundo push sin cambios locales no envía nada.
    api.lotes.clear();
    final r2 = await sync.push();
    expect(r2.enviadas, 0);
    expect(api.lotes, isEmpty);
  });

  test('ACCEPTED → SYNCED y adopta la versión del servidor', () async {
    final creada = await notas.crear(usuarioUuid: usuario, titulo: 'x');
    api.respuestaFija = [_aceptado(creada.uuid, versionServidor: 5)];

    final r = await sync.push();

    expect(r.aceptadas, 1);
    final n = await notaPorUuid(creada.uuid);
    expect(n.syncStatus, SyncStatus.SYNCED);
    expect(n.version, 5);
  });

  test('tras un CREATE aceptado, la siguiente edición se envía como UPDATE', () async {
    final creada = await notas.crear(usuarioUuid: usuario, titulo: 'v1');
    api.respuestaFija = [_aceptado(creada.uuid, versionServidor: 1)];
    await sync.push();

    await notas.editar(uuid: creada.uuid, titulo: 'v2');
    api.respuestaFija = [_aceptado(creada.uuid, versionServidor: 2)];
    await sync.push();

    expect(api.ultimoLote.single.operacion, 'UPDATE');
    expect(api.ultimoLote.single.version, 1); // la versión base conocida
  });

  test('CONFLICT (CU-05 fase 3): sobrescribe con el servidor y audita el descarte',
      () async {
    final creada =
        await notas.crear(usuarioUuid: usuario, titulo: 'mía', contenido: 'local');
    // Simula que ya estaba sincronizada y fue editada de nuevo.
    await db.customStatement(
      "UPDATE notas SET sincronizado = 1, sync_status = 'SYNCED' WHERE uuid = ?",
      [creada.uuid],
    );
    await notas.editar(uuid: creada.uuid, titulo: 'edición perdedora');

    api.respuestaFija = [
      _conflicto(
        creada.uuid,
        versionServidor: 9,
        payloadServidor: {
          'titulo': 'ganadora del servidor',
          'contenido': 'remoto',
          'updated_at': '2026-07-20T10:00:00.000Z',
          'is_deleted': false,
          'version': 9,
        },
      ),
    ];

    final r = await sync.push();

    expect(r.conflictos, 1);
    final n = await notaPorUuid(creada.uuid);
    // Convergió al estado autoritativo del servidor.
    expect(n.titulo, 'ganadora del servidor');
    expect(n.contenido, 'remoto');
    expect(n.version, 9);
    expect(n.syncStatus, SyncStatus.SYNCED);

    // El cambio descartado quedó en el historial (RF-05).
    final historial = await (db.select(db.historialCambios)
          ..where((h) => h.origenCambio.equalsValue(OrigenCambio.CONFLICTO_DESCARTADO)))
        .get();
    expect(historial, hasLength(1));
    final descartado = jsonDecode(historial.single.valorAnterior!) as Map;
    expect(descartado['titulo'], 'edición perdedora');
  });

  test('ERROR → sync_status = ERROR, sin reintento automático', () async {
    final creada = await notas.crear(usuarioUuid: usuario, titulo: 'x');
    api.respuestaFija = [
      const ResultadoSync(
        uuid: '',
        estado: 'ERROR',
      ).copiaConUuid(creada.uuid),
    ];

    final r = await sync.push();

    expect(r.errores, 1);
    final n = await notaPorUuid(creada.uuid);
    expect(n.syncStatus, SyncStatus.ERROR);
  });

  test('CU-07: fallo de red a mitad de lote → todo sigue PENDING', () async {
    final creada = await notas.crear(usuarioUuid: usuario, titulo: 'x');
    api.lanzarSinConexion = true;

    final r = await sync.push();

    expect(r.sinRed, true);
    final n = await notaPorUuid(creada.uuid);
    expect(n.syncStatus, SyncStatus.PENDING); // nada cambió
    expect(n.sincronizado, false);
  });

  test('tombstone nunca sincronizado se cierra localmente, sin tocar la red', () async {
    final creada = await notas.crear(usuarioUuid: usuario, titulo: 'efímera');
    await notas.eliminar(creada.uuid); // isDeleted + PENDING, jamás sincronizada

    final r = await sync.push();

    expect(r.enviadas, 0); // no se envió nada
    expect(api.lotes, isEmpty);
    final n = await notaPorUuid(creada.uuid);
    expect(n.syncStatus, SyncStatus.SYNCED); // cerrada localmente
    expect(n.isDeleted, true);
  });

  test('un lote mixto: nota nueva antes que su adjunto (orden de creación)', () async {
    // Dos notas creadas en orden: el backend las procesa en el orden del array.
    final a = await notas.crear(usuarioUuid: usuario, titulo: 'primera');
    final b = await notas.crear(usuarioUuid: usuario, titulo: 'segunda');
    api.respuestaFija = [
      _aceptado(a.uuid, versionServidor: 1),
      _aceptado(b.uuid, versionServidor: 1),
    ];

    await sync.push();

    expect(api.ultimoLote.map((o) => o.uuid).toList(), [a.uuid, b.uuid]);
  });
}

ResultadoSync _aceptado(String uuid, {required int versionServidor}) =>
    ResultadoSync(uuid: uuid, estado: 'ACCEPTED', versionServidor: versionServidor);

ResultadoSync _conflicto(
  String uuid, {
  required int versionServidor,
  required Map<String, Object?> payloadServidor,
}) =>
    ResultadoSync(
      uuid: uuid,
      estado: 'CONFLICT',
      versionServidor: versionServidor,
      payloadServidor: payloadServidor,
    );

extension on ResultadoSync {
  ResultadoSync copiaConUuid(String uuid) => ResultadoSync(
        uuid: uuid,
        estado: estado,
        versionServidor: versionServidor,
        payloadServidor: payloadServidor,
        error: error,
      );
}

/// SyncApi falsa: captura los lotes enviados y devuelve respuestas fijas.
/// No usa el Dio: sobreescribe `push` sin llamar a super.
class _SyncApiFalsa extends SyncApi {
  _SyncApiFalsa() : super(Dio());

  final List<List<OperacionSync>> lotes = [];
  final List<String> deviceIdsVistos = [];
  List<ResultadoSync> respuestaFija = const [];
  bool lanzarSinConexion = false;

  List<OperacionSync> get ultimoLote => lotes.last;

  @override
  Future<RespuestaPush> push({
    required String deviceId,
    required List<OperacionSync> operaciones,
  }) async {
    if (lanzarSinConexion) throw SinConexionException();
    deviceIdsVistos.add(deviceId);
    lotes.add(operaciones);
    final huboConflicto = respuestaFija.any((r) => r.estado == 'CONFLICT');
    return RespuestaPush(resultados: respuestaFija, huboConflicto: huboConflicto);
  }
}

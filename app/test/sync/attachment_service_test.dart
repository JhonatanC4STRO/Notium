import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notium/data/auth/almacen_seguro.dart';
import 'package:notium/data/db/app_database.dart';
import 'package:notium/data/red/attachments_api.dart';
import 'package:notium/data/red/auth_api.dart';
import 'package:notium/data/repositorios/adjunto_repository.dart';
import 'package:notium/data/repositorios/nota_repository.dart';
import 'package:notium/data/sync/attachment_service.dart';
import 'package:notium/data/sync/identidad_dispositivo.dart';
import 'package:notium/domain/enums.dart';

/// Tests de AttachmentService (tarea 3.5): subida de binarios tras
/// sincronizarse los metadatos y descarga bajo demanda. Sin red.
void main() {
  late AppDatabase db;
  late NotaRepository notas;
  late AdjuntoRepository adjuntos;
  late _AttachmentsApiFalsa api;
  late AttachmentService service;
  late Directory temporal;
  late Directory almacen;
  late String notaUuid;

  setUp(() async {
    db = AppDatabase.paraTests(NativeDatabase.memory());
    temporal = await Directory.systemTemp.createTemp('notium_adj_');
    almacen = Directory('${temporal.path}/adjuntos');
    notas = NotaRepository(db);
    adjuntos = AdjuntoRepository(db, directorioAdjuntos: almacen);
    api = _AttachmentsApiFalsa();
    service = AttachmentService(
      db: db,
      api: api,
      identidad: IdentidadDispositivo(AlmacenSeguroEnMemoria()),
      directorioAdjuntos: almacen,
    );
    notaUuid = (await notas.crear(usuarioUuid: 'u-1', titulo: 'Con adjuntos')).uuid;
  });

  tearDown(() async {
    await db.close();
    await temporal.delete(recursive: true);
  });

  Future<Adjunto> adjuntoPorUuid(String uuid) =>
      (db.select(db.adjuntos)..where((a) => a.uuid.equals(uuid))).getSingle();

  /// Crea un adjunto local ya "sincronizado" (metadatos en el servidor) pero
  /// sin url_remota: el estado justo antes de subir el binario.
  Future<String> adjuntoSincronizadoSinBinario() async {
    final archivo = File('${temporal.path}/f.pdf')..writeAsBytesSync([1, 2, 3]);
    final a = await adjuntos.agregar(notaUuid: notaUuid, archivo: File(archivo.path));
    await (db.update(db.adjuntos)..where((x) => x.uuid.equals(a.uuid))).write(
      const AdjuntosCompanion(sincronizado: Value(true), syncStatus: Value(SyncStatus.SYNCED)),
    );
    return a.uuid;
  }

  test('sube el binario pendiente y guarda url_remota', () async {
    final uuid = await adjuntoSincronizadoSinBinario();
    api.urlAsignada = '/v1/attachments/$uuid';

    final r = await service.subirPendientes();

    expect(r.subidos, 1);
    expect(api.subidos, [uuid]); // se subió por multipart
    final a = await adjuntoPorUuid(uuid);
    expect(a.urlRemota, '/v1/attachments/$uuid');
  });

  test('no re-sube un adjunto que ya tiene url_remota', () async {
    final uuid = await adjuntoSincronizadoSinBinario();
    await (db.update(db.adjuntos)..where((x) => x.uuid.equals(uuid)))
        .write(const AdjuntosCompanion(urlRemota: Value('/ya/subido')));

    final r = await service.subirPendientes();

    expect(r.subidos, 0);
    expect(api.subidos, isEmpty);
  });

  test('413 del servidor → adjunto en ERROR, sin reintento (CU-08)', () async {
    final uuid = await adjuntoSincronizadoSinBinario();
    api.lanzar413 = true;

    final r = await service.subirPendientes();

    expect(r.errores, 1);
    final a = await adjuntoPorUuid(uuid);
    expect(a.syncStatus, SyncStatus.ERROR);
    expect(a.urlRemota, isNull);
  });

  test('sin red al subir → propaga (el coordinador lo vuelve sinRed)', () async {
    await adjuntoSincronizadoSinBinario();
    api.lanzarSinConexion = true;

    await expectLater(service.subirPendientes(), throwsA(isA<SinConexionException>()));
  });

  test('descarga bajo demanda: si no hay copia local, la trae y persiste ruta', () async {
    // Adjunto remoto: existe en la BD con url_remota pero sin archivo local.
    const uuid = 'adj-remoto';
    await db.into(db.adjuntos).insert(AdjuntosCompanion.insert(
          uuid: uuid,
          notaUuid: notaUuid,
          urlRemota: const Value('/v1/attachments/adj-remoto'),
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
          sincronizado: const Value(true),
          syncStatus: const Value(SyncStatus.SYNCED),
        ));
    api.bytesDescarga = [9, 8, 7, 6];

    final archivo = await service.descargar(uuid);

    expect(await archivo.readAsBytes(), [9, 8, 7, 6]);
    final a = await adjuntoPorUuid(uuid);
    expect(a.rutaLocal, archivo.path); // ruta persistida para la próxima vez

    // Segunda llamada: ya hay copia local, no vuelve a la red.
    api.descargas = 0;
    await service.descargar(uuid);
    expect(api.descargas, 0);
  });
}

class _AttachmentsApiFalsa extends AttachmentsApi {
  _AttachmentsApiFalsa() : super(Dio());

  final List<String> subidos = [];
  String? urlAsignada;
  bool lanzar413 = false;
  bool lanzarSinConexion = false;

  List<int> bytesDescarga = const [];
  int descargas = 0;

  @override
  Future<AdjuntoRemoto> subir({
    required String uuid,
    required String notaUuid,
    String? deviceId,
    required File archivo,
  }) async {
    if (lanzarSinConexion) throw SinConexionException();
    if (lanzar413) {
      throw ApiException(codigo: 'ADJUNTO_EXCEDE_LIMITE', mensaje: 'x', status: 413);
    }
    subidos.add(uuid);
    return AdjuntoRemoto(uuid: uuid, urlRemota: urlAsignada);
  }

  @override
  Future<List<int>> descargar(String uuid) async {
    descargas++;
    return bytesDescarga;
  }
}

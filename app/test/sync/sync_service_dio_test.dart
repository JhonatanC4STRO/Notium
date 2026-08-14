import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notium/data/auth/almacen_seguro.dart';
import 'package:notium/data/db/app_database.dart';
import 'package:notium/data/red/sync_api.dart';
import 'package:notium/data/repositorios/nota_repository.dart';
import 'package:notium/data/sync/identidad_dispositivo.dart';
import 'package:notium/data/sync/sync_service.dart';
import 'package:notium/domain/enums.dart';

/// Cierre de la tarea 4.3: SyncService ejercitado con SyncApi real sobre un
/// Dio mockeado por HttpClientAdapter. No toca red, pero valida el contrato
/// HTTP que aparece en doc/openapi.yaml y doc/doc.md seccion 5.5.
void main() {
  late AppDatabase db;
  late NotaRepository notas;
  late _BackendSyncFalso backend;
  late SyncService sync;

  const usuario = 'u-1';

  setUp(() {
    db = AppDatabase.paraTests(NativeDatabase.memory());
    notas = NotaRepository(db);
    backend = _BackendSyncFalso();

    final dio = Dio(BaseOptions(baseUrl: 'http://backend.falso/v1'))
      ..httpClientAdapter = backend;
    sync = SyncService(
      db: db,
      api: SyncApi(dio),
      identidad: IdentidadDispositivo(AlmacenSeguroEnMemoria()),
    );
  });

  tearDown(() => db.close());

  Future<Nota> notaPorUuid(String uuid) =>
      (db.select(db.notas)..where((n) => n.uuid.equals(uuid))).getSingle();

  test(
    'push arma el lote del contrato y aplica ACCEPTED desde Dio mockeado',
    () async {
      final creada = await notas.crear(usuarioUuid: usuario, titulo: 'Acta');
      backend.pushBody = {
        'resultados': [
          {'uuid': creada.uuid, 'estado': 'ACCEPTED', 'version_servidor': 4},
        ],
      };

      final r = await sync.push();

      expect(r.enviadas, 1);
      expect(r.aceptadas, 1);
      expect(backend.ultimoMetodo, 'POST');
      expect(backend.ultimaRuta, endsWith('/sync/push'));

      final cuerpo = backend.ultimoCuerpo!;
      expect(cuerpo['device_id'], startsWith('disp-'));
      final operaciones = cuerpo['operaciones'] as List;
      final op = (operaciones.single as Map).cast<String, Object?>();
      expect(op['uuid'], creada.uuid);
      expect(op['entidad'], 'NOTA');
      expect(op['operacion'], 'CREATE');
      expect(op['version'], 1);
      expect(op.containsKey('device_id'), false);
      expect((op['payload'] as Map)['titulo'], 'Acta');

      final finalLocal = await notaPorUuid(creada.uuid);
      expect(finalLocal.syncStatus, SyncStatus.SYNCED);
      expect(finalLocal.version, 4);
    },
  );

  test('push acepta 409 como respuesta valida y resuelve CONFLICT', () async {
    final creada = await notas.crear(
      usuarioUuid: usuario,
      titulo: 'titulo local inicial',
      contenido: 'local',
    );
    await db.customStatement(
      "UPDATE notas SET sincronizado = 1, sync_status = 'SYNCED' WHERE uuid = ?",
      [creada.uuid],
    );
    await notas.editar(uuid: creada.uuid, titulo: 'titulo perdedor');

    backend.pushStatus = 409;
    backend.pushBody = {
      'resultados': [
        {
          'uuid': creada.uuid,
          'estado': 'CONFLICT',
          'version_servidor': 8,
          'payload_servidor': {
            'titulo': 'titulo servidor',
            'contenido': 'remoto',
            'updated_at': '2026-07-20T10:00:00.000Z',
            'is_deleted': false,
            'version': 8,
          },
        },
      ],
    };

    final r = await sync.push();

    expect(r.conflictos, 1);
    final finalLocal = await notaPorUuid(creada.uuid);
    expect(finalLocal.titulo, 'titulo servidor');
    expect(finalLocal.contenido, 'remoto');
    expect(finalLocal.version, 8);
    expect(finalLocal.syncStatus, SyncStatus.SYNCED);
  });

  test(
    'pull envia cursor/device_id/limite por query y aplica la pagina',
    () async {
      backend.pullBodies = [
        {
          'cambios': [
            {
              'uuid': 'nota-remota-1',
              'entidad': 'NOTA',
              'operacion': 'CREATE',
              'payload': {
                'titulo': 'Remota',
                'contenido': 'desde backend',
                'created_at': '2026-07-20T09:00:00.000Z',
              },
              'version': 3,
              'updated_at': '2026-07-20T09:30:00.000Z',
              'is_deleted': false,
              'device_id': 'disp-otro',
            },
          ],
          'timestamp_servidor': '2026-07-20T10:00:00.000Z',
          'hay_mas': false,
        },
      ];

      final r = await sync.pull(usuario);

      expect(r.aplicados, 1);
      expect(backend.ultimoMetodo, 'GET');
      expect(backend.ultimaRuta, endsWith('/sync/pull'));
      expect(backend.ultimaQuery['desde'], '1970-01-01T00:00:00.000Z');
      expect(backend.ultimaQuery['device_id'], startsWith('disp-'));
      expect(backend.ultimaQuery['limite'], 100);

      final remota = await notaPorUuid('nota-remota-1');
      expect(remota.titulo, 'Remota');
      expect(remota.syncStatus, SyncStatus.SYNCED);
    },
  );

  test('fallo de red desde Dio deja los registros PENDING (CU-07)', () async {
    final creada = await notas.crear(usuarioUuid: usuario, titulo: 'Pendiente');
    backend.sinConexion = true;

    final r = await sync.push();

    expect(r.sinRed, true);
    final finalLocal = await notaPorUuid(creada.uuid);
    expect(finalLocal.syncStatus, SyncStatus.PENDING);
    expect(finalLocal.sincronizado, false);
  });
}

class _BackendSyncFalso implements HttpClientAdapter {
  int pushStatus = 200;
  Map<String, Object?> pushBody = const {'resultados': []};
  List<Map<String, Object?>> pullBodies = const [];
  bool sinConexion = false;

  String? ultimoMetodo;
  String? ultimaRuta;
  Map<String, Object?>? ultimoCuerpo;
  Map<String, Object?> ultimaQuery = const {};
  int _pullIndex = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (sinConexion) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: 'sin conexion',
      );
    }

    ultimoMetodo = options.method;
    ultimaRuta = options.path;
    ultimaQuery = options.queryParameters.cast<String, Object?>();
    ultimoCuerpo = _cuerpoDe(options);

    if (options.path.endsWith('/sync/push')) {
      return _json(pushStatus, pushBody);
    }
    if (options.path.endsWith('/sync/pull')) {
      return _json(200, pullBodies[_pullIndex++]);
    }
    return _json(404, {
      'codigo': 'NO_ENCONTRADO',
      'mensaje': 'Ruta no encontrada',
    });
  }

  Map<String, Object?>? _cuerpoDe(RequestOptions options) {
    final datos = options.data;
    if (datos == null) return null;
    if (datos is Map) return datos.cast<String, Object?>();
    if (datos is String && datos.isNotEmpty) {
      return (jsonDecode(datos) as Map).cast<String, Object?>();
    }
    return null;
  }

  ResponseBody _json(int status, Map<String, Object?> cuerpo) =>
      ResponseBody.fromString(
        jsonEncode(cuerpo),
        status,
        headers: {
          'content-type': ['application/json; charset=utf-8'],
        },
      );

  @override
  void close({bool force = false}) {}
}

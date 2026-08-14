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

/// Tests de SyncService.pull() (tarea 3.3) con una SyncApi falsa: sin red.
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

  Future<Nota?> notaPorUuid(String uuid) =>
      (db.select(db.notas)..where((n) => n.uuid.equals(uuid))).getSingleOrNull();

  test('aplica una nota remota nueva como SYNCED con origen REMOTO', () async {
    api.paginas = [
      _pagina([_cambioNota('n-1', titulo: 'Remota', version: 3)], '2026-07-20T10:00:00.000Z'),
    ];

    final r = await sync.pull(usuario);

    expect(r.aplicados, 1);
    final n = await notaPorUuid('n-1');
    expect(n, isNotNull);
    expect(n!.titulo, 'Remota');
    expect(n.version, 3);
    expect(n.syncStatus, SyncStatus.SYNCED);
    expect(n.sincronizado, true);

    final historial = await (db.select(db.historialCambios)
          ..where((h) => h.origenCambio.equalsValue(OrigenCambio.REMOTO)))
        .get();
    expect(historial, hasLength(1));
  });

  test('envía device_id (anti-eco) y el cursor desde persistido', () async {
    api.paginas = [_pagina([], '2026-07-20T10:00:00.000Z')];
    await sync.pull(usuario);

    expect(api.deviceIdEnviado, startsWith('disp-'));
    expect(api.desdeEnviado.first, '1970-01-01T00:00:00.000Z'); // época en el 1er pull

    // El segundo pull parte del cursor persistido por el primero.
    api.paginas = [_pagina([], '2026-07-21T00:00:00.000Z')];
    await sync.pull(usuario);
    expect(api.desdeEnviado.last, '2026-07-20T10:00:00.000Z');
  });

  test('respeta tombstones remotos: oculta de la vista pero conserva la fila', () async {
    // Primero la nota existe localmente (sincronizada).
    api.paginas = [
      _pagina([_cambioNota('n-1', titulo: 'Viva', version: 1)], '2026-07-20T10:00:00.000Z'),
    ];
    await sync.pull(usuario);

    // Luego llega su tombstone.
    api.paginas = [
      _pagina([_tombstoneNota('n-1', version: 2)], '2026-07-20T11:00:00.000Z'),
    ];
    final r = await sync.pull(usuario);

    expect(r.tombstones, 1);
    final n = await notaPorUuid('n-1');
    expect(n, isNotNull); // la fila sigue (tombstone, no borrado físico)
    expect(n!.isDeleted, true);

    // No aparece en la vista de notas activas.
    final visibles = await notas.watchNotas(usuario).first;
    expect(visibles, isEmpty);
  });

  test('NO pisa un registro PENDING local; el push posterior resolverá', () async {
    // Nota creada y editada localmente (PENDING), aún sin sincronizar.
    final local = await notas.crear(usuarioUuid: usuario, titulo: 'mi versión local');

    // Llega un cambio remoto para el mismo uuid.
    api.paginas = [
      _pagina(
        [_cambioNota(local.uuid, titulo: 'versión del servidor', version: 7)],
        '2026-07-20T10:00:00.000Z',
      ),
    ];

    final r = await sync.pull(usuario);

    expect(r.omitidosPendientes, 1);
    expect(r.aplicados, 0);
    final n = await notaPorUuid(local.uuid);
    expect(n!.titulo, 'mi versión local'); // intacto
    expect(n.syncStatus, SyncStatus.PENDING); // sigue pendiente de push
  });

  test('pagina mientras hay_mas y persiste el cursor de la última página', () async {
    api.paginas = [
      _pagina([_cambioNota('a', titulo: 'A', version: 1)], '2026-07-20T10:00:00.000Z', hayMas: true),
      _pagina([_cambioNota('b', titulo: 'B', version: 1)], '2026-07-20T11:00:00.000Z', hayMas: false),
    ];

    final r = await sync.pull(usuario);

    expect(r.paginas, 2);
    expect(r.aplicados, 2);
    expect(await notaPorUuid('a'), isNotNull);
    expect(await notaPorUuid('b'), isNotNull);

    // El siguiente pull parte del cursor de la 2ª página.
    api.paginas = [_pagina([], '2026-07-22T00:00:00.000Z')];
    await sync.pull(usuario);
    expect(api.desdeEnviado.last, '2026-07-20T11:00:00.000Z');
  });

  test('CU-07: sin red no avanza el cursor ni aplica nada', () async {
    api.lanzarSinConexion = true;

    final r = await sync.pull(usuario);

    expect(r.sinRed, true);
    // El cursor sigue en la época: el próximo pull reintenta desde el principio.
    api.lanzarSinConexion = false;
    api.paginas = [_pagina([], '2026-07-20T10:00:00.000Z')];
    await sync.pull(usuario);
    expect(api.desdeEnviado.last, '1970-01-01T00:00:00.000Z');
  });
}

// --- Helpers de construcción de cambios/páginas -----------------------------

CambioServidor _cambioNota(String uuid, {required String titulo, required int version}) =>
    CambioServidor(
      uuid: uuid,
      entidad: 'NOTA',
      operacion: version == 1 ? 'CREATE' : 'UPDATE',
      payload: {'titulo': titulo, 'contenido': null, 'created_at': '2026-07-20T09:00:00.000Z'},
      version: version,
      updatedAt: '2026-07-20T09:30:00.000Z',
      isDeleted: false,
      deviceId: 'disp-otro',
    );

CambioServidor _tombstoneNota(String uuid, {required int version}) => CambioServidor(
      uuid: uuid,
      entidad: 'NOTA',
      operacion: 'DELETE',
      payload: const {},
      version: version,
      updatedAt: '2026-07-20T10:30:00.000Z',
      isDeleted: true,
      deviceId: 'disp-otro',
    );

RespuestaPull _pagina(List<CambioServidor> cambios, String cursor, {bool hayMas = false}) =>
    RespuestaPull(cambios: cambios, timestampServidor: cursor, hayMas: hayMas);

/// SyncApi falsa: devuelve páginas en secuencia y captura los parámetros.
class _SyncApiFalsa extends SyncApi {
  _SyncApiFalsa() : super(Dio());

  List<RespuestaPull> _paginas = const [];
  int _indice = 0;
  final List<String> desdeEnviado = [];
  String? deviceIdEnviado;
  bool lanzarSinConexion = false;

  // Reasignar la secuencia de páginas reinicia el cursor de lectura, para
  // poder encadenar varios pull() en un mismo test.
  set paginas(List<RespuestaPull> valor) {
    _paginas = valor;
    _indice = 0;
  }

  @override
  Future<RespuestaPull> pull({
    required String desde,
    String? deviceId,
    int limite = 100,
  }) async {
    if (lanzarSinConexion) throw SinConexionException();
    desdeEnviado.add(desde);
    deviceIdEnviado = deviceId;
    return _paginas[_indice++];
  }
}

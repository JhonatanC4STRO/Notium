import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notium/data/db/app_database.dart';
import 'package:notium/data/sync/purga_service.dart';
import 'package:notium/domain/enums.dart';

/// Tests de PurgaService (tarea 3.5, CU-06 fase 3, RNF-05).
void main() {
  late AppDatabase db;
  late PurgaService purga;

  final ahora = DateTime.now().toUtc();
  final vieja = ahora.subtract(const Duration(days: 40)); // > ventana de gracia
  final reciente = ahora.subtract(const Duration(days: 1));

  setUp(() {
    db = AppDatabase.paraTests(NativeDatabase.memory());
    purga = PurgaService(db: db); // ventana por defecto: 30 días
  });

  tearDown(() => db.close());

  Future<void> insertarNota(
    String uuid, {
    required bool isDeleted,
    required SyncStatus estado,
    required DateTime updatedAt,
  }) {
    return db.into(db.notas).insert(NotasCompanion.insert(
          uuid: uuid,
          usuarioUuid: 'u-1',
          titulo: uuid,
          createdAt: ahora,
          updatedAt: updatedAt,
          isDeleted: Value(isDeleted),
          syncStatus: Value(estado),
        ));
  }

  Future<String> insertarAdjunto(String notaUuid, {String? rutaLocal, bool isDeleted = false, SyncStatus estado = SyncStatus.SYNCED, DateTime? updatedAt}) async {
    final uuid = 'adj-$notaUuid-${rutaLocal ?? ''}';
    await db.into(db.adjuntos).insert(AdjuntosCompanion.insert(
          uuid: uuid,
          notaUuid: notaUuid,
          rutaLocal: Value(rutaLocal),
          createdAt: ahora,
          updatedAt: updatedAt ?? ahora,
          isDeleted: Value(isDeleted),
          syncStatus: Value(estado),
        ));
    return uuid;
  }

  Future<int> contarNotas() async => (await db.select(db.notas).get()).length;
  Future<int> contarAdjuntos() async => (await db.select(db.adjuntos).get()).length;

  test('purga una nota tombstone SYNCED vencida y su historial', () async {
    await insertarNota('n-1', isDeleted: true, estado: SyncStatus.SYNCED, updatedAt: vieja);
    await db.into(db.historialCambios).insert(HistorialCambiosCompanion.insert(
          uuid: 'h-1',
          notaUuid: 'n-1',
          tipoCambio: 'DELETE',
          origenCambio: OrigenCambio.LOCAL,
          fecha: vieja,
        ));

    final r = await purga.purgar();

    expect(r.notas, 1);
    expect(await contarNotas(), 0);
    expect(await db.select(db.historialCambios).get(), isEmpty); // cascada
  });

  test('NO purga tombstones dentro de la ventana de gracia', () async {
    await insertarNota('n-1', isDeleted: true, estado: SyncStatus.SYNCED, updatedAt: reciente);
    final r = await purga.purgar();
    expect(r.notas, 0);
    expect(await contarNotas(), 1);
  });

  test('NO purga tombstones aún PENDING (no confirmados por el servidor)', () async {
    await insertarNota('n-1', isDeleted: true, estado: SyncStatus.PENDING, updatedAt: vieja);
    final r = await purga.purgar();
    expect(r.notas, 0);
    expect(await contarNotas(), 1);
  });

  test('NO purga notas activas aunque sean viejas', () async {
    await insertarNota('n-1', isDeleted: false, estado: SyncStatus.SYNCED, updatedAt: vieja);
    final r = await purga.purgar();
    expect(r.notas, 0);
    expect(await contarNotas(), 1);
  });

  test('borra en cascada los adjuntos de una nota purgada y sus archivos', () async {
    final temp = await Directory.systemTemp.createTemp('notium_purga_');
    addTearDown(() => temp.delete(recursive: true));
    final archivo = File('${temp.path}/binario.bin')..writeAsBytesSync([1, 2, 3]);

    await insertarNota('n-1', isDeleted: true, estado: SyncStatus.SYNCED, updatedAt: vieja);
    await insertarAdjunto('n-1', rutaLocal: archivo.path);

    final r = await purga.purgar();

    expect(r.notas, 1);
    expect(r.adjuntos, 1);
    expect(await contarAdjuntos(), 0);
    expect(archivo.existsSync(), false); // el binario físico se borró
  });

  test('purga adjuntos tombstone huérfanos (su nota sigue viva)', () async {
    await insertarNota('n-1', isDeleted: false, estado: SyncStatus.SYNCED, updatedAt: reciente);
    await insertarAdjunto('n-1', rutaLocal: null, isDeleted: true, estado: SyncStatus.SYNCED, updatedAt: vieja);

    final r = await purga.purgar();

    expect(r.notas, 0);
    expect(r.adjuntos, 1);
    expect(await contarNotas(), 1); // la nota viva permanece
    expect(await contarAdjuntos(), 0);
  });
}

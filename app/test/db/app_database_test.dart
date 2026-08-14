import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notium/data/db/app_database.dart';
import 'package:notium/domain/enums.dart';

/// Verificación del esquema de la tarea 2.2 con una BD en memoria: las
/// tablas se crean, los metadatos de sync tienen los defaults correctos,
/// los enums persisten por nombre y las FK están activas.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.paraTests(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  final ahora = DateTime.utc(2026, 7, 13, 10);

  NotasCompanion notaBase(String uuid) => NotasCompanion.insert(
        uuid: uuid,
        usuarioUuid: 'usuario-1',
        titulo: 'Nota de prueba',
        createdAt: ahora,
        updatedAt: ahora,
      );

  test('crea una nota con los defaults de los metadatos de sync (4.2)', () async {
    await db.into(db.notas).insert(notaBase('nota-1'));

    final nota = await db.select(db.notas).getSingle();
    expect(nota.syncStatus, SyncStatus.PENDING); // cola implícita (5.2)
    expect(nota.isDeleted, false);
    expect(nota.version, 1); // el cliente solo inicializa en 1 (6.3)
    expect(nota.deviceId, isNull);
  });

  test('los enums persisten por su NOMBRE (contrato openapi.yaml)', () async {
    await db.into(db.notas).insert(notaBase('nota-1'));
    await db.into(db.historialCambios).insert(
          HistorialCambiosCompanion.insert(
            uuid: 'hist-1',
            notaUuid: 'nota-1',
            tipoCambio: 'CREATE',
            origenCambio: OrigenCambio.CONFLICTO_DESCARTADO,
            fecha: ahora,
          ),
        );

    // Se lee la columna cruda, sin pasar por el converter de Drift.
    final filas = await db
        .customSelect('SELECT sync_status FROM notas WHERE uuid = ?',
            variables: [Variable('nota-1')])
        .get();
    expect(filas.single.data['sync_status'], 'PENDING');

    final historial = await db
        .customSelect('SELECT origen_cambio FROM historial_cambios')
        .get();
    expect(historial.single.data['origen_cambio'], 'CONFLICTO_DESCARTADO');
  });

  test('las FK están activas: un adjunto exige una nota existente', () async {
    expect(
      () => db.into(db.adjuntos).insert(
            AdjuntosCompanion.insert(
              uuid: 'adj-huerfano',
              notaUuid: 'nota-inexistente',
              createdAt: ahora,
              updatedAt: ahora,
            ),
          ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('un tombstone conserva la fila con is_deleted = true (5.4)', () async {
    await db.into(db.notas).insert(notaBase('nota-1'));
    await (db.update(db.notas)..where((n) => n.uuid.equals('nota-1'))).write(
      const NotasCompanion(
        isDeleted: Value(true),
        syncStatus: Value(SyncStatus.PENDING),
      ),
    );

    final nota = await db.select(db.notas).getSingle();
    expect(nota.isDeleted, true);
    expect(nota.titulo, 'Nota de prueba'); // el contenido no se pierde
  });
}

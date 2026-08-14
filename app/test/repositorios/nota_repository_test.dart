import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notium/data/db/app_database.dart';
import 'package:notium/data/repositorios/nota_repository.dart';
import 'package:notium/domain/enums.dart';
import 'package:notium/domain/errores.dart';

/// Tests del NotaRepository con Drift en memoria (tarea 2.3, sin emulador).
void main() {
  late AppDatabase db;
  late NotaRepository repo;

  const usuario = 'usuario-1';
  final uuidV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  setUp(() {
    db = AppDatabase.paraTests(NativeDatabase.memory());
    repo = NotaRepository(db);
  });

  tearDown(() => db.close());

  group('crear (CU-04 fase local)', () {
    test('genera UUID v4, version 1, PENDING y updated_at (sección 5.1/5.2)', () async {
      final nota = await repo.crear(usuarioUuid: usuario, titulo: 'Acta', contenido: 'x');

      expect(nota.uuid, matches(uuidV4));
      expect(nota.version, 1);
      expect(nota.syncStatus, SyncStatus.PENDING);
      expect(nota.isDeleted, false);
      expect(nota.updatedAt.isUtc, true);
    });

    test('registra HISTORIAL_CAMBIO con origen LOCAL en la misma operación', () async {
      final nota = await repo.crear(usuarioUuid: usuario, titulo: 'Acta');

      final historial = await db.select(db.historialCambios).get();
      expect(historial, hasLength(1));
      expect(historial.single.notaUuid, nota.uuid);
      expect(historial.single.tipoCambio, 'CREATE');
      expect(historial.single.origenCambio, OrigenCambio.LOCAL);
      expect(historial.single.valorAnterior, isNull);
      expect(historial.single.valorNuevo, contains('Acta'));
    });
  });

  group('editar', () {
    test('vuelve a PENDING, actualiza updated_at y NO toca version (6.3)', () async {
      final creada = await repo.crear(usuarioUuid: usuario, titulo: 'v1');

      // Simula que la sincronización de la fase 3 ya la marcó SYNCED.
      await db.customStatement(
        "UPDATE notas SET sync_status = 'SYNCED' WHERE uuid = ?",
        [creada.uuid],
      );

      final editada = await repo.editar(uuid: creada.uuid, titulo: 'v2');

      expect(editada.titulo, 'v2');
      expect(editada.contenido, creada.contenido); // campo no tocado se conserva
      expect(editada.syncStatus, SyncStatus.PENDING); // SYNCED → PENDING (5.2)
      expect(editada.version, creada.version); // solo el servidor incrementa
      expect(editada.updatedAt.isAfter(creada.updatedAt) ||
          editada.updatedAt.isAtSameMomentAs(creada.updatedAt), true);

      final historial = await db.select(db.historialCambios).get();
      expect(historial.map((h) => h.tipoCambio), containsAll(['CREATE', 'UPDATE']));
      final update = historial.singleWhere((h) => h.tipoCambio == 'UPDATE');
      expect(update.valorAnterior, contains('v1'));
      expect(update.valorNuevo, contains('v2'));
    });

    test('nota inexistente lanza y NO deja rastro en el historial (transacción)', () async {
      await expectLater(
        repo.editar(uuid: 'no-existe', titulo: 'x'),
        throwsA(isA<NotaNoEncontrada>()),
      );
      expect(await db.select(db.historialCambios).get(), isEmpty);
    });
  });

  group('eliminar (CU-06 fase 1)', () {
    test('soft delete: la fila queda como tombstone PENDING con su contenido', () async {
      final nota = await repo.crear(usuarioUuid: usuario, titulo: 'Efímera');
      await repo.eliminar(nota.uuid);

      final fila = await (db.select(db.notas)
            ..where((n) => n.uuid.equals(nota.uuid)))
          .getSingle();
      expect(fila.isDeleted, true);
      expect(fila.syncStatus, SyncStatus.PENDING);
      expect(fila.titulo, 'Efímera'); // no hay borrado físico (5.4)

      final historial = await db.select(db.historialCambios).get();
      expect(historial.map((h) => h.tipoCambio), contains('DELETE'));
    });

    test('eliminar una nota ya eliminada lanza NotaNoEncontrada', () async {
      final nota = await repo.crear(usuarioUuid: usuario, titulo: 'x');
      await repo.eliminar(nota.uuid);
      await expectLater(repo.eliminar(nota.uuid), throwsA(isA<NotaNoEncontrada>()));
    });
  });

  group('watchNotas (Single Source of Truth, 3.1)', () {
    test('emite reactivamente y filtra tombstones y otros usuarios', () async {
      final emisiones = <List<Nota>>[];
      final sub = repo.watchNotas(usuario).listen(emisiones.add);
      addTearDown(sub.cancel);

      final mia = await repo.crear(usuarioUuid: usuario, titulo: 'Mía');
      await repo.crear(usuarioUuid: 'otro-usuario', titulo: 'Ajena');
      final borrada = await repo.crear(usuarioUuid: usuario, titulo: 'Borrada');
      await repo.eliminar(borrada.uuid);

      // Espera a que el stream drene las emisiones pendientes.
      await pumpEventQueue();

      final ultima = emisiones.last;
      expect(ultima.map((n) => n.uuid), [mia.uuid]); // ni ajena ni tombstone
      expect(emisiones.length, greaterThan(1)); // fue reactivo, no un get()
    });
  });
}

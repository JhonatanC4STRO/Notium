import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notium/data/db/app_database.dart';
import 'package:notium/data/repositorios/adjunto_repository.dart';
import 'package:notium/data/repositorios/nota_repository.dart';
import 'package:notium/domain/enums.dart';
import 'package:notium/domain/errores.dart';

/// Tests del AdjuntoRepository con Drift en memoria y un directorio temporal
/// (tarea 2.3, CU-08 fase local).
void main() {
  late AppDatabase db;
  late NotaRepository notas;
  late AdjuntoRepository repo;
  late Directory temporal;
  late Directory almacen;
  late String notaUuid;

  setUp(() async {
    db = AppDatabase.paraTests(NativeDatabase.memory());
    temporal = await Directory.systemTemp.createTemp('notium_test_');
    almacen = Directory('${temporal.path}/adjuntos');
    notas = NotaRepository(db);
    repo = AdjuntoRepository(db, directorioAdjuntos: almacen);
    notaUuid =
        (await notas.crear(usuarioUuid: 'usuario-1', titulo: 'Con adjuntos')).uuid;
  });

  tearDown(() async {
    await db.close();
    await temporal.delete(recursive: true);
  });

  Future<File> archivoDePrueba(String nombre, int bytes) async {
    final archivo = File('${temporal.path}/$nombre');
    await archivo.writeAsBytes(List.filled(bytes, 7));
    return archivo;
  }

  test('copia el archivo al almacenamiento de la app y persiste PENDING', () async {
    final original = await archivoDePrueba('factura.pdf', 1024);

    final adjunto = await repo.agregar(notaUuid: notaUuid, archivo: original);

    expect(adjunto.notaUuid, notaUuid);
    expect(adjunto.syncStatus, SyncStatus.PENDING);
    expect(adjunto.version, 1);
    expect(adjunto.rutaLocal, endsWith('.pdf')); // conserva la extensión

    // Es una COPIA dentro del almacén de la app, no el original.
    final copia = File(adjunto.rutaLocal!);
    expect(copia.existsSync(), true);
    expect(copia.path, isNot(original.path));
    expect(copia.lengthSync(), 1024);

    final historial = await db.select(db.historialCambios).get();
    expect(historial.map((h) => h.tipoCambio), contains('ADJUNTO_CREATE'));
  });

  test('CU-08: >10 MB se rechaza ANTES de persistir — sin copia y sin fila', () async {
    final grande = await archivoDePrueba('video.mp4', limiteAdjuntoBytes + 1);

    await expectLater(
      repo.agregar(notaUuid: notaUuid, archivo: grande),
      throwsA(isA<AdjuntoExcedeLimite>()),
    );

    expect(await db.select(db.adjuntos).get(), isEmpty); // sin fila
    expect(almacen.existsSync(), false); // ni siquiera se creó el almacén
  });

  test('exactamente 10 MB sí se acepta (el límite es inclusivo)', () async {
    final justo = await archivoDePrueba('maximo.bin', limiteAdjuntoBytes);
    final adjunto = await repo.agregar(notaUuid: notaUuid, archivo: justo);
    expect(File(adjunto.rutaLocal!).lengthSync(), limiteAdjuntoBytes);
  });

  test('nota inexistente o eliminada lanza NotaNoEncontrada', () async {
    final archivo = await archivoDePrueba('a.txt', 10);

    await expectLater(
      repo.agregar(notaUuid: 'no-existe', archivo: archivo),
      throwsA(isA<NotaNoEncontrada>()),
    );

    await notas.eliminar(notaUuid);
    await expectLater(
      repo.agregar(notaUuid: notaUuid, archivo: archivo),
      throwsA(isA<NotaNoEncontrada>()),
    );
  });

  test('eliminar es soft delete y el watch filtra el tombstone', () async {
    final archivo = await archivoDePrueba('b.txt', 10);
    final adjunto = await repo.agregar(notaUuid: notaUuid, archivo: archivo);

    final emisiones = <List<Adjunto>>[];
    final sub = repo.watchAdjuntosDeNota(notaUuid).listen(emisiones.add);
    addTearDown(sub.cancel);

    await repo.eliminar(adjunto.uuid);
    await pumpEventQueue();

    expect(emisiones.last, isEmpty); // el watch ya no lo muestra

    final fila = await (db.select(db.adjuntos)
          ..where((a) => a.uuid.equals(adjunto.uuid)))
        .getSingle();
    expect(fila.isDeleted, true); // pero la fila sigue (tombstone)
    expect(fila.syncStatus, SyncStatus.PENDING);
    expect(File(adjunto.rutaLocal!).existsSync(), true); // el binario espera la purga (3.5)
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../domain/enums.dart';
import '../../domain/errores.dart';
import '../db/app_database.dart';

/// Adjuntos locales (tarea 2.3, CU-08 fase local). El binario se COPIA al
/// almacenamiento propio de la app (el archivo original del usuario puede
/// desaparecer); en la BD solo va la ruta. El directorio se inyecta para
/// que los tests usen un temporal sin path_provider; la app lo cablea con
/// getApplicationDocumentsDirectory() en los providers (tarea 2.4).
class AdjuntoRepository {
  AdjuntoRepository(this._db, {required Directory directorioAdjuntos})
      : _directorio = directorioAdjuntos;

  final AppDatabase _db;
  final Directory _directorio;
  static const _uuid = Uuid();

  /// Adjuntos visibles de una nota, reactivo y sin tombstones.
  Stream<List<Adjunto>> watchAdjuntosDeNota(String notaUuid) {
    final consulta = _db.select(_db.adjuntos)
      ..where((a) => a.notaUuid.equals(notaUuid) & a.isDeleted.equals(false))
      ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]);
    return consulta.watch();
  }

  Future<Adjunto> agregar({required String notaUuid, required File archivo}) async {
    // CU-08: el límite se valida ANTES de copiar o persistir nada — un
    // archivo rechazado no deja rastro ni en disco ni en la BD.
    final tamano = await archivo.length();
    if (tamano > limiteAdjuntoBytes) throw AdjuntoExcedeLimite(tamano);

    final nota = await (_db.select(_db.notas)
          ..where((n) => n.uuid.equals(notaUuid) & n.isDeleted.equals(false)))
        .getSingleOrNull();
    if (nota == null) throw NotaNoEncontrada(notaUuid);

    final uuid = _uuid.v4();
    final ahora = DateTime.now().toUtc();

    // La copia conserva la extensión para poder abrir el archivo después.
    await _directorio.create(recursive: true);
    final destino = p.join(_directorio.path, '$uuid${p.extension(archivo.path)}');
    await archivo.copy(destino);

    try {
      return await _db.transaction(() async {
        await _db.into(_db.adjuntos).insert(
              AdjuntosCompanion.insert(
                uuid: uuid,
                notaUuid: notaUuid,
                rutaLocal: Value(destino),
                createdAt: ahora,
                updatedAt: ahora,
              ),
            );
        await _registrarHistorial(
          notaUuid: notaUuid,
          tipo: 'ADJUNTO_CREATE',
          valorNuevo: {'adjunto_uuid': uuid, 'ruta_local': destino, 'tamano_bytes': tamano},
          fecha: ahora,
        );
        return (_db.select(_db.adjuntos)..where((a) => a.uuid.equals(uuid))).getSingle();
      });
    } catch (e) {
      // Si la BD falla, la copia huérfana se limpia: disco y BD coherentes.
      final copia = File(destino);
      if (await copia.exists()) await copia.delete();
      rethrow;
    }
  }

  /// Soft delete del adjunto (tombstone). El archivo físico se conserva
  /// hasta la purga con ventana de gracia (fase 3.5).
  Future<void> eliminar(String uuid) {
    return _db.transaction(() async {
      final actual = await (_db.select(_db.adjuntos)
            ..where((a) => a.uuid.equals(uuid) & a.isDeleted.equals(false)))
          .getSingleOrNull();
      if (actual == null) throw AdjuntoNoEncontrado(uuid);

      final ahora = DateTime.now().toUtc();
      await (_db.update(_db.adjuntos)..where((a) => a.uuid.equals(uuid))).write(
        AdjuntosCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(ahora),
          syncStatus: const Value(SyncStatus.PENDING),
        ),
      );
      await _registrarHistorial(
        notaUuid: actual.notaUuid,
        tipo: 'ADJUNTO_DELETE',
        valorNuevo: {'adjunto_uuid': uuid},
        fecha: ahora,
      );
    });
  }

  Future<void> _registrarHistorial({
    required String notaUuid,
    required String tipo,
    required Map<String, Object?> valorNuevo,
    required DateTime fecha,
  }) {
    return _db.into(_db.historialCambios).insert(
          HistorialCambiosCompanion.insert(
            uuid: _uuid.v4(),
            notaUuid: notaUuid,
            tipoCambio: tipo,
            origenCambio: OrigenCambio.LOCAL,
            fecha: fecha,
            valorNuevo: Value(jsonEncode(valorNuevo)),
          ),
        );
  }
}

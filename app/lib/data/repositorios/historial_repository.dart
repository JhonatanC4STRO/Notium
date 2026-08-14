import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// Lectura del historial de auditoría local (tarea 4.1, RF-05). El historial
/// local es la fuente offline-first: incluye los cambios `LOCAL`, los
/// `REMOTO` aplicados por pull y los `CONFLICTO_DESCARTADO` de este
/// dispositivo. La vista del servidor (otros dispositivos) llega por
/// `HistoryApi`.
class HistorialRepository {
  HistorialRepository(this._db);

  final AppDatabase _db;

  /// Entradas de una nota, más recientes primero, reactivo.
  Stream<List<HistorialCambio>> watchHistorial(String notaUuid) {
    final consulta = _db.select(_db.historialCambios)
      ..where((h) => h.notaUuid.equals(notaUuid))
      ..orderBy([(h) => OrderingTerm.desc(h.fecha)]);
    return consulta.watch();
  }
}

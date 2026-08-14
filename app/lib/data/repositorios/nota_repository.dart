import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums.dart';
import '../../domain/errores.dart';
import '../db/app_database.dart';

/// CRUD local de notas (tarea 2.3, CU-04 y CU-06 fase 1). 100% offline: la
/// red no existe en esta capa; la SyncTask de la fase 3 consumirá los
/// registros PENDING que este repositorio deja marcados.
///
/// Invariantes (secciones 5.1, 5.2 y 4.2):
/// - Todo uuid se genera aquí (UUID v4), nunca en el servidor.
/// - Toda escritura marca `sync_status = PENDING` y registra la entrada de
///   `HISTORIAL_CAMBIO` con `origen_cambio = LOCAL` en LA MISMA transacción:
///   no puede quedar un cambio sin su rastro de auditoría, ni viceversa.
/// - `version` no se toca localmente: solo el servidor la incrementa (6.3).
/// - Eliminar es soft delete (tombstone, sección 5.4).
class NotaRepository {
  NotaRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// Notas visibles del usuario, reactivo: cada escritura en la BD re-emite
  /// la lista (la UI la consume vía StreamProvider, RNF-03). Los tombstones
  /// se filtran aquí para que ninguna pantalla los muestre por accidente.
  Stream<List<Nota>> watchNotas(String usuarioUuid) {
    final consulta = _db.select(_db.notas)
      ..where((n) => n.usuarioUuid.equals(usuarioUuid) & n.isDeleted.equals(false))
      ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)]);
    return consulta.watch();
  }

  /// Una nota puntual (para el editor), también reactiva.
  Stream<Nota?> watchNota(String uuid) {
    final consulta = _db.select(_db.notas)
      ..where((n) => n.uuid.equals(uuid) & n.isDeleted.equals(false));
    return consulta.watchSingleOrNull();
  }

  Future<Nota> crear({
    required String usuarioUuid,
    required String titulo,
    String? contenido,
  }) {
    final ahora = DateTime.now().toUtc();
    final uuid = _uuid.v4();

    return _db.transaction(() async {
      await _db.into(_db.notas).insert(
            NotasCompanion.insert(
              uuid: uuid,
              usuarioUuid: usuarioUuid,
              titulo: titulo,
              contenido: Value(contenido),
              createdAt: ahora,
              updatedAt: ahora,
              // syncStatus PENDING y version 1 son defaults del esquema.
            ),
          );
      await _registrarHistorial(
        notaUuid: uuid,
        tipo: 'CREATE',
        valorAnterior: null,
        valorNuevo: {'titulo': titulo, 'contenido': contenido},
        fecha: ahora,
      );
      return _porUuid(uuid);
    });
  }

  Future<Nota> editar({
    required String uuid,
    String? titulo,
    String? contenido,
  }) {
    return _db.transaction(() async {
      final actual = await _activaPorUuid(uuid);
      final ahora = DateTime.now().toUtc();

      await (_db.update(_db.notas)..where((n) => n.uuid.equals(uuid))).write(
        NotasCompanion(
          titulo: titulo != null ? Value(titulo) : const Value.absent(),
          contenido: contenido != null ? Value(contenido) : const Value.absent(),
          updatedAt: Value(ahora),
          syncStatus: const Value(SyncStatus.PENDING),
          // Corrección del usuario: ERROR → PENDING y se limpia el motivo
          // (sección 5.2; la salida de ERROR exige corregir el dato).
          syncError: const Value(null),
        ),
      );
      await _registrarHistorial(
        notaUuid: uuid,
        tipo: 'UPDATE',
        valorAnterior: {'titulo': actual.titulo, 'contenido': actual.contenido},
        valorNuevo: {
          'titulo': titulo ?? actual.titulo,
          'contenido': contenido ?? actual.contenido,
        },
        fecha: ahora,
      );
      return _porUuid(uuid);
    });
  }

  /// Soft delete (CU-06 fase 1): marca el tombstone y lo deja PENDING para
  /// que la sincronización lo propague. Idempotente.
  Future<void> eliminar(String uuid) {
    return _db.transaction(() async {
      final actual = await _activaPorUuid(uuid);
      final ahora = DateTime.now().toUtc();

      await (_db.update(_db.notas)..where((n) => n.uuid.equals(uuid))).write(
        NotasCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(ahora),
          syncStatus: const Value(SyncStatus.PENDING),
        ),
      );
      await _registrarHistorial(
        notaUuid: uuid,
        tipo: 'DELETE',
        valorAnterior: {'titulo': actual.titulo, 'contenido': actual.contenido},
        valorNuevo: null,
        fecha: ahora,
      );
    });
  }

  Future<Nota> _porUuid(String uuid) {
    return (_db.select(_db.notas)..where((n) => n.uuid.equals(uuid))).getSingle();
  }

  Future<Nota> _activaPorUuid(String uuid) async {
    final nota = await (_db.select(_db.notas)
          ..where((n) => n.uuid.equals(uuid) & n.isDeleted.equals(false)))
        .getSingleOrNull();
    if (nota == null) throw NotaNoEncontrada(uuid);
    return nota;
  }

  Future<void> _registrarHistorial({
    required String notaUuid,
    required String tipo,
    required Map<String, Object?>? valorAnterior,
    required Map<String, Object?>? valorNuevo,
    required DateTime fecha,
  }) {
    return _db.into(_db.historialCambios).insert(
          HistorialCambiosCompanion.insert(
            uuid: _uuid.v4(),
            notaUuid: notaUuid,
            tipoCambio: tipo,
            origenCambio: OrigenCambio.LOCAL,
            fecha: fecha,
            valorAnterior: Value(valorAnterior == null ? null : jsonEncode(valorAnterior)),
            valorNuevo: Value(valorNuevo == null ? null : jsonEncode(valorNuevo)),
            // dispositivoOrigen se completa en la fase 3, cuando exista el
            // device_id estable persistido (tarea 3.2).
          ),
        );
  }
}

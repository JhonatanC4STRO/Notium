import 'dart:io';

import 'package:drift/drift.dart';

import '../../domain/enums.dart';
import '../db/app_database.dart';

/// Resumen de una pasada de purga.
class ResumenPurga {
  const ResumenPurga({required this.notas, required this.adjuntos});
  static const vacio = ResumenPurga(notas: 0, adjuntos: 0);
  final int notas;
  final int adjuntos;
}

/// Purga física de tombstones (tarea 3.5, CU-06 fase 3, RNF-05). Elimina de
/// verdad los registros marcados como eliminados que ya se sincronizaron
/// (`SYNCED`) y superaron la ventana de gracia, conteniendo el crecimiento de
/// la BD local. Borra en cascada los adjuntos de una nota purgada y sus
/// archivos físicos.
///
/// La ventana de gracia se mide sobre `updated_at`: sin confirmación de
/// propagación por dispositivo (que exigiría estado extra en el servidor), es
/// la aproximación pragmática que admite el doc (secciones 5.4 y 9).
class PurgaService {
  PurgaService({
    required this.db,
    this.ventanaGracia = const Duration(days: 30),
  });

  final AppDatabase db;
  final Duration ventanaGracia;

  Future<ResumenPurga> purgar() async {
    final corte = DateTime.now().toUtc().subtract(ventanaGracia);
    final archivosABorrar = <String>[];
    var notasPurgadas = 0, adjuntosPurgados = 0;

    await db.transaction(() async {
      // 1. Notas tombstone vencidas: se van con TODOS sus adjuntos (cascada),
      //    su historial y la propia fila (en ese orden por las FK).
      final notas = await (db.select(db.notas)
            ..where((n) =>
                n.isDeleted.equals(true) &
                n.syncStatus.equalsValue(SyncStatus.SYNCED) &
                n.updatedAt.isSmallerThanValue(corte)))
          .get();

      for (final nota in notas) {
        final adjuntos = await (db.select(db.adjuntos)
              ..where((a) => a.notaUuid.equals(nota.uuid)))
            .get();
        for (final a in adjuntos) {
          if (a.rutaLocal != null) archivosABorrar.add(a.rutaLocal!);
        }
        await (db.delete(db.adjuntos)..where((a) => a.notaUuid.equals(nota.uuid))).go();
        await (db.delete(db.historialCambios)..where((h) => h.notaUuid.equals(nota.uuid)))
            .go();
        await (db.delete(db.notas)..where((n) => n.uuid.equals(nota.uuid))).go();
        notasPurgadas++;
        adjuntosPurgados += adjuntos.length;
      }

      // 2. Adjuntos tombstone huérfanos (su nota sigue viva).
      final adjuntos = await (db.select(db.adjuntos)
            ..where((a) =>
                a.isDeleted.equals(true) &
                a.syncStatus.equalsValue(SyncStatus.SYNCED) &
                a.updatedAt.isSmallerThanValue(corte)))
          .get();
      for (final a in adjuntos) {
        if (a.rutaLocal != null) archivosABorrar.add(a.rutaLocal!);
        await (db.delete(db.adjuntos)..where((x) => x.uuid.equals(a.uuid))).go();
        adjuntosPurgados++;
      }
    });

    // Borrado físico de los binarios, ya fuera de la transacción de la BD.
    for (final ruta in archivosABorrar) {
      final archivo = File(ruta);
      if (await archivo.exists()) await archivo.delete();
    }

    return ResumenPurga(notas: notasPurgadas, adjuntos: adjuntosPurgados);
  }
}

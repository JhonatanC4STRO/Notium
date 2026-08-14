import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../domain/enums.dart';
import '../../domain/errores.dart';
import '../db/app_database.dart';
import '../red/attachments_api.dart';
import '../red/auth_api.dart';
import 'identidad_dispositivo.dart';

/// Resumen de una pasada de subida de binarios.
class ResumenAdjuntos {
  const ResumenAdjuntos({required this.subidos, required this.errores});
  static const vacio = ResumenAdjuntos(subidos: 0, errores: 0);
  final int subidos;
  final int errores;
}

/// Sube y descarga los binarios de los adjuntos (tarea 3.5). El binario viaja
/// FUERA del lote de `/sync/push`: la sincronización mueve los metadatos, y
/// este servicio sube el archivo tras aceptarse esos metadatos.
class AttachmentService {
  AttachmentService({
    required this.db,
    required this.api,
    required this.identidad,
    required this.directorioAdjuntos,
  });

  final AppDatabase db;
  final AttachmentsApi api;
  final IdentidadDispositivo identidad;
  final Directory directorioAdjuntos;

  /// Sube los binarios pendientes: adjuntos cuyos metadatos ya están en el
  /// servidor (`sincronizado`), no eliminados, con archivo local y sin
  /// `url_remota` todavía. Un fallo de red DETIENE la pasada (se reintenta en
  /// el próximo ciclo); un `413` marca el adjunto como ERROR (CU-08) y sigue.
  Future<ResumenAdjuntos> subirPendientes() async {
    final deviceId = await identidad.obtener();
    final pendientes = await (db.select(db.adjuntos)
          ..where((a) =>
              a.sincronizado.equals(true) &
              a.isDeleted.equals(false) &
              a.rutaLocal.isNotNull() &
              a.urlRemota.isNull()))
        .get();

    var subidos = 0, errores = 0;
    for (final adjunto in pendientes) {
      final archivo = File(adjunto.rutaLocal!);
      if (!await archivo.exists()) {
        // El archivo local desapareció: no hay nada que subir.
        await _marcarError(adjunto.uuid);
        errores++;
        continue;
      }

      try {
        final remoto = await api.subir(
          uuid: adjunto.uuid,
          notaUuid: adjunto.notaUuid,
          deviceId: deviceId,
          archivo: archivo,
        );
        await (db.update(db.adjuntos)..where((a) => a.uuid.equals(adjunto.uuid)))
            .write(AdjuntosCompanion(urlRemota: Value(remoto.urlRemota)));
        subidos++;
      } on ApiException catch (e) {
        if (e.status == 413) {
          // Rechazo definitivo (CU-08): sin reintento automático.
          await _marcarError(adjunto.uuid);
          errores++;
        } else {
          rethrow; // 401 u otros suben al coordinador (refresh/backoff)
        }
      }
      // SinConexionException se propaga: el coordinador lo traduce a sinRed.
    }
    return ResumenAdjuntos(subidos: subidos, errores: errores);
  }

  /// Descarga bajo demanda el binario de un adjunto remoto (RNF-05). Si ya
  /// existe una copia local, la devuelve sin ir a la red; si no, la descarga,
  /// la guarda y persiste su `ruta_local`.
  Future<File> descargar(String uuid) async {
    final adjunto = await (db.select(db.adjuntos)..where((a) => a.uuid.equals(uuid)))
        .getSingleOrNull();
    if (adjunto == null) throw AdjuntoNoEncontrado(uuid);

    if (adjunto.rutaLocal != null && File(adjunto.rutaLocal!).existsSync()) {
      return File(adjunto.rutaLocal!);
    }

    final bytes = await api.descargar(uuid);
    await directorioAdjuntos.create(recursive: true);
    final destino = File(p.join(directorioAdjuntos.path, uuid));
    await destino.writeAsBytes(bytes);

    await (db.update(db.adjuntos)..where((a) => a.uuid.equals(uuid)))
        .write(AdjuntosCompanion(rutaLocal: Value(destino.path)));
    return destino;
  }

  Future<void> _marcarError(String uuid) =>
      (db.update(db.adjuntos)..where((a) => a.uuid.equals(uuid)))
          .write(const AdjuntosCompanion(syncStatus: Value(SyncStatus.ERROR)));
}

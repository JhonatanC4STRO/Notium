import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums.dart';
import '../db/app_database.dart';
import '../red/auth_api.dart';
import '../red/sync_api.dart';
import 'identidad_dispositivo.dart';

/// Resumen de un ciclo de push, para la orquestación (3.4) y los tests.
class ResumenPush {
  const ResumenPush({
    required this.enviadas,
    required this.aceptadas,
    required this.conflictos,
    required this.errores,
    required this.sinRed,
  });

  static const vacio =
      ResumenPush(enviadas: 0, aceptadas: 0, conflictos: 0, errores: 0, sinRed: false);

  final int enviadas;
  final int aceptadas;
  final int conflictos;
  final int errores;

  /// El lote no se pudo enviar por falta de red: todo sigue PENDING (CU-07).
  final bool sinRed;
}

/// Resumen de un ciclo de pull.
class ResumenPull {
  const ResumenPull({
    required this.aplicados,
    required this.tombstones,
    required this.omitidosPendientes,
    required this.paginas,
    required this.sinRed,
  });

  static const vacio = ResumenPull(
      aplicados: 0, tombstones: 0, omitidosPendientes: 0, paginas: 0, sinRed: false);

  final int aplicados;
  final int tombstones;

  /// Cambios remotos que NO se aplicaron por haber un cambio local PENDING
  /// para el mismo uuid (el push posterior resuelve el conflicto).
  final int omitidosPendientes;
  final int paginas;
  final bool sinRed;
}

/// Efecto de aplicar un cambio remoto individual.
enum _Efecto { aplicado, tombstone, omitidoPendiente, ninguno }

/// Subida de cambios locales (tarea 3.2). Puro Dart, independiente de
/// `workmanager` (la orquestación en segundo plano es la 3.4): consulta los
/// registros PENDING, arma el lote de `SyncPushRequest` y procesa el array
/// de resultados según la sección 5.5 y el diagrama de CU-05.
class SyncService {
  SyncService({
    required this.db,
    required this.api,
    required this.identidad,
  });

  final AppDatabase db;
  final SyncApi api;
  final IdentidadDispositivo identidad;
  static const _uuid = Uuid();

  Future<ResumenPush> push() async {
    final deviceId = await identidad.obtener();
    final (pendientes, resolucionesLocales) = await _recolectar();

    // Tombstones que nunca llegaron al servidor: no hay nada que propagar,
    // se cierran localmente (los purgará el job de la fase 3.5).
    if (resolucionesLocales.isNotEmpty) {
      await _cerrarLocalmente(resolucionesLocales);
    }

    if (pendientes.isEmpty) return ResumenPush.vacio;

    final RespuestaPush respuesta;
    try {
      respuesta = await api.push(
        deviceId: deviceId,
        operaciones: pendientes.map((p) => p.operacion).toList(),
      );
    } on SinConexionException {
      // CU-07: fallo de red → nada cambia de estado, siguen PENDING.
      return ResumenPush(
        enviadas: pendientes.length,
        aceptadas: 0,
        conflictos: 0,
        errores: 0,
        sinRed: true,
      );
    }

    return _aplicarResultados(pendientes, respuesta.resultados);
  }

  // =========================================================================
  // PULL (tarea 3.3): descarga de cambios remotos.
  // =========================================================================

  /// Descarga y aplica los cambios del servidor posteriores al cursor
  /// persistido, paginando mientras `hay_mas`. Cada página se aplica en una
  /// transacción que también avanza el cursor: si la red falla entre páginas,
  /// las ya aplicadas quedan firmes y el siguiente pull retoma desde ahí.
  Future<ResumenPull> pull(String usuarioUuid) async {
    final deviceId = await identidad.obtener();
    var cursor = await _leerCursor(usuarioUuid);

    var aplicados = 0, tombstones = 0, omitidos = 0, paginas = 0;
    var hayMas = true;

    while (hayMas) {
      final RespuestaPull pagina;
      try {
        pagina = await api.pull(desde: cursor, deviceId: deviceId, limite: 100);
      } on SinConexionException {
        return ResumenPull(
          aplicados: aplicados,
          tombstones: tombstones,
          omitidosPendientes: omitidos,
          paginas: paginas,
          sinRed: true,
        );
      }

      await db.transaction(() async {
        for (final cambio in pagina.cambios) {
          switch (await _aplicarCambioRemoto(usuarioUuid, cambio)) {
            case _Efecto.aplicado:
              aplicados++;
            case _Efecto.tombstone:
              tombstones++;
            case _Efecto.omitidoPendiente:
              omitidos++;
            case _Efecto.ninguno:
              break;
          }
        }
        // El cursor avanza SOLO dentro de la transacción de la página.
        await _guardarCursor(usuarioUuid, pagina.timestampServidor);
      });

      cursor = pagina.timestampServidor;
      hayMas = pagina.hayMas;
      paginas++;
    }

    return ResumenPull(
      aplicados: aplicados,
      tombstones: tombstones,
      omitidosPendientes: omitidos,
      paginas: paginas,
      sinRed: false,
    );
  }

  Future<_Efecto> _aplicarCambioRemoto(String usuarioUuid, CambioServidor c) {
    return c.entidad == 'NOTA'
        ? _aplicarNotaRemota(usuarioUuid, c)
        : _aplicarAdjuntoRemoto(usuarioUuid, c);
  }

  Future<_Efecto> _aplicarNotaRemota(String usuarioUuid, CambioServidor c) async {
    final local = await (db.select(db.notas)..where((n) => n.uuid.equals(c.uuid)))
        .getSingleOrNull();

    // Regla local (3.3): no pisar un cambio local sin sincronizar. El push
    // posterior enviará el cambio y el servidor resolverá el conflicto.
    if (local != null && local.syncStatus == SyncStatus.PENDING) {
      return _Efecto.omitidoPendiente;
    }

    final updatedAt = DateTime.parse(c.updatedAt).toUtc();

    if (c.isDeleted) {
      if (local == null) return _Efecto.ninguno; // nada local que ocultar
      await (db.update(db.notas)..where((n) => n.uuid.equals(c.uuid))).write(
        NotasCompanion(
          isDeleted: const Value(true),
          version: Value(c.version),
          updatedAt: Value(updatedAt),
          deviceId: Value(c.deviceId),
          syncStatus: const Value(SyncStatus.SYNCED),
          sincronizado: const Value(true),
        ),
      );
      await _historialRemoto(c.uuid, 'DELETE', null);
      return _Efecto.tombstone;
    }

    final titulo = c.payload['titulo'] as String? ?? local?.titulo ?? '';
    final contenido = c.payload['contenido'] as String?;

    if (local == null) {
      final createdAt = c.payload['created_at'] is String
          ? DateTime.parse(c.payload['created_at'] as String).toUtc()
          : updatedAt;
      await db.into(db.notas).insert(NotasCompanion.insert(
            uuid: c.uuid,
            usuarioUuid: usuarioUuid,
            titulo: titulo,
            contenido: Value(contenido),
            createdAt: createdAt,
            updatedAt: updatedAt,
            version: Value(c.version),
            deviceId: Value(c.deviceId),
            syncStatus: const Value(SyncStatus.SYNCED),
            sincronizado: const Value(true),
          ));
    } else {
      await (db.update(db.notas)..where((n) => n.uuid.equals(c.uuid))).write(
        NotasCompanion(
          titulo: Value(titulo),
          contenido: Value(contenido),
          updatedAt: Value(updatedAt),
          version: Value(c.version),
          deviceId: Value(c.deviceId),
          isDeleted: const Value(false),
          syncStatus: const Value(SyncStatus.SYNCED),
          sincronizado: const Value(true),
        ),
      );
    }
    await _historialRemoto(c.uuid, c.operacion, {'titulo': titulo, 'contenido': contenido});
    return _Efecto.aplicado;
  }

  Future<_Efecto> _aplicarAdjuntoRemoto(String usuarioUuid, CambioServidor c) async {
    final local = await (db.select(db.adjuntos)..where((a) => a.uuid.equals(c.uuid)))
        .getSingleOrNull();

    if (local != null && local.syncStatus == SyncStatus.PENDING) {
      return _Efecto.omitidoPendiente;
    }

    final notaUuid = local?.notaUuid ?? c.payload['nota_uuid'] as String?;
    if (notaUuid == null) return _Efecto.ninguno;

    // El adjunto referencia una nota (FK): si aún no llegó localmente, se
    // omite; volverá en un pull posterior cuando su nota exista.
    final notaExiste = await (db.select(db.notas)..where((n) => n.uuid.equals(notaUuid)))
            .getSingleOrNull() !=
        null;
    if (local == null && !notaExiste) return _Efecto.ninguno;

    final updatedAt = DateTime.parse(c.updatedAt).toUtc();

    if (c.isDeleted) {
      if (local == null) return _Efecto.ninguno;
      await (db.update(db.adjuntos)..where((a) => a.uuid.equals(c.uuid))).write(
        AdjuntosCompanion(
          isDeleted: const Value(true),
          version: Value(c.version),
          updatedAt: Value(updatedAt),
          deviceId: Value(c.deviceId),
          syncStatus: const Value(SyncStatus.SYNCED),
          sincronizado: const Value(true),
        ),
      );
      await _historialRemoto(notaUuid, 'ADJUNTO_DELETE', null);
      return _Efecto.tombstone;
    }

    final rutaLocal = c.payload['ruta_local'] as String?;
    final urlRemota = c.payload['url_remota'] as String?;

    if (local == null) {
      await db.into(db.adjuntos).insert(AdjuntosCompanion.insert(
            uuid: c.uuid,
            notaUuid: notaUuid,
            rutaLocal: Value(rutaLocal),
            urlRemota: Value(urlRemota),
            createdAt: updatedAt,
            updatedAt: updatedAt,
            version: Value(c.version),
            deviceId: Value(c.deviceId),
            syncStatus: const Value(SyncStatus.SYNCED),
            sincronizado: const Value(true),
          ));
    } else {
      await (db.update(db.adjuntos)..where((a) => a.uuid.equals(c.uuid))).write(
        AdjuntosCompanion(
          urlRemota: Value(urlRemota),
          updatedAt: Value(updatedAt),
          version: Value(c.version),
          deviceId: Value(c.deviceId),
          isDeleted: const Value(false),
          syncStatus: const Value(SyncStatus.SYNCED),
          sincronizado: const Value(true),
        ),
      );
    }
    await _historialRemoto(notaUuid, 'ADJUNTO_${c.operacion}', {'url_remota': urlRemota});
    return _Efecto.aplicado;
  }

  Future<void> _historialRemoto(
    String notaUuid,
    String tipo,
    Map<String, Object?>? valorNuevo,
  ) {
    return db.into(db.historialCambios).insert(
          HistorialCambiosCompanion.insert(
            uuid: _uuid.v4(),
            notaUuid: notaUuid,
            tipoCambio: tipo,
            origenCambio: OrigenCambio.REMOTO,
            fecha: DateTime.now().toUtc(),
            valorNuevo:
                Value(valorNuevo == null ? null : jsonEncode(valorNuevo)),
          ),
        );
  }

  static const _epoca = '1970-01-01T00:00:00.000Z';

  String _claveCursor(String usuarioUuid) => 'pull_cursor:$usuarioUuid';

  Future<String> _leerCursor(String usuarioUuid) async {
    final fila = await (db.select(db.syncMeta)
          ..where((m) => m.clave.equals(_claveCursor(usuarioUuid))))
        .getSingleOrNull();
    return fila?.valor ?? _epoca;
  }

  Future<void> _guardarCursor(String usuarioUuid, String timestampServidor) {
    return db.into(db.syncMeta).insertOnConflictUpdate(
          SyncMetaCompanion.insert(
            clave: _claveCursor(usuarioUuid),
            valor: timestampServidor,
          ),
        );
  }

  // -------------------------------------------------------------------------
  // Recolección de PENDING → operaciones del lote (orden: notas y luego sus
  // adjuntos, para que una nota se cree antes que su adjunto en el mismo lote).
  // -------------------------------------------------------------------------

  Future<(List<_Pendiente>, List<_ResolucionLocal>)> _recolectar() async {
    final pendientes = <_Pendiente>[];
    final locales = <_ResolucionLocal>[];

    final notas = await (db.select(db.notas)
          ..where((n) => n.syncStatus.equalsValue(SyncStatus.PENDING))
          ..orderBy([(n) => OrderingTerm.asc(n.createdAt)]))
        .get();
    for (final n in notas) {
      if (n.isDeleted && !n.sincronizado) {
        locales.add(const _ResolucionLocal('NOTA').conUuid(n.uuid));
        continue;
      }
      final (operacion, payload) = _opNota(n);
      pendientes.add(_Pendiente(
        entidad: 'NOTA',
        uuid: n.uuid,
        notaUuidHistorial: n.uuid,
        cambioLocal: {'titulo': n.titulo, 'contenido': n.contenido},
        operacion: OperacionSync(
          uuid: n.uuid,
          entidad: 'NOTA',
          operacion: operacion,
          payload: payload,
          updatedAt: n.updatedAt.toIso8601String(),
          version: n.version,
        ),
      ));
    }

    final adjuntos = await (db.select(db.adjuntos)
          ..where((a) => a.syncStatus.equalsValue(SyncStatus.PENDING))
          ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]))
        .get();
    for (final a in adjuntos) {
      if (a.isDeleted && !a.sincronizado) {
        locales.add(const _ResolucionLocal('ADJUNTO').conUuid(a.uuid));
        continue;
      }
      final (operacion, payload) = _opAdjunto(a);
      pendientes.add(_Pendiente(
        entidad: 'ADJUNTO',
        uuid: a.uuid,
        notaUuidHistorial: a.notaUuid,
        cambioLocal: {'ruta_local': a.rutaLocal},
        operacion: OperacionSync(
          uuid: a.uuid,
          entidad: 'ADJUNTO',
          operacion: operacion,
          payload: payload,
          updatedAt: a.updatedAt.toIso8601String(),
          version: a.version,
        ),
      ));
    }

    return (pendientes, locales);
  }

  (String, Map<String, Object?>) _opNota(Nota n) {
    if (n.isDeleted) return ('DELETE', const {});
    if (!n.sincronizado) {
      return (
        'CREATE',
        {
          'titulo': n.titulo,
          'contenido': n.contenido,
          'created_at': n.createdAt.toIso8601String(),
        }
      );
    }
    return ('UPDATE', {'titulo': n.titulo, 'contenido': n.contenido});
  }

  (String, Map<String, Object?>) _opAdjunto(Adjunto a) {
    if (a.isDeleted) return ('DELETE', const {});
    if (!a.sincronizado) {
      return ('CREATE', {'nota_uuid': a.notaUuid, 'ruta_local': a.rutaLocal});
    }
    return ('UPDATE', {'ruta_local': a.rutaLocal});
  }

  // -------------------------------------------------------------------------
  // Aplicación de resultados. Todo en UNA transacción: o converge el lote
  // completo o no cambia nada (atomicidad de CU-05 fase 3).
  // -------------------------------------------------------------------------

  Future<ResumenPush> _aplicarResultados(
    List<_Pendiente> pendientes,
    List<ResultadoSync> resultados,
  ) async {
    final porUuid = {for (final p in pendientes) p.uuid: p};
    var aceptadas = 0, conflictos = 0, errores = 0;

    await db.transaction(() async {
      for (final r in resultados) {
        final p = porUuid[r.uuid];
        if (p == null) continue; // defensivo: el servidor no debería inventarlos
        switch (r.estado) {
          case 'ACCEPTED':
            await _marcarAceptado(p, r);
            aceptadas++;
          case 'CONFLICT':
            await _resolverConflicto(p, r);
            conflictos++;
          case 'ERROR':
            await _marcarError(p, r);
            errores++;
        }
      }
    });

    return ResumenPush(
      enviadas: pendientes.length,
      aceptadas: aceptadas,
      conflictos: conflictos,
      errores: errores,
      sinRed: false,
    );
  }

  /// ACCEPTED → SYNCED, adoptando la versión autoritativa del servidor.
  Future<void> _marcarAceptado(_Pendiente p, ResultadoSync r) {
    final version = r.versionServidor ?? p.operacion.version;
    if (p.entidad == 'NOTA') {
      return (db.update(db.notas)..where((n) => n.uuid.equals(p.uuid))).write(
        NotasCompanion(
          syncStatus: const Value(SyncStatus.SYNCED),
          version: Value(version),
          sincronizado: const Value(true),
          syncError: const Value(null), // se sincronizó: ya no hay error
        ),
      );
    }
    return (db.update(db.adjuntos)..where((a) => a.uuid.equals(p.uuid))).write(
      AdjuntosCompanion(
        syncStatus: const Value(SyncStatus.SYNCED),
        version: Value(version),
        sincronizado: const Value(true),
        syncError: const Value(null),
      ),
    );
  }

  /// CONFLICT (CU-05 fase 3): mi cambio local perdió el LWW. Se registra en
  /// el historial como CONFLICTO_DESCARTADO y se sobrescribe con el estado
  /// autoritativo del servidor. Ya estamos dentro de la transacción del lote.
  Future<void> _resolverConflicto(_Pendiente p, ResultadoSync r) async {
    final servidor = r.payloadServidor ?? const {};
    final version = r.versionServidor ?? p.operacion.version;

    await db.into(db.historialCambios).insert(
          HistorialCambiosCompanion.insert(
            uuid: _uuid.v4(),
            notaUuid: p.notaUuidHistorial,
            tipoCambio: 'CONFLICTO',
            origenCambio: OrigenCambio.CONFLICTO_DESCARTADO,
            fecha: DateTime.now().toUtc(),
            // valorAnterior = mi cambio descartado; valorNuevo = lo que quedó.
            valorAnterior: Value(jsonEncode(p.cambioLocal)),
            valorNuevo: Value(jsonEncode(servidor)),
          ),
        );

    if (p.entidad == 'NOTA') {
      await (db.update(db.notas)..where((n) => n.uuid.equals(p.uuid))).write(
        NotasCompanion(
          titulo: _txt(servidor, 'titulo') ?? const Value.absent(),
          contenido: Value(servidor['contenido'] as String?),
          updatedAt: _fecha(servidor) ?? const Value.absent(),
          isDeleted: _bool(servidor, 'is_deleted') ?? const Value.absent(),
          version: Value(version),
          syncStatus: const Value(SyncStatus.SYNCED),
          sincronizado: const Value(true),
        ),
      );
    } else {
      await (db.update(db.adjuntos)..where((a) => a.uuid.equals(p.uuid))).write(
        AdjuntosCompanion(
          rutaLocal: Value(servidor['ruta_local'] as String?),
          urlRemota: Value(servidor['url_remota'] as String?),
          updatedAt: _fecha(servidor) ?? const Value.absent(),
          isDeleted: _bool(servidor, 'is_deleted') ?? const Value.absent(),
          version: Value(version),
          syncStatus: const Value(SyncStatus.SYNCED),
          sincronizado: const Value(true),
        ),
      );
    }
  }

  /// ERROR → rechazo definitivo del servidor: sin reintento automático; la
  /// salida exige que el usuario corrija el dato (sección 5.2). Se guarda el
  /// motivo para poder mostrárselo (tarea 4.2, RF-04).
  Future<void> _marcarError(_Pendiente p, ResultadoSync r) {
    final motivo = r.error?['mensaje'] as String? ??
        r.error?['codigo'] as String? ??
        'El servidor rechazó el cambio.';
    if (p.entidad == 'NOTA') {
      return (db.update(db.notas)..where((n) => n.uuid.equals(p.uuid))).write(
        NotasCompanion(
          syncStatus: const Value(SyncStatus.ERROR),
          syncError: Value(motivo),
        ),
      );
    }
    return (db.update(db.adjuntos)..where((a) => a.uuid.equals(p.uuid))).write(
      AdjuntosCompanion(
        syncStatus: const Value(SyncStatus.ERROR),
        syncError: Value(motivo),
      ),
    );
  }

  Future<void> _cerrarLocalmente(List<_ResolucionLocal> locales) {
    return db.transaction(() async {
      for (final l in locales) {
        if (l.entidad == 'NOTA') {
          await (db.update(db.notas)..where((n) => n.uuid.equals(l.uuid)))
              .write(const NotasCompanion(syncStatus: Value(SyncStatus.SYNCED)));
        } else {
          await (db.update(db.adjuntos)..where((a) => a.uuid.equals(l.uuid)))
              .write(const AdjuntosCompanion(syncStatus: Value(SyncStatus.SYNCED)));
        }
      }
    });
  }

  Value<String>? _txt(Map<String, Object?> m, String k) =>
      m[k] is String ? Value(m[k] as String) : null;

  Value<bool>? _bool(Map<String, Object?> m, String k) =>
      m[k] is bool ? Value(m[k] as bool) : null;

  Value<DateTime>? _fecha(Map<String, Object?> m) => m['updated_at'] is String
      ? Value(DateTime.parse(m['updated_at'] as String).toUtc())
      : null;
}

/// Operación a enviar + metadatos para aplicar su resultado.
class _Pendiente {
  const _Pendiente({
    required this.entidad,
    required this.uuid,
    required this.notaUuidHistorial,
    required this.cambioLocal,
    required this.operacion,
  });

  final String entidad;
  final String uuid;
  final String notaUuidHistorial;
  final Map<String, Object?> cambioLocal;
  final OperacionSync operacion;
}

/// Tombstone que nunca se sincronizó: se cierra sin tocar la red.
class _ResolucionLocal {
  const _ResolucionLocal(this.entidad) : uuid = '';
  const _ResolucionLocal._(this.entidad, this.uuid);

  final String entidad;
  final String uuid;

  _ResolucionLocal conUuid(String uuid) => _ResolucionLocal._(entidad, uuid);
}

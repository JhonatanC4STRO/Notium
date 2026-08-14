import 'package:drift/drift.dart';

import '../../domain/enums.dart';

/// Tablas Drift del modelo local (tarea 2.2), replicando la sección 4.1 con
/// los metadatos de sincronización de la 4.2. Los `uuid` los genera el
/// cliente (UUID v4, sección 5.1); las fechas se guardan en UTC.
///
/// Drift genera las clases de datos (`Nota`, `Adjunto`, `HistorialCambio`,
/// `Usuario`), que son los modelos de dominio que consumen las capas
/// superiores.

/// Metadatos comunes a toda entidad sincronizable (sección 4.2).
mixin MetadatosSync on Table {
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// `PENDING` al crear/editar/borrar localmente, en la MISMA transacción
  /// (sección 5.2): el propio flag actúa como cola de la SyncTask.
  TextColumn get syncStatus =>
      textEnum<SyncStatus>().withDefault(const Constant('PENDING'))();

  /// Tombstone (sección 5.4): nunca se borra físicamente hasta confirmar
  /// la propagación.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// Última versión autoritativa conocida del servidor; el cliente solo la
  /// inicializa en 1 al crear (sección 6.3).
  IntColumn get version => integer().withDefault(const Constant(1))();

  TextColumn get deviceId => text().nullable()();

  /// Verdadero cuando el servidor ya confirmó la existencia del registro
  /// (tras el primer ACCEPTED). Distingue una CREATE nunca sincronizada de
  /// una UPDATE ya sincronizada: ambas pueden tener `version = 1`, así que
  /// `version` sola no basta para elegir la operación del lote (sección 5.5).
  BoolColumn get sincronizado => boolean().withDefault(const Constant(false))();

  /// Motivo del rechazo cuando `sync_status = ERROR` (tarea 4.2, RF-04): el
  /// usuario necesita saber POR QUÉ el servidor rechazó el cambio para poder
  /// corregirlo. Se limpia al corregir (ERROR → PENDING) o al sincronizar.
  TextColumn get syncError => text().nullable()();
}

@DataClassName('Nota')
class Notas extends Table with MetadatosSync {
  TextColumn get uuid => text()();
  TextColumn get usuarioUuid => text()();
  TextColumn get titulo => text()();
  TextColumn get contenido => text().nullable()();

  @override
  Set<Column> get primaryKey => {uuid};
}

@DataClassName('Adjunto')
class Adjuntos extends Table with MetadatosSync {
  TextColumn get uuid => text()();
  TextColumn get notaUuid => text().references(Notas, #uuid)();

  /// Ruta del archivo en el almacenamiento de la app (metadato local).
  TextColumn get rutaLocal => text().nullable()();

  /// URL asignada por el servidor tras subir el binario (fase 3.5).
  TextColumn get urlRemota => text().nullable()();

  @override
  Set<Column> get primaryKey => {uuid};
}

@DataClassName('HistorialCambio')
class HistorialCambios extends Table {
  TextColumn get uuid => text()();
  TextColumn get notaUuid => text().references(Notas, #uuid)();
  TextColumn get tipoCambio => text()();
  TextColumn get origenCambio => textEnum<OrigenCambio>()();
  DateTimeColumn get fecha => dateTime()();
  TextColumn get dispositivoOrigen => text().nullable()();

  /// Estados serializados (JSON). En conflictos descartados, `valorNuevo`
  /// es el valor que NO se aplicó (mismo criterio que el backend).
  TextColumn get valorAnterior => text().nullable()();
  TextColumn get valorNuevo => text().nullable()();

  @override
  Set<Column> get primaryKey => {uuid};
}

/// Caché local del usuario autenticado (sección 4.1). Los tokens NO van
/// aquí: viven en flutter_secure_storage (sección 8).
@DataClassName('Usuario')
class Usuarios extends Table {
  TextColumn get uuid => text()();
  TextColumn get nombre => text()();
  TextColumn get email => text()();

  @override
  Set<Column> get primaryKey => {uuid};
}

/// Metadatos de sincronización clave/valor (tarea 3.3). Guarda el cursor de
/// `/sync/pull` (`timestamp_servidor` de la última página aplicada) por
/// usuario. Vive en la BD para poder actualizarlo en la MISMA transacción en
/// que se aplica la página: el cursor solo avanza si la página se aplicó.
@DataClassName('SyncMetaDato')
class SyncMeta extends Table {
  TextColumn get clave => text()();
  TextColumn get valor => text()();

  @override
  Set<Column> get primaryKey => {clave};
}

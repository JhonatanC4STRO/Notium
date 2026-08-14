// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $NotasTable extends Notas with TableInfo<$NotasTable, Nota> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('PENDING'),
      ).withConverter<SyncStatus>($NotasTable.$convertersyncStatus);
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sincronizadoMeta = const VerificationMeta(
    'sincronizado',
  );
  @override
  late final GeneratedColumn<bool> sincronizado = GeneratedColumn<bool>(
    'sincronizado',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sincronizado" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usuarioUuidMeta = const VerificationMeta(
    'usuarioUuid',
  );
  @override
  late final GeneratedColumn<String> usuarioUuid = GeneratedColumn<String>(
    'usuario_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tituloMeta = const VerificationMeta('titulo');
  @override
  late final GeneratedColumn<String> titulo = GeneratedColumn<String>(
    'titulo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contenidoMeta = const VerificationMeta(
    'contenido',
  );
  @override
  late final GeneratedColumn<String> contenido = GeneratedColumn<String>(
    'contenido',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    updatedAt,
    syncStatus,
    isDeleted,
    version,
    deviceId,
    sincronizado,
    syncError,
    uuid,
    usuarioUuid,
    titulo,
    contenido,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Nota> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('sincronizado')) {
      context.handle(
        _sincronizadoMeta,
        sincronizado.isAcceptableOrUnknown(
          data['sincronizado']!,
          _sincronizadoMeta,
        ),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('usuario_uuid')) {
      context.handle(
        _usuarioUuidMeta,
        usuarioUuid.isAcceptableOrUnknown(
          data['usuario_uuid']!,
          _usuarioUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_usuarioUuidMeta);
    }
    if (data.containsKey('titulo')) {
      context.handle(
        _tituloMeta,
        titulo.isAcceptableOrUnknown(data['titulo']!, _tituloMeta),
      );
    } else if (isInserting) {
      context.missing(_tituloMeta);
    }
    if (data.containsKey('contenido')) {
      context.handle(
        _contenidoMeta,
        contenido.isAcceptableOrUnknown(data['contenido']!, _contenidoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  Nota map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Nota(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: $NotasTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      sincronizado: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sincronizado'],
      )!,
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      usuarioUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usuario_uuid'],
      )!,
      titulo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}titulo'],
      )!,
      contenido: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contenido'],
      ),
    );
  }

  @override
  $NotasTable createAlias(String alias) {
    return $NotasTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatus, String, String> $convertersyncStatus =
      const EnumNameConverter<SyncStatus>(SyncStatus.values);
}

class Nota extends DataClass implements Insertable<Nota> {
  final DateTime createdAt;
  final DateTime updatedAt;

  /// `PENDING` al crear/editar/borrar localmente, en la MISMA transacción
  /// (sección 5.2): el propio flag actúa como cola de la SyncTask.
  final SyncStatus syncStatus;

  /// Tombstone (sección 5.4): nunca se borra físicamente hasta confirmar
  /// la propagación.
  final bool isDeleted;

  /// Última versión autoritativa conocida del servidor; el cliente solo la
  /// inicializa en 1 al crear (sección 6.3).
  final int version;
  final String? deviceId;

  /// Verdadero cuando el servidor ya confirmó la existencia del registro
  /// (tras el primer ACCEPTED). Distingue una CREATE nunca sincronizada de
  /// una UPDATE ya sincronizada: ambas pueden tener `version = 1`, así que
  /// `version` sola no basta para elegir la operación del lote (sección 5.5).
  final bool sincronizado;

  /// Motivo del rechazo cuando `sync_status = ERROR` (tarea 4.2, RF-04): el
  /// usuario necesita saber POR QUÉ el servidor rechazó el cambio para poder
  /// corregirlo. Se limpia al corregir (ERROR → PENDING) o al sincronizar.
  final String? syncError;
  final String uuid;
  final String usuarioUuid;
  final String titulo;
  final String? contenido;
  const Nota({
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    required this.isDeleted,
    required this.version,
    this.deviceId,
    required this.sincronizado,
    this.syncError,
    required this.uuid,
    required this.usuarioUuid,
    required this.titulo,
    this.contenido,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_status'] = Variable<String>(
        $NotasTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['sincronizado'] = Variable<bool>(sincronizado);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['uuid'] = Variable<String>(uuid);
    map['usuario_uuid'] = Variable<String>(usuarioUuid);
    map['titulo'] = Variable<String>(titulo);
    if (!nullToAbsent || contenido != null) {
      map['contenido'] = Variable<String>(contenido);
    }
    return map;
  }

  NotasCompanion toCompanion(bool nullToAbsent) {
    return NotasCompanion(
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      isDeleted: Value(isDeleted),
      version: Value(version),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      sincronizado: Value(sincronizado),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      uuid: Value(uuid),
      usuarioUuid: Value(usuarioUuid),
      titulo: Value(titulo),
      contenido: contenido == null && nullToAbsent
          ? const Value.absent()
          : Value(contenido),
    );
  }

  factory Nota.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Nota(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: $NotasTable.$convertersyncStatus.fromJson(
        serializer.fromJson<String>(json['syncStatus']),
      ),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      version: serializer.fromJson<int>(json['version']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      sincronizado: serializer.fromJson<bool>(json['sincronizado']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      uuid: serializer.fromJson<String>(json['uuid']),
      usuarioUuid: serializer.fromJson<String>(json['usuarioUuid']),
      titulo: serializer.fromJson<String>(json['titulo']),
      contenido: serializer.fromJson<String?>(json['contenido']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<String>(
        $NotasTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'version': serializer.toJson<int>(version),
      'deviceId': serializer.toJson<String?>(deviceId),
      'sincronizado': serializer.toJson<bool>(sincronizado),
      'syncError': serializer.toJson<String?>(syncError),
      'uuid': serializer.toJson<String>(uuid),
      'usuarioUuid': serializer.toJson<String>(usuarioUuid),
      'titulo': serializer.toJson<String>(titulo),
      'contenido': serializer.toJson<String?>(contenido),
    };
  }

  Nota copyWith({
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    bool? isDeleted,
    int? version,
    Value<String?> deviceId = const Value.absent(),
    bool? sincronizado,
    Value<String?> syncError = const Value.absent(),
    String? uuid,
    String? usuarioUuid,
    String? titulo,
    Value<String?> contenido = const Value.absent(),
  }) => Nota(
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    isDeleted: isDeleted ?? this.isDeleted,
    version: version ?? this.version,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    sincronizado: sincronizado ?? this.sincronizado,
    syncError: syncError.present ? syncError.value : this.syncError,
    uuid: uuid ?? this.uuid,
    usuarioUuid: usuarioUuid ?? this.usuarioUuid,
    titulo: titulo ?? this.titulo,
    contenido: contenido.present ? contenido.value : this.contenido,
  );
  Nota copyWithCompanion(NotasCompanion data) {
    return Nota(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      version: data.version.present ? data.version.value : this.version,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      sincronizado: data.sincronizado.present
          ? data.sincronizado.value
          : this.sincronizado,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      usuarioUuid: data.usuarioUuid.present
          ? data.usuarioUuid.value
          : this.usuarioUuid,
      titulo: data.titulo.present ? data.titulo.value : this.titulo,
      contenido: data.contenido.present ? data.contenido.value : this.contenido,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Nota(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('version: $version, ')
          ..write('deviceId: $deviceId, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('syncError: $syncError, ')
          ..write('uuid: $uuid, ')
          ..write('usuarioUuid: $usuarioUuid, ')
          ..write('titulo: $titulo, ')
          ..write('contenido: $contenido')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    updatedAt,
    syncStatus,
    isDeleted,
    version,
    deviceId,
    sincronizado,
    syncError,
    uuid,
    usuarioUuid,
    titulo,
    contenido,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Nota &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.isDeleted == this.isDeleted &&
          other.version == this.version &&
          other.deviceId == this.deviceId &&
          other.sincronizado == this.sincronizado &&
          other.syncError == this.syncError &&
          other.uuid == this.uuid &&
          other.usuarioUuid == this.usuarioUuid &&
          other.titulo == this.titulo &&
          other.contenido == this.contenido);
}

class NotasCompanion extends UpdateCompanion<Nota> {
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<SyncStatus> syncStatus;
  final Value<bool> isDeleted;
  final Value<int> version;
  final Value<String?> deviceId;
  final Value<bool> sincronizado;
  final Value<String?> syncError;
  final Value<String> uuid;
  final Value<String> usuarioUuid;
  final Value<String> titulo;
  final Value<String?> contenido;
  final Value<int> rowid;
  const NotasCompanion({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.version = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.syncError = const Value.absent(),
    this.uuid = const Value.absent(),
    this.usuarioUuid = const Value.absent(),
    this.titulo = const Value.absent(),
    this.contenido = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotasCompanion.insert({
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncStatus = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.version = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.syncError = const Value.absent(),
    required String uuid,
    required String usuarioUuid,
    required String titulo,
    this.contenido = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       uuid = Value(uuid),
       usuarioUuid = Value(usuarioUuid),
       titulo = Value(titulo);
  static Insertable<Nota> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncStatus,
    Expression<bool>? isDeleted,
    Expression<int>? version,
    Expression<String>? deviceId,
    Expression<bool>? sincronizado,
    Expression<String>? syncError,
    Expression<String>? uuid,
    Expression<String>? usuarioUuid,
    Expression<String>? titulo,
    Expression<String>? contenido,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (version != null) 'version': version,
      if (deviceId != null) 'device_id': deviceId,
      if (sincronizado != null) 'sincronizado': sincronizado,
      if (syncError != null) 'sync_error': syncError,
      if (uuid != null) 'uuid': uuid,
      if (usuarioUuid != null) 'usuario_uuid': usuarioUuid,
      if (titulo != null) 'titulo': titulo,
      if (contenido != null) 'contenido': contenido,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotasCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<SyncStatus>? syncStatus,
    Value<bool>? isDeleted,
    Value<int>? version,
    Value<String?>? deviceId,
    Value<bool>? sincronizado,
    Value<String?>? syncError,
    Value<String>? uuid,
    Value<String>? usuarioUuid,
    Value<String>? titulo,
    Value<String?>? contenido,
    Value<int>? rowid,
  }) {
    return NotasCompanion(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? this.version,
      deviceId: deviceId ?? this.deviceId,
      sincronizado: sincronizado ?? this.sincronizado,
      syncError: syncError ?? this.syncError,
      uuid: uuid ?? this.uuid,
      usuarioUuid: usuarioUuid ?? this.usuarioUuid,
      titulo: titulo ?? this.titulo,
      contenido: contenido ?? this.contenido,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $NotasTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (sincronizado.present) {
      map['sincronizado'] = Variable<bool>(sincronizado.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (usuarioUuid.present) {
      map['usuario_uuid'] = Variable<String>(usuarioUuid.value);
    }
    if (titulo.present) {
      map['titulo'] = Variable<String>(titulo.value);
    }
    if (contenido.present) {
      map['contenido'] = Variable<String>(contenido.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotasCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('version: $version, ')
          ..write('deviceId: $deviceId, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('syncError: $syncError, ')
          ..write('uuid: $uuid, ')
          ..write('usuarioUuid: $usuarioUuid, ')
          ..write('titulo: $titulo, ')
          ..write('contenido: $contenido, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AdjuntosTable extends Adjuntos with TableInfo<$AdjuntosTable, Adjunto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdjuntosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('PENDING'),
      ).withConverter<SyncStatus>($AdjuntosTable.$convertersyncStatus);
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sincronizadoMeta = const VerificationMeta(
    'sincronizado',
  );
  @override
  late final GeneratedColumn<bool> sincronizado = GeneratedColumn<bool>(
    'sincronizado',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sincronizado" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notaUuidMeta = const VerificationMeta(
    'notaUuid',
  );
  @override
  late final GeneratedColumn<String> notaUuid = GeneratedColumn<String>(
    'nota_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES notas (uuid)',
    ),
  );
  static const VerificationMeta _rutaLocalMeta = const VerificationMeta(
    'rutaLocal',
  );
  @override
  late final GeneratedColumn<String> rutaLocal = GeneratedColumn<String>(
    'ruta_local',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urlRemotaMeta = const VerificationMeta(
    'urlRemota',
  );
  @override
  late final GeneratedColumn<String> urlRemota = GeneratedColumn<String>(
    'url_remota',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    updatedAt,
    syncStatus,
    isDeleted,
    version,
    deviceId,
    sincronizado,
    syncError,
    uuid,
    notaUuid,
    rutaLocal,
    urlRemota,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'adjuntos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Adjunto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('sincronizado')) {
      context.handle(
        _sincronizadoMeta,
        sincronizado.isAcceptableOrUnknown(
          data['sincronizado']!,
          _sincronizadoMeta,
        ),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('nota_uuid')) {
      context.handle(
        _notaUuidMeta,
        notaUuid.isAcceptableOrUnknown(data['nota_uuid']!, _notaUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_notaUuidMeta);
    }
    if (data.containsKey('ruta_local')) {
      context.handle(
        _rutaLocalMeta,
        rutaLocal.isAcceptableOrUnknown(data['ruta_local']!, _rutaLocalMeta),
      );
    }
    if (data.containsKey('url_remota')) {
      context.handle(
        _urlRemotaMeta,
        urlRemota.isAcceptableOrUnknown(data['url_remota']!, _urlRemotaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  Adjunto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Adjunto(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: $AdjuntosTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      sincronizado: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sincronizado'],
      )!,
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      notaUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nota_uuid'],
      )!,
      rutaLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ruta_local'],
      ),
      urlRemota: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url_remota'],
      ),
    );
  }

  @override
  $AdjuntosTable createAlias(String alias) {
    return $AdjuntosTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatus, String, String> $convertersyncStatus =
      const EnumNameConverter<SyncStatus>(SyncStatus.values);
}

class Adjunto extends DataClass implements Insertable<Adjunto> {
  final DateTime createdAt;
  final DateTime updatedAt;

  /// `PENDING` al crear/editar/borrar localmente, en la MISMA transacción
  /// (sección 5.2): el propio flag actúa como cola de la SyncTask.
  final SyncStatus syncStatus;

  /// Tombstone (sección 5.4): nunca se borra físicamente hasta confirmar
  /// la propagación.
  final bool isDeleted;

  /// Última versión autoritativa conocida del servidor; el cliente solo la
  /// inicializa en 1 al crear (sección 6.3).
  final int version;
  final String? deviceId;

  /// Verdadero cuando el servidor ya confirmó la existencia del registro
  /// (tras el primer ACCEPTED). Distingue una CREATE nunca sincronizada de
  /// una UPDATE ya sincronizada: ambas pueden tener `version = 1`, así que
  /// `version` sola no basta para elegir la operación del lote (sección 5.5).
  final bool sincronizado;

  /// Motivo del rechazo cuando `sync_status = ERROR` (tarea 4.2, RF-04): el
  /// usuario necesita saber POR QUÉ el servidor rechazó el cambio para poder
  /// corregirlo. Se limpia al corregir (ERROR → PENDING) o al sincronizar.
  final String? syncError;
  final String uuid;
  final String notaUuid;

  /// Ruta del archivo en el almacenamiento de la app (metadato local).
  final String? rutaLocal;

  /// URL asignada por el servidor tras subir el binario (fase 3.5).
  final String? urlRemota;
  const Adjunto({
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    required this.isDeleted,
    required this.version,
    this.deviceId,
    required this.sincronizado,
    this.syncError,
    required this.uuid,
    required this.notaUuid,
    this.rutaLocal,
    this.urlRemota,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_status'] = Variable<String>(
        $AdjuntosTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['sincronizado'] = Variable<bool>(sincronizado);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['uuid'] = Variable<String>(uuid);
    map['nota_uuid'] = Variable<String>(notaUuid);
    if (!nullToAbsent || rutaLocal != null) {
      map['ruta_local'] = Variable<String>(rutaLocal);
    }
    if (!nullToAbsent || urlRemota != null) {
      map['url_remota'] = Variable<String>(urlRemota);
    }
    return map;
  }

  AdjuntosCompanion toCompanion(bool nullToAbsent) {
    return AdjuntosCompanion(
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      isDeleted: Value(isDeleted),
      version: Value(version),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      sincronizado: Value(sincronizado),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      uuid: Value(uuid),
      notaUuid: Value(notaUuid),
      rutaLocal: rutaLocal == null && nullToAbsent
          ? const Value.absent()
          : Value(rutaLocal),
      urlRemota: urlRemota == null && nullToAbsent
          ? const Value.absent()
          : Value(urlRemota),
    );
  }

  factory Adjunto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Adjunto(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: $AdjuntosTable.$convertersyncStatus.fromJson(
        serializer.fromJson<String>(json['syncStatus']),
      ),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      version: serializer.fromJson<int>(json['version']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      sincronizado: serializer.fromJson<bool>(json['sincronizado']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      uuid: serializer.fromJson<String>(json['uuid']),
      notaUuid: serializer.fromJson<String>(json['notaUuid']),
      rutaLocal: serializer.fromJson<String?>(json['rutaLocal']),
      urlRemota: serializer.fromJson<String?>(json['urlRemota']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<String>(
        $AdjuntosTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'version': serializer.toJson<int>(version),
      'deviceId': serializer.toJson<String?>(deviceId),
      'sincronizado': serializer.toJson<bool>(sincronizado),
      'syncError': serializer.toJson<String?>(syncError),
      'uuid': serializer.toJson<String>(uuid),
      'notaUuid': serializer.toJson<String>(notaUuid),
      'rutaLocal': serializer.toJson<String?>(rutaLocal),
      'urlRemota': serializer.toJson<String?>(urlRemota),
    };
  }

  Adjunto copyWith({
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    bool? isDeleted,
    int? version,
    Value<String?> deviceId = const Value.absent(),
    bool? sincronizado,
    Value<String?> syncError = const Value.absent(),
    String? uuid,
    String? notaUuid,
    Value<String?> rutaLocal = const Value.absent(),
    Value<String?> urlRemota = const Value.absent(),
  }) => Adjunto(
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    isDeleted: isDeleted ?? this.isDeleted,
    version: version ?? this.version,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    sincronizado: sincronizado ?? this.sincronizado,
    syncError: syncError.present ? syncError.value : this.syncError,
    uuid: uuid ?? this.uuid,
    notaUuid: notaUuid ?? this.notaUuid,
    rutaLocal: rutaLocal.present ? rutaLocal.value : this.rutaLocal,
    urlRemota: urlRemota.present ? urlRemota.value : this.urlRemota,
  );
  Adjunto copyWithCompanion(AdjuntosCompanion data) {
    return Adjunto(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      version: data.version.present ? data.version.value : this.version,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      sincronizado: data.sincronizado.present
          ? data.sincronizado.value
          : this.sincronizado,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      notaUuid: data.notaUuid.present ? data.notaUuid.value : this.notaUuid,
      rutaLocal: data.rutaLocal.present ? data.rutaLocal.value : this.rutaLocal,
      urlRemota: data.urlRemota.present ? data.urlRemota.value : this.urlRemota,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Adjunto(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('version: $version, ')
          ..write('deviceId: $deviceId, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('syncError: $syncError, ')
          ..write('uuid: $uuid, ')
          ..write('notaUuid: $notaUuid, ')
          ..write('rutaLocal: $rutaLocal, ')
          ..write('urlRemota: $urlRemota')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    updatedAt,
    syncStatus,
    isDeleted,
    version,
    deviceId,
    sincronizado,
    syncError,
    uuid,
    notaUuid,
    rutaLocal,
    urlRemota,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Adjunto &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.isDeleted == this.isDeleted &&
          other.version == this.version &&
          other.deviceId == this.deviceId &&
          other.sincronizado == this.sincronizado &&
          other.syncError == this.syncError &&
          other.uuid == this.uuid &&
          other.notaUuid == this.notaUuid &&
          other.rutaLocal == this.rutaLocal &&
          other.urlRemota == this.urlRemota);
}

class AdjuntosCompanion extends UpdateCompanion<Adjunto> {
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<SyncStatus> syncStatus;
  final Value<bool> isDeleted;
  final Value<int> version;
  final Value<String?> deviceId;
  final Value<bool> sincronizado;
  final Value<String?> syncError;
  final Value<String> uuid;
  final Value<String> notaUuid;
  final Value<String?> rutaLocal;
  final Value<String?> urlRemota;
  final Value<int> rowid;
  const AdjuntosCompanion({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.version = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.syncError = const Value.absent(),
    this.uuid = const Value.absent(),
    this.notaUuid = const Value.absent(),
    this.rutaLocal = const Value.absent(),
    this.urlRemota = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AdjuntosCompanion.insert({
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncStatus = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.version = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.syncError = const Value.absent(),
    required String uuid,
    required String notaUuid,
    this.rutaLocal = const Value.absent(),
    this.urlRemota = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       uuid = Value(uuid),
       notaUuid = Value(notaUuid);
  static Insertable<Adjunto> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncStatus,
    Expression<bool>? isDeleted,
    Expression<int>? version,
    Expression<String>? deviceId,
    Expression<bool>? sincronizado,
    Expression<String>? syncError,
    Expression<String>? uuid,
    Expression<String>? notaUuid,
    Expression<String>? rutaLocal,
    Expression<String>? urlRemota,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (version != null) 'version': version,
      if (deviceId != null) 'device_id': deviceId,
      if (sincronizado != null) 'sincronizado': sincronizado,
      if (syncError != null) 'sync_error': syncError,
      if (uuid != null) 'uuid': uuid,
      if (notaUuid != null) 'nota_uuid': notaUuid,
      if (rutaLocal != null) 'ruta_local': rutaLocal,
      if (urlRemota != null) 'url_remota': urlRemota,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AdjuntosCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<SyncStatus>? syncStatus,
    Value<bool>? isDeleted,
    Value<int>? version,
    Value<String?>? deviceId,
    Value<bool>? sincronizado,
    Value<String?>? syncError,
    Value<String>? uuid,
    Value<String>? notaUuid,
    Value<String?>? rutaLocal,
    Value<String?>? urlRemota,
    Value<int>? rowid,
  }) {
    return AdjuntosCompanion(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? this.version,
      deviceId: deviceId ?? this.deviceId,
      sincronizado: sincronizado ?? this.sincronizado,
      syncError: syncError ?? this.syncError,
      uuid: uuid ?? this.uuid,
      notaUuid: notaUuid ?? this.notaUuid,
      rutaLocal: rutaLocal ?? this.rutaLocal,
      urlRemota: urlRemota ?? this.urlRemota,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $AdjuntosTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (sincronizado.present) {
      map['sincronizado'] = Variable<bool>(sincronizado.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (notaUuid.present) {
      map['nota_uuid'] = Variable<String>(notaUuid.value);
    }
    if (rutaLocal.present) {
      map['ruta_local'] = Variable<String>(rutaLocal.value);
    }
    if (urlRemota.present) {
      map['url_remota'] = Variable<String>(urlRemota.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdjuntosCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('version: $version, ')
          ..write('deviceId: $deviceId, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('syncError: $syncError, ')
          ..write('uuid: $uuid, ')
          ..write('notaUuid: $notaUuid, ')
          ..write('rutaLocal: $rutaLocal, ')
          ..write('urlRemota: $urlRemota, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HistorialCambiosTable extends HistorialCambios
    with TableInfo<$HistorialCambiosTable, HistorialCambio> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistorialCambiosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notaUuidMeta = const VerificationMeta(
    'notaUuid',
  );
  @override
  late final GeneratedColumn<String> notaUuid = GeneratedColumn<String>(
    'nota_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES notas (uuid)',
    ),
  );
  static const VerificationMeta _tipoCambioMeta = const VerificationMeta(
    'tipoCambio',
  );
  @override
  late final GeneratedColumn<String> tipoCambio = GeneratedColumn<String>(
    'tipo_cambio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<OrigenCambio, String>
  origenCambio = GeneratedColumn<String>(
    'origen_cambio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<OrigenCambio>($HistorialCambiosTable.$converterorigenCambio);
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<DateTime> fecha = GeneratedColumn<DateTime>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dispositivoOrigenMeta = const VerificationMeta(
    'dispositivoOrigen',
  );
  @override
  late final GeneratedColumn<String> dispositivoOrigen =
      GeneratedColumn<String>(
        'dispositivo_origen',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _valorAnteriorMeta = const VerificationMeta(
    'valorAnterior',
  );
  @override
  late final GeneratedColumn<String> valorAnterior = GeneratedColumn<String>(
    'valor_anterior',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valorNuevoMeta = const VerificationMeta(
    'valorNuevo',
  );
  @override
  late final GeneratedColumn<String> valorNuevo = GeneratedColumn<String>(
    'valor_nuevo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    notaUuid,
    tipoCambio,
    origenCambio,
    fecha,
    dispositivoOrigen,
    valorAnterior,
    valorNuevo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'historial_cambios';
  @override
  VerificationContext validateIntegrity(
    Insertable<HistorialCambio> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('nota_uuid')) {
      context.handle(
        _notaUuidMeta,
        notaUuid.isAcceptableOrUnknown(data['nota_uuid']!, _notaUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_notaUuidMeta);
    }
    if (data.containsKey('tipo_cambio')) {
      context.handle(
        _tipoCambioMeta,
        tipoCambio.isAcceptableOrUnknown(data['tipo_cambio']!, _tipoCambioMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoCambioMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('dispositivo_origen')) {
      context.handle(
        _dispositivoOrigenMeta,
        dispositivoOrigen.isAcceptableOrUnknown(
          data['dispositivo_origen']!,
          _dispositivoOrigenMeta,
        ),
      );
    }
    if (data.containsKey('valor_anterior')) {
      context.handle(
        _valorAnteriorMeta,
        valorAnterior.isAcceptableOrUnknown(
          data['valor_anterior']!,
          _valorAnteriorMeta,
        ),
      );
    }
    if (data.containsKey('valor_nuevo')) {
      context.handle(
        _valorNuevoMeta,
        valorNuevo.isAcceptableOrUnknown(data['valor_nuevo']!, _valorNuevoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  HistorialCambio map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistorialCambio(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      notaUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nota_uuid'],
      )!,
      tipoCambio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo_cambio'],
      )!,
      origenCambio: $HistorialCambiosTable.$converterorigenCambio.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}origen_cambio'],
        )!,
      ),
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha'],
      )!,
      dispositivoOrigen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dispositivo_origen'],
      ),
      valorAnterior: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valor_anterior'],
      ),
      valorNuevo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valor_nuevo'],
      ),
    );
  }

  @override
  $HistorialCambiosTable createAlias(String alias) {
    return $HistorialCambiosTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<OrigenCambio, String, String>
  $converterorigenCambio = const EnumNameConverter<OrigenCambio>(
    OrigenCambio.values,
  );
}

class HistorialCambio extends DataClass implements Insertable<HistorialCambio> {
  final String uuid;
  final String notaUuid;
  final String tipoCambio;
  final OrigenCambio origenCambio;
  final DateTime fecha;
  final String? dispositivoOrigen;

  /// Estados serializados (JSON). En conflictos descartados, `valorNuevo`
  /// es el valor que NO se aplicó (mismo criterio que el backend).
  final String? valorAnterior;
  final String? valorNuevo;
  const HistorialCambio({
    required this.uuid,
    required this.notaUuid,
    required this.tipoCambio,
    required this.origenCambio,
    required this.fecha,
    this.dispositivoOrigen,
    this.valorAnterior,
    this.valorNuevo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['nota_uuid'] = Variable<String>(notaUuid);
    map['tipo_cambio'] = Variable<String>(tipoCambio);
    {
      map['origen_cambio'] = Variable<String>(
        $HistorialCambiosTable.$converterorigenCambio.toSql(origenCambio),
      );
    }
    map['fecha'] = Variable<DateTime>(fecha);
    if (!nullToAbsent || dispositivoOrigen != null) {
      map['dispositivo_origen'] = Variable<String>(dispositivoOrigen);
    }
    if (!nullToAbsent || valorAnterior != null) {
      map['valor_anterior'] = Variable<String>(valorAnterior);
    }
    if (!nullToAbsent || valorNuevo != null) {
      map['valor_nuevo'] = Variable<String>(valorNuevo);
    }
    return map;
  }

  HistorialCambiosCompanion toCompanion(bool nullToAbsent) {
    return HistorialCambiosCompanion(
      uuid: Value(uuid),
      notaUuid: Value(notaUuid),
      tipoCambio: Value(tipoCambio),
      origenCambio: Value(origenCambio),
      fecha: Value(fecha),
      dispositivoOrigen: dispositivoOrigen == null && nullToAbsent
          ? const Value.absent()
          : Value(dispositivoOrigen),
      valorAnterior: valorAnterior == null && nullToAbsent
          ? const Value.absent()
          : Value(valorAnterior),
      valorNuevo: valorNuevo == null && nullToAbsent
          ? const Value.absent()
          : Value(valorNuevo),
    );
  }

  factory HistorialCambio.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistorialCambio(
      uuid: serializer.fromJson<String>(json['uuid']),
      notaUuid: serializer.fromJson<String>(json['notaUuid']),
      tipoCambio: serializer.fromJson<String>(json['tipoCambio']),
      origenCambio: $HistorialCambiosTable.$converterorigenCambio.fromJson(
        serializer.fromJson<String>(json['origenCambio']),
      ),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
      dispositivoOrigen: serializer.fromJson<String?>(
        json['dispositivoOrigen'],
      ),
      valorAnterior: serializer.fromJson<String?>(json['valorAnterior']),
      valorNuevo: serializer.fromJson<String?>(json['valorNuevo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'notaUuid': serializer.toJson<String>(notaUuid),
      'tipoCambio': serializer.toJson<String>(tipoCambio),
      'origenCambio': serializer.toJson<String>(
        $HistorialCambiosTable.$converterorigenCambio.toJson(origenCambio),
      ),
      'fecha': serializer.toJson<DateTime>(fecha),
      'dispositivoOrigen': serializer.toJson<String?>(dispositivoOrigen),
      'valorAnterior': serializer.toJson<String?>(valorAnterior),
      'valorNuevo': serializer.toJson<String?>(valorNuevo),
    };
  }

  HistorialCambio copyWith({
    String? uuid,
    String? notaUuid,
    String? tipoCambio,
    OrigenCambio? origenCambio,
    DateTime? fecha,
    Value<String?> dispositivoOrigen = const Value.absent(),
    Value<String?> valorAnterior = const Value.absent(),
    Value<String?> valorNuevo = const Value.absent(),
  }) => HistorialCambio(
    uuid: uuid ?? this.uuid,
    notaUuid: notaUuid ?? this.notaUuid,
    tipoCambio: tipoCambio ?? this.tipoCambio,
    origenCambio: origenCambio ?? this.origenCambio,
    fecha: fecha ?? this.fecha,
    dispositivoOrigen: dispositivoOrigen.present
        ? dispositivoOrigen.value
        : this.dispositivoOrigen,
    valorAnterior: valorAnterior.present
        ? valorAnterior.value
        : this.valorAnterior,
    valorNuevo: valorNuevo.present ? valorNuevo.value : this.valorNuevo,
  );
  HistorialCambio copyWithCompanion(HistorialCambiosCompanion data) {
    return HistorialCambio(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      notaUuid: data.notaUuid.present ? data.notaUuid.value : this.notaUuid,
      tipoCambio: data.tipoCambio.present
          ? data.tipoCambio.value
          : this.tipoCambio,
      origenCambio: data.origenCambio.present
          ? data.origenCambio.value
          : this.origenCambio,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      dispositivoOrigen: data.dispositivoOrigen.present
          ? data.dispositivoOrigen.value
          : this.dispositivoOrigen,
      valorAnterior: data.valorAnterior.present
          ? data.valorAnterior.value
          : this.valorAnterior,
      valorNuevo: data.valorNuevo.present
          ? data.valorNuevo.value
          : this.valorNuevo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistorialCambio(')
          ..write('uuid: $uuid, ')
          ..write('notaUuid: $notaUuid, ')
          ..write('tipoCambio: $tipoCambio, ')
          ..write('origenCambio: $origenCambio, ')
          ..write('fecha: $fecha, ')
          ..write('dispositivoOrigen: $dispositivoOrigen, ')
          ..write('valorAnterior: $valorAnterior, ')
          ..write('valorNuevo: $valorNuevo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    notaUuid,
    tipoCambio,
    origenCambio,
    fecha,
    dispositivoOrigen,
    valorAnterior,
    valorNuevo,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistorialCambio &&
          other.uuid == this.uuid &&
          other.notaUuid == this.notaUuid &&
          other.tipoCambio == this.tipoCambio &&
          other.origenCambio == this.origenCambio &&
          other.fecha == this.fecha &&
          other.dispositivoOrigen == this.dispositivoOrigen &&
          other.valorAnterior == this.valorAnterior &&
          other.valorNuevo == this.valorNuevo);
}

class HistorialCambiosCompanion extends UpdateCompanion<HistorialCambio> {
  final Value<String> uuid;
  final Value<String> notaUuid;
  final Value<String> tipoCambio;
  final Value<OrigenCambio> origenCambio;
  final Value<DateTime> fecha;
  final Value<String?> dispositivoOrigen;
  final Value<String?> valorAnterior;
  final Value<String?> valorNuevo;
  final Value<int> rowid;
  const HistorialCambiosCompanion({
    this.uuid = const Value.absent(),
    this.notaUuid = const Value.absent(),
    this.tipoCambio = const Value.absent(),
    this.origenCambio = const Value.absent(),
    this.fecha = const Value.absent(),
    this.dispositivoOrigen = const Value.absent(),
    this.valorAnterior = const Value.absent(),
    this.valorNuevo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HistorialCambiosCompanion.insert({
    required String uuid,
    required String notaUuid,
    required String tipoCambio,
    required OrigenCambio origenCambio,
    required DateTime fecha,
    this.dispositivoOrigen = const Value.absent(),
    this.valorAnterior = const Value.absent(),
    this.valorNuevo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       notaUuid = Value(notaUuid),
       tipoCambio = Value(tipoCambio),
       origenCambio = Value(origenCambio),
       fecha = Value(fecha);
  static Insertable<HistorialCambio> custom({
    Expression<String>? uuid,
    Expression<String>? notaUuid,
    Expression<String>? tipoCambio,
    Expression<String>? origenCambio,
    Expression<DateTime>? fecha,
    Expression<String>? dispositivoOrigen,
    Expression<String>? valorAnterior,
    Expression<String>? valorNuevo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (notaUuid != null) 'nota_uuid': notaUuid,
      if (tipoCambio != null) 'tipo_cambio': tipoCambio,
      if (origenCambio != null) 'origen_cambio': origenCambio,
      if (fecha != null) 'fecha': fecha,
      if (dispositivoOrigen != null) 'dispositivo_origen': dispositivoOrigen,
      if (valorAnterior != null) 'valor_anterior': valorAnterior,
      if (valorNuevo != null) 'valor_nuevo': valorNuevo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HistorialCambiosCompanion copyWith({
    Value<String>? uuid,
    Value<String>? notaUuid,
    Value<String>? tipoCambio,
    Value<OrigenCambio>? origenCambio,
    Value<DateTime>? fecha,
    Value<String?>? dispositivoOrigen,
    Value<String?>? valorAnterior,
    Value<String?>? valorNuevo,
    Value<int>? rowid,
  }) {
    return HistorialCambiosCompanion(
      uuid: uuid ?? this.uuid,
      notaUuid: notaUuid ?? this.notaUuid,
      tipoCambio: tipoCambio ?? this.tipoCambio,
      origenCambio: origenCambio ?? this.origenCambio,
      fecha: fecha ?? this.fecha,
      dispositivoOrigen: dispositivoOrigen ?? this.dispositivoOrigen,
      valorAnterior: valorAnterior ?? this.valorAnterior,
      valorNuevo: valorNuevo ?? this.valorNuevo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (notaUuid.present) {
      map['nota_uuid'] = Variable<String>(notaUuid.value);
    }
    if (tipoCambio.present) {
      map['tipo_cambio'] = Variable<String>(tipoCambio.value);
    }
    if (origenCambio.present) {
      map['origen_cambio'] = Variable<String>(
        $HistorialCambiosTable.$converterorigenCambio.toSql(origenCambio.value),
      );
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(fecha.value);
    }
    if (dispositivoOrigen.present) {
      map['dispositivo_origen'] = Variable<String>(dispositivoOrigen.value);
    }
    if (valorAnterior.present) {
      map['valor_anterior'] = Variable<String>(valorAnterior.value);
    }
    if (valorNuevo.present) {
      map['valor_nuevo'] = Variable<String>(valorNuevo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistorialCambiosCompanion(')
          ..write('uuid: $uuid, ')
          ..write('notaUuid: $notaUuid, ')
          ..write('tipoCambio: $tipoCambio, ')
          ..write('origenCambio: $origenCambio, ')
          ..write('fecha: $fecha, ')
          ..write('dispositivoOrigen: $dispositivoOrigen, ')
          ..write('valorAnterior: $valorAnterior, ')
          ..write('valorNuevo: $valorNuevo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsuariosTable extends Usuarios with TableInfo<$UsuariosTable, Usuario> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsuariosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [uuid, nombre, email];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'usuarios';
  @override
  VerificationContext validateIntegrity(
    Insertable<Usuario> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  Usuario map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Usuario(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
    );
  }

  @override
  $UsuariosTable createAlias(String alias) {
    return $UsuariosTable(attachedDatabase, alias);
  }
}

class Usuario extends DataClass implements Insertable<Usuario> {
  final String uuid;
  final String nombre;
  final String email;
  const Usuario({
    required this.uuid,
    required this.nombre,
    required this.email,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['nombre'] = Variable<String>(nombre);
    map['email'] = Variable<String>(email);
    return map;
  }

  UsuariosCompanion toCompanion(bool nullToAbsent) {
    return UsuariosCompanion(
      uuid: Value(uuid),
      nombre: Value(nombre),
      email: Value(email),
    );
  }

  factory Usuario.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Usuario(
      uuid: serializer.fromJson<String>(json['uuid']),
      nombre: serializer.fromJson<String>(json['nombre']),
      email: serializer.fromJson<String>(json['email']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'nombre': serializer.toJson<String>(nombre),
      'email': serializer.toJson<String>(email),
    };
  }

  Usuario copyWith({String? uuid, String? nombre, String? email}) => Usuario(
    uuid: uuid ?? this.uuid,
    nombre: nombre ?? this.nombre,
    email: email ?? this.email,
  );
  Usuario copyWithCompanion(UsuariosCompanion data) {
    return Usuario(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      email: data.email.present ? data.email.value : this.email,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Usuario(')
          ..write('uuid: $uuid, ')
          ..write('nombre: $nombre, ')
          ..write('email: $email')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(uuid, nombre, email);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Usuario &&
          other.uuid == this.uuid &&
          other.nombre == this.nombre &&
          other.email == this.email);
}

class UsuariosCompanion extends UpdateCompanion<Usuario> {
  final Value<String> uuid;
  final Value<String> nombre;
  final Value<String> email;
  final Value<int> rowid;
  const UsuariosCompanion({
    this.uuid = const Value.absent(),
    this.nombre = const Value.absent(),
    this.email = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsuariosCompanion.insert({
    required String uuid,
    required String nombre,
    required String email,
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       nombre = Value(nombre),
       email = Value(email);
  static Insertable<Usuario> custom({
    Expression<String>? uuid,
    Expression<String>? nombre,
    Expression<String>? email,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (nombre != null) 'nombre': nombre,
      if (email != null) 'email': email,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsuariosCompanion copyWith({
    Value<String>? uuid,
    Value<String>? nombre,
    Value<String>? email,
    Value<int>? rowid,
  }) {
    return UsuariosCompanion(
      uuid: uuid ?? this.uuid,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsuariosCompanion(')
          ..write('uuid: $uuid, ')
          ..write('nombre: $nombre, ')
          ..write('email: $email, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetaTable extends SyncMeta
    with TableInfo<$SyncMetaTable, SyncMetaDato> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _claveMeta = const VerificationMeta('clave');
  @override
  late final GeneratedColumn<String> clave = GeneratedColumn<String>(
    'clave',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valorMeta = const VerificationMeta('valor');
  @override
  late final GeneratedColumn<String> valor = GeneratedColumn<String>(
    'valor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [clave, valor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetaDato> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('clave')) {
      context.handle(
        _claveMeta,
        clave.isAcceptableOrUnknown(data['clave']!, _claveMeta),
      );
    } else if (isInserting) {
      context.missing(_claveMeta);
    }
    if (data.containsKey('valor')) {
      context.handle(
        _valorMeta,
        valor.isAcceptableOrUnknown(data['valor']!, _valorMeta),
      );
    } else if (isInserting) {
      context.missing(_valorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clave};
  @override
  SyncMetaDato map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaDato(
      clave: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clave'],
      )!,
      valor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valor'],
      )!,
    );
  }

  @override
  $SyncMetaTable createAlias(String alias) {
    return $SyncMetaTable(attachedDatabase, alias);
  }
}

class SyncMetaDato extends DataClass implements Insertable<SyncMetaDato> {
  final String clave;
  final String valor;
  const SyncMetaDato({required this.clave, required this.valor});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['clave'] = Variable<String>(clave);
    map['valor'] = Variable<String>(valor);
    return map;
  }

  SyncMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaCompanion(clave: Value(clave), valor: Value(valor));
  }

  factory SyncMetaDato.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaDato(
      clave: serializer.fromJson<String>(json['clave']),
      valor: serializer.fromJson<String>(json['valor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clave': serializer.toJson<String>(clave),
      'valor': serializer.toJson<String>(valor),
    };
  }

  SyncMetaDato copyWith({String? clave, String? valor}) =>
      SyncMetaDato(clave: clave ?? this.clave, valor: valor ?? this.valor);
  SyncMetaDato copyWithCompanion(SyncMetaCompanion data) {
    return SyncMetaDato(
      clave: data.clave.present ? data.clave.value : this.clave,
      valor: data.valor.present ? data.valor.value : this.valor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaDato(')
          ..write('clave: $clave, ')
          ..write('valor: $valor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(clave, valor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetaDato &&
          other.clave == this.clave &&
          other.valor == this.valor);
}

class SyncMetaCompanion extends UpdateCompanion<SyncMetaDato> {
  final Value<String> clave;
  final Value<String> valor;
  final Value<int> rowid;
  const SyncMetaCompanion({
    this.clave = const Value.absent(),
    this.valor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetaCompanion.insert({
    required String clave,
    required String valor,
    this.rowid = const Value.absent(),
  }) : clave = Value(clave),
       valor = Value(valor);
  static Insertable<SyncMetaDato> custom({
    Expression<String>? clave,
    Expression<String>? valor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clave != null) 'clave': clave,
      if (valor != null) 'valor': valor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetaCompanion copyWith({
    Value<String>? clave,
    Value<String>? valor,
    Value<int>? rowid,
  }) {
    return SyncMetaCompanion(
      clave: clave ?? this.clave,
      valor: valor ?? this.valor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clave.present) {
      map['clave'] = Variable<String>(clave.value);
    }
    if (valor.present) {
      map['valor'] = Variable<String>(valor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaCompanion(')
          ..write('clave: $clave, ')
          ..write('valor: $valor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NotasTable notas = $NotasTable(this);
  late final $AdjuntosTable adjuntos = $AdjuntosTable(this);
  late final $HistorialCambiosTable historialCambios = $HistorialCambiosTable(
    this,
  );
  late final $UsuariosTable usuarios = $UsuariosTable(this);
  late final $SyncMetaTable syncMeta = $SyncMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    notas,
    adjuntos,
    historialCambios,
    usuarios,
    syncMeta,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$NotasTableCreateCompanionBuilder =
    NotasCompanion Function({
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<SyncStatus> syncStatus,
      Value<bool> isDeleted,
      Value<int> version,
      Value<String?> deviceId,
      Value<bool> sincronizado,
      Value<String?> syncError,
      required String uuid,
      required String usuarioUuid,
      required String titulo,
      Value<String?> contenido,
      Value<int> rowid,
    });
typedef $$NotasTableUpdateCompanionBuilder =
    NotasCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<SyncStatus> syncStatus,
      Value<bool> isDeleted,
      Value<int> version,
      Value<String?> deviceId,
      Value<bool> sincronizado,
      Value<String?> syncError,
      Value<String> uuid,
      Value<String> usuarioUuid,
      Value<String> titulo,
      Value<String?> contenido,
      Value<int> rowid,
    });

final class $$NotasTableReferences
    extends BaseReferences<_$AppDatabase, $NotasTable, Nota> {
  $$NotasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AdjuntosTable, List<Adjunto>> _adjuntosRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.adjuntos,
    aliasName: 'notas__uuid__adjuntos__nota_uuid',
  );

  $$AdjuntosTableProcessedTableManager get adjuntosRefs {
    final manager = $$AdjuntosTableTableManager(
      $_db,
      $_db.adjuntos,
    ).filter((f) => f.notaUuid.uuid.sqlEquals($_itemColumn<String>('uuid')!));

    final cache = $_typedResult.readTableOrNull(_adjuntosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HistorialCambiosTable, List<HistorialCambio>>
  _historialCambiosRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.historialCambios,
    aliasName: 'notas__uuid__historial_cambios__nota_uuid',
  );

  $$HistorialCambiosTableProcessedTableManager get historialCambiosRefs {
    final manager = $$HistorialCambiosTableTableManager(
      $_db,
      $_db.historialCambios,
    ).filter((f) => f.notaUuid.uuid.sqlEquals($_itemColumn<String>('uuid')!));

    final cache = $_typedResult.readTableOrNull(
      _historialCambiosRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$NotasTableFilterComposer extends Composer<_$AppDatabase, $NotasTable> {
  $$NotasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usuarioUuid => $composableBuilder(
    column: $table.usuarioUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titulo => $composableBuilder(
    column: $table.titulo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contenido => $composableBuilder(
    column: $table.contenido,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> adjuntosRefs(
    Expression<bool> Function($$AdjuntosTableFilterComposer f) f,
  ) {
    final $$AdjuntosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.adjuntos,
      getReferencedColumn: (t) => t.notaUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdjuntosTableFilterComposer(
            $db: $db,
            $table: $db.adjuntos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> historialCambiosRefs(
    Expression<bool> Function($$HistorialCambiosTableFilterComposer f) f,
  ) {
    final $$HistorialCambiosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.historialCambios,
      getReferencedColumn: (t) => t.notaUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HistorialCambiosTableFilterComposer(
            $db: $db,
            $table: $db.historialCambios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NotasTableOrderingComposer
    extends Composer<_$AppDatabase, $NotasTable> {
  $$NotasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usuarioUuid => $composableBuilder(
    column: $table.usuarioUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titulo => $composableBuilder(
    column: $table.titulo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contenido => $composableBuilder(
    column: $table.contenido,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotasTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotasTable> {
  $$NotasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get usuarioUuid => $composableBuilder(
    column: $table.usuarioUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get titulo =>
      $composableBuilder(column: $table.titulo, builder: (column) => column);

  GeneratedColumn<String> get contenido =>
      $composableBuilder(column: $table.contenido, builder: (column) => column);

  Expression<T> adjuntosRefs<T extends Object>(
    Expression<T> Function($$AdjuntosTableAnnotationComposer a) f,
  ) {
    final $$AdjuntosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.adjuntos,
      getReferencedColumn: (t) => t.notaUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdjuntosTableAnnotationComposer(
            $db: $db,
            $table: $db.adjuntos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> historialCambiosRefs<T extends Object>(
    Expression<T> Function($$HistorialCambiosTableAnnotationComposer a) f,
  ) {
    final $$HistorialCambiosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.historialCambios,
      getReferencedColumn: (t) => t.notaUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HistorialCambiosTableAnnotationComposer(
            $db: $db,
            $table: $db.historialCambios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NotasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotasTable,
          Nota,
          $$NotasTableFilterComposer,
          $$NotasTableOrderingComposer,
          $$NotasTableAnnotationComposer,
          $$NotasTableCreateCompanionBuilder,
          $$NotasTableUpdateCompanionBuilder,
          (Nota, $$NotasTableReferences),
          Nota,
          PrefetchHooks Function({bool adjuntosRefs, bool historialCambiosRefs})
        > {
  $$NotasTableTableManager(_$AppDatabase db, $NotasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<bool> sincronizado = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> usuarioUuid = const Value.absent(),
                Value<String> titulo = const Value.absent(),
                Value<String?> contenido = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotasCompanion(
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                isDeleted: isDeleted,
                version: version,
                deviceId: deviceId,
                sincronizado: sincronizado,
                syncError: syncError,
                uuid: uuid,
                usuarioUuid: usuarioUuid,
                titulo: titulo,
                contenido: contenido,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<bool> sincronizado = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                required String uuid,
                required String usuarioUuid,
                required String titulo,
                Value<String?> contenido = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotasCompanion.insert(
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                isDeleted: isDeleted,
                version: version,
                deviceId: deviceId,
                sincronizado: sincronizado,
                syncError: syncError,
                uuid: uuid,
                usuarioUuid: usuarioUuid,
                titulo: titulo,
                contenido: contenido,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$NotasTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({adjuntosRefs = false, historialCambiosRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (adjuntosRefs) db.adjuntos,
                    if (historialCambiosRefs) db.historialCambios,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (adjuntosRefs)
                        await $_getPrefetchedData<Nota, $NotasTable, Adjunto>(
                          currentTable: table,
                          referencedTable: $$NotasTableReferences
                              ._adjuntosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NotasTableReferences(
                                db,
                                table,
                                p0,
                              ).adjuntosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.notaUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                      if (historialCambiosRefs)
                        await $_getPrefetchedData<
                          Nota,
                          $NotasTable,
                          HistorialCambio
                        >(
                          currentTable: table,
                          referencedTable: $$NotasTableReferences
                              ._historialCambiosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NotasTableReferences(
                                db,
                                table,
                                p0,
                              ).historialCambiosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.notaUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$NotasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotasTable,
      Nota,
      $$NotasTableFilterComposer,
      $$NotasTableOrderingComposer,
      $$NotasTableAnnotationComposer,
      $$NotasTableCreateCompanionBuilder,
      $$NotasTableUpdateCompanionBuilder,
      (Nota, $$NotasTableReferences),
      Nota,
      PrefetchHooks Function({bool adjuntosRefs, bool historialCambiosRefs})
    >;
typedef $$AdjuntosTableCreateCompanionBuilder =
    AdjuntosCompanion Function({
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<SyncStatus> syncStatus,
      Value<bool> isDeleted,
      Value<int> version,
      Value<String?> deviceId,
      Value<bool> sincronizado,
      Value<String?> syncError,
      required String uuid,
      required String notaUuid,
      Value<String?> rutaLocal,
      Value<String?> urlRemota,
      Value<int> rowid,
    });
typedef $$AdjuntosTableUpdateCompanionBuilder =
    AdjuntosCompanion Function({
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<SyncStatus> syncStatus,
      Value<bool> isDeleted,
      Value<int> version,
      Value<String?> deviceId,
      Value<bool> sincronizado,
      Value<String?> syncError,
      Value<String> uuid,
      Value<String> notaUuid,
      Value<String?> rutaLocal,
      Value<String?> urlRemota,
      Value<int> rowid,
    });

final class $$AdjuntosTableReferences
    extends BaseReferences<_$AppDatabase, $AdjuntosTable, Adjunto> {
  $$AdjuntosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NotasTable _notaUuidTable(_$AppDatabase db) =>
      db.notas.createAlias('adjuntos__nota_uuid__notas__uuid');

  $$NotasTableProcessedTableManager get notaUuid {
    final $_column = $_itemColumn<String>('nota_uuid')!;

    final manager = $$NotasTableTableManager(
      $_db,
      $_db.notas,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_notaUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AdjuntosTableFilterComposer
    extends Composer<_$AppDatabase, $AdjuntosTable> {
  $$AdjuntosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rutaLocal => $composableBuilder(
    column: $table.rutaLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get urlRemota => $composableBuilder(
    column: $table.urlRemota,
    builder: (column) => ColumnFilters(column),
  );

  $$NotasTableFilterComposer get notaUuid {
    final $$NotasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notaUuid,
      referencedTable: $db.notas,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotasTableFilterComposer(
            $db: $db,
            $table: $db.notas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AdjuntosTableOrderingComposer
    extends Composer<_$AppDatabase, $AdjuntosTable> {
  $$AdjuntosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rutaLocal => $composableBuilder(
    column: $table.rutaLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get urlRemota => $composableBuilder(
    column: $table.urlRemota,
    builder: (column) => ColumnOrderings(column),
  );

  $$NotasTableOrderingComposer get notaUuid {
    final $$NotasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notaUuid,
      referencedTable: $db.notas,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotasTableOrderingComposer(
            $db: $db,
            $table: $db.notas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AdjuntosTableAnnotationComposer
    extends Composer<_$AppDatabase, $AdjuntosTable> {
  $$AdjuntosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get rutaLocal =>
      $composableBuilder(column: $table.rutaLocal, builder: (column) => column);

  GeneratedColumn<String> get urlRemota =>
      $composableBuilder(column: $table.urlRemota, builder: (column) => column);

  $$NotasTableAnnotationComposer get notaUuid {
    final $$NotasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notaUuid,
      referencedTable: $db.notas,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotasTableAnnotationComposer(
            $db: $db,
            $table: $db.notas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AdjuntosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AdjuntosTable,
          Adjunto,
          $$AdjuntosTableFilterComposer,
          $$AdjuntosTableOrderingComposer,
          $$AdjuntosTableAnnotationComposer,
          $$AdjuntosTableCreateCompanionBuilder,
          $$AdjuntosTableUpdateCompanionBuilder,
          (Adjunto, $$AdjuntosTableReferences),
          Adjunto,
          PrefetchHooks Function({bool notaUuid})
        > {
  $$AdjuntosTableTableManager(_$AppDatabase db, $AdjuntosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdjuntosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdjuntosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AdjuntosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<bool> sincronizado = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> notaUuid = const Value.absent(),
                Value<String?> rutaLocal = const Value.absent(),
                Value<String?> urlRemota = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdjuntosCompanion(
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                isDeleted: isDeleted,
                version: version,
                deviceId: deviceId,
                sincronizado: sincronizado,
                syncError: syncError,
                uuid: uuid,
                notaUuid: notaUuid,
                rutaLocal: rutaLocal,
                urlRemota: urlRemota,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<bool> sincronizado = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                required String uuid,
                required String notaUuid,
                Value<String?> rutaLocal = const Value.absent(),
                Value<String?> urlRemota = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdjuntosCompanion.insert(
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                isDeleted: isDeleted,
                version: version,
                deviceId: deviceId,
                sincronizado: sincronizado,
                syncError: syncError,
                uuid: uuid,
                notaUuid: notaUuid,
                rutaLocal: rutaLocal,
                urlRemota: urlRemota,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AdjuntosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({notaUuid = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (notaUuid) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.notaUuid,
                                referencedTable: $$AdjuntosTableReferences
                                    ._notaUuidTable(db),
                                referencedColumn: $$AdjuntosTableReferences
                                    ._notaUuidTable(db)
                                    .uuid,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AdjuntosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AdjuntosTable,
      Adjunto,
      $$AdjuntosTableFilterComposer,
      $$AdjuntosTableOrderingComposer,
      $$AdjuntosTableAnnotationComposer,
      $$AdjuntosTableCreateCompanionBuilder,
      $$AdjuntosTableUpdateCompanionBuilder,
      (Adjunto, $$AdjuntosTableReferences),
      Adjunto,
      PrefetchHooks Function({bool notaUuid})
    >;
typedef $$HistorialCambiosTableCreateCompanionBuilder =
    HistorialCambiosCompanion Function({
      required String uuid,
      required String notaUuid,
      required String tipoCambio,
      required OrigenCambio origenCambio,
      required DateTime fecha,
      Value<String?> dispositivoOrigen,
      Value<String?> valorAnterior,
      Value<String?> valorNuevo,
      Value<int> rowid,
    });
typedef $$HistorialCambiosTableUpdateCompanionBuilder =
    HistorialCambiosCompanion Function({
      Value<String> uuid,
      Value<String> notaUuid,
      Value<String> tipoCambio,
      Value<OrigenCambio> origenCambio,
      Value<DateTime> fecha,
      Value<String?> dispositivoOrigen,
      Value<String?> valorAnterior,
      Value<String?> valorNuevo,
      Value<int> rowid,
    });

final class $$HistorialCambiosTableReferences
    extends
        BaseReferences<_$AppDatabase, $HistorialCambiosTable, HistorialCambio> {
  $$HistorialCambiosTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $NotasTable _notaUuidTable(_$AppDatabase db) =>
      db.notas.createAlias('historial_cambios__nota_uuid__notas__uuid');

  $$NotasTableProcessedTableManager get notaUuid {
    final $_column = $_itemColumn<String>('nota_uuid')!;

    final manager = $$NotasTableTableManager(
      $_db,
      $_db.notas,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_notaUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HistorialCambiosTableFilterComposer
    extends Composer<_$AppDatabase, $HistorialCambiosTable> {
  $$HistorialCambiosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipoCambio => $composableBuilder(
    column: $table.tipoCambio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<OrigenCambio, OrigenCambio, String>
  get origenCambio => $composableBuilder(
    column: $table.origenCambio,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dispositivoOrigen => $composableBuilder(
    column: $table.dispositivoOrigen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valorAnterior => $composableBuilder(
    column: $table.valorAnterior,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valorNuevo => $composableBuilder(
    column: $table.valorNuevo,
    builder: (column) => ColumnFilters(column),
  );

  $$NotasTableFilterComposer get notaUuid {
    final $$NotasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notaUuid,
      referencedTable: $db.notas,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotasTableFilterComposer(
            $db: $db,
            $table: $db.notas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HistorialCambiosTableOrderingComposer
    extends Composer<_$AppDatabase, $HistorialCambiosTable> {
  $$HistorialCambiosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipoCambio => $composableBuilder(
    column: $table.tipoCambio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origenCambio => $composableBuilder(
    column: $table.origenCambio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dispositivoOrigen => $composableBuilder(
    column: $table.dispositivoOrigen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valorAnterior => $composableBuilder(
    column: $table.valorAnterior,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valorNuevo => $composableBuilder(
    column: $table.valorNuevo,
    builder: (column) => ColumnOrderings(column),
  );

  $$NotasTableOrderingComposer get notaUuid {
    final $$NotasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notaUuid,
      referencedTable: $db.notas,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotasTableOrderingComposer(
            $db: $db,
            $table: $db.notas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HistorialCambiosTableAnnotationComposer
    extends Composer<_$AppDatabase, $HistorialCambiosTable> {
  $$HistorialCambiosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get tipoCambio => $composableBuilder(
    column: $table.tipoCambio,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<OrigenCambio, String> get origenCambio =>
      $composableBuilder(
        column: $table.origenCambio,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<String> get dispositivoOrigen => $composableBuilder(
    column: $table.dispositivoOrigen,
    builder: (column) => column,
  );

  GeneratedColumn<String> get valorAnterior => $composableBuilder(
    column: $table.valorAnterior,
    builder: (column) => column,
  );

  GeneratedColumn<String> get valorNuevo => $composableBuilder(
    column: $table.valorNuevo,
    builder: (column) => column,
  );

  $$NotasTableAnnotationComposer get notaUuid {
    final $$NotasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notaUuid,
      referencedTable: $db.notas,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotasTableAnnotationComposer(
            $db: $db,
            $table: $db.notas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HistorialCambiosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HistorialCambiosTable,
          HistorialCambio,
          $$HistorialCambiosTableFilterComposer,
          $$HistorialCambiosTableOrderingComposer,
          $$HistorialCambiosTableAnnotationComposer,
          $$HistorialCambiosTableCreateCompanionBuilder,
          $$HistorialCambiosTableUpdateCompanionBuilder,
          (HistorialCambio, $$HistorialCambiosTableReferences),
          HistorialCambio,
          PrefetchHooks Function({bool notaUuid})
        > {
  $$HistorialCambiosTableTableManager(
    _$AppDatabase db,
    $HistorialCambiosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HistorialCambiosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HistorialCambiosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HistorialCambiosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String> notaUuid = const Value.absent(),
                Value<String> tipoCambio = const Value.absent(),
                Value<OrigenCambio> origenCambio = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<String?> dispositivoOrigen = const Value.absent(),
                Value<String?> valorAnterior = const Value.absent(),
                Value<String?> valorNuevo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HistorialCambiosCompanion(
                uuid: uuid,
                notaUuid: notaUuid,
                tipoCambio: tipoCambio,
                origenCambio: origenCambio,
                fecha: fecha,
                dispositivoOrigen: dispositivoOrigen,
                valorAnterior: valorAnterior,
                valorNuevo: valorNuevo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                required String notaUuid,
                required String tipoCambio,
                required OrigenCambio origenCambio,
                required DateTime fecha,
                Value<String?> dispositivoOrigen = const Value.absent(),
                Value<String?> valorAnterior = const Value.absent(),
                Value<String?> valorNuevo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HistorialCambiosCompanion.insert(
                uuid: uuid,
                notaUuid: notaUuid,
                tipoCambio: tipoCambio,
                origenCambio: origenCambio,
                fecha: fecha,
                dispositivoOrigen: dispositivoOrigen,
                valorAnterior: valorAnterior,
                valorNuevo: valorNuevo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HistorialCambiosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({notaUuid = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (notaUuid) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.notaUuid,
                                referencedTable:
                                    $$HistorialCambiosTableReferences
                                        ._notaUuidTable(db),
                                referencedColumn:
                                    $$HistorialCambiosTableReferences
                                        ._notaUuidTable(db)
                                        .uuid,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HistorialCambiosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HistorialCambiosTable,
      HistorialCambio,
      $$HistorialCambiosTableFilterComposer,
      $$HistorialCambiosTableOrderingComposer,
      $$HistorialCambiosTableAnnotationComposer,
      $$HistorialCambiosTableCreateCompanionBuilder,
      $$HistorialCambiosTableUpdateCompanionBuilder,
      (HistorialCambio, $$HistorialCambiosTableReferences),
      HistorialCambio,
      PrefetchHooks Function({bool notaUuid})
    >;
typedef $$UsuariosTableCreateCompanionBuilder =
    UsuariosCompanion Function({
      required String uuid,
      required String nombre,
      required String email,
      Value<int> rowid,
    });
typedef $$UsuariosTableUpdateCompanionBuilder =
    UsuariosCompanion Function({
      Value<String> uuid,
      Value<String> nombre,
      Value<String> email,
      Value<int> rowid,
    });

class $$UsuariosTableFilterComposer
    extends Composer<_$AppDatabase, $UsuariosTable> {
  $$UsuariosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsuariosTableOrderingComposer
    extends Composer<_$AppDatabase, $UsuariosTable> {
  $$UsuariosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsuariosTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsuariosTable> {
  $$UsuariosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);
}

class $$UsuariosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsuariosTable,
          Usuario,
          $$UsuariosTableFilterComposer,
          $$UsuariosTableOrderingComposer,
          $$UsuariosTableAnnotationComposer,
          $$UsuariosTableCreateCompanionBuilder,
          $$UsuariosTableUpdateCompanionBuilder,
          (Usuario, BaseReferences<_$AppDatabase, $UsuariosTable, Usuario>),
          Usuario,
          PrefetchHooks Function()
        > {
  $$UsuariosTableTableManager(_$AppDatabase db, $UsuariosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsuariosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsuariosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsuariosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsuariosCompanion(
                uuid: uuid,
                nombre: nombre,
                email: email,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                required String nombre,
                required String email,
                Value<int> rowid = const Value.absent(),
              }) => UsuariosCompanion.insert(
                uuid: uuid,
                nombre: nombre,
                email: email,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsuariosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsuariosTable,
      Usuario,
      $$UsuariosTableFilterComposer,
      $$UsuariosTableOrderingComposer,
      $$UsuariosTableAnnotationComposer,
      $$UsuariosTableCreateCompanionBuilder,
      $$UsuariosTableUpdateCompanionBuilder,
      (Usuario, BaseReferences<_$AppDatabase, $UsuariosTable, Usuario>),
      Usuario,
      PrefetchHooks Function()
    >;
typedef $$SyncMetaTableCreateCompanionBuilder =
    SyncMetaCompanion Function({
      required String clave,
      required String valor,
      Value<int> rowid,
    });
typedef $$SyncMetaTableUpdateCompanionBuilder =
    SyncMetaCompanion Function({
      Value<String> clave,
      Value<String> valor,
      Value<int> rowid,
    });

class $$SyncMetaTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clave => $composableBuilder(
    column: $table.clave,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clave => $composableBuilder(
    column: $table.clave,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clave =>
      $composableBuilder(column: $table.clave, builder: (column) => column);

  GeneratedColumn<String> get valor =>
      $composableBuilder(column: $table.valor, builder: (column) => column);
}

class $$SyncMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetaTable,
          SyncMetaDato,
          $$SyncMetaTableFilterComposer,
          $$SyncMetaTableOrderingComposer,
          $$SyncMetaTableAnnotationComposer,
          $$SyncMetaTableCreateCompanionBuilder,
          $$SyncMetaTableUpdateCompanionBuilder,
          (
            SyncMetaDato,
            BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaDato>,
          ),
          SyncMetaDato,
          PrefetchHooks Function()
        > {
  $$SyncMetaTableTableManager(_$AppDatabase db, $SyncMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clave = const Value.absent(),
                Value<String> valor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetaCompanion(clave: clave, valor: valor, rowid: rowid),
          createCompanionCallback:
              ({
                required String clave,
                required String valor,
                Value<int> rowid = const Value.absent(),
              }) => SyncMetaCompanion.insert(
                clave: clave,
                valor: valor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetaTable,
      SyncMetaDato,
      $$SyncMetaTableFilterComposer,
      $$SyncMetaTableOrderingComposer,
      $$SyncMetaTableAnnotationComposer,
      $$SyncMetaTableCreateCompanionBuilder,
      $$SyncMetaTableUpdateCompanionBuilder,
      (
        SyncMetaDato,
        BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaDato>,
      ),
      SyncMetaDato,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NotasTableTableManager get notas =>
      $$NotasTableTableManager(_db, _db.notas);
  $$AdjuntosTableTableManager get adjuntos =>
      $$AdjuntosTableTableManager(_db, _db.adjuntos);
  $$HistorialCambiosTableTableManager get historialCambios =>
      $$HistorialCambiosTableTableManager(_db, _db.historialCambios);
  $$UsuariosTableTableManager get usuarios =>
      $$UsuariosTableTableManager(_db, _db.usuarios);
  $$SyncMetaTableTableManager get syncMeta =>
      $$SyncMetaTableTableManager(_db, _db.syncMeta);
}

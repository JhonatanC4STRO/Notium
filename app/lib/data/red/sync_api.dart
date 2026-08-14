import 'package:dio/dio.dart';

import 'auth_api.dart';

/// Una operación del lote de `/sync/push` (esquema `OperacionSync` de
/// openapi.yaml). El `device_id` NO va por operación: se envía a nivel de
/// lote (sección 5.5).
class OperacionSync {
  const OperacionSync({
    required this.uuid,
    required this.entidad,
    required this.operacion,
    required this.payload,
    required this.updatedAt,
    required this.version,
  });

  final String uuid;
  final String entidad; // NOTA | ADJUNTO
  final String operacion; // CREATE | UPDATE | DELETE
  final Map<String, Object?> payload;
  final String updatedAt; // ISO 8601 UTC
  final int version;

  Map<String, Object?> toJson() => {
        'uuid': uuid,
        'entidad': entidad,
        'operacion': operacion,
        'payload': payload,
        'updated_at': updatedAt,
        'version': version,
      };
}

/// Resultado del procesamiento de una operación (esquema `ResultadoSync`).
class ResultadoSync {
  const ResultadoSync({
    required this.uuid,
    required this.estado,
    this.versionServidor,
    this.payloadServidor,
    this.error,
  });

  final String uuid;
  final String estado; // ACCEPTED | CONFLICT | ERROR
  final int? versionServidor;
  final Map<String, Object?>? payloadServidor;
  final Map<String, Object?>? error;

  factory ResultadoSync.fromJson(Map<String, Object?> json) => ResultadoSync(
        uuid: json['uuid'] as String,
        estado: json['estado'] as String,
        versionServidor: json['version_servidor'] as int?,
        payloadServidor: (json['payload_servidor'] as Map?)?.cast<String, Object?>(),
        error: (json['error'] as Map?)?.cast<String, Object?>(),
      );
}

/// Respuesta completa de `/sync/push` (esquema `SyncPushResponse`).
class RespuestaPush {
  const RespuestaPush({required this.resultados, required this.huboConflicto});

  final List<ResultadoSync> resultados;

  /// Verdadero si el servidor respondió 409 (al menos un CONFLICT).
  final bool huboConflicto;
}

/// Un cambio autoritativo del servidor (esquema `CambioServidor`).
class CambioServidor {
  const CambioServidor({
    required this.uuid,
    required this.entidad,
    required this.operacion,
    required this.payload,
    required this.version,
    required this.updatedAt,
    required this.isDeleted,
    this.deviceId,
  });

  final String uuid;
  final String entidad; // NOTA | ADJUNTO
  final String operacion; // CREATE | UPDATE | DELETE
  final Map<String, Object?> payload;
  final int version;
  final String updatedAt;
  final bool isDeleted;
  final String? deviceId;

  factory CambioServidor.fromJson(Map<String, Object?> json) => CambioServidor(
        uuid: json['uuid'] as String,
        entidad: json['entidad'] as String,
        operacion: json['operacion'] as String,
        payload: (json['payload'] as Map?)?.cast<String, Object?>() ?? const {},
        version: json['version'] as int,
        updatedAt: json['updated_at'] as String,
        isDeleted: json['is_deleted'] as bool,
        deviceId: json['device_id'] as String?,
      );
}

/// Respuesta paginada de `/sync/pull` (esquema `SyncPullResponse`).
class RespuestaPull {
  const RespuestaPull({
    required this.cambios,
    required this.timestampServidor,
    required this.hayMas,
  });

  final List<CambioServidor> cambios;
  final String timestampServidor;
  final bool hayMas;
}

/// Endpoints de sincronización (tareas 3.2/3.3). Usa el Dio autenticado: el
/// interceptor adjunta el token y refresca en 401 (CU-03).
class SyncApi {
  SyncApi(this._dio);

  final Dio _dio;

  /// `POST /sync/push`. Devuelve los resultados en el mismo orden del lote.
  /// 200 (sin conflictos) y 409 (con conflictos) traen ambos el array
  /// completo; se aceptan los dos como respuesta válida para que el 401
  /// siga disparando el refresh del interceptor.
  Future<RespuestaPush> push({
    required String deviceId,
    required List<OperacionSync> operaciones,
  }) async {
    try {
      final respuesta = await _dio.post<Map<String, Object?>>(
        '/sync/push',
        data: {
          'device_id': deviceId,
          'operaciones': operaciones.map((o) => o.toJson()).toList(),
        },
        options: Options(validateStatus: (s) => s == 200 || s == 409),
      );
      final lista = (respuesta.data!['resultados'] as List)
          .map((e) => ResultadoSync.fromJson((e as Map).cast<String, Object?>()))
          .toList();
      return RespuestaPush(
        resultados: lista,
        huboConflicto: respuesta.statusCode == 409,
      );
    } on DioException catch (e) {
      throw _traducir(e);
    }
  }

  /// `GET /sync/pull`. Una sola página; la paginación (mientras `hay_mas`) la
  /// orquesta `SyncService.pull` avanzando el cursor `desde`.
  Future<RespuestaPull> pull({
    required String desde,
    String? deviceId,
    int limite = 100,
  }) async {
    try {
      final respuesta = await _dio.get<Map<String, Object?>>(
        '/sync/pull',
        queryParameters: {
          'desde': desde,
          'device_id': ?deviceId,
          'limite': limite,
        },
      );
      final datos = respuesta.data!;
      final cambios = (datos['cambios'] as List)
          .map((e) => CambioServidor.fromJson((e as Map).cast<String, Object?>()))
          .toList();
      return RespuestaPull(
        cambios: cambios,
        timestampServidor: datos['timestamp_servidor'] as String,
        hayMas: datos['hay_mas'] as bool,
      );
    } on DioException catch (e) {
      throw _traducir(e);
    }
  }

  Exception _traducir(DioException e) {
    final cuerpo = e.response?.data;
    if (cuerpo is Map<String, Object?> && cuerpo['codigo'] is String) {
      return ApiException(
        codigo: cuerpo['codigo'] as String,
        mensaje: (cuerpo['mensaje'] as String?) ?? 'Error del servidor',
        status: e.response?.statusCode,
      );
    }
    if (e.response != null) {
      return ApiException(
        codigo: 'HTTP_${e.response!.statusCode}',
        mensaje: 'Respuesta inesperada del servidor',
        status: e.response!.statusCode,
      );
    }
    return SinConexionException();
  }
}

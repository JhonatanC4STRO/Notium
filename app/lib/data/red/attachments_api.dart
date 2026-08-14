import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import 'auth_api.dart';

/// Metadatos de un adjunto devueltos por el servidor (esquema `Adjunto`).
class AdjuntoRemoto {
  const AdjuntoRemoto({required this.uuid, required this.urlRemota});

  final String uuid;
  final String? urlRemota;

  factory AdjuntoRemoto.fromJson(Map<String, Object?> json) => AdjuntoRemoto(
        uuid: json['uuid'] as String,
        urlRemota: json['url_remota'] as String?,
      );
}

/// Adjuntos (tarea 3.5): el binario viaja FUERA del lote de sincronización
/// (RNF-05). Usa el Dio autenticado (refresh en 401, CU-03).
class AttachmentsApi {
  AttachmentsApi(this._dio);

  final Dio _dio;

  /// `POST /attachments` (multipart). El límite de 10 MB (RNF-05) ya se validó
  /// en el cliente al adjuntar (2.3); un `413` del servidor se traduce a
  /// `ApiException(status: 413)` para marcar el registro como ERROR (CU-08).
  Future<AdjuntoRemoto> subir({
    required String uuid,
    required String notaUuid,
    String? deviceId,
    required File archivo,
  }) async {
    final form = FormData.fromMap({
      'uuid': uuid,
      'nota_uuid': notaUuid,
      'device_id': ?deviceId,
      'archivo': await MultipartFile.fromFile(
        archivo.path,
        filename: p.basename(archivo.path),
      ),
    });
    try {
      final respuesta =
          await _dio.post<Map<String, Object?>>('/attachments', data: form);
      return AdjuntoRemoto.fromJson(respuesta.data!);
    } on DioException catch (e) {
      throw _traducir(e);
    }
  }

  /// `GET /attachments/{uuid}` → bytes del binario. `410` (tombstone) y `404`
  /// se propagan como `ApiException`.
  Future<List<int>> descargar(String uuid) async {
    try {
      final respuesta = await _dio.get<List<int>>(
        '/attachments/$uuid',
        options: Options(responseType: ResponseType.bytes),
      );
      return respuesta.data!;
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

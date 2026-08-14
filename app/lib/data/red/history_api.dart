import 'package:dio/dio.dart';

import 'auth_api.dart';

/// Una entrada del historial de auditoría según el servidor (esquema
/// `HistorialCambio` de openapi.yaml).
class HistorialRemoto {
  const HistorialRemoto({
    required this.uuid,
    required this.tipoCambio,
    required this.origenCambio,
    required this.fecha,
    this.dispositivoOrigen,
    this.valorAnterior,
    this.valorNuevo,
  });

  final String uuid;
  final String tipoCambio;
  final String origenCambio; // LOCAL | REMOTO | CONFLICTO_DESCARTADO
  final String fecha; // ISO 8601
  final String? dispositivoOrigen;
  final String? valorAnterior;
  final String? valorNuevo;

  factory HistorialRemoto.fromJson(Map<String, Object?> json) => HistorialRemoto(
        uuid: json['uuid'] as String,
        tipoCambio: json['tipo_cambio'] as String,
        origenCambio: json['origen_cambio'] as String,
        fecha: json['fecha'] as String,
        dispositivoOrigen: json['dispositivo_origen'] as String?,
        valorAnterior: json['valor_anterior'] as String?,
        valorNuevo: json['valor_nuevo'] as String?,
      );
}

/// Historial de auditoría de una nota en el servidor (tarea 4.1, RF-05). Es la
/// vista autoritativa entre dispositivos; complementa al historial local.
class HistoryApi {
  HistoryApi(this._dio);

  final Dio _dio;

  Future<List<HistorialRemoto>> obtener(String notaUuid) async {
    try {
      final respuesta =
          await _dio.get<Map<String, Object?>>('/history/$notaUuid');
      return (respuesta.data!['historial'] as List)
          .map((e) => HistorialRemoto.fromJson((e as Map).cast<String, Object?>()))
          .toList();
    } on DioException catch (e) {
      final cuerpo = e.response?.data;
      if (cuerpo is Map<String, Object?> && cuerpo['codigo'] is String) {
        throw ApiException(
          codigo: cuerpo['codigo'] as String,
          mensaje: (cuerpo['mensaje'] as String?) ?? 'Error del servidor',
          status: e.response?.statusCode,
        );
      }
      if (e.response != null) {
        throw ApiException(
          codigo: 'HTTP_${e.response!.statusCode}',
          mensaje: 'Respuesta inesperada del servidor',
          status: e.response!.statusCode,
        );
      }
      throw SinConexionException();
    }
  }
}

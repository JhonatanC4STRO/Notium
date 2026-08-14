import 'package:dio/dio.dart';

import '../../domain/sesion.dart';

/// Errores traducidos de la API (esquema `Error` de openapi.yaml).
class ApiException implements Exception {
  ApiException({required this.codigo, required this.mensaje, this.status});

  final String codigo;
  final String mensaje;
  final int? status;

  @override
  String toString() => 'ApiException($codigo): $mensaje';
}

/// Fallo de red (sin respuesta del servidor): timeout, DNS, sin conexión.
/// El registro que lo cause queda PENDING y se reintenta (sección 5.2).
class SinConexionException implements Exception {
  @override
  String toString() => 'SinConexionException: no hay conexión con el servidor';
}

class TokensRemotos {
  const TokensRemotos({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInSegundos,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresInSegundos;

  factory TokensRemotos.fromJson(Map<String, Object?> json) => TokensRemotos(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        expiresInSegundos: json['expires_in'] as int,
      );
}

class SesionRemota {
  const SesionRemota({required this.usuario, required this.tokens});

  final UsuarioSesion usuario;
  final TokensRemotos tokens;

  factory SesionRemota.fromJson(Map<String, Object?> json) => SesionRemota(
        usuario: UsuarioSesion.fromJson(json['usuario'] as Map<String, Object?>),
        tokens: TokensRemotos.fromJson(json['tokens'] as Map<String, Object?>),
      );
}

/// Endpoints de /auth (CU-01 a CU-03). Usa el Dio SIN interceptor de auth:
/// login/register no llevan token y refresh gestiona el suyo a mano.
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<SesionRemota> registrar({
    required String uuid, // generado por el cliente (sección 5.1)
    required String nombre,
    required String email,
    required String contrasena,
  }) async {
    final respuesta = await _atrapar(() => _dio.post<Map<String, Object?>>(
          '/auth/register',
          data: {'uuid': uuid, 'nombre': nombre, 'email': email, 'contrasena': contrasena},
        ));
    return SesionRemota.fromJson(respuesta.data!);
  }

  Future<SesionRemota> login({required String email, required String contrasena}) async {
    final respuesta = await _atrapar(() => _dio.post<Map<String, Object?>>(
          '/auth/login',
          data: {'email': email, 'contrasena': contrasena},
        ));
    return SesionRemota.fromJson(respuesta.data!);
  }

  /// El contrato exige el access token (aunque esté EXPIRADO) en la
  /// cabecera; el servidor valida solo la firma (CU-03).
  Future<TokensRemotos> refrescar({
    required String accessTokenExpirado,
    required String refreshToken,
  }) async {
    final respuesta = await _atrapar(() => _dio.post<Map<String, Object?>>(
          '/auth/refresh',
          data: {'refresh_token': refreshToken},
          options: Options(headers: {'authorization': 'Bearer $accessTokenExpirado'}),
        ));
    return TokensRemotos.fromJson(respuesta.data!);
  }

  Future<void> cerrarSesion({
    required String accessToken,
    required String refreshToken,
  }) {
    return _atrapar(() => _dio.post<void>(
          '/auth/logout',
          data: {'refresh_token': refreshToken},
          options: Options(headers: {'authorization': 'Bearer $accessToken'}),
        ));
  }

  Future<Response<T>> _atrapar<T>(Future<Response<T>> Function() peticion) async {
    try {
      return await peticion();
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

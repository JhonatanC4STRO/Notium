import 'package:dio/dio.dart';

import '../auth/almacen_sesion.dart';
import 'auth_api.dart';

/// Interceptor de autenticación y refresh automático (tarea 3.1, CU-03).
///
/// - `onRequest`: adjunta el access token vigente.
/// - `onError` 401: refresca el par de tokens y REINTENTA la petición
///   original de forma transparente.
///
/// Reentrada (el "cuidado" del roadmap): extiende [QueuedInterceptor], que
/// serializa los handlers — mientras un refresh está en vuelo, los demás
/// 401 esperan en cola. Al despertar, cada uno compara el token con el que
/// usó su petición fallida: si ya cambió (otro refresh ganó), reintenta
/// directamente sin refrescar de nuevo. Resultado: un solo refresh por
/// expiración, sin carreras que quemen el refresh token rotativo del
/// backend (reusar un refresh rotado responde 401 definitivo).
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this._almacen,
    required this._authApi,
    required Dio dioSinAuth,
    this.alExpirarSesion,
  }) : _dioReintento = dioSinAuth;

  final AlmacenSesion _almacen;
  final AuthApi _authApi;

  /// Dio SIN este interceptor: reintentar con el Dio interceptado podría
  /// encolar recursivamente otro ciclo de refresh.
  final Dio _dioReintento;

  /// Notifica a la capa de sesión que el refresh falló definitivamente
  /// (refresh token inválido/expirado): el usuario debe reautenticarse.
  final void Function()? alExpirarSesion;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _almacen.accessToken();
    if (token != null) {
      options.headers['authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final esAuth = err.requestOptions.path.startsWith('/auth/');
    final ya401 = err.response?.statusCode == 401;
    final yaReintentada = err.requestOptions.extra['notium_reintentada'] == true;

    // Los 401 de /auth son de credenciales, no de token vencido; y una
    // petición ya reintentada que vuelve a fallar no se reintenta más.
    if (!ya401 || esAuth || yaReintentada) {
      return handler.next(err);
    }

    final tokenUsado = _extraerBearer(err.requestOptions);
    final tokenActual = await _almacen.accessToken();
    if (tokenActual == null) return handler.next(err); // sesión ya cerrada

    var tokenParaReintento = tokenActual;

    if (tokenActual == tokenUsado) {
      // Nadie refrescó todavía: nos toca (single-flight garantizado por la
      // serialización de QueuedInterceptor).
      final refreshToken = await _almacen.refreshToken();
      if (refreshToken == null) return handler.next(err);

      try {
        final nuevos = await _authApi.refrescar(
          accessTokenExpirado: tokenActual,
          refreshToken: refreshToken,
        );
        await _almacen.actualizarTokens(
          accessToken: nuevos.accessToken,
          refreshToken: nuevos.refreshToken,
          expiraEn: DateTime.now()
              .toUtc()
              .add(Duration(seconds: nuevos.expiresInSegundos)),
        );
        tokenParaReintento = nuevos.accessToken;
      } on ApiException {
        // Refresh inválido/expirado: sesión terminada (CU-03 rama de error).
        await _almacen.limpiar();
        alExpirarSesion?.call();
        return handler.next(err);
      } on SinConexionException {
        // Sin red no hay refresh posible; el registro queda PENDING y la
        // SyncTask reintentará (sección 5.2).
        return handler.next(err);
      }
    }
    // Si el token ya cambió, otro handler refrescó mientras esperábamos:
    // basta reintentar con el token nuevo.

    try {
      final opciones = err.requestOptions
        ..extra['notium_reintentada'] = true
        ..headers['authorization'] = 'Bearer $tokenParaReintento';
      final respuesta = await _dioReintento.fetch<Object?>(opciones);
      handler.resolve(respuesta);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  String? _extraerBearer(RequestOptions options) {
    final cabecera = options.headers['authorization'];
    if (cabecera is String && cabecera.startsWith('Bearer ')) {
      return cabecera.substring(7);
    }
    return null;
  }
}

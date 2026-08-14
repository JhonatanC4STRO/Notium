import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notium/data/auth/almacen_seguro.dart';
import 'package:notium/data/auth/almacen_sesion.dart';
import 'package:notium/data/red/auth_api.dart';
import 'package:notium/data/red/auth_interceptor.dart';
import 'package:notium/domain/sesion.dart';

/// Tests del interceptor de refresh (tarea 3.1, CU-03) con un adaptador
/// HTTP falso: sin red ni backend real.
///
/// El adaptador simula el comportamiento del backend de la fase 1:
/// - Los recursos responden 401 a todo access token distinto del vigente.
/// - /auth/refresh rota los tokens; reusar un refresh rotado da 401.
void main() {
  late AlmacenSeguroEnMemoria almacenCrudo;
  late AlmacenSesion almacen;
  late _BackendFalso backend;
  late Dio dio;
  late bool sesionExpirada;

  Future<void> guardarSesionInicial({required String access, required String refresh}) {
    return almacen.guardarSesion(Sesion(
      usuario: const UsuarioSesion(uuid: 'u-1', nombre: 'Test', email: 't@t.co'),
      accessToken: access,
      refreshToken: refresh,
      expiraEn: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
    ));
  }

  setUp(() async {
    almacenCrudo = AlmacenSeguroEnMemoria();
    almacen = AlmacenSesion(almacenCrudo);
    backend = _BackendFalso(accessVigente: 'access-1', refreshVigente: 'refresh-1');
    sesionExpirada = false;

    final dioSinAuth = Dio(BaseOptions(baseUrl: 'http://backend.falso/v1'))
      ..httpClientAdapter = backend;
    dio = Dio(BaseOptions(baseUrl: 'http://backend.falso/v1'))
      ..httpClientAdapter = backend
      ..interceptors.add(AuthInterceptor(
        almacen: almacen,
        authApi: AuthApi(dioSinAuth),
        dioSinAuth: dioSinAuth,
        alExpirarSesion: () => sesionExpirada = true,
      ));
  });

  test('401 → refresh → reintento transparente con el token nuevo (CU-03)', () async {
    await guardarSesionInicial(access: 'access-viejo', refresh: 'refresh-1');

    final respuesta = await dio.get<Map<String, Object?>>('/sync/pull');

    expect(respuesta.statusCode, 200);
    expect(backend.refreshsAtendidos, 1);
    // El par rotado quedó persistido para las siguientes peticiones.
    expect(await almacen.accessToken(), 'access-2');
    expect(await almacen.refreshToken(), 'refresh-2');
  });

  test('reentrada: N peticiones concurrentes con token vencido → UN solo refresh', () async {
    await guardarSesionInicial(access: 'access-viejo', refresh: 'refresh-1');

    final respuestas = await Future.wait([
      dio.get<Map<String, Object?>>('/sync/pull'),
      dio.get<Map<String, Object?>>('/history/x'),
      dio.get<Map<String, Object?>>('/sync/pull'),
    ]);

    expect(respuestas.map((r) => r.statusCode), everyElement(200));
    // Un segundo refresh habría quemado el token rotado → 401 definitivo.
    expect(backend.refreshsAtendidos, 1);
  });

  test('refresh inválido → limpia la sesión y notifica (reautenticación)', () async {
    await guardarSesionInicial(access: 'access-viejo', refresh: 'refresh-quemado');

    await expectLater(
      dio.get<Map<String, Object?>>('/sync/pull'),
      throwsA(isA<DioException>()),
    );

    expect(sesionExpirada, true);
    expect(await almacen.leerSesion(), isNull);
  });

  test('los 401 de /auth (credenciales) NO disparan refresh', () async {
    await guardarSesionInicial(access: 'access-viejo', refresh: 'refresh-1');

    await expectLater(
      dio.post<Map<String, Object?>>('/auth/login'),
      throwsA(isA<DioException>()),
    );
    expect(backend.refreshsAtendidos, 0);
  });
}

/// Adaptador HTTP que simula el backend (tokens rotativos como en fase 1.2).
class _BackendFalso implements HttpClientAdapter {
  _BackendFalso({required this.accessVigente, required this.refreshVigente});

  String accessVigente;
  String refreshVigente;
  int refreshsAtendidos = 0;
  int _generacion = 1;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final ruta = options.path;

    if (ruta.endsWith('/auth/login')) {
      return _json(401, {'codigo': 'CREDENCIALES_INVALIDAS', 'mensaje': 'no'});
    }

    if (ruta.endsWith('/auth/refresh')) {
      final cuerpo = _cuerpoDe(options);
      if (cuerpo['refresh_token'] != refreshVigente) {
        return _json(401, {'codigo': 'REFRESH_INVALIDO', 'mensaje': 'inválido'});
      }
      refreshsAtendidos++;
      _generacion++;
      accessVigente = 'access-$_generacion';
      refreshVigente = 'refresh-$_generacion';
      return _json(200, {
        'access_token': accessVigente,
        'refresh_token': refreshVigente,
        'token_type': 'Bearer',
        'expires_in': 900,
      });
    }

    // Recurso protegido: exige el access vigente.
    final autorizacion = options.headers['authorization'];
    if (autorizacion != 'Bearer $accessVigente') {
      return _json(401, {'codigo': 'TOKEN_EXPIRADO', 'mensaje': 'expirado'});
    }
    return _json(200, {'ok': true});
  }

  /// El adapter puede recibir el body como Map (sin transformar) o String.
  Map<String, Object?> _cuerpoDe(RequestOptions options) {
    final datos = options.data;
    if (datos is Map) return datos.cast<String, Object?>();
    if (datos is String && datos.isNotEmpty) {
      return (jsonDecode(datos) as Map).cast<String, Object?>();
    }
    return const {};
  }

  ResponseBody _json(int status, Map<String, Object?> cuerpo) =>
      ResponseBody.fromString(
        jsonEncode(cuerpo),
        status,
        headers: {
          'content-type': ['application/json; charset=utf-8'],
        },
      );

  @override
  void close({bool force = false}) {}
}

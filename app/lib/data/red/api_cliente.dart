import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// URL base de la API por entorno (tarea 3.1). El default apunta al backend
/// local visto desde el emulador Android (10.0.2.2 = host). Producción:
///   flutter run --dart-define=API_BASE_URL=https://api.midominio.com/v1
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000/v1',
);

/// Dio base con timeouts y logging de desarrollo. No incluye el interceptor
/// de auth: esa variante la arma el provider (evita el ciclo refresh→401).
Dio crearDioBase({String? baseUrl}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
    ),
  );
  if (kDebugMode) {
    // Sin cuerpos: los payloads de sync pueden ser grandes y el de auth
    // lleva credenciales.
    dio.interceptors.add(LogInterceptor(requestBody: false, responseBody: false));
  }
  return dio;
}

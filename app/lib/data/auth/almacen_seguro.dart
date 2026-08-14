import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstracción mínima sobre el almacenamiento seguro, para poder testear la
/// lógica de sesión sin el plugin de plataforma.
abstract class AlmacenSeguro {
  Future<String?> leer(String clave);
  Future<void> escribir(String clave, String valor);
  Future<void> eliminar(String clave);
}

/// Implementación real: flutter_secure_storage (Android Keystore).
class AlmacenSeguroDispositivo implements AlmacenSeguro {
  const AlmacenSeguroDispositivo([this._almacen = const FlutterSecureStorage()]);

  final FlutterSecureStorage _almacen;

  @override
  Future<String?> leer(String clave) => _almacen.read(key: clave);

  @override
  Future<void> escribir(String clave, String valor) =>
      _almacen.write(key: clave, value: valor);

  @override
  Future<void> eliminar(String clave) => _almacen.delete(key: clave);
}

/// Implementación en memoria para tests.
class AlmacenSeguroEnMemoria implements AlmacenSeguro {
  final Map<String, String> valores = {};

  @override
  Future<String?> leer(String clave) async => valores[clave];

  @override
  Future<void> escribir(String clave, String valor) async => valores[clave] = valor;

  @override
  Future<void> eliminar(String clave) async => valores.remove(clave);
}

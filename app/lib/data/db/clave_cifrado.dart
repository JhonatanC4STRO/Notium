import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Gestión de la clave de cifrado de SQLCipher (sección 8 del doc): se
/// genera una sola vez con un RNG criptográfico y vive en
/// flutter_secure_storage (Android Keystore), nunca en la BD ni en el
/// código. Sin esta clave, el archivo notium.db es ilegible (criterio de
/// salida de la fase 2).
class ClaveCifrado {
  ClaveCifrado(this._almacen);

  final FlutterSecureStorage _almacen;

  static const _campo = 'notium_clave_sqlcipher';

  /// Devuelve la clave existente o crea una nueva de 32 bytes.
  ///
  /// Formato: hex crudo para usarse como `PRAGMA key = "x'<hex>'"`, la
  /// variante binaria de SQLCipher que evita el derivado PBKDF2 de
  /// contraseñas de texto y cualquier problema de escapado.
  Future<String> obtenerOCrear() async {
    final existente = await _almacen.read(key: _campo);
    if (existente != null) return existente;

    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    final clave =
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    await _almacen.write(key: _campo, value: clave);
    return clave;
  }
}

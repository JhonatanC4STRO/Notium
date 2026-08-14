import 'dart:convert';

import '../../domain/sesion.dart';
import 'almacen_seguro.dart';

/// Persistencia de la sesión en el almacenamiento seguro (sección 8): los
/// tokens NUNCA tocan la base de datos ni SharedPreferences.
class AlmacenSesion {
  AlmacenSesion(this._almacen);

  final AlmacenSeguro _almacen;

  static const _claveAccess = 'notium_access_token';
  static const _claveRefresh = 'notium_refresh_token';
  static const _claveExpira = 'notium_expira_en';
  static const _claveUsuario = 'notium_usuario';

  Future<void> guardarSesion(Sesion sesion) async {
    await _almacen.escribir(_claveAccess, sesion.accessToken);
    await _almacen.escribir(_claveRefresh, sesion.refreshToken);
    await _almacen.escribir(_claveExpira, sesion.expiraEn.toIso8601String());
    await _almacen.escribir(_claveUsuario, jsonEncode(sesion.usuario.toJson()));
  }

  /// Rotación de tokens (la usa el interceptor de refresh): conserva el
  /// usuario y reemplaza el par completo.
  Future<void> actualizarTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiraEn,
  }) async {
    await _almacen.escribir(_claveAccess, accessToken);
    await _almacen.escribir(_claveRefresh, refreshToken);
    await _almacen.escribir(_claveExpira, expiraEn.toIso8601String());
  }

  Future<Sesion?> leerSesion() async {
    final access = await _almacen.leer(_claveAccess);
    final refresh = await _almacen.leer(_claveRefresh);
    final expira = await _almacen.leer(_claveExpira);
    final usuario = await _almacen.leer(_claveUsuario);
    if (access == null || refresh == null || expira == null || usuario == null) {
      return null;
    }
    return Sesion(
      usuario: UsuarioSesion.fromJson(jsonDecode(usuario) as Map<String, Object?>),
      accessToken: access,
      refreshToken: refresh,
      expiraEn: DateTime.parse(expira),
    );
  }

  Future<String?> accessToken() => _almacen.leer(_claveAccess);
  Future<String?> refreshToken() => _almacen.leer(_claveRefresh);

  Future<void> limpiar() async {
    await _almacen.eliminar(_claveAccess);
    await _almacen.eliminar(_claveRefresh);
    await _almacen.eliminar(_claveExpira);
    await _almacen.eliminar(_claveUsuario);
  }
}

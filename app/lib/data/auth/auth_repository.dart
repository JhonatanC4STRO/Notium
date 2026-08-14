import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/sesion.dart';
import '../db/app_database.dart';
import '../red/auth_api.dart';
import 'almacen_sesion.dart';

/// Autenticación del cliente (tarea 3.1, CU-01/CU-02).
///
/// - El registro genera el uuid del usuario EN EL CLIENTE (sección 5.1).
/// - Login/registro guardan la sesión en el almacenamiento seguro y cachean
///   el usuario en la BD local (tabla usuarios, sección 4.1).
/// - `sesionGuardada()` es el login offline de CU-02: no toca la red; la
///   validez se decide con `Sesion.estadoEn` (validación local de
///   expiración + ventana degradada).
class AuthRepository {
  AuthRepository({
    required this._api,
    required this._almacen,
    required this._db,
  });

  final AuthApi _api;
  final AlmacenSesion _almacen;
  final AppDatabase _db;

  static const _uuid = Uuid();

  /// Identidad provisional de los datos creados antes del primer login
  /// (fase 2 era 100% offline y sin cuentas).
  static const usuarioLocalUuid = 'usuario-local';

  Future<Sesion> registrar({
    required String nombre,
    required String email,
    required String contrasena,
  }) async {
    final remota = await _api.registrar(
      uuid: _uuid.v4(),
      nombre: nombre,
      email: email,
      contrasena: contrasena,
    );
    return _persistir(remota);
  }

  Future<Sesion> login({required String email, required String contrasena}) async {
    final remota = await _api.login(email: email, contrasena: contrasena);
    return _persistir(remota);
  }

  /// CU-02 sin red: devuelve la sesión cacheada sin validar contra el
  /// servidor. El primer login siempre exige red (sin sesión → null).
  Future<Sesion?> sesionGuardada() => _almacen.leerSesion();

  /// Invalida el refresh token en el servidor cuando hay red; si no la hay,
  /// la sesión local se limpia igual y la invalidación remota queda para la
  /// próxima conexión (mitigación de la sección 9).
  Future<void> cerrarSesion() async {
    final sesion = await _almacen.leerSesion();
    if (sesion != null) {
      try {
        await _api.cerrarSesion(
          accessToken: sesion.accessToken,
          refreshToken: sesion.refreshToken,
        );
      } on SinConexionException {
        // Offline: solo limpieza local.
      } on ApiException {
        // Token ya inválido en el servidor: nada que invalidar.
      }
    }
    await _almacen.limpiar();
  }

  Future<Sesion> _persistir(SesionRemota remota) async {
    final sesion = Sesion(
      usuario: remota.usuario,
      accessToken: remota.tokens.accessToken,
      refreshToken: remota.tokens.refreshToken,
      expiraEn: DateTime.now()
          .toUtc()
          .add(Duration(seconds: remota.tokens.expiresInSegundos)),
    );

    await _almacen.guardarSesion(sesion);

    // Caché local del usuario (sección 4.1; los tokens NO van a la BD).
    await _db.into(_db.usuarios).insertOnConflictUpdate(
          UsuariosCompanion.insert(
            uuid: sesion.usuario.uuid,
            nombre: sesion.usuario.nombre,
            email: sesion.usuario.email,
          ),
        );

    // Adopción de los datos creados offline antes de tener cuenta: pasan a
    // pertenecer al usuario autenticado y se sincronizarán como suyos.
    await (_db.update(_db.notas)
          ..where((n) => n.usuarioUuid.equals(usuarioLocalUuid)))
        .write(NotasCompanion(usuarioUuid: Value(sesion.usuario.uuid)));

    return sesion;
  }
}

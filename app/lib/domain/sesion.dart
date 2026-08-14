/// Modelo de sesión local (sección 8 del doc, CU-02): la app valida la
/// expiración del token LOCALMENTE para permitir el uso offline.
library;

/// Ventana extendida (mitigación de la sección 9): si el access token
/// expiró hace menos de esto, la sesión queda "degradada" — se permite el
/// uso general offline y se bloquean solo operaciones sensibles hasta
/// refrescar el token al reconectar.
const Duration ventanaSesionDegradada = Duration(days: 7);

enum EstadoSesion {
  /// Access token vigente.
  activa,

  /// Access token expirado dentro de la ventana extendida: uso offline
  /// permitido; al reconectar, el interceptor refresca automáticamente.
  degradada,

  /// Expirado más allá de la ventana: reautenticación con credenciales.
  expirada,
}

class UsuarioSesion {
  const UsuarioSesion({required this.uuid, required this.nombre, required this.email});

  final String uuid;
  final String nombre;
  final String email;

  Map<String, Object?> toJson() => {'uuid': uuid, 'nombre': nombre, 'email': email};

  factory UsuarioSesion.fromJson(Map<String, Object?> json) => UsuarioSesion(
        uuid: json['uuid'] as String,
        nombre: json['nombre'] as String,
        email: json['email'] as String,
      );
}

class Sesion {
  const Sesion({
    required this.usuario,
    required this.accessToken,
    required this.refreshToken,
    required this.expiraEn,
  });

  final UsuarioSesion usuario;
  final String accessToken;
  final String refreshToken;

  /// Momento (UTC) en que expira el access token, calculado al recibirlo
  /// (`ahora + expires_in`): permite validar sin decodificar el JWT.
  final DateTime expiraEn;

  EstadoSesion estadoEn(DateTime ahora) {
    if (ahora.isBefore(expiraEn)) return EstadoSesion.activa;
    if (ahora.isBefore(expiraEn.add(ventanaSesionDegradada))) {
      return EstadoSesion.degradada;
    }
    return EstadoSesion.expirada;
  }
}

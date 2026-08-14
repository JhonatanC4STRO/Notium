import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notium/data/auth/almacen_seguro.dart';
import 'package:notium/data/auth/almacen_sesion.dart';
import 'package:notium/data/auth/auth_repository.dart';
import 'package:notium/data/db/app_database.dart';
import 'package:notium/data/red/auth_api.dart';
import 'package:notium/data/repositorios/nota_repository.dart';
import 'package:notium/domain/sesion.dart';

/// Tests del AuthRepository y de la validación local de sesión (tarea 3.1,
/// CU-01/CU-02) con una API falsa y almacén en memoria.
void main() {
  late AppDatabase db;
  late AlmacenSesion almacen;
  late _AuthApiFalsa api;
  late AuthRepository repo;

  const uuidV4 = r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$';

  setUp(() {
    db = AppDatabase.paraTests(NativeDatabase.memory());
    almacen = AlmacenSesion(AlmacenSeguroEnMemoria());
    api = _AuthApiFalsa();
    repo = AuthRepository(api: api, almacen: almacen, db: db);
  });

  tearDown(() => db.close());

  test('registrar genera el uuid EN EL CLIENTE (UUID v4, sección 5.1)', () async {
    await repo.registrar(nombre: 'Ana', email: 'ana@test.co', contrasena: 'clave12345');

    expect(api.uuidRecibido, matches(RegExp(uuidV4, caseSensitive: false)));
  });

  test('login persiste la sesión, cachea el usuario y adopta las notas offline', () async {
    // Datos creados en la fase 2, antes de tener cuenta.
    final notas = NotaRepository(db);
    await notas.crear(
      usuarioUuid: AuthRepository.usuarioLocalUuid,
      titulo: 'Creada sin cuenta',
    );

    final sesion = await repo.login(email: 'ana@test.co', contrasena: 'clave12345');

    // Sesión en el almacén seguro, restaurable (login offline de CU-02).
    final restaurada = await repo.sesionGuardada();
    expect(restaurada, isNotNull);
    expect(restaurada!.accessToken, sesion.accessToken);
    expect(restaurada.usuario.uuid, _AuthApiFalsa.usuarioUuid);

    // Usuario cacheado en la BD (sección 4.1).
    final usuarios = await db.select(db.usuarios).get();
    expect(usuarios.single.uuid, _AuthApiFalsa.usuarioUuid);

    // La nota offline ahora pertenece al usuario autenticado.
    final fila = await db.select(db.notas).getSingle();
    expect(fila.usuarioUuid, _AuthApiFalsa.usuarioUuid);
  });

  test('sin sesión guardada no hay login offline (el primero exige red)', () async {
    expect(await repo.sesionGuardada(), isNull);
  });

  test('cerrarSesion limpia lo local aunque no haya red (sección 9)', () async {
    await repo.login(email: 'ana@test.co', contrasena: 'clave12345');
    api.sinConexion = true; // el logout remoto fallará

    await repo.cerrarSesion();

    expect(await repo.sesionGuardada(), isNull);
  });

  group('validación local de expiración (CU-02 sin red)', () {
    Sesion sesionQueExpira(DateTime expiraEn) => Sesion(
          usuario: const UsuarioSesion(uuid: 'u', nombre: 'n', email: 'e@e.co'),
          accessToken: 'a',
          refreshToken: 'r',
          expiraEn: expiraEn,
        );

    final ahora = DateTime.utc(2026, 7, 15, 12);

    test('token vigente → activa', () {
      final s = sesionQueExpira(ahora.add(const Duration(minutes: 10)));
      expect(s.estadoEn(ahora), EstadoSesion.activa);
    });

    test('expirado dentro de la ventana extendida → degradada (uso offline)', () {
      final s = sesionQueExpira(ahora.subtract(const Duration(days: 3)));
      expect(s.estadoEn(ahora), EstadoSesion.degradada);
    });

    test('expirado más allá de la ventana → expirada (reautenticación)', () {
      final s = sesionQueExpira(ahora.subtract(ventanaSesionDegradada + const Duration(hours: 1)));
      expect(s.estadoEn(ahora), EstadoSesion.expirada);
    });
  });
}

/// AuthApi falsa: registra los argumentos y devuelve una sesión fija.
class _AuthApiFalsa extends AuthApi {
  _AuthApiFalsa() : super(Dio());

  static const usuarioUuid = 'b1a2c3d4-0000-4000-8000-000000000001';

  String? uuidRecibido;
  bool sinConexion = false;
  int logoutsRemotos = 0;

  SesionRemota _sesion(String uuid) => SesionRemota(
        usuario: const UsuarioSesion(uuid: usuarioUuid, nombre: 'Ana', email: 'ana@test.co'),
        tokens: const TokensRemotos(
          accessToken: 'access-falso',
          refreshToken: 'refresh-falso',
          expiresInSegundos: 900,
        ),
      );

  @override
  Future<SesionRemota> registrar({
    required String uuid,
    required String nombre,
    required String email,
    required String contrasena,
  }) async {
    uuidRecibido = uuid;
    return _sesion(uuid);
  }

  @override
  Future<SesionRemota> login({required String email, required String contrasena}) async {
    return _sesion(usuarioUuid);
  }

  @override
  Future<void> cerrarSesion({required String accessToken, required String refreshToken}) async {
    if (sinConexion) throw SinConexionException();
    logoutsRemotos++;
  }
}

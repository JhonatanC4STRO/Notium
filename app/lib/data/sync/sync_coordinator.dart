import '../auth/almacen_sesion.dart';
import '../red/auth_api.dart';
import 'attachment_service.dart';
import 'purga_service.dart';
import 'sync_service.dart';

/// Desenlace de un ciclo de sincronización completo.
enum DesenlaceSync {
  /// push y pull completaron.
  ok,

  /// Falló la red (CU-07): los registros siguen PENDING; conviene reintentar
  /// con backoff.
  sinRed,

  /// El refresh de token falló o no hay sesión (CU-03): los registros siguen
  /// PENDING y la sesión queda marcada para reautenticación. Reintentar no
  /// ayuda hasta que el usuario vuelva a iniciar sesión.
  sesionExpirada,

  /// Error inesperado del servidor (p. ej. 5xx): conviene reintentar.
  error,
}

/// Orquesta un ciclo push → pull y traduce los fallos a un [DesenlaceSync]
/// (tarea 3.4). Es independiente de `workmanager`, Riverpod y las plataformas:
/// lo usan tanto el disparo inmediato en foreground como el isolate de fondo,
/// y se prueba unitariamente con dobles.
class SyncCoordinator {
  SyncCoordinator({
    required this.sync,
    required this.almacenSesion,
    this.adjuntos,
    this.purga,
    bool Function()? sesionExpiro,
  }) : _sesionExpiro = sesionExpiro ?? (() => false);

  final SyncService sync;
  final AlmacenSesion almacenSesion;

  /// Subida de binarios tras el push (tarea 3.5). Opcional: los tests del
  /// coordinador lo omiten.
  final AttachmentService? adjuntos;

  /// Purga de tombstones vencidos (tarea 3.5). Opcional; best-effort: un fallo
  /// aquí no invalida el resto del ciclo.
  final PurgaService? purga;

  /// Señal opcional del interceptor: el refresh de token falló definitivamente
  /// durante el ciclo. Complementa la detección por `ApiException` 401.
  final bool Function() _sesionExpiro;

  Future<DesenlaceSync> ejecutar() async {
    final sesion = await almacenSesion.leerSesion();
    if (sesion == null) return DesenlaceSync.sesionExpirada;

    try {
      // push primero: sube los cambios locales antes de traer los remotos,
      // para que un conflicto se resuelva en el servidor (5.3) y el pull
      // posterior baje ya el estado autoritativo.
      final resumenPush = await sync.push();
      if (_sesionExpiro()) return DesenlaceSync.sesionExpirada;
      if (resumenPush.sinRed) return DesenlaceSync.sinRed;

      // Los binarios viajan tras aceptarse sus metadatos (RNF-05).
      await adjuntos?.subirPendientes();
      if (_sesionExpiro()) return DesenlaceSync.sesionExpirada;

      final resumenPull = await sync.pull(sesion.usuario.uuid);
      if (_sesionExpiro()) return DesenlaceSync.sesionExpirada;
      if (resumenPull.sinRed) return DesenlaceSync.sinRed;

      // Purga best-effort: un fallo local no debe marcar el ciclo como error.
      if (purga != null) {
        try {
          await purga!.purgar();
        } catch (_) {
          // Se reintenta en el próximo ciclo.
        }
      }

      return DesenlaceSync.ok;
    } on ApiException catch (e) {
      // 401 tras un refresh fallido → reautenticación (el interceptor ya
      // limpió la sesión). Otros códigos → error reintentable.
      return e.status == 401 ? DesenlaceSync.sesionExpirada : DesenlaceSync.error;
    } on SinConexionException {
      return DesenlaceSync.sinRed;
    }
  }
}

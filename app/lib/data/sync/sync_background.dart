import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

import '../auth/almacen_seguro.dart';
import '../auth/almacen_sesion.dart';
import '../db/app_database.dart';
import '../red/api_cliente.dart';
import '../red/attachments_api.dart';
import '../red/auth_api.dart';
import '../red/auth_interceptor.dart';
import '../red/sync_api.dart';
import 'attachment_service.dart';
import 'identidad_dispositivo.dart';
import 'purga_service.dart';
import 'sync_coordinator.dart';
import 'sync_service.dart';

/// Orquestación en segundo plano con workmanager (tarea 3.4).
///
/// El callback corre en un ISOLATE separado sin acceso a los providers de
/// Riverpod: por eso [ejecutarSyncEnIsolate] arma el grafo de dependencias a
/// mano. La BD cifrada se abre con su propia instancia (path_provider y
/// flutter_secure_storage funcionan en el isolate de workmanager, que inicia
/// su propio motor Flutter). Limitación conocida (documentada): si la app en
/// primer plano y esta tarea abrieran la BD a la vez podrían competir; en la
/// práctica la tarea periódica (~15 min) y el sync en foreground rara vez se
/// solapan.

const String tareaSyncPeriodica = 'notium.sync.periodica';
const String tareaSyncUnica = 'notium.sync.unica';

/// Punto de entrada del isolate de workmanager. DEBE ser una función de nivel
/// superior anotada con `vm:entry-point` para que el AOT no la elimine.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((tarea, datos) async {
    final resultado = await ejecutarSyncEnIsolate();
    // Devolver `false` pide a workmanager reintentar con backoff exponencial
    // (CU-07). Sin red o error transitorio → reintentar. ok o sesión expirada
    // → no reintentar (la sesión expirada exige que el usuario reingrese).
    return switch (resultado) {
      DesenlaceSync.sinRed || DesenlaceSync.error => false,
      DesenlaceSync.ok || DesenlaceSync.sesionExpirada => true,
    };
  });
}

/// Arma las dependencias en el isolate y ejecuta un ciclo completo
/// push → subir binarios → pull → purga.
Future<DesenlaceSync> ejecutarSyncEnIsolate() async {
  final db = AppDatabase();
  try {
    const almacenSeguro = AlmacenSeguroDispositivo();
    final almacenSesion = AlmacenSesion(almacenSeguro);
    final identidad = IdentidadDispositivo(almacenSeguro);
    final dioSinAuth = crearDioBase();
    final authApi = AuthApi(dioSinAuth);

    var sesionExpiro = false;
    final dio = crearDioBase()
      ..interceptors.add(AuthInterceptor(
        almacen: almacenSesion,
        authApi: authApi,
        dioSinAuth: dioSinAuth,
        alExpirarSesion: () => sesionExpiro = true,
      ));

    final documentos = await getApplicationDocumentsDirectory();
    final directorioAdjuntos = Directory(p.join(documentos.path, 'adjuntos'));

    final coordinador = SyncCoordinator(
      sync: SyncService(db: db, api: SyncApi(dio), identidad: identidad),
      almacenSesion: almacenSesion,
      adjuntos: AttachmentService(
        db: db,
        api: AttachmentsApi(dio),
        identidad: identidad,
        directorioAdjuntos: directorioAdjuntos,
      ),
      purga: PurgaService(db: db),
      sesionExpiro: () => sesionExpiro,
    );

    return await coordinador.ejecutar();
  } finally {
    await db.close();
  }
}

/// Inicializa workmanager (se llama una vez en `main`).
Future<void> inicializarWorkmanager() =>
    Workmanager().initialize(callbackDispatcher);

/// Registra la tarea periódica con restricción de red y backoff exponencial.
/// `keep` evita duplicarla si ya estaba registrada.
Future<void> registrarSyncPeriodica() => Workmanager().registerPeriodicTask(
      tareaSyncPeriodica,
      tareaSyncPeriodica,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
    );

/// Dispara una sincronización única en segundo plano (p. ej. tras crear/editar
/// cuando no hay red aún: se ejecutará al cumplirse la restricción de red).
Future<void> dispararSyncUnica() => Workmanager().registerOneOffTask(
      tareaSyncUnica,
      tareaSyncUnica,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
    );

/// Cancela todas las tareas (al cerrar sesión).
Future<void> cancelarSync() => Workmanager().cancelAll();

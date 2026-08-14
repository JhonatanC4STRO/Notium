import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'sync_background.dart';
import 'sync_coordinator.dart';

/// Orquestación en primer plano (tarea 3.4): registra la tarea periódica de
/// workmanager y, con `connectivity_plus`, dispara un sync inmediato al
/// recuperar la red. El ciclo en sí lo ejecuta [SyncCoordinator].
class SyncManager {
  SyncManager({required this.coordinator, Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final SyncCoordinator coordinator;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _suscripcion;
  bool _sincronizando = false;

  /// Se llama cuando hay sesión activa (tras login o al arrancar con sesión):
  /// registra la tarea periódica y escucha los cambios de conectividad.
  Future<void> iniciar() async {
    await registrarSyncPeriodica();
    _suscripcion ??= _connectivity.onConnectivityChanged.listen((estados) {
      final hayRed = estados.any((e) => e != ConnectivityResult.none);
      if (hayRed) unawaited(sincronizarAhora());
    });
    // Intento inmediato por si ya hay red al iniciar sesión.
    unawaited(sincronizarAhora());
  }

  /// Ejecuta un ciclo de sincronización ahora, en foreground. Reentrante:
  /// si ya hay uno en curso, no lanza otro en paralelo.
  Future<DesenlaceSync> sincronizarAhora() async {
    if (_sincronizando) return DesenlaceSync.ok;
    _sincronizando = true;
    try {
      return await coordinator.ejecutar();
    } finally {
      _sincronizando = false;
    }
  }

  /// Al cerrar sesión: corta la escucha y cancela las tareas de workmanager.
  /// Se llama tras una escritura local. Intenta sincronizar ahora si hay red y
  /// deja una tarea unica pendiente para que Android la ejecute al recuperar
  /// conexion si el intento inmediato no puede salir.
  void notificarCambioLocal() {
    unawaited(dispararSyncUnica());
    unawaited(sincronizarAhora());
  }

  Future<void> detener() async {
    await _suscripcion?.cancel();
    _suscripcion = null;
    await cancelarSync();
  }
}

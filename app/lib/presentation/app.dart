import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/sesion.dart';
import 'pantallas/pantalla_lista_notas.dart';
import 'pantallas/pantalla_login.dart';
import 'providers.dart';

/// Raíz de la app: decide entre login y notas según la sesión local.
class NotiumApp extends StatelessWidget {
  const NotiumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notium',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const _Raiz(),
    );
  }
}

class _Raiz extends ConsumerWidget {
  const _Raiz();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Arranca/detiene la orquestación en segundo plano según haya sesión
    // (tarea 3.4). Guardado por el flag para no invocar plugins en los tests.
    if (ref.watch(syncEnSegundoPlanoProvider)) {
      ref.listen(sesionProvider, (anterior, actual) {
        final manager = ref.read(syncManagerProvider);
        if (actual.value != null) {
          manager.iniciar();
        } else {
          manager.detener();
        }
      });
    }

    final sesion = ref.watch(sesionProvider);

    return sesion.when(
      // Restaurando la sesión cacheada (CU-02): decisión 100% local.
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Error al restaurar la sesión: $error')),
      ),
      data: (s) => s == null ? const PantallaLogin() : const _NotasConAvisos(),
    );
  }
}

/// Lista de notas con el aviso de sesión degradada (CU-02 sin red: el token
/// expiró dentro de la ventana extendida; el uso offline continúa).
class _NotasConAvisos extends ConsumerWidget {
  const _NotasConAvisos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sesionProvider).value;
    final degradada =
        s != null && s.estadoEn(DateTime.now().toUtc()) == EstadoSesion.degradada;

    if (!degradada) return const PantallaListaNotas();

    return Column(
      children: [
        Material(
          color: Colors.amber.shade100,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.wifi_off, size: 18, color: Colors.amber.shade900),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Sesión por renovar: conéctate a internet pronto.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Expanded(child: PantallaListaNotas()),
      ],
    );
  }
}

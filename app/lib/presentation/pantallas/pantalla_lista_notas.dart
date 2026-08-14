import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../domain/enums.dart';
import '../providers.dart';
import '../widgets/indicador_sync.dart';
import 'pantalla_editor_nota.dart';

/// Lista de notas (tarea 2.4): consume el StreamProvider — cada escritura
/// local re-emite y la lista se actualiza sola (RNF-03: < 100 ms).
class PantallaListaNotas extends ConsumerWidget {
  const PantallaListaNotas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notas = ref.watch(notasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notium'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _confirmarCierreSesion(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          const _AvisoEspacio(),
          Expanded(
            child: notas.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Error al leer la BD local: $error')),
              data: (lista) => lista.isEmpty
                  ? const Center(
                      child: Text(
                        'Sin notas todavía.\nCrea la primera con el botón +',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: lista.length,
                      itemBuilder: (context, i) => _ItemNota(nota: lista[i]),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Crear nota',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const PantallaEditorNota()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmarCierreSesion(BuildContext context, WidgetRef ref) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Tus notas permanecen en este dispositivo. Si estás sin conexión, '
          'la sesión se invalidará en el servidor al reconectar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmado == true) {
      await ref.read(sesionProvider.notifier).cerrarSesion();
    }
  }
}

/// Aviso al acercarse al presupuesto de almacenamiento local (tarea 4.2,
/// RNF-05). Silencioso mientras haya holgura: solo aparece cerca del límite.
class _AvisoEspacio extends ConsumerWidget {
  const _AvisoEspacio();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uso = ref.watch(usoAlmacenamientoProvider).value;
    if (uso == null || !uso.cercaDelLimite) return const SizedBox.shrink();

    return Material(
      color: Colors.orange.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.storage, size: 18, color: Colors.orange.shade900),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Almacenamiento casi lleno (${uso.legible} de ${uso.limiteLegible}). '
                'Elimina notas o adjuntos para liberar espacio.',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemNota extends ConsumerWidget {
  const _ItemNota({required this.nota});

  final Nota nota;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enError = nota.syncStatus == SyncStatus.ERROR;

    return ListTile(
      title: Text(nota.titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (nota.contenido != null && nota.contenido!.isNotEmpty)
            Text(nota.contenido!, maxLines: 2, overflow: TextOverflow.ellipsis),
          // RF-04 / sección 5.2: un rechazo del servidor no se reintenta solo;
          // el usuario debe corregir el dato o eliminar la nota.
          if (enError)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'No se sincronizó: ${nota.syncError ?? 'el servidor rechazó el cambio'}. '
                'Toca para corregir.',
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ),
        ],
      ),
      isThreeLine: enError,
      leading: IndicadorSync(estado: nota.syncStatus),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Eliminar nota',
        onPressed: () => _confirmarEliminacion(context, ref),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PantallaEditorNota(notaExistente: nota),
        ),
      ),
    );
  }

  Future<void> _confirmarEliminacion(BuildContext context, WidgetRef ref) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar nota?'),
        content: Text(
          '"${nota.titulo}" se eliminará de todos tus dispositivos '
          'en la próxima sincronización.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await ref.read(accionesNotasProvider.notifier).eliminar(nota.uuid);
    }
  }
}

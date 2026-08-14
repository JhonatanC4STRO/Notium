import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../data/db/app_database.dart';
import '../../domain/enums.dart';
import '../../domain/errores.dart';
import '../providers.dart';
import '../widgets/indicador_sync.dart';
import 'pantalla_historial.dart';

/// Editor de notas (tarea 2.4): crear cuando `notaExistente` es null,
/// editar en caso contrario. Los adjuntos se gestionan sobre una nota ya
/// guardada (necesitan su uuid como relación, sección 5.1).
class PantallaEditorNota extends ConsumerStatefulWidget {
  const PantallaEditorNota({super.key, this.notaExistente});

  final Nota? notaExistente;

  @override
  ConsumerState<PantallaEditorNota> createState() => _PantallaEditorNotaState();
}

class _PantallaEditorNotaState extends ConsumerState<PantallaEditorNota> {
  late final TextEditingController _titulo;
  late final TextEditingController _contenido;

  Nota? get _nota => widget.notaExistente;

  @override
  void initState() {
    super.initState();
    _titulo = TextEditingController(text: _nota?.titulo ?? '');
    _contenido = TextEditingController(text: _nota?.contenido ?? '');
  }

  @override
  void dispose() {
    _titulo.dispose();
    _contenido.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final titulo = _titulo.text.trim();
    if (titulo.isEmpty) {
      _avisar('El título es obligatorio.');
      return;
    }

    final acciones = ref.read(accionesNotasProvider.notifier);
    if (_nota == null) {
      await acciones.crear(titulo: titulo, contenido: _contenido.text);
    } else {
      await acciones.editar(
        uuid: _nota!.uuid,
        titulo: titulo,
        contenido: _contenido.text,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _adjuntarArchivo() async {
    final seleccion = await FilePicker.platform.pickFiles();
    final ruta = seleccion?.files.single.path;
    if (ruta == null) return; // cancelado

    try {
      await ref
          .read(accionesNotasProvider.notifier)
          .agregarAdjunto(notaUuid: _nota!.uuid, archivo: File(ruta));
    } on AdjuntoExcedeLimite {
      // CU-08: rechazo definitivo, sin reintento automático.
      _avisar('El archivo supera el límite de 10 MB por adjunto.');
    } on NotaNoEncontrada {
      _avisar('La nota ya no existe.');
    }
  }

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_nota == null ? 'Nueva nota' : 'Editar nota'),
        actions: [
          if (_nota != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(child: IndicadorSync(estado: _nota!.syncStatus)),
            ),
          if (_nota != null)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Ver historial',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PantallaHistorial(
                    notaUuid: _nota!.uuid,
                    titulo: _titulo.text.trim().isEmpty ? _nota!.titulo : _titulo.text.trim(),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Guardar',
            onPressed: _guardar,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Rechazo del servidor (RF-04, sección 5.2): se explica el motivo y
          // se indica la salida — corregir y guardar vuelve a dejarla PENDING.
          if (_nota != null && _nota!.syncStatus == SyncStatus.ERROR)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'El servidor rechazó este cambio',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _nota!.syncError ?? 'No se indicó un motivo.',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Corrige el contenido y guarda para reintentar.',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          TextField(
            controller: _titulo,
            decoration: const InputDecoration(
              labelText: 'Título',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contenido,
            decoration: const InputDecoration(
              labelText: 'Contenido',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            minLines: 8,
            maxLines: null,
          ),
          if (_nota != null) ...[
            const SizedBox(height: 24),
            _SeccionAdjuntos(
              notaUuid: _nota!.uuid,
              onAdjuntar: _adjuntarArchivo,
            ),
          ] else ...[
            const SizedBox(height: 24),
            const Text(
              'Guarda la nota para poder adjuntar archivos.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}

class _SeccionAdjuntos extends ConsumerWidget {
  const _SeccionAdjuntos({required this.notaUuid, required this.onAdjuntar});

  final String notaUuid;
  final VoidCallback onAdjuntar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adjuntos = ref.watch(adjuntosDeNotaProvider(notaUuid));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Adjuntos', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: onAdjuntar,
              icon: const Icon(Icons.attach_file),
              label: const Text('Adjuntar'),
            ),
          ],
        ),
        adjuntos.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text('Error: $error'),
          data: (lista) => lista.isEmpty
              ? const Text('Sin adjuntos.', style: TextStyle(color: Colors.grey))
              : Column(
                  children: [
                    for (final adjunto in lista)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.insert_drive_file_outlined),
                        title: Text(
                          p.basename(adjunto.rutaLocal ?? adjunto.uuid),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Row(
                          children: [
                            IndicadorSync(estado: adjunto.syncStatus, tamano: 14),
                            const SizedBox(width: 6),
                            const Text('Solo en este dispositivo'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Quitar adjunto',
                          onPressed: () => ref
                              .read(accionesNotasProvider.notifier)
                              .eliminarAdjunto(adjunto.uuid),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

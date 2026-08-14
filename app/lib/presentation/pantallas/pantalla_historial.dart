import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/red/auth_api.dart';
import '../../data/red/history_api.dart';
import '../../domain/enums.dart';
import '../providers.dart';

/// Historial de auditoría de una nota (tarea 4.1, RF-05). Muestra el
/// historial LOCAL (offline-first, reactivo) resaltando los cambios
/// descartados por conflicto, y permite cargar bajo demanda la vista del
/// servidor (otros dispositivos).
class PantallaHistorial extends ConsumerStatefulWidget {
  const PantallaHistorial({super.key, required this.notaUuid, required this.titulo});

  final String notaUuid;
  final String titulo;

  @override
  ConsumerState<PantallaHistorial> createState() => _PantallaHistorialState();
}

class _PantallaHistorialState extends ConsumerState<PantallaHistorial> {
  bool _mostrarServidor = false;

  @override
  Widget build(BuildContext context) {
    final local = ref.watch(historialDeNotaProvider(widget.notaUuid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.titulo,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
      body: local.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error al leer el historial: $e')),
        data: (entradas) => ListView(
          children: [
            if (entradas.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Sin cambios registrados todavía.'),
              )
            else
              for (final e in entradas) _EntradaLocal(entrada: e),
            const Divider(height: 32),
            _SeccionServidor(
              notaUuid: widget.notaUuid,
              mostrar: _mostrarServidor,
              onCargar: () => setState(() => _mostrarServidor = true),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estilo por origen del cambio. `CONFLICTO_DESCARTADO` se resalta: es el dato
/// que RF-05 conserva para que el usuario revise qué se descartó.
({IconData icono, Color color, String etiqueta}) _estilo(
  BuildContext context,
  OrigenCambio origen,
) {
  return switch (origen) {
    OrigenCambio.LOCAL => (
        icono: Icons.edit_outlined,
        color: Theme.of(context).colorScheme.primary,
        etiqueta: 'Cambio en este dispositivo',
      ),
    OrigenCambio.REMOTO => (
        icono: Icons.cloud_download_outlined,
        color: Colors.blueGrey,
        etiqueta: 'Cambio de otro dispositivo',
      ),
    OrigenCambio.CONFLICTO_DESCARTADO => (
        icono: Icons.report_problem_outlined,
        color: Colors.deepOrange.shade700,
        etiqueta: 'Cambio descartado por conflicto',
      ),
  };
}

String _formatoFecha(DateTime fecha) {
  final f = fecha.toLocal();
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${f.year}-${dos(f.month)}-${dos(f.day)} ${dos(f.hour)}:${dos(f.minute)}';
}

/// Resumen legible de un valor serializado (JSON) del historial.
String? _resumenValor(String? json) {
  if (json == null) return null;
  try {
    final mapa = jsonDecode(json);
    if (mapa is Map && mapa['titulo'] is String) return mapa['titulo'] as String;
    return json;
  } catch (_) {
    return json;
  }
}

class _EntradaLocal extends StatelessWidget {
  const _EntradaLocal({required this.entrada});

  final HistorialCambio entrada;

  @override
  Widget build(BuildContext context) {
    final estilo = _estilo(context, entrada.origenCambio);
    final esDescartado = entrada.origenCambio == OrigenCambio.CONFLICTO_DESCARTADO;
    final descartado = _resumenValor(entrada.valorAnterior);

    return ListTile(
      leading: Icon(estilo.icono, color: estilo.color),
      title: Text('${entrada.tipoCambio} · ${estilo.etiqueta}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_formatoFecha(entrada.fecha)),
          if (entrada.dispositivoOrigen != null)
            Text('Dispositivo: ${entrada.dispositivoOrigen}'),
          if (esDescartado && descartado != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Se descartó: "$descartado"',
                style: TextStyle(
                  color: estilo.color,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
      isThreeLine: esDescartado,
    );
  }
}

/// Sección plegable con el historial del servidor (otros dispositivos). Se
/// carga solo al pulsar, para no forzar red al abrir la pantalla.
class _SeccionServidor extends ConsumerWidget {
  const _SeccionServidor({
    required this.notaUuid,
    required this.mostrar,
    required this.onCargar,
  });

  final String notaUuid;
  final bool mostrar;
  final VoidCallback onCargar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!mostrar) {
      return Center(
        child: TextButton.icon(
          onPressed: onCargar,
          icon: const Icon(Icons.cloud_sync_outlined),
          label: const Text('Ver historial del servidor'),
        ),
      );
    }

    final remoto = ref.watch(historialServidorProvider(notaUuid));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Según el servidor (todos los dispositivos)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        remoto.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              e is SinConexionException
                  ? 'Sin conexión: no se pudo traer el historial del servidor.'
                  : 'No se pudo cargar el historial del servidor.',
            ),
          ),
          data: (entradas) => entradas.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('El servidor no tiene entradas para esta nota.'),
                )
              : Column(children: [for (final e in entradas) _EntradaRemota(entrada: e)]),
        ),
      ],
    );
  }
}

class _EntradaRemota extends StatelessWidget {
  const _EntradaRemota({required this.entrada});

  final HistorialRemoto entrada;

  @override
  Widget build(BuildContext context) {
    final origen = OrigenCambio.values.firstWhere(
      (o) => o.name == entrada.origenCambio,
      orElse: () => OrigenCambio.REMOTO,
    );
    final estilo = _estilo(context, origen);
    final descartado = _resumenValor(entrada.valorNuevo);

    return ListTile(
      dense: true,
      leading: Icon(estilo.icono, color: estilo.color, size: 20),
      title: Text('${entrada.tipoCambio} · ${estilo.etiqueta}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entrada.fecha),
          if (entrada.dispositivoOrigen != null)
            Text('Dispositivo: ${entrada.dispositivoOrigen}'),
          if (origen == OrigenCambio.CONFLICTO_DESCARTADO && descartado != null)
            Text('Se descartó: "$descartado"',
                style: TextStyle(color: estilo.color, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

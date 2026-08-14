import 'package:flutter/material.dart';

import '../../domain/enums.dart';

/// Indicador de estado de sincronización por registro (RF-04). Es un
/// REQUISITO del sistema, no un adorno: el usuario debe poder distinguir
/// qué registros ya están seguros en el servidor y cuáles no.
///
/// En la fase 2 todo registro estará en PENDING (no hay red); los demás
/// estados se activan con la sincronización de la fase 3.
class IndicadorSync extends StatelessWidget {
  const IndicadorSync({super.key, required this.estado, this.tamano = 18});

  final SyncStatus estado;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final (icono, color, descripcion) = switch (estado) {
      SyncStatus.PENDING => (
          Icons.schedule,
          Colors.amber.shade800,
          'Pendiente de sincronizar',
        ),
      SyncStatus.SYNCED => (
          Icons.cloud_done_outlined,
          Colors.green.shade700,
          'Sincronizada con el servidor',
        ),
      SyncStatus.CONFLICT => (
          Icons.sync_problem,
          Colors.deepOrange.shade700,
          'Hubo un conflicto: prevaleció la copia del servidor (ver historial)',
        ),
      SyncStatus.ERROR => (
          Icons.error_outline,
          Colors.red.shade700,
          'Rechazada por el servidor: corrige el contenido para reintentar',
        ),
    };

    return Tooltip(
      message: descripcion,
      child: Icon(icono, color: color, size: tamano, semanticLabel: descripcion),
    );
  }
}

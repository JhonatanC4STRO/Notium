import 'dart:io';

/// Uso de almacenamiento local en un momento dado.
class UsoAlmacenamiento {
  const UsoAlmacenamiento({
    required this.bytes,
    required this.limiteBytes,
  });

  final int bytes;
  final int limiteBytes;

  double get fraccion => limiteBytes == 0 ? 0 : bytes / limiteBytes;

  /// Verdadero al acercarse al límite (RNF-05): momento de avisar al usuario
  /// para que elimine notas o adjuntos antes de topar.
  bool get cercaDelLimite => fraccion >= EspacioService.umbralAviso;

  String get legible => _formatear(bytes);
  String get limiteLegible => _formatear(limiteBytes);

  static String _formatear(int bytes) {
    const mb = 1024 * 1024;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
}

/// Medición del almacenamiento local (tarea 4.2, RNF-05): el tamaño de la BD
/// cifrada más el de las copias de adjuntos. Las rutas se inyectan para poder
/// probarlo con archivos temporales, sin `path_provider`.
class EspacioService {
  EspacioService({
    required this.archivoBaseDatos,
    required this.directorioAdjuntos,
    this.limiteBytes = limitePorDefecto,
  });

  /// Presupuesto de almacenamiento local del doc (RNF-05).
  static const int limitePorDefecto = 500 * 1024 * 1024; // 500 MB

  /// Fracción del límite a partir de la cual se avisa.
  static const double umbralAviso = 0.9;

  final File archivoBaseDatos;
  final Directory directorioAdjuntos;
  final int limiteBytes;

  Future<UsoAlmacenamiento> medir() async {
    var total = 0;

    if (await archivoBaseDatos.exists()) {
      total += await archivoBaseDatos.length();
    }
    if (await directorioAdjuntos.exists()) {
      await for (final entrada
          in directorioAdjuntos.list(recursive: true, followLinks: false)) {
        if (entrada is File) total += await entrada.length();
      }
    }

    return UsoAlmacenamiento(bytes: total, limiteBytes: limiteBytes);
  }
}

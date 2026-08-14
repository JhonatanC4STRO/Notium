/// Errores de dominio del CRUD local (fase 2).
library;

/// Límite por adjunto (RNF-05). La validación ocurre ANTES de copiar o
/// persistir nada (CU-08).
const int limiteAdjuntoBytes = 10 * 1024 * 1024; // 10 MB

class NotaNoEncontrada implements Exception {
  NotaNoEncontrada(this.uuid);
  final String uuid;

  @override
  String toString() => 'NotaNoEncontrada: no existe una nota activa con uuid $uuid';
}

class AdjuntoNoEncontrado implements Exception {
  AdjuntoNoEncontrado(this.uuid);
  final String uuid;

  @override
  String toString() => 'AdjuntoNoEncontrado: no existe un adjunto activo con uuid $uuid';
}

class AdjuntoExcedeLimite implements Exception {
  AdjuntoExcedeLimite(this.tamanoBytes);
  final int tamanoBytes;

  @override
  String toString() =>
      'AdjuntoExcedeLimite: $tamanoBytes bytes supera el máximo de $limiteAdjuntoBytes (10 MB, RNF-05)';
}

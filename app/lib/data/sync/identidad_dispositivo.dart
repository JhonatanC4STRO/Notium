import 'package:uuid/uuid.dart';

import '../auth/almacen_seguro.dart';

/// `device_id` estable del dispositivo (tarea 3.2): se genera una sola vez y
/// se persiste. Va a nivel de lote en `/sync/push` (todas las operaciones de
/// un envío provienen del mismo dispositivo) y permite el filtro anti-eco de
/// `/sync/pull` (excluir los cambios que originó este mismo dispositivo).
///
/// No es un secreto, pero se guarda en el almacenamiento seguro por reusar
/// la misma abstracción testeable del resto de la capa de datos.
class IdentidadDispositivo {
  IdentidadDispositivo(this._almacen);

  final AlmacenSeguro _almacen;
  static const _clave = 'notium_device_id';
  static const _uuid = Uuid();

  Future<String> obtener() async {
    final existente = await _almacen.leer(_clave);
    if (existente != null) return existente;

    final nuevo = 'disp-${_uuid.v4()}';
    await _almacen.escribir(_clave, nuevo);
    return nuevo;
  }
}

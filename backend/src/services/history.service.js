const pool = require('../db/pool');
const AppError = require('../utils/app-error');

/**
 * GET /history/{nota_uuid} (RF-05): historial de auditoría de una nota,
 * incluidas las entradas CONFLICTO_DESCARTADO generadas al resolver
 * conflictos por LWW (sección 5.3), ordenado por fecha descendente.
 */
async function obtenerHistorial({ usuarioUuid, notaUuid }) {
  const { rows: notas } = await pool.query('SELECT usuario_uuid FROM nota WHERE uuid = $1', [
    notaUuid,
  ]);
  if (notas.length === 0 || notas[0].usuario_uuid !== usuarioUuid) {
    throw new AppError(404, 'NOTA_NO_ENCONTRADA', 'La nota no existe o no pertenece al usuario autenticado.');
  }

  const { rows } = await pool.query(
    `SELECT uuid, nota_uuid, tipo_cambio, origen_cambio, fecha,
            dispositivo_origen, valor_anterior, valor_nuevo
     FROM historial_cambio
     WHERE nota_uuid = $1
     ORDER BY fecha DESC`,
    [notaUuid]
  );

  return {
    historial: rows.map((fila) => ({
      uuid: fila.uuid,
      nota_uuid: fila.nota_uuid,
      tipo_cambio: fila.tipo_cambio,
      origen_cambio: fila.origen_cambio,
      fecha: fila.fecha.toISOString(),
      dispositivo_origen: fila.dispositivo_origen,
      valor_anterior: fila.valor_anterior,
      valor_nuevo: fila.valor_nuevo,
    })),
  };
}

module.exports = { obtenerHistorial };

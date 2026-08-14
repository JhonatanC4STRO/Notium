const syncService = require('../services/sync.service');
const AppError = require('../utils/app-error');

/**
 * POST /sync/push — validación a nivel de lote (SyncPushRequest). La
 * validación por operación la hace el service, que rechaza items
 * individuales con estado ERROR sin abortar el lote.
 */
async function enviarLote(req, res, next) {
  try {
    const { device_id: deviceId, operaciones } = req.body || {};

    if (typeof deviceId !== 'string' || deviceId.trim().length === 0) {
      throw new AppError(400, 'VALIDACION', 'La solicitud contiene datos inválidos.', 'device_id es obligatorio.');
    }
    if (!Array.isArray(operaciones) || operaciones.length === 0) {
      throw new AppError(400, 'VALIDACION', 'La solicitud contiene datos inválidos.', 'operaciones debe ser un array con al menos un elemento.');
    }

    const { httpStatus, resultados } = await syncService.procesarLote({
      usuarioUuid: req.usuario.uuid,
      deviceId,
      operaciones,
    });
    res.status(httpStatus).json({ resultados });
  } catch (err) {
    next(err);
  }
}

/**
 * GET /sync/pull — validación de query params (desde obligatorio,
 * limite 1..500 con default 100, device_id opcional para anti-eco).
 */
async function obtenerCambios(req, res, next) {
  try {
    const { desde, device_id: deviceId, limite } = req.query;

    if (typeof desde !== 'string' || Number.isNaN(Date.parse(desde))) {
      throw new AppError(400, 'VALIDACION', 'La solicitud contiene datos inválidos.', 'desde es obligatorio y debe ser una fecha ISO 8601.');
    }

    let limiteNum = 100; // default de openapi.yaml
    if (limite !== undefined) {
      limiteNum = Number(limite);
      if (!Number.isInteger(limiteNum) || limiteNum < 1 || limiteNum > 500) {
        throw new AppError(400, 'VALIDACION', 'La solicitud contiene datos inválidos.', 'limite debe ser un entero entre 1 y 500.');
      }
    }

    const respuesta = await syncService.obtenerCambios({
      usuarioUuid: req.usuario.uuid,
      desde,
      deviceId: typeof deviceId === 'string' && deviceId.length > 0 ? deviceId : null,
      limite: limiteNum,
    });
    res.status(200).json(respuesta);
  } catch (err) {
    next(err);
  }
}

module.exports = { enviarLote, obtenerCambios };

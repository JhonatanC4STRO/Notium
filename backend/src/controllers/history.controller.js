const historyService = require('../services/history.service');
const AppError = require('../utils/app-error');

const UUID_V4 = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

async function obtenerHistorial(req, res, next) {
  try {
    const notaUuid = req.params.nota_uuid;
    if (!UUID_V4.test(notaUuid)) {
      throw new AppError(400, 'VALIDACION', 'La solicitud contiene datos inválidos.', 'nota_uuid debe ser un UUID v4.');
    }
    const historial = await historyService.obtenerHistorial({
      usuarioUuid: req.usuario.uuid,
      notaUuid,
    });
    res.status(200).json(historial);
  } catch (err) {
    next(err);
  }
}

module.exports = { obtenerHistorial };

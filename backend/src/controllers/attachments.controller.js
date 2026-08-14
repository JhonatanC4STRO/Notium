const attachmentsService = require('../services/attachments.service');
const AppError = require('../utils/app-error');

const UUID_V4 = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function validar(condicion, detalle) {
  if (!condicion) {
    throw new AppError(400, 'VALIDACION', 'La solicitud contiene datos inválidos.', detalle);
  }
}

async function subir(req, res, next) {
  try {
    const { uuid, nota_uuid: notaUuid, device_id: deviceId } = req.body || {};
    validar(typeof uuid === 'string' && UUID_V4.test(uuid), 'uuid debe ser un UUID v4.');
    validar(typeof notaUuid === 'string' && UUID_V4.test(notaUuid), 'nota_uuid debe ser un UUID v4.');
    validar(req.file && req.file.buffer && req.file.buffer.length > 0, 'archivo es obligatorio.');

    const adjunto = await attachmentsService.subirAdjunto({
      usuarioUuid: req.usuario.uuid,
      uuid,
      notaUuid,
      deviceId: typeof deviceId === 'string' && deviceId.length > 0 ? deviceId : null,
      archivo: req.file,
    });
    res.status(201).json(adjunto);
  } catch (err) {
    next(err);
  }
}

async function descargar(req, res, next) {
  try {
    const { ruta } = await attachmentsService.obtenerBinario({
      usuarioUuid: req.usuario.uuid,
      uuid: req.params.uuid,
    });
    res.setHeader('content-type', 'application/octet-stream');
    res.sendFile(ruta);
  } catch (err) {
    next(err);
  }
}

async function eliminar(req, res, next) {
  try {
    await attachmentsService.eliminarAdjunto({
      usuarioUuid: req.usuario.uuid,
      uuid: req.params.uuid,
    });
    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

module.exports = { subir, descargar, eliminar };

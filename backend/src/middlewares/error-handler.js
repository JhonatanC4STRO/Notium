const AppError = require('../utils/app-error');

/**
 * Manejadores de error con el esquema `Error` de openapi.yaml:
 * { codigo, mensaje, detalle }.
 */

function noEncontrado(req, res) {
  res.status(404).json({
    codigo: 'RUTA_NO_ENCONTRADA',
    mensaje: 'La ruta solicitada no existe.',
    detalle: `${req.method} ${req.originalUrl}`,
  });
}

// eslint-disable-next-line no-unused-vars
function manejadorErrores(err, req, res, next) {
  if (err instanceof AppError) {
    return res.status(err.httpStatus).json({
      codigo: err.codigo,
      mensaje: err.message,
      detalle: err.detalle,
    });
  }

  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({
      codigo: 'JSON_INVALIDO',
      mensaje: 'El cuerpo de la solicitud no es JSON válido.',
      detalle: null,
    });
  }

  console.error(err);
  res.status(500).json({
    codigo: 'ERROR_INTERNO',
    mensaje: 'Error interno del servidor.',
    detalle: null,
  });
}

module.exports = { noEncontrado, manejadorErrores };

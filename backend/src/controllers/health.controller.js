const healthService = require('../services/health.service');

async function verificarSalud(req, res, next) {
  try {
    const { httpStatus, body } = await healthService.verificarSalud();
    res.status(httpStatus).json(body);
  } catch (err) {
    next(err);
  }
}

module.exports = { verificarSalud };

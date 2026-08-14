const tokenService = require('../services/token.service');
const AppError = require('../utils/app-error');

function extraerBearer(req) {
  const cabecera = req.headers.authorization || '';
  const [esquema, token] = cabecera.split(' ');
  if (esquema !== 'Bearer' || !token) {
    throw new AppError(401, 'TOKEN_AUSENTE', 'Falta la cabecera Authorization: Bearer <token>.');
  }
  return token;
}

/**
 * Exige un access token vigente y deja el usuario autenticado en
 * `req.usuario`. Se aplica a todas las rutas protegidas (tarea 1.2).
 */
function requerirAutenticacion(req, res, next) {
  try {
    const payload = tokenService.verificarAccessToken(extraerBearer(req));
    req.usuario = { uuid: payload.sub };
    next();
  } catch (err) {
    next(err);
  }
}

module.exports = { extraerBearer, requerirAutenticacion };

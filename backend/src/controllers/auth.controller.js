const authService = require('../services/auth.service');
const { extraerBearer } = require('../middlewares/auth');
const AppError = require('../utils/app-error');

const UUID_V4 = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function validar(condicion, detalle) {
  if (!condicion) {
    throw new AppError(400, 'VALIDACION', 'La solicitud contiene datos inválidos.', detalle);
  }
}

async function registrar(req, res, next) {
  try {
    const { uuid, nombre, email, contrasena } = req.body || {};
    validar(typeof uuid === 'string' && UUID_V4.test(uuid), 'uuid debe ser un UUID v4.');
    validar(typeof nombre === 'string' && nombre.trim().length > 0, 'nombre es obligatorio.');
    validar(typeof email === 'string' && EMAIL.test(email), 'email no tiene formato válido.');
    validar(
      typeof contrasena === 'string' && contrasena.length >= 8,
      'contrasena debe tener al menos 8 caracteres.'
    );

    const sesion = await authService.registrar({
      uuid,
      nombre: nombre.trim(),
      email: email.toLowerCase(),
      contrasena,
    });
    res.status(201).json(sesion);
  } catch (err) {
    next(err);
  }
}

async function iniciarSesion(req, res, next) {
  try {
    const { email, contrasena } = req.body || {};
    validar(typeof email === 'string' && EMAIL.test(email), 'email no tiene formato válido.');
    validar(typeof contrasena === 'string' && contrasena.length > 0, 'contrasena es obligatoria.');

    const sesion = await authService.iniciarSesion({ email: email.toLowerCase(), contrasena });
    res.status(200).json(sesion);
  } catch (err) {
    next(err);
  }
}

async function refrescar(req, res, next) {
  try {
    const { refresh_token: refreshToken } = req.body || {};
    validar(typeof refreshToken === 'string' && refreshToken.length > 0, 'refresh_token es obligatorio.');

    // El access token viene en la cabecera y puede estar expirado; la
    // validación de solo-firma la hace el service (contrato de openapi.yaml).
    const tokens = await authService.refrescar({
      accessToken: extraerBearer(req),
      refreshToken,
    });
    res.status(200).json(tokens);
  } catch (err) {
    next(err);
  }
}

async function cerrarSesion(req, res, next) {
  try {
    const { refresh_token: refreshToken } = req.body || {};
    validar(typeof refreshToken === 'string' && refreshToken.length > 0, 'refresh_token es obligatorio.');

    await authService.cerrarSesion({ usuarioUuid: req.usuario.uuid, refreshToken });
    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

module.exports = { registrar, iniciarSesion, refrescar, cerrarSesion };

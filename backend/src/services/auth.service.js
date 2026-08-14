const bcrypt = require('bcryptjs');
const pool = require('../db/pool');
const env = require('../config/env');
const tokenService = require('./token.service');
const AppError = require('../utils/app-error');

/**
 * Registro, login y ciclo de vida de los tokens (sección 8, CU-01 a CU-03).
 */

async function persistirRefreshToken(cliente, usuarioUuid, refreshToken) {
  await cliente.query(
    `INSERT INTO refresh_token (token_hash, usuario_uuid, expira_en)
     VALUES ($1, $2, now() + make_interval(secs => $3))`,
    [tokenService.hashDeToken(refreshToken), usuarioUuid, env.refreshTokenTtlSegundos]
  );
}

async function emitirSesion(usuarioUuid) {
  const tokens = tokenService.emitirPar(usuarioUuid);
  await persistirRefreshToken(pool, usuarioUuid, tokens.refresh_token);
  return tokens;
}

/**
 * POST /auth/register — acepta el uuid generado por el cliente (sección 5.1),
 * valida unicidad del email (409) y almacena la contraseña con bcrypt.
 */
async function registrar({ uuid, nombre, email, contrasena }) {
  const contrasenaHash = await bcrypt.hash(contrasena, env.bcryptRounds);

  try {
    await pool.query(
      `INSERT INTO usuario (uuid, nombre, email, contrasena_hash)
       VALUES ($1, $2, $3, $4)`,
      [uuid, nombre, email, contrasenaHash]
    );
  } catch (err) {
    if (err.code === '23505' && err.constraint === 'usuario_email_key') {
      throw new AppError(409, 'EMAIL_DUPLICADO', 'El email ya está registrado.');
    }
    if (err.code === '23505' && err.constraint === 'usuario_pkey') {
      throw new AppError(409, 'UUID_DUPLICADO', 'Ya existe un usuario con ese uuid.');
    }
    throw err;
  }

  const tokens = await emitirSesion(uuid);
  return { usuario: { uuid, nombre, email }, tokens }; // SesionResponse
}

/**
 * POST /auth/login — mismo error para email inexistente y contraseña
 * incorrecta, para no revelar qué cuentas existen.
 */
async function iniciarSesion({ email, contrasena }) {
  const credencialesInvalidas = new AppError(
    401,
    'CREDENCIALES_INVALIDAS',
    'Email o contraseña incorrectos.'
  );

  const { rows } = await pool.query(
    'SELECT uuid, nombre, email, contrasena_hash FROM usuario WHERE email = $1',
    [email]
  );
  if (rows.length === 0) throw credencialesInvalidas;

  const usuario = rows[0];
  const coincide = await bcrypt.compare(contrasena, usuario.contrasena_hash);
  if (!coincide) throw credencialesInvalidas;

  const tokens = await emitirSesion(usuario.uuid);
  return {
    usuario: { uuid: usuario.uuid, nombre: usuario.nombre, email: usuario.email },
    tokens,
  };
}

/**
 * POST /auth/refresh — el access token de la cabecera puede estar expirado
 * (se valida solo la firma, contrato de openapi.yaml). El refresh token debe
 * ser válido, estar vigente en la BD y no revocado. Se rota: el token usado
 * queda revocado y se emite un par nuevo.
 */
async function refrescar({ accessToken, refreshToken }) {
  const accessPayload = tokenService.verificarAccessToken(accessToken, {
    ignorarExpiracion: true,
  });
  const refreshPayload = tokenService.verificarRefreshToken(refreshToken);

  if (accessPayload.sub !== refreshPayload.sub) {
    throw new AppError(401, 'REFRESH_INVALIDO', 'Los tokens no pertenecen al mismo usuario.');
  }

  const cliente = await pool.connect();
  try {
    await cliente.query('BEGIN');

    // Revocación atómica: si otra petición concurrente ya rotó este token,
    // el UPDATE no afecta filas y el refresh se rechaza (un solo uso).
    const { rowCount } = await cliente.query(
      `UPDATE refresh_token
       SET revocado_en = now()
       WHERE token_hash = $1 AND usuario_uuid = $2
         AND revocado_en IS NULL AND expira_en > now()`,
      [tokenService.hashDeToken(refreshToken), refreshPayload.sub]
    );
    if (rowCount === 0) {
      throw new AppError(401, 'REFRESH_INVALIDO', 'El refresh token ya no es válido.');
    }

    const tokens = tokenService.emitirPar(refreshPayload.sub);
    await persistirRefreshToken(cliente, refreshPayload.sub, tokens.refresh_token);

    await cliente.query('COMMIT');
    return tokens; // TokensResponse
  } catch (err) {
    await cliente.query('ROLLBACK');
    throw err;
  } finally {
    cliente.release();
  }
}

/**
 * POST /auth/logout — invalida el refresh token del dispositivo (mitigación
 * de robo, sección 9). Idempotente: cerrar una sesión ya cerrada responde 204.
 */
async function cerrarSesion({ usuarioUuid, refreshToken }) {
  await pool.query(
    `UPDATE refresh_token
     SET revocado_en = now()
     WHERE token_hash = $1 AND usuario_uuid = $2 AND revocado_en IS NULL`,
    [tokenService.hashDeToken(refreshToken), usuarioUuid]
  );
}

module.exports = { registrar, iniciarSesion, refrescar, cerrarSesion };

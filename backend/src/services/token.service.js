const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const env = require('../config/env');
const AppError = require('../utils/app-error');

/**
 * Emisión y verificación de tokens JWT (sección 8 del doc de arquitectura).
 * El claim `tipo` distingue access de refresh para que un token no pueda
 * usarse en el rol del otro aunque compartieran secreto.
 */

function emitirPar(usuarioUuid) {
  // jti único por token: sin él, dos emisiones para el mismo usuario dentro
  // del mismo segundo (mismos sub/iat/exp) producen JWT byte a byte idénticos
  // y el hash del refresh chocaría con la PK de la tabla refresh_token.
  const accessToken = jwt.sign({ sub: usuarioUuid, tipo: 'access' }, env.jwtSecret, {
    expiresIn: env.accessTokenTtlSegundos,
    jwtid: crypto.randomUUID(),
  });
  const refreshToken = jwt.sign({ sub: usuarioUuid, tipo: 'refresh' }, env.jwtRefreshSecret, {
    expiresIn: env.refreshTokenTtlSegundos,
    jwtid: crypto.randomUUID(),
  });

  // Esquema TokensResponse de openapi.yaml.
  return {
    access_token: accessToken,
    refresh_token: refreshToken,
    token_type: 'Bearer',
    expires_in: env.accessTokenTtlSegundos,
  };
}

/**
 * Verifica un access token. Con `ignorarExpiracion` valida solo la firma:
 * es el modo que usa POST /auth/refresh, que por contrato acepta un access
 * token vencido en la cabecera Authorization (openapi.yaml).
 */
function verificarAccessToken(token, { ignorarExpiracion = false } = {}) {
  try {
    const payload = jwt.verify(token, env.jwtSecret, { ignoreExpiration: ignorarExpiracion });
    if (payload.tipo !== 'access') {
      throw new AppError(401, 'TOKEN_INVALIDO', 'El token no es un access token.');
    }
    return payload;
  } catch (err) {
    if (err instanceof AppError) throw err;
    if (err.name === 'TokenExpiredError') {
      throw new AppError(401, 'TOKEN_EXPIRADO', 'El access token expiró.');
    }
    throw new AppError(401, 'TOKEN_INVALIDO', 'El access token es inválido.');
  }
}

function verificarRefreshToken(token) {
  try {
    const payload = jwt.verify(token, env.jwtRefreshSecret);
    if (payload.tipo !== 'refresh') {
      throw new AppError(401, 'REFRESH_INVALIDO', 'El token no es un refresh token.');
    }
    return payload;
  } catch (err) {
    if (err instanceof AppError) throw err;
    throw new AppError(401, 'REFRESH_INVALIDO', 'El refresh token es inválido o expiró.');
  }
}

/**
 * Hash SHA-256 del refresh token para persistirlo sin exponerlo (tarea 1.2:
 * "persistir refresh tokens o su hash").
 */
function hashDeToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

module.exports = { emitirPar, verificarAccessToken, verificarRefreshToken, hashDeToken };

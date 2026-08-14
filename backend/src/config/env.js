const path = require('path');
require('dotenv').config();

const REQUERIDAS = ['DATABASE_URL', 'JWT_SECRET', 'JWT_REFRESH_SECRET'];

const faltantes = REQUERIDAS.filter((nombre) => !process.env[nombre]);
if (faltantes.length > 0) {
  throw new Error(
    `Faltan variables de entorno requeridas: ${faltantes.join(', ')}. ` +
      'Copie .env.example a .env y complete los valores.'
  );
}

module.exports = {
  databaseUrl: process.env.DATABASE_URL,
  jwtSecret: process.env.JWT_SECRET,
  jwtRefreshSecret: process.env.JWT_REFRESH_SECRET,
  port: Number(process.env.PORT) || 3000,
  // Vigencias de los tokens JWT (sección 8): access corto, refresh largo.
  // expires_in de TokensResponse se deriva del TTL del access token.
  accessTokenTtlSegundos: Number(process.env.JWT_ACCESS_TTL_SEGUNDOS) || 900, // 15 min
  refreshTokenTtlSegundos: Number(process.env.JWT_REFRESH_TTL_SEGUNDOS) || 2592000, // 30 días
  bcryptRounds: 10,
  // Almacenamiento de binarios de adjuntos (RNF-05): disco local en
  // desarrollo; en el PaaS puede apuntarse a un volumen persistente.
  uploadsDir: process.env.UPLOADS_DIR || path.resolve(__dirname, '../../uploads'),
  maxAdjuntoBytes: 10 * 1024 * 1024, // 10 MB por adjunto (RNF-05)
};

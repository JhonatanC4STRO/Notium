const pool = require('../db/pool');

/**
 * Verifica el estado del servicio y de la conexión a PostgreSQL.
 * Devuelve el esquema `Health` de openapi.yaml.
 */
async function verificarSalud() {
  const marcaTiempo = new Date().toISOString();

  try {
    await pool.query('SELECT 1');
    return {
      httpStatus: 200,
      body: { estado: 'ok', marca_tiempo: marcaTiempo, base_datos: 'ok' },
    };
  } catch (err) {
    return {
      httpStatus: 503,
      body: { estado: 'caido', marca_tiempo: marcaTiempo, base_datos: 'caido' },
    };
  }
}

module.exports = { verificarSalud };

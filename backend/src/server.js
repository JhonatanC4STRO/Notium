const env = require('./config/env');
const app = require('./app');
const pool = require('./db/pool');

const server = app.listen(env.port, () => {
  console.log(`API de Notium escuchando en http://localhost:${env.port}/v1`);
});

function cerrar(senal) {
  console.log(`Recibida ${senal}, cerrando servidor...`);
  server.close(() => {
    pool.end().then(() => process.exit(0));
  });
}

process.on('SIGINT', () => cerrar('SIGINT'));
process.on('SIGTERM', () => cerrar('SIGTERM'));

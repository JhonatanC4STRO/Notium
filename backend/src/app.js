const express = require('express');
const routes = require('./routes');
const { noEncontrado, manejadorErrores } = require('./middlewares/error-handler');

const app = express();

// 1 MB da holgura para lotes grandes de /sync/push; los binarios de adjuntos
// no pasan por aquí (van por multipart en /attachments, RNF-05).
app.use(express.json({ limit: '1mb' }));

// Prefijo /v1 según los servidores declarados en openapi.yaml.
app.use('/v1', routes);

app.use(noEncontrado);
app.use(manejadorErrores);

module.exports = app;

/**
 * Validación de contrato (tarea 1.6): cada respuesta de la API se valida
 * contra doc/openapi.yaml con express-openapi-validator (soporta OpenAPI 3.1).
 *
 * El validador envuelve res.json: si una respuesta no cumple el esquema del
 * contrato, se convierte en un error → el status esperado del test falla y
 * el cuerpo trae el detalle de la violación.
 *
 * /attachments se excluye aquí: su multipart lo parsea multer dentro de la
 * ruta y chocaría con el parser del validador; su comportamiento funcional
 * está cubierto en attachments-history.test.js.
 */
const path = require('path');
const express = require('express');
const request = require('supertest');
const { randomUUID } = require('crypto');
const OpenApiValidator = require('express-openapi-validator');
const routes = require('../src/routes');
const pool = require('../src/db/pool');

afterAll(() => pool.end());

function crearAppContrato() {
  const app = express();
  app.use(express.json({ limit: '1mb' }));
  app.use(
    OpenApiValidator.middleware({
      apiSpec: path.resolve(__dirname, '../../doc/openapi.yaml'),
      validateRequests: true,
      validateResponses: true,
      ignorePaths: (ruta) => ruta.startsWith('/v1/attachments'),
    })
  );
  app.use('/v1', routes);
  // Serializa cualquier error (de la app o del validador) al esquema Error.
  // eslint-disable-next-line no-unused-vars
  app.use((err, req, res, next) => {
    res.status(err.httpStatus || err.status || 500).json({
      codigo: err.codigo || 'CONTRATO',
      mensaje: err.message,
      detalle: err.detalle ?? null,
    });
  });
  return app;
}

const app = crearAppContrato();

/** Falla con el cuerpo completo visible cuando el status no es el esperado. */
function esperar(res, status) {
  if (res.status !== status) {
    throw new Error(
      `Se esperaba ${status} y llegó ${res.status}: ${JSON.stringify(res.body)}`
    );
  }
  return res;
}

const T1 = '2026-07-10T10:00:00.000Z';

describe('las respuestas cumplen el contrato de openapi.yaml', () => {
  const email = `contrato-${randomUUID()}@notium.test`;
  const contrasena = 'contrasena123';
  let tokens;

  test('GET /health → Health', async () => {
    esperar(await request(app).get('/v1/health'), 200);
  });

  test('POST /auth/register → 201 SesionResponse, 409 y 400 → Error', async () => {
    esperar(
      await request(app).post('/v1/auth/register').send({
        uuid: randomUUID(),
        nombre: 'Contrato',
        email,
        contrasena,
      }),
      201
    );
    esperar(
      await request(app).post('/v1/auth/register').send({
        uuid: randomUUID(),
        nombre: 'Contrato',
        email, // duplicado
        contrasena,
      }),
      409
    );
    esperar(
      await request(app).post('/v1/auth/register').send({
        uuid: randomUUID(),
        nombre: 'Contrato',
        email: `otro-${randomUUID()}@notium.test`,
        contrasena: 'corta', // < 8: lo rechaza el propio validador de requests
      }),
      400
    );
  });

  test('POST /auth/login → 200 SesionResponse y 401 → Error', async () => {
    const res = esperar(
      await request(app).post('/v1/auth/login').send({ email, contrasena }),
      200
    );
    tokens = res.body.tokens;
    esperar(
      await request(app).post('/v1/auth/login').send({ email, contrasena: 'incorrecta1' }),
      401
    );
  });

  test('POST /auth/refresh → 200 TokensResponse y 401 → Error', async () => {
    const res = esperar(
      await request(app)
        .post('/v1/auth/refresh')
        .set('authorization', `Bearer ${tokens.access_token}`)
        .send({ refresh_token: tokens.refresh_token }),
      200
    );
    tokens = res.body;
    esperar(
      await request(app)
        .post('/v1/auth/refresh')
        .set('authorization', `Bearer ${tokens.access_token}`)
        .send({ refresh_token: 'token-invalido' }),
      401
    );
  });

  test('POST /sync/push → 200 y 409 SyncPushResponse, 401 → Error', async () => {
    const notaUuid = randomUUID();
    esperar(
      await request(app)
        .post('/v1/sync/push')
        .set('authorization', `Bearer ${tokens.access_token}`)
        .send({
          device_id: 'disp-A',
          operaciones: [
            { uuid: notaUuid, entidad: 'NOTA', operacion: 'CREATE', payload: { titulo: 'Contrato' }, updated_at: T1, version: 1 },
          ],
        }),
      200
    );
    // Edición concurrente perdedora → 409 con ResultadoSync CONFLICT.
    await request(app)
      .post('/v1/sync/push')
      .set('authorization', `Bearer ${tokens.access_token}`)
      .send({
        device_id: 'disp-A',
        operaciones: [
          { uuid: notaUuid, entidad: 'NOTA', operacion: 'UPDATE', payload: { titulo: 'v2' }, updated_at: '2026-07-10T11:00:00.000Z', version: 1 },
        ],
      });
    esperar(
      await request(app)
        .post('/v1/sync/push')
        .set('authorization', `Bearer ${tokens.access_token}`)
        .send({
          device_id: 'disp-B',
          operaciones: [
            { uuid: notaUuid, entidad: 'NOTA', operacion: 'UPDATE', payload: { titulo: 'pierde' }, updated_at: T1, version: 1 },
          ],
        }),
      409
    );
    esperar(
      await request(app)
        .post('/v1/sync/push')
        .send({ device_id: 'disp-A', operaciones: [] }),
      401
    );
  });

  test('GET /sync/pull → 200 SyncPullResponse y 400 → Error', async () => {
    esperar(
      await request(app)
        .get('/v1/sync/pull')
        .set('authorization', `Bearer ${tokens.access_token}`)
        .query({ desde: '1970-01-01T00:00:00.000Z', device_id: 'disp-C', limite: 10 }),
      200
    );
    esperar(
      await request(app)
        .get('/v1/sync/pull')
        .set('authorization', `Bearer ${tokens.access_token}`),
      400 // falta desde: lo rechaza el validador de requests con el esquema Error
    );
  });

  test('GET /history/{nota_uuid} → 200 y 404 → Error', async () => {
    const notaUuid = randomUUID();
    await request(app)
      .post('/v1/sync/push')
      .set('authorization', `Bearer ${tokens.access_token}`)
      .send({
        device_id: 'disp-A',
        operaciones: [
          { uuid: notaUuid, entidad: 'NOTA', operacion: 'CREATE', payload: { titulo: 'Con historial' }, updated_at: T1, version: 1 },
        ],
      });
    esperar(
      await request(app)
        .get(`/v1/history/${notaUuid}`)
        .set('authorization', `Bearer ${tokens.access_token}`),
      200
    );
    esperar(
      await request(app)
        .get(`/v1/history/${randomUUID()}`)
        .set('authorization', `Bearer ${tokens.access_token}`),
      404
    );
  });

  test('POST /auth/logout → 204', async () => {
    esperar(
      await request(app)
        .post('/v1/auth/logout')
        .set('authorization', `Bearer ${tokens.access_token}`)
        .send({ refresh_token: tokens.refresh_token }),
      204
    );
  });
});

/**
 * E2E de la tarea 1.6: el flujo literal de CU-05 (conflicto de edición
 * concurrente entre dos dispositivos y convergencia por LWW) y la
 * propagación de tombstones de CU-06, simulando la SyncTask de cada
 * dispositivo: push de pendientes → aplicar resultados → pull de cambios.
 */
const request = require('supertest');
const { randomUUID } = require('crypto');
const app = require('../src/app');
const pool = require('../src/db/pool');

afterAll(() => pool.end());

async function crearUsuario() {
  const res = await request(app)
    .post('/v1/auth/register')
    .send({
      uuid: randomUUID(),
      nombre: 'Usuario E2E',
      email: `e2e-${randomUUID()}@notium.test`,
      contrasena: 'contrasena123',
    });
  expect(res.status).toBe(201);
  return { token: res.body.tokens.access_token };
}

function push(token, deviceId, operaciones) {
  return request(app)
    .post('/v1/sync/push')
    .set('authorization', `Bearer ${token}`)
    .send({ device_id: deviceId, operaciones });
}

function pull(token, deviceId, desde) {
  return request(app)
    .get('/v1/sync/pull')
    .set('authorization', `Bearer ${token}`)
    .query({ desde, device_id: deviceId });
}

const EPOCA = '1970-01-01T00:00:00.000Z';

test('CU-05: dos dispositivos editan offline la misma nota y convergen por LWW', async () => {
  const { token } = await crearUsuario();
  const notaUuid = randomUUID();

  // Precondición: la nota existe sincronizada en ambos dispositivos (version 1).
  await push(token, 'disp-A', [
    { uuid: notaUuid, entidad: 'NOTA', operacion: 'CREATE', payload: { titulo: 'Original', contenido: 'base' }, updated_at: '2026-07-11T09:00:00.000Z', version: 1 },
  ]);
  const pullInicialB = await pull(token, 'disp-B', EPOCA);
  expect(pullInicialB.body.cambios[0]).toMatchObject({ uuid: notaUuid, version: 1 });
  let estadoB = pullInicialB.body.cambios[0].payload; // copia local de B
  let cursorB = pullInicialB.body.timestamp_servidor;

  // Ambos editan offline: A a las 10:20 (más reciente), B a las 10:05.
  // Fase 1 — A recupera red y sincroniza primero: sin conflicto → v2.
  const pushA = await push(token, 'disp-A', [
    { uuid: notaUuid, entidad: 'NOTA', operacion: 'UPDATE', payload: { titulo: 'Edición de A' }, updated_at: '2026-07-11T10:20:00.000Z', version: 1 },
  ]);
  expect(pushA.status).toBe(200);
  expect(pushA.body.resultados[0]).toMatchObject({ estado: 'ACCEPTED', version_servidor: 2 });

  // Fase 2 — B sincroniza después: version 1 vs 2 → concurrencia → LWW:
  // 10:20 del servidor es más reciente que 10:05 → CONFLICT + estado autoritativo.
  const pushB = await push(token, 'disp-B', [
    { uuid: notaUuid, entidad: 'NOTA', operacion: 'UPDATE', payload: { titulo: 'Edición de B' }, updated_at: '2026-07-11T10:05:00.000Z', version: 1 },
  ]);
  expect(pushB.status).toBe(409);
  const resultadoB = pushB.body.resultados[0];
  expect(resultadoB).toMatchObject({ estado: 'CONFLICT', version_servidor: 2 });
  expect(resultadoB.payload_servidor.titulo).toBe('Edición de A');

  // Fase 3 — Resolución local en B: aplica el payload autoritativo.
  estadoB = { titulo: resultadoB.payload_servidor.titulo };

  // Postcondición 1: ambos dispositivos convergen al estado del servidor (RNF-02).
  const { rows } = await pool.query('SELECT titulo, version FROM nota WHERE uuid = $1', [notaUuid]);
  expect(rows[0]).toMatchObject({ titulo: 'Edición de A', version: 2 });
  expect(estadoB.titulo).toBe(rows[0].titulo);

  // El pull siguiente de B no re-entrega su propio eco ni pierde nada.
  const pullFinalB = await pull(token, 'disp-B', cursorB);
  const cambioParaB = pullFinalB.body.cambios.find((c) => c.uuid === notaUuid);
  expect(cambioParaB).toMatchObject({ version: 2, device_id: 'disp-A' });
  expect(cambioParaB.payload.titulo).toBe('Edición de A');

  // Postcondición 2: el cambio descartado de B quedó en el historial (RF-05).
  const historial = await request(app)
    .get(`/v1/history/${notaUuid}`)
    .set('authorization', `Bearer ${token}`);
  const descartado = historial.body.historial.find(
    (h) => h.origen_cambio === 'CONFLICTO_DESCARTADO'
  );
  expect(descartado).toBeDefined();
  expect(descartado.dispositivo_origen).toBe('disp-B');
  expect(JSON.parse(descartado.valor_nuevo).titulo).toBe('Edición de B');
});

test('CU-06: la eliminación offline se propaga como tombstone al otro dispositivo', async () => {
  const { token } = await crearUsuario();
  const notaUuid = randomUUID();

  // A crea y sincroniza; B la recibe.
  await push(token, 'disp-A', [
    { uuid: notaUuid, entidad: 'NOTA', operacion: 'CREATE', payload: { titulo: 'Efímera' }, updated_at: '2026-07-11T09:00:00.000Z', version: 1 },
  ]);
  const pullB = await pull(token, 'disp-B', EPOCA);
  expect(pullB.body.cambios).toHaveLength(1);
  const cursorB = pullB.body.timestamp_servidor;

  // A elimina offline y sincroniza el tombstone.
  const borrado = await push(token, 'disp-A', [
    { uuid: notaUuid, entidad: 'NOTA', operacion: 'DELETE', payload: {}, updated_at: '2026-07-11T09:30:00.000Z', version: 1 },
  ]);
  expect(borrado.body.resultados[0].estado).toBe('ACCEPTED');

  // B recibe el DELETE en su siguiente pull y puede borrar su copia local.
  const pullTombstone = await pull(token, 'disp-B', cursorB);
  expect(pullTombstone.body.cambios).toHaveLength(1);
  expect(pullTombstone.body.cambios[0]).toMatchObject({
    uuid: notaUuid,
    operacion: 'DELETE',
    is_deleted: true,
  });

  // En el servidor no hubo borrado físico (sección 5.4).
  const { rows } = await pool.query('SELECT is_deleted FROM nota WHERE uuid = $1', [notaUuid]);
  expect(rows).toHaveLength(1);
  expect(rows[0].is_deleted).toBe(true);
});

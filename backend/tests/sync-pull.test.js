/**
 * Suite de GET /sync/pull (tarea 1.4): corte por `desde`, anti-eco por
 * device_id, paginación con limite/hay_mas, tombstones y aislamiento
 * entre usuarios.
 */
const request = require('supertest');
const { randomUUID } = require('crypto');
const app = require('../src/app');
const pool = require('../src/db/pool');

afterAll(() => pool.end());

const EPOCA = '1970-01-01T00:00:00.000Z';
const T1 = '2026-07-10T10:00:00.000Z';
const T2 = '2026-07-10T11:00:00.000Z';

async function crearUsuario() {
  const res = await request(app)
    .post('/v1/auth/register')
    .send({
      uuid: randomUUID(),
      nombre: 'Usuario Pull',
      email: `pull-${randomUUID()}@notium.test`,
      contrasena: 'contrasena123',
    });
  expect(res.status).toBe(201);
  return { token: res.body.tokens.access_token, uuid: res.body.usuario.uuid };
}

async function push(token, deviceId, operaciones) {
  const res = await request(app)
    .post('/v1/sync/push')
    .set('authorization', `Bearer ${token}`)
    .send({ device_id: deviceId, operaciones });
  expect([200, 409]).toContain(res.status);
  return res;
}

function pull(token, query) {
  return request(app)
    .get('/v1/sync/pull')
    .set('authorization', `Bearer ${token}`)
    .query(query);
}

function opNota(uuid, operacion, { payload = {}, updated_at, version }) {
  return { uuid, entidad: 'NOTA', operacion, payload, updated_at, version };
}

async function crearNota(token, deviceId, titulo, uuid = randomUUID()) {
  await push(token, deviceId, [
    opNota(uuid, 'CREATE', { payload: { titulo }, updated_at: T1, version: 1 }),
  ]);
  return uuid;
}

// ---------------------------------------------------------------------------

describe('validación y autenticación', () => {
  test('sin token responde 401', async () => {
    const res = await request(app).get('/v1/sync/pull').query({ desde: EPOCA });
    expect(res.status).toBe(401);
  });

  test('sin desde responde 400', async () => {
    const { token } = await crearUsuario();
    const res = await pull(token, {});
    expect(res.status).toBe(400);
    expect(res.body.codigo).toBe('VALIDACION');
  });

  test('limite fuera de rango responde 400', async () => {
    const { token } = await crearUsuario();
    const res = await pull(token, { desde: EPOCA, limite: 501 });
    expect(res.status).toBe(400);
  });
});

describe('entrega de cambios', () => {
  test('devuelve los cambios posteriores a desde con el contrato SyncPullResponse', async () => {
    const { token } = await crearUsuario();
    const uuid = await crearNota(token, 'disp-A', 'Mi nota');

    const res = await pull(token, { desde: EPOCA, device_id: 'disp-B' });
    expect(res.status).toBe(200);
    expect(res.body.hay_mas).toBe(false);
    expect(typeof res.body.timestamp_servidor).toBe('string');
    expect(res.body.cambios).toHaveLength(1);
    expect(res.body.cambios[0]).toMatchObject({
      uuid,
      entidad: 'NOTA',
      operacion: 'CREATE',
      version: 1,
      is_deleted: false,
      device_id: 'disp-A',
    });
    expect(res.body.cambios[0].payload.titulo).toBe('Mi nota');
  });

  test('anti-eco: excluye los cambios del propio device_id consultante', async () => {
    const { token } = await crearUsuario();
    await crearNota(token, 'disp-A', 'Hecha en A');

    const ecoPropio = await pull(token, { desde: EPOCA, device_id: 'disp-A' });
    expect(ecoPropio.body.cambios).toHaveLength(0);

    const otroDispositivo = await pull(token, { desde: EPOCA, device_id: 'disp-B' });
    expect(otroDispositivo.body.cambios).toHaveLength(1);
  });

  test('incluye tombstones para propagar eliminaciones', async () => {
    const { token } = await crearUsuario();
    const uuid = await crearNota(token, 'disp-A', 'Se eliminará');
    await push(token, 'disp-A', [
      opNota(uuid, 'DELETE', { payload: {}, updated_at: T2, version: 1 }),
    ]);

    const res = await pull(token, { desde: EPOCA, device_id: 'disp-B' });
    expect(res.body.cambios).toHaveLength(1);
    expect(res.body.cambios[0]).toMatchObject({
      uuid,
      operacion: 'DELETE',
      is_deleted: true,
      payload: {}, // el tombstone viaja sin contenido (sección 5.4)
    });
  });

  test('no entrega cambios de otros usuarios', async () => {
    const usuarioA = await crearUsuario();
    const usuarioB = await crearUsuario();
    await crearNota(usuarioA.token, 'disp-A', 'Solo de A');

    const res = await pull(usuarioB.token, { desde: EPOCA });
    expect(res.body.cambios).toHaveLength(0);
  });

  test('incluye cambios de adjuntos (entidad ADJUNTO)', async () => {
    const { token } = await crearUsuario();
    const notaUuid = await crearNota(token, 'disp-A', 'Con adjunto');
    const adjuntoUuid = randomUUID();
    await push(token, 'disp-A', [
      {
        uuid: adjuntoUuid,
        entidad: 'ADJUNTO',
        operacion: 'CREATE',
        payload: { nota_uuid: notaUuid, ruta_local: '/docs/a.pdf' },
        updated_at: T2,
        version: 1,
      },
    ]);

    const res = await pull(token, { desde: EPOCA, device_id: 'disp-B' });
    expect(res.body.cambios).toHaveLength(2);
    const adjunto = res.body.cambios.find((c) => c.entidad === 'ADJUNTO');
    expect(adjunto).toMatchObject({ uuid: adjuntoUuid, operacion: 'CREATE' });
    expect(adjunto.payload.nota_uuid).toBe(notaUuid);
  });
});

describe('paginación y cursor', () => {
  test('limite + hay_mas paginan y timestamp_servidor avanza el cursor sin perder cambios', async () => {
    const { token } = await crearUsuario();
    const uuids = [];
    for (let i = 0; i < 3; i++) uuids.push(await crearNota(token, 'disp-A', `Nota ${i}`));

    // Página 1: 2 de 3 cambios.
    const pagina1 = await pull(token, { desde: EPOCA, device_id: 'disp-B', limite: 2 });
    expect(pagina1.body.cambios).toHaveLength(2);
    expect(pagina1.body.hay_mas).toBe(true);

    // Página 2 con el cursor devuelto: el cambio restante, sin repetidos.
    const pagina2 = await pull(token, {
      desde: pagina1.body.timestamp_servidor,
      device_id: 'disp-B',
      limite: 2,
    });
    expect(pagina2.body.cambios).toHaveLength(1);
    expect(pagina2.body.hay_mas).toBe(false);

    const recibidos = [...pagina1.body.cambios, ...pagina2.body.cambios].map((c) => c.uuid);
    expect(new Set(recibidos).size).toBe(3);
    expect(recibidos.sort()).toEqual([...uuids].sort());
  });

  test('pull incremental: con el cursor persistido solo llegan los cambios nuevos', async () => {
    const { token } = await crearUsuario();
    await crearNota(token, 'disp-A', 'Vieja');

    const inicial = await pull(token, { desde: EPOCA, device_id: 'disp-B' });
    expect(inicial.body.cambios).toHaveLength(1);
    const cursor = inicial.body.timestamp_servidor;

    // Sin cambios nuevos: vacío y el cursor no retrocede.
    const vacio = await pull(token, { desde: cursor, device_id: 'disp-B' });
    expect(vacio.body.cambios).toHaveLength(0);
    expect(vacio.body.hay_mas).toBe(false);

    // Llega un cambio nuevo: solo ese.
    const nueva = await crearNota(token, 'disp-A', 'Nueva');
    const incremental = await pull(token, { desde: cursor, device_id: 'disp-B' });
    expect(incremental.body.cambios).toHaveLength(1);
    expect(incremental.body.cambios[0].uuid).toBe(nueva);
  });
});

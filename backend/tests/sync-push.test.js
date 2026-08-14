/**
 * Suite de POST /sync/push (tarea 1.3), un bloque por paso del roadmap.
 * Corre contra la BD real de desarrollo (PostgreSQL en Docker); cada test
 * usa uuids/emails aleatorios para no depender de datos previos.
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
      nombre: 'Usuario Sync',
      email: `sync-${randomUUID()}@notium.test`,
      contrasena: 'contrasena123',
    });
  expect(res.status).toBe(201);
  return { token: res.body.tokens.access_token, uuid: res.body.usuario.uuid };
}

function push(token, deviceId, operaciones) {
  return request(app)
    .post('/v1/sync/push')
    .set('authorization', `Bearer ${token}`)
    .send({ device_id: deviceId, operaciones });
}

function opNota(uuid, operacion, { payload = {}, updated_at, version }) {
  return { uuid, entidad: 'NOTA', operacion, payload, updated_at, version };
}

const T1 = '2026-07-10T10:00:00.000Z';
const T2 = '2026-07-10T11:00:00.000Z';
const T3 = '2026-07-10T12:00:00.000Z';

/** Crea una nota (version 1 en T1) y la edita (version 2 en T2). */
async function notaConDosVersiones(token) {
  const uuid = randomUUID();
  let res = await push(token, 'disp-A', [
    opNota(uuid, 'CREATE', { payload: { titulo: 'v1', contenido: 'original' }, updated_at: T1, version: 1 }),
  ]);
  expect(res.status).toBe(200);
  res = await push(token, 'disp-A', [
    opNota(uuid, 'UPDATE', { payload: { titulo: 'v2' }, updated_at: T2, version: 1 }),
  ]);
  expect(res.status).toBe(200);
  expect(res.body.resultados[0]).toMatchObject({ estado: 'ACCEPTED', version_servidor: 2 });
  return uuid;
}

// ---------------------------------------------------------------------------

describe('validación y control de acceso (paso 1)', () => {
  test('sin token responde 401', async () => {
    const res = await request(app)
      .post('/v1/sync/push')
      .send({ device_id: 'disp-X', operaciones: [] });
    expect(res.status).toBe(401);
  });

  test('lote sin operaciones responde 400 con esquema Error', async () => {
    const { token } = await crearUsuario();
    const res = await push(token, 'disp-X', []);
    expect(res.status).toBe(400);
    expect(res.body.codigo).toBe('VALIDACION');
  });

  test('item inválido produce ERROR sin abortar el lote (lote mixto)', async () => {
    const { token } = await crearUsuario();
    const buena = randomUUID();
    const res = await push(token, 'disp-X', [
      opNota(buena, 'CREATE', { payload: { titulo: 'Válida' }, updated_at: T1, version: 1 }),
      { uuid: randomUUID(), entidad: 'CARPETA', operacion: 'CREATE', payload: {}, updated_at: T1, version: 1 },
    ]);
    expect(res.status).toBe(200); // hay ERROR pero no CONFLICT → 200
    expect(res.body.resultados).toHaveLength(2);
    expect(res.body.resultados[0]).toMatchObject({ uuid: buena, estado: 'ACCEPTED' });
    expect(res.body.resultados[1].estado).toBe('ERROR');
    expect(res.body.resultados[1].error.codigo).toBe('VALIDACION');
  });

  test('operación sobre registro de otro usuario produce ERROR ACCESO_DENEGADO', async () => {
    const usuarioA = await crearUsuario();
    const usuarioB = await crearUsuario();
    const uuid = randomUUID();
    await push(usuarioA.token, 'disp-A', [
      opNota(uuid, 'CREATE', { payload: { titulo: 'De A' }, updated_at: T1, version: 1 }),
    ]);

    const res = await push(usuarioB.token, 'disp-B', [
      opNota(uuid, 'UPDATE', { payload: { titulo: 'Intruso' }, updated_at: T2, version: 1 }),
    ]);
    expect(res.body.resultados[0].estado).toBe('ERROR');
    expect(res.body.resultados[0].error.codigo).toBe('ACCESO_DENEGADO');
  });

  test('UPDATE de un registro inexistente produce ERROR REGISTRO_NO_ENCONTRADO', async () => {
    const { token } = await crearUsuario();
    const res = await push(token, 'disp-X', [
      opNota(randomUUID(), 'UPDATE', { payload: { titulo: 'Fantasma' }, updated_at: T1, version: 1 }),
    ]);
    expect(res.body.resultados[0].estado).toBe('ERROR');
    expect(res.body.resultados[0].error.codigo).toBe('REGISTRO_NO_ENCONTRADO');
  });
});

describe('idempotencia por (uuid, version) (paso 2)', () => {
  test('reenviar el mismo lote devuelve el mismo resultado sin duplicar', async () => {
    const { token } = await crearUsuario();
    const uuid = randomUUID();
    const lote = [
      opNota(uuid, 'CREATE', { payload: { titulo: 'Única' }, updated_at: T1, version: 1 }),
    ];

    const primera = await push(token, 'disp-X', lote);
    const reintento = await push(token, 'disp-X', lote);

    expect(primera.status).toBe(200);
    expect(reintento.status).toBe(200);
    expect(reintento.body.resultados).toEqual(primera.body.resultados);

    const { rows } = await pool.query('SELECT version FROM nota WHERE uuid = $1', [uuid]);
    expect(rows).toHaveLength(1);
    expect(rows[0].version).toBe(1); // el reintento no re-aplicó ni incrementó
  });

  test('una edición legítima posterior usa otra version y sí se aplica', async () => {
    const { token } = await crearUsuario();
    const uuid = await notaConDosVersiones(token); // llegó a version 2
    const res = await push(token, 'disp-A', [
      opNota(uuid, 'UPDATE', { payload: { titulo: 'v3' }, updated_at: T3, version: 2 }),
    ]);
    expect(res.body.resultados[0]).toMatchObject({ estado: 'ACCEPTED', version_servidor: 3 });
  });
});

describe('camino sin conflicto (paso 3)', () => {
  test('CREATE y UPDATE con version coincidente → ACCEPTED e historial', async () => {
    const { token } = await crearUsuario();
    const uuid = await notaConDosVersiones(token);

    const { rows: notas } = await pool.query('SELECT titulo, version FROM nota WHERE uuid = $1', [uuid]);
    expect(notas[0]).toMatchObject({ titulo: 'v2', version: 2 });

    const { rows: historial } = await pool.query(
      `SELECT origen_cambio FROM historial_cambio WHERE nota_uuid = $1 ORDER BY fecha`,
      [uuid]
    );
    expect(historial.map((h) => h.origen_cambio)).toEqual(['LOCAL', 'LOCAL']);
  });
});

describe('conflicto LWW (paso 4)', () => {
  test('gana el servidor: version vieja y updated_at más antiguo → CONFLICT + 409', async () => {
    const { token } = await crearUsuario();
    const uuid = await notaConDosVersiones(token); // servidor: v2 en T2

    // Dispositivo B editó offline partiendo de v1, ANTES de T2.
    const res = await push(token, 'disp-B', [
      opNota(uuid, 'UPDATE', { payload: { titulo: 'edición vieja de B' }, updated_at: T1, version: 1 }),
    ]);

    expect(res.status).toBe(409);
    const r = res.body.resultados[0];
    expect(r.estado).toBe('CONFLICT');
    expect(r.version_servidor).toBe(2);
    expect(r.payload_servidor.titulo).toBe('v2'); // estado autoritativo para resolución local

    // El cambio descartado del cliente quedó auditado (RF-05).
    const { rows } = await pool.query(
      `SELECT dispositivo_origen, valor_nuevo FROM historial_cambio
       WHERE nota_uuid = $1 AND origen_cambio = 'CONFLICTO_DESCARTADO'`,
      [uuid]
    );
    expect(rows).toHaveLength(1);
    expect(rows[0].dispositivo_origen).toBe('disp-B');
    expect(JSON.parse(rows[0].valor_nuevo).titulo).toBe('edición vieja de B');

    // Y el servidor NO aplicó el cambio.
    const { rows: notas } = await pool.query('SELECT titulo, version FROM nota WHERE uuid = $1', [uuid]);
    expect(notas[0]).toMatchObject({ titulo: 'v2', version: 2 });
  });

  test('gana el cliente: version vieja pero updated_at más reciente → ACCEPTED y descarte auditado', async () => {
    const { token } = await crearUsuario();
    const uuid = await notaConDosVersiones(token); // servidor: v2 en T2

    // Dispositivo B editó offline partiendo de v1, pero DESPUÉS de T2.
    const res = await push(token, 'disp-B', [
      opNota(uuid, 'UPDATE', { payload: { titulo: 'edición nueva de B' }, updated_at: T3, version: 1 }),
    ]);

    expect(res.status).toBe(200);
    expect(res.body.resultados[0]).toMatchObject({ estado: 'ACCEPTED', version_servidor: 3 });

    const { rows: notas } = await pool.query('SELECT titulo, version FROM nota WHERE uuid = $1', [uuid]);
    expect(notas[0]).toMatchObject({ titulo: 'edición nueva de B', version: 3 });

    // La versión del servidor que se descartó quedó en el historial.
    const { rows } = await pool.query(
      `SELECT valor_nuevo FROM historial_cambio
       WHERE nota_uuid = $1 AND origen_cambio = 'CONFLICTO_DESCARTADO'`,
      [uuid]
    );
    expect(rows).toHaveLength(1);
    expect(JSON.parse(rows[0].valor_nuevo).titulo).toBe('v2');
  });
});

describe('tombstones (paso 5)', () => {
  test('DELETE marca is_deleted sin borrar físicamente', async () => {
    const { token } = await crearUsuario();
    const uuid = randomUUID();
    await push(token, 'disp-A', [
      opNota(uuid, 'CREATE', { payload: { titulo: 'A eliminar' }, updated_at: T1, version: 1 }),
    ]);

    const res = await push(token, 'disp-A', [
      opNota(uuid, 'DELETE', { payload: {}, updated_at: T2, version: 1 }),
    ]);
    expect(res.body.resultados[0]).toMatchObject({ estado: 'ACCEPTED', version_servidor: 2 });

    const { rows } = await pool.query('SELECT is_deleted, titulo FROM nota WHERE uuid = $1', [uuid]);
    expect(rows).toHaveLength(1); // sigue existiendo (tombstone)
    expect(rows[0].is_deleted).toBe(true);
    expect(rows[0].titulo).toBe('A eliminar'); // el contenido se conserva
  });
});

describe('códigos de respuesta (paso 6)', () => {
  test('lote con aceptados + un conflicto responde 409 con el array completo en orden', async () => {
    const { token } = await crearUsuario();
    const conflictiva = await notaConDosVersiones(token);
    const nueva = randomUUID();

    const res = await push(token, 'disp-B', [
      opNota(nueva, 'CREATE', { payload: { titulo: 'Sin problema' }, updated_at: T3, version: 1 }),
      opNota(conflictiva, 'UPDATE', { payload: { titulo: 'pierde LWW' }, updated_at: T1, version: 1 }),
    ]);

    expect(res.status).toBe(409);
    expect(res.body.resultados).toHaveLength(2);
    expect(res.body.resultados[0]).toMatchObject({ uuid: nueva, estado: 'ACCEPTED' });
    expect(res.body.resultados[1]).toMatchObject({ uuid: conflictiva, estado: 'CONFLICT' });

    // Los items sin conflicto del mismo lote SÍ quedaron aplicados (openapi.yaml).
    const { rows } = await pool.query('SELECT 1 FROM nota WHERE uuid = $1', [nueva]);
    expect(rows).toHaveLength(1);
  });
});

describe('adjuntos por metadatos (entidad ADJUNTO)', () => {
  test('CREATE de adjunto sobre nota propia → ACCEPTED; sobre nota ajena → ERROR', async () => {
    const usuarioA = await crearUsuario();
    const usuarioB = await crearUsuario();
    const notaA = randomUUID();
    await push(usuarioA.token, 'disp-A', [
      opNota(notaA, 'CREATE', { payload: { titulo: 'Con adjunto' }, updated_at: T1, version: 1 }),
    ]);

    const propio = await push(usuarioA.token, 'disp-A', [
      {
        uuid: randomUUID(),
        entidad: 'ADJUNTO',
        operacion: 'CREATE',
        payload: { nota_uuid: notaA, ruta_local: '/docs/factura.pdf' },
        updated_at: T2,
        version: 1,
      },
    ]);
    expect(propio.body.resultados[0].estado).toBe('ACCEPTED');

    const ajeno = await push(usuarioB.token, 'disp-B', [
      {
        uuid: randomUUID(),
        entidad: 'ADJUNTO',
        operacion: 'CREATE',
        payload: { nota_uuid: notaA, ruta_local: '/mal/intento.pdf' },
        updated_at: T2,
        version: 1,
      },
    ]);
    expect(ajeno.body.resultados[0].estado).toBe('ERROR');
    expect(ajeno.body.resultados[0].error.codigo).toBe('ACCESO_DENEGADO');
  });
});

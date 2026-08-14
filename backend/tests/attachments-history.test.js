/**
 * Suite de la tarea 1.5: POST/GET/DELETE /attachments (límite 10 MB → 413,
 * idempotencia por contenido → 409, soft delete → 410) y GET /history (RF-05).
 */
const request = require('supertest');
const { randomUUID } = require('crypto');
const app = require('../src/app');
const pool = require('../src/db/pool');

afterAll(() => pool.end());

const T1 = '2026-07-10T10:00:00.000Z';
const T2 = '2026-07-10T11:00:00.000Z';

async function crearUsuario() {
  const res = await request(app)
    .post('/v1/auth/register')
    .send({
      uuid: randomUUID(),
      nombre: 'Usuario Adjuntos',
      email: `adj-${randomUUID()}@notium.test`,
      contrasena: 'contrasena123',
    });
  expect(res.status).toBe(201);
  return { token: res.body.tokens.access_token, uuid: res.body.usuario.uuid };
}

async function crearNota(token, titulo = 'Nota con adjuntos') {
  const uuid = randomUUID();
  const res = await request(app)
    .post('/v1/sync/push')
    .set('authorization', `Bearer ${token}`)
    .send({
      device_id: 'disp-A',
      operaciones: [
        { uuid, entidad: 'NOTA', operacion: 'CREATE', payload: { titulo }, updated_at: T1, version: 1 },
      ],
    });
  expect(res.status).toBe(200);
  return uuid;
}

function subir(token, { uuid, notaUuid, contenido, nombre = 'archivo.pdf' }) {
  return request(app)
    .post('/v1/attachments')
    .set('authorization', `Bearer ${token}`)
    .field('uuid', uuid)
    .field('nota_uuid', notaUuid)
    .field('device_id', 'disp-A')
    .attach('archivo', contenido, nombre);
}

// ---------------------------------------------------------------------------

describe('POST /attachments', () => {
  test('sin token responde 401', async () => {
    const res = await request(app).post('/v1/attachments');
    expect(res.status).toBe(401);
  });

  test('sube un binario y devuelve los metadatos con url_remota (201)', async () => {
    const { token } = await crearUsuario();
    const notaUuid = await crearNota(token);
    const uuid = randomUUID();
    const contenido = Buffer.from('contenido del pdf de prueba');

    const res = await subir(token, { uuid, notaUuid, contenido });
    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({
      uuid,
      nota_uuid: notaUuid,
      url_remota: `/v1/attachments/${uuid}`,
      is_deleted: false,
      version: 1,
    });
  });

  test('rechaza archivos de más de 10 MB con 413 (RNF-05, CU-08)', async () => {
    const { token } = await crearUsuario();
    const notaUuid = await crearNota(token);
    const grande = Buffer.alloc(10 * 1024 * 1024 + 1, 1); // 10 MB + 1 byte

    const res = await subir(token, { uuid: randomUUID(), notaUuid, contenido: grande });
    expect(res.status).toBe(413);
    expect(res.body.codigo).toBe('ADJUNTO_EXCEDE_LIMITE');
  });

  test('reintento con el mismo contenido es idempotente (201); contenido distinto → 409', async () => {
    const { token } = await crearUsuario();
    const notaUuid = await crearNota(token);
    const uuid = randomUUID();
    const contenido = Buffer.from('versión original');

    const primera = await subir(token, { uuid, notaUuid, contenido });
    expect(primera.status).toBe(201);

    const reintento = await subir(token, { uuid, notaUuid, contenido });
    expect(reintento.status).toBe(201);
    expect(reintento.body).toEqual(primera.body);

    const distinto = await subir(token, { uuid, notaUuid, contenido: Buffer.from('otro contenido') });
    expect(distinto.status).toBe(409);
    expect(distinto.body.codigo).toBe('ADJUNTO_CONTENIDO_DISTINTO');
  });

  test('nota inexistente o de otro usuario responde 404', async () => {
    const usuarioA = await crearUsuario();
    const usuarioB = await crearUsuario();
    const notaDeA = await crearNota(usuarioA.token);
    const contenido = Buffer.from('x');

    const inexistente = await subir(usuarioA.token, {
      uuid: randomUUID(),
      notaUuid: randomUUID(),
      contenido,
    });
    expect(inexistente.status).toBe(404);

    const ajena = await subir(usuarioB.token, { uuid: randomUUID(), notaUuid: notaDeA, contenido });
    expect(ajena.status).toBe(404);
  });

  test('completa el binario de metadatos ya sincronizados por push', async () => {
    const { token } = await crearUsuario();
    const notaUuid = await crearNota(token);
    const uuid = randomUUID();

    // Flujo normal de la fase 3.5: primero los metadatos por push...
    await request(app)
      .post('/v1/sync/push')
      .set('authorization', `Bearer ${token}`)
      .send({
        device_id: 'disp-A',
        operaciones: [
          { uuid, entidad: 'ADJUNTO', operacion: 'CREATE', payload: { nota_uuid: notaUuid, ruta_local: '/local/f.pdf' }, updated_at: T2, version: 1 },
        ],
      });

    // ...el binario aún no está disponible...
    const sinBinario = await request(app)
      .get(`/v1/attachments/${uuid}`)
      .set('authorization', `Bearer ${token}`);
    expect(sinBinario.status).toBe(404);
    expect(sinBinario.body.codigo).toBe('BINARIO_NO_DISPONIBLE');

    // ...y la subida lo completa conservando los metadatos del push.
    const res = await subir(token, { uuid, notaUuid, contenido: Buffer.from('binario') });
    expect(res.status).toBe(201);
    expect(res.body.ruta_local).toBe('/local/f.pdf');
    expect(res.body.url_remota).toBe(`/v1/attachments/${uuid}`);
  });
});

describe('GET y DELETE /attachments/{uuid}', () => {
  test('descarga el binario exacto subido', async () => {
    const { token } = await crearUsuario();
    const notaUuid = await crearNota(token);
    const uuid = randomUUID();
    const contenido = Buffer.from([0x25, 0x50, 0x44, 0x46, 0x00, 0xff, 0x07]); // bytes arbitrarios

    await subir(token, { uuid, notaUuid, contenido });

    const res = await request(app)
      .get(`/v1/attachments/${uuid}`)
      .set('authorization', `Bearer ${token}`)
      .buffer(true)
      .parse((res2, cb) => {
        const trozos = [];
        res2.on('data', (t) => trozos.push(t));
        res2.on('end', () => cb(null, Buffer.concat(trozos)));
      });

    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toContain('application/octet-stream');
    expect(Buffer.compare(res.body, contenido)).toBe(0);
  });

  test('adjunto inexistente o de otro usuario responde 404', async () => {
    const usuarioA = await crearUsuario();
    const usuarioB = await crearUsuario();
    const notaDeA = await crearNota(usuarioA.token);
    const uuid = randomUUID();
    await subir(usuarioA.token, { uuid, notaUuid: notaDeA, contenido: Buffer.from('privado') });

    const inexistente = await request(app)
      .get(`/v1/attachments/${randomUUID()}`)
      .set('authorization', `Bearer ${usuarioA.token}`);
    expect(inexistente.status).toBe(404);

    const ajeno = await request(app)
      .get(`/v1/attachments/${uuid}`)
      .set('authorization', `Bearer ${usuarioB.token}`);
    expect(ajeno.status).toBe(404);
  });

  test('DELETE hace soft delete: 204, luego GET responde 410 y el tombstone se propaga por pull', async () => {
    const { token } = await crearUsuario();
    const notaUuid = await crearNota(token);
    const uuid = randomUUID();
    await subir(token, { uuid, notaUuid, contenido: Buffer.from('a eliminar') });

    const borrado = await request(app)
      .delete(`/v1/attachments/${uuid}`)
      .set('authorization', `Bearer ${token}`);
    expect(borrado.status).toBe(204);

    // Idempotente: repetir el DELETE también responde 204.
    const repetido = await request(app)
      .delete(`/v1/attachments/${uuid}`)
      .set('authorization', `Bearer ${token}`);
    expect(repetido.status).toBe(204);

    const descarga = await request(app)
      .get(`/v1/attachments/${uuid}`)
      .set('authorization', `Bearer ${token}`);
    expect(descarga.status).toBe(410);
    expect(descarga.body.codigo).toBe('ADJUNTO_ELIMINADO');

    // La fila sigue en la BD como tombstone con la versión incrementada...
    const { rows } = await pool.query('SELECT is_deleted, version FROM adjunto WHERE uuid = $1', [uuid]);
    expect(rows[0]).toMatchObject({ is_deleted: true, version: 2 });

    // ...y otro dispositivo la recibe como DELETE vía /sync/pull (sección 5.4).
    const pull = await request(app)
      .get('/v1/sync/pull')
      .set('authorization', `Bearer ${token}`)
      .query({ desde: '1970-01-01T00:00:00.000Z', device_id: 'disp-B' });
    const tombstone = pull.body.cambios.find((c) => c.uuid === uuid);
    expect(tombstone).toMatchObject({ entidad: 'ADJUNTO', operacion: 'DELETE', is_deleted: true });
  });
});

describe('GET /history/{nota_uuid} (RF-05)', () => {
  test('devuelve el historial en orden descendente, incluidos los conflictos descartados', async () => {
    const { token } = await crearUsuario();
    const notaUuid = await crearNota(token, 'v1'); // historial: CREATE

    // UPDATE normal → historial: UPDATE (v2 en T2).
    await request(app)
      .post('/v1/sync/push')
      .set('authorization', `Bearer ${token}`)
      .send({
        device_id: 'disp-A',
        operaciones: [
          { uuid: notaUuid, entidad: 'NOTA', operacion: 'UPDATE', payload: { titulo: 'v2' }, updated_at: T2, version: 1 },
        ],
      });

    // Edición vieja desde otro dispositivo → pierde LWW → CONFLICTO_DESCARTADO.
    const conflicto = await request(app)
      .post('/v1/sync/push')
      .set('authorization', `Bearer ${token}`)
      .send({
        device_id: 'disp-B',
        operaciones: [
          { uuid: notaUuid, entidad: 'NOTA', operacion: 'UPDATE', payload: { titulo: 'perdedora' }, updated_at: T1, version: 1 },
        ],
      });
    expect(conflicto.status).toBe(409);

    const res = await request(app)
      .get(`/v1/history/${notaUuid}`)
      .set('authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    const { historial } = res.body;
    expect(historial.length).toBe(3);

    // Orden descendente por fecha.
    const fechas = historial.map((h) => h.fecha);
    expect([...fechas].sort().reverse()).toEqual(fechas);

    // El conflicto descartado quedó auditado con su dispositivo y su valor.
    const descartado = historial.find((h) => h.origen_cambio === 'CONFLICTO_DESCARTADO');
    expect(descartado).toBeDefined();
    expect(descartado.dispositivo_origen).toBe('disp-B');
    expect(JSON.parse(descartado.valor_nuevo).titulo).toBe('perdedora');
  });

  test('nota inexistente o de otro usuario responde 404', async () => {
    const usuarioA = await crearUsuario();
    const usuarioB = await crearUsuario();
    const notaDeA = await crearNota(usuarioA.token);

    const inexistente = await request(app)
      .get(`/v1/history/${randomUUID()}`)
      .set('authorization', `Bearer ${usuarioA.token}`);
    expect(inexistente.status).toBe(404);

    const ajena = await request(app)
      .get(`/v1/history/${notaDeA}`)
      .set('authorization', `Bearer ${usuarioB.token}`);
    expect(ajena.status).toBe(404);
  });
});

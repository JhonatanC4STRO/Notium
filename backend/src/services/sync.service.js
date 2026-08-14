const pool = require('../db/pool');
const AppError = require('../utils/app-error');

/**
 * POST /sync/push — el corazón del sistema (tarea 1.3, secciones 5.3, 5.5 y 6.3).
 *
 * Cada operación del lote se procesa de forma independiente dentro de su
 * propia transacción SQL: un rechazo individual produce un item ERROR sin
 * abortar el resto del lote. El array de resultados conserva el orden del
 * lote de entrada (contrato de openapi.yaml).
 *
 * Reglas de resolución (sección 5.3):
 * - `version` del cliente == `version` del servidor → sin conflicto: se aplica
 *   y la versión autoritativa se incrementa (solo el servidor incrementa, 6.3).
 * - Versiones distintas → edición concurrente: Last-Write-Wins por `updated_at`.
 *   Empate exacto de `updated_at` → gana el servidor (decisión determinista;
 *   evita que dos réplicas se pisen alternadamente).
 * - CREATE sobre un registro que ya existe (p. ej. reinstalación del cliente)
 *   se trata como edición concurrente y lo resuelve LWW.
 *
 * Idempotencia (sección 6.3, corregida): los resultados ACCEPTED y CONFLICT
 * se persisten en `operacion_procesada` con clave (uuid, version, operacion,
 * device_id); un reenvío devuelve el resultado original sin re-aplicar.
 * La clave del doc — (uuid, version) a secas — colisiona: el UPDATE que parte
 * de la versión base 1 comparte clave con el CREATE que la produjo, y una
 * edición concurrente de OTRO dispositivo con la misma versión base se
 * confundiría con un reintento en lugar de entrar al flujo LWW (ver la
 * migración clave-idempotencia-compuesta). Los ERROR no se persisten a
 * propósito: son rechazos de validación y la corrección del usuario puede
 * llegar con la misma clave — persistirlos la bloquearía para siempre.
 */

const UUID_V4 = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const ENTIDADES = ['NOTA', 'ADJUNTO'];
const OPERACIONES = ['CREATE', 'UPDATE', 'DELETE'];

// ---------------------------------------------------------------------------
// Manejadores por entidad: encapsulan el SQL propio de NOTA y ADJUNTO para
// que el flujo de conflictos/idempotencia sea único.
// ---------------------------------------------------------------------------

const manejadorNota = {
  async cargar(cliente, uuid) {
    const { rows } = await cliente.query('SELECT * FROM nota WHERE uuid = $1 FOR UPDATE', [uuid]);
    return rows[0] || null;
  },

  duenoDe(fila) {
    return fila.usuario_uuid;
  },

  notaUuidParaHistorial(fila, op) {
    return op.uuid; // el historial de una nota apunta a la propia nota
  },

  async crear(cliente, { usuarioUuid, deviceId, op }) {
    const { payload } = op;
    if (typeof payload.titulo !== 'string' || payload.titulo.trim().length === 0) {
      throw new AppError(400, 'VALIDACION', 'payload.titulo es obligatorio al crear una nota.');
    }
    await cliente.query(
      `INSERT INTO nota (uuid, usuario_uuid, titulo, contenido, created_at, updated_at,
                         is_deleted, version, device_id)
       VALUES ($1, $2, $3, $4, $5, $6, FALSE, $7, $8)`,
      [
        op.uuid,
        usuarioUuid,
        payload.titulo,
        payload.contenido ?? null,
        payload.created_at ?? op.updated_at,
        op.updated_at,
        op.version,
        deviceId,
      ]
    );
  },

  async aplicar(cliente, { deviceId, op, nuevaVersion, eliminar }) {
    const { payload } = op;
    await cliente.query(
      `UPDATE nota
       SET titulo = COALESCE($2, titulo),
           contenido = COALESCE($3, contenido),
           updated_at = $4,
           version = $5,
           device_id = $6,
           is_deleted = $7,
           server_updated_at = now()
       WHERE uuid = $1`,
      [op.uuid, payload.titulo ?? null, payload.contenido ?? null, op.updated_at, nuevaVersion, deviceId, eliminar]
    );
  },

  serializar(fila) {
    return {
      uuid: fila.uuid,
      titulo: fila.titulo,
      contenido: fila.contenido,
      created_at: fila.created_at.toISOString(),
      updated_at: fila.updated_at.toISOString(),
      is_deleted: fila.is_deleted,
      version: fila.version,
      device_id: fila.device_id,
    };
  },
};

const manejadorAdjunto = {
  async cargar(cliente, uuid) {
    // El dueño del adjunto es el dueño de su nota (control de acceso, sección 8).
    const { rows } = await cliente.query(
      `SELECT a.*, n.usuario_uuid
       FROM adjunto a
       JOIN nota n ON n.uuid = a.nota_uuid
       WHERE a.uuid = $1
       FOR UPDATE OF a`,
      [uuid]
    );
    return rows[0] || null;
  },

  duenoDe(fila) {
    return fila.usuario_uuid;
  },

  notaUuidParaHistorial(fila, op) {
    return fila ? fila.nota_uuid : op.payload.nota_uuid;
  },

  async crear(cliente, { usuarioUuid, deviceId, op }) {
    const { payload } = op;
    if (typeof payload.nota_uuid !== 'string' || !UUID_V4.test(payload.nota_uuid)) {
      throw new AppError(400, 'VALIDACION', 'payload.nota_uuid es obligatorio al crear un adjunto.');
    }
    const { rows } = await cliente.query('SELECT usuario_uuid FROM nota WHERE uuid = $1', [
      payload.nota_uuid,
    ]);
    if (rows.length === 0) {
      throw new AppError(404, 'NOTA_NO_ENCONTRADA', 'La nota del adjunto no existe.');
    }
    if (rows[0].usuario_uuid !== usuarioUuid) {
      throw new AppError(403, 'ACCESO_DENEGADO', 'La nota del adjunto no pertenece al usuario autenticado.');
    }
    await cliente.query(
      `INSERT INTO adjunto (uuid, nota_uuid, ruta_local, updated_at, is_deleted, version, device_id)
       VALUES ($1, $2, $3, $4, FALSE, $5, $6)`,
      [op.uuid, payload.nota_uuid, payload.ruta_local ?? null, op.updated_at, op.version, deviceId]
    );
  },

  async aplicar(cliente, { deviceId, op, nuevaVersion, eliminar }) {
    const { payload } = op;
    await cliente.query(
      `UPDATE adjunto
       SET ruta_local = COALESCE($2, ruta_local),
           updated_at = $3,
           version = $4,
           device_id = $5,
           is_deleted = $6,
           server_updated_at = now()
       WHERE uuid = $1`,
      [op.uuid, payload.ruta_local ?? null, op.updated_at, nuevaVersion, deviceId, eliminar]
    );
  },

  serializar(fila) {
    return {
      uuid: fila.uuid,
      nota_uuid: fila.nota_uuid,
      ruta_local: fila.ruta_local,
      url_remota: fila.url_remota,
      updated_at: fila.updated_at.toISOString(),
      is_deleted: fila.is_deleted,
      version: fila.version,
      device_id: fila.device_id,
    };
  },
};

const MANEJADORES = { NOTA: manejadorNota, ADJUNTO: manejadorAdjunto };

// ---------------------------------------------------------------------------
// Paso 1 del roadmap: validación de forma de cada operación.
// ---------------------------------------------------------------------------

function validarOperacion(op) {
  if (op === null || typeof op !== 'object' || Array.isArray(op)) {
    return new AppError(400, 'VALIDACION', 'La operación debe ser un objeto.');
  }
  if (typeof op.uuid !== 'string' || !UUID_V4.test(op.uuid)) {
    return new AppError(400, 'VALIDACION', 'uuid debe ser un UUID v4.');
  }
  if (!ENTIDADES.includes(op.entidad)) {
    return new AppError(400, 'VALIDACION', `entidad debe ser una de: ${ENTIDADES.join(', ')}.`);
  }
  if (!OPERACIONES.includes(op.operacion)) {
    return new AppError(400, 'VALIDACION', `operacion debe ser una de: ${OPERACIONES.join(', ')}.`);
  }
  if (op.payload === null || typeof op.payload !== 'object' || Array.isArray(op.payload)) {
    return new AppError(400, 'VALIDACION', 'payload debe ser un objeto.');
  }
  if (typeof op.updated_at !== 'string' || Number.isNaN(Date.parse(op.updated_at))) {
    return new AppError(400, 'VALIDACION', 'updated_at debe ser una fecha ISO 8601 válida.');
  }
  if (!Number.isInteger(op.version) || op.version < 1) {
    return new AppError(400, 'VALIDACION', 'version debe ser un entero >= 1.');
  }
  return null;
}

function resultadoError(op, appError) {
  return {
    uuid: typeof op?.uuid === 'string' ? op.uuid : null,
    estado: 'ERROR',
    error: { codigo: appError.codigo, mensaje: appError.message, detalle: appError.detalle },
  };
}

async function registrarHistorial(cliente, { notaUuid, tipo, origen, dispositivo, valorAnterior, valorNuevo }) {
  await cliente.query(
    `INSERT INTO historial_cambio
       (uuid, nota_uuid, tipo_cambio, origen_cambio, fecha, dispositivo_origen, valor_anterior, valor_nuevo)
     VALUES (gen_random_uuid(), $1, $2, $3, now(), $4, $5, $6)`,
    [
      notaUuid,
      tipo,
      origen,
      dispositivo,
      valorAnterior === null ? null : JSON.stringify(valorAnterior),
      valorNuevo === null ? null : JSON.stringify(valorNuevo),
    ]
  );
}

// ---------------------------------------------------------------------------
// Núcleo: aplica una operación ya validada dentro de una transacción abierta.
// Devuelve el resultado (ACCEPTED / CONFLICT) o lanza AppError (→ item ERROR).
// ---------------------------------------------------------------------------

async function aplicarOperacion(cliente, { usuarioUuid, deviceId, op }) {
  const manejador = MANEJADORES[op.entidad];
  const tipoBase = op.entidad === 'NOTA' ? op.operacion : `ADJUNTO_${op.operacion}`;
  const fila = await manejador.cargar(cliente, op.uuid);

  // Registro nuevo: solo CREATE es aplicable.
  if (!fila) {
    if (op.operacion !== 'CREATE') {
      throw new AppError(
        404,
        'REGISTRO_NO_ENCONTRADO',
        `No existe ${op.entidad} con ese uuid para aplicar ${op.operacion}.`
      );
    }
    await manejador.crear(cliente, { usuarioUuid, deviceId, op });
    await registrarHistorial(cliente, {
      notaUuid: manejador.notaUuidParaHistorial(null, op),
      tipo: tipoBase,
      origen: 'LOCAL',
      dispositivo: deviceId,
      valorAnterior: null,
      valorNuevo: op.payload,
    });
    return { uuid: op.uuid, estado: 'ACCEPTED', version_servidor: op.version };
  }

  // Paso 1 del roadmap: control de acceso por usuario_uuid (sección 8).
  if (manejador.duenoDe(fila) !== usuarioUuid) {
    throw new AppError(403, 'ACCESO_DENEGADO', 'El registro no pertenece al usuario autenticado.');
  }

  const notaUuid = manejador.notaUuidParaHistorial(fila, op);
  const eliminar = op.operacion === 'DELETE' ? true : fila.is_deleted;

  // Paso 3: sin edición concurrente → aplicar e incrementar versión autoritativa.
  if (op.operacion !== 'CREATE' && fila.version === op.version) {
    const nuevaVersion = fila.version + 1;
    await manejador.aplicar(cliente, { deviceId, op, nuevaVersion, eliminar });
    await registrarHistorial(cliente, {
      notaUuid,
      tipo: tipoBase,
      origen: 'LOCAL',
      dispositivo: deviceId,
      valorAnterior: manejador.serializar(fila),
      valorNuevo: op.operacion === 'DELETE' ? null : op.payload,
    });
    return { uuid: op.uuid, estado: 'ACCEPTED', version_servidor: nuevaVersion };
  }

  // Paso 4: edición concurrente → Last-Write-Wins por updated_at (sección 5.3).
  const updatedCliente = new Date(op.updated_at).getTime();
  const updatedServidor = new Date(fila.updated_at).getTime();

  if (updatedCliente > updatedServidor) {
    // Gana el cliente: se aplica su cambio y el estado del servidor que se
    // descarta queda en el historial (valor_nuevo = lo NO aplicado, openapi.yaml).
    const nuevaVersion = fila.version + 1;
    await manejador.aplicar(cliente, { deviceId, op, nuevaVersion, eliminar });
    await registrarHistorial(cliente, {
      notaUuid,
      tipo: tipoBase,
      origen: 'CONFLICTO_DESCARTADO',
      dispositivo: fila.device_id,
      valorAnterior: op.payload,
      valorNuevo: manejador.serializar(fila),
    });
    await registrarHistorial(cliente, {
      notaUuid,
      tipo: tipoBase,
      origen: 'LOCAL',
      dispositivo: deviceId,
      valorAnterior: manejador.serializar(fila),
      valorNuevo: op.operacion === 'DELETE' ? null : op.payload,
    });
    return { uuid: op.uuid, estado: 'ACCEPTED', version_servidor: nuevaVersion };
  }

  // Gana el servidor: el cambio del cliente se descarta y se devuelve el
  // estado autoritativo para la resolución local (sección 5.3).
  await registrarHistorial(cliente, {
    notaUuid,
    tipo: tipoBase,
    origen: 'CONFLICTO_DESCARTADO',
    dispositivo: deviceId,
    valorAnterior: manejador.serializar(fila),
    valorNuevo: op.payload,
  });
  return {
    uuid: op.uuid,
    estado: 'CONFLICT',
    version_servidor: fila.version,
    payload_servidor: manejador.serializar(fila),
  };
}

// ---------------------------------------------------------------------------
// Paso 7: cada operación en su propia transacción; paso 2: idempotencia.
// ---------------------------------------------------------------------------

async function procesarOperacion({ usuarioUuid, deviceId, op }) {
  const errorValidacion = validarOperacion(op);
  if (errorValidacion) return resultadoError(op, errorValidacion);

  const cliente = await pool.connect();
  try {
    await cliente.query('BEGIN');

    // Paso 2: operación ya procesada → resultado original, sin re-aplicar.
    const previa = await cliente.query(
      `SELECT resultado FROM operacion_procesada
       WHERE uuid = $1 AND version = $2 AND operacion = $3 AND device_id = $4`,
      [op.uuid, op.version, op.operacion, deviceId]
    );
    if (previa.rows.length > 0) {
      await cliente.query('ROLLBACK');
      return previa.rows[0].resultado;
    }

    const resultado = await aplicarOperacion(cliente, { usuarioUuid, deviceId, op });

    await cliente.query(
      `INSERT INTO operacion_procesada (uuid, version, operacion, device_id, resultado)
       VALUES ($1, $2, $3, $4, $5)`,
      [op.uuid, op.version, op.operacion, deviceId, JSON.stringify(resultado)]
    );

    await cliente.query('COMMIT');
    return resultado;
  } catch (err) {
    await cliente.query('ROLLBACK');

    // Carrera entre dos lotes con la misma clave: la PK de operacion_procesada
    // frena al segundo; se devuelve el resultado que ganó la carrera.
    if (err.code === '23505' && err.constraint === 'operacion_procesada_pkey') {
      const { rows } = await pool.query(
        `SELECT resultado FROM operacion_procesada
         WHERE uuid = $1 AND version = $2 AND operacion = $3 AND device_id = $4`,
        [op.uuid, op.version, op.operacion, deviceId]
      );
      if (rows.length > 0) return rows[0].resultado;
    }

    if (err instanceof AppError) return resultadoError(op, err);

    console.error(`Error procesando operación ${op.uuid}:`, err);
    return resultadoError(
      op,
      new AppError(500, 'ERROR_INTERNO', 'Error interno al procesar la operación.')
    );
  } finally {
    cliente.release();
  }
}

/**
 * Procesa el lote en orden y devuelve los resultados en el mismo orden.
 * Paso 6: 200 sin conflictos, 409 si al menos un item quedó en CONFLICT.
 */
async function procesarLote({ usuarioUuid, deviceId, operaciones }) {
  const resultados = [];
  for (const op of operaciones) {
    // Secuencial a propósito: el lote viene en el orden en que se generó
    // localmente (CREATE antes que UPDATE del mismo registro, etc.).
    resultados.push(await procesarOperacion({ usuarioUuid, deviceId, op }));
  }

  const hayConflicto = resultados.some((r) => r.estado === 'CONFLICT');
  return { httpStatus: hayConflicto ? 409 : 200, resultados };
}

// ---------------------------------------------------------------------------
// GET /sync/pull (tarea 1.4): cambios del usuario posteriores a `desde`.
// ---------------------------------------------------------------------------

/**
 * El corte usa `server_updated_at` (reloj del servidor, asignado al aceptar
 * cada cambio), no el `updated_at` del cliente: los relojes de los
 * dispositivos no son comparables entre sí y solo sirven para LWW.
 *
 * `timestamp_servidor` de la respuesta es el cursor de la siguiente consulta:
 * el `server_updated_at` del último cambio devuelto (o el mismo `desde` si no
 * hubo cambios). Con él la paginación es estable aunque lleguen cambios
 * nuevos entre página y página. Limitación conocida y aceptada: una
 * transacción de push que quede abierta durante un pull podría comitear un
 * cambio con marca anterior al cursor ya entregado; como cada operación de
 * push es una transacción de milisegundos, la ventana es despreciable para
 * este caso de uso.
 */
async function obtenerCambios({ usuarioUuid, desde, deviceId, limite }) {
  // Se pide limite + 1 para saber si hay más páginas sin una consulta extra.
  const tope = limite + 1;

  // El cursor se serializa en SQL con to_char para conservar los
  // MICROSEGUNDOS de timestamptz: convertirlo a Date de JS lo truncaría a
  // milisegundos, quedaría apenas antes del último cambio entregado y ese
  // cambio se re-entregaría en la página siguiente.
  const CURSOR_SQL = `to_char(%c AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"')`;

  // El filtro anti-eco usa IS DISTINCT FROM para no excluir filas con
  // device_id NULL cuando sí se envía device_id.
  const { rows: notas } = await pool.query(
    `SELECT uuid, titulo, contenido, created_at, updated_at, is_deleted, version,
            device_id, ${CURSOR_SQL.replace('%c', 'server_updated_at')} AS cursor
     FROM nota
     WHERE usuario_uuid = $1
       AND server_updated_at > $2::timestamptz
       AND ($3::text IS NULL OR device_id IS DISTINCT FROM $3)
     ORDER BY server_updated_at
     LIMIT $4`,
    [usuarioUuid, desde, deviceId, tope]
  );

  const { rows: adjuntos } = await pool.query(
    `SELECT a.uuid, a.nota_uuid, a.ruta_local, a.url_remota, a.updated_at,
            a.is_deleted, a.version, a.device_id,
            ${CURSOR_SQL.replace('%c', 'a.server_updated_at')} AS cursor
     FROM adjunto a
     JOIN nota n ON n.uuid = a.nota_uuid
     WHERE n.usuario_uuid = $1
       AND a.server_updated_at > $2::timestamptz
       AND ($3::text IS NULL OR a.device_id IS DISTINCT FROM $3)
     ORDER BY a.server_updated_at
     LIMIT $4`,
    [usuarioUuid, desde, deviceId, tope]
  );

  const aCambio = (fila, entidad) => ({
    uuid: fila.uuid,
    entidad,
    // La operación se deriva del estado autoritativo: el cliente solo
    // necesita saber qué aplicar, no la secuencia exacta de operaciones.
    operacion: fila.is_deleted ? 'DELETE' : fila.version === 1 ? 'CREATE' : 'UPDATE',
    payload: fila.is_deleted
      ? {} // tombstone: se identifica por uuid + operacion (sección 5.4)
      : entidad === 'NOTA'
        ? {
            titulo: fila.titulo,
            contenido: fila.contenido,
            created_at: fila.created_at.toISOString(),
          }
        : {
            nota_uuid: fila.nota_uuid,
            ruta_local: fila.ruta_local,
            url_remota: fila.url_remota,
          },
    version: fila.version,
    updated_at: fila.updated_at.toISOString(),
    is_deleted: fila.is_deleted,
    device_id: fila.device_id,
    cursor: fila.cursor, // interno; se quita antes de responder
  });

  // El formato del cursor es de ancho fijo en UTC: la comparación
  // lexicográfica equivale a la cronológica.
  const combinados = [
    ...notas.map((f) => aCambio(f, 'NOTA')),
    ...adjuntos.map((f) => aCambio(f, 'ADJUNTO')),
  ].sort((a, b) => a.cursor.localeCompare(b.cursor) || a.uuid.localeCompare(b.uuid));

  const hayMas = combinados.length > limite;
  const pagina = combinados.slice(0, limite);

  // Sin cambios se devuelve el mismo `desde`: normalizarlo a Date también
  // perdería microsegundos y haría retroceder el cursor del cliente.
  const timestampServidor = pagina.length > 0 ? pagina[pagina.length - 1].cursor : desde;

  return {
    cambios: pagina.map(({ cursor, ...cambio }) => cambio),
    timestamp_servidor: timestampServidor,
    hay_mas: hayMas,
  };
}

module.exports = { procesarLote, obtenerCambios };

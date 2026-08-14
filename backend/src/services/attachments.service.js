const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const pool = require('../db/pool');
const env = require('../config/env');
const AppError = require('../utils/app-error');

/**
 * Adjuntos (tarea 1.5, RNF-05): el binario viaja FUERA del lote de
 * sincronización — /sync/push solo mueve los metadatos de la entidad
 * ADJUNTO; este servicio recibe y entrega el archivo físico.
 *
 * El binario se guarda en disco como uploads/<uuid> (sin extensión; el
 * nombre lo da el uuid del cliente) y en la BD solo quedan metadatos:
 * hash SHA-256 (idempotencia), tamaño y MIME.
 */

fs.mkdirSync(env.uploadsDir, { recursive: true });

function rutaBinario(uuid) {
  return path.join(env.uploadsDir, uuid);
}

function urlRemota(uuid) {
  // URI relativa al servidor declarado en openapi.yaml; el cliente la
  // resuelve contra su baseUrl (evita fijar host/protocolo del PaaS en la BD).
  return `/v1/attachments/${uuid}`;
}

function serializarAdjunto(fila) {
  // Esquema Adjunto de openapi.yaml.
  return {
    uuid: fila.uuid,
    nota_uuid: fila.nota_uuid,
    ruta_local: fila.ruta_local,
    url_remota: fila.url_remota,
    is_deleted: fila.is_deleted,
    version: fila.version,
    updated_at: fila.updated_at.toISOString(),
  };
}

async function cargarConDueno(cliente, uuid) {
  const { rows } = await cliente.query(
    `SELECT a.*, n.usuario_uuid
     FROM adjunto a
     JOIN nota n ON n.uuid = a.nota_uuid
     WHERE a.uuid = $1
     FOR UPDATE OF a`,
    [uuid]
  );
  return rows[0] || null;
}

/**
 * POST /attachments — sube el binario. Casos del contrato:
 * - Adjunto nuevo: crea el registro de metadatos y guarda el binario (201).
 *   (Tolera subir el binario antes de sincronizar los metadatos por push.)
 * - Reintento con el MISMO contenido (hash igual): 201 idempotente.
 * - Mismo uuid con contenido DISTINTO: 409 (violación de idempotencia).
 * - Nota inexistente o ajena: 404.
 * - El límite de 10 MB (413) lo aplica multer antes de llegar aquí.
 */
async function subirAdjunto({ usuarioUuid, uuid, notaUuid, deviceId, archivo }) {
  const hash = crypto.createHash('sha256').update(archivo.buffer).digest('hex');

  const cliente = await pool.connect();
  try {
    await cliente.query('BEGIN');

    let fila = await cargarConDueno(cliente, uuid);

    if (fila && fila.usuario_uuid !== usuarioUuid) {
      // Mismo 404 que "no existe" para no revelar uuids ajenos.
      throw new AppError(404, 'NOTA_NO_ENCONTRADA', 'La nota referenciada no existe o no pertenece al usuario autenticado.');
    }
    if (fila && fila.is_deleted) {
      throw new AppError(404, 'ADJUNTO_ELIMINADO', 'El adjunto fue eliminado (tombstone); no admite nuevas subidas.');
    }

    if (!fila) {
      // Metadatos aún no sincronizados: el endpoint crea el registro.
      const { rows } = await cliente.query(
        'SELECT usuario_uuid, is_deleted FROM nota WHERE uuid = $1',
        [notaUuid]
      );
      if (rows.length === 0 || rows[0].usuario_uuid !== usuarioUuid || rows[0].is_deleted) {
        throw new AppError(404, 'NOTA_NO_ENCONTRADA', 'La nota referenciada no existe o no pertenece al usuario autenticado.');
      }
      await cliente.query(
        `INSERT INTO adjunto (uuid, nota_uuid, url_remota, updated_at, is_deleted, version,
                              device_id, contenido_sha256, tamano_bytes, mime_type)
         VALUES ($1, $2, $3, now(), FALSE, 1, $4, $5, $6, $7)`,
        [uuid, notaUuid, urlRemota(uuid), deviceId, hash, archivo.buffer.length, archivo.mimetype]
      );
      await cliente.query(
        `INSERT INTO historial_cambio
           (uuid, nota_uuid, tipo_cambio, origen_cambio, fecha, dispositivo_origen, valor_anterior, valor_nuevo)
         VALUES (gen_random_uuid(), $1, 'ADJUNTO_CREATE', 'LOCAL', now(), $2, NULL, $3)`,
        [notaUuid, deviceId, JSON.stringify({ uuid, tamano_bytes: archivo.buffer.length })]
      );
    } else if (fila.contenido_sha256 === null) {
      // Metadatos ya sincronizados por push; primer binario para el registro.
      await cliente.query(
        `UPDATE adjunto
         SET url_remota = $2, contenido_sha256 = $3, tamano_bytes = $4, mime_type = $5,
             server_updated_at = now()
         WHERE uuid = $1`,
        [uuid, urlRemota(uuid), hash, archivo.buffer.length, archivo.mimetype]
      );
    } else if (fila.contenido_sha256 !== hash) {
      throw new AppError(
        409,
        'ADJUNTO_CONTENIDO_DISTINTO',
        'Ya existe un adjunto con ese uuid y contenido distinto (violación de idempotencia).'
      );
    }
    // hash idéntico → reintento: no se reescribe nada, respuesta idempotente.

    // El binario se escribe antes del COMMIT: si el disco falla, la
    // transacción se revierte y no quedan metadatos apuntando a la nada.
    await fs.promises.writeFile(rutaBinario(uuid), archivo.buffer);

    await cliente.query('COMMIT');
  } catch (err) {
    await cliente.query('ROLLBACK');
    throw err;
  } finally {
    cliente.release();
  }

  const { rows } = await pool.query('SELECT * FROM adjunto WHERE uuid = $1', [uuid]);
  return serializarAdjunto(rows[0]);
}

/**
 * GET /attachments/{uuid} — entrega el binario. 404 si no existe, no es del
 * usuario o aún no tiene binario; 410 si es un tombstone (sección 5.4).
 */
async function obtenerBinario({ usuarioUuid, uuid }) {
  const { rows } = await pool.query(
    `SELECT a.uuid, a.is_deleted, a.contenido_sha256, a.mime_type, n.usuario_uuid
     FROM adjunto a
     JOIN nota n ON n.uuid = a.nota_uuid
     WHERE a.uuid = $1`,
    [uuid]
  );
  const fila = rows[0];

  if (!fila || fila.usuario_uuid !== usuarioUuid) {
    throw new AppError(404, 'ADJUNTO_NO_ENCONTRADO', 'El adjunto no existe o no pertenece al usuario autenticado.');
  }
  if (fila.is_deleted) {
    throw new AppError(410, 'ADJUNTO_ELIMINADO', 'El adjunto fue eliminado y su binario ya no está disponible.');
  }
  if (fila.contenido_sha256 === null) {
    throw new AppError(404, 'BINARIO_NO_DISPONIBLE', 'Los metadatos existen pero el binario aún no fue subido.');
  }

  return { ruta: rutaBinario(uuid) };
}

/**
 * DELETE /attachments/{uuid} — soft delete (tombstone): incrementa la
 * versión y toca server_updated_at para que la eliminación se propague a
 * los demás dispositivos vía /sync/pull. Idempotente. La purga física del
 * binario queda para la ventana de gracia (fase 3.5 del roadmap).
 */
async function eliminarAdjunto({ usuarioUuid, uuid }) {
  const cliente = await pool.connect();
  try {
    await cliente.query('BEGIN');

    const fila = await cargarConDueno(cliente, uuid);
    if (!fila || fila.usuario_uuid !== usuarioUuid) {
      throw new AppError(404, 'ADJUNTO_NO_ENCONTRADO', 'El adjunto no existe o no pertenece al usuario autenticado.');
    }

    if (!fila.is_deleted) {
      await cliente.query(
        `UPDATE adjunto
         SET is_deleted = TRUE, version = version + 1, updated_at = now(),
             server_updated_at = now()
         WHERE uuid = $1`,
        [uuid]
      );
      await cliente.query(
        `INSERT INTO historial_cambio
           (uuid, nota_uuid, tipo_cambio, origen_cambio, fecha, dispositivo_origen, valor_anterior, valor_nuevo)
         VALUES (gen_random_uuid(), $1, 'ADJUNTO_DELETE', 'LOCAL', now(), $2, $3, NULL)`,
        [fila.nota_uuid, fila.device_id, JSON.stringify({ uuid })]
      );
    }

    await cliente.query('COMMIT');
  } catch (err) {
    await cliente.query('ROLLBACK');
    throw err;
  } finally {
    cliente.release();
  }
}

module.exports = { subirAdjunto, obtenerBinario, eliminarAdjunto };

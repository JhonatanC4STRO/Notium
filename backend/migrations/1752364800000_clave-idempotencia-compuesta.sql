-- Up Migration
-- Corrección a la sección 6.3: la clave (uuid, version) a secas colisiona.
-- Un CREATE aceptado queda registrado con (uuid, 1) y la siguiente edición
-- legítima parte de la versión base 1, por lo que el UPDATE llega también
-- con (uuid, 1) y se confundiría con un reintento del CREATE. Lo mismo pasa
-- con ediciones concurrentes desde otro dispositivo con la misma versión base.
--
-- La clave real de un reintento es "la misma operación desde el mismo
-- dispositivo": se amplía la PK a (uuid, version, operacion, device_id).
-- Documentar esta desviación en doc.md v1.5 (tarea 5.3 del roadmap).

ALTER TABLE operacion_procesada
    ADD COLUMN operacion TEXT NOT NULL DEFAULT 'CREATE',
    ADD COLUMN device_id TEXT NOT NULL DEFAULT '';

ALTER TABLE operacion_procesada ALTER COLUMN operacion DROP DEFAULT;
ALTER TABLE operacion_procesada ALTER COLUMN device_id DROP DEFAULT;

ALTER TABLE operacion_procesada DROP CONSTRAINT operacion_procesada_pkey;
ALTER TABLE operacion_procesada
    ADD CONSTRAINT operacion_procesada_pkey
    PRIMARY KEY (uuid, version, operacion, device_id);

-- Down Migration
ALTER TABLE operacion_procesada DROP CONSTRAINT operacion_procesada_pkey;
ALTER TABLE operacion_procesada DROP COLUMN operacion;
ALTER TABLE operacion_procesada DROP COLUMN device_id;
ALTER TABLE operacion_procesada ADD CONSTRAINT operacion_procesada_pkey PRIMARY KEY (uuid, version);

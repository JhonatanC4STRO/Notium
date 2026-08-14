-- Up Migration
-- Soporte del binario de los adjuntos (tarea 1.5, RNF-05):
-- - contenido_sha256 detecta la "violación de idempotencia" del contrato:
--   reintento con el mismo contenido → 201 idempotente; mismo uuid con
--   contenido distinto → 409.
-- - El binario se guarda en disco (uploads/<uuid>); en la BD solo metadatos.

ALTER TABLE adjunto
    ADD COLUMN contenido_sha256 TEXT,
    ADD COLUMN tamano_bytes BIGINT,
    ADD COLUMN mime_type TEXT;

-- Down Migration
ALTER TABLE adjunto DROP COLUMN contenido_sha256;
ALTER TABLE adjunto DROP COLUMN tamano_bytes;
ALTER TABLE adjunto DROP COLUMN mime_type;

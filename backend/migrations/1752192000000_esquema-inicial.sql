-- Up Migration
-- Esquema autoritativo de Notium (secciones 4.1, 4.2 y 6.3 del doc de arquitectura).
-- Los uuid los genera el cliente (UUID v4, sección 5.1); el servidor solo los acepta.
-- sync_status NO se persiste aquí: es un metadato local del cliente (openapi.yaml).

CREATE TABLE usuario (
    uuid            UUID PRIMARY KEY,
    nombre          TEXT NOT NULL,
    email           TEXT NOT NULL UNIQUE,
    contrasena_hash TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE nota (
    uuid              UUID PRIMARY KEY,
    usuario_uuid      UUID NOT NULL REFERENCES usuario (uuid),
    titulo            TEXT NOT NULL,
    contenido         TEXT,
    created_at        TIMESTAMPTZ NOT NULL,
    updated_at        TIMESTAMPTZ NOT NULL,
    is_deleted        BOOLEAN NOT NULL DEFAULT FALSE,
    version           INTEGER NOT NULL DEFAULT 1,
    device_id         TEXT,
    -- Marca temporal asignada por el servidor al aceptar el cambio; es el corte
    -- del parámetro `desde` de GET /sync/pull (no sirve updated_at, que es del
    -- reloj del cliente y base de LWW — tarea 1.4 del roadmap).
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_nota_usuario ON nota (usuario_uuid);
CREATE INDEX idx_nota_pull ON nota (usuario_uuid, server_updated_at);

CREATE TABLE adjunto (
    uuid              UUID PRIMARY KEY,
    nota_uuid         UUID NOT NULL REFERENCES nota (uuid),
    ruta_local        TEXT,
    url_remota        TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL,
    is_deleted        BOOLEAN NOT NULL DEFAULT FALSE,
    version           INTEGER NOT NULL DEFAULT 1,
    device_id         TEXT,
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_adjunto_nota ON adjunto (nota_uuid);
CREATE INDEX idx_adjunto_pull ON adjunto (nota_uuid, server_updated_at);

CREATE TABLE historial_cambio (
    uuid                UUID PRIMARY KEY,
    nota_uuid           UUID NOT NULL REFERENCES nota (uuid),
    tipo_cambio         TEXT NOT NULL,
    origen_cambio       TEXT NOT NULL
                        CHECK (origen_cambio IN ('LOCAL', 'REMOTO', 'CONFLICTO_DESCARTADO')),
    fecha               TIMESTAMPTZ NOT NULL,
    dispositivo_origen  TEXT,
    valor_anterior      TEXT,
    valor_nuevo         TEXT
);

CREATE INDEX idx_historial_nota_fecha ON historial_cambio (nota_uuid, fecha DESC);

-- Clave de idempotencia (uuid, version) de POST /sync/push (secciones 5.5 y 6.3):
-- un reintento con la misma clave devuelve `resultado` sin re-aplicar la operación.
CREATE TABLE operacion_procesada (
    uuid         UUID NOT NULL,
    version      INTEGER NOT NULL,
    resultado    JSONB NOT NULL,
    procesada_en TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (uuid, version)
);

-- Down Migration
DROP TABLE operacion_procesada;
DROP TABLE historial_cambio;
DROP TABLE adjunto;
DROP TABLE nota;
DROP TABLE usuario;

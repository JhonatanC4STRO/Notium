-- Up Migration
-- Persistencia de refresh tokens (tarea 1.2 del roadmap, sección 8 del doc):
-- se guarda solo el hash SHA-256 del token, nunca el token en claro, de modo
-- que un volcado de la BD no permita suplantar sesiones. El logout marca
-- revocado_en (mitigación de dispositivo robado, sección 9) y el refresh
-- rota el token: revoca el usado y persiste el nuevo.

CREATE TABLE refresh_token (
    token_hash   TEXT PRIMARY KEY,
    usuario_uuid UUID NOT NULL REFERENCES usuario (uuid),
    emitido_en   TIMESTAMPTZ NOT NULL DEFAULT now(),
    expira_en    TIMESTAMPTZ NOT NULL,
    revocado_en  TIMESTAMPTZ
);

CREATE INDEX idx_refresh_token_usuario ON refresh_token (usuario_uuid);

-- Down Migration
DROP TABLE refresh_token;

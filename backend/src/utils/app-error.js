/**
 * Error de negocio con mapeo directo al esquema `Error` de openapi.yaml.
 * Los services lo lanzan y el manejador de errores lo serializa.
 */
class AppError extends Error {
  constructor(httpStatus, codigo, mensaje, detalle = null) {
    super(mensaje);
    this.httpStatus = httpStatus;
    this.codigo = codigo;
    this.detalle = detalle;
  }
}

module.exports = AppError;

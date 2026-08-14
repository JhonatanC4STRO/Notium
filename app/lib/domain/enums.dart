/// Enums del modelo de datos (secciones 4.2 y 5.3 del doc de arquitectura).
///
/// Los nombres de los valores coinciden EXACTAMENTE con los del contrato
/// `openapi.yaml`: Drift los persiste por nombre (`textEnum`) y la capa de
/// sincronización (fase 3) los serializa tal cual hacia la API. Por eso se
/// mantienen en mayúsculas aunque no sigan lowerCamelCase.
library;

// ignore_for_file: constant_identifier_names

/// Estado de sincronización de un registro (sección 4.2). Determina qué
/// registros procesa la `SyncTask` y qué indicador muestra la UI (RF-04).
enum SyncStatus { PENDING, SYNCED, CONFLICT, ERROR }

/// Origen de una entrada del historial de auditoría (secciones 4.1 y 5.3).
enum OrigenCambio { LOCAL, REMOTO, CONFLICTO_DESCARTADO }

/// Tipo de operación pendiente de sincronizar (sección 5.5).
enum Operacion { CREATE, UPDATE, DELETE }

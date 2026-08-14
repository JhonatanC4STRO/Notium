# Notium — contenido para el portafolio

## Resumen corto

Aplicacion Android de notas offline-first que funciona sin conexion y
sincroniza automaticamente los cambios entre dispositivos cuando la red vuelve.

## Descripcion del proyecto

Notium nacio para resolver un problema frecuente en aplicaciones moviles: la
perdida de funcionalidad cuando la conexion es inestable. La interfaz trabaja
siempre contra una base de datos local cifrada, por lo que crear, editar,
eliminar y consultar notas no depende de internet.

Al recuperar la conexion, una tarea en segundo plano envia los cambios al
servidor y descarga las actualizaciones de otros dispositivos. Los conflictos
se resuelven de forma determinista y el valor descartado queda disponible en un
historial de auditoria.

## Funciones destacadas

- Creacion y edicion de notas completamente offline.
- Adjuntos de hasta 10 MB con cache local.
- Base de datos cifrada con SQLCipher.
- Sincronizacion automatica en segundo plano.
- Resolucion y trazabilidad de conflictos entre dispositivos.
- Eliminacion propagada mediante tombstones y purga posterior.
- Sesion segura con access/refresh tokens y almacenamiento en Android Keystore.
- Indicadores visuales de estado: pendiente, sincronizado, conflicto y error.

## Tecnologias

Flutter, Dart, Riverpod, Drift, SQLCipher, Dio, WorkManager, Node.js, Express,
PostgreSQL, Docker, Caddy, JWT y OpenAPI.

## Mi aporte

Disene e implemente la arquitectura completa del cliente y el servidor: modelo
offline-first, persistencia cifrada, API REST, autenticacion, sincronizacion,
resolucion de conflictos, adjuntos, despliegue y pruebas automatizadas.

## Botones sugeridos

1. **Probar en el navegador** — enlace de Appetize.
2. **Descargar APK** — enlace al APK firmado en GitHub Releases.
3. **Ver codigo** — repositorio publico.
4. **Ver arquitectura** — `doc/doc.md` o una pagina del portafolio.

## Guion para un video de 45 segundos

1. Abrir Notium e iniciar sesion.
2. Activar modo avion y crear una nota con un adjunto.
3. Cerrar y volver a abrir la aplicacion para demostrar persistencia offline.
4. Recuperar la red y mostrar el indicador de sincronizacion.
5. Abrir el historial de cambios y explicar brevemente la resolucion de conflictos.

## Capturas recomendadas

- Inicio de sesion/registro.
- Lista de notas con estados de sincronizacion.
- Editor de nota con un adjunto.
- Uso offline o aviso de sesion por renovar.
- Historial local y del servidor.
- Conflicto descartado resaltado.

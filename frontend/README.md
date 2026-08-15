# Notium — landing del proyecto

Sitio público de presentación de Notium. Explica el enfoque offline-first,
visualiza la arquitectura, documenta el stack y enlaza el repositorio y la API.

## Desarrollo

```bash
npm install
npm run dev
```

## Producción

```bash
npm run build
npm run start
```

El `Dockerfile` usa la salida standalone de Vinext y sirve el sitio en el
puerto `3000`. En Dokploy, el dominio principal debe apuntar al servicio
`frontend` y el subdominio de API al servicio `api`.

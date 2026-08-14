FROM node:20-alpine

WORKDIR /app

# Solo dependencias de producción (node-pg-migrate es dependencia normal:
# las migraciones se aplican dentro del contenedor al desplegar).
COPY package*.json ./
RUN npm ci --omit=dev

COPY src ./src
COPY migrations ./migrations

ENV NODE_ENV=production
EXPOSE 3000

# Las migraciones se aplican en el arranque (idempotente: solo las pendientes).
CMD ["sh", "-c", "npm run migrate && node src/server.js"]

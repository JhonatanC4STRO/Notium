FROM node:22-bookworm-slim AS dependencies

WORKDIR /app
COPY package*.json ./
# Vite 8 uses a native Rolldown binary. Keeping optional dependencies enabled
# and using glibc avoids Alpine/musl binding failures on VPS build hosts.
RUN npm ci --include=optional

FROM dependencies AS builder

COPY . .
RUN npm run build

FROM node:22-bookworm-slim AS runner

WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000

COPY package*.json ./
RUN npm ci --omit=dev
COPY --from=builder /app/dist/standalone ./

EXPOSE 3000
CMD ["node", "server.js"]

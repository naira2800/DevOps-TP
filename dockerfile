# -------- Base para build --------
FROM node:22-alpine AS build
WORKDIR /app

# Toolchain para módulos nativos
RUN apk add --no-cache python3 make g++ curl

COPY package*.json ./

# Instalamos dependencias (Sentry ya viene incluido en tu package.json)
RUN npm ci --only=production

COPY . .

# -------- Imagen final --------
FROM node:22-alpine AS prod
WORKDIR /app

# Crear usuario no root y grupo
RUN addgroup -S nodejs && adduser -S nodeuser -G nodejs

# Copiamos todo desde la etapa de build
COPY --from=build /app /app

# --------------------------------------------------
# 🔑 PERMISOS Y CARPETAS
# --------------------------------------------------
RUN mkdir -p /app/logs /data \
    && chown -R nodeuser:nodejs /app/logs /data \
    && chmod 700 /data

# --------------------------------------------------
# 🌐 VARIABLES DE ENTORNO Y SENTRY
# --------------------------------------------------
ENV NODE_ENV=production
ENV PORT=3000
ENV DB_URL=/data/data.sqlite

# 1. Declaramos los argumentos que vienen de GitHub Actions
ARG SENTRY_DSN
ARG RELEASE_VERSION

# 2. Los convertimos en ENV para que Node.js pueda leerlos
ENV SENTRY_DSN=${SENTRY_DSN}
ENV SENTRY_RELEASE=${RELEASE_VERSION}

# Puerto
EXPOSE 3000

# Healthcheck
RUN apk add --no-cache curl
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:${PORT}/items || exit 1

# Cambiar a usuario no root
USER nodeuser

# Comando de inicio
CMD ["node", "server.js"]

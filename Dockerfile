# ----------------------------------------------------
# 1. Base image s Corepack / pnpm
# ----------------------------------------------------
FROM node:24-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable && corepack prepare pnpm@11.25.0 --activate
WORKDIR /app

# ----------------------------------------------------
# 2. Závislosti & Build
# ----------------------------------------------------
FROM base AS build
# Pokud klonujete z gitu uvnitř kontejneru, odkomentujte následující řádek:
# RUN apk add --no-cache git git-lfs && git lfs install

COPY pnpm-lock.yaml package.json ./
RUN pnpm install --frozen-lockfile

COPY . .
RUN pnpm build

# ----------------------------------------------------
# 3. Produkční Runtime (minimální velikost)
# ----------------------------------------------------
FROM base AS prod
ENV NODE_ENV=production

# Zkopírování z buildu (nebo nasazení built klienta a serveru)
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist 2>/dev/null || true
COPY --from=build /app .

# Porty: 5173 (Vite dev) / 4179 (Prod preview) / 2567 (Colyseus server)
EXPOSE 4179 2567

# Spuštění produkčního preview / serveru (upravte podle package.json skriptu)
CMD ["pnpm", "preview", "--host", "0.0.0.0", "--port", "4179"]

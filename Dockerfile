FROM node:24-alpine

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
ENV CI=true

# Aktivace přesné verze pnpm podle package.json
RUN corepack enable && corepack prepare pnpm@11.25.0 --activate

WORKDIR /app

# 1. Zkopírování celého projektu (včetně konfigurace pro patchedDependencies)
COPY . .

# 2. Instalace všech závislostí (včetně devDependencies pro vite, tsx a concurrently)
RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --frozen-lockfile || pnpm install --no-frozen-lockfile

# 3. Kontrola typů a produkční build frontendu do složky dist/
RUN pnpm build

# Vite preview naslouchá na 4179 a uvnitř kontejneru proxuje /api a /realtime na 2567
EXPOSE 4179

# 4. Současné spuštění Colyseus backendu a sestaveného frontendu na 0.0.0.0:4179
CMD ["pnpm", "exec", "concurrently", "-k", "-n", "SERVER,CLIENT", "tsx server/index.ts", "vite preview --host 0.0.0.0 --port 4179"]

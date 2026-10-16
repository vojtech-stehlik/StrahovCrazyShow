FROM node:24-alpine

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
ENV CI=true
ENV NODE_ENV=production

# Aktivace pnpm 11.25.0 přes vestavěný Corepack
RUN corepack enable && corepack prepare pnpm@11.25.0 --activate

WORKDIR /app

# Zkopírujeme celý projekt před instalací, aby pnpm vidělo
# pnpm-workspace.yaml, .npmrc i složku patches/
COPY . .

# Instalace s BuildKit cache a pojistkou pro případ nesouladu v lockfilu
RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --frozen-lockfile || pnpm install --no-frozen-lockfile

# Sestavení produkční verze
RUN pnpm build

# Porty: 4179 (Vite preview), 5173 (Vite dev), 2567 (Colyseus API/Realtime)
EXPOSE 4179 2567

# Spuštění (přepínač --host 0.0.0.0 je v Dockeru/Coolify nutný,
# jinak aplikace poslouchá jen na 127.0.0.1 uvnitř kontejneru)
CMD ["pnpm", "preview", "--host", "0.0.0.0", "--port", "4179"]

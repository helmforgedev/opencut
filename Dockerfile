# syntax=docker/dockerfile:1.7

# SPDX-License-Identifier: Apache-2.0
ARG BUN_VERSION=1.2.18
ARG OPENCUT_VERSION=v0.3.0

FROM docker.io/oven/bun:${BUN_VERSION}-alpine AS build

ARG OPENCUT_VERSION
ARG FREESOUND_CLIENT_ID
ARG FREESOUND_API_KEY
ARG NEXT_PUBLIC_MARBLE_API_URL=https://api.marblecms.com
ARG MARBLE_WORKSPACE_KEY=build-placeholder

RUN apk add --no-cache ca-certificates git nodejs npm

WORKDIR /src
RUN git clone --depth 1 --branch "${OPENCUT_VERSION}" https://github.com/OpenCut-app/OpenCut.git .

RUN bun install

ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    DATABASE_URL=postgresql://opencut:opencut@localhost:5432/opencut \
    BETTER_AUTH_SECRET=build-time-secret \
    UPSTASH_REDIS_REST_URL=http://localhost:8079 \
    UPSTASH_REDIS_REST_TOKEN=example_token \
    NEXT_PUBLIC_SITE_URL=http://localhost:3000 \
    NEXT_PUBLIC_MARBLE_API_URL=${NEXT_PUBLIC_MARBLE_API_URL} \
    MARBLE_WORKSPACE_KEY=${MARBLE_WORKSPACE_KEY} \
    FREESOUND_CLIENT_ID=${FREESOUND_CLIENT_ID} \
    FREESOUND_API_KEY=${FREESOUND_API_KEY}

WORKDIR /src/apps/web
RUN node ../../node_modules/next/dist/bin/next build

FROM docker.io/node:24-alpine AS runtime

ARG OPENCUT_VERSION
LABEL org.opencontainers.image.title="OpenCut" \
      org.opencontainers.image.description="OpenCut web application packaged by HelmForge" \
      org.opencontainers.image.vendor="HelmForge" \
      org.opencontainers.image.authors="HelmForge Team" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/helmforgedev/opencut" \
      org.opencontainers.image.url="https://github.com/OpenCut-app/OpenCut" \
      org.opencontainers.image.version="${OPENCUT_VERSION}"

RUN apk add --no-cache ca-certificates wget && \
    addgroup --system --gid 1001 opencut && \
    adduser --system --uid 1001 --ingroup opencut opencut

WORKDIR /app
COPY --from=build --chown=opencut:opencut /src/apps/web/public ./apps/web/public
COPY --from=build --chown=opencut:opencut /src/apps/web/.next/standalone ./
COPY --from=build --chown=opencut:opencut /src/apps/web/.next/static ./apps/web/.next/static

ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    HOSTNAME=0.0.0.0 \
    PORT=3000

USER opencut:opencut
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -qO- "http://127.0.0.1:${PORT}/api/health" >/dev/null || exit 1

CMD ["node", "apps/web/server.js"]

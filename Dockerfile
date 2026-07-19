# syntax=docker/dockerfile:1
# Shared build for React Router SSR apps. Build: docker build --build-arg APP=erp -t carbon/erp .
ARG APP=erp

# ==========================================
# 1. Dependency Installation Stage
# ==========================================
FROM node:22 AS deps
WORKDIR /repo

# Enable corepack to enforce your pinned pnpm version
RUN corepack enable
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0

# Copy root configuration and dependency configurations
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc turbo.json lingui.config.js ./
COPY apps ./apps
COPY packages ./packages
COPY patches ./patches

# Install core dependencies including optional system binaries
RUN HUSKY=0 pnpm install --frozen-lockfile

# ==========================================
# 2. Application Compiling Stage
# ==========================================
FROM deps AS build
ARG APP=erp
ARG NODE_OPTIONS="--max-old-space-size=8024"
ENV NODE_OPTIONS=${NODE_OPTIONS}

# Execute Turborepo build for the target application
RUN pnpm run build:${APP}

# ==========================================
# 3. Production Runtime Stage
# ==========================================
FROM node:22-slim AS runner
ARG APP=erp
WORKDIR /repo

# Environment variables configuration
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
ENV NODE_ENV=production
ENV PORT=3000
ENV HOST=0.0.0.0

# Re-enable corepack in the slim base image so the final container recognizes 'pnpm' commands
RUN corepack enable

# Copy pruned, deployment-ready configurations and folders
COPY --from=deps /repo/package.json /repo/pnpm-lock.yaml /repo/pnpm-workspace.yaml /repo/.npmrc ./
COPY --from=deps /repo/node_modules ./node_modules
COPY --from=deps /repo/packages ./packages
COPY --from=build /repo/apps/${APP} ./apps/${APP}

EXPOSE 3000
WORKDIR /repo/apps/${APP}

# Execute a client-side static application view context to bypass SQL dependencies completely
CMD ["pnpm", "exec", "vite", "preview", "--port", "3000", "--host", "0.0.0.0"]

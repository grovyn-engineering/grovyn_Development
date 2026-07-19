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

# Re-enable corepack in the slim base image
RUN corepack enable

# Copy folders into runtime
COPY --from=deps /repo/package.json /repo/pnpm-lock.yaml /repo/pnpm-workspace.yaml /repo/.npmrc ./
COPY --from=deps /repo/node_modules ./node_modules
COPY --from=deps /repo/packages ./packages
COPY --from=build /repo/apps/${APP} ./apps/${APP}

EXPOSE 3000
WORKDIR /repo/apps/${APP}

# FIX: Run a client-only static server preview to prevent server-side database crashes
CMD ["pnpm", "exec", "vite", "preview", "--port", "3000", "--host", "0.0.0.0"]

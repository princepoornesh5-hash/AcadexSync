# ── Stage 1: Build Stage ───────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies first for efficient layer caching
COPY package*.json tsconfig*.json ./
RUN npm ci

# Copy TypeScript source code and build
COPY src ./src
RUN npm run build

# ── Stage 2: Production Runtime ────────────────────────────
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=5050

# Copy package manifests and install production-only dependencies
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Copy compiled JavaScript output from builder stage
COPY --from=builder /app/dist ./dist

# Use non-root node user for container security
USER node

EXPOSE 5050

CMD ["node", "dist/server.js"]

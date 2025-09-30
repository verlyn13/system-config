# syntax=docker/dockerfile:1.11
# Use latest Dockerfile syntax for BuildKit features

# Multi-stage build for optimal image size
FROM node:22-alpine AS base

# Install curl for healthchecks
RUN apk add --no-cache curl

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S bridge -u 1001

WORKDIR /app

# Copy package files for better layer caching
COPY package*.json ./

# Development stage
FROM base AS dev
RUN npm ci --include=dev
COPY . .
USER bridge
EXPOSE 7171
CMD ["npm", "run", "dev"]

# Production dependencies stage
FROM base AS deps
RUN npm ci --omit=dev && npm cache clean --force

# Production stage
FROM base AS prod
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Remove development files
RUN rm -rf tests/ docs/ examples/ *.md

# Use non-root user
USER bridge

# Expose port
EXPOSE 7171

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:7171/api/health || exit 1

# Use exec form for better signal handling
CMD ["node", "scripts/http-bridge.js"]

# Default to production stage
FROM prod
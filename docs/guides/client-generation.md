---
title: Client Generation
category: reference
component: client_generation
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---


# Typed Client Generation (Stage 2)

This guide shows how to generate TypeScript Axios clients for the Bridge, DS, and MCP servers and how to integrate them into the dashboard adapters.

## Prerequisites

### Option 1: Node.js
- Node 18+ and npm/pnpm
- `@openapitools/openapi-generator-cli` installed via npx

### Option 2: Docker (Recommended for CI/Reproducible Builds)
- Docker Engine v28.x (latest stable release)
- Docker Compose v2.38.1+ (released June 30, 2025)
- OrbStack (preferred on macOS for optimal performance)
- No Node.js installation required

### Development Environment
- Bridge server running locally for live `openapi.yaml` (optional)

## Recommended pipeline (bundle once, generate types)

```
# 1) Lint + 2) Bundle + 3) Generate types
node scripts/gen-client.mjs
```

This creates `build/openapi.bundled.yaml` and `examples/dashboard/generated/bridge-types.d.ts`.

Use `openapi-fetch` or your preferred fetch client with these types.

## Bridge axios client (optional)

```
# Uses OBS_BRIDGE_URL (default http://127.0.0.1:7171)
./scripts/generate-openapi-client.sh examples/dashboard/generated/bridge-client build/openapi.bundled.yaml
```

## DS client

```
# Uses DS_BASE_URL (default http://127.0.0.1:7777)
./scripts/generate-openapi-client-ds.sh examples/dashboard/generated/ds-client
```

## MCP client

```
# Uses MCP_BASE_URL (default http://127.0.0.1:4319)
./scripts/generate-openapi-client-mcp.sh examples/dashboard/generated/mcp-client
```

## Dashboard adapter integration (outline)

- Prefer generated Bridge client in `bridgeAdapter` methods (integration, manifest, tools):
  - Fallback to fetch if the client is not present (keep behavior compatible).
- Optionally use generated DS client in `dsAdapter` for DS self-status/health.
- Keep SSE logic unchanged; validate SSE payloads via Ajv client-side.

## Docker/OrbStack Integration

### Automatic Docker Fallback

All generation scripts automatically detect and prefer Docker when Node.js/npx is not available:

```bash
# Script logic: tries npx first, falls back to Docker
if command -v npx >/dev/null 2>&1; then
  npx @openapitools/openapi-generator-cli generate ...
elif command -v docker >/dev/null 2>&1; then
  docker run --rm -v "$(pwd):/local" openapitools/openapi-generator-cli generate ...
fi
```

### OrbStack Optimizations (macOS)

OrbStack provides significant performance improvements over Docker Desktop:

- **Fast container startup**: ~2-3x faster than Docker Desktop
- **Native macOS integration**: Better file system performance
- **Lower resource usage**: Reduced memory and CPU overhead
- **Rosetta 2 optimization**: Improved ARM64/x86_64 compatibility

### Docker Compose for Development

For development workflows with multiple services:

```yaml
# docker-compose.yml (example)
services:
  bridge:
    build: .
    ports:
      - "7171:7171"
    environment:
      - BRIDGE_STRICT=1
      - BRIDGE_CORS=1

  client-generator:
    image: openapitools/openapi-generator-cli:latest
    volumes:
      - ./generated:/local/generated
    command: generate -g typescript-axios -o /local/generated/bridge-client -i http://bridge:7171/openapi.yaml --skip-validate-spec
    depends_on:
      - bridge
```

### Modern Docker Patterns (2025)

#### Enhanced Generation Script
Use the modern Docker client generation script for optimal performance:

```bash
# Version checking + modern patterns
./scripts/docker-client-generation.sh direct bridge http://127.0.0.1:7171
# or via Docker Compose
./scripts/docker-client-generation.sh compose bridge
```

#### Docker Compose Development Workflow

```bash
# Start bridge with development watch mode
docker compose --profile dev up bridge-dev

# Generate clients using Compose
docker compose --profile tools run --rm client-generator generate \
  -g typescript-axios -o /local/generated/bridge-client \
  -i http://bridge:7171/openapi.yaml --skip-validate-spec

# Full development stack
docker compose --profile dev --profile tools up
```

#### 2025 Best Practices Implementation

Our implementation follows the latest Docker patterns:

- **Docker Engine v28.x compatibility**: Automatic version checking
- **Compose v2.38.1+ features**: `develop.watch`, `include`, `profiles`
- **BuildKit optimization**: `DOCKER_BUILDKIT=1` with enhanced caching
- **Security hardening**: Non-root containers, read-only filesystems
- **Multi-stage builds**: Optimized production images
- **Modern volume syntax**: `type=bind` with explicit mount options
- **Health checks**: Integrated container health monitoring
- **Network isolation**: Custom bridge networks with explicit naming

### Troubleshooting

#### Schema Resolution Issues
If you see `contracts.local` connection errors:
- The `--skip-validate-spec` flag is automatically added to bypass $ref resolution
- Schema validation warnings are expected and non-blocking

#### Version Compatibility
Run version checks before generation:
```bash
# Check Docker compatibility
./scripts/docker-client-generation.sh --version-check
# Manual verification
docker version  # Should be v28.x
docker compose version  # Should be v2.38.1+
```

#### Performance Optimization
- **OrbStack on macOS**: 2-3x faster than Docker Desktop
- **Pre-pull images**: `docker pull openapitools/openapi-generator-cli:latest`
- **BuildKit enabled**: `export DOCKER_BUILDKIT=1` (default in v28.x)
- **Multi-platform caching**: `docker buildx build --cache-from --cache-to`
- **Compose profiles**: Use `--profile` flags for selective service startup

## Notes

- Generation requires `@openapitools/openapi-generator-cli` via npx or Docker
- Docker is preferred for CI/CD and reproducible builds
- OrbStack provides optimal Docker performance on macOS
- All scripts include automatic fallback from npx to Docker
- Schema validation is bypassed for Docker generation to handle $ref resolution

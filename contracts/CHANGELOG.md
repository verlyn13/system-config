# Contract Changelog

## v1.1.0 - 2025-09-29 [FROZEN]

### Stage 0 Endpoints (Locked)

#### Discovery
- `GET /api/discovery/services` - Service discovery with ds.self_status and ts:number
- `GET /api/discovery/schemas` - Schema listing with fallback (no Ajv dependency)
- `GET /api/schemas/{name}` - Individual schema retrieval with ETag

#### Projects
- `GET /api/projects` - Project listing with count
- `GET /api/projects/{id}/manifest` - Manifest with validation (404 if not found)
- `GET /api/projects/{id}/integration` - Integration with services.ds.self_status
- `GET /api/projects/{id}/status` - Project observation status
- `GET /api/projects/{id}/health` - Project health summary

#### Tools
- `POST /api/tools/obs_validate` - Project validation tool
- `POST /api/tools/obs_migrate` - Observation migration tool

#### SSE
- `GET /api/events/stream` - Server-sent events (ProjectObsCompleted, SLOBreach)

#### Well-known
- `GET /.well-known/obs-bridge.json` - Public discovery document
- `GET /api/obs/well-known` - Alias route (also public)

#### Aliases (/api/obs/*)
All primary routes have aliases under `/api/obs/*` with full parity:
- `/api/obs/discovery/services`
- `/api/obs/discovery/schemas`
- `/api/obs/discovery/openapi`
- `/api/obs/schemas/{name}`
- `/api/obs/projects/{id}/integration`
- `/api/obs/projects/{id}/observers/{type}`
- `/api/obs/tools/obs_validate`
- `/api/obs/tools/obs_migrate`

### Schemas (Locked)

#### Core Schemas
- `obs.integration.v1.json` - Project integration response
- `obs.manifest.result.v1.json` - Manifest validation result
- `obs.line.v1.json` - Observation line format
- `obs.health.v1.json` - Health check format
- `service.discovery.v1.json` - Service discovery response
- `obs.validate.result.v1.json` - Validation tool result
- `obs.migrate.result.v1.json` - Migration tool result

#### Required Fields
- All discovery responses include `ts:number`
- DS services include `self_status` endpoint reference
- Integration responses include:
  - `schemaVersion: "obs.v1"`
  - `contractVersion: "v1.1.0"`
  - `checkedAt:number` (epoch ms)
  - `services.ds.self_status` object

### Contract Rules

#### Allowed Changes (Non-breaking)
- ✅ New endpoints can be added
- ✅ Optional fields can be added to responses
- ✅ New optional query parameters
- ✅ Additional HTTP headers (optional)
- ✅ New event types in SSE stream

#### Prohibited Changes (Breaking)
- ❌ Removing existing endpoints
- ❌ Changing endpoint URLs
- ❌ Removing response fields
- ❌ Changing field types
- ❌ Adding required request fields
- ❌ Changing authentication methods
- ❌ Modifying schema validation rules

### Implementation Details

#### Error Handling
- All endpoints return consistent error format:
  ```json
  {
    "error": "string",
    "details": "string (optional)"
  }
  ```
- HTTP status codes follow REST conventions

#### Authentication
- Optional Bearer token via `BRIDGE_TOKEN` environment variable
- Public paths: `/api/health`, `/.well-known/obs-bridge.json`, `/api/obs/well-known`
- Protected endpoints return 401 when token is set but not provided

#### Content Types
- All JSON responses use `application/json`
- SSE stream uses `text/event-stream`
- OpenAPI served as `text/yaml` or `application/yaml`

#### Caching
- Schemas include ETag headers
- 304 Not Modified supported with If-None-Match

### Migration Notes

Future versions requiring breaking changes must:
1. Create new major version (v2.0.0)
2. Document migration path
3. Support both versions temporarily
4. Provide deprecation timeline
5. Coordinate across all agents

### Version History

- **v1.1.0** (2025-09-29): Initial contract freeze, Stage 0 complete
- **v1.0.0** (2025-09-28): Pre-freeze development version

---
**Contract Status**: FROZEN
**Version**: v1.1.0
**Freeze Date**: 2025-09-29
**Breaking Changes**: Prohibited without major version bump
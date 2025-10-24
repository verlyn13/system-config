---
title: Mcp Http Examples
category: reference
component: mcp_http_examples
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---


# MCP HTTP Examples

Validate observations coverage
```
curl -sS -X POST http://127.0.0.1:7171/api/tools/obs_validate | jq .
curl -sS http://127.0.0.1:7171/api/obs/validate | jq .
```

Migrate NDJSON per project (combine per-observer files)
```
curl -sS -X POST http://127.0.0.1:7171/api/tools/obs_migrate -H 'Content-Type: application/json' -d '{"project_id":"<id>"}' | jq .
```

Validate manifest
```
curl -sS http://127.0.0.1:7171/api/projects/<id-encoded>/manifest | jq .
PROJECT_ID=<id> node scripts/validate-manifest.mjs http://127.0.0.1:7171
```

Project integration view
```
curl -sS http://127.0.0.1:7171/api/projects/<id-encoded>/integration | jq .
```

Schemas and OpenAPI
```
curl -sS http://127.0.0.1:7171/openapi.yaml
curl -sS http://127.0.0.1:7171/api/schemas/obs.integration.v1.json | jq .
```


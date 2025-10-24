---
title: Pull_Request_Template
category: reference
component: pull_request_template
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---

Title: <concise summary>

## Summary

- What’s changing and why?
- Link related issues/epic (Stage, Epic)

## Changes

- Endpoints touched:
  - [ ] Discovery (`/api/discovery/*`, aliases under `/api/obs/*`)
  - [ ] Projects (`/api/projects/:id/{manifest,integration}`)
  - [ ] Tools (`POST /api/tools/{obs_validate,obs_migrate}`)
  - [ ] SSE (`/api/events/stream`)
  - [ ] Well-known (`/.well-known/obs-bridge.json`)

- Schemas updated:
  - [ ] `schema/service.discovery.v1.json`
  - [ ] `schema/obs.integration.v1.json`
  - [ ] `schema/obs.manifest.result.v1.json`
  - [ ] `schema/obs.validate.result.v1.json`
  - [ ] `schema/obs.migrate.result.v1.json`

- OpenAPI changes:
  - [ ] Component schemas
  - [ ] Response envelopes
  - [ ] New/updated endpoints

- SSE Events:
  - [ ] `ProjectObsCompleted`
  - [ ] `SLOBreach`

## Validation (Local)

Run what applies and paste relevant snippets/logs.

```
node scripts/validate-endpoints.js
PROJECT_ID=<id> node scripts/validate-endpoints.js
DS_BASE_URL=http://127.0.0.1:7777 DS_TOKEN=... node scripts/ds-validate.mjs
node scripts/sse-listen.js
```

## CI Expectations

- [ ] Ajv schema validation passes
- [ ] OpenAPI lint passes
- [ ] Endpoint validation workflow green
 - [ ] Documentation changes (if any) follow docs/INDEX.md Writing Guidelines (no duplication, value-dense; no word-count metrics)
 - [ ] Docs Lint: zero errors (see artifact docs-lint-report)

## Breaking Changes / Migrations

- [ ] No breaking changes
- If breaking, describe migration path and alias coverage.

## Demo Checklist

- [ ] Verified Contracts page (ETag-aware)
- [ ] Verified DS/MCP cards (if applicable)
- [ ] Verified Projects grid/table chips
- [ ] Verified Project detail: Manifest/Integration with `checkedAt`

## Screenshots / Logs

Attach if UI or logs changed.

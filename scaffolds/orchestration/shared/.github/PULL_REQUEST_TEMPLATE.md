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

Paste commands and relevant logs.

## CI Expectations

- [ ] Ajv schema validation passes
- [ ] OpenAPI lint passes
- [ ] Endpoint validation workflow green

## Breaking Changes / Migrations

- [ ] No breaking changes
- If breaking, describe migration path and alias coverage.


---
title: Prefetch
category: reference
component: prefetch
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---


# Dashboard Prefetch & Caching

This guide defines the endpoints, TTLs, and validation rules for Stage 4 prefetch.

- Map: docs/prefetch-map.json
- Validator: scripts/prefetch-validate.mjs

## Endpoints

- /api/discovery/services
  - Cache-Control: public, max-age=15, must-revalidate
  - ETag: weak; derived from system registry mtime and URLs
  - Usage: prefetch on app boot; use conditional GET with If-None-Match

- /api/projects
  - Cache-Control: public, max-age=10, must-revalidate
  - ETag: weak; derived from registry mtime, size, and project count
  - Usage: prefetch on app boot; use conditional GET with If-None-Match

- /api/discovery/schemas
  - Cache-Control: no-store (validation-heavy); ETag present for efficient re-fetch when needed
  - Usage: fetch on demand; conditional GET with If-None-Match when reloading

## Implementation Pattern

1. Read docs/prefetch-map.json; fire requests in parallel
2. Store ETag per path
3. On subsequent fetches, set If-None-Match to leverage 304s
4. Hydrate UI from cached data; wire SSE for live deltas

## CI

- Stage 4 Prefetch Smoke: .github/workflows/stage-4-prefetch.yml
  - Starts the Bridge
  - Validates ETag/Cache-Control and conditional GETs


---
title: Contracts Index
category: reference
component: contracts
status: active
version: 1.1.0
last_updated: 2025-09-28
---

# Contracts Index

Schemas (served by bridge):
- ObserverLine: /api/schemas/obs.line.v1.json (id: https://contracts.local/schemas/obs.line.v1.json)
- ProjectHealthSummary: /api/schemas/obs.health.v1.json
- SLOBreachEvent: /api/schemas/obs.slobreach.v1.json
- ProjectManifest (v1): /api/schemas/project.manifest.v1.json
- ProjectManifest (legacy): /api/schemas/project.manifest.schema.json
- ProjectIntegration: /api/schemas/obs.integration.v1.json
- ProjectManifestValidationResult: /api/schemas/obs.manifest.result.v1.json

OpenAPI:
- Bridge: /openapi.yaml (mirror: /api/discovery/openapi)

Service Discovery:
- Bridge: /.well-known/obs-bridge.json
- DS: See /api/discovery/services (ds.well_known)
- MCP: /api/mcp/self-status for availability; service discovery includes URLs


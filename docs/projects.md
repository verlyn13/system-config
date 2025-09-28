---
title: Project Manifests
category: reference
component: projects
status: active
version: 1.0.0
last_updated: 2025-09-28
---

# Project Manifests (devops.v1)

This document defines the canonical `project.manifest.yaml` used for discovery, governance, and observability.

See schema: `schema/project.manifest.schema.json`.

## Minimal Example

```yaml
apiVersion: devops.v1
project:
  id: github:org/my-service
  name: my-service
  org: org
  tier: prod
  kind: app
  owners: ["you@example.com"]
runtime:
  language: node
repo:
  url: "git@github.com:org/my-service.git"
quality:
  minCoverage: 0.8
observability:
  slo:
    ciSuccessRate: ">=0.95"
    p95LocalBuildSec: "<=120"
dependencies:
  packageManagers: [npm]
security:
  secretRefs: ["secret://gopass/org/my-service/ci-token"]
dashboard:
  panels: ["buildHealth","coverage","deps","repoStatus","obsLatency"]
```

## Location & Discovery

- File: `/<workspace>/<org>/<project>/project.manifest.yaml`
- Discovery roots: see `scripts/project-discover.sh` allowlist
- Registry cache: `~/.local/share/devops-mcp/project-registry.json`

## Template

Use `06-templates/projects/` samples to bootstrap new repos.


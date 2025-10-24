---
title: Monorepo Current State
category: reference
component: monorepo_current_state
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---


# Monorepo Migration: Current State Analysis Checklist

This report captures verified details from the four core repositories that make up the MVP system. Sources include repository files, lockfiles, manifests, and CI workflows. Host OS: macOS 26.0 (Tahoe), Darwin 25.0.0.

Repositories analyzed:
- Repo 1: personal/system-setup-update — Bridge/Contracts + orchestration
- Repo 2: personal/ds-go — DS CLI/Service (Go)
- Repo 3: personal/system-dashboard — Dashboard (React + Vite + Bun)
- Repo 4: personal/devops-mcp — MCP Server (TypeScript, PNPM)

---

## 1. Codebase & Architecture 🧬

- Languages & Frameworks
  - Repo 1: Node.js 24 (scripts, small Node HTTP bridge), Shell; Libraries: Ajv; No framework runtime
  - Repo 2: Go 1.25; Frameworks/Libraries: cobra (CLI), net/http; OpenAPI present
  - Repo 3: React 19 + Vite; Node server (Express 5); Runtime Bun 1.2.x
  - Repo 4: TypeScript (Node >=18); PNPM workspace; Libraries: MCP SDK, OpenTelemetry, Pino; Tests: Vitest

- Inter-Repository Dependencies
  - Runtime coupling via HTTP and SSE:
    - Dashboard consumes Bridge and DS endpoints
    - Bridge proxies/links to DS and MCP, and runs observer scripts from Repo 1
    - MCP can run external observers (git/mise/build/sbom/manifest) in Repo 1
  - No package linking or submodules; no inter-repo build-time dependencies detected

- Dependency Management
  - Repo 1: npm (package-lock.json)
  - Repo 2: Go Modules (go.mod)
  - Repo 3: Bun with package.json (npm registry); scripts via bunx
  - Repo 4: PNPM (pnpm-workspace.yaml, pnpm-lock.yaml)

- Repository Metrics (approximate)
  - Repo 1: Size 11 MB, Commits 11
  - Repo 2: Size 23 MB, Commits 10
  - Repo 3: Size 673 MB, Commits 4
  - Repo 4: Size 285 MB, Commits 2

- Git History Preservation
  - Observed: all four repos use `main` as default; no tags detected
  - Recommendation: Preserve history for audit/blame; interleaving not required (runtime coupling only)

---

## 2. Tooling & Infrastructure 🛠️

- CI/CD Platform
  - All four: GitHub Actions (.github/workflows present in each)

- Build System (primary commands/tools)
  - Repo 1: Node scripts (no explicit build step); Dockerfile present for tooling
  - Repo 2: Go (Makefile delegates to `mise run build`); `go build` used under the hood
  - Repo 3: Bun + Vite (`bun run build`), Express dev server
  - Repo 4: PNPM + TypeScript (`pnpm build` -> `tsc`)

- Testing Strategy
  - Repo 1: Validation scripts (endpoint, SSE, prefetch); no formal test framework
  - Repo 2: Go `go test` (pkg/dsclient); make/mise tasks for lint/coverage
  - Repo 3: `bun test` (package.json), Biome lint/check
  - Repo 4: `pnpm test` (Vitest), schema/openapi lint workflows
  - Average runtime: Not established across all repos (no consistent historical timings available)

- Deployment Strategy
  - Dev: Local processes (Node/Bun/Go)
  - Containers: docker-compose present in Repo 1 and Repo 4 for local stack; Kubernetes/ECS not defined
  - Static build (Dashboard): Build with Vite; served by dev server for local

---

## 3. Process & Governance 🧑‍⚖️

- Team Structure & Ownership
  - Inferred: Single operator/team across repos (personal workspace); no team metadata in code

- Branching Strategy
  - Trunk-based on `main` for all four; no long-lived alternate branches observed

- Release Cadence
  - No tags found; releases appear ad-hoc per repo (independent schedules)
  - Repo 1 Cadence: (no tags; CI workflows per change)
  - Repo 2 Cadence: (no tags; Makefile + stages docs)
  - Repo 3 Cadence: (no tags; Vite/Bun build triggers)
  - Repo 4 Cadence: (no tags; CI stages present)

- OPA Policy Goals (proposed, aligned with current Policy-as-Code)
  1. Contract protection: block breaking changes to OpenAPI/JSON Schemas via CI
  2. Version management compliance: enforce mise usage and trusted config across repos
  3. Secret hygiene: forbid committing secret-like files (.env, *.key, *.pem) to repos
  4. Tool/version baselines: require minimum versions for git, node, go, python, etc.
  5. Project bootstrap standards: require .envrc structure and `.mise.toml` in each repo

- OPA Integration Points
  - CI Pull Request checks (primary)
  - Optional: pre-commit hooks for secrets and formatting
  - Optional: CD pre-deploy gates for contract conformance (where applicable)

---

## 4. Stage Readiness Snapshot ✅

- Stage 0–2: Complete for Agent A; supporting docs and CI in all repos
- Stage 3: SSE validator fixed; CI smoke job short timeout; end-to-end event validation passes locally
- Stage 4: Prefetch/ETag semantics in Bridge; validator and CI workflow added; dashboard integration pending

Artifacts added in this pass:
- SSE fix: scripts/sse-validate.mjs (reader cancel + fast exit)
- Prefetch: scripts/prefetch-validate.mjs, docs/prefetch.md, docs/prefetch-map.json
- CI: .github/workflows/stage-3-sse.yml (tightened), stage-4-prefetch.yml (added)
- Env standards: .envrc template and multi-repo alignment script

---

## 5. Next Steps for Monorepo Migration 📦

1) Decide scope of monorepo: include these 4, or expand to adjacent repos (e.g., system-dashboard only, ds-go, devops-mcp, system-setup-update)
2) Choose monorepo tooling: PNPM workspaces or Nx/Turborepo for JS; Go remains module-per-folder
3) Policy alignment: codify OPA rules above; add CI checks to enforce .envrc/mise trust
4) Contract centralization: single `contracts/` source with versioning; publish clients as artifacts
5) Incremental migration: start with dashboard + bridge (shared contracts), then integrate ds-go and devops-mcp

---

## 6. Evidence Pointers 🔎

- Repo 1
  - package.json, openapi.yaml, scripts/http-bridge.js, .github/workflows/*
- Repo 2
  - go.mod (Go 1.25), Makefile, pkg/dsclient tests, .github/workflows/*
- Repo 3
  - package.json (React/Vite), src/lib/* adapters, .github/workflows/*
- Repo 4
  - pnpm-workspace.yaml, package.json scripts, tsconfig.json, .github/workflows/*


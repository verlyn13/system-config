# DECISIONS.md — Host Capability Substrate

Target-repo template drafted in `system-config`. Copy to HCS repo root when created.

Human-readable decision ledger. Complementary to ADRs. Agents check this before reopening settled questions.

- **Pending** are unresolved questions blocking a decision.
- **Accepted** are settled; changing them requires an amendment ADR.
- **Reversed** are decisions that were later changed; keep the history.

Upstream research plan (canonical): `~/Organizations/jefahnierocks/system-config/docs/host-capability-substrate-research-plan.md` (v0.3.0+ resolved all v0.2.0 open items).

## Pending

| ID | Question | Owner | Due before | Status |
|----|----------|-------|------------|--------|
|    |          |       |            |        |

## Accepted

| ID | Decision | Rationale | ADR | Date |
|----|----------|-----------|-----|------|
| D-001 | HCS is a horizontal substrate with kernel + protocol adapters; MCP is one adapter, not the architecture. | Protocol-agnostic kernel ages better as GPT/Claude/Gemini/MCP/A2A evolve. | ADR 0001 | 2026-04-22 |
| D-002 | Runtime: Node LTS first. Bun only with measured evidence. | Always-on service prioritizes ecosystem maturity, OTEL, SQLite library stability. | ADR 0002 | 2026-04-22 |
| D-003 | Storage: SQLite with WAL; single writer, snapshot-isolation readers. | Matches workload shape. | ADR 0004 | 2026-04-22 |
| D-004 | Policy canonical location: `system-config/policies/host-capability-substrate/`. HCS repo vendors a snapshot for tests. | Governance-adjacent; consistent across hosts; review under existing `policies/` process. | ADR 0006 | 2026-04-22 |
| D-005 | Hook call pattern: blocking local RPC, 50ms target, cache fallback. Writes fail-closed when classifiable as mutating/destructive; reads warn-and-allow on timeout. | Blocking is simplest; cache prevents SPOF; 50ms is the perceptible-latency threshold. | ADR 0007 | 2026-04-22 |
| D-006 | Claude hooks: command hook for hard decisions (fail-closed), HTTP hook for advisory/telemetry. Bodies stay thin. | Command hooks run with user permissions; HTTP hook failures are non-blocking per Claude Code docs. | ADR 0007 | 2026-04-22 |
| D-007 | Codex hooks: advisory guardrails, not the hard enforcement boundary (Bash-only coverage). | Current Codex hook coverage is incomplete; substrate-side policy is the real boundary. | ADR 0007 | 2026-04-22 |
| D-008 | OPA adoption trigger: migrate when ≥2 rules need boolean composition across principal + host + workspace + operation + target + time + prior grants. | Concrete + observable; avoids premature engine adoption. | (pending ADR) | 2026-04-22 |
| D-009 | GPT-5.4 remote MCP hosting: localhost-only in Phase 0/1 (stdio + Streamable HTTP bound to 127.0.0.1). Remote tunnel is a separate ADR. | MCP Streamable HTTP guidance says local servers bind localhost with auth; build posture before exposing. | ADR 0003 | 2026-04-22 |
| D-010 | Audit access: both direct read-only SQLite/DuckDB AND server-side query endpoints. | SQL is right for post-hoc investigation; agents should not discover audit schema ad hoc. | (pending ADR) | 2026-04-22 |
| D-011 | Tier file owner-of-record: human (user) owns; agents may draft; `hcs-policy-reviewer` subagent must file objections before merge. | Tier classification is judgment work; human loop kept light by the reviewer subagent. | (pending ADR) | 2026-04-22 |
| D-012 | MCP primitives: tools for live calls; resources for cached snapshots/evidence/policy/audit views; prompts for user-invoked workflows. | Matches MCP's primitive hierarchy; keeps surface idiomatic for every host. | ADR 0010 | 2026-04-22 |
| D-013 | A2A facade: deferred to Month 6+ unless a concrete cross-agent delegation flow that cannot be represented as MCP tools/resources/prompts emerges. | Complementary to MCP; HCS must first be a reliable tool/context substrate. | (pending ADR) | 2026-04-22 |
| D-014 | Repo: dedicated target repo (name pending user choice). | Substrate cadence differs from project code. | ADR 0001 | 2026-04-22 |
| D-015 | Dashboard is part of first slice (read-only). View-model contracts defined before kernel internals. | Human visibility is first-class; kernel output must be dashboard-renderable from day 1. | ADR 0008 | 2026-04-22 |
| D-016 | Execute lane ships only after approval grants + audit hash chain + dashboard review + lease manager all exist. | Defer the dangerous surface until the full safety stack is live. | (pending ADR) | 2026-04-22 |
| D-017 | Repo name: `host-capability-substrate` (no prefix); path: `~/Organizations/jefahnierocks/host-capability-substrate/`; GitHub: `verlyn13/host-capability-substrate`. | Matches observed practice on all 30+ verlyn13 repos; stale `jfr-` prefix in `.subsidiary.yaml` tracked for separate cleanup. | ADR 0001 | 2026-04-22 |
| D-018 | Public source, private deployment boundary. Repo contains source/schemas/fixtures/docs; live policy, runtime state, audit archives, and tokens live outside the repo. | Transparency of structure without leaking authority over live host. | ADR 0011 | 2026-04-22 |
| D-019 | Skills canonical location is `.agents/skills/` (cross-tool). `.claude/skills/` is Claude-specific wrappers only, empty at Phase 0a. | Windsurf and Codex honor `.agents/skills/`; Claude wrappers added only when needed. Avoids skill drift. | (pending ADR) | 2026-04-22 |
| D-020 | Runtime state at `~/Library/Application Support/host-capability-substrate/`; logs at `~/Library/Logs/host-capability-substrate/`; LaunchAgent label `com.jefahnierocks.host-capability-substrate`. | macOS-native; matches OS conventions; reverse-DNS chosen for uniqueness. | ADR 0005 | 2026-04-22 |
| D-021 | Six project-scoped subagents including `hcs-ontology-reviewer`. All default Opus 4.7. No Bash in any review subagent's tool list. | Schema/ontology drift is load-bearing; independent reviewer is warranted. | (pending ADR) | 2026-04-22 |
| D-022 | Tool baseline early-phase: Claude Code `1.3883.0 (93ff6c)` + Opus 4.7; Codex `26.417.41555 (1858)` + GPT-5.4. Subsequent minor updates acceptable. | Stabilize behavior during scaffolding + first slice. Re-evaluate end of Phase 0b. | (pending ADR) | 2026-04-22 |
| D-023 | No `WARP.md` in Phase 0a. Warp prioritizes `WARP.md` over `AGENTS.md`; adding early risks policy fork. | Let Warp consume `AGENTS.md` first; add pointer-only `WARP.md` post-Phase-0b only if measurement shows a gap. | (pending ADR) | 2026-04-22 |

## Reversed

| ID | Old decision | New decision | Why | Date |
|----|--------------|--------------|-----|------|
|    |              |              |     |      |

## How to use this file

- Before proposing a design change, scan **Accepted** to see if the question is settled.
- If settled but you believe it should change: open an amendment ADR, not a PR that contradicts.
- If unsettled: add a row to **Pending** with an owner and due-before date.
- When a decision is accepted, add the ADR link and move from **Pending** to **Accepted**.
- When a decision is reversed, move the old row to **Reversed** and add a new accepted row.

Agents should treat this file as authoritative for "is this settled?" even when AGENTS.md or CLAUDE.md is silent.

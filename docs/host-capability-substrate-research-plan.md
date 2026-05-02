---
title: Host Capability Substrate — Research Plan
category: research
component: host_capability_substrate
status: draft
version: 0.3.0
last_updated: 2026-04-22
tags: [substrate, kernel, mcp, a2a, apps, agentic, ontology, policy, audit, operations, implementation, macos]
priority: high
---

# Host Capability Substrate — Research Plan

Methodical plan for investigating, de-risking, and building a horizontal **Host Capability Substrate (HCS)** — an operations kernel that provides ground-truth host knowledge, toolchain resolution, capability exposure, policy enforcement, session/execution semantics, approval grants, audited runs, and human control for every agent that touches this workstation.

The substrate is the durable product. MCP, A2A, MCP Apps, client hooks, the local dashboard, and any future protocol surface are **adapters** over the same internal kernel.

Related live docs:

- [`docs/mcp-config.md`](./mcp-config.md) — current MCP framework and sync behavior
- [`docs/secrets.md`](./secrets.md) — 1Password + `op` policy the substrate must follow
- [`docs/agentic-tooling.md`](./agentic-tooling.md) — shell and tool contract the substrate composes with
- [`policies/version-policy.md`](../policies/version-policy.md) — existing policy-as-data precedent
- [`policies/opa/policy.rego`](../policies/opa/policy.rego) — existing OPA policy precedent
- [`docs/host-capability-substrate/implementation-charter.md`](./host-capability-substrate/implementation-charter.md) — binding four-ring rule
- [`docs/host-capability-substrate/templates/`](./host-capability-substrate/templates/) — target-repo scaffolding drafts

This is a research plan. It enumerates investigations, measurements, ontology work, resolved decisions, an agent operating system, human rituals, and an ordered implementation sequence. v0.3.0 closes the eight open items from v0.2.0 and adds a full Implementation Program — the discipline required to prevent implementation entropy once work begins.

## Context — why a substrate, not a server

Three agents routinely hit this host on the same day; 150+ repos with multi-agent orchestration; redundant probing compounds daily. Hooks encode policy that drifts from runbooks. Mutating commands are gated by ad-hoc patterns. Protocols are moving: MCP is maturing (2025-11-25 revision, MCP Apps extension January 2026), A2A is stabilizing, GPT-5.4 adds `tool_search`, Claude Code adds subagent tool scoping, Gemini/ADK adds multi-agent composition. A single-protocol server built today ages fast; a substrate with typed operations, versioned ontology, policy-as-data, protocol adapters, and strict implementation discipline ages well.

**Product name.** Host Capability Substrate (HCS). Short form: *substrate*. The MCP surface it exposes is one adapter among several. The existing MCP tool-namespace (`system.*`) is preserved as an adapter-layer convention — it names what agents see, not what the kernel is.

**Thesis in one line.** Treat this as a governance product with code, not a code product with governance.

**Timebox.** ~1 week of scaffolding (Phase 0a), then ~3-4 weeks of research (Phases 0b + 1) before the week-one build slice. ~6 months to a working first cut, landed incrementally and gated by daily-pain evidence.

## 1. Internal architecture — kernel + adapters

The durable rule, stated once:

> **Core domain logic knows nothing about GPT, Claude, Gemini, ChatGPT Apps, Claude Desktop, Codex, Cursor, Windsurf, or MCP transport quirks. Adapters translate external protocol calls into internal capability calls.**

### Internal kernel services

| Service | Responsibility |
|--------|--|
| **Host-state service** | Canonical `HostProfile` + live fact observations with provenance |
| **Tool-resolution service** | `ResolvedTool` walk: project-local → mise → brew → system, cwd-aware |
| **Capability registry** | Declared `Capability` set with schemas, preflight, preview, rollback, verification hooks |
| **Policy / gateway service** | Classifies operations, returns decision packages, owns tier definitions |
| **Session ledger** | `Session` objects with declared/measured `SessionContext`, lane state, client attribution |
| **Execution broker** | Finite-state machine that runs `OperationShape` through resolve/classify/preflight/preview/approve/execute/verify |
| **Evidence / cache store** | Cached help, man pages, probe results, tool metadata — every entry provenance-tagged |
| **Audit / event log** | Append-only, hash-chained, tamper-evident record of every kernel transition |
| **Lease / lock manager** | Exclusive and shared leases on resources (brew, mise, launchd domains, filesystem paths, orbstack) |
| **Dashboard / control plane** | Local HTTPS surface for humans — live sessions, approval queue, kill switches, policy explorer |
| **Protocol adapters** | Thin translation layers: MCP stdio, MCP Streamable HTTP, CLI (`ng-doctor` integration), Claude Code hooks, Codex hooks, A2A facade (later), direct local API |

### Adapter surfaces

- **MCP stdio** — Claude Code, Codex CLI, Cursor, Windsurf, IDE-spawned
- **MCP Streamable HTTP** — Claude Desktop, GPT-5.4 remote MCP, any HTTP-speaking client ([Transports spec](https://modelcontextprotocol.io/specification/2025-11-25/basic/transports))
- **Local dashboard HTTP** — bound to `127.0.0.1`, token-gated, human control plane
- **CLI (`ng-doctor` / substrate-wrapper)** — scripted and human invocation
- **Claude Code PreToolUse/PostToolUse hooks** — enforcement tier ([Claude Code hooks](https://code.claude.com/docs/en/hooks))
- **Codex hooks** — advisory/telemetry where available ([Codex hooks](https://developers.openai.com/codex/hooks))
- **A2A facade (later)** — expose a "Host Operations Agent" for inter-agent negotiation ([A2A protocol](https://a2a-protocol.org/latest/))
- **MCP Apps UI (optional, later)** — small dashboard components inside compatible clients ([MCP Apps blog](https://blog.modelcontextprotocol.io/posts/2026-01-26-mcp-apps/))

The MCP specification itself separates hosts/clients/servers and emphasizes focused servers with progressive capability negotiation ([MCP architecture](https://modelcontextprotocol.io/specification/2025-11-25/architecture)). That aligns with adapter-first design: each adapter is a focused surface; the kernel is not.

### The four rings

The substrate is organized in four rings. **No lower ring may import from a higher ring.** This is codified in [`docs/host-capability-substrate/implementation-charter.md`](./host-capability-substrate/implementation-charter.md) and enforced by package boundaries, CI checks, and review.

```
Ring 0 — Ontology and schemas
  Versioned entities, operation shapes, command shapes, evidence, decisions,
  approval grants, runs, leases, artifacts.

Ring 1 — Kernel services
  Host state, tool resolution, capability registry, policy/gateway,
  session ledger, evidence/cache, audit, lease manager, execution broker.

Ring 2 — Adapter surfaces
  MCP stdio, MCP Streamable HTTP, dashboard HTTP, CLI, Claude hooks,
  Codex hooks, future A2A, future MCP Apps.

Ring 3 — Agent/human workflows
  Skills, AGENTS.md, CLAUDE.md, PLAN.md, runbooks, eval prompts,
  dashboard review flows.
```

Rules:

- No policy decision may live in an adapter.
- No shell command is an ontology object; it is only a rendered `CommandShape`.
- No agent can reach across rings to shortcut a layer.

### Never in adapters

- Tier definitions
- Cache decisions
- Audit semantics
- Approval grant logic
- Operation-shape validation
- Toolchain resolution rules

Adapters translate requests, shape responses to the protocol's idiom, propagate session identity, and honor protocol-specific capabilities (e.g., MCP elicitation). Nothing else.

## 2. Ontology

The ontology is binding. Write it before production code and version every entity.

### Core entities

```text
HostProfile          canonical host identity + stable facts
WorkspaceContext     project/workspace identity (workspace.toml-derived)
Principal            a human or automated actor with an identity
AgentClient          connected MCP/A2A/hook client with version + identity
Session              one agent-client connection with declared/measured context
ToolProvider         a source of tools: mise, brew, system, project-local
ToolInstallation     a specific instance of a tool on this host
ResolvedTool         the authoritative answer for "what tool X in this context"
Capability           a declared kernel operation (e.g., service.activate)
OperationShape       semantic operation proposal with target + mutation scope
CommandShape         argv vector + env profile + execution lane (rendered from Operation)
Evidence             a fact with provenance, freshness, authority, confidence
PolicyRule           a tier/destructive-pattern/approval rule (YAML or Rego)
Decision             gateway output: allowed | requires_approval | denied
ApprovalGrant        scoped, expiring, replay-resistant authorization
Run                  one execution of an approved operation through the broker
Artifact             a run's structured output (diff, log chunks, exit code, signed summary)
Lease                exclusive or shared resource lock
Lock                 coarser mutex (e.g., "package-manager global")
SecretReference      op:// URI, never the value
ResourceBudget       per-session CPU/memory/network/sandbox-concurrency allocation
```

Each entity carries a `schema_version`. Entity schema versions are independent of adapter tool-name versions.

### Provenance on every fact

Every `Evidence` record:

```json
{
  "value": "node 24.3.0",
  "source": "mise current --json",
  "observed_at": "2026-04-22T18:31:12Z",
  "valid_until": "2026-04-22T18:36:12Z",
  "authority": "project-local",
  "cwd": "/path/to/project",
  "parser_version": "mise-current-json@1",
  "confidence": "authoritative",
  "host_id": "host_...",
  "session_id": "sess_..."
}
```

Authority levels: `project-local` > `workspace-local` > `user-global` > `system` > `derived` > `sandbox-observation`. Confidence levels: `authoritative`, `high`, `best-effort`, `stale`, `unknown`. Parsers are versioned so parser bugs can be fixed without cache-poisoning surviving the fix.

### Operation attributes

Every `OperationShape`:

```json
{
  "operation_id": "service.restart",
  "capability": "launchd.service.restart",
  "mutation_scope": "write-host",
  "target_resources": ["launchd:gui/501/com.example.foo"],
  "preflight": ["service.describe", "plist.validate"],
  "preview": "available",
  "rollback": "restart previous loaded state",
  "verification": ["service.status"],
  "locks_required": ["launchd:gui/501"],
  "requires_tty": false,
  "requires_network": false,
  "requires_sudo": false,
  "max_duration_seconds": 30,
  "idempotent": true
}
```

### Binding the ontology

- `docs/host-capability-substrate/ontology.md` — human-facing canonical reference (drafted in Phase 1 Thread D)
- `packages/schemas/` in target repo — Zod schemas generating TypeScript types and JSON Schema
- `policies/host-capability-substrate/` in this repo — YAML entries referencing entity schema versions
- Every audit event, every adapter response, every policy input validates against the ontology

Versioning: breaking changes to any entity bump its own `schema_version`; the gateway's decision cache keys include every relevant entity version so policy changes invalidate deterministically.

## 3. Operations, not commands

The wrong abstraction:

```text
agent -> shell command
```

The right abstraction:

```text
agent -> operation intent -> capability -> command shape -> validated invocation -> audited run
```

A shell command is one rendering of a capability. The substrate reasons about operations. The model never invents syntax; it proposes intent, and the kernel renders the invocation through the execution broker against the currently-resolved toolchain on this host.

**Wrong:**

```bash
launchctl load ~/Library/LaunchAgents/foo.plist
```

**Right:**

```json
{
  "operation": "service.activate",
  "manager": "launchd",
  "domain": "gui",
  "label": "com.example.foo",
  "plist": "~/Library/LaunchAgents/foo.plist",
  "scope": "user",
  "mutation": true
}
```

The broker renders this as modern `launchctl bootstrap gui/501 ~/Library/LaunchAgents/foo.plist`, rejects deprecated `load`/`unload` at the policy layer, requires approval if the tier demands it, and can return a plan-only preview. The same capability renders differently on future macOS versions without changing calling code.

**`CommandShape` is downstream of `OperationShape`.** Adapters translate incoming intents from their protocol idiom into `OperationShape`; the capability registry renders each into `CommandShape` against the current resolved toolchain; the broker runs the rendering through preflight → preview → approve → execute → verify.

## 4. Design principles (April 2026 standards)

- **Protocol-independent core.** Kernel knows no protocol. Adapters are the edge.
- **Capability-first, not command-first.** Operations are the unit of reasoning. Commands are a rendering.
- **Read-free, write-gated.** Reads cost nothing (cache-backed, sub-20ms p50, no approval). Writes go through the approval gateway unconditionally.
- **Policy as data.** Tier files, destructive-pattern lists, approval rules live in versioned YAML (and Rego where composition demands). Hooks, Skills, runbooks, and the kernel all read from the same policy store.
- **Evidence with provenance.** Every fact has a source, observed_at, valid_until, authority, parser version, confidence. No bare strings.
- **Approval as object, not signal.** `ApprovalGrant` is scoped, expiring, audit-recorded, optionally revocable.
- **Cache-heavy, session-aware.** Cross-agent persistent cache; session-aware invalidation; typed staleness.
- **Auditable by default.** Every kernel transition emits an event. Audit logging is never an agent-callable tool; it is an internal side effect.
- **Secret-free at rest.** Kernel references `op://` URIs; wrappers hydrate at launch. Never persist values.
- **Typed degraded mode.** "Server down" is a structured result with freshness metadata, not a prose warning or silent fallback.
- **Human visibility is first-class.** The dashboard is part of the substrate from the first slice, not a reporting afterthought.
- **Model-portable by construction.** Same capability answers for Claude, GPT, Gemini, or any future agent runtime.
- **Governance-versioned.** Every schema, policy, tier file, operation shape, decision record carries a version. Breaking changes bump the version and ship alongside the old one through a deprecation window.
- **Observable.** OpenTelemetry from line one. `/metrics` endpoint. Structured JSON logs. `ng-doctor` integration.

## 5. Scope — owns / does not own

> **If a capability answers "how does this machine work right now", it belongs in the substrate. If it answers "what should I do with this project", it belongs in a domain server or a Skill. If it's "what value is behind this secret reference", it belongs in `op`.**

### Owns

- Host identity + live fact observations with provenance
- Toolchain resolution (cwd-aware, workspace-aware)
- Capability registry and operation rendering
- Session ledger and `SessionContext` derivation
- Execution broker (FSM-governed)
- Typed validation wrappers: `nginx -t`, `terraform validate`, `sshd -t`, `plutil -lint`, `launchctl print-disabled`, `brew doctor`, `mise doctor`
- Dry-run orchestration where the native tool supports it
- Approval gateway (proposals + grants + decisions)
- Evidence / cache store
- Audit log (hash-chained, checkpointed)
- Resource lease / lock manager
- Sandbox orchestration via OrbStack ephemeral (later phase)
- Dashboard / control plane (from the first slice, read-only initially)
- MCP adapters, CLI adapter, hook adapters, A2A facade (later)

### Does not own

- Application-layer state
- Secret values (references only; `op` resolves at launch)
- Direct package installation
- Git operations (GitHub MCP and `gh`)
- Network-mutating commands outside the host
- Universal shell execution (`bash.run`-style tools are forbidden; see §7)
- Human-facing narrative
- Model orchestration

### Surface boundary rule (six-question test)

Before adding a capability, answer in writing:

1. Does it describe host/toolchain/session state?
2. Does it produce or consume an `OperationShape`?
3. Is its answer cacheable? If not, why?
4. Is there a less-powerful read-only variant that satisfies 80% of the need?
5. If it's a mutation, does it go through the gateway and produce an `ApprovalGrant`?
6. Does it carry a session identity and audit attribution?

Record these six answers in the capability's schema description.

## 6. Research phases

### Phase 0a — Scaffolding (week 1, first half)

Do this before the measurement week. Creates the structured surface that Phase 0b's observations and Phase 1's research threads write into.

**Tasks:**

- Create the HCS target repo (pending user go-ahead; see §22.1).
- Add `docs/host-capability-substrate/implementation-charter.md` (already authored in this repo; copied into target).
- Scaffold target-repo `AGENTS.md`, `CLAUDE.md`, `PLAN.md`, `IMPLEMENT.md`, `DECISIONS.md` from the templates in [`docs/host-capability-substrate/templates/`](./host-capability-substrate/templates/).
- Add ADR stubs (§22.11, Appendix M).
- Add `.logs/phase-0/` with output schema for measurement artifacts.
- Add seed regression corpus files for the 12 traps (§18, Appendix F).
- Wire Claude Code PreToolUse and Codex hooks in **warning/log-only mode** — no blocking yet. Hook bodies are thin: they call a local helper script that writes to `.logs/phase-0/` and returns advisory signals.
- Register `hcs-architect`, `hcs-policy-reviewer`, `hcs-security-reviewer`, `hcs-hook-integrator`, `hcs-eval-reviewer` subagents in `.claude/agents/` (Appendix I).
- Register Codex profiles `hcs-plan`, `hcs-implement`, `hcs-review` in `~/.codex/config.toml` (Appendix L).

**Deliverable.** A target repo that enforces its own discipline from the first commit. Agents cannot casually violate the four rings because package boundaries and hooks nudge them toward the right ring.

### Phase 0b — Baseline & measurement (week 1, second half)

With scaffolding in place, quantify.

**Tasks:**

- **Activity audit.** One week of agent tool-call logs across Claude Code, Codex CLI, Windsurf, Copilot CLI, Claude Desktop. Count `--help` invocations, version probes, toolchain resolution commands, host-state probes, and raw shell invocations.
- **Redundancy measurement.** Same-command-different-agent-within-24h counts.
- **Token-cost estimate.** `tokens/day/host`.
- **Hallucination-trap audit.** From recent sessions, collect deprecated-syntax proposals, wrong-toolchain suggestions, shell-mode confusion, and plausible-but-unverified CLI advice. Expand the seed regression corpus.
- **Governance-surface inventory.** Existing PreToolUse hooks, tier classifications, `policies/` content, runbook prose, hard-coded command lists in scripts.
- **1Password migration reconciliation.** Confirm `docs/secrets.md` v2.1.0 authoritative; document any gopass residue that must clear before the substrate consumes it.
- **Client identity mechanism.** Per-host probe of `InitializeRequest.clientInfo`. Propose `MCP_CLIENT_ID` env injection wrapper.
- **Protocol feature matrix.** Support per host for MCP stdio, Streamable HTTP, structured output schemas, resources, prompts, elicitation (form/URL), subagent tool scoping.

**Deliverable.** 3-4 page measurement brief + annotated governance inventory + protocol feature matrix + expanded trap corpus.

**Acceptance gate.** Real numbers. Concrete artifact citations. Trap corpus ≥15 entries (up from 10 in v0.2.0 — scaffolding gives you better instrumentation to capture).

### Phase 1 — Parallel research threads (weeks 1-2)

Six concurrent threads, each on its own branch or worktree (§22.11). Each produces a 1-2 page technical note + proposed ADRs.

#### Thread A — macOS surface APIs

Per-domain matrix (authoritative API, structured output, invocation cost, cache TTL, gotchas) for: launchd, Homebrew, mise, TCC, Xcode/CLT, OrbStack, codesign/quarantine, APFS, System identity. Prefer plist/JSON; regex parsers get versioned keys. TCC is least-charted — `tcc_unknown` as first-class result when FDA is absent, never silent best-guess.

#### Thread B — Protocol surfaces

Beyond MCP alone:

- **MCP tools, resources, prompts mapping.** Per [MCP server overview](https://modelcontextprotocol.io/specification/2025-11-25/server) and [tools spec](https://modelcontextprotocol.io/specification/2025-11-25/server/tools): tools are model-controlled executable functions; resources are application-controlled contextual data; prompts are user-controlled templates. Map substrate capabilities to the right primitive. Not everything should be a tool.
- **Deferred tool loading.** Validate `tool_search` on GPT-5.4 per [OpenAI docs](https://developers.openai.com/api/docs/guides/tools-tool-search) (recommends namespaces under ~10 functions). Validate Claude Code equivalent. Test a 50-dummy-tool scratch server; measure session init latency and wrong-tool-chosen rates.
- **Schema strictness.** Zod 4 → JSON Schema. Claude strict tool use and GPT-5.4 structured outputs. Substrate should exploit structured content + output schemas for decision packages.
- **Streamable HTTP transport.** Per [Transports spec](https://modelcontextprotocol.io/specification/2025-11-25/basic/transports), disconnection is not cancellation; explicit cancellation required. Confirm each host's cancellation semantics.
- **Elicitation.** Per [Elicitation spec](https://modelcontextprotocol.io/specification/2025-11-25/client/elicitation) (form + URL modes, URL mode new in 2025-11-25): use opportunistically for approval flows; dashboard is canonical.
- **MCP Apps.** Per [blog](https://blog.modelcontextprotocol.io/posts/2026-01-26-mcp-apps/): design dashboard view contracts to be embeddable without requiring Apps rendering.
- **A2A.** Per [A2A protocol](https://a2a-protocol.org/latest/): complementary. Defer facade to Month 6+ (see §21 decision).
- **Transport topology.** Single Hono process fronting stdio + Streamable HTTP vs separate processes sharing SQLite (WAL).

#### Thread C — Prior art

Anthropic reference MCP servers; community MCP for mise/brew/launchd/macOS; `mise doctor`, `brew doctor`, `mas-cli` output formats; Nix eval-style resolution; [OPA](https://openpolicyagent.org/docs) command-gating patterns; [OpenAI sandbox-agent guidance](https://developers.openai.com/api/docs/guides/agents/sandboxes); Google ADK multi-agent evaluation model ([ADK docs](https://google.github.io/adk-docs/)).

#### Thread D — Ontology + policy schema

Zod schemas for 20 core entities; generated JSON Schema and TypeScript types; `policies/host-capability-substrate/tiers.yaml` (first 30 tools, Appendix C); `gateway.contract.md`; `storage.sql` (Appendix D); `ontology.md`.

#### Thread E — Session and execution lanes

`SessionContext` schema (§7); execution lane taxonomy; `spawn(file, argv, env)` vs shell-string decision tree; `system.exec.unsafe_shell_proposal.v1` stigma design; PATH composition per lane; PTY detection; environment profile versioning.

#### Thread F — Cross-host portability

`HostProfile` resolution (adaptive, not forked); CI test matrix; second-host provisioning runbook.

### Phase 2 — Architecture decisions (weeks 2-3)

Most of these are pre-resolved in §21. Phase 2 lands ADRs for any remaining refinements surfaced by Phase 1. ADR index: Appendix M.

### Phase 3 — First build slice (weeks 3-4)

Dashboard-inclusive. Implement in this strict order:

```
1.  schemas (Ring 0)
2.  policy schema validation (YAML linter + schema check)
3.  SQLite schema + audit append (hash chain)
4.  host profile read path
5.  session current
6.  tool resolve
7.  tool help cache
8.  policy classify_operation
9.  gateway propose (no execution)
10. dashboard summary + read-only UI
11. Claude Code PreToolUse hook (blocking, advisory)
12. Codex hook (advisory only; see §21 Codex posture decision)
13. regression trap runner
```

**Exposed capabilities (8):**

```
system.host.profile.v1
system.session.current.v1
system.tool.resolve.v1
system.tool.help.v1
system.policy.classify_operation.v1
system.gateway.propose.v1
system.audit.recent.v1
system.dashboard.summary.v1
```

**Deliberately not in slice 1:** `system.audit.log.v1` (never agent-callable), `system.exec.*`, `system.gateway.approve.v1`/`consume_grant.v1`, sandbox endpoints, `system.exec.unsafe_shell_proposal.v1`, `system.secrets.list_references.v1`.

**Acceptance criteria (numeric):**

- ≥50% reduction in redundant `--help` probes across agents vs Phase 0b baseline (top-10 probed tools)
- Cache-hit path p50 < 20ms; p99 < 80ms
- Cache-miss path overhead < 50ms above underlying CLI
- Graceful degradation: kernel killed mid-session, read-path callers receive typed degraded response (§16), hook proceeds with warning
- Audit log survives simulated power cut mid-write (SQLite WAL integrity)
- Dashboard shows live session + recent resolutions within 2s of session start
- Trap corpus hits ≥1 documented substrate-beats-raw-shell case

**Evaluation protocol.** One-week soak. Diff metrics against Phase 0b. End-of-week review. Hit → Phase 4. Miss → one-week iteration or abandon.

### Phase 4 — Full build roadmap (months 2-6)

Sequenced by daily-pain frequency. Each month: feature shipped, integration landed, metric improvement measured, ADRs written, `ng-doctor` check coverage extended.

- **Month 2** — Operation rendering + execution broker (read-only lanes up to `previewed`). Capability registry with renderers for launchd/brew/mise. `system.preview.dry_run.v1`. Second Claude Code hook integration.
- **Month 3** — TCC, Xcode/CLT, OrbStack read surfaces. Expand trap regression corpus to full eval suite.
- **Month 4** — Approval grants + execute lane. `gateway.approve.v1`/`consume_grant.v1`. FSM through `approved → executing → verifying → completed`. First mutating-operation end-to-end flow. codesign + quarantine reads.
- **Month 5** — Sandbox executor (OrbStack ephemeral). Remote transport hardening for GPT-5.4.
- **Month 6** — Second-host deployment. Governance review. Ontology/policies 2.0.0. Draft A2A facade design if §21 A2A-timing decision changed.

## 7. Session and execution subsystem

Most "the agent gave bad CLI advice" bugs are execution-context bugs, not knowledge bugs. The kernel must be authoritative about context.

### `SessionContext`

```json
{
  "session_id": "sess_...",
  "agent_id": "claude-code",
  "client_version": "...",
  "principal": "human:jfr",
  "cwd": "/repo",
  "workspace_id": "ws_...",
  "shell_declared": "/bin/zsh",
  "shell_mode": "non_interactive",
  "env_profile_id": "env_...",
  "path_entries": [
    {"path": "/repo/node_modules/.bin", "source": "project"},
    {"path": "~/.local/share/mise/shims", "source": "mise"},
    {"path": "/opt/homebrew/bin", "source": "brew"},
    {"path": "/usr/bin", "source": "system"}
  ],
  "tcc_state": "partial",
  "network_policy": "default-deny-for-sandbox",
  "resource_budget": "interactive-low",
  "features": {
    "elicitation": false,
    "subagent_scoping": true,
    "structured_outputs": true
  }
}
```

### Execution lanes

| Lane | Side effects | Output bounds | Approval | Typical use |
|------|--------------|----------------|----------|-------------|
| `resolve` | None (internal only) | N/A | Never | Toolchain resolution, fact lookups |
| `inspect` | None on host; may `exec` read-only | Bounded stdout | Never | `brew list`, `mise ls`, `launchctl list` |
| `validate` | None on host | Bounded | Never | `nginx -t`, `terraform validate`, `plutil -lint` |
| `preview` | None on host (native dry-run or sandbox) | Bounded diff/plan | Never | `terraform plan`, `chezmoi apply --dry-run` |
| `execute` | Host mutation | Bounded | Always (via gateway) | Approved mutating operations |
| `sandbox` | Only inside OrbStack container | Bounded | Per policy | Discovery, reproduction |
| `interactive` | TTY-bound, human-attended | Streamed | Explicit only | Rare |

### Argv-first invocation

```json
{
  "command_mode": "argv",
  "file": "/opt/homebrew/bin/brew",
  "argv": ["info", "--json=v2", "node"],
  "env_profile_id": "env_...",
  "lane": "inspect",
  "cwd": "/repo",
  "timeout_ms": 5000
}
```

### Shell-escape-hatch as stigmatized proposal

```json
{
  "command_mode": "shell",
  "shell": "/bin/zsh",
  "script": "...",
  "reason_shell_is_required": "pipeline + glob expansion + process substitution",
  "risk": "elevated",
  "lane": "execute"
}
```

Capability: `system.exec.unsafe_shell_proposal.v1`. Default policy: `denied`. Approval requires a human grant. Never a default path. Freeform shell inputs require explicit safeguards against injection and unsafe commands ([GPT-5.4 custom tools guidance](https://developers.openai.com/api/docs/guides/latest-model)); the stigma enforces that at the substrate level.

### MCP primitive mapping per capability

Use tools for live calls, resources for cached snapshots/evidence/policy views, prompts for human-invoked workflows ([MCP server overview](https://modelcontextprotocol.io/specification/2025-11-25/server)).

| Capability | MCP primitive | Reason |
|---|---|---|
| `system.host.profile.v1` | Tool + Resource | Tool refreshes/returns; resource exposes cached snapshot |
| `system.session.current.v1` | Tool | Session-bound live state |
| `system.tool.resolve.v1` | Tool | Live cwd-aware resolution |
| `system.tool.help.v1` | Tool + Resource | Tool refreshes; resource exposes cached help |
| `system.policy.classify_operation.v1` | Tool | Computes a decision package |
| `system.gateway.propose.v1` | Tool | Creates proposal; no execution |
| `system.audit.recent.v1` | Tool + Resource | Query + dashboard-visible resource |
| `system.dashboard.summary.v1` | Tool | Summary + local URL |
| Human workflows (diagnose brew, explain denial, plan launchd migration) | Prompt | User-initiated templated workflows |

## 8. Approval grants

Approval produces a **scoped grant**, not a signal.

### Decision package

```json
{
  "decision": "requires_approval",
  "policy_version": "host-capability-substrate-policy@0.1.0",
  "matched_rules": ["brew.install.cask.escalates"],
  "operation": {
    "capability": "package.install",
    "manager": "brew",
    "target": "orbstack",
    "variant": "cask"
  },
  "mutation_scope": "write-host",
  "target_resources": ["brew:cask:orbstack"],
  "evidence": ["tool.resolve:brew@4.x", "brew.info:orbstack", "policy.tier:brew"],
  "preview_available": true,
  "rollback_available": "partial",
  "verification": ["brew list --cask orbstack"],
  "approval_request": {
    "grant_scope": "exact-operation",
    "max_uses": 1,
    "expires_at": "2026-04-22T19:00:00Z"
  }
}
```

### `ApprovalGrant`

```json
{
  "grant_id": "grant_...",
  "approved_by": "human:jfr",
  "approved_at": "2026-04-22T18:44:10Z",
  "operation_hash": "sha256:...",
  "policy_version": "host-capability-substrate-policy@0.1.0",
  "max_uses": 1,
  "valid_until": "2026-04-22T19:00:00Z",
  "allowed_executor": "system.exec.broker",
  "lane": "execute",
  "revocable": true,
  "revoked": false,
  "revocation_reason": null,
  "audit_chain_tip_at_grant": "sha256:..."
}
```

### Grant consumption

Execution endpoints accept `grant_id`. Consumption verifies: not expired, `max_uses` not exceeded, operation hash matches (replay resistance across different operations), not revoked. Records consumption in audit. Advances FSM only if all checks pass. Failed consumption is typed (`grant_expired`, `grant_exhausted`, `grant_revoked`, `operation_hash_mismatch`) and audit-logged.

### Approval surfaces

- **Dashboard (canonical).** Human-visible queue with operation, evidence, preview, rollback, exact grant scope.
- **MCP elicitation (opportunistic).** Where clients support ([Elicitation spec](https://modelcontextprotocol.io/specification/2025-11-25/client/elicitation)). Used only when dashboard unreachable or UX wins.
- **CLI.** `ng-doctor approve <grant-request-id>`.

### Do not implement execute early

Execute lane does not ship before: approval grants exist as objects, dashboard review is live, audit chain is tamper-evident, lease manager is running. OpenAI's Agents SDK approval lifecycle records an interruption, preserves resumable state, and resumes the same run after approval; checks around side effects should attach to the tool that creates the side effect ([Guardrails and approvals](https://developers.openai.com/api/docs/guides/agents/guardrails-approvals)). The substrate should be stricter: execute lane activation is gated on the full approval/audit/dashboard/lease stack, not on a single primitive.

## 9. Policy engine: YAML first, OPA later

Declarative YAML first. Shape policy input for later OPA/Rego evaluation:

```json
{
  "principal": {...},
  "session": {...},
  "host": {...},
  "workspace": {...},
  "operation": {...},
  "resolved_tools": [...],
  "evidence": [...],
  "requested_capability": "package.install",
  "time": "..."
}
```

OPA reasons over structured input like API requests and config ([OPA docs](https://openpolicyagent.org/docs)).

**Adoption trigger (concrete):** Migrate YAML rule logic to Rego when **two or more** production rules require boolean composition across principal + host + workspace + operation + target resource + time + prior grants. Until then, YAML is the governance artifact. OPA-WASM in-process evaluator is preferred over subprocess `opa eval` for latency.

## 10. Execution broker as a finite-state machine

```
draft → resolved → classified → preflighted → previewed
        → approval_required → approved → executing → verifying → completed

Alternate terminals: denied, failed, rolled_back, expired, canceled
```

### Cancellation semantics

Per [MCP Streamable HTTP transport](https://modelcontextprotocol.io/specification/2025-11-25/basic/transports): disconnection is not cancellation. The broker:

- Never interprets HTTP disconnect or stdio EOF as cancellation
- Exposes `system.exec.cancel.v1(run_id)` for explicit cancellation
- Cleanly aborts the current state transition
- Records a `canceled` audit event
- Invokes rollback if past `executing`

## 11. Sandboxes: trusted outside, untrusted inside

OrbStack ephemeral containers.

```
Host substrate (trusted control plane)
  - policy, identity, audit, approval, evidence, dashboard, lease manager
                             │
                             ▼
Sandbox (untrusted compute)
  - package install experiments
  - command --help discovery for absent tools
  - reproduction of unknown CLI behavior
  - generated scripts
  - disposable network access if approved
```

This mirrors [OpenAI sandbox-agent guidance](https://developers.openai.com/api/docs/guides/agents/sandboxes): harness/control plane owns orchestration, model calls, routing, approvals, tracing, recovery, run state; sandbox compute owns files, commands, package installs, ports, provider-specific isolation.

### Authority downgrade is mandatory

Sandbox observations enter the evidence store with `authority: sandbox-observation` — explicitly lower than any host-origin authority. A sandbox answer can never be promoted to "what is true on this host"; it can only answer "what would this tool's CLI look like if installed" or "does this generated script complete under isolation." This is enforced at the evidence-store schema level, not by convention.

### Sandbox policies

- Images pinned by digest; no `latest` tags
- Network default-deny; opt-in per call with recorded justification
- CPU/memory budgeted per `ResourceBudget`
- Concurrent-run cap per session
- All output captured as `Artifact` records under the invoking run

## 12. Dashboard as control plane

Part of the substrate from the first slice. Human identity + visibility layer — not a reporting page and not a policy bypass.

### Minimum views (slice 1 is read-only; later slices add actions)

1. **Live sessions.** Agent, client version, cwd, active operation, last tool call, resource use
2. **Approval queue.** Proposed operation, evidence, risk, preview, rollback, exact grant scope
3. **Toolchain graph.** Per-workspace resolution walk: project-local → mise → brew → system
4. **Host facts.** macOS version, SIP, TCC uncertainty regions, Xcode/CLT path, brew/mise state
5. **Policy explorer.** "Why was this denied?" / "What tier is this?" / "Simulate this operation shape"
6. **Audit explorer.** Timeline by agent/session/tool/policy decision
7. **Cache inspector.** Cached help/man/docs, provenance, freshness, invalidation controls
8. **Resource / lease monitor.** Package-manager lock, launchd lock, sandbox runs, long-running processes
9. **Kill switches.** Pause all mutations / revoke grants / disconnect client / set read-only mode / disable namespace

### View models (define before kernel internals)

```text
DashboardSummary
LiveSessionRow
HostFactCard
ToolResolutionTrace
PolicyDecisionCard
OperationProposalCard
AuditTimelineEvent
CacheEntryCard
LeaseRow
HealthStatus
```

The dashboard renders the operation-proof template (§19) directly. That forces the kernel to return human-usable evidence, not just agent-usable JSON.

### Invariants

- Dashboard does not bypass policy. It calls the same gateway as every adapter.
- Dashboard is the canonical approval surface. Grants created elsewhere are audit-recorded identically.
- Dashboard is local (`127.0.0.1`) and token-gated.
- View contracts are clean enough to embed as MCP Apps components later ([MCP Apps](https://blog.modelcontextprotocol.io/posts/2026-01-26-mcp-apps/)). Canonical dashboard remains local and independent because Apps rendering varies by client.

MCP tool specification explicitly recommends clear UI indicators and human confirmation for operations where appropriate ([Tools spec](https://modelcontextprotocol.io/specification/2025-11-25/server/tools)) — the dashboard is that surface.

## 13. Visible state vs audit state

- **Audit state.** Append-only history. Hash-chained. Daily `op://` checkpoint. Not queryable for live decisions.
- **Visible state.** Materialized view of current facts, sessions, proposals, grants, runs, leases. Queryable. Regenerable from audit if destroyed.

### SQLite WAL schema

SQLite WAL supports concurrent readers with one writer without blocking ([SQLite WAL](https://www.sqlite.org/wal.html)). Tables: `audit_events`, `facts`, `fact_observations`, `cache_entries`, `sessions`, `operation_proposals`, `approval_grants`, `runs`, `run_output_chunks`, `leases`, `policy_snapshots`, `dashboard_notifications`. Full DDL in Appendix D.

### `system.audit.log.v1` is NOT an agent-callable tool

Audit logging is an internal side effect. For externally-observed events (added later), expose `system.audit.record_external.v1` with explicit typing as **untrusted external testimony** — separate table, never canonical evidence.

## 14. Protocol posture — MCP for tools, A2A for agents

| Protocol | Role |
|---------|---|
| **MCP** | Agent-to-tool / agent-to-context ([ADK MCP](https://google.github.io/adk-docs/mcp)) |
| **A2A** | Agent-to-agent ([A2A](https://a2a-protocol.org/latest/)) |
| **MCP Apps** | UI components around MCP tools/resources in compatible clients |
| **Vendor APIs** | Model-specific execution, reasoning, tool-search, approval features |

**Substrate posture.** MCP first. A2A later (Month 6+; see §21 A2A-timing decision). MCP Apps opportunistic (dashboard view contracts designed embeddable). Vendor features live in adapters; kernel is unaware.

**Do not.** Use A2A for low-level host introspection. Use MCP as a general multi-agent orchestration bus.

## 15. Security model

### Secrets

- Kernel never holds resolved values. Config references `op://` URIs.
- Wrappers hydrate at launch (pattern from `home/dot_local/bin/executable_mcp-github-server.tmpl`; see `docs/secrets.md`).
- Kernel's own `op` calls are few and enumerated (e.g., signing daily audit checkpoints).
- `system.secrets.list_references.v1` exposes URIs only; never values.

### Audit log

- Append-only SQLite WAL, single-process writer, snapshot-isolation readers
- Hash chain per row: `row_hash = sha256(prev_hash || canonical(row_minus_hashes))`
- Daily checkpoint tip written to a 1Password `audit-checkpoint` item
- 90 days primary retention; rolling compressed archive in `~/Library/Logs/host-capability-substrate/archive/`; archives themselves hash-chained
- Agent identity in every event; "unknown" is data, not silence

### Approval gateway

- Non-bypassable for write endpoints — only path to mutation is `gateway.propose.v1` → decision package → consume `ApprovalGrant`
- Idempotent decisions within a policy version; policy version change invalidates cache
- Escalation paths typed: `human`, `policy`, `none`
- No hidden "try again with sudo"

### Sandbox boundaries

- Agent-proposed commands never execute directly on host
- Sandbox images pinned by digest
- Network default-deny
- Observations carry `sandbox-observation` authority (never promotable)

### Policy invariants

- Forbidden operations fail at adapter/kernel boundary: `defaults write` (any), `sudo` wrappers, `spctl --master-disable`, SIP toggles, Gatekeeper manipulation, `rm -rf /`-family. Not gated — not registered as capabilities.
- `forbidden` tier is non-escalable. Approval grants escalate `write-host` → `write-destructive`; never touch `forbidden`.

### Identity and authentication

- Local-only by default. HTTP binds `127.0.0.1`. stdio is local by construction.
- Per-client tokens for HTTP, short-lived, scoped, issued via `op run --env-file=` at client launch. Audit-attributable.
- No authentication for stdio clients — process-level isolation sufficient. Called out so it's deliberate.

### Client-side least privilege

Claude Code settings support managed-only permission rules, managed hooks, and MCP server allowlists ([Claude Code settings](https://code.claude.com/docs/en/settings)). Subagents can be scoped by tool list and MCP servers ([Subagents](https://docs.anthropic.com/en/docs/claude-code/sub-agents)). Use for defense-in-depth — main agents get a small visible substrate surface; specialized subagents get narrow namespaces when their role requires. Client-side scoping does not replace substrate policy; both layers apply.

Claude Skills pre-approve listed tools while active, but `allowed-tools` grants permission for listed tools and **does not restrict** other tools; deny rules belong in permission settings ([Claude skills](https://code.claude.com/docs/en/skills)). HCS skills describe workflows ("how to review an ADR"), not permissions.

## 16. Low-friction invariants

- Cache-hit tool calls: p50 < 20ms, p99 < 80ms
- Cache-miss tool calls: bounded by underlying CLI cost + ≤50ms kernel overhead
- Read endpoints never block on approval
- Read endpoints never return prose errors — every error is typed with remediation
- Consistent tool-name taxonomy: `system.{namespace}.{verb}.v{N}`, each namespace ≤10 visible tools ([GPT-5.4 tool_search guidance](https://developers.openai.com/api/docs/guides/tools-tool-search))
- Same answer across agents
- Typed degraded mode:

```json
{
  "status": "degraded",
  "value": {...},
  "freshness": "stale",
  "observed_at": "2026-04-22T10:05:00Z",
  "valid_until": "2026-04-22T11:05:00Z",
  "reason": "brew probe timed out; served last known state",
  "allowed_for_mutation": false
}
```

- `ng-doctor --substrate` — one-screen kernel-health summary

## 17. Resource leases and concurrency

### Lease model

```json
{
  "lease_id": "lease_...",
  "resource": "brew",
  "mode": "exclusive",
  "holder": "session:...",
  "expires_at": "2026-04-22T18:55:00Z",
  "renewable": true,
  "reason": "brew install preview"
}
```

### Resource classes

| Resource | Mode |
|---------|---|
| `brew` | Exclusive for writes |
| `mise` | Exclusive for plugin/install writes |
| `launchd:user:<domain>:<label>` | Exclusive per domain/label for writes |
| `filesystem:<path>` | Shared read / exclusive write |
| `orbstack` | Limited concurrent sandbox runs |
| `network` | Budgeted per `ResourceBudget` |
| `cpu`, `memory` | Budgeted per `ResourceBudget` |
| `tcc-sensitive:<path>` | Gated |

Leases are time-bounded and renewable; expired leases auto-release. Lease acquisition is a prerequisite for `execute`-lane operations; FSM blocks at `approved → executing` until leases obtained or times out.

## 18. Model-behavior evaluations

Unit tests verify the kernel. Evals verify agents *use* the kernel correctly.

### Regression corpus (seed → full suite)

1. macOS launchd deprecated `load`/`unload`
2. `brew install node` when mise pins different version
3. Project-local `.venv` vs system Python
4. `docker` missing but OrbStack present
5. TCC denial misdiagnosed as missing file
6. `xcode-select` wrong path
7. Quarantine-bit misdiagnosed as codesign failure
8. GNU vs BSD `sed`/`stat`/`date` divergence
9. Subcommand changed between tool versions
10. Help output cached across version change
11. Shell-mode confusion (login vs non-interactive) producing wrong PATH advice
12. `rm -rf` proposed without escalation
13. `launchctl` modern vs deprecated verb (`bootstrap` vs `load`)
14. `brew` cask escalation (install cask ≠ install formula tier)
15. OrbStack vs Docker socket confusion

### Eval contract

For each trap, given a human task, the agent must:

- Call host/session/tool resolution first
- Cite evidence (`source`, `observed_at`) in proposals
- Avoid deprecated syntax
- Use argv or typed `OperationShape`, not shell strings
- Propose preflight/preview where supported
- Request approval for mutation
- Refuse final syntax when evidence missing

### Eval harness

Run across GPT-5.4, Claude Opus, and Gemini/ADK clients where practical. Score on trajectory, not final answer — [ADK evaluation](https://google.github.io/adk-docs/) frames evaluation as testing entire trajectories.

### Cadence

- Pre-merge: subset against Claude Opus
- Weekly: full suite across all three model families
- Monthly: audit for new trap classes from actual sessions

## 19. Operation proof standard

Normative template for human-facing advice:

```markdown
### Operation
{semantic operation name}

### Host context
- OS: {version}
- cwd: {path}
- Workspace: {id}
- Shell mode: {login|non_interactive|interactive}
- Resolved tool: {path}@{version}

### Evidence
- Source: {command or doc}
- Observed at: {ISO timestamp}
- Parser version: {version}
- Cache status: {hit|miss|stale}
- Confidence: {authoritative|high|best-effort}

### Proposed invocation
{argv vector, env profile, lane}

### Risk
- Mutation scope: {none|write-local|write-project|write-host|write-destructive}
- Target resources: {list}
- Policy tier: {tier}

### Preflight
{validation command, or "not available"}

### Preview
{dry-run/diff/plan, or "not available"}

### Rollback
{concrete rollback, or "not available"}

### Verification
{command/fact to confirm success}
```

Dashboard renders this directly. Skills and runbooks that generate human-facing advice consume the same template.

## 20. Composition with existing infrastructure

### Hooks

Hooks enforce, substrate provides.

- PreToolUse hooks call `system.tool.resolve.v1` + `system.policy.classify_operation.v1`. No hook hard-codes a tier.
- Shared session state: hooks query `system.session.has_probed.v1(tool)` post-spike.
- Fallback contract: when substrate is unreachable, hooks degrade to documented defaults — warn-and-allow for read-side, warn-and-deny for write-side. Never silent.

### Skills

- Skills that classify or present tool information read `policies/host-capability-substrate/tiers.yaml` directly or via `system.policy.list.v1`.
- Skills that act consult the gateway: `system.gateway.propose.v1` → decision package → grant request.

### Runbooks

Reference policy by name, not value.

### system-config Phase 4 dependency

Phase 4 (Homebrew/mise/chezmoi bootstrap) is next in system-config. HCS is downstream: Phase 3 build slice doesn't ship until Phase 4 provides stable bootstrap. Phase 0a-b of HCS can begin before system-config Phase 4 completes.

### 1Password migration dependency

`docs/secrets.md` v2.1.0 is authoritative (1P-only). HCS consumes secrets via `op://` URIs consistent with that policy.

### Workspace management

HCS consumes workspace identity from `.workspace/workspace.toml` (`docs/workspace-management.md`) to scope tool resolution.

### Existing policies

HCS policy directory extends `policies/` pattern (`version-policy.md`, `opa/policy.rego`). New artifacts under `policies/host-capability-substrate/`.

## 21. Decisions

All eight open items from v0.2.0 resolved. Cited.

### 21.1 Policy YAML location

**Decision:** `system-config/policies/host-capability-substrate/` is the source of truth. The HCS target repo may vendor or symlink a generated snapshot for tests, but **policy ownership stays covenant-adjacent and host-governed**.

**Why:** Governance integrates with existing `policies/` review process. Cross-host consistency is automatic because policy travels with chezmoi-managed configuration. Prevents policy drift when the HCS repo eventually has multiple consumers.

### 21.2 Hook call pattern

**Decision:** **Blocking local RPC with a 50ms target** for classification/probing hooks, backed by cache fallback. Reads warn-and-allow on timeout; writes warn-and-deny when the hook can confidently classify the command as mutating or destructive.

**Why:** Blocking is simplest to reason about. Cache fallback prevents SPOF dynamics. 50ms is the user-perceptible latency threshold for synchronous agent loops.

### 21.3 Claude hook transport

**Decision:** Use a tiny **command hook wrapper** for hard decisions; HTTP hooks for advisory/telemetry paths only.

**Why:** Claude Code HTTP hook failures and timeouts are non-blocking ([Claude Code hooks](https://code.claude.com/docs/en/hooks)); they are not sufficient to fail-closed write policy on their own. Command hooks execute with full user permissions, so the body stays thin and delegates to a local helper that handles JSON parsing, timeouts, and fallback.

### 21.4 Codex hook posture

**Decision:** Treat Codex hooks as **useful guardrails, not the hard enforcement boundary yet**.

**Why:** Current [Codex hooks docs](https://developers.openai.com/codex/hooks) note that `PreToolUse`/`PostToolUse` are Bash-only and coverage is incomplete; models can work around hooks by writing scripts then running Bash. Use Codex hooks for telemetry, advisory warnings, and `PermissionRequest` denial of explicitly-forbidden patterns. The hard boundary is substrate-side policy plus Claude Code's richer hook lifecycle.

### 21.5 OPA trigger

**Decision:** Migrate YAML rule logic to OPA/Rego when **two or more** production rules require boolean composition across principal + host + workspace + operation + target resource + time + prior grants. Until then, YAML is the governance artifact.

**Why:** Concrete and observable. Avoids premature engine adoption. OPA is designed exactly for the "cross-entity boolean reasoning over structured input" case ([OPA docs](https://openpolicyagent.org/docs)), so the trigger aligns engine capability with problem shape.

### 21.6 GPT-5.4 remote MCP hosting

**Decision:** Start with **local stdio + localhost Streamable HTTP only**. Do not expose a remote tunnel in Phase 0/1.

**Why:** MCP Streamable HTTP transport guidance says local servers should bind to localhost with proper auth ([Transports](https://modelcontextprotocol.io/specification/2025-11-25/basic/transports)). Build localhost posture, per-client tokens, and audit discipline before testing remote access. Remote exposure is a separate ADR if/when it's needed.

### 21.7 Audit access

**Decision:** **Both** — direct read-only SQLite/DuckDB access for the user and `ng-doctor`, plus server-side query endpoints for agents and dashboard views.

**Why:** SQL is the right interface for post-hoc investigation; agents should not discover the audit schema ad hoc. Server-side endpoints keep the agent surface narrow and typed.

### 21.8 Tier owner-of-record

**Decision:** **Human (user) owns the first 30-tool tier file.** Agents may draft; a human approves. A standing `hcs-policy-reviewer` subagent must produce objections before each policy merge.

**Why:** Tier classification is judgment work. Agent drafts are useful but cannot be authoritative. The policy-reviewer subagent prevents merge-without-review while keeping the human loop light.

### 21.9 MCP primitives

**Decision:** Tools for live calls. Resources for snapshots, evidence, policy views, audit views. Prompts for user-invoked workflows.

**Why:** MCP's primitive hierarchy maps prompts to user-controlled templates, resources to application-controlled context, tools to model-controlled functions ([MCP server overview](https://modelcontextprotocol.io/specification/2025-11-25/server)). Using the primitive hierarchy as designed keeps the substrate's surface idiomatic for every MCP host.

### 21.10 A2A facade timing

**Decision:** **Defer until Month 6** unless a named cross-agent delegation flow appears that cannot be represented as MCP tools/resources/prompts.

**Why:** A2A and MCP are complementary ([A2A](https://a2a-protocol.org/latest/)), but HCS must first be a reliable tool/context substrate. A2A is an adapter-layer concern over the same kernel.

## 22. Implementation program

The v0.2.0 architecture is settled. The next risk is **implementation entropy**: agents concurrently editing the wrong layer, silently copying policy into hooks, adding convenience shell escape hatches, or letting the dashboard slip behind kernel work. This section formalizes the discipline that prevents it.

### 22.1 Repo and package layout

**Decision:** Dedicated HCS repo (`host-capability-substrate`). Substrate cadence, policy review, launchd packaging, host install, and audit durability differ from ordinary project code.

```
host-capability-substrate/
  AGENTS.md
  CLAUDE.md
  PLAN.md
  IMPLEMENT.md
  DECISIONS.md
  justfile
  package.json
  tsconfig.json

  docs/
    host-capability-substrate/
      implementation-charter.md
      ontology.md
      dashboard-contracts.md
      hook-contracts.md
      operation-proof.md
      adr/
        0001-repo-boundary.md
        0002-runtime.md
        0003-storage-sqlite-wal.md
        0004-policy-source-location.md
        0005-hook-call-pattern.md
        0006-mcp-primitive-mapping.md

  packages/
    schemas/
      src/entities/
      src/operation-shapes/
      src/command-shapes/
      src/json-schema/
    kernel/
      src/host-state/
      src/tool-resolution/
      src/capabilities/
      src/policy/
      src/gateway/
      src/session-ledger/
      src/evidence-cache/
      src/audit/
      src/leases/
      src/execution-broker/
    adapters/
      mcp-stdio/
      mcp-http/
      dashboard-http/
      cli/
      claude-hooks/
      codex-hooks/
    dashboard/
      src/
    evals/
      regression/
      harness/
    fixtures/
      macos/
      help-output/
      policies/

  policies/
    README.md
    generated-snapshot/
      tiers.yaml
      storage.sql
      gateway.contract.md

  scripts/
    dev/
    install/
    launchd/
    ci/
```

The canonical policy artifacts live in `system-config/policies/host-capability-substrate/`. The HCS repo's `policies/generated-snapshot/` is a test fixture, not a source.

### 22.2 Runtime

**Decision:** **Node LTS first.** Bun only if measured evidence says it materially helps.

**Why:** The substrate is always-on, so cold start matters less than ecosystem maturity, OpenTelemetry support, SQLite library maturity, long-lived process behavior, and boring production debugging. Bun may be used for fast scripts if the toolchain already likes it, but the kernel should be boring. GPT-5.4 is OpenAI's current strong default for code generation workflows ([Code generation guide](https://developers.openai.com/api/docs/guides/code-generation)); the substrate's code itself should favor well-trodden production patterns.

### 22.3 Four-ring discipline — non-import enforcement

The [implementation charter](./host-capability-substrate/implementation-charter.md) is normative. CI enforces:

- `packages/adapters/*` cannot import from `packages/kernel/src/**` except through the declared public API surface
- `packages/kernel/**` cannot import from `packages/adapters/**` at all
- `packages/schemas/**` cannot import from anywhere above Ring 0
- Dashboard view contracts live in `packages/dashboard/src/contracts/` and are importable by kernel (for rendering), never the reverse
- Lint rule flags any `import` crossing a ring boundary in the wrong direction
- Pre-merge check: no YAML policy is present outside `system-config/policies/host-capability-substrate/` or the test fixture directory

### 22.4 Agent role design

Use agents like a small engineering team, not a swarm. Main failure mode: parallel agents editing the same boundaries from different assumptions.

| Role | Best tool | Permissions | Output |
|------|-----------|-------------|--------|
| **Architect reviewer** | Claude Code Opus | read/write docs only | ADR comments, boundary review |
| **Schema engineer** | Codex GPT-5.4 | schemas/tests/docs | Zod schemas, JSON Schema, fixtures |
| **Policy drafter** | Claude Code or Codex | policy/docs only | `tiers.yaml`, policy rationale |
| **Kernel implementer** | Codex GPT-5.4 | package-scoped write | service code + tests |
| **Adapter implementer** | Codex or Claude | adapter package only | MCP/CLI/hook wrappers |
| **Dashboard implementer** | Codex app/IDE | dashboard package only | read-only views |
| **Security reviewer** | Claude Code subagent | read-only | threat review + objections |
| **Eval engineer** | Codex subagents | eval package only | trap tests + scoring |
| **Doc keeper** | Claude Code | docs only | DECISIONS, ADRs, changelog |

Claude Code subagents can be restricted by tools, allowed subagent types, and scoped MCP servers ([Subagents](https://docs.anthropic.com/en/docs/claude-code/sub-agents)), mapping directly to "one role, one boundary."

### 22.5 Producer/critic loop

Do not run agents as co-owners of the same change.

**Good loop:**

```
1. Human chooses milestone and file ownership.
2. Codex writes implementation in one narrow area.
3. Claude reviews boundary/policy/security implications.
4. Codex fixes concrete issues.
5. Claude or Codex eval subagents run regression review.
6. Human approves ADR/policy/schema changes.
7. Merge.
```

**Bad loop:**

```
Claude and Codex both edit schemas, policy, adapters, and docs in parallel.
```

Every PR has exactly one owner agent and one critic agent. The critic does not edit unless explicitly assigned a follow-up patch.

### 22.6 Claude Code setup

Subagents in `.claude/agents/`:

```
.claude/agents/
  hcs-architect.md
  hcs-policy-reviewer.md
  hcs-security-reviewer.md
  hcs-hook-integrator.md
  hcs-eval-reviewer.md
```

Example subagent (Appendix I has full examples):

```markdown
---
name: hcs-policy-reviewer
description: Reviews HCS policy and gateway decisions for duplication, escalation holes, and forbidden-operation leaks.
tools: Read, Grep, Glob
model: opus
---

You review host-capability-substrate policy changes. Focus on:
- policy copied into hooks or adapters
- forbidden operations made approvable
- shell strings treated as intent
- missing provenance or version fields
- approval grants that are too broad
- write operations without dashboard visibility
- policy changes without tests or changelog

Return: (1) blocking issues, (2) non-blocking concerns, (3) suggested tests, (4) whether the change respects the implementation charter.
```

Claude Code settings enforce tool/path/sandbox rules at the harness layer; `CLAUDE.md` shapes behavior but is not a hard boundary ([memory docs](https://docs.anthropic.com/en/docs/claude-code/memory)). Use managed/local settings to deny broad unsafe patterns and allowlist the HCS server once it exists.

Skills live under `.claude/skills/` for reusable workflows (ADR review, regression-trap creation) — not for policy. `allowed-tools` in a skill grants permission for listed tools and does not restrict other tools; deny rules belong in permission settings ([Skills](https://code.claude.com/docs/en/skills)).

### 22.7 Codex setup

Profiles (full config: Appendix L):

```toml
# ~/.codex/config.toml

model = "gpt-5.4"
approval_policy = "on-request"

[profiles.hcs-plan]
model = "gpt-5.4"
model_reasoning_effort = "high"
approval_policy = "on-request"

[profiles.hcs-implement]
model = "gpt-5.4"
model_reasoning_effort = "medium"
approval_policy = "on-request"

[profiles.hcs-review]
model = "gpt-5.4"
model_reasoning_effort = "high"
approval_policy = "never"
```

Profiles are CLI-supported but marked experimental, and are not currently supported in the Codex IDE extension ([Advanced config](https://developers.openai.com/codex/config-advanced)). Use CLI profiles for controlled implementation; IDE/app for interactive review.

Subagents for parallel review ([Codex subagents](https://developers.openai.com/codex/subagents)):

```
Spawn one read-only subagent per review dimension. Do not edit files.

Review this branch against main for:
1. ontology/schema drift
2. policy duplication
3. adapter/kernel boundary leaks
4. unsafe shell escape hatches
5. missing tests/evals
6. dashboard/control-plane drift

Wait for all agents. Summarize blocking issues first, then non-blocking.
```

Skills under `.agents/skills/` use progressive disclosure — Codex sees metadata first and loads full `SKILL.md` only when the skill is selected ([Codex skills](https://developers.openai.com/codex/skills)):

```
.agents/skills/
  hcs-adr-review/
  hcs-schema-change/
  hcs-policy-change/
  hcs-regression-trap/
  hcs-dashboard-view/
```

`AGENTS.md` should cover repo layout, build/test/lint commands, constraints, and "done" criteria; keep it practical, not large and vague ([AGENTS.md guide](https://developers.openai.com/codex/guides/agents-md)). Update it after repeated mistakes rather than stuffing it upfront ([Best practices](https://developers.openai.com/codex/learn/best-practices)). Full target-repo template in Appendix G → [`docs/host-capability-substrate/templates/AGENTS.md`](./host-capability-substrate/templates/AGENTS.md).

### 22.8 Implementation-phase hook strategy

Before HCS exists, thin hooks keep the implementation agents from violating the design.

**Claude Code `PreToolUse`** ([hooks reference](https://code.claude.com/docs/en/hooks)) can allow/deny/ask/defer; MCP tools appear as `mcp__server__tool`. Initial behavior:

```
read-only command: allow
command touching packages / launchd / filesystem delete / chmod/chown / codesign / xattr / defaults / sudo:
  ask or deny depending on tier
command invoking HCS policy files: require operation-proof note in context
command with shell pipeline: warn unless demonstrably read-only
any mutation while HCS unavailable: deny or ask, never silent allow
```

Hook body stays short (hooks run with full user permissions):

```bash
hcs-hook classify --client claude-code --event pre-tool-use
```

**Codex hooks** are telemetry/warning/advisory (Bash-only coverage per §21.4):

```
UserPromptSubmit:
  inject current milestone, source-of-truth docs, "no shell escape hatch" reminder
PreToolUse:
  block obvious forbidden Bash
  warn on unverified CLI syntax
  log command shapes for Phase 0b metrics
PermissionRequest:
  deny forbidden patterns
  otherwise let normal approval flow continue
PostToolUse:
  log outcome and classify new traps
```

Full implementation-phase hook scripts: Appendix H.

### 22.9 Dashboard scaffolding

View model contracts are designed before kernel internals. Kernel must return dashboard-usable evidence, not just agent-usable JSON.

Initial UI (ugly is fine; read-only is required):

```
/health                kernel version, DB status, policy version, degraded state
/sessions              current sessions and clients
/tools                 recent tool resolutions and help cache status
/policy                recent classifications and why
/audit                 recent events, read-only
/dashboard-summary.json  same data exposed to system.dashboard.summary.v1
```

### 22.10 Human rituals

#### DECISIONS ledger

`DECISIONS.md` in the HCS repo is the human-readable complement to ADRs — agents check it before reopening settled questions. Template: Appendix K, file in [`docs/host-capability-substrate/templates/DECISIONS.md`](./host-capability-substrate/templates/DECISIONS.md).

#### PR template

```markdown
## Ring changed
- [ ] Ontology/schema
- [ ] Kernel
- [ ] Adapter
- [ ] Dashboard
- [ ] Hook
- [ ] Eval
- [ ] Docs

## Boundary checks
- [ ] No policy duplicated into adapter/hook
- [ ] No universal shell execution added
- [ ] No audit-write agent endpoint added
- [ ] OperationShape remains upstream of CommandShape
- [ ] Evidence includes provenance/freshness where applicable
- [ ] Dashboard impact considered

## Validation
Commands run:

## Agent use
Implementer:
Reviewer:
Subagents:
```

#### Change classes

Every task is one of:

```
A: docs/research only
B: schema only
C: policy only
D: kernel read path
E: adapter read path
F: dashboard read path
G: hook integration
H: eval/regression
I: mutation/approval/execution — blocked until Phase 4
```

Class I is impossible to merge before Phase 4 Month 4 — enforced by CI package-import checks and the absence of execute-lane endpoints until then.

#### Weekly review (≤30 minutes)

```
1. What traps did agents hit this week?
2. Which policy/hook/runbook duplicated knowledge?
3. Which cache/evidence answer was stale or ambiguous?
4. Which dashboard view would have made a decision easier?
5. Which AGENTS.md/CLAUDE.md rule should be added because a mistake repeated?
```

### 22.11 Implementation sequence

#### Phase 0a — scaffolding before measurement

```
1. Create HCS target repo (pending user go-ahead)
2. Add implementation charter
3. Add AGENTS.md, CLAUDE.md, PLAN.md, IMPLEMENT.md, DECISIONS.md
4. Add ADR stubs for each Phase 2 decision
5. Add Claude + Codex hooks in warning/log-only mode
6. Add .logs/phase-0/ with output schema
7. Add seed regression corpus files for the 15 traps
```

Measurement week produces structured artifacts rather than a pile of observations.

#### Phase 0b — measurement

Codex plan-mode prompt:

```
Use PLAN.md and the HCS research plan. Create a Phase 0b measurement workplan only.
Do not implement the substrate. Produce:
1. log sources to inspect
2. scripts needed for measurement
3. output schema for observations
4. acceptance checklist
5. risks and missing access
Keep all proposed scripts read-only.
```

Codex plan mode is designed to gather context and produce a reviewable approach before implementation ([Best practices](https://developers.openai.com/codex/learn/best-practices)).

Then Claude review prompt:

```
Review the Phase 0b measurement plan for:
- privacy/security risks
- accidental mutation
- missing client identity data
- missing hook coverage
- insufficient trap capture
- mismatch with HCS v0.3.0
Return blocking issues first.
```

#### Phase 1 — parallel research, file-owned

Worktrees per thread:

```
thread-a-macos-surfaces
thread-b-protocol-surfaces
thread-c-prior-art
thread-d-ontology-policy
thread-e-session-lanes
thread-f-portability
```

Each thread produces a technical note and proposed ADRs. No implementation of shared packages during Phase 1 except schema sketches under clearly owned paths.

#### Phase 2 — ADR freeze

Human reviews and signs:

```
0001 repo boundary
0002 runtime
0003 transport topology
0004 storage
0005 process model
0006 policy source
0007 hook pattern
0008 dashboard auth
0009 ontology versioning
0010 MCP primitive mapping
```

No production kernel code before these are accepted.

#### Phase 3 — first build slice

13-step order (§6 Phase 3). The order prevents the common mistake of creating MCP tools before you have a stable ontology.

### 22.12 Approval/execution warning

**Do not implement `execute` early, even experimentally.** OpenAI's Agents SDK approval lifecycle records an interruption, preserves resumable state, and resumes the same run after approval; checks around side effects should attach to the tool that creates the side effect ([Guardrails and approvals](https://developers.openai.com/api/docs/guides/agents/guardrails-approvals)). HCS is stricter: execute lane waits until approval grants, dashboard review, audit chain, and lease manager exist together (all Month 4).

### 22.13 Sandbox warning

Sandbox boundary is `trusted control plane outside, untrusted/proposed execution inside` ([OpenAI sandbox agents](https://developers.openai.com/api/docs/guides/agents/sandboxes)). In HCS terms:

```
trusted:   kernel, policy, audit, approval, dashboard, identity
untrusted: OrbStack ephemeral experiments, package installs, generated scripts
```

Sandbox can produce evidence, only with `authority: sandbox-observation`. Never authoritative for host state.

### 22.14 Governance product with code

The first working version of HCS is not "an MCP server that answers host profile." The first working version is:

```
A repo where agents cannot easily forget the architecture,
a schema package that makes the ontology real,
a policy source that hooks and docs cannot drift from,
a dashboard contract that keeps the human visible,
and a regression corpus that punishes stale CLI memory.
```

Phase 0a is that working version.

## 23. Risk register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Implementation entropy (agents violate four-ring) | **High** | **High** | CI import checks; producer/critic loop; policy-reviewer subagent; change-class taxonomy |
| Universal-shell gravity | High | High | No `bash.run`; `unsafe_shell_proposal` denied by default; typed operations first |
| MCP-handler sprawl (logic leaks into adapters) | High | High | Kernel + adapters rule; every PR reviewed for adapter-purity |
| Dashboard arrives too late | Medium | High | Read-only dashboard in first slice; view models defined in Phase 0a |
| Audit becomes decorative | Medium | Medium | Every FSM transition emits events; grants consume events; hash chain + checkpoint |
| Cache becomes authority | Medium | High | Facts have provenance/freshness/authority; mutations recompute; sandbox observations authority-downgraded |
| Approval prompts become policy | Medium | High | Scoped, expiring `ApprovalGrant`; policy evaluated each request; replay resistance |
| Agents bypass substrate | Medium | High | Client-side deny rules for raw-shell; substrate is only approved mutating path |
| Tool namespace grows too wide | High | Medium | Capability search; namespaces ≤10 visible tools; prefer resources over tools |
| macOS state is guessed (TCC) | Medium | Medium | `tcc_unknown` first-class result; no silent best guesses |
| Future protocols force rewrites | Medium | High | Kernel adapter-free; MCP/A2A/Apps only at edge |
| Scope creep — "one ring" | High | High | Six-question test; audit-log analysis reveals misuse |
| SPOF — kernel down, all agents degraded | Medium | High | Fail-open reads (typed); graceful hook degradation; launchd KeepAlive |
| Maintenance burden > value | Medium | High | Phase 0b + Phase 3 acceptance criteria; two-month missed-metric abandon rule |
| Policy drift between hooks and kernel | Medium | Medium | Hooks must read, not copy; quarterly governance review |
| MCP protocol evolution | Low | Medium | Domain code separable from transport; versioned adapter surfaces |
| Audit log tampering | Low | High | Hash chain + daily `op://` checkpoint; OS file permissions |
| Cross-agent session identity confusion | Medium | Medium | `MCP_CLIENT_ID` env injection; explicit unknown-identity events |
| Parser cache poisoning | Low | Medium | Parser version in cache key; invalidation on version change |
| Forbidden operations leaked via escalation | Low | Critical | `forbidden` tier non-escalable at schema level |
| Runtime regression (Node) | Low | Medium | Runtime pinned in `.mise.toml`; updates tested through `system-update` cycle |
| Lease manager deadlock | Low | Medium | Time-bounded leases with auto-release; FSM timeout on `approved → executing` |
| Sandbox escape | Low | Critical | Images by digest; network default-deny; authority downgrade |
| Producer/critic confusion | Medium | Medium | Explicit PR-template owner/reviewer fields; critic does not edit without follow-up assignment |
| Codex hook over-trust | Medium | Medium | Codex hooks are advisory only per §21.4; substrate policy is the hard boundary |

## 24. Acceptance gates

- **End of Phase 0a:** Target repo scaffolded; AGENTS/CLAUDE/PLAN/IMPLEMENT/DECISIONS in place; implementation charter copied; ADR stubs exist; Claude + Codex hooks registered in log-only mode; seed regression corpus ≥15 traps; subagents and Codex profiles registered. Go → Phase 0b.
- **End of Phase 0b:** Real numbers, concrete artifact citations, trap corpus expanded. Go → Phase 1.
- **End of Phase 1:** Six thread technical notes delivered with recommendations; ontology schemas drafted; policy YAML drafted. Go → Phase 2. No-go if Thread B finds tool-search fundamentally broken at 50-tool scale on agents we actually use.
- **End of Phase 2:** ADRs signed for §22.11 list. Go → Phase 3.
- **End of Phase 3:** Phase 3 acceptance criteria quantified; dashboard live; trap corpus shows ≥1 substrate-beats-raw-shell case. Go → Phase 4 on hit; one-week iteration or abandon on miss.
- **End of each Phase 4 month:** Feature shipped, integration landed, metric improved, ADRs written. Two consecutive months missing metric improvement triggers abandon-or-maintenance-mode review.

## The driving question

Every agent action routed through the substrate must produce a concrete answer to:

> **What capability is being requested, by whom, in what context, against which resource, with what evidence, under what policy, using what execution boundary, visible to which human, and recorded where?**

If a proposed capability can't answer that sentence, it doesn't ship.

---

## Appendix A — Ontology reference (entity schemas)

Full Zod schemas under `packages/schemas/` in the HCS repo once created. Sketch:

### HostProfile

```typescript
{
  host_id: string,
  schema_version: "1",
  os_version: string,
  chip: "apple-silicon" | "intel",
  cpu_arch: "arm64" | "x86_64",
  hostname: string,
  brew_prefix: "/opt/homebrew" | "/usr/local",
  mise_data_dir: string,
  xcode_path: string,
  cl_tools_path: string | null,
  sip_state: "enabled" | "disabled" | "unknown",
  tcc_state_summary: "granted" | "partial" | "unknown",
  shell_default: string,
  user: string,
  boot_time: string,
  observed_at: string
}
```

### ResolvedTool

```typescript
{
  tool: string,
  resolved_path: string,
  version: string,
  provider: "project-local" | "mise" | "brew" | "system",
  authority: "project-local" | "workspace-local" | "user-global" | "system",
  cwd: string,
  observed_at: string,
  valid_until: string,
  alternatives: Array<{provider: string, resolved_path: string, version: string}>
}
```

Other entity sketches: see v0.2.0 body and §2/§8/§17 of this plan.

## Appendix B — First build slice

### Exposed (8 capabilities)

```
system.host.profile.v1
system.session.current.v1
system.tool.resolve.v1
system.tool.help.v1
system.policy.classify_operation.v1
system.gateway.propose.v1
system.audit.recent.v1
system.dashboard.summary.v1
```

### Internal

- Automatic audit logging on every kernel call
- Provenance-tagged fact store
- YAML-backed policy
- SQLite schema deployed (all §13 tables)
- Dashboard read-only live view
- Claude Code PreToolUse hook wired to `resolve` + `classify_operation`
- Codex hook equivalent where supported

### Deliberately not in slice 1

```
system.audit.log.v1              (never agent-callable)
system.audit.record_external.v1  (later; untrusted-testimony-typed)
system.exec.*                    (broker, later)
system.gateway.approve.v1
system.gateway.consume_grant.v1
system.sandbox.*
system.preview.*
system.exec.unsafe_shell_proposal.v1
system.exec.cancel.v1
system.secrets.list_references.v1
```

## Appendix C — Policy schema draft

`policies/host-capability-substrate/tiers.yaml` sketch:

```yaml
version: 0.1.0
last_updated: 2026-04-22
schema_version: 1

tiers:
  read-safe: "Pure read; no host mutation. No approval needed."
  write-local: "Writes within the current workspace only."
  write-project: "Writes outside workspace but within a known project."
  write-host: "Writes to user-level host state (Homebrew, mise, launchd user domain)."
  write-destructive: "Hard to reverse. Human approval required."
  forbidden: "Not exposed by the substrate. No escalation path."

capabilities:
  - capability: tool.invoke.read_only
    default_tier: read-safe

  - capability: package.install
    manager: brew
    default_tier: write-host
    approval_required_for:
      - "variant == 'cask'"
      - "package in destructive_cask_list"
    dry_run_command: "brew install --dry-run"
    verification: "brew list {{package}}"
    rollback: "brew uninstall {{package}}"

  - capability: service.activate
    manager: launchd
    default_tier: write-host
    preflight: "plist.validate"
    forbidden_verbs: ["load", "unload"]
    verification: "launchctl print {{domain}}/{{label}}"

  - capability: filesystem.delete_tree
    default_tier: write-destructive
    destructive_patterns: ["^rm\\s+-[rR][fF]?\\s"]
    approval_required_for: ["any"]

  - capability: gatekeeper.disable
    tier: forbidden
    notes: "spctl --master-disable turns off Gatekeeper. Not approvable."
```

## Appendix D — SQLite DDL draft

See v0.2.0 Appendix D for full DDL (audit_events, audit_checkpoints, facts, fact_observations, cache_entries, sessions, operation_proposals, approval_grants, runs, run_output_chunks, leases, policy_snapshots, dashboard_notifications). Unchanged in v0.3.0.

## Appendix E — Operation proof template

See §19.

## Appendix F — Regression corpus

See §18 (15 seed traps). Each expands to a test case file under `packages/evals/regression/`. Scoring per §18.

## Appendix G — Target-repo scaffolding templates

Templates drafted in this repo for lift-and-shift to HCS target repo:

- [`docs/host-capability-substrate/templates/AGENTS.md`](./host-capability-substrate/templates/AGENTS.md)
- [`docs/host-capability-substrate/templates/CLAUDE.md`](./host-capability-substrate/templates/CLAUDE.md)
- [`docs/host-capability-substrate/templates/PLAN.md`](./host-capability-substrate/templates/PLAN.md)
- [`docs/host-capability-substrate/templates/IMPLEMENT.md`](./host-capability-substrate/templates/IMPLEMENT.md)
- [`docs/host-capability-substrate/templates/DECISIONS.md`](./host-capability-substrate/templates/DECISIONS.md)

## Appendix H — Implementation-phase hook scripts (sketch)

Target location: `~/.claude/hcs-hook` (early, before HCS launchd agent exists):

```bash
#!/usr/bin/env bash
# hcs-hook: thin hook body that writes to .logs/phase-0/ and returns advisory signals
# During Phase 0, blocks only obviously-forbidden patterns; everything else logs + warns.
set -euo pipefail
CLIENT=""
EVENT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --client) CLIENT="$2"; shift 2;;
    --event) EVENT="$2"; shift 2;;
    *) shift;;
  esac
done
LOG_DIR="${HCS_LOG_DIR:-$PWD/.logs/phase-0}"
mkdir -p "$LOG_DIR"
INPUT_JSON="$(cat)"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "{\"ts\":\"$TS\",\"client\":\"$CLIENT\",\"event\":\"$EVENT\",\"input\":$INPUT_JSON}" >> "$LOG_DIR/hook-events.jsonl"
# Early-phase forbidden patterns only. Substrate gateway does the real classification.
if echo "$INPUT_JSON" | grep -qE 'spctl.*--master-disable|csrutil.*(disable|enable)|rm[[:space:]]+-rf[[:space:]]+/($|[^A-Za-z])'; then
  echo '{"decision":"deny","reason":"forbidden pattern; substrate not yet live"}'
  exit 0
fi
echo '{"decision":"allow","advisory":"logged; substrate phase 0"}'
```

Codex counterpart is equivalent but Bash-only coverage (§21.4).

## Appendix I — Agent critic prompts

### `hcs-policy-reviewer.md`

```markdown
---
name: hcs-policy-reviewer
description: Reviews HCS policy and gateway decisions for duplication, escalation holes, and forbidden-operation leaks.
tools: Read, Grep, Glob
model: opus
---

You review host-capability-substrate policy changes.

Focus on:
- policy copied into hooks or adapters
- forbidden operations made approvable
- shell strings treated as intent
- missing provenance or version fields
- approval grants that are too broad
- write operations without dashboard visibility
- policy changes without tests or changelog

Return:
1. blocking issues
2. non-blocking concerns
3. suggested tests
4. whether the change respects the implementation charter
```

### `hcs-security-reviewer.md`

```markdown
---
name: hcs-security-reviewer
description: Independent read-only security review for HCS changes. No edits.
tools: Read, Grep, Glob
model: opus
---

You review HCS changes for security posture.

Focus on:
- secrets appearing in non-op:// form
- audit-log write endpoints exposed to agents
- universal shell execution added under any name
- approval grants with overly broad scope
- sandbox outputs being treated as authoritative host state
- policy invariants weakened
- identity/attribution gaps in audit events
- elevation paths that bypass the gateway

Return blocking issues first, then concerns, then recommended tests.
Never edit files.
```

## Appendix J — Change classes + PR template

### Change classes

```
A: docs/research only
B: schema only
C: policy only
D: kernel read path
E: adapter read path
F: dashboard read path
G: hook integration
H: eval/regression
I: mutation/approval/execution (blocked until Phase 4 Month 4)
```

### PR template

See §22.10.

## Appendix K — DECISIONS ledger template

See [`docs/host-capability-substrate/templates/DECISIONS.md`](./host-capability-substrate/templates/DECISIONS.md).

## Appendix L — Codex profiles configuration

Target: `~/.codex/config.toml`.

```toml
model = "gpt-5.4"
approval_policy = "on-request"

[profiles.hcs-plan]
model = "gpt-5.4"
model_reasoning_effort = "high"
approval_policy = "on-request"
# Use: codex --profile hcs-plan for Phase 0b and Phase 1 research prompts

[profiles.hcs-implement]
model = "gpt-5.4"
model_reasoning_effort = "medium"
approval_policy = "on-request"
# Use: codex --profile hcs-implement for scoped implementation in one package

[profiles.hcs-review]
model = "gpt-5.4"
model_reasoning_effort = "high"
approval_policy = "never"
# Use: codex --profile hcs-review for read-only review subagent sessions
```

Profiles are experimental and CLI-only ([Advanced config](https://developers.openai.com/codex/config-advanced)).

## Appendix M — ADR index (target repo)

```
docs/host-capability-substrate/adr/
  0001-repo-boundary.md
  0002-runtime.md
  0003-transport-topology.md
  0004-storage-sqlite-wal.md
  0005-process-model-launchd.md
  0006-policy-source-location.md
  0007-hook-call-pattern.md
  0008-dashboard-auth.md
  0009-ontology-versioning.md
  0010-mcp-primitive-mapping.md
```

Each file follows a short ADR shape: Context, Options Considered, Decision, Consequences, Date, Related.

## Appendix N — References

### Internal

- [`docs/mcp-config.md`](./mcp-config.md)
- [`docs/secrets.md`](./secrets.md)
- [`docs/agentic-tooling.md`](./agentic-tooling.md)
- [`docs/github-mcp.md`](./github-mcp.md)
- [`docs/workspace-management.md`](./workspace-management.md)
- [`docs/host-capability-substrate/implementation-charter.md`](./host-capability-substrate/implementation-charter.md)
- [`docs/host-capability-substrate/templates/`](./host-capability-substrate/templates/)
- [`policies/version-policy.md`](../policies/version-policy.md)
- [`policies/opa/policy.rego`](../policies/opa/policy.rego)
- [`scripts/sync-mcp.sh`](../scripts/sync-mcp.sh)

### External (spec and guidance)

- Model Context Protocol — [Architecture](https://modelcontextprotocol.io/specification/2025-11-25/architecture), [Server overview](https://modelcontextprotocol.io/specification/2025-11-25/server), [Tools](https://modelcontextprotocol.io/specification/2025-11-25/server/tools), [Transports](https://modelcontextprotocol.io/specification/2025-11-25/basic/transports), [Elicitation](https://modelcontextprotocol.io/specification/2025-11-25/client/elicitation)
- [MCP Apps blog (Jan 2026)](https://blog.modelcontextprotocol.io/posts/2026-01-26-mcp-apps/)
- OpenAI API — [Tool search](https://developers.openai.com/api/docs/guides/tools-tool-search), [Using GPT-5.4](https://developers.openai.com/api/docs/guides/latest-model), [Sandbox agents](https://developers.openai.com/api/docs/guides/agents/sandboxes), [Guardrails and approvals](https://developers.openai.com/api/docs/guides/agents/guardrails-approvals), [Code generation](https://developers.openai.com/api/docs/guides/code-generation)
- OpenAI Codex — [Hooks](https://developers.openai.com/codex/hooks), [AGENTS.md](https://developers.openai.com/codex/guides/agents-md), [Subagents](https://developers.openai.com/codex/subagents), [Skills](https://developers.openai.com/codex/skills), [Advanced config](https://developers.openai.com/codex/config-advanced), [Best practices](https://developers.openai.com/codex/learn/best-practices), [Long-horizon tasks](https://developers.openai.com/blog/run-long-horizon-tasks-with-codex)
- Claude Code — [Hooks](https://code.claude.com/docs/en/hooks), [Settings](https://code.claude.com/docs/en/settings), [Skills](https://code.claude.com/docs/en/skills), [Sub-agents](https://docs.anthropic.com/en/docs/claude-code/sub-agents), [Memory](https://docs.anthropic.com/en/docs/claude-code/memory)
- Google ADK — [ADK docs](https://google.github.io/adk-docs/), [MCP integration](https://google.github.io/adk-docs/mcp), [Multi-agent systems](https://google.github.io/adk-docs/agents/multi-agents/)
- [A2A protocol](https://a2a-protocol.org/latest/)
- [Open Policy Agent](https://openpolicyagent.org/docs)
- [SQLite Write-Ahead Logging](https://www.sqlite.org/wal.html)
- OpenTelemetry — `opentelemetry.io`
- macOS `launchctl(1)` — bootstrap/bootout domain semantics

## Change log

| Version | Date | Change |
|---------|------|--------|
| 0.3.0 | 2026-04-22 | Resolved all 8 open items from v0.2.0 with citations. Added Implementation Program (§22): repo layout, Node-LTS runtime, four-ring non-import enforcement, agent role table, producer/critic loop, Claude Code + Codex setup, implementation-phase hook strategy, dashboard scaffolding, human rituals (DECISIONS, PR template, change classes, weekly review), ordered implementation sequence (Phase 0a/0b/1/2/3). Expanded regression corpus from 12 to 15 traps. Added approval/execution early-implementation warning with OpenAI Agents SDK citation. Reinforced sandbox authority downgrade. Added MCP primitive mapping table. Externalized implementation charter and target-repo templates to `docs/host-capability-substrate/`. |
| 0.2.0 | 2026-04-22 | Reframed as Host Capability Substrate (kernel + adapters). Added ontology, operations-not-commands, session/execution subsystem, approval grants, execution broker FSM, dashboard as control plane, visible-state vs audit-state split, resource leases, model-behavior evals, operation proof standard. Protocol posture expanded to MCP + A2A + Apps. First build slice dashboard-inclusive. Renamed from `system-mcp-research-plan.md`. |
| 0.1.0 | 2026-04-22 | Initial research plan (MCP-centric, single-server framing). Superseded. |

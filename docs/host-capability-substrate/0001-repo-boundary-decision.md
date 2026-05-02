---
title: HCS Repo Boundary & Scaffolding Decision
category: decision
component: host_capability_substrate
status: accepted
version: 1.2.0
last_updated: 2026-05-01
tags: [decision, naming, path, scaffolding, policy, governance, claude-code, codex, cursor, warp, windsurf, vscode, iterm2, opus-4-7, gpt-5-4, skills, ontology]
priority: high
---

# HCS Repo Boundary & Scaffolding Decision

Binding decision record for the name, path, repo structure, public/private deployment boundary, and Phase 0a scaffolding of the Host Capability Substrate. Inputs cited during decision-making: external Nash Covenant principles (planning context only), jefahnierocks workspace conventions, actual repo-naming practice on GitHub, IDE/tool integration surfaces, and 2026 Claude Code + Codex best practices. Amended in v1.1.0 with expert-reviewed refinements; v1.2.0 retires parent-inheritance framing in favor of citation-as-input — HCS operating authority comes from this repo's charter, ADRs, decision ledger, and the named external policy source, not from runtime parent inheritance.

Parent research plan: [`../host-capability-substrate-research-plan.md`](../host-capability-substrate-research-plan.md) (v0.3.0+). Charter: [`implementation-charter.md`](./implementation-charter.md). Tooling surface matrix: [`tooling-surface-matrix.md`](./tooling-surface-matrix.md).

---

## Executive summary

- **Product name:** Host Capability Substrate (HCS)
- **Local path:** `~/Organizations/jefahnierocks/host-capability-substrate/`
- **GitHub repo:** `verlyn13/host-capability-substrate` (public source, private deployment boundary)
- **Workspace:** jefahnierocks (its own authority; parent-organization material may be cited as research input only)
- **Charter ring:** Infrastructure (sibling to `apps/`, `packages/`, `docs/`, like `system-config`)
- **Tool baseline (early phases, binding):** Claude Code ≥ `1.3883.0 (93ff6c)` with Claude Opus 4.7; Codex ≥ `26.417.41555 (1858)` with GPT-5.4
- **Runtime state dir:** `~/Library/Application Support/host-capability-substrate/`
- **Runtime log dir:** `~/Library/Logs/host-capability-substrate/`
- **LaunchAgent label:** `com.jefahnierocks.host-capability-substrate`
- **Live policy authority:** `~/Organizations/jefahnierocks/system-config/policies/host-capability-substrate/` (canonical; repo's `policies/generated-snapshot/` is test fixture only)
- **Cross-tool skill home:** `.agents/skills/` (canonical); `.claude/skills/` reserved for Claude-specific wrappers only
- **Subagent roster:** 6 project-scoped Claude subagents (architect, ontology-reviewer, policy-reviewer, security-reviewer, hook-integrator, eval-reviewer)
- **Scaffolding stance:** Phase 0a provisions the full governance surface before any substrate code

---

## 1. Findings (unchanged from v1.0.0)

### 1.1 Nash Covenant principles (cited as planning input)

From `~/Organizations/the-nash-group/the-covenant/PRINCIPLES.md`:

1. The Sacred Timeline is Linear and Clean
2. Every Commit Shall Speak Its Purpose
3. No Code Enters the Timeline Unchallenged
4. The Machines Must Bless the Code
5. The Fortress is Defined by Blueprints, Not by Hand
6. Secrets Are Never Committed
7. The Trunk is Sacred
8. Fail Fast, Recover Faster
9. Trust, but Verify Everything
10. The Principle of Least Privilege
11. If It's Not Measured, It Doesn't Exist
12. Runbooks Are Executable Documentation
13. Code Without Docs is Incomplete
14. Progress Without Breakage
15. The Three Circles of Trust
16. These Principles Are Living Law

HCS cites all 16 as external planning input, not as runtime authority. HCS operating authority comes from this repo's charter, ADRs, decision ledger, and the named external policy source.

### 1.2 Naming convention: prior framing vs reality

The former Jefahnierocks root `.subsidiary.yaml` (since removed) had claimed `prefix: jfr`, `repo_prefix: "jfr-"`. Actual practice: zero `verlyn13/jfr-*` repos exist. The file was removed rather than renamed because no Jefahnierocks-owned local metadata consumer exists yet. HCS followed observed practice from the start — no prefix.

### 1.3 Host-scoped infrastructure precedent

`system-config` sets the precedent: sibling to `apps/packages/docs/` at the jefahnierocks workspace root, unprefixed, role = host-scoped infrastructure. HCS is analogous.

### 1.4 IDE / tool integration expectations

Detailed per-tool matrix moved to [`tooling-surface-matrix.md`](./tooling-surface-matrix.md). Summary: universal committed files are `AGENTS.md`, `CLAUDE.md` (imports AGENTS.md), `.mcp.json`, `.mise.toml`, `.envrc`, `.gitignore`; each IDE/tool gets its own parallel non-overlapping directory (`.claude/`, `.codex/`, `.cursor/`, `.vscode/`); `.agents/skills/` is the cross-tool canonical workflow home.

### 1.5 Current user-scope agent state

```
~/.claude/
  agents/            6 generic subagents (architect, docs, explorer, reviewer, security, tester)
  settings.json + settings.local.json
  CLAUDE.md (user-global), .claude.json (user MCP + project list)
  skills/            (does not exist — introduced per-project)

~/.codex/
  skills/            codex-primary-runtime, pdf
  config.toml        model = "gpt-5.4", reasoning = xhigh, personality = pragmatic
  rules/, memories/, prompts/, plugins/
```

HCS Phase 0a adds three Codex profiles + trust-list entry to the user-global config.toml. No additions to `~/.claude/agents/`.

### 1.6 2026 Claude Code + Codex standards (sources)

See appended references. Key guidance honored: project-scoped subagents with `tools:` whitelist; skills via progressive disclosure; settings hierarchy managed > local > project > user; hooks use exit codes 0/1/2 for allow/log/block; command hooks enforce, HTTP hooks advise; Codex `AGENTS.md` layered by directory; Codex profiles experimental and CLI-only; Codex hooks Bash-only and advisory.

---

## 2. Decisions

### 2.1 Name

**Decision:** `host-capability-substrate`. Short alias `hcs` for env vars, CLI, URLs, package names.

### 2.2 Local path

**Decision:** `~/Organizations/jefahnierocks/host-capability-substrate/`. Sibling to `apps/`, `packages/`, `docs/`, `system-config/`.

### 2.3 GitHub repo

**Decision:** `verlyn13/host-capability-substrate`, public source. See §3 for public/private deployment boundary.

### 2.4 Charter ring classification

HCS is **infrastructure** under jefahnierocks — sibling to `system-config`, not nested in `apps/` or `packages/`.

### 2.5 Tool baseline (early phases, v1.1.0 amendment)

Early-phase development binds to specific tool versions to stabilize behavior:

- **Claude Code** ≥ `1.3883.0 (93ff6c)` dated `2026-04-21T17:24:01.000Z`, subsequent minor updates acceptable
- **Claude model** Opus 4.7 (`claude-opus-4-7`), short name `opus` in settings
- **Codex** ≥ `26.417.41555 (1858)`, subsequent minor updates acceptable
- **Codex model** GPT-5.4, short name `gpt-5.4` in config

Settings and subagent frontmatter reflect this. Version references recorded in `AGENTS.md` at the target repo.

---

## 3. Public source, private deployment boundary (v1.1.0 new section)

The HCS GitHub repo is **public source**. It does not carry the authority or data of the running substrate on this host. The deployment boundary is stricter than the source boundary.

### 3.1 What lives where

```text
Public HCS repo (verlyn13/host-capability-substrate):
  source code (packages/)
  schemas (packages/schemas)
  generated JSON Schema (CI artifact, committed for consumers)
  test fixtures with redacted/sample data (packages/fixtures)
  docs (docs/host-capability-substrate)
  ADRs (docs/host-capability-substrate/adr)
  regression trap prompts and expectations (packages/evals/regression)
  policy schema (Zod definitions for PolicyRule, tiers, grants)
  generated policy snapshots for tests only (policies/generated-snapshot)
  implementation charter, AGENTS.md, CLAUDE.md, PLAN.md, IMPLEMENT.md, DECISIONS.md

system-config (verlyn13/system-config, public):
  canonical live policy YAML (policies/host-capability-substrate/tiers.yaml)
  launchd plist templates
  sync-mcp integration (if HCS graduates to baseline)
  ng-doctor integration
  host bootstrap/runbook integration
  op:// reference conventions

~/Library/Application Support/host-capability-substrate/  (local, not versioned):
  SQLite state files (audit_events, facts, sessions, etc.)
  materialized visible state
  cache
  policy loaded copy (hash-verified against system-config source)
  local dashboard metadata
  resolved environment profiles

~/Library/Logs/host-capability-substrate/  (local, not versioned):
  structured runtime logs
  audit archives (rolled, hash-chained)

1Password (my.1password.com, Dev vault):
  dashboard authentication tokens
  audit checkpoint references
  signing material for daily checkpoints
```

### 3.2 Enforcement rules

- The public repo **never** contains: resolved secret values, machine-specific host identity beyond sample fixtures, live tier classifications (they're in system-config), live SQLite state, runtime tokens, audit archives.
- The public repo **may** contain: code that reads `HCS_POLICY_DIR`, schema that classifies policy rules, redacted fixtures for test runs, documentation that describes structure without instantiating it.
- CI scan (gitleaks or equivalent) blocks commits matching secret patterns. Forbidden-string scan rejects any resolved `op://` URI value.

### 3.3 Policy-load path

At runtime, the substrate kernel reads policy from `$HCS_POLICY_DIR` (default: `~/Organizations/jefahnierocks/system-config/policies/host-capability-substrate/`). It never reads live policy from inside its own source tree. The repo's `policies/generated-snapshot/` directory is test-only and hash-tagged to a specific system-config commit.

---

## 4. Runtime paths and environment variables (v1.1.0 new section)

Binding environment variable names the substrate uses. Wrappers (chezmoi-managed) populate these before invoking any HCS process.

```bash
# HCS environment baseline
export HCS_ROOT="$HOME/Organizations/jefahnierocks/host-capability-substrate"
export HCS_STATE_DIR="$HOME/Library/Application Support/host-capability-substrate"
export HCS_LOG_DIR="$HOME/Library/Logs/host-capability-substrate"
export HCS_POLICY_DIR="$HOME/Organizations/jefahnierocks/system-config/policies/host-capability-substrate"
export HCS_LAUNCH_LABEL="com.jefahnierocks.host-capability-substrate"

# Agent-scope environment (injected by MCP wrappers and client helpers)
export HCS_SESSION_ID="sess_<random>"     # allocated per MCP connection
export HCS_CLIENT_ID="claude-code"         # e.g., claude-code, codex, cursor, windsurf
export HCS_CLIENT_VERSION="1.3883.0"
export MCP_CLIENT_ID="$HCS_CLIENT_ID"     # alias for cross-tool tooling
```

### 4.1 LaunchAgent

- Label: `com.jefahnierocks.host-capability-substrate`
- Plist: `~/Library/LaunchAgents/com.jefahnierocks.host-capability-substrate.plist`
- Keepalive: true; RunAtLoad: true; ThrottleInterval: 10s
- StandardOutPath / StandardErrorPath → `$HCS_LOG_DIR/stdout.log`, `$HCS_LOG_DIR/stderr.log`
- Plist template lives at `scripts/launchd/com.jefahnierocks.host-capability-substrate.plist.tmpl` in the HCS repo; `scripts/install/install-launchd.sh` renders and installs it

### 4.2 Directory conventions (macOS-native)

- Code: repo only, never writes to sealed system volume, `/usr/local`, or `/opt/homebrew` except through Homebrew itself
- State: `$HCS_STATE_DIR` (SQLite WAL, materialized views, loaded policy)
- Logs: `$HCS_LOG_DIR` (rolled JSONL, hash-chained audit archives)
- Never writes into another project's repo except through explicit workspace-scoped operation

This matches substrate ontology semantics: repo is a workspace artifact; running service is a user LaunchAgent; state is Application Support; logs are logs; live policy is covenant-adjacent in system-config.

---

## 5. Subagent roster (v1.1.0 amended: 6 subagents)

All six subagents are project-scoped (`.claude/agents/` in the HCS repo). They are invisible in other repos by design. All default to Opus 4.7.

| Subagent | Tools | Write scope | Role |
|----------|-------|-------------|------|
| `hcs-architect` | Read, Grep, Glob, Edit | `docs/`, `adr/` | ADR + boundary review; drafts ADRs |
| `hcs-ontology-reviewer` | Read, Grep, Glob | none | Schema/entity/provenance drift review |
| `hcs-policy-reviewer` | Read, Grep, Glob | none | Policy duplication, escalation holes, forbidden leaks |
| `hcs-security-reviewer` | Read, Grep, Glob | none | Secrets, sandbox, audit, forbidden operations |
| `hcs-hook-integrator` | Read, Grep, Glob, Edit | `.claude/hooks/`, adapter hook docs | Wires hooks without owning policy |
| `hcs-eval-reviewer` | Read, Grep, Glob, Edit | `packages/evals/`, `packages/fixtures/` | Regression trap quality |

Tool-whitelist discipline: reviewers that should not edit do not have `Edit` in their `tools:` list. The settings.json permission layer adds path-scoped allow rules for the cases where editing is appropriate; both layers must allow for an action to occur.

**Never**: Bash in any review subagent's tool list. Reviewers catch drift; they do not run commands. Implementation work happens in the main session with explicit permission.

### 5.1 `hcs-ontology-reviewer` (new in v1.1.0)

Rationale: schema drift is the most expensive early mistake. The substrate's ontology is load-bearing — every kernel service, every adapter, every policy input depends on it. An independent reviewer checks:

- Entity schema changes without `schema_version` bump
- Bare strings where `Evidence` with provenance belongs
- `OperationShape` or `CommandShape` structural drift
- JSON Schema out of sync with Zod source
- Entity relationships that violate ring boundaries
- Missing `valid_until` / `observed_at` / `authority` / `confidence` / `parser_version`
- Sandbox observations written with authority other than `sandbox-observation`
- Schema changes not reflected in `ontology.md`
- Tests not covering new schema variants
- Generated JSON Schema not regenerated in the same commit

Full frontmatter template ships at `docs/host-capability-substrate/templates/` (or lifted from this doc during scaffolding).

---

## 6. Skills: `.agents/skills/` is the cross-tool canonical home (v1.1.0 new discipline)

### 6.1 Rule

- **Canonical skill content** lives at `.agents/skills/<skill-name>/SKILL.md`. Windsurf discovers `.agents/skills/` natively; Codex skills use progressive disclosure and honor the same path convention; this is the cross-tool home.
- **Claude-specific wrappers** at `.claude/skills/<skill-name>/SKILL.md` **only when** Claude-specific frontmatter (`context: fork`, `agent: Explore`, `allowed-tools`) adds behavior that the canonical content does not express. When a Claude wrapper exists, its body references the canonical `.agents/skills/` content and layers Claude-specific frontmatter on top.
- If a skill's workflow is tool-neutral, it lives **only** in `.agents/skills/`. No duplication.

### 6.2 Phase 0a skill set (under `.agents/skills/`)

- `hcs-adr-review/SKILL.md` — review an ADR for substrate-boundary violations
- `hcs-draft-adr/SKILL.md` — turn a decision into a structured ADR
- `hcs-regression-trap/SKILL.md` — convert a stale-CLI-memory failure into a regression trap
- `hcs-operation-proof/SKILL.md` — render the operation-proof template
- `hcs-policy-tier-entry/SKILL.md` — draft a YAML tier entry; canonical live tier lives in system-config
- `hcs-schema-change/SKILL.md` — schema + docs + generated JSON Schema + tests moved together

### 6.3 Claude-specific wrappers

Created only when Claude Code's `context: fork` / `agent: Explore` / `allowed-tools` surface requires it. For Phase 0a, start with **no** `.claude/skills/` content. If Claude Code testing shows a skill is not discovered without a wrapper, add a thin wrapper in `.claude/skills/<name>/SKILL.md` that references `.agents/skills/<name>/SKILL.md`.

---

## 7. No `WARP.md` in Phase 0a (v1.1.0 new discipline)

Warp prioritizes `WARP.md` over `AGENTS.md` when both exist. Creating a `WARP.md` during Phase 0a risks forking policy off `AGENTS.md` before the cross-tool contract has stabilized.

**Decision:** no `WARP.md` committed in Phase 0a. Warp consumes `AGENTS.md`. If Phase 0b measurement reveals Warp-specific gaps, add a **pointer-only** `WARP.md` that references `AGENTS.md` as the source of truth; never a parallel contract.

---

## 8. Four-layer policy set (v1.1.0 refined)

### 8.1 Layer 1 — Constitutional principles

The 16 Nash Covenant principles, cited as planning input, mapped to concrete HCS manifestations. Citation only — HCS authority for these manifestations comes from this charter and the ADRs that adopt them. Full table below.

| # | Nash principle | HCS manifestation |
|---|----------------|-------------------|
| 1 | Sacred Timeline is Linear | main protected; squash merge with conventional-commit title; no direct pushes |
| 2 | Every Commit Speaks | conventional commits; scope = ring or package name |
| 3 | No Code Enters Unchallenged | producer/critic loop; PR template boundary checks |
| 4 | Machines Must Bless | CI runs `just verify` (see §10); no merge without green |
| 5 | Fortress by Blueprints | ontology.md + schemas + policy YAML define the fortress |
| 6 | Secrets Never Committed | `op://` URIs only; forbidden-string scan + gitleaks in CI |
| 7 | Trunk is Sacred | branch protection: review + status checks + linear history |
| 8 | Fail Fast, Recover Faster | typed degraded responses; FSM with `failed`/`rolled_back`; launchd KeepAlive |
| 9 | Trust, but Verify | every fact has provenance; audit hash chain; daily `op://` checkpoint |
| 10 | Least Privilege | `forbidden` tier non-escalable; subagent tool whitelists; sandbox authority downgrade |
| 11 | Measured, or Doesn't Exist | OTEL from line 1; Phase 0b numeric baseline; numeric phase acceptance criteria |
| 12 | Runbooks Executable | operation proof template renders as runbook + dashboard view; grants consumable programmatically |
| 13 | Code Without Docs Incomplete | ADR for every non-obvious decision; ontology.md binding; CLAUDE.md + AGENTS.md present |
| 14 | Progress Without Breakage | ring-boundary CI check; versioned schemas/policies; deprecation windows |
| 15 | Three Circles of Trust | tiers (`read-safe` → `write-local` → `write-project` → `write-host` → `write-destructive` → `forbidden`) map to circles |
| 16 | Living Law | charter + policies versioned; amendments require ADR; governance flows through system-config |

### 8.2 Layer 2 — HCS invariants (charter-backed)

Restated in the implementation charter. Non-negotiable:

1. Kernel is protocol-unaware.
2. `OperationShape` precedes `CommandShape`.
3. There is no universal shell execution tool.
4. Audit logging is internal, not agent-callable.
5. Live policy is data, not copied prose.
6. `forbidden` tier is non-escalable.
7. Writes require gateway classification.
8. Mutations require `ApprovalGrant`.
9. Runtime facts require provenance.
10. Stale/degraded state is typed.
11. Dashboard is a control plane from the first slice.
12. Adapters may translate, never decide.
13. Skills canonical at `.agents/skills/`; `.claude/skills/` for Claude-specific wrappers only. *(added in charter v1.1.0)*
14. Public source, private deployment boundary: repo does not carry live policy, live state, resolved secrets, or audit archives. *(added in charter v1.1.0)*
15. Sandbox observations carry `authority: sandbox-observation`; never promotable. *(already implicit; made explicit in v1.1.0)*

### 8.3 Layer 3 — Tool/client posture

Governs how each IDE/agent interacts with the repo. See [`tooling-surface-matrix.md`](./tooling-surface-matrix.md) for the full matrix. Summary:

- **Claude Code:** project settings enforce; hooks block obvious forbidden patterns; subagents project-scoped and tool-limited; Opus 4.7 baseline.
- **Codex:** `AGENTS.md` canonical; profiles user-scoped; trusted-project entry required; hooks advisory until coverage improves.
- **Cursor:** thin `.cursor/rules/` only; no policy duplication; `.cursor/mcp.json` mirrors project MCP.
- **Windsurf:** `AGENTS.md` + `.agents/skills/`; user-scope MCP at `~/.codeium/windsurf/mcp_config.json`; no repo-local live policy.
- **Warp:** `AGENTS.md` first; no `WARP.md` Phase 0a; terminal permissions stay explicit.
- **VS Code:** editor/task convenience only; no policy logic; respects existing shell integration.

### 8.4 Layer 4 — Runtime operation policy

What the HCS gateway evaluates. YAML schema in system-config. Tiers:

```
read-safe            no approval; cacheable; typed degraded allowed
write-local          workspace-contained; still classified and audited
write-project        broader project writes; requires operation proof when agent-initiated
write-host           Homebrew, mise installs, launchd user domain, host state — requires approval (post execute-lane launch)
write-destructive    hard-to-reverse; requires dashboard approval + rollback/backup statement
forbidden            no approval path; not registered as capabilities
```

### 8.5 Expanded forbidden list

`forbidden` tier includes at minimum:

- SIP toggles (`csrutil`)
- Gatekeeper disabling (`spctl --master-disable`, `spctl --global-disable`)
- Broad `sudo` wrappers
- Unscoped `rm -rf` patterns targeting `/`, `$HOME`, `~`
- Raw `defaults write` as a general operation (specific domains may be approved case-by-case, but `defaults write` as a capability is forbidden)
- Universal shell execution (`bash.run`, `shell.exec`, equivalents — not registered as capabilities)
- Secret value disclosure (logging resolved `op://` values, writing tokens to files)
- Audit rewriting (any path that mutates historical audit rows)
- Policy self-modification by an agent (agents may draft; merge requires human approval via the reviewer subagent)
- `launchctl load`/`unload` (deprecated verbs; use `bootstrap`/`bootout`)

---

## 9. Repo root layout (Phase 0a, v1.1.0 amended)

```
host-capability-substrate/
├── README.md
├── LICENSE
├── .gitignore
├── .gitattributes
├── .editorconfig
├── .mise.toml
├── .envrc
├── CLAUDE.md                          # imports AGENTS.md
├── AGENTS.md                          # canonical cross-tool contract
├── PLAN.md
├── IMPLEMENT.md
├── DECISIONS.md
├── .mcp.json                          # empty stub
├── package.json
├── tsconfig.json
├── tsconfig.base.json
├── biome.json
├── justfile
│
├── .agents/                           # CROSS-TOOL CANONICAL SKILLS (v1.1.0 new)
│   └── skills/
│       ├── hcs-adr-review/SKILL.md
│       ├── hcs-draft-adr/SKILL.md
│       ├── hcs-regression-trap/SKILL.md
│       ├── hcs-operation-proof/SKILL.md
│       ├── hcs-policy-tier-entry/SKILL.md
│       └── hcs-schema-change/SKILL.md
│
├── .claude/                           # Project-scoped Claude Code
│   ├── settings.json                  # permissions, hooks, model=opus
│   ├── agents/
│   │   ├── hcs-architect.md
│   │   ├── hcs-ontology-reviewer.md   # (v1.1.0 new)
│   │   ├── hcs-policy-reviewer.md
│   │   ├── hcs-security-reviewer.md
│   │   ├── hcs-hook-integrator.md
│   │   └── hcs-eval-reviewer.md
│   ├── skills/                        # empty at Phase 0a; Claude-specific wrappers only if needed
│   └── hooks/
│       └── hcs-hook                   # thin helper script; log-only in Phase 0a
│
├── .codex/                            # Project-scoped Codex (opt-in trust)
│   └── config.toml
│
├── .cursor/                           # Cursor project config (thin)
│   ├── mcp.json                       # empty stub
│   └── rules/
│       ├── hcs-boundaries.mdc
│       └── hcs-review-checklist.mdc
│
├── .vscode/                           # VS Code workspace (editor conveniences only)
│   ├── settings.json
│   ├── extensions.json
│   └── tasks.json
│
# NO WARP.md at Phase 0a — Warp consumes AGENTS.md
# NO .windsurf/ — Windsurf has no project scope; .agents/skills/ covers shared workflows
# NO .copilot/ at Phase 0a — add only when Copilot is part of HCS work
│
├── docs/
│   └── host-capability-substrate/
│       ├── implementation-charter.md  # lifted from system-config
│       ├── ontology.md                # stub; Phase 1 Thread D populates
│       ├── dashboard-contracts.md     # stub
│       ├── hook-contracts.md          # stub
│       ├── operation-proof.md         # template
│       ├── tooling-surface-matrix.md  # (v1.1.0 new) lifted from system-config
│       └── adr/
│           ├── 0000-template.md
│           ├── 0001-repo-boundary.md  # short stub → points to this file in system-config
│           ├── 0002-runtime.md
│           ├── 0003-transport-topology.md
│           ├── 0004-storage-sqlite-wal.md
│           ├── 0005-process-model-launchd.md
│           ├── 0006-policy-source-location.md
│           ├── 0007-hook-call-pattern.md
│           ├── 0008-dashboard-auth.md
│           ├── 0009-ontology-versioning.md
│           ├── 0010-mcp-primitive-mapping.md
│           └── 0011-public-private-boundary.md  # (v1.1.0 new)
│
├── packages/
│   ├── schemas/                       # Ring 0 (.gitkeep)
│   ├── kernel/                        # Ring 1 (.gitkeep)
│   ├── adapters/                      # Ring 2 (.gitkeep)
│   │   ├── mcp-stdio/
│   │   ├── mcp-http/
│   │   ├── dashboard-http/
│   │   ├── cli/
│   │   ├── claude-hooks/
│   │   └── codex-hooks/
│   ├── dashboard/                     # Ring 2 (.gitkeep)
│   ├── evals/
│   │   └── regression/
│   │       └── seed.md                # 15 seed traps
│   └── fixtures/
│       ├── macos/
│       ├── help-output/
│       └── policies/
│
├── policies/
│   ├── README.md                      # points to canonical in system-config
│   └── generated-snapshot/            # test-only, CI-populated
│
└── scripts/
    ├── ci/
    │   ├── boundary-check.ts
    │   ├── policy-lint.ts
    │   ├── schema-drift.ts
    │   ├── forbidden-string-scan.ts
    │   ├── no-live-secrets.ts
    │   └── no-runtime-state-in-repo.ts
    ├── dev/
    ├── install/
    │   └── install-launchd.sh
    └── launchd/
        └── com.jefahnierocks.host-capability-substrate.plist.tmpl
```

---

## 10. Quality gates (v1.1.0 expanded)

`just verify` from first commit runs (all of):

```
format                              # biome format --check
typecheck                           # tsc --noEmit
unit tests                          # vitest
schema generation check             # Zod → JSON Schema
schema drift check                  # regenerate and diff
boundary import check               # adapter cannot import kernel-private; kernel cannot import adapter
policy schema lint                  # tiers.yaml validates against PolicyRule schema
forbidden-string scan               # no raw op:// values, no forbidden-list patterns in strings
hook dry-run tests                  # .claude/hooks/hcs-hook runs clean on test inputs
AGENTS/CLAUDE pointer check         # CLAUDE.md imports AGENTS.md; AGENTS.md present
no live secrets check               # gitleaks or equivalent
no runtime-state-in-repo check      # repo contains no paths matching $HCS_STATE_DIR layout
```

HCS-specific checks (run via `scripts/ci/*.ts`):

- No adapter imports kernel-private internals
- No kernel imports adapter code
- No hooks contain policy tier tables
- No `.cursor/`, `.vscode/`, `WARP.md`, `.windsurf/` file contains forbidden-list policy prose
- No universal shell execution tool name appears (`bash.run`, `shell.exec`, etc. are banned names)
- No `system.audit.log.v1` appears as exposed capability
- No `ApprovalGrant` consumption code exists before approval + dashboard + audit schemas exist

---

## 11. Stage-by-stage configuration

### 11.1 Phase 0a — scaffolding day

**Project scope (in new `host-capability-substrate/` repo):**

- `.claude/settings.json` — `model: "opus"`, `defaultMode: "ask"`, permissions allow/ask/deny lists, hook wiring for `.claude/hooks/hcs-hook`. Full example in §12.
- `.claude/agents/hcs-*.md` × **6** (see §5 table)
- `.claude/hooks/hcs-hook` — bash helper that logs to `.logs/phase-0/hook-events.jsonl` and blocks only obvious forbidden patterns (literal SIP/Gatekeeper/rm -rf root)
- `.agents/skills/hcs-*/SKILL.md` × 6 (see §6.2)
- `.claude/skills/` — empty at Phase 0a
- `.codex/config.toml` — minimal project override
- `.cursor/rules/hcs-boundaries.mdc`, `hcs-review-checklist.mdc` — pointer rules (not policy)
- `.mcp.json`, `.cursor/mcp.json` — empty stubs
- `.mise.toml` — Node LTS, shellcheck, shfmt, just, biome, tsc
- `.envrc` — `use mise`
- `biome.json`, `tsconfig.json`, `tsconfig.base.json`, `package.json`, `justfile`
- Governance docs: CLAUDE.md (imports AGENTS.md), AGENTS.md, PLAN.md, IMPLEMENT.md, DECISIONS.md
- `docs/host-capability-substrate/` — charter, ontology stub, dashboard-contracts stub, hook-contracts stub, operation-proof template, **tooling-surface-matrix.md**, 12 ADR stubs (0000-0011)
- `packages/` with .gitkeeps + evals/regression/seed.md (15 traps)
- `scripts/ci/*.ts` — 6 boundary checks (see §10)
- `scripts/launchd/com.jefahnierocks.host-capability-substrate.plist.tmpl`
- `scripts/install/install-launchd.sh`

**User scope additions:**

Append to `~/.codex/config.toml`:

```toml
[profiles.hcs-plan]
model = "gpt-5.4"
model_reasoning_effort = "high"
approval_policy = "on-request"
sandbox_mode = "workspace-write"

[profiles.hcs-implement]
model = "gpt-5.4"
model_reasoning_effort = "medium"
approval_policy = "on-request"
sandbox_mode = "workspace-write"

[profiles.hcs-review]
model = "gpt-5.4"
model_reasoning_effort = "high"
approval_policy = "never"
sandbox_mode = "read-only"

[projects."/Users/verlyn13/Organizations/jefahnierocks/host-capability-substrate"]
trust_level = "trusted"
```

User-scope Claude Code: no changes. Existing 6 generic subagents in `~/.claude/agents/` stay.

**iTerm2:** no new profile; use existing `agentic-zsh` / `dev-zsh`.

**Runtime directories:** created on first launchd-agent load (Phase 4). Not provisioned in Phase 0a.

### 11.2 Phase 3 — read-only kernel slice

Exposed capabilities (8, unchanged from research plan):

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

Config changes:

- `.mcp.json` populated with `hcs` server entry
- `.claude/settings.json` — add HCS server to MCP allowlist
- `.claude/hooks/hcs-hook` — upgraded from log-only to calling `system.tool.resolve.v1` + `system.policy.classify_operation.v1` with 50ms timeout + cache fallback
- LaunchAgent installed; `$HCS_STATE_DIR` and `$HCS_LOG_DIR` populated on first run
- `ng-doctor --substrate` reads dashboard health

### 11.3 Phase 4 — mutations / approvals / sandbox

Gated on: approval grants + audit hash chain + dashboard review + lease manager all live. Separate ADR:

- Whether HCS graduates to cross-project baseline via `system-config/scripts/mcp-servers.json` (likely yes — every agent benefits; decide explicitly at that time)
- Dashboard auth token lifecycle via `op run`
- MCP `URL` elicitation mode for approval (opportunistic; dashboard remains canonical)
- Warp and Windsurf user-scope MCP registration

---

## 12. Example `.claude/settings.json` (Phase 0a)

```json
{
  "model": "opus",
  "defaultMode": "ask",
  "permissions": {
    "allow": [
      "Read(**)",
      "Grep(**)",
      "Glob(**)",
      "Edit(docs/**)",
      "Edit(packages/**)",
      "Edit(policies/README.md)",
      "Edit(scripts/**)",
      "Edit(.claude/hooks/**)",
      "Edit(.agents/skills/**)",
      "Edit(AGENTS.md)",
      "Edit(CLAUDE.md)",
      "Edit(PLAN.md)",
      "Edit(IMPLEMENT.md)",
      "Edit(DECISIONS.md)",
      "Edit(README.md)",
      "Edit(package.json)",
      "Edit(tsconfig*.json)",
      "Edit(biome.json)",
      "Edit(justfile)",
      "Edit(.mise.toml)",
      "Edit(.envrc)",
      "Edit(.gitignore)",
      "Edit(.editorconfig)",
      "Bash(git:*)",
      "Bash(gh:*)",
      "Bash(just:*)",
      "Bash(mise:*)",
      "Bash(node:*)",
      "Bash(npm:*)",
      "Bash(pnpm:*)",
      "Bash(npx:*)",
      "Bash(biome:*)",
      "Bash(vitest:*)",
      "Bash(tsc:*)",
      "Bash(ls:*)",
      "Bash(cat:*)",
      "Bash(file:*)",
      "Bash(stat:*)"
    ],
    "ask": [
      "Edit(.claude/settings.json)",
      "Edit(.claude/agents/**)",
      "Edit(.claude/skills/**)",
      "Edit(.codex/**)",
      "Edit(.cursor/**)",
      "Edit(.vscode/**)",
      "Bash(brew:*)",
      "Bash(chmod:*)",
      "Bash(chown:*)",
      "Bash(launchctl:*)"
    ],
    "deny": [
      "Bash(defaults write:*)",
      "Bash(spctl --master-disable:*)",
      "Bash(spctl --global-disable:*)",
      "Bash(csrutil:*)",
      "Bash(sudo:*)",
      "Bash(launchctl load:*)",
      "Bash(launchctl unload:*)",
      "Bash(rm -rf /:*)",
      "Bash(rm -rf ~:*)",
      "Bash(rm -rf $HOME:*)",
      "Bash(rm -rf /Users:*)",
      "Read(.env)",
      "Read(.env.local)",
      "Read(**/*.pem)",
      "Read(**/*.key)",
      "Read(**/credentials*)",
      "Read(**/secrets/**)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/hcs-hook pre-bash",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

---

## 13. Consequences (v1.1.0 amended)

**Accepts:**

- Long repo name — mitigated by `hcs` alias and tab-completion
- Public source, tighter private deployment boundary — requires discipline on what enters the repo
- Skills discipline `.agents/skills/` canonical, `.claude/skills/` wrappers only — adds one thin Claude wrapper per skill only when Claude Code can't discover the canonical content otherwise
- Lightweight workspace-scoped governance — appropriate for host-scoped infrastructure that does not need a heavier review surface
- Project-scope subagents only — HCS subagents invisible in other projects by design
- Opus 4.7 + GPT-5.4 specific versions — re-evaluate at end of Phase 0b; subsequent minor updates acceptable

**Rejects:**

- Placing HCS under `apps/` or `packages/`
- `jfr-` prefix
- User-scoping HCS subagents
- Separate-subsidiary placement
- `WARP.md` in Phase 0a
- `.windsurf/skills/` — redundant with `.agents/skills/`
- `.copilot/` at Phase 0a — add only if Copilot becomes a target agent
- Audit-write endpoint exposed to agents at any phase
- Any capability that cannot answer the six-question surface boundary test

**Future amendments:**

- End of Phase 0b: re-evaluate tool baseline (Claude/Codex versions, Opus/GPT model choice) based on measurement data
- Month 4: decide HCS graduation to cross-project baseline via `system-config/scripts/mcp-servers.json`
- If Warp measurement in Phase 0b shows gaps, add pointer-only `WARP.md`

---

## 14. What gets created now, and what needs user approval

### 14.1 Already persisted in system-config (this commit)

- This decision record at [`docs/host-capability-substrate/0001-repo-boundary-decision.md`](./0001-repo-boundary-decision.md) (v1.1.0)
- Tooling surface matrix at [`docs/host-capability-substrate/tooling-surface-matrix.md`](./tooling-surface-matrix.md)
- Implementation charter updated to v1.1.0
- Target-repo templates updated to reflect v1.1.0 refinements

### 14.2 Requires user approval before execution

- Create local directory + git init + GitHub repo create (`verlyn13/host-capability-substrate`, public)
- Bootstrap scaffold (all files per §9, including 6 subagents, 6 skills in `.agents/skills/`, settings.json per §12, hook helper, ADR stubs, regression seed, CI scripts)
- Append three Codex profiles + trust-list entry to `~/.codex/config.toml` (back up first)
- ~~Spawned separately (chip in UI): retire stale `jfr-` prefix in `.subsidiary.yaml` and jefahnierocks/CLAUDE.md~~ — completed 2026-05-01: `.subsidiary.yaml` removed, jefahnierocks/CLAUDE.md and AGENTS.md rewritten in workspace-own voice (v1.2.0)

---

## 15. References

### Internal

- [HCS research plan](../host-capability-substrate-research-plan.md) (v0.3.0+)
- [Implementation charter](./implementation-charter.md) (v1.1.0+)
- [Tooling surface matrix](./tooling-surface-matrix.md) (v1.0.0+)
- [Target-repo templates](./templates/)
- `~/Organizations/the-nash-group/the-covenant/PRINCIPLES.md` — 16 principles
- [`docs/project-conventions.md`](../project-conventions.md)
- [`docs/mcp-config.md`](../mcp-config.md)
- [`docs/secrets.md`](../secrets.md)
- [`docs/agentic-tooling.md`](../agentic-tooling.md)

### External

- MCP: [Architecture](https://modelcontextprotocol.io/specification/2025-11-25/architecture), [Server](https://modelcontextprotocol.io/specification/2025-11-25/server), [Tools](https://modelcontextprotocol.io/specification/2025-11-25/server/tools), [Transports](https://modelcontextprotocol.io/specification/2025-11-25/basic/transports)
- Claude Code: [Subagents](https://docs.anthropic.com/en/docs/claude-code/sub-agents), [Settings](https://docs.anthropic.com/en/docs/claude-code/settings), [Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks), [Memory](https://docs.anthropic.com/en/docs/claude-code/memory)
- Codex: [AGENTS.md](https://developers.openai.com/codex/guides/agents-md), [Profiles](https://developers.openai.com/codex/config-advanced), [Subagents](https://developers.openai.com/codex/subagents), [Skills](https://developers.openai.com/codex/skills), [Hooks](https://developers.openai.com/codex/hooks)
- Windsurf: [Skills](https://docs.windsurf.com/windsurf/cascade/skills), [AGENTS.md](https://docs.windsurf.com/windsurf/cascade/agents-md), [MCP](https://docs.windsurf.com/windsurf/cascade/mcp)
- Warp: [Agents](https://docs.warp.dev/agent-platform/getting-started/agents-in-warp), [Rules](https://docs.warp.dev/agent-platform/warp-agents/capabilities-overview/rules)
- iTerm2 [Shell Integration](https://iterm2.com/shell_integration.html)
- VS Code [Terminal Shell Integration](https://code.visualstudio.com/docs/terminal/shell-integration)
- OpenAI: [GPT-5.4 guide](https://developers.openai.com/api/docs/guides/latest-model), [Tool search](https://developers.openai.com/api/docs/guides/tools-tool-search), [Guardrails](https://developers.openai.com/api/docs/guides/agents/guardrails-approvals), [Sandbox agents](https://developers.openai.com/api/docs/guides/agents/sandboxes)
- OPA: [docs](https://openpolicyagent.org/docs)
- SQLite: [WAL](https://www.sqlite.org/wal.html)

## Change log

| Version | Date | Change |
|---------|------|--------|
| 1.2.0 | 2026-05-01 | Parent-inheritance framing retired. Nash Covenant principles reframed as cited planning input rather than runtime-inherited authority. Jefahnierocks reframed as a workspace with its own authority rather than a subsidiary tier. `.subsidiary.yaml` cleanup recorded as complete (file removed rather than renamed because no Jefahnierocks-owned local metadata consumer exists yet). Decision content (name, path, GitHub slug, deployment boundary, policy set, scaffolding stance) is unchanged from v1.1.0; only the authority/citation framing changes. |
| 1.1.0 | 2026-04-22 | Expert-reviewed refinements. Public/private deployment boundary made explicit (§3). Runtime paths + env vars + LaunchAgent reverse-DNS label standardized (§4). Sixth subagent `hcs-ontology-reviewer` added (§5). Skills discipline: `.agents/skills/` canonical, `.claude/skills/` Claude-specific wrappers only (§6). No `WARP.md` in Phase 0a (§7). Four-layer policy set with expanded forbidden list (§8). Tool baseline pinned: Claude Code 1.3883.0+ Opus 4.7, Codex 26.417.41555+ GPT-5.4 (§2.5). Quality gates expanded (§10). Example settings.json (§12). Added references to tooling-surface-matrix.md and ADR 0011 public-private-boundary. |
| 1.0.0 | 2026-04-22 | Initial decision. Name `host-capability-substrate`; path `~/Organizations/jefahnierocks/host-capability-substrate/`; GitHub `verlyn13/host-capability-substrate` (no prefix — matches observed practice). Stale `jfr-` prefix flagged as separate cleanup. Full Phase 0a layout specified. Policy set cited 16 Nash principles + 12 2026 agentic additions as planning input (framing later clarified in v1.2.0). |

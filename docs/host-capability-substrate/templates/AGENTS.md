# AGENTS.md — Host Capability Substrate

Target-repo template drafted in `system-config`. Copy to HCS repo root when created.

## Tool baseline (binding during early phases)

- **Claude Code:** `1.3883.0 (93ff6c)` minimum; Opus 4.7 (`opus` in settings)
- **Codex:** `26.417.41555 (1858)` minimum; GPT-5.4 (`gpt-5.4` in profiles)

Subsequent minor updates acceptable without re-baselining. Re-evaluate at end of Phase 0b.

## Source of truth

Read these before editing:

1. `docs/host-capability-substrate/implementation-charter.md` — binding rules, four rings, non-negotiable invariants (v1.1.0+)
2. `docs/host-capability-substrate/ontology.md` — entity schemas
3. `docs/host-capability-substrate/tooling-surface-matrix.md` — where each config file belongs and what it can enforce
4. `docs/host-capability-substrate/adr/` — architecture decisions
5. `PLAN.md` — current milestone and acceptance criteria
6. `IMPLEMENT.md` — workflow rules
7. `DECISIONS.md` — human-readable decision ledger

Upstream research plan (in system-config, canonical reference):
`~/Organizations/jefahnierocks/system-config/docs/host-capability-substrate-research-plan.md`.

Canonical live policy (not in this repo):
`~/Organizations/jefahnierocks/system-config/policies/host-capability-substrate/`.

## Repo layout

```
packages/
  schemas/      Ring 0: ontology + JSON Schema + TypeScript types
  kernel/       Ring 1: host-state, tool-resolution, capabilities, policy,
                        gateway, session-ledger, evidence-cache, audit,
                        leases, execution-broker
  adapters/     Ring 2: mcp-stdio, mcp-http, dashboard-http, cli,
                        claude-hooks, codex-hooks
  dashboard/    Ring 2: local HTTPS dashboard
  evals/        regression corpus + trajectory harness
  fixtures/     macOS fixtures, help-output fixtures, policy test fixtures

policies/
  generated-snapshot/   read-only snapshot for tests; canonical policy lives
                        in system-config/policies/host-capability-substrate/

scripts/
  dev/          local dev helpers
  install/      launchd install
  launchd/      plist templates
  ci/           boundary checks, policy lint, schema drift check
```

## Hard boundaries (charter invariants summarized)

- Do not put business logic in MCP, dashboard, Claude, Codex, or CLI adapters.
- Do not add a universal shell execution tool.
- Do not represent shell strings as primary intent.
- Do not copy policy into hooks. Hooks call HCS or read the generated policy snapshot.
- Do not expose audit-write tools to agents.
- Do not add mutating execution endpoints before approval grants and dashboard review exist.
- Do not use live CLI syntax from model memory; use tool-resolution/help evidence.
- Do not promote sandbox observations to host-authoritative evidence.
- Skills are canonical at `.agents/skills/`; `.claude/skills/` is for Claude-specific wrappers only.
- No `WARP.md` in Phase 0a; Warp consumes `AGENTS.md`.
- No runtime state in the repo — it lives under `~/Library/Application Support/host-capability-substrate/` and `~/Library/Logs/host-capability-substrate/`.
- Live policy is canonical in `system-config/policies/host-capability-substrate/`, not in this repo.

## Required workflow

Before code:

1. Identify the target ring: schema, kernel, adapter, dashboard, hook, eval, docs.
2. Confirm the matching ADR exists.
3. If the task changes ontology, update schema + docs + tests together.

For implementation:

1. Keep diffs scoped to one milestone.
2. Add or update tests with every behavior change.
3. Run `just verify` before finishing.
4. Update `DECISIONS.md` for non-obvious choices.
5. Add regression traps when a model/tooling failure motivates a rule.

## Validation commands

```bash
just verify             # runs lint + typecheck + tests + boundary check
just test schemas       # schema tests only
just test kernel        # kernel tests only
just test mcp           # MCP adapter tests
just generate-schemas --check   # confirms JSON Schema matches Zod
just policy-lint        # checks policy files are well-formed and schema-valid
just boundary-check     # enforces charter §Package boundary enforcement
```

## Definition of done

A change is not done until:

- schemas validate
- tests pass
- generated JSON Schema updated if schemas changed
- docs match behavior
- no adapter imports kernel-private internals
- no policy is duplicated outside policy sources
- eval fixtures updated when relevant
- `just verify` passes
- PR template boundary checks ticked

## Agent role table

One role per PR. Critic does not edit without a follow-up assignment. Six project-scoped Claude subagents in `.claude/agents/`:

| Subagent | Tools | Write scope | Role |
|----------|-------|-------------|------|
| `hcs-architect` | Read, Grep, Glob, Edit | docs/ + adr/ | ADR + boundary review; drafts ADRs |
| `hcs-ontology-reviewer` | Read, Grep, Glob | none | Schema/entity/provenance drift review |
| `hcs-policy-reviewer` | Read, Grep, Glob | none | Policy duplication, escalation holes, forbidden leaks |
| `hcs-security-reviewer` | Read, Grep, Glob | none | Secrets, sandbox, audit, forbidden operations |
| `hcs-hook-integrator` | Read, Grep, Glob, Edit | .claude/hooks/, adapter hook docs | Wires hooks without owning policy |
| `hcs-eval-reviewer` | Read, Grep, Glob, Edit | packages/evals/, packages/fixtures/ | Regression trap quality |

All subagents default to Opus 4.7. No subagent has Bash in its tool list — reviewers catch drift, not execute commands. Implementation work happens in the main session with explicit permission.

Implementation roles (human-directed; not subagents):

| Role | Tool | Output |
|------|------|--------|
| Schema engineer | Codex GPT-5.4 (profile: hcs-implement) | Zod + JSON Schema + fixtures |
| Kernel implementer | Codex GPT-5.4 (profile: hcs-implement) | service code + tests |
| Adapter implementer | Codex or Claude Code Opus | MCP/CLI/hook wrappers |
| Dashboard implementer | Codex or Claude Code Opus | read-only views |
| Policy drafter | Claude Code Opus | `tiers.yaml` (to system-config), rationale |
| Doc keeper | Claude Code Opus | DECISIONS, ADRs, changelog |

## Update policy

Update `AGENTS.md` after repeated agent mistakes; do not stuff it upfront. Keep it practical. When a class of mistake surfaces twice, add a rule and record the trap in the regression corpus.

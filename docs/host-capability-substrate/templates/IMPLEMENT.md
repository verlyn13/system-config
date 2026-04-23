# IMPLEMENT.md — Host Capability Substrate

Target-repo template drafted in `system-config`. Copy to HCS repo root when created.

Follow `PLAN.md` milestone by milestone.

## Rules

- Do not skip validation.
- If validation fails, fix before continuing.
- Keep each PR to one milestone (ideally one ring).
- Update `DECISIONS.md` when making a tradeoff.
- Update docs whenever schema, policy, or adapter behavior changes.
- Do not implement execution, approvals, sandbox, or audit-write endpoints unless the current milestone explicitly says so.
- Honor the implementation charter at `docs/host-capability-substrate/implementation-charter.md`.

## Per-PR checklist (mirrors PR template)

**Ring changed:**

- [ ] Ontology/schema
- [ ] Kernel
- [ ] Adapter
- [ ] Dashboard
- [ ] Hook
- [ ] Eval
- [ ] Docs

**Boundary checks:**

- [ ] No policy duplicated into adapter/hook
- [ ] No universal shell execution added
- [ ] No audit-write agent endpoint added
- [ ] `OperationShape` remains upstream of `CommandShape`
- [ ] Evidence includes provenance/freshness where applicable
- [ ] Dashboard impact considered

**Validation:**

```
just verify
just test <package>
```

**Agent use:**

- Implementer: (role from AGENTS.md table)
- Reviewer: (different role)
- Subagents: (optional)

## Producer/critic loop

Good:

```
1. Human chooses milestone and file ownership.
2. One agent writes implementation in one narrow area.
3. A different agent reviews boundary/policy/security implications.
4. Implementer fixes concrete issues.
5. Eval subagents run regression review.
6. Human approves ADR/policy/schema changes.
7. Merge.
```

Bad:

```
Two agents edit schemas, policy, adapters, docs in parallel.
```

Exactly one owner agent + one critic agent per PR. Critic does not edit without a follow-up assignment.

## Change classes

Every task declares its class:

```
A: docs/research only
B: schema only
C: policy only
D: kernel read path
E: adapter read path
F: dashboard read path
G: hook integration
H: eval/regression
I: mutation/approval/execution — blocked until approval grants + audit + dashboard + leases all exist
```

Class I is CI-enforced as unmergeable until Milestone M4-Month-4 per the research plan.

## Weekly review (≤30 minutes)

1. What traps did agents hit this week?
2. Which policy/hook/runbook duplicated knowledge?
3. Which cache/evidence answer was stale or ambiguous?
4. Which dashboard view would have made a decision easier?
5. Which `AGENTS.md`/`CLAUDE.md` rule should be added because a mistake repeated?

Update `AGENTS.md` only after repeated mistakes. Add traps to the regression corpus when a new class surfaces.

## When uncertain

- About CLI behavior → add an evidence/fixture path, do not guess
- About schema shape → open an ADR before implementing; require `hcs-ontology-reviewer` objections
- About policy tier → ask in `DECISIONS.md` pending queue, do not default-allow
- About ring boundary → consult the charter; if ambiguous, the stricter ring wins
- About skill placement → canonical is `.agents/skills/`; only add `.claude/skills/` wrapper if Claude Code cannot discover the canonical
- About runtime state → it does not belong in the repo; target `~/Library/Application Support/host-capability-substrate/` and `~/Library/Logs/host-capability-substrate/`

## Required subagent reviews

Per charter v1.1.0:

- PR touches any `packages/schemas/` file or `docs/host-capability-substrate/ontology.md` → `hcs-ontology-reviewer` objections required
- PR touches `system-config/policies/host-capability-substrate/` (via workspace) or any file that classifies operations → `hcs-policy-reviewer` objections required
- PR touches `.claude/settings.json`, `.claude/hooks/`, or any adapter security posture → `hcs-security-reviewer` objections required
- PR adds or edits ADRs → `hcs-architect` review required

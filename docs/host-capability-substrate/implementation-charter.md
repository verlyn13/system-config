---
title: Host Capability Substrate — Implementation Charter
category: charter
component: host_capability_substrate
status: active
version: 1.1.0
last_updated: 2026-04-22
tags: [substrate, kernel, adapters, ontology, policy, four-rings, non-import, skills, deployment-boundary]
priority: critical
---

# Host Capability Substrate — Implementation Charter

Binding rule for everyone (human and agent) touching HCS. Citable from every PR. Violations block merge.

Parent research plan: [`../host-capability-substrate-research-plan.md`](../host-capability-substrate-research-plan.md). Boundary decision: [`0001-repo-boundary-decision.md`](./0001-repo-boundary-decision.md). Tooling surface matrix: [`tooling-surface-matrix.md`](./tooling-surface-matrix.md).

## The four rings

The substrate has four rings. **No lower ring may import from a higher ring.**

```text
Ring 0: Ontology and schemas
  Versioned entities, operation shapes, command shapes, evidence, decisions,
  approval grants, runs, leases, artifacts.

Ring 1: Kernel services
  Host state, tool resolution, capability registry, policy/gateway,
  session ledger, evidence/cache, audit, lease manager, execution broker.

Ring 2: Adapter surfaces
  MCP stdio, MCP Streamable HTTP, dashboard HTTP, CLI, Claude hooks,
  Codex hooks, future A2A, future MCP Apps.

Ring 3: Agent/human workflows
  Skills (.agents/skills/ canonical), AGENTS.md, CLAUDE.md, PLAN.md,
  runbooks, eval prompts, dashboard review flows.
```

## Non-negotiable invariants

1. **No policy decision may live in an adapter.** Tier classification, destructive-pattern matching, approval logic, forbidden-operation checks — all belong in Ring 1's policy/gateway service. Adapters translate, they do not classify.

2. **No shell command is an ontology object; it is only a rendered `CommandShape`.** `CommandShape` is downstream of `OperationShape`. Agents propose operations; the kernel renders commands against the current resolved toolchain.

3. **No agent can reach across rings to shortcut a layer.** If Ring 3 wants host state, it calls Ring 2 which calls Ring 1 which reads Ring 0. Layer skipping is a design smell that manifests as coupling in the audit log.

4. **Audit logging is an internal side effect, never an agent-callable tool.** External testimony (when added) uses a separate endpoint and a separate table, typed as untrusted.

5. **Secrets never live in Ring 0 or Ring 1 at rest.** References (`op://` URIs) yes. Values no.

6. **`forbidden` tier is non-escalable.** No approval grant, no policy exception, no human override at the gateway level. Forbidden operations are not registered as capabilities.

7. **Execute lane does not ship before the full approval/audit/dashboard/lease stack is live.** Approval grants, dashboard review, tamper-evident audit, lease manager — all four must exist together before any capability with `mutation_scope != "none"` is callable.

8. **Sandbox observations cannot be promoted to host-authoritative evidence.** `authority: sandbox-observation` is a schema-level value, lower than any host-origin authority.

9. **Skills are canonical at `.agents/skills/`.** *(added in v1.1.0)* The cross-tool workflow home is `.agents/skills/<skill-name>/SKILL.md`. `.claude/skills/` is reserved for Claude-specific wrappers only, and exists only when Claude Code requires a wrapper that cannot be expressed in the canonical skill body. Skill content is not duplicated.

10. **Public source, private deployment boundary.** *(added in v1.1.0)* The repo contains source, schemas, generated JSON Schema, test fixtures with redacted data, docs, ADRs, regression prompts, and policy schemas. The repo does **not** contain: live policy YAML (that lives in `system-config/policies/host-capability-substrate/`), SQLite runtime state, materialized facts cache, audit archives, dashboard tokens, resolved secret values, or host-specific runtime configuration. Runtime state lives under `~/Library/Application Support/host-capability-substrate/`, logs under `~/Library/Logs/host-capability-substrate/`, secrets in 1Password.

11. **Operations never use deprecated syntax when a modern replacement exists.** *(added in v1.1.0)* `launchctl load`/`unload` are deprecated; use `bootstrap`/`bootout`. The capability registry refuses to render deprecated verbs. Rule generalizes to any tool whose docs mark a syntax as deprecated.

12. **Tool version baseline is explicit.** *(added in v1.1.0)* Early-phase HCS work is pinned to Claude Code ≥ `1.3883.0` with Claude Opus 4.7 and Codex ≥ `26.417.41555` with GPT-5.4. Baseline re-evaluation is a gated end-of-Phase-0b task. Subsequent minor updates are acceptable.

## Package boundary enforcement

CI checks at merge time:

- `packages/adapters/**` cannot import from `packages/kernel/src/**` except through the declared public API surface (`packages/kernel/src/api/`).
- `packages/kernel/**` cannot import from `packages/adapters/**` at all.
- `packages/schemas/**` cannot import from anywhere above Ring 0 (no kernel, no adapter, no dashboard imports in schemas).
- Dashboard view contracts (`packages/dashboard/src/contracts/`) are importable by kernel for rendering; kernel modules other than rendering helpers must not import dashboard internals.
- No YAML policy file exists outside `system-config/policies/host-capability-substrate/` or the test fixture directory `packages/fixtures/policies/`.
- No `bash.run`, `shell.exec`, or equivalent universal-shell tool is registered in any capability manifest.
- Every `OperationShape` with `mutation_scope != "none"` has a documented gateway path, a decision-package contract, and a renderer; missing any of these blocks merge.
- *(added in v1.1.0)* No skill content exists only in `.claude/skills/`; every skill has a canonical file at `.agents/skills/<name>/SKILL.md`. `.claude/skills/<name>/SKILL.md` is permitted only when it adds Claude-specific frontmatter on top of the canonical body.
- *(added in v1.1.0)* No file in the repo matches the `$HCS_STATE_DIR` or `$HCS_LOG_DIR` layout — runtime state must never enter the repo.
- *(added in v1.1.0)* No committed file contains a resolved `op://` value or any string matching known secret patterns (gitleaks/forbidden-string scan).

## Authoring rules

When opening a PR:

- Identify the target ring (a single ring per PR is strongly preferred).
- If the PR changes ontology, schemas, JSON Schema, **and** docs must change together.
- If the PR changes policy, the `hcs-policy-reviewer` subagent must produce its objections before human review.
- If the PR changes any ontology entity or schema, the `hcs-ontology-reviewer` subagent must produce its objections before human review. *(v1.1.0)*
- If the PR changes adapter code, confirm no kernel or policy logic leaks in.
- If the PR changes kernel code, confirm no protocol or client-specific assumption leaks in.
- If the PR adds a capability, include the six-question surface boundary answers in the capability's schema description (see research plan §5).
- If the PR adds or edits a skill, the canonical file must be at `.agents/skills/<name>/SKILL.md`. *(v1.1.0)*

## Forbidden patterns (list, not exhaustive)

- Copying tier classification into a hook body
- Hard-coding a `--help` string instead of invoking and caching with provenance
- Treating a shell string as the canonical operation representation
- Exposing `system.audit.log.v1` (or equivalent) as an agent-callable tool
- Registering `bash.run` or a universal shell wrapper
- Promoting sandbox evidence to `authoritative` confidence
- Adding an adapter that conditionally evaluates policy locally
- Writing secrets into any persistent config file
- Adding a capability whose description omits the six-question answers
- Registering an operation whose `forbidden` tier has an `approval_required_for` clause
- *(v1.1.0)* Duplicating a skill into `.claude/skills/` when no Claude-specific wrapper behavior is required
- *(v1.1.0)* Creating `WARP.md` during Phase 0a (Warp prioritizes `WARP.md` over `AGENTS.md`; if ever added post-Phase-0b, must be pointer-only referencing `AGENTS.md`)
- *(v1.1.0)* Duplicating forbidden-pattern literals across `.claude/settings.json`, `.cursor/rules/`, `.vscode/settings.json`, or agent docs — enforcement is `.claude/settings.json` + `.claude/hooks/hcs-hook`; other surfaces are pointers
- *(v1.1.0)* Adding `.windsurf/skills/` or `.windsurf/` project-scope config — Windsurf has no project scope; cross-tool skills live in `.agents/skills/`
- *(v1.1.0)* Committing resolved `op://` values or any secret-pattern match
- *(v1.1.0)* Writing any runtime state, loaded policy copy, or audit archive into the repo

## How to cite this charter

In a PR description:

```markdown
Complies with implementation charter v1.1.0. Ring: {0|1|2|3}. No cross-ring imports added.
```

In a policy objection:

```markdown
Blocked per charter invariant {N}: {quoted invariant}.
```

## Change policy

This charter is amendable. Amendments require:

1. An ADR under `docs/host-capability-substrate/adr/` justifying the change.
2. `hcs-policy-reviewer` and `hcs-security-reviewer` subagent objections filed and addressed. *(v1.1.0: include `hcs-ontology-reviewer` if the amendment touches ontology.)*
3. Human approval.
4. Version bump. Breaking changes bump the major.

Do not amend the charter in the same PR as the change the amendment enables. Charter changes are their own PR.

## References

- Research plan: [`../host-capability-substrate-research-plan.md`](../host-capability-substrate-research-plan.md) (v0.3.0+)
- Boundary decision: [`0001-repo-boundary-decision.md`](./0001-repo-boundary-decision.md) (v1.1.0+)
- Tooling surface matrix: [`tooling-surface-matrix.md`](./tooling-surface-matrix.md) (v1.0.0+)
- Target-repo templates: [`./templates/`](./templates/)
- Existing governance precedents: [`../../policies/version-policy.md`](../../policies/version-policy.md), [`../../policies/opa/policy.rego`](../../policies/opa/policy.rego)

## Change log

| Version | Date | Change |
|---------|------|--------|
| 1.1.0 | 2026-04-22 | Added invariants 9–12 (skills canonical location, public/private deployment boundary, deprecated-syntax refusal, tool version baseline). Extended boundary enforcement with skills-location, runtime-state-not-in-repo, and no-secrets checks. Added forbidden patterns covering skill duplication, WARP.md, cross-surface policy duplication, `.windsurf/` creation, secret commits, and runtime-state commits. Added authoring requirements for `hcs-ontology-reviewer` on schema changes and `.agents/skills/` for skill changes. |
| 1.0.0 | 2026-04-22 | Initial charter. Four rings, eight non-negotiable invariants, CI boundary enforcement, authoring rules, forbidden patterns. |

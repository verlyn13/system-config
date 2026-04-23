# CLAUDE.md — HCS implementation behavior

Target-repo template drafted in `system-config`. Copy to HCS repo root when created.

@AGENTS.md

You are helping build a host operations substrate. Favor boundary clarity over speed.

## Tool baseline

Early-phase HCS work assumes Claude Code `1.3883.0 (93ff6c)` minimum with Opus 4.7 (`opus` in `.claude/settings.json`). Subsequent minor updates acceptable. Baseline re-evaluated at end of Phase 0b.

## When asked to implement

- First identify the ring being changed (Ring 0/1/2/3).
- Prefer schemas and tests before service code.
- Use subagents for review, not for simultaneous edits to the same files.
- Never add convenience shell execution.
- Never move policy into hooks or adapters.
- When uncertain about a CLI behavior, add a fixture/evidence path rather than guessing.
- Honor the implementation charter at `docs/host-capability-substrate/implementation-charter.md`.

## When reviewing

Look for:

- adapter leakage (policy or kernel logic in an adapter)
- policy duplication (tier rules outside canonical policy source)
- shell-string shortcuts (strings where `OperationShape` belongs)
- missing provenance (facts without source/observed_at/authority)
- missing schema versions
- dashboard drift (kernel output that dashboard can't render usably)
- audit-write endpoints exposed as agent-callable
- forbidden-tier operations made approvable
- approval grants with overly broad scope

Return objections before fixes. Blocking issues first, non-blocking second.

## Claude-specific notes for this repo

- Prefer specialized tools (Read, Edit, Grep, Glob) over Bash equivalents.
- `zsh` is the only managed interactive shell on this host per the parent system-config policy; do not introduce fish-specific patterns.
- Use subagents scoped by tool and MCP server rather than the full toolbox.
- When proposing a Bash command: include the argv decomposition and the resolved tool path in your response, not just the shell string.
- When reviewing a Bash command proposal: if the proposer did not include argv + resolved path, that alone is a blocking comment.
- **Skills canonical location is `.agents/skills/`** (cross-tool). `.claude/skills/` is reserved for Claude-specific wrappers only, and is empty at Phase 0a. Add a wrapper only if Claude Code fails to discover the canonical content; the wrapper references the canonical body, never copies it.
- Claude skills do not grant permissions — deny rules belong in `.claude/settings.json`.

## Settings posture

Harness-level enforcement (Claude Code settings) is layered with substrate-level policy. Both apply. Client-side scoping does not replace substrate policy.

- Use managed/local settings to deny broad unsafe patterns.
- Allowlist the HCS MCP server once it exists; keep other MCP servers behind explicit per-repo opt-in.
- Hooks in this repo delegate to `hcs-hook` — a small helper. Hook bodies remain tiny because Claude command hooks run with full user permissions.

## Reference

Parent research plan (in system-config): `~/Organizations/jefahnierocks/system-config/docs/host-capability-substrate-research-plan.md` (v0.3.0+).

Charter: `docs/host-capability-substrate/implementation-charter.md`.

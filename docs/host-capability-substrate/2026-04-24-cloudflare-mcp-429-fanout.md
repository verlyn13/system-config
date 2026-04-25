---
title: Cloudflare MCP 429 Fan-Out Field Report
category: field-report
component: host_capability_substrate
status: active
date: 2026-04-24
tags: [cloudflare, mcp, rate-limit, codemode, fanout, broker]
---

# Cloudflare MCP 429 Fan-Out Field Report

## Summary

The 2026-04-24 Cloudflare MCP 429s are best explained as shared-token
fan-out, not a single broken MCP host. `system-config` makes the authenticated
Cloudflare API MCP available globally to every agentic host, so every open
Claude/Codex/Cursor/Windsurf-style process can hold its own long-lived
`mcp-remote` session against the same Cloudflare token. At the same time,
Cloudflare Codemode lets one `execute` tool call issue multiple
`cloudflare.request()` calls.

The immediate mitigation is operational: one broker agent owns Cloudflare
mutations, all other agents stay read-only, and every agent honors
`last_cf_mcp_429` markers before making more Cloudflare API calls.

## Evidence

- Official Cloudflare API docs state that the client API limit is cumulative
  per user/account token and that exceeding it blocks API calls with HTTP 429
  for the next window.
- Local process inspection on 2026-04-24 found 9 active authenticated
  `node ... mcp-remote https://mcp.cloudflare.com/mcp` sessions:
  2 direct Claude Desktop sessions, 3 Claude Code macOS-app embedded sessions,
  3 Claude Code CLI sessions, and 1 Codex CLI session.
- Claude Desktop logs showed repeated Cloudflare MCP initialize/tools-list and
  transport-close cycles, matching the earlier GUI respawn class. Those logs
  did not show the actual Cloudflare API 429 body.
- The concrete 429 marker was in
  `/Users/verlyn13/Repos/verlyn13/hetzner/docs/system-state/runpod-stack.md`:
  `last_cf_mcp_429: 2026-04-24T22:23:05Z`, with a 5-minute deferred retry for
  a Cloudflare Access Fix A PUT.
- Sibling repos already had a local concurrency rule: one broker owns shared
  control-plane mutations, read-only queries must be coalesced, and HTTP 429
  requires a recorded timestamp plus backoff. That rule had not been promoted
  into the system-level Cloudflare MCP docs.
- Upstream `cloudflare/mcp` retries 429s in its outbound fetch helper, but the
  retry is per underlying request. It does not prevent an agent's Codemode
  JavaScript from using `Promise.all` or loops that create parallel API calls.

## Interpretation

The user-level baseline is doing what it was configured to do: every modern
agentic host gets Cloudflare access. During a soak period, that is useful for
discovery, but it is unsafe as a writer model for a shared external control
plane. The practical rate-limit unit is the Cloudflare token/account, not the
MCP session or the visible tool call.

This means two actions that look safe in isolation can collide:

1. Multiple agents open Cloudflare MCP sessions and inspect Access/DNS/Tunnel
   state at roughly the same time.
2. One agent runs a Codemode `execute` call whose JavaScript performs several
   Cloudflare API requests, possibly in parallel.

Cloudflare sees the aggregate API traffic from the same token/account. Once the
limit is tripped, more probes only extend the outage window for useful work.

## Operating Rule

For Cloudflare MCP work until the host-capability-substrate broker exists:

1. Run `scripts/mcp-cloudflare-diagnostics.sh` before Cloudflare mutations.
2. Pick exactly one broker repo/agent for Cloudflare writes.
3. Avoid `Promise.all` and unbounded loops in `cloudflare.execute`.
4. On HTTP 429, write `last_cf_mcp_429: <iso8601>` in the owner repo state doc
   and stop Cloudflare API traffic for at least 5 minutes or `Retry-After`.
5. Prefer `cloudflare-docs` for documentation questions because it does not
   consume the authenticated Cloudflare API token.

## Substrate Follow-Up

The future host-capability-substrate design should move this from convention to
mechanism:

1. A local broker should hold Cloudflare auth in memory and eliminate bearer
   leakage through `mcp-remote --header` argv.
2. The broker should serialize Cloudflare API traffic per token/account with a
   shared backoff clock.
3. The broker should expose cheap local diagnostics for session fan-out,
   last-429 state, and pending Retry-After windows.
4. GUI hosts should not be allowed to create duplicate authenticated Cloudflare
   sessions without going through the same broker.

## References

- [Cloudflare API rate limits](https://developers.cloudflare.com/fundamentals/api/reference/limits/)
- [Cloudflare's own MCP servers](https://developers.cloudflare.com/agents/model-context-protocol/mcp-servers-for-cloudflare/)
- [`cloudflare/mcp`](https://github.com/cloudflare/mcp)

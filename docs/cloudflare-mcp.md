---
title: Cloudflare MCP Integration
category: reference
component: cloudflare_mcp
status: active
version: 1.3.0
last_updated: 2026-05-08
tags: [cloudflare, mcp, codemode, api-token, bearer, mcp-remote, 1password, workers, dns, zero-trust, tunnel, rate-limit]
priority: high
---

# Cloudflare MCP Integration

Single source of truth for the Cloudflare MCP integration on this system. Read this before calling `cloudflare.search` / `cloudflare.execute`, and before modifying the wrapper or its 1Password item.

For the general MCP framework (sync, scope model, launch patterns) see
[`docs/mcp-config.md`](./mcp-config.md). For the GitHub MCP (parallel
structure, different per-host rendering), see
[`docs/github-mcp.md`](./github-mcp.md). For the Claude-Desktop-specific
auth cycle that informs how this wrapper is designed, see the field
report at
[`docs/host-capability-substrate/2026-04-23-claude-desktop-op-consent-cycle.md`](./host-capability-substrate/2026-04-23-claude-desktop-op-consent-cycle.md).
For the 2026-04-24 Cloudflare 429 fan-out investigation, see
[`docs/host-capability-substrate/2026-04-24-cloudflare-mcp-429-fanout.md`](./host-capability-substrate/2026-04-24-cloudflare-mcp-429-fanout.md).
For the substrate-era broker target, see
[`docs/host-capability-substrate/2026-04-24-control-plane-broker-design.md`](./host-capability-substrate/2026-04-24-control-plane-broker-design.md).
For the Access + Tunnel AUD coupling lesson from the runpod 403, see
[`docs/host-capability-substrate/2026-04-25-cloudflare-access-tunnel-audtag.md`](./host-capability-substrate/2026-04-25-cloudflare-access-tunnel-audtag.md).

## At-a-glance

| Item | Value |
|---|---|
| User-level MCP entries | `cloudflare` (auth'd) and `cloudflare-docs` (no auth) |
| Remote endpoint (auth'd) | `https://mcp.cloudflare.com/mcp` (Codemode) |
| Remote endpoint (docs) | `https://docs.mcp.cloudflare.com/mcp` (no auth) |
| Local wrapper | `~/.local/bin/mcp-cloudflare-server` (stdio via `mcp-remote`) |
| Chezmoi source | `home/dot_local/bin/executable_mcp-cloudflare-server.tmpl` |
| Token op URI | wired alias, currently cleared: `op://Dev/cloudflare-mcp-jefahnierocks/token`; replacement staging: `op://Dev/cloudflare-jefahnierocks-mcp-readonly/credential` |
| Token account | current personal-custody Cloudflare account (`13eb584192d9cefb730fde0cfd271328`) |
| Token TTL | replacement staging credential valid 2026-05-08 → 2026-11-04; old `cloudflare-mcp-jefahnierocks` token and prior replacement were deleted in Cloudflare UI |
| Transport to Cloudflare | Streamable HTTP via `mcp-remote@0.1.38` stdio relay |
| Tools exposed by the auth'd server | `search`, `execute` — see §Codemode |
| Rate-limit surface | Cloudflare API rate limits apply cumulatively to the underlying token |
| Local no-API diagnostic | `scripts/mcp-cloudflare-diagnostics.sh` |
| Local quarantine toggle | `scripts/mcp-cloudflare-quarantine.sh` |

## Per-host wiring

Unlike GitHub MCP (which is rendered in four distinct shapes per host), Cloudflare MCP is written **uniformly** as the stdio wrapper across all six sync targets. `scripts/sync-mcp.sh` writes the same `command: "${HOME}/.local/bin/mcp-cloudflare-server"` entry to each host, with per-host format adjustments (e.g. Claude Desktop strips `type`, Codex TOML becomes `[mcp_servers.cloudflare]`).

| Host | Config file | Entry shape |
|---|---|---|
| Claude Code CLI | `~/.claude.json` | `{"type": "stdio", "command": "~/.local/bin/mcp-cloudflare-server"}` |
| Claude Desktop | `~/Library/Application Support/Claude/claude_desktop_config.json` | `{"command": "~/.local/bin/mcp-cloudflare-server"}` (no `type`) |
| Cursor | `~/.cursor/mcp.json` | same as Claude Code CLI |
| Windsurf | `~/.codeium/windsurf/mcp_config.json` | same as Claude Code CLI |
| Copilot CLI | `~/.copilot/mcp-config.json` | same as Claude Code CLI |
| Codex CLI | `~/.codex/config.toml` | `[mcp_servers.cloudflare]\ncommand = "~/.local/bin/mcp-cloudflare-server"` |

Uniform stdio-via-wrapper is the right shape for this server because Cloudflare's remote MCP gateway advertises OAuth discovery; some MCP SDKs attempt Dynamic Client Registration even when a static bearer is present and fail with `InvalidTokenError: Failed to verify token: no user or account information` before honoring the Authorization header. The wrapper routes through `mcp-remote` which bypasses that discovery path.

Uniform user-level wiring is not a concurrency guarantee. Each open host can
spawn its own long-lived authenticated `mcp-remote` process against the same
Cloudflare token. During control-plane work, choose one broker agent for
mutations and keep the other hosts read-only or closed.

## Token identity and scope

The replacement token target is not account-wide. It needs `User Details Read`
so Cloudflare's MCP gateway can resolve a user identity, plus zone-scoped
`Zone Read` and `DNS Read` for `jefahnierocks.com` only. Earlier zone-only
tokens without user identity metadata were rejected with "no user or account
information"; that is not a reason to grant account-wide read or write scope.

2026-05-08 rotation staging: the currently wired alias
`op://Dev/cloudflare-mcp-jefahnierocks/token` has been cleared and marked
blocked. The replacement value is stored in the staging item
`op://Dev/cloudflare-jefahnierocks-mcp-readonly/credential`, verified, and
not runtime-wired. Do not wire any staging alias into the wrapper until the
replacement bridge no longer passes bearer material through process argv.

**Resolvable identity checks after human credential entry:**

```bash
TOKEN="$(op read --account my.1password.com 'op://Dev/cloudflare-jefahnierocks-mcp-readonly/credential')"
curl -sS -K - https://api.cloudflare.com/client/v4/user <<EOF | jq .result.email
header = "Authorization: Bearer $TOKEN"
EOF
unset TOKEN
```

**Replacement target scope** — read-only `jefahnierocks.com` inspection only:

- User permissions: `User Details Read`
- Zone resources: include the `jefahnierocks.com` zone only
- Zone permissions: `Zone Read`, `DNS Read`

This matches the Citadel Entry 7 split decision for
`cloudflare/jefahnierocks/mcp-readonly`: MCP/tooling may inspect the
Jefahnierocks zone, but it must not mutate Cloudflare and must not read across
other entity zones. Do not grant account-wide reads or write/edit permissions
to this token. If a Cloudflare mutation workflow is needed, create a separate
mutation-broker credential with a narrower logical path, explicit stop rules,
and provider-side evidence.

**Historical build-out scope set** — this was intentionally broad during the
initial 30-day build-out period and is not the replacement target:

- Identity (required): `User Details: Read`, `Account Settings: Read`
- Workers platform: `Workers Scripts: Edit`, `KV: Edit`, `R2: Edit`, `Tail: Read`, `Builds: Edit`, `Observability: Edit`, `D1: Edit`, `Queues: Edit`, `Vectorize: Edit`, `AI Gateway: Edit`, `AI Search: Edit`
- Pages: `Cloudflare Pages: Edit`
- DNS / zones: `Zone: Read`, `DNS: Edit`, `Zone Settings: Edit`, `Cache Purge`, `SSL & Certificates: Edit` (zone scope), `Page Rules: Edit`
- Zero Trust: `Cloudflare Tunnel: Edit`, `Access: Apps and Policies: Edit`, `Access: IdP / Orgs / Groups: Edit`, `Access: Service Tokens: Edit`
- Observability: `Account Analytics: Read`, `Zone Analytics: Read`, `Logs: Read`, `Audit Logs: Read`
- Utility: `Radar: Read`, `Browser Rendering: Edit`

**Explicitly excluded** (organizational standard):

- `Account API Tokens: Edit` (master-key equivalent; can mint new tokens)
- `User API Tokens: Edit`
- `Memberships: Edit`
- `Billing: Edit`

**Pruning policy:** do not issue a replacement with the historical breadth
unless rebuild-out is active and separately approved.

## Codemode — how the `search` and `execute` tools actually work

The Cloudflare API MCP server uses [Codemode](https://developers.cloudflare.com/agents/api-reference/codemode/), a technique where the model writes JavaScript against a typed OpenAPI-spec representation rather than calling individual tool definitions per endpoint. Two tools cover all 2,500+ endpoints.

### `search(code: string)`

Runs a JavaScript arrow function against an in-memory OpenAPI spec, inside a Dynamic Worker sandbox. Returns whatever the function returns.

Available in-sandbox:

```typescript
interface OperationInfo {
  summary?: string;
  description?: string;
  tags?: string[];
  parameters?: Array<{ name: string; in: string; required?: boolean; schema?: unknown; description?: string }>;
  requestBody?: { required?: boolean; content?: Record<string, { schema?: unknown }> };
  responses?: Record<string, { description?: string; content?: Record<string, { schema?: unknown }> }>;
}

interface PathItem {
  get?: OperationInfo;
  post?: OperationInfo;
  put?: OperationInfo;
  patch?: OperationInfo;
  delete?: OperationInfo;
}

declare const spec: {
  paths: Record<string, PathItem>;
};
```

Example — find all Workers endpoints:

```javascript
async () => {
  const results = [];
  for (const [path, methods] of Object.entries(spec.paths)) {
    for (const [method, op] of Object.entries(methods)) {
      if (op.tags?.some(t => t.toLowerCase() === 'workers')) {
        results.push({ method: method.toUpperCase(), path, summary: op.summary });
      }
    }
  }
  return results;
}
```

Example — inspect request body for creating a D1 database:

```javascript
async () => {
  const op = spec.paths['/accounts/{account_id}/d1/database']?.post;
  return { summary: op?.summary, requestBody: op?.requestBody };
}
```

**When `search` is the right tool:** discovering endpoints, inspecting schemas, planning a multi-step operation before committing to it. Always search before execute.

### `execute(code: string)`

Runs a JavaScript arrow function against the live Cloudflare API, inside the same sandbox. Available in-sandbox:

```typescript
interface CloudflareRequestOptions {
  method: "GET" | "POST" | "PUT" | "PATCH" | "DELETE";
  path: string;
  query?: Record<string, string | number | boolean | undefined>;
  body?: unknown;
  contentType?: string;  // defaults to application/json
  rawBody?: boolean;     // if true, body passed as-is
}

interface CloudflareResponse<T = unknown> {
  success: boolean;
  result?: T;
  errors?: Array<{ code: number; message: string }>;
  messages?: Array<{ code: number; message: string }>;
  result_info?: { page: number; per_page: number; count: number; total_count: number };
}

declare const cloudflare: {
  request<T = unknown>(options: CloudflareRequestOptions): Promise<CloudflareResponse<T>>;
};

// Also available: the account id the token resolves to, if Codemode injects it.
// Prefer using the account id returned by `/accounts` on first use.
```

Example — list zones in the account:

```javascript
async () => {
  const response = await cloudflare.request({
    method: "GET",
    path: "/zones",
    query: { per_page: 50 }
  });
  if (!response.success) return { error: response.errors };
  return response.result.map(z => ({ id: z.id, name: z.name, status: z.status }));
}
```

Example — read a DNS record:

```javascript
async () => {
  const zone = "8d5f44e67ab4b37e47b034ff48b03099";  // jefahnierocks.com
  const response = await cloudflare.request({
    method: "GET",
    path: `/zones/${zone}/dns_records`,
    query: { type: "A", name: "api.jefahnierocks.com" }
  });
  return response.result;
}
```

**When `execute` is the right tool:** you already know the endpoint path + shape (often from a prior `search` call), and you're ready to make the live call. Prefer read-only calls first; confirm with the user before any write.

Important implementation detail: `execute` runs caller-supplied JavaScript,
so one tool call can issue many `cloudflare.request()` calls. The upstream
server retries HTTP 429 responses internally a few times, but that retry loop
is per request, capped, and does not serialize multiple requests created by
your code. Treat each `cloudflare.request()` as a real Cloudflare API call.

## Usage guidance for agents

### When to use which tool

| Task | Preferred tool | Reason |
|---|---|---|
| Look up Cloudflare documentation, concepts, product relationships | `cloudflare-docs` MCP | No auth; designed for retrieval; doesn't count against API rate limits |
| Discover an API endpoint or inspect request/response schemas | `cloudflare.search` | Structured access to the live OpenAPI spec |
| Make a read-only API call (list zones, get DNS records, inspect Worker config) | `cloudflare.execute` | One call, typed, with proper auth |
| Workers development cycle (deploy, tail, test) | `wrangler` CLI | Faster, designed for the inner loop, better dev ergonomics |
| Scripted infra automation checked into a repo | direct `curl`/SDK in committed scripts | Reproducible, diffable, reviewable; MCP is interactive, not CI |
| Understanding an error from Cloudflare | `cloudflare.execute` on `/user/tokens/verify` + docs MCP | Verify token state first, then look up the error code |

### Rate-limit and concurrency discipline

Cloudflare's documented global API limit applies cumulatively per user/account
token across dashboard, API key, and API-token traffic. When exceeded, API
calls are blocked with HTTP 429 for the next window. The shared
`cloudflare-mcp-jefahnierocks` token therefore needs cross-agent discipline,
not just per-agent backoff.

Before any `cloudflare.execute` that may mutate state:

1. Run `scripts/mcp-cloudflare-diagnostics.sh`. It only inspects local
   processes, logs, and state markers; it does not call Cloudflare.
2. If more than one authenticated Cloudflare MCP session is live, pick one
   broker agent/repo for the mutation. Other agents should observe, write
   follow-up markers, or wait.
3. Check any `last_cf_mcp_429` marker in the owning project's current-state
   doc. If the timestamp is less than 5 minutes old, or `Retry-After` was
   longer, do not probe for recovery yet.

Inside `execute` code:

1. Do not use `Promise.all` or other parallel fan-out around
   `cloudflare.request()`.
2. Bound pagination and use conservative `per_page` values; do not poll.
3. Prefer one reversible mutation per `execute` call after explicit human
   authorization for that specific mutation.
4. Coalesce read-only diagnostics into one serial function when possible.

On HTTP 429:

1. Stop all Cloudflare MCP reads and writes immediately.
2. Record `last_cf_mcp_429: <iso8601>` in the owner repo's current-state doc.
3. Defer Cloudflare API traffic for at least 5 minutes, or the longer
   `Retry-After` if present.
4. The first call after the backoff should be a purposeful read needed to
   continue the work, not a loop that tests whether the limit has cleared.

If dashboard, Wrangler, curl, or MCP calls keep tripping 429, quarantine the
authenticated Cloudflare MCP wrapper so agent development can continue without
Cloudflare API traffic:

```bash
scripts/mcp-cloudflare-quarantine.sh on
scripts/mcp-cloudflare-quarantine.sh reap
scripts/mcp-cloudflare-diagnostics.sh
```

This creates
`~/.local/state/system-config/mcp-cloudflare.disabled`. The live wrapper and
chezmoi template check this marker before resolving the token or launching
`mcp-remote`. `cloudflare-docs` remains available because it is unauthenticated
and does not use the Cloudflare account API token. Re-enable only after the
quiet window and planned single-client retry:

```bash
scripts/mcp-cloudflare-quarantine.sh off
```

For Access service-token 403s, do not expect the Zero Trust dashboard Access
authentication log or REST `access_requests` endpoint to show the decisive row.
Cloudflare classifies service-token attempts as non-identity authentication;
those events are retrieved through GraphQL Analytics. Use the one-shot helper
while authenticated Cloudflare MCP remains quarantined:

```bash
scripts/cloudflare-access-login-graphql.sh plan \
  --ray-id <ray-id-with-or-without-colo> \
  --since <iso8601> \
  --until <iso8601>
```

Only after explicit approval, change `plan` to `run`. The helper refuses to run
if authenticated Cloudflare MCP sessions are live.

Interpret the GraphQL result before proposing Access policy mutations. If the
row has `isSuccessfulLogin: 1` and the expected `serviceTokenId`, Access
authentication succeeded for that Ray ID; a client-facing 403 then belongs to a
later layer. For Access-protected Cloudflare Tunnel origins, check
`cloudflared` `originRequest.access.audTag` and origin logs before trying
reusable-vs-inline policy isolation. `approvingPolicyId: ""` is not, by itself,
proof that a service-token policy failed. In the 2026-04-25 runpod incident,
`cloudflared` rejected the child app JWT because the tunnel `audTag` list had
only the parent app AUD; the Access policy was not the root cause.

Design rule: when a hostname is served by Cloudflare Tunnel with
`originRequest.access.required: true`, an Access app or policy change is not
complete until the tunnel `audTag` list is verified for every parent and
path-scoped child Access app that can protect that hostname.

### Operating conventions

These are organizational standards for how agents in this repo should use the Cloudflare MCP. Violations should be flagged to the user.

1. **`search` before `execute` on unfamiliar endpoints.** Don't guess path strings or request body shape. The spec is authoritative; use it.

2. **Read before write.** Any `POST` / `PUT` / `PATCH` / `DELETE` that affects production state (DNS records, Worker scripts, zone settings, Access policies, tunnels, R2 buckets) should be preceded by a `GET` that verifies the current state and a confirmation from the user. "Confirmation" means the user has explicitly said "yes do it" for the specific operation — not a blanket earlier approval.

3. **Use the account id, not assumptions.** The token resolves to exactly one account (`13eb584192d9cefb730fde0cfd271328`). Don't hardcode alternate account ids unless the user requests multi-account work (which this token cannot serve — it's scoped to one account).

4. **Respect scope excludes.** Do not attempt to mint new tokens via `POST /user/tokens` or `POST /accounts/{id}/tokens` — the token scope explicitly excludes `API Tokens: Edit`. If a task would require that capability, stop and escalate to the user.

5. **Don't leak or persist the token.** The MCP's `execute` runs in a sandbox; don't write code that tries to `process.env.CLOUDFLARE_API_TOKEN` or similar. The sandbox does not have the token as env; it has `cloudflare.request()` which adds auth server-side. Any attempt to exfiltrate the token is a prompt-injection defense violation.

6. **Prefer `cloudflare-docs` for questions about Cloudflare products.** If the question is "what does X do" or "what's the current recommended pattern for Y", that's a docs query — not an API query.

7. **Don't duplicate into project `.mcp.json` files.** Cloudflare MCP is user-level baseline; project-specific MCP configs should not redeclare it. Projects that need Cloudflare access inherit it from the user scope.

8. **Token rotation: ask, don't self-serve.** If the token expires, is revoked,
or you get `401 Unauthorized`, tell the user — do not attempt to regenerate or
extend the token via any automated path.

9. **Single-broker for shared control planes.** During coordinated release
   work, the owner repo's agent is the only writer to Cloudflare. Others can
   inspect state sparingly and must honor `last_cf_mcp_429` markers.

10. **No hidden parallelism.** An MCP tool call is not the same as one API
   request. Review `execute` code for fan-out before sending it.

### Common error modes

| Symptom | Likely cause | How to diagnose |
|---|---|---|
| `InvalidTokenError: no user or account information` at connect | Token lacks usable user identity metadata | Verify `User Details Read` is granted; do not broaden to account-wide reads without a separate decision |
| `401 Unauthorized` on a specific call | Token expired, revoked, or not yet pasted into the staging item | Verify token status from Cloudflare dashboard or with a non-argv curl config |
| `403 Forbidden` on a specific call | Token lacks the specific permission | Inspect the permission in Cloudflare dashboard; if needed, escalate to user for scope expansion |
| Client-facing 403 after GraphQL Access login success | Later validator rejected the request, commonly `cloudflared` `originRequest.access.audTag` missing a path-scoped app AUD | Check `cloudflared` logs for `AccessJWTValidator`, inspect tunnel `audTag`, then origin logs before Access policy mutations |
| `429 Too Many Requests` | Token/account shared rate limit exhausted, often from multi-agent fan-out or repeated retries | Stop; run `scripts/mcp-cloudflare-diagnostics.sh`; record `last_cf_mcp_429`; wait 5 minutes or `Retry-After` |
| `400 Bad Request` with schema errors | Request body doesn't match the OpenAPI shape | Re-run `search` on the endpoint; inspect `op.requestBody.content['application/json'].schema` |
| `search` or `execute` hangs >30s | MCP server startup (cold start on first call) or network slowness | Wait once; if persistent, check `claude mcp list` — should show `✓ Connected` |
| MCP fails to start entirely | 1Password session cold (biometric needed) | `op whoami --account my.1password.com` in terminal to pre-warm |

## Security posture

### What the wrapper protects

- The token is never written into any host config file (all client configs just reference the wrapper command).
- `mcp-remote` runs with `--silent` so the `Authorization: Bearer` header is not logged to stderr (and therefore not into host log files).
- The token is resolved from 1Password at wrapper launch, env-first then `op read` fallback.

### What the wrapper does NOT protect (current limitation)

**The token is exposed in the `mcp-remote` child process's argv.** The wrapper's final `exec` is:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

exec "$SCRIPT_DIR/mcp-npx" -y "mcp-remote@${MCP_REMOTE_VERSION}" \
  "$REMOTE_URL" \
  --transport http-only \
  --silent \
  --header "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}"
```

Once exec'd, the bearer token appears in the process's argv. Any process running as the same macOS user can read it via `ps -eo args`. Examples of "same user processes":

- Any npm package postinstall script run in the same user session
- Any Python/Node library that enumerates processes
- Malicious code in a repo opened in an editor that spawns language servers

This is not a config error; it's structural to `mcp-remote`'s `--header` flag. The substrate's MCP auth adapter (future work — see [field report](./host-capability-substrate/2026-04-23-claude-desktop-op-consent-cycle.md)) will eliminate this by becoming the HTTP client itself and holding the bearer in memory only.

**Mitigations in the current design:**

- 30-day token TTL limits exposure window.
- Over-permissive token scopes are build-out-only; pruning at expiry is the plan.
- `Account API Tokens: Edit` is excluded so a leaked token cannot bootstrap more tokens.
- 1Password-sourced, never at rest in any config.

### Threat model for this token

| Concern | Rating | Notes |
|---|---|---|
| Token leaks via `ps` | **High if relaunched through `mcp-remote --header`** | Wired alias is cleared; do not relaunch authenticated Cloudflare MCP until the no-argv bridge exists |
| Token leaks via host log files | Low | `--silent` + wrapper stdio; not observed |
| Token leaks via `.mcp.json` / committed config | None | Never written to disk; not possible under current design |
| Unauthorized account enumeration | Low | Replacement target has no account-wide read permission |
| Zone-wide destructive action | None for replacement target | Replacement target is read-only for `jefahnierocks.com`; writes require a separate mutation-broker credential |
| Account takeover via new token mint | None | `API Tokens: Edit` excluded |
| Billing changes | None | `Billing: Edit` excluded |

## Wrapper details

Source: `home/dot_local/bin/executable_mcp-cloudflare-server.tmpl` (chezmoi-managed, deployed to `~/.local/bin/mcp-cloudflare-server`).

Behavior summary:

1. If `CLOUDFLARE_API_TOKEN` is set in env, use it (fast path for `op run --env-file` launches).
2. Else, if `op` is on PATH, `op read --account my.1password.com 'op://Dev/cloudflare-mcp-jefahnierocks/token'`.
3. If neither path yields a token, print a helpful error to stderr and exit 1.
4. `exec ~/.local/bin/mcp-npx -y mcp-remote@0.1.38 https://mcp.cloudflare.com/mcp --transport http-only --silent --header "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}"`.

The wrapper is uniform across all six sync targets. Different hosts may launch it with different working directories and env-var presence, but the auth resolution logic handles both cases (env-first with `op` fallback).

## Verification

```bash
# 1. Token resolves from 1Password
op read --account my.1password.com 'op://Dev/cloudflare-mcp-jefahnierocks/token' >/dev/null \
  && echo "token resolves"

# 2. Token passes Cloudflare identity resolution (required for MCP gateway)
TOKEN="$(op read --account my.1password.com 'op://Dev/cloudflare-mcp-jefahnierocks/token')"
curl -s -H "Authorization: Bearer $TOKEN" https://api.cloudflare.com/client/v4/user \
  | jq -e '.success == true'  # should output "true"

# 3. MCP gateway accepts the token
curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "MCP-Protocol-Version: 2025-06-18" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"smoke","version":"0"}}}' \
  https://mcp.cloudflare.com/mcp \
  | jq -e '.result.serverInfo.name == "cloudflare-api"'  # should output "true"

# 4. Wrapper produces a clean MCP handshake end-to-end
( printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"smoke","version":"0"}}}\n'; sleep 15 ) \
  | timeout 25 ~/.local/bin/mcp-cloudflare-server \
  | jq -e '.result.serverInfo.name == "cloudflare-api"'

# 5. Host-level connectivity (Claude Code CLI)
claude mcp list | grep -E "^cloudflare"
#   expected: "cloudflare: /Users/.../mcp-cloudflare-server  - ✓ Connected"
#             "cloudflare-docs: https://docs.mcp.cloudflare.com/mcp (HTTP) - ✓ Connected"

unset TOKEN
```

## Lifecycle

### Incident rotation

1. In Cloudflare dashboard (`https://dash.cloudflare.com/profile/api-tokens`):
   create a successor token named `cloudflare/jefahnierocks/mcp-readonly`.
   Use the replacement target scope above: `User Details Read` plus
   `Zone Read` and `DNS Read` on `jefahnierocks.com` only.
2. During the current incident response, paste the new token into the staging
   1P item `cloudflare-jefahnierocks-mcp-readonly`, built-in field
   `credential`, from the 1Password GUI:
   - Do not paste the value into the wired `cloudflare-mcp-jefahnierocks`
     alias until the no-argv bridge is in place.
   - Update `valid-from` and `expires` dates.
3. Revoke the provider token currently named `cloudflare-mcp-jefahnierocks`.
   Parent-side notes say it was narrowed to read-only but kept the same value,
   so narrowing did not close the argv-exposure incident.
4. Do not relaunch the authenticated Cloudflare MCP wrapper until the no-argv
   bridge is implemented and wired to the staging alias.

### Emergency revocation

If the token is suspected compromised:

1. Immediately revoke in Cloudflare dashboard. Token goes 401 within minutes; all running MCP sessions lose auth at next call.
2. Issue successor token and update 1P item (as above).
3. Audit recent usage: `GET /accounts/{id}/audit_logs?since=<leak_time>` to see every call made.
4. If destructive calls appear in the audit log that weren't authorized, escalate beyond this integration.

### Adding scopes mid-cycle

If a Cloudflare MCP operation returns `403 Forbidden` and the call is legitimate:

1. Stop. Do not retry or try to work around it.
2. Identify the specific permission needed (Cloudflare's dashboard shows this for most 403s).
3. Ask the user whether to expand the token's scope for the remainder of the TTL. This is a human decision, not an agent decision.

## Related files

| File | Role |
|---|---|
| `scripts/mcp-servers.json` | Baseline entries for `cloudflare` and `cloudflare-docs` |
| `scripts/sync-mcp.sh` | Propagates entries to 6 host configs |
| `scripts/cloudflare-access-login-graphql.sh` | One-shot GraphQL Analytics reader for Access service-token login events |
| `scripts/mcp-cloudflare-diagnostics.sh` | Local-only fan-out, log, and `last_cf_mcp_429` inspection without API calls |
| `scripts/mcp-cloudflare-quarantine.sh` | Local disable/reap switch for authenticated Cloudflare MCP during 429 containment |
| `home/dot_local/bin/executable_mcp-cloudflare-server.tmpl` | Chezmoi template; deployed to `~/.local/bin/mcp-cloudflare-server` |
| `home/dot_config/mcp/private_common.env` | Manifest including `CLOUDFLARE_API_TOKEN=op://Dev/cloudflare-mcp-jefahnierocks/token` |
| `docs/mcp-config.md` | MCP framework (scope model, sync behavior, launch patterns) |
| `docs/github-mcp.md` | Parallel integration doc for GitHub MCP |
| `docs/secrets.md` | 1Password policy; lists the `mcp-cloudflare-server` wrapper |
| `docs/project-conventions.md` | Lists the `cloudflare-mcp-jefahnierocks` 1P item |
| `docs/host-capability-substrate/2026-04-23-claude-desktop-op-consent-cycle.md` | Field report explaining the wrapper pattern's GUI-host interaction |
| `docs/host-capability-substrate/2026-04-24-cloudflare-mcp-429-fanout.md` | Field report for multi-agent Cloudflare MCP fan-out and 429 handling |
| `docs/host-capability-substrate/2026-04-25-cloudflare-access-tunnel-audtag.md` | Field report and HCS design rule for Access app AUDs behind `cloudflared` JWT validation |

## External references

- [Cloudflare's own MCP servers](https://developers.cloudflare.com/agents/model-context-protocol/mcp-servers-for-cloudflare/) — official catalog of all 13 Cloudflare MCP servers (we use 2)
- [Cloudflare API rate limits](https://developers.cloudflare.com/fundamentals/api/reference/limits/) — official 429, `retry-after`, and cumulative API token limit behavior
- [Cloudflare Access authentication logs](https://developers.cloudflare.com/cloudflare-one/insights/logs/dashboard-logs/access-authentication-logs/) — identity-vs-non-identity logging split
- [Querying Access login events with GraphQL](https://developers.cloudflare.com/analytics/graphql-api/tutorials/querying-access-login-events/) — GraphQL query shape for Access 403 Ray IDs
- [Cloudflare Tunnel origin parameters](https://developers.cloudflare.com/tunnel/advanced/origin-parameters/) — `originRequest.access.required` and `audTag` validation at `cloudflared`
- [`cloudflare/mcp` on GitHub](https://github.com/cloudflare/mcp) — canonical source for the Cloudflare API MCP server
- [Cloudflare Codemode](https://developers.cloudflare.com/agents/api-reference/codemode/) — the technique powering `search` + `execute`
- [Cloudflare API reference](https://developers.cloudflare.com/api/) — 2,500+ endpoints; the MCP is a view over this

## Change log

| Version | Date | Change |
|---|---|---|
| 1.2.0 | 2026-04-25 | Records Access + Tunnel AUD coupling: service-token Access success can still 403 at `cloudflared` when `originRequest.access.audTag` lacks a child app AUD. |
| 1.1.0 | 2026-04-24 | Adds Cloudflare 429 fan-out diagnosis, single-broker rate-limit discipline, and local no-API diagnostic script. |
| 1.0.0 | 2026-04-23 | Initial doc. Matches the Cloudflare MCP state after commit `946a058` (sync to Claude Desktop) and `9210aae` (account-scoped token). |

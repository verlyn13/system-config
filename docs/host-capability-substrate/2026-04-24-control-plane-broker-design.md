---
title: Control-Plane Broker Design
category: design
component: host_capability_substrate
status: active
date: 2026-04-24
updated: 2026-04-25
tags: [broker, mcp, cloudflare, access, tunnel, cloudflared, service-auth, rate-limit, substrate]
---

# Control-Plane Broker Design

## Problem

The 2026-04-24 Cloudflare Access incident exposed three coupled problems:

1. The workstation has many agentic MCP clients that can independently reach
   the same external control plane through one shared token.
2. The Cloudflare Access mutation itself was reasoned about as a one-off delta
   instead of as a typed operation with a policy model, evidence, rollback, and
   rate-limit state.
3. The Access app was treated as the full authorization boundary even though
   the host tunnel connector had its own Access JWT audience validator.

The correct fix is not another local convention or `flock` wrapper. The target
shape is a host-local control-plane broker in the host-capability-substrate
kernel. Until that exists, `system-config` docs and scripts define a strict
manual approximation.

## Cloudflare Access Facts

These are design inputs from Cloudflare's current public docs and the observed
runpod Access state.

- Service-token callers must use a policy action of **Service Auth**. In the API
  this is `decision: "non_identity"`.
- A self-hosted Access app is deny-by-default. Human/browser users need an
  `Allow` policy that matches an IdP-backed identity.
- Service Auth policies are evaluated before Bypass, Block, and Allow policies.
  Precedence numbers order policies within the relevant action group; an Allow
  policy with precedence 1 does not run before a Service Auth policy.
- If an Access app has only Service Auth policies, callers must send the
  service token on every request. Cloudflare's JWT/cookie shortcut for
  subsequent requests only works when the app has at least one Allow policy.
- Updating an Access app is a full-document `PUT`; preserve existing writable
  fields and change the minimum field set.
- Access authentication logs split identity and non-identity events. The Zero
  Trust dashboard and REST `access_requests` endpoint are identity-focused; they
  are not the right source for service-token failures.
- Service-token failures are non-identity authentication events. Use the
  GraphQL Analytics API dataset `accessLoginRequestsAdaptiveGroups`, filtered
  by the bare Ray ID, to retrieve fields such as `identityProvider`,
  `serviceTokenId`, `approvingPolicyId`, and `isSuccessfulLogin`.
- A successful Access authentication event is not the same as an end-to-end
  upstream HTTP success. When a request traverses a Cloudflare Tunnel with
  `originRequest.access.required: true`, `cloudflared` also validates the
  `Cf-Access-Jwt-Assertion` header before proxying to the origin. The
  tunnel-side `audTag` allow-list must include every Access application AUD
  that can protect that hostname/path.

## Current Runpod Incident Outcome

The reported Fix B, "attach `allow-admin-emails` to the child app", was the
wrong default for this incident. It may clear symptoms for a caller that is
trying to exchange the service token once and then reuse only the Access
JWT/cookie, but the runpod caller sends service-token headers on every request.
For this server-to-server internal path, the cleaner target remains:

1. Keep the path-scoped child app machine-only.
2. Keep a `decision: "non_identity"` policy scoped to the exact service token.
3. Send `CF-Access-Client-Id` and `CF-Access-Client-Secret` on every
   server-to-server request.
4. Do not rely on a Cloudflare Access JWT/cookie for this internal call path
   unless a documented client constraint requires it.

If JWT/cookie reuse is a hard requirement, adding an Allow policy is an
intentional product workaround and must be recorded as such. Prefer a dedicated
child-app policy over reusing a broad admin policy when Cloudflare accepts a
tighter selector. Reusing `allow-admin-emails` is reversible and mirrors the
working parent, but it also authorizes admin browser identities against the
internal path. That is a real exposure change even if the origin currently
rejects wrong methods or malformed bodies.

The 2026-04-25 follow-up added the decisive discriminator: if GraphQL shows
`isSuccessfulLogin: 1` and the correct `serviceTokenId`, Access authentication
has succeeded for that Ray ID. Do **not** jump to inline-policy isolation or an
Allow-policy workaround from that evidence. First classify the response after
Access approval:

1. Check whether the origin saw the request. For the runpod webui, deployed
   `v0.5.2` does not contain `/api/internal/run-published`, so a request that
   reaches FastAPI should return 404, not 403.
2. Check `cloudflared` logs and live tunnel config. A hostname-level
   `originRequest.access.audTag` list that contains only the parent/root app AUD
   will reject a child path-app JWT after the edge has already approved it.
3. If the origin did not see the request and `cloudflared` rejected the JWT,
   fix the tunnel `audTag` list, not the Access policy.
4. If `cloudflared` forwarded the request and the origin returned 403, debug
   origin/app behavior.
5. Only if GraphQL shows `isSuccessfulLogin: 0` or no service token association
   should B1/B2 Access-policy isolation remain the next default step.

Confirmed for the runpod incident: `cloudflared` logged
`AccessJWTValidator` rejecting the child app AUD
`44250efc94fc220ee27bb3a7a8f4bbbc34976ca27c1292dc3256cb09b3f7c4fd`
because `/etc/cloudflared/config.yml` only allowed the parent/root app AUD
`eb7da8adc85626f6c5e001fc65a6555d4e40d73ba5cbba5b0fa5677d00247e0d`
for `runpod.jefahnierocks.com`. The request did not reach FastAPI. The fix is
to add the child AUD to the existing tunnel `audTag` list, validate the tunnel
config, and reload `cloudflared`. This is a host config change, not a
Cloudflare Access policy change.

The design pattern is captured in
[`2026-04-25-cloudflare-access-tunnel-audtag.md`](./2026-04-25-cloudflare-access-tunnel-audtag.md).

## Immediate Manual Workflow

Before any new Cloudflare Access or Tunnel mutation:

1. Run `scripts/mcp-cloudflare-diagnostics.sh`.
2. Inspect `last_cf_mcp_429` markers in the owning repo state docs.
3. Identify the intended auth flow:
   - `service-token-every-request`: expected for server-to-server internal
     APIs; no Allow policy should be needed.
   - `service-token-exchange-then-jwt`: requires at least one Allow policy on
     the app per Cloudflare docs.
4. Identify every validator in the request path:
   - Cloudflare Access edge policy
   - `cloudflared` `originRequest.access` JWT validation
   - WAF / account security rules, if enabled
   - origin application behavior
5. Produce a decision package:
   - owner repo and resource ids
   - current app and policy shape
   - proposed full-document `PUT` body hash or redacted body
   - expected evaluator behavior
   - pass/fail tests
   - rollback `PUT`
   - rate-limit budget and last-429 state
   - tunnel AUD impact when the hostname is served by Cloudflare Tunnel
6. Get operator approval for exactly one reversible mutation.
7. Execute one mutation, then stop and record before/after evidence.

For the current `runpod-review-webui-internal` app, the caller has already been
confirmed as `service-token-every-request`, and the root cause has been
confirmed as tunnel-side AUD validation. Fix B is blocked unless a future
GraphQL event shows Access authentication failure instead of post-Access
tunnel rejection.

## Emergency Quarantine

When Cloudflare returns 429 from dashboard, Wrangler, curl, or MCP, development
should not remain blocked. Instead, temporarily disable only the authenticated
Cloudflare API MCP wrapper:

```bash
scripts/mcp-cloudflare-quarantine.sh on
scripts/mcp-cloudflare-quarantine.sh reap
```

The marker lives at
`~/.local/state/system-config/mcp-cloudflare.disabled`. New wrapper launches
exit before token resolution or `mcp-remote` startup. Existing authenticated
sessions are terminated by `reap`. Unauthenticated `cloudflare-docs` stays
available.

During quarantine, agents may continue local code, docs, tests, pre-fire
packages, and non-Cloudflare work. They must not use dashboard refreshes,
Wrangler, curl, or Cloudflare MCP. Re-enable with:

```bash
scripts/mcp-cloudflare-quarantine.sh off
```

Only one Cloudflare-facing client should be re-enabled for the first post-window
probe.

## Non-Identity Access Log Read

The correct evidence path for the current service-token 403 is a single bounded
GraphQL Analytics read, not the Zero Trust dashboard Access log view. The helper
below prints the request body without a network call:

```bash
scripts/cloudflare-access-login-graphql.sh plan \
  --ray-id 9f1970365cde7e49-ANC \
  --since 2026-04-25T01:00:00Z \
  --until 2026-04-25T01:10:00Z
```

After explicit operator approval for that one read, run the same command with
`run` instead of `plan`. The helper refuses to run unless authenticated
Cloudflare MCP is quarantined and no active authenticated Cloudflare MCP
sessions remain:

```bash
scripts/cloudflare-access-login-graphql.sh run \
  --ray-id 9f1970365cde7e49-ANC \
  --since 2026-04-25T01:00:00Z \
  --until 2026-04-25T01:10:00Z
```

The helper makes exactly one `POST https://api.cloudflare.com/client/v4/graphql`
request, passes the bearer token to `curl` through stdin config rather than
argv, stores request/headers/response under
`~/.local/state/system-config/cloudflare-access-graphql/`, and prints the key
Access dimensions.

Interpretation:

- `isSuccessfulLogin: 1` with the expected `serviceTokenId`: Access
  authentication succeeded. Any client-facing 403 happened after Access
  authentication, so inspect tunnel `originRequest.access.audTag`, WAF/security
  events, and origin logs before changing Access policies. An empty
  `approvingPolicyId` is not by itself evidence of failure for service-token
  auth; Cloudflare's own service-token GraphQL examples may omit it.
- `isSuccessfulLogin: 0` with the expected `serviceTokenId`: token recognized,
  but no Access approval. This points back to policy binding, reusable-policy
  attachment, or path-scoped app evaluator behavior.
- `serviceTokenId` empty: Cloudflare did not associate the request with the
  expected service token.
- Empty rows: the Ray ID did not produce an Access login event in that window;
  widen only after a new approval, or inspect non-Access Cloudflare layers.

## Broker Target

The substrate broker is a Ring 1 kernel service. MCP, CLI, dashboard, and IDE
adapters are Ring 2 clients. No adapter owns policy.

```text
Agent / IDE / CLI
  -> MCP or CLI adapter
    -> HCS policy/gateway
      -> lease + rate-limit ledger
        -> typed control-plane provider
          -> Cloudflare API / Runpod API / GitHub API
```

### Broker Responsibilities

- Hold API credentials in memory only, resolved from 1Password at launch or by
  short-lived request from the operator.
- Eliminate bearer leakage through `mcp-remote --header` argv by becoming the
  HTTP client for authenticated control planes.
- Serialize mutations per control plane, account, and resource family.
- Maintain a shared rate-limit ledger keyed by provider/account/token. Parse
  `Ratelimit`, `Ratelimit-Policy`, and `retry-after`; deny or defer requests
  inside cooldown windows.
- Coalesce read-only diagnostics and cache evidence with provenance.
- Require a lease for every mutation. A lease records owner repo, operation
  type, resource ids, expiry, approval grant, and rollback shape.
- Track cross-resource invariants, including Access app AUDs that must be
  accepted by `cloudflared` public-hostname `originRequest.access.audTag`
  lists.
- Emit tamper-evident audit events for decision packages, approvals, requests,
  responses, and rollbacks.
- Provide a local diagnostic endpoint that supersedes
  `scripts/mcp-cloudflare-diagnostics.sh`.

### Broker Refusals

The broker should refuse:

- hidden parallelism against a shared control plane
- Cloudflare Codemode mutation snippets with `Promise.all`, unbounded loops, or
  multiple write calls
- mutation attempts while `last_<plane>_mcp_429` or observed headers indicate a
  live cooldown
- direct Access app `PUT` bodies that omit previously existing writable fields
- Access app/policy changes behind an Access-protected tunnel when the decision
  package omits tunnel AUD impact
- policy attachments that broaden human access without an explicit
  `exposure_change` field in the decision package
- any request whose rollback is missing or not type-compatible with the
  proposed mutation

## Operation Shapes

The first Cloudflare operations should be typed instead of generic JavaScript:

```text
cloudflare.access.app.read.v1
cloudflare.access.app.update.v1
cloudflare.access.policy.read.v1
cloudflare.access.policy.attach_to_app.v1
cloudflare.access.service_token.read.v1
cloudflare.access.service_token.rotate.v1
cloudflare.access.login_event.read.v1
cloudflare.tunnel.public_hostname.read.v1
cloudflare.tunnel.public_hostname.update_access_aud_tags.v1
host.cloudflared.config.read.v1
host.cloudflared.config.update_access_aud_tags.v1
```

Each mutating operation carries:

- `provider_account_id`
- `resource_owner_repo`
- `resource_ids`
- `auth_flow`
- `request_validators`
- `tunnel_aud_impact` when a Cloudflare Tunnel hostname has Access validation
- `before_hash`
- `after_patch`
- `full_put_body_hash` when the provider requires full replacement
- `exposure_change`
- `rate_limit_budget`
- `approval_grant_id`
- `rollback_operation`

The Cloudflare Access policy evaluator should be modeled explicitly:

```text
AccessApp
  domain_patterns
  allowed_idps
  policies[]

AccessPolicy
  decision: allow | deny | non_identity | bypass
  precedence
  include / require / exclude

AccessAuthFlow
  service-token-every-request
  service-token-exchange-then-jwt
  idp-browser-session

TunnelPublicHostname
  hostname
  service
  origin_request_access.required
  origin_request_access.team_name
  origin_request_access.aud_tags[]

ValidatorChain
  cloudflare-access-edge
  cloudflared-access-jwt-validator
  cloudflare-waf-or-security-rule
  origin-application
```

## Current Recommendation

For `runpod-review-webui-internal`, the canonical fix is not "add admin Allow
policy" and not reusable-vs-inline policy isolation. The preferred end state is
Service Auth-only plus service-token headers on every request, with the child
Access app AUD present in the existing `cloudflared` `audTag` list.

The substrate should encode the validator chain so future agents cannot
collapse different 403 classes into the same "Access policy failed" bucket.

## References

- [Cloudflare service tokens](https://developers.cloudflare.com/cloudflare-one/access-controls/service-credentials/service-tokens/)
- [Cloudflare Access policies](https://developers.cloudflare.com/cloudflare-one/access-controls/policies/)
- [Cloudflare self-hosted applications](https://developers.cloudflare.com/cloudflare-one/access-controls/applications/http-apps/self-hosted-public-app/)
- [Cloudflare Access authentication logs](https://developers.cloudflare.com/cloudflare-one/insights/logs/dashboard-logs/access-authentication-logs/)
- [Querying Access login events with GraphQL](https://developers.cloudflare.com/analytics/graphql-api/tutorials/querying-access-login-events/)
- [Cloudflare Tunnel origin parameters](https://developers.cloudflare.com/tunnel/advanced/origin-parameters/)
- [Cloudflare API rate limits](https://developers.cloudflare.com/fundamentals/api/reference/limits/)
- [`docs/cloudflare-mcp.md`](../cloudflare-mcp.md)
- [`docs/host-capability-substrate/2026-04-24-cloudflare-mcp-429-fanout.md`](./2026-04-24-cloudflare-mcp-429-fanout.md)
- [`docs/host-capability-substrate/2026-04-24-mcp-usage-collector.md`](./2026-04-24-mcp-usage-collector.md)
- [`docs/host-capability-substrate/2026-04-25-cloudflare-access-tunnel-audtag.md`](./2026-04-25-cloudflare-access-tunnel-audtag.md)

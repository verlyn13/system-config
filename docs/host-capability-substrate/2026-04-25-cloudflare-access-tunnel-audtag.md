---
title: Cloudflare Access + Tunnel AUD Coupling Field Report
category: field-report
component: host_capability_substrate
status: active
date: 2026-04-25
tags: [cloudflare, access, tunnel, cloudflared, aud, service-auth, substrate]
---

# Cloudflare Access + Tunnel AUD Coupling Field Report

## Summary

The runpod G1a 403 was not caused by Cloudflare Access policy evaluation. The
Access edge accepted the service-token request and minted a child application
JWT, but the host-side tunnel connector rejected that JWT before proxying to
the origin.

The failing path was protected by a path-scoped Access application:

```text
runpod.jefahnierocks.com/api/internal/*
```

The shared `cloudflared` hostname rule for `runpod.jefahnierocks.com` had
`originRequest.access.required: true`, but its `audTag` allow-list contained
only the parent/root Access application AUD. A child path-app JWT therefore
passed Access policy and failed tunnel-side JWT audience validation.

## Root Cause

Two Cloudflare controls were active in series:

1. Cloudflare Access edge policy evaluation for the most-specific matching
   Access application.
2. `cloudflared` origin-request Access JWT validation for the public hostname.

The first control selected the child Access app and approved the service-token
request. The second control still allowed only the parent/root app AUD.

```text
request
  -> Cloudflare Access child app policy: allow service token
  -> child app JWT minted with child AUD
  -> cloudflared AccessJWTValidator: reject, AUD not in originRequest.access.audTag
  -> origin never receives request
```

## Evidence Pattern

This failure class has a distinctive evidence shape:

| Evidence | Meaning |
|---|---|
| GraphQL `accessLoginRequestsAdaptiveGroups.isSuccessfulLogin = 1` | Access authentication succeeded for that Ray ID |
| GraphQL `serviceTokenId` matches expected token | The service-token headers were recognized |
| Client still receives HTTP 403 | The deny happened after Access authentication |
| `cloudflared` log mentions `AccessJWTValidator` and invalid AUD | Tunnel-side JWT audience validation rejected the request |
| Origin logs show no request for the path | The request never reached the application |

For the runpod incident, `cloudflared` rejected child AUD:

```text
44250efc94fc220ee27bb3a7a8f4bbbc34976ca27c1292dc3256cb09b3f7c4fd
```

The live tunnel config only allowed parent AUD:

```text
eb7da8adc85626f6c5e001fc65a6555d4e40d73ba5cbba5b0fa5677d00247e0d
```

## Design Rule

When a Cloudflare Tunnel hostname uses `originRequest.access.required: true`,
the tunnel `audTag` list must include every Access application AUD that can
protect URLs routed through that hostname, including path-scoped child apps.

Creating or updating a path-scoped Access app behind an Access-protected tunnel
is therefore a coupled operation:

```text
Access application / policy state
  + Cloudflare Tunnel public-hostname access.audTag state
  + origin routing/log evidence
```

Treating the Access app alone as the resource boundary is incomplete.

## Required Design-Phase Checklist

Before proposing any Cloudflare Access app for a hostname that is served by
Cloudflare Tunnel:

1. Identify whether the tunnel public-hostname route has
   `originRequest.access.required: true`.
2. Record the parent/root app AUD and any child/path app AUDs.
3. Verify the tunnel `audTag` list includes every intended app AUD.
4. Decide whether the tunnel should validate Access JWTs at all. If yes, keep
   the AUD list explicit; do not rely on Access policy approval alone.
5. Define the pass condition by layer:
   - Access auth: GraphQL login event shows success and expected token/user.
   - Tunnel validation: `cloudflared` forwards the request.
   - Origin behavior: application returns the expected status for the deployed
     version.
6. Include a rollback for both Access state and tunnel-host config state.

## Broker Implications

The host-capability-substrate broker needs first-class operations for
Cloudflare Tunnel public-hostname Access settings, not just Access apps and
policies.

Minimum operation shapes:

```text
cloudflare.tunnel.public_hostname.read.v1
cloudflare.tunnel.public_hostname.update_access_aud_tags.v1
cloudflare.access.app.read.v1
cloudflare.access.app.update.v1
cloudflare.access.login_event.read.v1
host.cloudflared.config.read.v1
host.cloudflared.config.update_access_aud_tags.v1
```

Minimum derived invariant:

```text
for each TunnelPublicHostname where origin_request_access.required == true:
  audTag must contain every AccessApp.aud reachable by hostname/path routing
```

The broker should refuse an Access app or policy mutation that adds a new
path-scoped app behind a protected tunnel unless the decision package also
declares the tunnel AUD impact:

```text
tunnel_aud_impact:
  tunnel_id
  hostname
  existing_aud_tags
  required_aud_tags
  missing_aud_tags
  host_config_update_required: true|false
```

For locally-managed tunnels, the broker may not own the final write to
`/etc/cloudflared/config.yml`, but it still owns the design-time invariant and
must emit a host-side follow-up before considering the Access change complete.

## Triage Rule

For a client-facing 403 on an Access-protected tunnel route:

1. Check the Access GraphQL login event by Ray ID.
2. If `isSuccessfulLogin: 0`, debug Access policy/token state.
3. If `isSuccessfulLogin: 1`, do not mutate Access policy first.
4. Check `cloudflared` logs for JWT validator errors and check origin logs for
   request arrival.
5. If `cloudflared` rejects the AUD, fix `audTag`.
6. If `cloudflared` forwards and the origin returns 403, debug the origin.
7. If Access succeeds, cloudflared forwards, and the origin does not see the
   request, inspect other Cloudflare edge layers or tunnel routing.

## References

- [`docs/host-capability-substrate/2026-04-24-control-plane-broker-design.md`](./2026-04-24-control-plane-broker-design.md)
- [`docs/cloudflare-mcp.md`](../cloudflare-mcp.md)
- [Cloudflare Tunnel origin parameters](https://developers.cloudflare.com/tunnel/advanced/origin-parameters/):
  `originRequest.access.required` and `audTag`
- [Cloudflare Access GraphQL Analytics](https://developers.cloudflare.com/analytics/graphql-api/tutorials/querying-access-login-events/):
  `accessLoginRequestsAdaptiveGroups`

---
title: Hetzner Cloudflare Management Status Ingest - 2026-05-14
category: operations
component: device_admin
status: advisory-ingest
version: 0.1.0
last_updated: 2026-05-14
tags: [device-admin, hetzner, cloudflare, advisory, ingest, boundary]
priority: high
---

# Hetzner Cloudflare Management Status Ingest - 2026-05-14

This record ingests the Hetzner repo's
2026-05-14 report on how Hetzner currently participates in Cloudflare,
**as advisory input for `system-config` planning only**. The Hetzner
repo is not a device-administration authority for the household
fleet; this ingest is the boundary statement that keeps
`system-config` from accidentally treating Hetzner as one.

No `system-config`, Hetzner, Cloudflare, HomeNetOps, OPNsense, DNS,
DHCP, WARP, Tailscale, 1Password, or host change is performed by
this ingest.

## Source

| Field | Value |
|---|---|
| Source repo | `/Users/verlyn13/Organizations/the-nash-group/hetzner` |
| Source report | `docs/reports/cloudflare-management-status-for-system-config-2026-05-14.md` |
| Source commit cited | `009c091bc63556e6fb43503bf70aee97a269ea82` (`docs: leave-clean status refresh post Phase 2 and post-transfer truth alignment (#23)`) |
| Source inspection mode | repo-only at Hetzner-repo authoring time; no live server, dashboard, Cloudflare API, or 1Password read was performed for that report |
| Ingest pass into system-config | this doc; non-secret summary only |

## What Hetzner Currently Is

Per the source report:

- Hetzner is the **transitional broker for Hetzner-served Cloudflare
  ingress** (Cloudflare Tunnel from the Hetzner primary host to
  hosted applications on host loopback).
- Hetzner primary-host applications that use that path today:
  - Infisical (`infisical.jefahnierocks.com` -> loopback Infisical
    backend)
  - Postal Web (`postal.jefahnierocks.com` -> loopback Postal Web)
  - `runpod-review-webui` (`runpod.jefahnierocks.com` -> loopback,
    behind Cloudflare Access)
- Hetzner hosts a separate Cloudflare Tunnel for RunPod pod API
  (`pod.jefahnierocks.com`); that tunnel's connector runs on the
  RunPod pod and is dormant while the pod is stopped.
- Hetzner serves `homevideos.jefahnierocks.com` via Caddy on the
  primary public IP, with the upstream reaching the NAS over
  Tailscale. Direct A record (no Cloudflare Tunnel).
- Private Tailscale/Traefik paths host `sonarqube`, `glitchtip`,
  `traefik` dashboards; no public Cloudflare DNS records exist for
  those.
- Hetzner host administration itself uses **public direct SSH on
  port 2222**, key-only, for `verlyn13`. That is for administering
  Hetzner hosts; **it is not a household device-admin path**.

## What Hetzner Currently Is Not

Per the source report and confirmed by `system-config` review:

- Hetzner is **not the household device control plane**. No Hetzner
  repo evidence shows Hetzner brokering SSH, RDP, VNC, or remote
  admin for `fedora-top`, MAMAWORK, the first Windows PC
  (DESKTOP-2JJ3187), or any family device.
- Hetzner is **not the policy home** for WARP enrollment, Gateway
  rules, adult-vs-kid Zero Trust profile separation, device posture
  rules, or device identity. Those belong to `cloudflare-dns`.
- Hetzner is **not the LAN authority**. DHCP reservations, hostnames,
  `home.arpa` overrides, OPNsense firewall, and LAN routing belong
  to HomeNetOps.
- The 2026-05-13 Hetzner evidence receipt records that the Windows
  PC and Fedora laptop were **not** marked as WARP-enrolled in
  `cloudflare-dns` at capture time. That fact has not been refreshed
  since; treat WARP enrollment for the household fleet as currently
  empty until `cloudflare-dns` returns a fresh handback.

## What system-config Will Rely On From This Ingest

| Fact for system-config | Sourced from |
|---|---|
| `verlyn13` is the administrator account/person for Jefahnierocks-managed devices. | Hetzner report Section 9 ("Boundaries For system-config"). |
| Hetzner currently hosts Infisical; Fedora laptop-hosted Infisical is retired and should stay retired. | Hetzner report Sections 6 and 9; matches the [fedora-top-infisical-redis-retirement-apply-2026-05-13.md](./fedora-top-infisical-redis-retirement-apply-2026-05-13.md) outcome on the `system-config` side. |
| Hetzner's active primary-host Cloudflare Tunnel is for hosted apps, not household device administration. | Hetzner report Sections 2, 4, 8. |
| The Hetzner repo prefers a Cloudflare-managed device posture (WARP-to-device or `cloudflared`-on-device) over `cloudflared`-on-Hetzner for household admin paths. | Hetzner report Section 8 (recommendation, not policy). |
| Tailscale stays transition/break-glass for already-documented paths, not the household-wide target. | Hetzner report Section 8 plus the [fedora-top-tailscale-retain-or-remove-apply-2026-05-13.md](./fedora-top-tailscale-retain-or-remove-apply-2026-05-13.md) Retain decision on the `system-config` side. |

These are facts `system-config` may quote. They are not Cloudflare
authority; if `cloudflare-dns` later contradicts any of them,
`cloudflare-dns` wins.

## Decision Encoded In system-config

```text
1. Do not route household device administration through Hetzner by
   default. fedora-top, MAMAWORK, and any future household device do
   not receive their primary remote-admin path via Hetzner.

2. The preferred remote-admin target remains Cloudflare Zero Trust /
   WARP private access, with policy governed by cloudflare-dns. LAN
   services remain private. Public WAN admin exposure remains
   rejected for household devices.

3. Tailscale remains transitional / possible break-glass design space
   only, per the 2026-05-13 retain decision. Activation requires a
   separate approved packet.

4. "Hetzner as a device bastion" is a new design and approval lane,
   not the current target. It would require a Hetzner-side, a
   cloudflare-dns-side, and a system-config-side packet, none of
   which exist.
```

## What This Ingest Does Not Conclude

- This ingest does **not** mark the `cloudflare-dns` outbound
  handback request as answered. The Hetzner report quotes a
  2026-05-13 Hetzner evidence receipt that summarizes a slice of
  `cloudflare-dns` state, but that does not substitute for a fresh
  handback from the `cloudflare-dns` repo
  (`/Users/verlyn13/Repos/local/cloudflare-dns`). The
  [outbound cloudflare-dns handback request](./handback-request-cloudflare-dns-2026-05-13.md)
  remains **open**.
- This ingest does **not** claim a refreshed snapshot of live
  Cloudflare state. The Hetzner report explicitly says no live
  Cloudflare API call, dashboard read, or audit log read was
  performed for that report. Any `system-config` packet that
  needs Cloudflare authority must still go through `cloudflare-dns`.
- This ingest does **not** authorize any Hetzner change. The stale
  `/root/.cloudflared/config.yml` cleanup, the `2222/tcp` Hetzner
  SSH narrowing discussion, and the IaC migration questions all
  belong to the Hetzner repo, not here.

## Open Questions Carried Forward

Captured here for cross-reference; resolution belongs to the named
repos.

1. Fedora-top and MAMAWORK target path: WARP-to-device,
   `cloudflared`-on-device, or another Cloudflare private-network
   pattern? Owner: `cloudflare-dns`.
2. Adult/admin vs family/kid Gateway/WARP profile design and
   evidence. Owner: `cloudflare-dns`.
3. Whether household devices use browser/manual OAuth enrollment,
   headless service-token enrollment, or a mix. Owner:
   `cloudflare-dns`.
4. Whether Tailscale is still needed as a break-glass for any
   household admin device. Owner: `system-config` after
   `cloudflare-dns` returns its handback.
5. Whether any clients still reference a retired Fedora-hosted
   Infisical endpoint. Owner: depends on the client; `system-config`
   for any reference originating in the local workstation surface.

## Related

- Hetzner repo source report (`/Users/verlyn13/Organizations/the-nash-group/hetzner/docs/reports/cloudflare-management-status-for-system-config-2026-05-14.md`)
- [handback-request-cloudflare-dns-2026-05-13.md](./handback-request-cloudflare-dns-2026-05-13.md) -
  the outbound request that remains open.
- [fedora-top-remote-admin-routing-design-2026-05-13.md](./fedora-top-remote-admin-routing-design-2026-05-13.md) -
  the system-config side design this ingest constrains.
- [fedora-top-tailscale-retain-or-remove-apply-2026-05-13.md](./fedora-top-tailscale-retain-or-remove-apply-2026-05-13.md)
- [fedora-top-infisical-redis-retirement-apply-2026-05-13.md](./fedora-top-infisical-redis-retirement-apply-2026-05-13.md)
- [windows-pc-mamawork.md](./windows-pc-mamawork.md)
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
- [../secrets.md](../secrets.md)

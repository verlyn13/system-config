---
title: Fedora Top Remote-Admin Routing Design - 2026-05-13
category: operations
component: device_admin
status: prepared
version: 0.1.0
last_updated: 2026-05-13
tags: [device-admin, fedora, routing, cloudflare, tailscale, warp, design]
priority: high
---

# Fedora Top Remote-Admin Routing Design - 2026-05-13

This packet is a **design / preparation document only**. It compares
the three plausible remote-administration paths for `fedora-top`,
categorizes each, and lists the evidence and approvals required to
move between them. No live host, provider, or network state was
changed while preparing this document, and applying this packet would
**not** change any live state - it sets up the *next* set of approval-
gated packets that would.

The decision recorded here is repo-only:

- Tailscale stays retained logged-out (per the 2026-05-13 decision).
- LAN SSH stays the current remote-admin default.
- The long-term target is Cloudflare WARP + `cloudflared`, but the
  detailed cutover lives in subsequent approval-gated packets, and any
  Cloudflare policy assertions in those packets must come from a
  `cloudflare-dns` handback first.

## Scope

In scope:

- Categorize each candidate remote-admin path for `fedora-top` as
  `current`, `transition`, `break-glass`, `target`, or `rejected`.
- Document the recommended near-term path, the long-term target, and
  the transition / break-glass plan.
- Enumerate the evidence required from sibling authority repos
  (`cloudflare-dns`, HomeNetOps) before any live cutover.
- Enumerate the live actions that would require explicit approval and
  the future packets that will carry those approval phrases.
- Capture the household admin / family-account stance that constrains
  identity and profile choices on shared devices.

Out of scope for this packet (each is its own future approval-gated
packet):

- Live Tailscale login, enrollment, auth-key issuance, or daemon
  restart.
- Cloudflare WARP install, `cloudflared` install, tunnel creation,
  Access policy authoring, device enrollment, or Gateway changes.
- HomeNetOps OPNsense, ISC DHCP, Unbound, NAT, HAProxy, WoL changes.
- `firewalld` zone changes on `fedora-top`.
- 1Password item creation or secret updates.
- LUKS, TPM, Secure Boot, firmware, sleep/power, reboot changes.
- Docker engine, daemon config, container or zone changes.
- SSH daemon, sudoers, users, groups, account-lifecycle changes.
- MacBook `known_hosts` reconciliation for `fedora-top.home.arpa`
  (separate item already tracked in `current-status.yaml`).

## Repo / Authority Boundaries

This design crosses three repos. The boundary is strict:

| Surface | Authoritative repo | What that repo owns | What `system-config` may say |
|---|---|---|---|
| Host hardening, host firewall, host package state, host SSH config, host daemon state | `system-config` (this repo) | All of it. | This document, packets, apply records. |
| LAN routing, OPNsense rules, ISC DHCP, Unbound DNS, NAT, HAProxy frontends, WoL | HomeNetOps (`~/Repos/verlyn13/HomeNetOps`) | All LAN-layer state. | "We need <X>" requests via the handback-format pattern; never reach in. |
| Cloudflare DNS records, Cloudflare Tunnel, Access policies, Gateway policies, WARP device-enrollment, Zero Trust profiles, account-level tokens | `cloudflare-dns` (`/Users/verlyn13/Repos/local/cloudflare-dns`) | All Cloudflare-side state, including current Zero Trust profile assignments and adult-vs-kids profile membership. | "We need <X>" requests; never claim live Cloudflare state unless a current `cloudflare-dns` handback supplies it. |

Implication: any statement in any subsequent packet of the form
"the Cloudflare Access policy for `fedora-top` is N" must cite a
`cloudflare-dns` handback. Same for "OPNsense allows N from N to N".
This packet flags those evidence gaps explicitly; it does not fill
them.

## Verified Baseline (system-config only)

Drawn from `current-status.yaml` and the per-packet apply records.
Every line below is in `system-config`'s authority.

```text
device:                fedora-top
hostname:              fedora-top
fqdn:                  fedora-top.home.arpa  (HomeNetOps Unbound override)
ip:                    192.168.0.206         (HomeNetOps static reservation)
remote_admin_path:     ssh - verlyn13@fedora-top.home.arpa
                       LAN-only
                       HostKeyAlias=192.168.0.206 required until MacBook
                       known_hosts is reconciled
sshd posture:          publickey-only; AllowUsers verlyn13;
                       AuthenticationMethods publickey
firewall posture:      FedoraWorkstation services: dhcpv6-client mdns
                       samba-client ssh; ports: (empty); rich rules:
                       (empty); docker zone: target ACCEPT (out of
                       scope here)
tailscale posture:     1.96.4-1 installed; tailscaled active+enabled;
                       Logged out; UDP/41641 listener bound but
                       blocked at firewall; DERP-relay reachability
                       confirmed (~54 ms Seattle); auth-URL treated
                       as sensitive
warp / cloudflared:    not installed; no host-side state
mission-critical svc:  none on this device today (Infisical/Redis
                       retired)
device user:           Wyn (summer-use laptop)
device administrator:  verlyn13
exploratory accounts:  wyn, axel, ila (no wheel, no docker, no sudo,
                       standard shells, hardware-only group access
                       for axel: dialout, plugdev)
```

## Candidate Paths

### Path 1 - LAN-only SSH (the current path)

**Mechanism**: OpenSSH client on the MacBook talks to `sshd` on
`fedora-top` over the 192.168.0.0/24 LAN, authenticated by a
publickey held in the MacBook's 1Password SSH agent.

**Strengths**:
- Already verified, hardened, in production for this engagement.
- Zero vendor dependency beyond OpenSSH.
- HomeNetOps owns the LAN routing; the only thing `system-config`
  needs to keep healthy is the host-side `sshd`.
- No new identity provider, no new token surface, no new dashboard.

**Weaknesses**:
- Only works while the operator is on the same physical LAN (or
  through a HomeNetOps-provided OPNsense path, which today does not
  include a public WAN ingress for SSH and should never).
- No off-LAN access whatsoever.
- Depends on home Wi-Fi / OPNsense health; a router failure that
  the operator cannot physically reach blocks admin.
- The `known_hosts` reconciliation for `fedora-top.home.arpa` is
  still pending; SSH currently uses `HostKeyAlias=192.168.0.206`
  as a workaround.

**Status**: **current** for routine administration.

### Path 2 - Tailscale (retained logged-out)

**Mechanism**: `tailscaled` (already installed) joins a tailnet,
publishes a WireGuard endpoint, accepts SSH-over-tailscale from
the MacBook. DERP-relay mode works without any inbound firewall
port. Direct UDP would require a future `firewalld` rule.

**Strengths**:
- Already on the host; activation is `tailscale up` + ACL.
- DERP-relay works through symmetric NAT (verified by `netcheck`).
- Independent of Cloudflare; viable break-glass if Cloudflare
  configuration goes wrong.
- Identity provider can be Google/Microsoft/email; no need to wait
  on cloudflare-dns to author Access policies.

**Weaknesses**:
- Auth-URL surface (`https://login.tailscale.com/a/<token>`) is
  emitted by `tailscale status` while logged out; documented and
  carried forward.
- Vendor lock-in to Tailscale's control plane.
- Doubles the identity-and-audit surface if Cloudflare WARP is also
  the target.
- A login means tailnet ACL design becomes load-bearing; tailnet
  ACL has not been authored.
- DERP relay adds ~54 ms RTT vs direct UDP; acceptable for shell
  but not great for sustained throughput.
- A future Tailscale upgrade (`1.98.1-1` is already pending in the
  DNF repo) may bring breakage; not a critical concern but noted.

**Status**: **transition / break-glass candidate**, decided
**retained logged-out** by the 2026-05-13 decision. Not a default
routing layer.

### Path 3 - Cloudflare WARP + `cloudflared` Tunnel + Access

**Mechanism**: `cloudflared` runs as a service on `fedora-top` and
maintains an outbound-initiated tunnel to Cloudflare's edge. The
operator's MacBook (and any other admin device) joins the same
Cloudflare Zero Trust org via WARP. A Cloudflare Access policy
binds an `ssh.fedora-top.<org-domain>` hostname (or equivalent)
to the operator's identity. SSH traffic flows MacBook -> WARP ->
Cloudflare edge -> tunnel -> `fedora-top:22`.

**Strengths**:
- Centralized identity (Cloudflare Access providers), centralized
  audit, centralized device enrollment.
- The Jefahnierocks Cloudflare org and `cloudflare-dns` repo
  already exist; reusing that infrastructure has lower marginal
  vendor cost than adding Tailscale-the-vendor.
- Tunnel is outbound-initiated; no `firewalld` ingress port is
  required.
- Aligns with the household plan: kids' and home personal devices
  are planned for Cloudflare Zero Trust profile management;
  putting `fedora-top` on the same infrastructure is consistent.
- OpenTofu IaC migration roadmap exists in `cloudflare-dns` per
  the directive note.

**Weaknesses**:
- No host-side state today. `cloudflared` install, token issuance,
  tunnel creation, Access policy authoring, and device enrollment
  all have to happen before this path is usable.
- All those steps live in `cloudflare-dns` authority, not
  `system-config`. `system-config` can stage the host install but
  cannot author the policy.
- WARP client on the MacBook needs profile assignment (adult
  profile) which is `cloudflare-dns`-owned.
- If the Cloudflare org has outage / token rotation / policy
  misconfiguration, off-LAN access goes down. The break-glass path
  must remain reachable through a separate provider (LAN or
  Tailscale).

**Status**: **target** for off-LAN administration once
`cloudflare-dns` supplies the evidence below and authors the
required Access / Tunnel / device-enrollment policy.

### Path 4 - Direct WAN SSH exposure

**Mechanism**: OPNsense forwards `22/tcp` (or a high port) from WAN
to `192.168.0.206`; the operator SSHes from the public internet.

**Status**: **rejected**. The operator policy explicitly states
"no WAN exposure" for SSH; HomeNetOps has confirmed no port
forward, NAT entry, or HAProxy frontend for this device; the SSH
hardening doc reaffirms this. Documenting only so the rejection is
audit-visible.

## Path Categorization Summary

| Path | Category | Why |
|---|---|---|
| LAN-only SSH | current | Verified, hardened, in use today |
| Tailscale (logged-out) | transition / break-glass | Retained but not the default; ACL + login design is a separate future packet |
| Cloudflare WARP + `cloudflared` | target | Long-term off-LAN path; gated on `cloudflare-dns` evidence and approvals |
| Direct WAN SSH | rejected | Operator policy, HomeNetOps confirms no WAN ingress for this device |

## Recommended Near-Term Path

Keep LAN-only SSH as the working remote-admin path while the
Cloudflare-side design is authored. Specifically:

1. Continue to administer `fedora-top` via
   `verlyn13@fedora-top.home.arpa` with `HostKeyAlias=192.168.0.206`.
2. Reconcile the MacBook `known_hosts` for
   `fedora-top.home.arpa` in a small standalone change (tracked in
   `current-status.yaml.blocked_items`).
3. Do **not** activate Tailscale. The retain-logged-out posture is
   the agreed transitional state.
4. Author the Cloudflare-side design packet (Path 3) with input from
   `cloudflare-dns` (see "Evidence Needed From cloudflare-dns"
   below).

This near-term path makes no provider/dashboard changes, asks the
human only for narrow scoped items (known_hosts reconciliation, then
review of the future Cloudflare design packet), and preserves the
ability to break-glass via Tailscale if a separate small packet later
opens that path.

## Target Long-Term Path

Cloudflare WARP + `cloudflared` tunnel + Access policy for the
operator. End state:

```text
operator device (MacBook):      WARP-enrolled (adult profile)
fedora-top:                     cloudflared service running an
                                outbound tunnel to Cloudflare edge
Cloudflare Access:              policy binds an admin hostname
                                (e.g. ssh.fedora-top.<jefahnierocks-
                                domain-of-cloudflare-dns-choice>) to
                                the operator identity
SSH path:                       ssh ssh.fedora-top... -> Access
                                checks identity -> tunnel -> sshd
firewall on fedora-top:         no new ingress ports; sshd remains
                                LAN-only-reachable directly, plus
                                tunnel-reachable from cloudflared
Tailscale:                      retained logged-out, OR removed,
                                depending on a later decision once
                                Cloudflare path is proven; either
                                outcome is a future packet
```

The future packet that ships this state is referred to here as
`fedora-top-cloudflare-warp-cloudflared-cutover` (not yet drafted).

## Transition / Break-Glass Plan

If the LAN path fails before the Cloudflare path is live, or if the
Cloudflare path itself fails after cutover, the recovery order is:

1. **Physical access** to the laptop (operator returns home). LUKS
   recovery is its own future packet; that is the deepest fallback.
2. **Tailscale break-glass** (if approved and activated by a future
   small packet). Activation requires:
   - a `tailscale-login-with-acl` packet that designs ACL scope and
     IdP choice
   - an approved live action to `tailscale up` once
   - possibly a `firewalld` rich rule for the WireGuard UDP port if
     direct mode is wanted
3. **MacBook known_hosts repair** (if the LAN path is healthy but
   client trust is the only blocker).

The break-glass path is intentionally not pre-activated. Activation
adds Tailscale to the daily attack surface; the design preference is
to keep break-glass cold until needed.

## Household Admin Strategy Alignment

This packet records the household stance that should shape any
identity / profile design in `cloudflare-dns` and any future
`tailscale-login-with-acl` packet here.

- The household has one full administrator: **verlyn13**. Managed
  devices have a `verlyn13` administrator path. `fedora-top` already
  honors this (`allowusers verlyn13`, `verlyn13` is the only `wheel`
  member after the 2026-05-13 privilege cleanup).
- **Family accounts are regular users** by default. `wyn`, `axel`,
  `ila` on `fedora-top` are regular users today; the privilege
  cleanup removed their `wheel`, `docker`, and broad sudoers grants.
- Family accounts should **allow normal use and exploration** without
  carrying authority to disrupt mission-critical services, routing,
  backups, device management, or security controls. On `fedora-top`
  today there are no mission-critical services hosted (Infisical /
  Redis are retired), so the surface is narrower than on other
  household devices.
- **Kids' and home personal devices are planned for Cloudflare
  Zero Trust management.** `fedora-top` is a Wyn-used laptop, so by
  the household model it belongs in the kids'-device profile,
  administered by an adult profile (verlyn13). The Zero Trust
  profile assignment is `cloudflare-dns` authority - see "Evidence
  Needed" below.
- **Adult profiles only on adult devices.** This packet flags the
  open question: when the Cloudflare design is authored, the WARP
  enrollment for `fedora-top` should reflect the device's user
  (Wyn) and the administrator (verlyn13). The right assignment is a
  `cloudflare-dns` call, not a `system-config` call.
- **OpenTofu IaC is the future state for Cloudflare config**, but
  the current authority remains `cloudflare-dns` text/state. This
  packet does not assume IaC is in place.

## Evidence Needed From `cloudflare-dns` (Handback Request)

Before any `fedora-top-cloudflare-warp-cloudflared-cutover` packet
can be authored, `system-config` needs a `cloudflare-dns` handback
that supplies the following non-secret evidence:

1. **Current Cloudflare org structure**:
   - Account / org name(s) and their relation to Jefahnierocks.
   - Whether Zero Trust is on the same account or a separate one.
   - The current `cloudflare-dns` repo path and the latest commit
     that should be cited.

2. **WARP / device-enrollment posture**:
   - Whether WARP is in use today on any household device.
   - The active device-enrollment policies, their names, and which
     identity providers are enabled.
   - Whether adult / kids' profile separation is already implemented;
     if so, the policy names, the membership criteria, and the
     network/route policies attached to each.
   - The expected enrollment flow on macOS (Cloudflare-supplied
     enrollment link, device-managed enrollment, etc.).

3. **Access policy posture**:
   - Whether any Access application exists for SSH today.
   - The identity providers Access can use (SSO / email OTP / etc.).
   - The naming convention `cloudflare-dns` prefers for Access
     applications protecting host SSH (so this packet's future
     follow-up uses the right hostname pattern).

4. **Tunnel posture**:
   - Whether any `cloudflared` connector tokens are issued and
     where they live in 1Password.
   - The naming convention for Tunnel names and per-tunnel hostnames.
   - Whether `cloudflare-dns` prefers managed (dashboard) or local
     (config.yml) tunnels.

5. **Profile assignment for `fedora-top`**:
   - Recommendation on adult vs kids' profile for this device,
     given that the user is Wyn and the administrator is verlyn13.
   - Whether `cloudflare-dns` wants to model "device used by minor,
     administered by adult" as a single profile or as a tagged
     overlay.

Until `cloudflare-dns` returns this evidence, no Cloudflare-side
assertion in this repo is authoritative. The future cutover packet
in `system-config` will quote the `cloudflare-dns` handback by
commit SHA.

## Evidence Needed From HomeNetOps (Handback Request)

Less is required here; HomeNetOps already supplied the static DHCP
and Unbound override on 2026-05-13. The only outstanding items are:

1. **Confirmation that the post-cutover LAN posture does not need
   any new HomeNetOps rule.** Specifically:
   - `cloudflared` makes only outbound TCP/443 connections from
     `192.168.0.206`; confirm OPNsense egress permits that.
   - WARP on the MacBook is outbound-only; same confirmation.
2. **Confirmation that the LAN path remains intact** after any
   future Cloudflare cutover (`fedora-top.home.arpa` resolution,
   SSH `22/tcp` reachability from LAN). The 2026-05-13 record
   already verifies the current posture; no change is requested.
3. **No new HomeNetOps work required by this packet.** The Tailscale
   retain-logged-out posture and the LAN-only SSH path both work
   inside the existing HomeNetOps state. Future packets should
   confirm the same before assuming HomeNetOps changes are needed.

## Live Actions That Would Require Explicit Approval

Each of the following is **out of scope of this packet** and would
be carried by its own future packet with its own approval phrase.
The approval phrases below are **placeholders** - the eventual
packet that ships each live action will quote the exact phrase
in its own "Required Approval Phrase" section.

| Future packet | Live actions it would cover | Placeholder approval phrase summary |
|---|---|---|
| `fedora-top-known-hosts-reconciliation` | Reconcile MacBook `~/.ssh/known_hosts` for `fedora-top.home.arpa`. | "I approve reconciling MacBook known_hosts for fedora-top.home.arpa using the verified ED25519 host key fingerprint." |
| `fedora-top-cloudflare-warp-cloudflared-cutover` | Install `cloudflared` on `fedora-top`; create or join a tunnel; reload service; verify Access path. **Requires a `cloudflare-dns` handback first.** | "I approve the Cloudflare WARP/cloudflared cutover for fedora-top per the cited cloudflare-dns commit SHA <X>: install cloudflared, configure tunnel <Y>, attach to Access app <Z>, verify SSH-over-Access works, do not disable LAN SSH, do not touch Tailscale." |
| `fedora-top-tailscale-login-with-acl` | Author tailnet ACL; run `tailscale up`; optionally add `firewalld` rich rule for WireGuard UDP. | "I approve activating Tailscale on fedora-top per the cited ACL design at <doc>: tailscale up with auth-key <K>; verify Logged in; optionally add firewalld rich rule for udp port <P>; do not enable as default route." |
| `fedora-top-tailscale-remove-after-cloudflare-proven` | If retained-logged-out Tailscale is later removed once Cloudflare proves stable. Uses Option A from the existing Tailscale packet, with refreshed snapshot. | "I approve removing Tailscale from fedora-top now that the Cloudflare WARP/cloudflared path is verified live: <Option A phrase from existing packet>." |

Each of those packets must:

- Cite a fresh `current-status.yaml` snapshot.
- For Cloudflare actions, cite the `cloudflare-dns` handback that
  supplies the policy state.
- For HomeNetOps assumptions, cite the prior HomeNetOps handback or
  request a new one.
- Use the held-open SSH + snapshot + rollback pattern (where
  applicable).
- Not bundle multiple live actions across boundaries.

## Updates Needed To `current-status.yaml`

This packet adds a new `prepared_packets[]` entry:

```yaml
- name: remote-admin-routing-design
  packet_doc: docs/device-admin/fedora-top-remote-admin-routing-design-2026-05-13.md
  prepared_at: 2026-05-13T23:30:00Z
  state: prepared
  approval_phrase_excerpt: >-
    Design/prep packet only; no live action is authorized by approving
    this packet itself. The packet enumerates four future approval-
    gated packets (known_hosts reconciliation, Cloudflare cutover,
    Tailscale login-with-ACL, Tailscale remove-after-Cloudflare); each
    will quote its own approval phrase when drafted.
```

It updates `next_recommended_action`:

```yaml
next_recommended_action:
  summary: >-
    Hand back this design packet to the human + cloudflare-dns. The
    next live-action packet is fedora-top-known-hosts-reconciliation
    (small, scoped, no cross-repo dependency). In parallel, request
    a cloudflare-dns handback covering Zero Trust org structure,
    WARP enrollment posture, Access policy posture, Tunnel naming,
    and device-profile recommendation for fedora-top so the
    Cloudflare cutover packet can be authored.
  preferred_packet: fedora-top-known-hosts-reconciliation
  preferred_packet_status: planned
  preferred_packet_blockers:
    - slug: doc-authoring
      note: >-
        Small standalone packet; no external blocker.
  handback_to_human: true
```

It leaves the Tailscale retain decision in `applied_packets[]` and
the existing `blocked_items[]` (`warp-and-cloudflared-design`,
`luks-remote-reboot-strategy`, `1password-device-admin-items`,
`macbook-known-hosts-reconciliation`,
`remote-admin-routing-design-pending`,
`tailscale-login-with-acl-pending`) refined: the
`remote-admin-routing-design-pending` entry resolves
(this packet) and the `warp-and-cloudflared-design` entry gets an
updated note pointing at the evidence-needed list above.

## Stop Rules (Re-Stated)

This packet, and the act of approving this packet by commit, must
**not** trigger any of the following:

- Tailscale login, enrollment, auth-key creation, daemon restart,
  or removal.
- WARP, `cloudflared`, Cloudflare DNS, Tunnel, Access, Gateway, or
  device-enrollment changes.
- `firewalld` zone changes on `fedora-top`.
- OPNsense, DHCP, Unbound, NAT, HAProxy, or LAN routing changes.
- 1Password item creation, edit, or secret update.
- LUKS, TPM, Secure Boot, firmware, power, or reboot changes.
- Docker engine, daemon config, container, image, volume, or zone
  changes.
- SSH daemon, sudoers, users, groups, or account-lifecycle changes.
- Any "full management" claim about `fedora-top` or any other
  household device.

The packet's authority extends to recording these intended future
boundaries, nothing more.

## Related

- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
- [fedora-top-tailscale-retain-or-remove-apply-2026-05-13.md](./fedora-top-tailscale-retain-or-remove-apply-2026-05-13.md)
- [fedora-top-tailscale-retain-or-remove-packet-2026-05-13.md](./fedora-top-tailscale-retain-or-remove-packet-2026-05-13.md)
- [fedora-top-firewalld-narrowing-apply-2026-05-13.md](./fedora-top-firewalld-narrowing-apply-2026-05-13.md)
- [fedora-top-privilege-cleanup-apply-2026-05-13.md](./fedora-top-privilege-cleanup-apply-2026-05-13.md)
- [fedora-top-ssh-hardening-apply-2026-05-13.md](./fedora-top-ssh-hardening-apply-2026-05-13.md)
- [fedora-top-homenetops-lan-identity-2026-05-13.md](./fedora-top-homenetops-lan-identity-2026-05-13.md)
- [fedora-44-laptop.md](./fedora-44-laptop.md)
- [../ssh.md](../ssh.md)
- [../secrets.md](../secrets.md)
- HomeNetOps repo (external authority): `~/Repos/verlyn13/HomeNetOps`
- `cloudflare-dns` repo (external authority):
  `/Users/verlyn13/Repos/local/cloudflare-dns`

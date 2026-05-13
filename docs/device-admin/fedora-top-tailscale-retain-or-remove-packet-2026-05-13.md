---
title: Fedora Top Tailscale Retain-or-Remove Packet - 2026-05-13
category: operations
component: device_admin
status: applied
version: 0.2.0
last_updated: 2026-05-13
tags: [device-admin, fedora, tailscale, off-lan, retire]
priority: high
---

# Fedora Top Tailscale Retain-or-Remove Packet - 2026-05-13

This packet defined a binary decision: retain Tailscale on `fedora-top`
in its current logged-out posture, or remove it cleanly. The guardian
chose **Option B - Retain (logged-out)** as transitional / break-glass
design space. The decision record is in
[fedora-top-tailscale-retain-or-remove-apply-2026-05-13.md](./fedora-top-tailscale-retain-or-remove-apply-2026-05-13.md).

No live Tailscale state was changed - Option B is documentation-only.
The remote-admin operating-readiness path continues to evolve under the
separate
[fedora-top-remote-admin-routing-design-2026-05-13.md](./fedora-top-remote-admin-routing-design-2026-05-13.md)
packet.

The original packet text below is preserved for reuse and audit.

## Scope

In scope:

- Tailscale package, daemon, DNF repo, GPG key on `fedora-top`.
- The retain-vs-remove decision and the apply path for each option.
- Read-only verification of the current Tailscale posture.

Out of scope (separate packets):

- WARP / `cloudflared` off-LAN access design.
- Cloudflare DNS / Tunnel / Access / Gateway / device enrollment.
- `firewalld` zone changes (`FedoraWorkstation` ports are already
  empty post-narrowing; if Retain is chosen and Tailscale is later
  logged in, a follow-up packet may reopen a stable WireGuard UDP
  port - not this packet).
- OPNsense, DNS, DHCP.
- LUKS / power / reboot.
- 1Password device-admin items.
- SSH, sudoers/users/groups, Docker hygiene.
- MacBook `known_hosts` reconciliation.

## Verified Current Live State

Observed via SSH from the MacBook on `2026-05-13T23:18:14Z` using
`HostKeyAlias=192.168.0.206`. Read-only; no Tailscale state changed.

### Package And Repo

```text
rpm:               tailscale-1.96.4-1.x86_64
tailscale binary:  /usr/sbin/tailscale
tailscaled binary: /usr/sbin/tailscaled
version:           1.96.4 (commit 8cf541dfd; go1.26.1)
upgrade available: tailscale.x86_64 1.98.1-1 from tailscale-stable
                   (pending; do not apply via this packet)

/etc/yum.repos.d/tailscale.repo:
  [tailscale-stable]
  name=Tailscale stable
  baseurl=https://pkgs.tailscale.com/stable/fedora/$basearch
  enabled=1
  type=rpm
  repo_gpgcheck=1
  gpgcheck=1
  gpgkey=https://pkgs.tailscale.com/stable/fedora/repo.gpg

dnf repolist --enabled                  shows tailscale-stable
dnf check-update --refresh --assumeno   shows tailscale 1.98.1-1 upgrade
                                        (no signing-key errors; the
                                        prior 2026-05-13 pre-hardening
                                        report's signing-key failure is
                                        no longer observed)
rpm -q gpg-pubkey                       shows imported:
                                        gpg-pubkey-957f5868-5e5499b8
                                        "Tailscale Inc. (Package
                                        repository signing key)
                                        <info@tailscale.com>"
```

The Tailscale repo trust path is healthy at apply time. The earlier
"signing-key failure" note in the pre-hardening report was either
transient (dnf cache state) or has since been repaired by an unrelated
update; no Tailscale repo repair is required for either option in this
packet.

### Daemon

```text
systemctl is-active tailscaled       active
systemctl is-enabled tailscaled      enabled
UnitFileState                        enabled
ActiveEnterTimestamp                 Tue 2026-05-12 12:44:44 AKDT
unit file:                           /usr/lib/systemd/system/tailscaled.service
multi-user.target wants:             /etc/systemd/system/multi-user.target.wants/tailscaled.service
```

### Status (logged-out posture)

```text
tailscale status                     "Logged out."
                                     Plus a node-enrollment URL that
                                     this packet INTENTIONALLY DOES
                                     NOT RECORD. See "Security Note
                                     On Auth-URL Exposure" below.
tailscale0 interface                 link-local IPv6 only
                                     (fe80::.../64), no tailnet IPv4
no tailnet IP, no peer state, no derp connection from this node
```

### Netcheck (no login required; outbound reachability)

```text
UDP egress:                yes
IPv4:                      yes (NATed; symmetric NAT detected)
IPv6:                      not currently usable
PortMapping (uPnP/PCP):    no
CaptivePortal:             false
Nearest DERP relay:        Seattle (~54 ms RTT)
DERP coverage (best 5):    sea 54ms, sfo 78ms, lax 78ms, den 99ms,
                           dfw 104ms
```

If Tailscale were ever logged in from this host, DERP-relay-mode
WireGuard would work without any inbound firewall port. Direct UDP
peer-to-peer would not work because `FedoraWorkstation` no longer
allows inbound `1025-65535/udp` (post-narrowing baseline). Performance
in DERP-relay mode is acceptable on this LAN (Seattle ~54 ms).

### Listeners And Firewall Interaction

```text
udp 0.0.0.0:41641   tailscaled (pid 22356)   bound, but firewall drops
                                             inbound packets after the
                                             2026-05-13 narrowing
udp [::]:41641      tailscaled (pid 22356)   same
nft / iptables rules referencing tailscale:  none
firewalld FedoraWorkstation runtime:
  services           dhcpv6-client mdns samba-client ssh
  ports              (empty)
  rich rules         (empty)
```

The kernel allows the process bind; the firewall drops external
traffic. No Tailscale rule was ever added to `firewalld`.

### On-Disk State

```text
/var/lib/tailscale/
  derpmap.cached.json   15055 B   Apr  3 10:10
  files/                          Sep  6 2025
  tailscaled.log.conf   209 B
  tailscaled.log1.txt   0 B       May 13 15:17 (post-firewall-narrow)
  tailscaled.log2.txt   0 B       May 13 11:18
  tailscaled.state      2822 B    Feb 28 11:17

/run/tailscale/
  tailscaled.sock       (socket)

cron / systemd timers referencing tailscale:  none
```

`tailscaled.state` is the per-node state binary; if Tailscale is
removed, this file becomes orphaned unless explicitly deleted. It
contains node keys and may contain peer history.

### Sudoers Implications

The 2026-05-13 privilege cleanup removed `/etc/sudoers.d/50-mesh-ops`,
which previously held NOPASSWD wildcards for `tailscale *` and the
`tailscaled` systemctl actions. No account on this host now has a
NOPASSWD route to Tailscale CLI or service control; the only
administrator path is `verlyn13` via the existing
`/etc/sudoers.d/ansible-automation` NOPASSWD: ALL grant (under
separate review).

## Off-LAN Remote-Admin Design Considerations

Stated direction (per `current-status.yaml` and recent device-admin
notes): the Jefahnierocks off-LAN remote-admin path will be authored
as a Cloudflare WARP + `cloudflared` design packet. Tailscale is a
candidate alternative or a candidate break-glass overlay.

- **Cloudflare path (planned)**: relies on `cloudflared` tunnels and
  Access policies. Centralized identity (Cloudflare Access providers),
  device enrollment via WARP, audit log in Cloudflare. The
  jefahnierocks org has Cloudflare DNS and MCP already in this repo's
  scope, so the auth and audit story is already partially in place.
- **Tailscale path (current)**: WireGuard mesh with tailnet ACLs.
  Independent identity provider (Google/Microsoft/email). Works in
  DERP-relay mode without an open inbound UDP port; works better in
  direct mode if a single UDP port is opened in `FedoraWorkstation`.

The two paths overlap. Running both indefinitely doubles the audit
surface, the identity-provider surface, and the package-trust surface
for limited additional security benefit. Either path can be the
primary; the other is at most a redundant break-glass.

Because the broader Jefahnierocks direction is the Cloudflare/WARP
path, and because the laptop currently provides no value from
Tailscale (logged out, listener blocked, DNF upgrade pending), this
packet recommends the **Remove** option as the default. If the
guardian prefers Tailscale to remain as a logged-out reserve until the
WARP/cloudflared packet is approved, the **Retain** option is also
available and requires no state change today.

## Option A - Remove (recommended default)

Goal: leave the laptop with no Tailscale software, no Tailscale
state, no Tailscale DNF repo, no orphan GPG key, and no listening
WireGuard UDP socket. SSH over LAN remains the only remote-admin
path until the Cloudflare WARP/cloudflared packet is approved and
applied.

### What Remove changes

| Surface | Before | After |
|---|---|---|
| `tailscaled.service` | active, enabled | disabled, not present |
| package `tailscale` | 1.96.4-1 installed | not installed |
| `tailscale0` interface | present (link-local IPv6 only) | absent |
| udp/41641 listener | bound by `tailscaled` | gone |
| `/var/lib/tailscale/` | populated (incl. `tailscaled.state`) | absent |
| `/run/tailscale/` socket | present | absent |
| `/etc/yum.repos.d/tailscale.repo` | enabled, healthy | absent |
| `gpg-pubkey-957f5868-5e5499b8` | imported | removed |
| firewall posture | unchanged | unchanged |
| SSH posture | unchanged | unchanged |

### Apply commands (Option A)

Apply only after explicit guardian approval. Use the standard
held-open SSH session pattern; `HostKeyAlias=192.168.0.206`.

```bash
sudo -n bash <<'EOF'
set -euo pipefail
SNAP="/var/backups/jefahnierocks-tailscale-remove-$(date -u +%Y%m%dT%H%M%SZ)"
install -d -m 0700 -o root -g root "$SNAP"

# Forensic-only snapshot (non-secret).
rpm -q tailscale                                         > "$SNAP/rpm-tailscale.txt" || true
tailscale --version                                      > "$SNAP/tailscale-version.txt" 2>&1 || true
systemctl show tailscaled                                > "$SNAP/tailscaled-systemd-show.txt" 2>&1 || true
install -m 0400 -o root -g root /etc/yum.repos.d/tailscale.repo \
                                                         "$SNAP/tailscale.repo" || true
rpm -qa gpg-pubkey --qf '%{NAME}-%{VERSION}-%{RELEASE} %{SUMMARY}\n' \
  | grep -iE 'tailscale' > "$SNAP/gpg-keys.txt" || true
ss -tulpnH | grep -E 'tailscaled' > "$SNAP/listeners-before.txt" || true
( cd "$SNAP" && sha256sum -- * 2>/dev/null > manifest.sha256 || true )
echo "snapshot_path=$SNAP"

# 1. Stop and disable the daemon.
systemctl disable --now tailscaled

# 2. Remove the package.
dnf -y remove tailscale

# 3. Remove on-disk state (after the package is gone so the daemon is not
# tempted to recreate it).
rm -rf /var/lib/tailscale
rm -rf /run/tailscale

# 4. Remove the DNF repo file and its GPG key.
rm -f /etc/yum.repos.d/tailscale.repo
TS_KEY="$(rpm -qa gpg-pubkey --qf '%{NAME}-%{VERSION}-%{RELEASE}|%{SUMMARY}\n' \
  | awk -F'|' 'tolower($2) ~ /tailscale/ {print $1}' | head -1)"
if [ -n "$TS_KEY" ]; then rpm -e --allmatches "$TS_KEY"; fi

# 5. Clear DNF metadata so the next dnf invocation re-resolves cleanly.
dnf clean metadata

echo "--- post-remove sanity ---"
rpm -q tailscale 2>&1 || true
systemctl status tailscaled --no-pager 2>&1 | head -5 || true
ls -la /var/lib/tailscale 2>&1 | head -3 || true
ls /etc/yum.repos.d/ | grep -i tailscale && echo "FAIL: repo file still present" || echo "ok: repo removed"
ss -tulpnH | grep -E ':41641 ' && echo "FAIL: 41641 listener still present" || echo "ok: 41641 listener gone"
EOF
```

### Validation (Option A)

Run from a fresh SSH session while the held-open session remains
open. All must pass before closing the held-open session.

```bash
ssh ... verlyn13@fedora-top.home.arpa 'sudo -n bash -s' <<'EOF'
set -u
echo "--- package + binary ---"
rpm -q tailscale 2>&1 || true
ls /usr/sbin/tailscale /usr/sbin/tailscaled 2>&1 || true
echo "--- service ---"
systemctl status tailscaled --no-pager 2>&1 | head -5 || true
echo "--- on-disk state ---"
ls -la /var/lib/tailscale 2>&1 | head -3 || true
ls -la /run/tailscale 2>&1 | head -3 || true
echo "--- listeners ---"
ss -tulpnH | grep -E ':41641 ' || echo "(no 41641 listener)"
echo "--- repo + key ---"
ls /etc/yum.repos.d/ | grep -i tailscale || echo "(no repo file)"
rpm -qa gpg-pubkey --qf '%{NAME}-%{VERSION}-%{RELEASE} %{SUMMARY}\n' | grep -iE 'tailscale' \
  || echo "(no tailscale gpg key)"
echo "--- dnf repolist (must not include tailscale) ---"
dnf repolist --enabled | grep -iE 'tailscale' && echo "FAIL" || echo "(no tailscale repo)"
echo "--- firewall + ssh sanity (must remain unchanged) ---"
firewall-cmd --zone=FedoraWorkstation --list-services
firewall-cmd --zone=FedoraWorkstation --list-ports
sshd -T 2>/dev/null | grep '^allowusers '
EOF
```

Expected: every "ls/rpm/systemctl/ss/dnf" line returns absent/empty;
firewalld and sshd checks unchanged.

### Rollback (Option A)

Tailscale is freely re-installable from the upstream repo.

```bash
sudo -n bash <<'EOF'
set -euo pipefail
# Re-fetch repo file (use whatever upstream Tailscale documentation says
# at the time; the snapshot directory under
# /var/backups/jefahnierocks-tailscale-remove-<ts>/tailscale.repo also
# has the prior text).
SNAP="<snapshot-path>"
install -m 0644 -o root -g root "$SNAP/tailscale.repo" /etc/yum.repos.d/tailscale.repo
dnf install -y tailscale
systemctl enable --now tailscaled
EOF
```

`tailscale up` to log in is **not** included in rollback. Login is a
separate decision and must be a new approval-gated packet.

The pre-remove `tailscaled.state` file is included in the snapshot but
is intentionally not restored on rollback; the right path is fresh
enrollment from `tailscale up`, not state-file replay. If a state
recovery is genuinely needed for some reason, restore
`/var/lib/tailscale/tailscaled.state` from the snapshot before
starting `tailscaled`.

## Option B - Retain (logged-out, no state change today)

Goal: leave Tailscale exactly as it is now (installed, logged out,
listener bound but firewall-blocked, repo enabled, GPG key
imported). Defer the login + ACL design to a future Tailscale
operating packet.

### What Retain changes

Nothing live. This option is a documentation-only decision today.

### Apply commands (Option B)

There are no live commands to run; the live state is already the
retained state. The "apply" of this option is:

- Commit this packet with a small follow-up annotation in
  `current-status.yaml` recording the decision and the implications:
  - `tailscale-retain-or-remove` moves from `approval-required` to
    `applied` (with `state: retained-logged-out` in the apply
    metadata).
  - A new entry under `approval_required[]` lists the future
    `tailscale-login-with-acl` packet as `planned`.

Optional non-live housekeeping during the same window (not required
for the decision):

- `sudo -n dnf upgrade -y tailscale` to land 1.98.1 (separate
  decision; explicitly out of scope of this packet unless approved
  alongside it).
- Generate and rotate the tailnet auth URL (see security note below)
  before the URL is consumed by an unauthorized party.

### Validation (Option B)

```bash
ssh ... verlyn13@fedora-top.home.arpa 'sudo -n bash -s' <<'EOF'
set -u
echo "--- still installed and still logged out ---"
rpm -q tailscale
systemctl is-active tailscaled
systemctl is-enabled tailscaled
# tailscale status would print the tailnet auth URL again. The
# packet's Option B validation deliberately does NOT call
# `tailscale status`. Use these proxy checks instead:
ls /var/lib/tailscale/tailscaled.state >/dev/null && echo "state file present"
ss -tulpnH | grep -E 'tailscaled' || echo "(no tailscaled listeners - unexpected)"
firewall-cmd --zone=FedoraWorkstation --list-all | grep -E 'ports:|rich rules:'
EOF
```

If the validation includes `tailscale status` (for whatever reason),
treat the printed `Log in at: ...` URL as the same kind of sensitive
artifact this packet treats it: do not place it in the repo.

### Rollback (Option B)

Retention has nothing to roll back. If the operator later changes
the decision to Remove, run Option A.

## Security Note On Auth-URL Exposure

`tailscale status` on a logged-out node always prints a node-bound
enrollment URL of the form `https://login.tailscale.com/a/<token>`.
Anyone who clicks that URL and authenticates can **bind this
laptop's `tailscaled` instance into their tailnet** until the URL
expires. The URL is rotated by `tailscaled` periodically and is
invalidated by a successful login from any party.

Implications for this packet:

- This packet's preparation **deliberately did not record the URL in
  this document**. It was printed once to the read-only verification
  output during preparation; the document treats that as a
  preparation-time artifact, not a repo-safe value.
- The retain option keeps the URL-generating surface present
  indefinitely. The remove option removes it.
- Even on a trusted-LAN host, the URL should be treated like a
  short-lived secret. Do not paste it into chat, screenshots,
  bug reports, or repo evidence files.
- If the URL was visible in any agent session log before the
  retain/remove decision lands, consider rotating it by running
  `sudo tailscale logout` followed by `sudo tailscale status` from
  the laptop console once a new URL is generated, OR by completing
  Option A (Remove), which makes the URL moot.
- If the URL was ever shared (or might have been), and the laptop is
  retained, run `sudo systemctl restart tailscaled` so the daemon
  generates a fresh token. The published guidance on URL
  invalidation is upstream Tailscale's; do not rely on guesswork.

## Recommended Default

**Option A - Remove.**

Rationale:

1. Tailscale currently provides no functional value on this device:
   `tailscaled` is logged out, the WireGuard listener is firewall-
   blocked after the 2026-05-13 narrowing, and there is no peer
   state.
2. The Jefahnierocks off-LAN remote-admin direction is Cloudflare
   WARP + `cloudflared` (separate packet). Running two parallel
   off-LAN paths doubles the audit and identity surface for limited
   marginal security benefit on a personal-workstation device.
3. The repo-signing concern from the 2026-05-13 pre-hardening
   report does not block either option, but the Remove path leaves
   a smaller package-trust surface to maintain.
4. The auth-URL exposure surface is real and recurring while
   Tailscale is retained logged out.
5. Re-installation from upstream is straightforward and documented
   inside this packet's rollback section.

The guardian may override and choose Option B. Approval phrases for
both options are below.

## Required Approval Phrase

### Approval phrase for Option A (Remove)

```text
I approve applying the Fedora Tailscale Remove option live now:
snapshot the pre-apply Tailscale package, repo file, GPG-key entry,
and listener output to /var/backups/jefahnierocks-tailscale-
remove-<timestamp>; systemctl disable --now tailscaled; dnf -y
remove tailscale; rm -rf /var/lib/tailscale and /run/tailscale; rm
-f /etc/yum.repos.d/tailscale.repo; rpm -e the Tailscale GPG public
key; dnf clean metadata; verify rpm -q tailscale shows absent,
tailscaled is gone, /var/lib/tailscale is absent, no 41641
listener, no tailscale repo or GPG key, firewalld FedoraWorkstation
unchanged, and sshd allowusers verlyn13 unchanged. Do not touch
SSH config, sudoers/users/groups, firewalld, Docker, Cloudflare,
WARP, cloudflared, OPNsense, DNS, DHCP, LUKS, power, reboot, or
1Password. Accept that the laptop loses any Tailscale-based
off-LAN path until the Cloudflare WARP/cloudflared packet is
prepared and applied.
```

### Approval phrase for Option B (Retain logged-out)

```text
I approve recording the Fedora Tailscale Retain decision: keep
Tailscale 1.96.4 installed, tailscaled enabled and active but
logged out, tailscale-stable DNF repo enabled, and the Tailscale
GPG key imported. No live state change today. The future
tailscale-login-with-acl packet is the gating step before the
laptop joins any tailnet. Acknowledge the auth-URL exposure note
and treat any printed `https://login.tailscale.com/a/...` URL as
sensitive; rotate it by restarting tailscaled if it may have been
shared. Do not touch SSH config, sudoers/users/groups, firewalld,
Docker, Cloudflare, WARP, cloudflared, OPNsense, DNS, DHCP, LUKS,
power, reboot, or 1Password.
```

## Evidence To Record After Apply

For Option A (Remove):

```text
timestamp:
operator:
held-open session used:
snapshot path:
package removal result:
service teardown result:
state directory removal result:
repo file removal result:
gpg key removal result:
dnf clean metadata result:
post-apply rpm -q tailscale (must be absent):
post-apply 41641 listener (must be absent):
post-apply firewalld FedoraWorkstation (must be unchanged):
post-apply sshd allowusers (must be verlyn13):
rollback used: yes/no
remaining blockers:
```

For Option B (Retain):

```text
timestamp:
operator:
decision recorded:
current-status.yaml updated: yes/no
tailscaled state still active+enabled+logged-out: yes/no
auth-URL rotation performed (if needed): yes/no/n-a
remaining blockers:
```

In either case, do not copy auth URLs, tailnet keys,
`tailscaled.state` contents, account identifiers, or any
authentication artifact into the repo.

## Related

- [fedora-top-firewalld-narrowing-apply-2026-05-13.md](./fedora-top-firewalld-narrowing-apply-2026-05-13.md) -
  baseline that blocks the existing Tailscale WireGuard UDP listener.
- [fedora-top-privilege-cleanup-apply-2026-05-13.md](./fedora-top-privilege-cleanup-apply-2026-05-13.md) -
  removal of the `mesh-ops` NOPASSWD wildcards over `tailscale *` and
  `systemctl ... tailscaled`.
- [fedora-top-ssh-hardening-apply-2026-05-13.md](./fedora-top-ssh-hardening-apply-2026-05-13.md) -
  the current LAN admin path that this packet does not replace.
- [fedora-44-laptop.md](./fedora-44-laptop.md) - master device record.
- [current-status.yaml](./current-status.yaml) - machine-readable status
  this packet's decision will update.
- [handback-format.md](./handback-format.md) - agent handback template.
- [../ssh.md](../ssh.md) - SSH client policy.
- [../secrets.md](../secrets.md) - what must never appear in this file
  (notably: any Tailscale auth URL, tailnet keys, account identifiers).

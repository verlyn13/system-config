---
title: Fedora Top MacBook known_hosts Reconciliation Packet - 2026-05-13
category: operations
component: device_admin
status: prepared
version: 0.1.0
last_updated: 2026-05-13
tags: [device-admin, fedora, ssh, known-hosts, macbook]
priority: high
---

# Fedora Top MacBook known_hosts Reconciliation Packet - 2026-05-13

This packet adds a `~/.ssh/known_hosts` entry on the MacBook for
`fedora-top.home.arpa` using the **already-verified** ED25519 host-key
fingerprint:

```text
SHA256:0dqRCxVLpssRFdRjgHKkWy5lS31IUiZF7DFZj8cFm2w
```

Once applied, routine SSH commands from the MacBook to `fedora-top`
no longer need the `-o HostKeyAlias=192.168.0.206` workaround.

The change is **MacBook-side only**. `fedora-top`, `sshd`, firewall,
DNS, DHCP, HomeNetOps, Cloudflare, Tailscale, WARP, `cloudflared`,
sudoers, Docker, LUKS, power, reboot, and 1Password are not touched.

## Scope

In scope:

- Append a single new entry to `~/.ssh/known_hosts` on the MacBook
  for the hostname `fedora-top.home.arpa` carrying the same ED25519
  host key the IP entry already carries.
- Verify the new entry's fingerprint matches the known-good value
  **before** appending.
- Verify that subsequent SSH attempts to `fedora-top.home.arpa` no
  longer require `HostKeyAlias=192.168.0.206`.

Out of scope:

- The existing `192.168.0.206` entry stays. The reconciliation adds
  a hostname alias, it does not remove or rewrite the IP entry.
- Any other host in `~/.ssh/known_hosts`.
- Anything on the Fedora host (no SSH command is issued against
  `fedora-top` during the apply other than the `ssh-keyscan` probe,
  which talks to `sshd`'s key-exchange phase only).
- Removal of `HostKeyAlias=192.168.0.206` from `~/.ssh/config` or
  from any tool's invocation - that is a separate, optional cleanup
  decision the operator can make at any time after this packet.

## Verified Current State (MacBook-side)

The current SSH path to `fedora-top` from the MacBook depends on
`HostKeyAlias=192.168.0.206`. Direct `ssh fedora-top.home.arpa`
without the alias would prompt for trust-on-first-use because the
hostname has no entry. The IP entry's fingerprint is the same key
recorded across the prior packets:

```text
ssh-keygen -F fedora-top.home.arpa          (returns nothing today;
                                              entry will be added)
ssh-keygen -F 192.168.0.206 -l              should return
                                              "256 SHA256:0dqRCxVLpssRFdRjgHKkWy5lS31IUiZF7DFZj8cFm2w
                                              ... ED25519"
~/.ssh/known_hosts                          mode 0600 owned by the
                                              operator account
~/.ssh/config                                contains the OpenSSH
                                              client policy managed
                                              by system-config; no
                                              host-specific rewrite
                                              is needed
1Password SSH agent                          serves the private key
                                              for the operator
                                              identity used to log in
                                              to fedora-top
```

The fingerprint to match is the same one recorded in every prior
fedora-top apply doc and packet (SSH hardening apply, privilege
cleanup apply, retirement apply, firewalld narrowing apply,
Tailscale retain decision). It has been verified through multiple
independent SSH sessions and is the trusted value for this packet.

## Approach

Two options were considered:

1. **`ssh-keyscan` + fingerprint match** (recommended). Fetch the
   ED25519 host key by hostname, verify the resulting fingerprint
   matches `SHA256:0dqRCxVLpssRFdRjgHKkWy5lS31IUiZF7DFZj8cFm2w`,
   then append. Uses one fresh KEX over the network, but the
   acceptance gate is a string match against a known-good value -
   not trust-on-first-use.
2. **Reuse the IP entry's key bytes**. Pull the key material from
   the existing `192.168.0.206` known_hosts line, prepend the
   hostname, and append. Avoids any network round-trip, but is
   harder to express robustly when the existing entry is hashed
   (`HashKnownHosts yes` is the OpenSSH client default on macOS).

Approach 1 is used in this packet. The fingerprint check is a hard
guard: if the fingerprint differs from the known-good value for any
reason (DNS spoof, MITM on the path, sshd host-key rotation that
nobody approved), the apply aborts and `~/.ssh/known_hosts` is not
modified.

## Apply Commands

Apply only after explicit guardian approval. All commands run on
the **MacBook**. There is no held-open SSH session for this packet
because nothing on the Fedora host is changed; the held-open
pattern protects against losing host-side admin access, which is
not at risk here.

```bash
set -euo pipefail

# Resolve the known-good value once.
EXPECTED_FP="SHA256:0dqRCxVLpssRFdRjgHKkWy5lS31IUiZF7DFZj8cFm2w"

# Backup current known_hosts.
TS="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP="$HOME/.ssh/known_hosts.pre-fedora-top-reconciliation-$TS"
cp -a "$HOME/.ssh/known_hosts" "$BACKUP"
chmod 600 "$BACKUP"
echo "backup_path=$BACKUP"

# Sanity checks before doing anything.
ssh-keygen -F fedora-top.home.arpa >/dev/null && {
  echo "FAIL: an entry for fedora-top.home.arpa already exists; aborting"
  exit 1
}
ip_fp="$(ssh-keygen -F 192.168.0.206 -l 2>/dev/null | awk '{print $2}' | head -1)"
[ "$ip_fp" = "$EXPECTED_FP" ] || {
  echo "FAIL: 192.168.0.206 known_hosts entry does not match the expected"
  echo "       fingerprint. Saw: $ip_fp"
  echo "       Expected: $EXPECTED_FP"
  exit 1
}

# Fetch a fresh ED25519 host key for the FQDN, hashed for consistency
# with the macOS-default HashKnownHosts=yes.
TMP="$(mktemp -t fedora-top-known-hosts.XXXXXX)"
chmod 600 "$TMP"
trap 'rm -f "$TMP"' EXIT
ssh-keyscan -t ed25519 -H fedora-top.home.arpa > "$TMP" 2> /dev/null
[ -s "$TMP" ] || {
  echo "FAIL: ssh-keyscan returned no key for fedora-top.home.arpa"
  exit 1
}

# Verify the fingerprint of the fetched key matches the known-good value.
fetched_fp="$(ssh-keygen -l -f "$TMP" 2>/dev/null | awk '{print $2}' | head -1)"
[ "$fetched_fp" = "$EXPECTED_FP" ] || {
  echo "FAIL: fetched host-key fingerprint does not match the expected value"
  echo "       Saw: $fetched_fp"
  echo "       Expected: $EXPECTED_FP"
  exit 1
}
echo "fingerprint_match=ok"

# Append the verified entry to known_hosts.
cat "$TMP" >> "$HOME/.ssh/known_hosts"
echo "appended=ok"
```

`-t ed25519` restricts the keyscan to the ED25519 host key, which is
the key the host has been operating on through every prior apply.
`-H` writes the new entry in hashed form to match the OpenSSH client
default on macOS. If the operator's `~/.ssh/known_hosts` uses
unhashed entries by local override, the new entry can be regenerated
without `-H`; the fingerprint check is unchanged.

## Validation

Two checks. Both must pass.

### Check 1 - the entry exists and resolves

```bash
ssh-keygen -F fedora-top.home.arpa -l
# Expected: "256 SHA256:0dqRCxVLpssRFdRjgHKkWy5lS31IUiZF7DFZj8cFm2w ... (ED25519)"
```

### Check 2 - SSH works without `HostKeyAlias`

```bash
ssh \
  -i "$HOME/.ssh/id_ed25519_personal.1password.pub" \
  -o IdentityAgent="$HOME/.1password-ssh-agent.sock" \
  -o IdentitiesOnly=yes \
  -o PreferredAuthentications=publickey \
  -o ControlMaster=no \
  -o ControlPath=none \
  -o StrictHostKeyChecking=yes \
  -o BatchMode=yes \
  verlyn13@fedora-top.home.arpa \
  'hostname; whoami'
# Expected:
#   fedora-top
#   verlyn13
# No host-key prompt; no warning.
```

`StrictHostKeyChecking=yes` + `BatchMode=yes` deliberately disable
prompting so the SSH command would fail (exit nonzero) if the new
known_hosts entry were missing or wrong. A successful login is the
positive signal.

A negative cross-check confirms the alias workaround is still
available as a fallback:

```bash
ssh \
  -i "$HOME/.ssh/id_ed25519_personal.1password.pub" \
  -o IdentityAgent="$HOME/.1password-ssh-agent.sock" \
  -o IdentitiesOnly=yes \
  -o PreferredAuthentications=publickey \
  -o HostKeyAlias=192.168.0.206 \
  -o ControlMaster=no \
  -o ControlPath=none \
  verlyn13@fedora-top.home.arpa \
  'hostname'
# Expected: fedora-top (the alias path keeps working)
```

## Rollback

The change is fully local and reversible.

```bash
# Remove the FQDN entry only.
ssh-keygen -R fedora-top.home.arpa
# Or, restore from the backup written during apply.
# Replace <backup-path> with the value printed by the apply step.
cp -a "<backup-path>" "$HOME/.ssh/known_hosts"
chmod 600 "$HOME/.ssh/known_hosts"
```

After rollback, SSH commands again need `HostKeyAlias=192.168.0.206`
to talk to `fedora-top.home.arpa`. The IP-based entry remains
intact in either case.

## Redaction / Secret-Handling Note

- The ED25519 host-key fingerprint
  `SHA256:0dqRCxVLpssRFdRjgHKkWy5lS31IUiZF7DFZj8cFm2w` is **public
  by definition**; it identifies the server publicly to clients
  during the SSH handshake. It is safe to record in repo docs and
  has been recorded across every prior fedora-top apply doc.
- The new known_hosts entry itself is non-secret public-key
  material. It is safe to store at `~/.ssh/known_hosts` with mode
  0600.
- The MacBook's private operator key (held in 1Password SSH agent)
  is **not touched** by this packet. No private-key material is
  written, read, copied, or echoed at any step.
- The pre-apply backup is named with a UTC timestamp; if the
  operator chooses, they may delete it after the validation passes.
  The backup contains other (non-fedora-top) known_hosts entries
  that are likewise non-secret host-identity material; same handling
  applies.
- No 1Password item is created, edited, or read by this packet.

## Required Approval Phrase

Live apply requires guardian approval substantially equivalent to:

```text
I approve applying the MacBook known_hosts reconciliation for
fedora-top.home.arpa: back up ~/.ssh/known_hosts to
~/.ssh/known_hosts.pre-fedora-top-reconciliation-<timestamp>; sanity
check that no fedora-top.home.arpa entry exists yet and that the
192.168.0.206 entry's fingerprint already matches
SHA256:0dqRCxVLpssRFdRjgHKkWy5lS31IUiZF7DFZj8cFm2w; run
ssh-keyscan -t ed25519 -H fedora-top.home.arpa, verify the fetched
key's fingerprint matches the same value, and append to
~/.ssh/known_hosts; validate that SSH to fedora-top.home.arpa works
with StrictHostKeyChecking=yes and BatchMode=yes and no
HostKeyAlias workaround. MacBook-side only; do not touch
fedora-top, sshd, firewall, DNS, DHCP, HomeNetOps, Cloudflare,
Tailscale, WARP, cloudflared, sudoers, Docker, LUKS, power, reboot,
or 1Password.
```

## current-status.yaml Update Plan

This packet introduces a new `prepared_packets[]` entry alongside
the existing `remote-admin-routing-design`:

```yaml
prepared_packets:
  - name: remote-admin-routing-design
    # (existing entry, unchanged)
  - name: known-hosts-reconciliation
    packet_doc: docs/device-admin/fedora-top-known-hosts-reconciliation-packet-2026-05-13.md
    prepared_at: 2026-05-14T00:00:00Z   # filled at commit time
    state: prepared
    approval_phrase_excerpt: >-
      "I approve applying the MacBook known_hosts reconciliation
      for fedora-top.home.arpa: back up ~/.ssh/known_hosts ... run
      ssh-keyscan ... verify fingerprint
      SHA256:0dqRCxVLpssRFdRjgHKkWy5lS31IUiZF7DFZj8cFm2w ...
      MacBook-side only; do not touch fedora-top, sshd, firewall,
      ..." (see packet for full text).
```

When the packet is applied, the YAML moves the entry to
`applied_packets[]` and removes the corresponding
`macbook-known-hosts-reconciliation` item from `blocked_items[]`.
Both the design packet and this one already point at this packet as
the preferred next live action.

## Evidence To Record After Apply

```text
timestamp:
operator:
backup path:
192.168.0.206 fingerprint pre-apply (must equal expected):
fetched fedora-top.home.arpa fingerprint (must equal expected):
appended: yes/no
post-apply ssh-keygen -F fedora-top.home.arpa -l:
post-apply SSH command (StrictHostKeyChecking=yes, BatchMode=yes,
                       no HostKeyAlias) result:
negative cross-check with HostKeyAlias=192.168.0.206 still works:
rollback used: yes/no
remaining blockers:
```

Do not paste private keys, agent socket paths, 1Password item IDs,
or shell history into the evidence block. The host-key fingerprint
is public and is the only host-identity value that should appear.

## Related

- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
- [fedora-top-remote-admin-routing-design-2026-05-13.md](./fedora-top-remote-admin-routing-design-2026-05-13.md)
- [fedora-top-ssh-hardening-apply-2026-05-13.md](./fedora-top-ssh-hardening-apply-2026-05-13.md)
- [fedora-top-firewalld-narrowing-apply-2026-05-13.md](./fedora-top-firewalld-narrowing-apply-2026-05-13.md)
- [fedora-44-laptop.md](./fedora-44-laptop.md)
- [../ssh.md](../ssh.md)
- [../secrets.md](../secrets.md)

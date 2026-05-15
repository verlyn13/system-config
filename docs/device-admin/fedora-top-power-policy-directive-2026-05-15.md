---
title: fedora-top Power Policy Operator Directive - 2026-05-15
category: operations
component: device_admin
status: active
version: 0.1.0
last_updated: 2026-05-15
tags: [device-admin, fedora-top, linux, power, suspend, directive, operator-handoff]
priority: high
---

# fedora-top Power Policy Operator Directive - 2026-05-15

This is the operator directive for the next fedora-top session after
the 2026-05-14T19:23:29 AKDT suspend-mid-SSH incident. It sequences
two prepared packets — a read-only baseline and a scoped-live-change
apply — and lists the manual validation that closes the loop.

Authority and procedure live in the packets and scripts linked below;
this directive just sequences them.

## Context

- **2026-05-14T19:23:29 AKDT**: an active SSH session from the MacBook
  was dropped when fedora-top broadcast `The system will suspend now!`
  and suspended. A mid-edit Claude session on `~/Projects/shelltutor`
  was interrupted; no host data was corrupted (the MacBook side
  saw the disconnect cleanly via `TCPKeepAlive`+`ServerAliveInterval=30`).
- **Root cause**: lid-close or idle suspend with no power policy
  applied. The intent ("no sleep on AC while remotely administered")
  was recorded in
  [fedora-44-laptop.md:460](./fedora-44-laptop.md) and
  [fedora-top-complete-instructions.md:539](./fedora-top-complete-instructions.md)
  on 2026-05-13 but never packetized.
- **Workstation mitigation already applied** (commit pending):
  `~/.ssh/conf.d/fedora-top.conf` now declares
  `ServerAliveCountMax=3` explicitly so future dead sessions die in
  ~90 s instead of waiting for the OS TCP timeout.
- **Host status at last check (2026-05-15T06:28:12Z)**: still
  off-LAN. Operator must physically wake the laptop before any of
  these steps can run.

## New Spec Authority

- [linux-terminal-admin-spec.md](./linux-terminal-admin-spec.md)
  v0.1.0 — the first Linux-side terminal-admin spec, parallel to
  Windows v0.5.0. Captures: artifact separation (Markdown runbook +
  `.sh` in `scripts/device-admin/`), `bash` + ASCII-portable
  contract, `jq`-driven structured JSON evidence, cross-shell
  normalization (no stringly-typed booleans), packet-defect halt
  rule (inherited from Windows §Packet-Defect Halt Rule).

## Reading List (read FIRST)

In this order:

1. [linux-terminal-admin-spec.md](./linux-terminal-admin-spec.md) v0.1.0
2. [current-status.yaml](./current-status.yaml) — find
   `devices[].device == "fedora-top"`. Both packets should be in
   `prepared_packets[]`; the power-policy baseline is
   `approval-required`, the apply is
   `approval-required-blocked-on-baseline`.
3. [fedora-top-power-policy-baseline-2026-05-15.md](./fedora-top-power-policy-baseline-2026-05-15.md)
4. [fedora-top-power-policy-apply-2026-05-15.md](./fedora-top-power-policy-apply-2026-05-15.md)

## Step 0 — Wake the laptop physically

`fedora-top` has been off the LAN since the 2026-05-14T19:23 suspend.
WoL is not configured. Open the lid or press the power button on the
physical device.

From the MacBook, confirm reachability:

```bash
nc -vz -G 3 fedora-top.home.arpa 22
# expected: Connection to fedora-top.home.arpa 22 port [tcp/ssh] succeeded!

ssh fedora-top 'uptime'
# expected: e.g. "  06:35:00 up 1 min, ..."
# the recent boot is informative; the suspend dropped the session
# but the laptop suspended cleanly, so this is a resume not a
# fresh boot. Either is fine.
```

Halt here if reachability fails.

## Step 1 — Phase 0 baseline (read-only)

The packet:
[fedora-top-power-policy-baseline-2026-05-15.md](./fedora-top-power-policy-baseline-2026-05-15.md).

```bash
# From the MacBook, in the system-config checkout:
script='scripts/device-admin/fedora-top-power-policy-baseline-v0.3.0.sh'

# 1. Verify the local copy matches the declared sha256.
expected='05a8a6f90d82a2e155f9064e982f1d250480342f0518fa6a53ea743a64ea41ef'
actual=$(shasum -a 256 "$script" | awk '{print $1}')
[ "$actual" = "$expected" ] || { echo "local sha256 mismatch"; exit 1; }

# 2. Copy to the host (Option A in the runbook).
scp "$script" fedora-top:/var/tmp/

# 3. SSH in, verify on host, run.
ssh fedora-top <<'EOF'
set -euo pipefail
cd /var/tmp
expected='05a8a6f90d82a2e155f9064e982f1d250480342f0518fa6a53ea743a64ea41ef'
actual=$(sha256sum fedora-top-power-policy-baseline-v0.3.0.sh | awk '{print $1}')
if [ "$actual" != "$expected" ]; then
    echo "host sha256 mismatch: $actual vs $expected" >&2
    exit 1
fi
bash fedora-top-power-policy-baseline-v0.3.0.sh
EOF
```

The script writes JSON evidence under
`/var/tmp/jefahnierocks-device-admin/fedora-top-power-policy-baseline-<UTC>/`
and prints the `08-summary.json` body at the end.

**Hand-back checkpoint.** Capture `08-summary.json` verbatim and
return it to system-config. Do NOT proceed to Step 2 until
`docs/device-admin/fedora-top-power-policy-baseline-apply-2026-05-15.md`
is committed.

Expected `08-summary.json` shape (key fields):

```json
{
  "host": "fedora-top",
  "ssh_user": "verlyn13",
  "logind": {
    "handle_lid_switch_external_power": "suspend",
    "handle_lid_switch_battery": "suspend",
    "idle_action": "ignore",
    "handle_lid_switch_docked": "suspend"
  },
  "diagnostic": {
    "lid_close_on_ac_will_suspend": true,
    "lid_close_on_battery_will_suspend": true,
    "idle_will_suspend": false
  },
  "suspend_events_last_7d": {
    "suspend_count": 1,
    "resume_count": 1
  }
}
```

`suspend_events_last_7d` should record the 2026-05-14T19:23:29 event.
`logind.handle_lid_switch_external_power` is the field this whole
exercise is about — the most likely root cause of tonight's failure
is that it was `suspend` (default).

## Step 2 — Phase 4 apply (live change)

**Only after Step 1's apply record commits.**

The packet:
[fedora-top-power-policy-apply-2026-05-15.md](./fedora-top-power-policy-apply-2026-05-15.md).

```bash
# From the MacBook:
script='scripts/device-admin/fedora-top-power-policy-apply-v0.2.0.sh'
expected='a1e3bf5da90b763648064d2dd8961ccfd11fcb4f560d9bdb5a255d40133ab4c2'
actual=$(shasum -a 256 "$script" | awk '{print $1}')
[ "$actual" = "$expected" ] || { echo "local sha256 mismatch"; exit 1; }

scp "$script" fedora-top:/var/tmp/

ssh fedora-top <<'EOF'
set -euo pipefail
cd /var/tmp
expected='a1e3bf5da90b763648064d2dd8961ccfd11fcb4f560d9bdb5a255d40133ab4c2'
actual=$(sha256sum fedora-top-power-policy-apply-v0.2.0.sh | awk '{print $1}')
if [ "$actual" != "$expected" ]; then
    echo "host sha256 mismatch: $actual vs $expected" >&2
    exit 1
fi
bash fedora-top-power-policy-apply-v0.2.0.sh
EOF
```

The script will:

1. Preflight identity / shell / sudo checks.
2. Snapshot `/etc/systemd/logind.conf` and every `.conf` in
   `/etc/systemd/logind.conf.d/` to
   `/var/tmp/jefahnierocks-device-admin/.../snapshot/`.
3. Write the drop-in (idempotent: skips if content already matches).
4. `systemctl reload systemd-logind` (SIGHUP — does NOT drop active
   sessions; your SSH stays alive).
5. Read-back validate `HandleLidSwitchExternalPower=ignore`,
   `HandleLidSwitchDocked=ignore`, `IdleAction=ignore`. Hard-stop +
   snapshot restore on mismatch.
6. Apply per-user GNOME `sleep-inactive-ac-type='nothing'` and
   `idle-dim=false` for `wyn` and `verlyn13` (only if the user has
   an active session bus; otherwise records `session_bus_available:
   false` and continues).
7. Emit `08-summary.json` with before / after / drop-in / GNOME
   result.

Return `08-summary.json` to system-config for the apply record.

## Step 3 — Manual validation

After Step 2's apply record commits, perform these operator-side
checks. They confirm the policy actually changed behavior, not just
the config files.

```bash
# A. Confirm lid-close on AC does NOT suspend.
#    Plug in (if not already), close the lid for 30 s, open the lid.
#    From the MacBook:
ssh fedora-top 'uptime; journalctl -u systemd-logind --since "1 minute ago" --no-pager'
# Expected: uptime unchanged (no recent boot/resume); journalctl
# shows the lid-close event but NOT a suspend.

# B. Confirm battery lid-close STILL suspends (intentional).
#    Unplug AC, close lid; the laptop should still suspend to save
#    battery. Operator decision; if Wyn finds this inconvenient,
#    run a separate packet to widen the policy to "ignore always".

# C. Confirm idle does NOT suspend.
#    Leave the laptop alone for >30 min on AC. SSH session should
#    stay alive; uptime should not advance through a sleep gap.
```

If any of A or C fails, halt and hand back.

## Step 4 — Update current-status.yaml

After Steps 1 and 2 apply records commit, update
`docs/device-admin/current-status.yaml`'s fedora-top block:

- Move `fedora-top-power-policy-baseline` and
  `fedora-top-power-policy-apply` from `prepared_packets[]` to
  `applied_packets[]` with apply record references + commit SHAs.
- Resolve the `fedora-top-suspend-mid-ssh-incident-2026-05-14`
  `blocked_items` entry by linking to the two apply records.
- The prose-only "AC/no-sleep policy" notes in
  [fedora-44-laptop.md](./fedora-44-laptop.md) and
  [fedora-top-complete-instructions.md](./fedora-top-complete-instructions.md)
  can be rewritten to point at the apply records as the source of
  truth.

## Hard Stops

Halt and hand back to system-config rather than improvise on any of:

- `fedora-top` not reachable on TCP/22 (host still suspended,
  network changed, sshd died).
- Local sha256 of either script does not match the value declared
  in the corresponding packet runbook.
- Host-side sha256 of the copied script does not match.
- The baseline `08-summary.json` shows unexpected state (the v0.3.0
  postmortem rule: a mismatched expectation is a packet defect, not
  a host defect — surface the divergence, do not paper over).
- The apply script throws (any halt class: identity mismatch, sudo
  -n failure, drop-in mode/owner mismatch, post-reload effective
  config mismatch, GNOME gsettings failure).
- Any out-of-scope surface gets touched: LUKS, TPM, Secure Boot,
  firmware, BIOS, kernel cmdline, sudoers, accounts, services other
  than `systemd-logind`, firewall, DNS, DHCP, OPNsense, Cloudflare,
  WARP, Tailscale, 1Password.

Per
[linux-terminal-admin-spec.md §Stop Rules](./linux-terminal-admin-spec.md)
and the inherited Windows §Packet-Defect Halt Rule: **the operating
agent does not patch a mutating script locally**. Parser /
encoding / quoting / serialization / state-normalization failures
are packet defects. Preserve, halt, hand back for a new packet
version.

## Out Of Scope

The power-policy chain explicitly does NOT cover:

- **LUKS remote-reboot strategy** — separate decision in
  `current-status.yaml`'s `luks-remote-reboot-strategy` blocked_item.
  Coupled in prose; tracked separately so the power policy can ship
  without that decision.
- **Wake-on-LAN configuration** — fedora-top will still suspend on
  battery+lid-close. If it goes off-LAN that way, it has to be woken
  physically. WoL is a separate packet.
- **`suspend.target` / `hibernate.target` masking** — apply packet
  leaves both reachable so `systemctl suspend` still works
  manually.
- **BIOS-level power settings** — out of scope; would require
  physical access and a firmware packet.
- **Cloudflare WARP / off-LAN access** — phase 5 work, separate gate.

## Cross-References

- [linux-terminal-admin-spec.md](./linux-terminal-admin-spec.md) v0.1.0
- [windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md) v0.5.0 (parent for §Packet-Defect Halt Rule and §Packet Artifact Separation)
- [fedora-top-power-policy-baseline-2026-05-15.md](./fedora-top-power-policy-baseline-2026-05-15.md)
- [fedora-top-power-policy-apply-2026-05-15.md](./fedora-top-power-policy-apply-2026-05-15.md)
- [fedora-44-laptop.md](./fedora-44-laptop.md)
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)

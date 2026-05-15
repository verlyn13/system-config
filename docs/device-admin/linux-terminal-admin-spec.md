---
title: Linux Terminal Administration Spec
category: operations
component: device_admin
status: active
version: 0.1.0
last_updated: 2026-05-15
tags: [device-admin, linux, fedora, bash, openssh, terminal-admin, evidence, lifecycle]
priority: high
---

# Linux Terminal Administration Spec

This is the operating spec for Linux device administration from the
MacBook terminal. It is the parallel of
[windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md) v0.5.0
and inherits its discipline; this doc records only the Linux-side
deltas. When the two specs disagree, the Linux spec wins for Linux
devices; for shared concepts (lifecycle phases, classification labels,
packet artifact separation, packet-defect halt rule), the Windows
spec is the longer-form reference and this doc points at it rather
than duplicating.

`fedora-top` is the first reference Linux SSH host
(`reference-ssh-host`, `lifecycle_phase: 4`).

## Authority

Authoritative Linux device state lives in:

- [current-status.yaml](./current-status.yaml) — `devices[].device` blocks for Linux hosts.
- Per-device record (e.g. [fedora-44-laptop.md](./fedora-44-laptop.md)).
- The packet and apply records under `docs/device-admin/`.

This spec defines procedure. It does not authorize a live change by
itself.

## Inherited From Windows Spec

The following sections in
[windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md)
v0.5.0 apply verbatim to Linux device administration:

- §Invariants And Future-State (per-device 1P SSH key invariant; no public WAN exposure)
- §Management Lanes (OpenSSH primary, RDP not applicable)
- §Fleet Standard rows that are not Windows-specific (admin client, local transport, SSH identity, 1P item naming, SSH client alias, firewall names where applicable)
- §Device Lifecycle (phases 0..6 — `install-shell-lane` and later)
- §Classification Labels (the labels are platform-agnostic; only `rdp-only-host` is Windows-only)
- §Session Classes (`read-only-probe`, `scoped-live-change`, `workstation-config-change`)
- §Preflight (MacBook ssh -G check; identity proof on the host)
- §SSH Client Rules
- §Packet Standards For Live Changes
- §Packet Artifact Separation
- §Structured Evidence
- §Packet-Defect Halt Rule
- §Stop Rules (with the Linux-specific additions below)

## Linux Deltas

### Shell And Encoding

- The executable shell is **bash**. Use `#!/usr/bin/env bash` and
  `set -euo pipefail` at the top of every mutating script.
- Encoding: scripts are **UTF-8 (no BOM)** by default. Linux readers
  do not suffer the Windows-1252 vs UTF-8 ambiguity that bit the
  DESKTOP-2JJ3187 v0.3.0 packet. **ASCII-portable is still preferred**
  for diagnostic output (avoid em-dashes, smart quotes, non-breaking
  spaces) so JSON serialization and log output are predictable.
- The encoding contract for the packet's executable artifact: **either
  ASCII-only or UTF-8 without BOM**. Declare which in the Markdown
  runbook's script reference.

### Cross-Shell Normalization (Linux Edition)

The Windows spec's §Cross-Shell Data Normalization addresses enum
serialization across PowerShell process boundaries. Linux has a
parallel hazard with bash: **stringly-typed values across pipes**.
Use `jq` to produce structured JSON; never compare booleans by
string match.

Patterns to use:

```bash
# Good: explicit boolean derived from a tested condition.
sshd_active=$(systemctl is-active sshd 2>/dev/null || echo unknown)
case "$sshd_active" in
  active) sshd_active_bool=true ;;
  *)      sshd_active_bool=false ;;
esac

# Good: jq for structured records, never string-builders.
jq -n \
  --arg ts        "$(date -u +%FT%TZ)" \
  --arg host      "$(hostname -s)" \
  --arg sshd      "$sshd_active" \
  --argjson alive "$sshd_active_bool" \
  '{ts:$ts, host:$host, sshd:$sshd, sshd_active:$alive}' \
  > "$evidence_dir/00-summary.json"
```

Patterns to avoid:

```bash
# Bad: stringly-typed booleans in JSON.
echo "{\"sshd_active\": \"$sshd_active\"}"  # produces ".. \"active\"" not true/false.

# Bad: comparing systemctl output as a string in the consumer.
if [ "$(cat result.json | grep -o '"state":[^,}]*')" = '"NotPresent"' ]; then ...
```

### Privilege Separation

Linux scripts run as the SSH user (`verlyn13` on fedora-top) and
invoke `sudo` internally for privileged steps. Do not run the whole
script under `sudo bash <<...`; the unprivileged half is fine as
verlyn13 and `sudo` calls are explicit.

Required at the top of any mutating Linux script:

```bash
require_sudo() {
  if ! sudo -n true 2>/dev/null; then
    echo "sudo -n unavailable. This script requires passwordless sudo for the SSH user." >&2
    exit 1
  fi
}
```

The fedora-top NOPASSWD sudoers grant is documented in
[fedora-top-privilege-cleanup-apply-2026-05-13.md](./fedora-top-privilege-cleanup-apply-2026-05-13.md);
read-only-probe scripts may not require sudo at all if they read
only user-accessible state.

### Evidence Layout

```text
/var/tmp/jefahnierocks-device-admin/<device>-<purpose>-<UTC-yyyymmddThhmmssZ>/
  00-run.log
  01-<concern>.json
  02-<concern>.json
  ...
  08-summary.json
```

`/var/tmp/` is preferred over `/tmp/` because `/var/tmp/` typically
survives reboot. The directory is per-run so successive applies do
not overwrite each other. Operators may `mv` evidence to
`~/jefahnierocks-device-admin/` or to an external operator-controlled
path; the repo's `.gitignore` excludes
`docs/device-admin/<device>-*-yyyymmddThhmmssZ/` to match the Windows
pattern.

JSON evidence files use `jq` to construct values; never write
hand-built JSON via `echo`. Run summary at `08-summary.json` is the
canonical hand-back to system-config.

### Script Transfer And Verification

The canonical operator flow for a Linux packet:

```bash
# On the operator MacBook, from the system-config checkout:
script="scripts/device-admin/<device>-<purpose>-vX.Y.Z.sh"

# Verify the local copy matches the declared sha256.
shasum -a 256 "$script"

# Transfer to the host.
scp "$script" <device>:/var/tmp/

# SSH in and verify on the host before running.
ssh <device> <<EOF
  set -euo pipefail
  cd /var/tmp
  expected="<sha256-from-packet>"
  actual=\$(sha256sum "\$(basename $script)" | awk '{print \$1}')
  if [ "\$actual" != "\$expected" ]; then
    echo "sha256 mismatch: \$actual vs \$expected" >&2
    exit 1
  fi
  bash "\$(basename $script)"
EOF
```

Or, equivalently, pipe the script through stdin so it never persists
on the host disk (operator's choice; both are spec-conforming as long
as the sha256 is declared in the Markdown runbook):

```bash
ssh <device> 'bash -s' < scripts/device-admin/<device>-<purpose>-vX.Y.Z.sh
```

The stdin form is convenient for one-shot scripts but makes
post-run inspection harder. Prefer the scp+verify form for any
mutating packet.

### Idempotency Hooks

Mutating Linux scripts should:

- Snapshot every file they will modify to `<evidence_dir>/snapshot/`
  with a `.preinstall` suffix BEFORE the first edit. This is the
  rollback substrate.
- Use `install -m <mode> -o <owner> -g <group> <file>` for files
  with required permissions; `install` is atomic and idempotent.
- Use `systemctl reload <unit>` over `restart` where the unit
  supports SIGHUP. `systemd-logind` only reloads via `systemctl
  restart systemd-logind` because the live session dies otherwise —
  prefer that explicit form when needed and document the user-session
  impact.
- Validate with `systemd-analyze verify <unit>` for unit edits;
  `sshd -t` for SSH config edits; equivalent for other services.
- Read back the effective state after the mutation and emit it as
  structured JSON.

### Stop Rules (Linux Additions)

In addition to the Windows-spec stop rules:

- Stop if `sudo -n true` fails partway through a mutating script
  (the NOPASSWD grant was withdrawn or the sudoers file is broken).
- Stop if `systemd-analyze verify <unit>` fails after a unit edit.
- Stop if a drop-in file's mode/owner does not match the documented
  required ACL after `install`.
- Stop if `journalctl --boot=0` shows an obvious mutation by another
  process during the script's run window.

The packet-defect halt rule (Windows §Packet-Defect Halt Rule) applies
unchanged: parser / encoding / quoting / serialization /
state-normalization failures are packet defects, not host defects.
Halt, preserve evidence, hand back for a new packet version. The
operating agent does not patch a mutating script locally.

## Current Linux Fleet Posture

| Device | `lifecycle_phase` | `classification` | Notes |
|---|---|---|---|
| `fedora-top` | 4 (entering harden+) | `reference-ssh-host` | Phase 4 applies through 2026-05-14 admin-backup-ssh-key. Power-policy packet is the next phase-4 work after the 2026-05-14 19:23 mid-SSH suspend incident. |

If a second Linux device enters the fleet, classification labels are
the same as Windows except `rdp-only-host` does not apply.

## Cross-References

- [windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md) v0.5.0 (parent reference for inherited sections)
- [windows-terminal-admin-baseline-template.md](./windows-terminal-admin-baseline-template.md) (PowerShell baseline pattern; bash equivalent is implicit in the per-device packets until a `linux-terminal-admin-baseline-template.md` is authored)
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)

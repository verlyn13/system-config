---
title: DESKTOP-2JJ3187 Reconciliation Packet - 2026-05-15
category: operations
component: device_admin
status: prepared
version: 0.1.0
last_updated: 2026-05-15
tags: [device-admin, desktop-2jj3187, windows, openssh, reconciliation, read-only, phase-3-prep]
priority: high
---

# DESKTOP-2JJ3187 Reconciliation Packet - 2026-05-15

Read-only reconciliation of DESKTOP-2JJ3187 admin state after
[desktop-2jj3187-ssh-lane-install-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-2026-05-15.md)
v0.3.0 halted in §S1 due to packet defects. This packet must apply
and its apply record must be committed **before** the v0.4.0 install
packet is allowed to run.

## Why This Packet Exists

The v0.3.0 attempt halted at:

```text
Unexpected OpenSSH.Server state: 0
```

Root-cause analysis identified two packet defects (not host defects):

1. The v0.3.0 procedure required the operating agent to transcribe a
   `.ps1` out of a Markdown code block. The script contained
   non-ASCII punctuation (em-dashes) and was first saved UTF-8
   without BOM. WinPS 5.1's Windows-1252 default produced mojibake
   and the parser failed. The agent then re-encoded the file as
   UTF-8 with BOM — that repair was **not authorized** by the
   packet, which is a [spec §Packet-Defect Halt Rule](./windows-terminal-admin-spec.md)
   violation but did not mutate host state.
2. The re-encoded script reached §S1 and shelled `Get-WindowsCapability`
   through `powershell.exe -Command` with `ConvertTo-Json -Compress`.
   That serialized the `Microsoft.Dism.Commands.PackageFeatureState`
   enum as integer `0`, which the outer string comparison rejected.
   The host's actual state was the correct `NotPresent`.

This reconciliation packet confirms the host has not drifted from
the Phase 0 baseline state (commit `00ee787`,
`2026-05-15T03:26:52Z`) and that no v0.3.0 §S2/§S5/§S6/§S7 mutation
occurred (no service start, no key install, no firewall rule, no
sshd restart). After the reconciliation apply record lands, v0.4.0
may proceed.

## Session Class

`read-only-probe`. No host mutation. No service, firewall, account,
sshd_config, authorized_keys, registry, or DISM mutation.

The script writes a structured JSON evidence directory under
`C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-reconciliation-<UTC-timestamp>\`.
Evidence is host-local; the agent returns the `08-summary.json` body
verbatim to system-config as the hand-back.

## Executable Artifact

The agent runs the named script directly. Do **not** transcribe
content from this Markdown into a separate file. The Markdown
documents *what* the script does; the canonical executable is the
file referenced below.

```text
script:     scripts/device-admin/desktop-2jj3187-reconciliation-v0.1.0.ps1
sha256:     4cd75bcb8f31857d53a02a2de29fa94f73700c882ebb6b739154f26261dc8b43
encoding:   ASCII (validated via python; no bytes > 0x7F)
shell:      C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
invocation: powershell.exe -NoProfile -ExecutionPolicy Bypass -File <path>\desktop-2jj3187-reconciliation-v0.1.0.ps1
```

Pre-run verification on DESKTOP-2JJ3187:

```powershell
# Confirm the script is the approved artifact before running.
$expected = '4cd75bcb8f31857d53a02a2de29fa94f73700c882ebb6b739154f26261dc8b43'
$actual   = (Get-FileHash -Algorithm SHA256 -LiteralPath '<path-to-script>').Hash.ToLower()
if ($actual -ne $expected) {
    throw "sha256 mismatch: expected $expected, got $actual"
}
```

If the sha256 differs, **halt and hand back**. Do not run a script
whose hash does not match the packet reference.

## Approval Phrase

> Run the `desktop-2jj3187-reconciliation-v0.1.0` script on
> DESKTOP-2JJ3187 from an elevated Windows PowerShell 5.1 session
> (`powershell.exe`) as `DESKTOP-2JJ3187\jeffr`. The script is
> read-only and writes a JSON evidence directory under
> `C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-reconciliation-<timestamp>\`.
> Return the `08-summary.json` body verbatim to system-config as the
> hand-back. No host mutation. The v0.3.0 install script and its
> evidence directory must be preserved untouched for postmortem.

## Preflight (operator)

Before invoking the script:

1. RDP into DESKTOP-2JJ3187 from the MacBook Windows App profile.
2. Open elevated **Windows PowerShell 5.1**, not pwsh 7. Start menu
   → search `Windows PowerShell` → right-click → **Run as
   administrator**. Confirm:

   ```powershell
   $PSVersionTable.PSVersion
   ```

   Expected: `Major=5  Minor=1  Build=...`.

3. Confirm identity:

   ```powershell
   hostname
   whoami
   ```

   Expected: `DESKTOP-2JJ3187` / `DESKTOP-2JJ3187\jeffr`.

4. Confirm script hash matches the value above. Halt if not.

5. Confirm the v0.3.0 evidence directory exists and is intact:

   ```powershell
   Get-ChildItem 'C:\Users\Public\Documents\jefahnierocks-device-admin' |
     Select-Object Name, LastWriteTime
   ```

   Do not delete or rotate the v0.3.0 directory; it is preservation
   evidence for the postmortem trail.

## Execute

From the elevated WinPS 5.1 session:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
  '<full-path-to>\desktop-2jj3187-reconciliation-v0.1.0.ps1'
```

Or, if already in WinPS 5.1:

```powershell
& '<full-path-to>\desktop-2jj3187-reconciliation-v0.1.0.ps1'
```

The script self-prints the summary at the end and tells the operator
where evidence landed.

## Evidence Layout

```text
C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-reconciliation-<UTC-yyyymmddThhmmssZ>\
  00-run.json
  01-identity.json
  01-identity-groups.txt        (whoami /groups raw text for SID lookup)
  02-openssh-capability.json    (NORMALIZED: state_string + state_int + state_type)
  03-openssh-paths.json
  04-services.json
  05-listeners.json
  06-firewall-rules.json
  07-network-profile.json
  08-summary.json               (one-page reconciliation; this is the hand-back)
```

All JSON files are written via `ConvertTo-Json -Depth 8` and
`Set-Content -Encoding utf8`. No `Format-Table -AutoSize` evidence
this time — the Phase 0 baseline's elision lesson is encoded.

## Hand-Back: `08-summary.json` Schema

The agent returns this JSON body verbatim. The fields are stable
strings (no enums, no objects); system-config compares against the
expected values listed below.

| Field | Expected value | Why |
|---|---|---|
| `computer` | `DESKTOP-2JJ3187` | identity proof |
| `expected_computer` | `DESKTOP-2JJ3187` | self-check |
| `user` | `jeffr` | identity proof |
| `expected_user` | `jeffr` | self-check |
| `shell` | `Desktop 5.1.x.x` | enforced WinPS 5.1 |
| `expected_shell_match` | `true` | self-check |
| `admin_role` | `true` | elevation proof |
| `high_mandatory_level` | `true` | elevation proof |
| `openssh_capability_present` | `true` | DISM returned a result |
| `openssh_capability_state` | `NotPresent` | confirms no v0.3.0 install mutation |
| `sshd_exe_present` | `false` | confirms no install mutation |
| `sshd_config_present` | `false` | confirms no config mutation |
| `admin_authkeys_present` | `false` | confirms no key install |
| `sshd_service_status` | empty | service absent |
| `sshd_service_starttype` | empty | service absent |
| `tcp_22_listening` | `false` | no SSH service running |
| `tcp_3389_listening` | `true` | RDP unchanged |
| `jefahnierocks_ssh_rule` | `false` | no §S6 mutation |
| `jefahnierocks_rdp_tcp_rule` | `true` | RDP rule preserved |
| `jefahnierocks_rdp_udp_rule` | `true` | RDP rule preserved |

Any deviation from these expected values is a finding system-config
must reconcile before v0.4.0 install can run.

## Hard Stops

Stop and hand back to system-config rather than improvising if:

- Identity proof returns a different hostname or admin username.
- `$PSVersionTable.PSVersion.Major` is not `5` (you are in pwsh 7).
  Close the window and open Windows PowerShell instead.
- Script sha256 does not match the value declared in this packet.
- The v0.3.0 evidence directory has been deleted or renamed; the
  postmortem trail must be preserved.
- `08-summary.json` has any field that differs from the Expected
  Values table above — surface the deviation as the hand-back rather
  than continuing to v0.4.0.

## Boundaries

This packet does **not** authorize:

- Any service start/stop/reconfigure.
- Any firewall rule mutation.
- Any sshd_config or authorized_keys mutation.
- Any DISM Add-WindowsCapability / Remove-WindowsCapability.
- Any rotation, deletion, or modification of the v0.3.0 evidence
  directory or the v0.3.0 script (preserve verbatim).
- Any change to BitLocker, Defender, network profile, DNS, DHCP,
  OPNsense, Cloudflare, WARP, or 1Password.

If the script's own logic appears to do anything beyond the read-only
operations described in this packet, halt — the script may have been
modified from its declared sha256.

## After Apply

System-config writes
`docs/device-admin/desktop-2jj3187-reconciliation-apply-2026-05-15.md`
with the returned `08-summary.json` body and confirms whether v0.4.0
install can proceed. The
[v0.4.0 install packet](./desktop-2jj3187-ssh-lane-install-v0.4.0-2026-05-15.md)
is approval-gated on the reconciliation apply record landing in git.

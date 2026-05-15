---
title: DESKTOP-2JJ3187 Windows-Side Directive - 2026-05-15
category: operations
component: device_admin
status: active
version: 0.2.0
last_updated: 2026-05-15
tags: [device-admin, desktop-2jj3187, windows, directive, agent-handoff, phase-3]
priority: high
---

# DESKTOP-2JJ3187 Windows-Side Directive - 2026-05-15

This is the directive for an **agent or operator running on
DESKTOP-2JJ3187 in an elevated Windows PowerShell 5.1 session**. The
MacBook-side prep (1Password item, chezmoi conf.d) is complete; the
Windows-side work is what remains.

**v0.2.0 update (2026-05-15)**: this directive supersedes the v0.1.0
sequence that referenced the v0.3.0 install packet. The v0.3.0
install attempt halted in §S1 due to packet defects (UTF-8-without-BOM
encoding under WinPS 5.1, then enum-as-integer JSON serialization).
**No host mutation occurred.** Spec is bumped to v0.5.0 with new
rules. New sequence: **reconciliation → v0.4.0 install**.

Authority and procedure live in the packets and scripts linked below;
this doc sequences them and states the new stop-on-handback rule.

## Context (already done on the MacBook side)

- 1Password admin key item created 2026-05-14T19:05:13-08:00:
  ```text
  op://Dev/jefahnierocks-device-desktop-2jj3187-admin-ssh-verlyn13
  fingerprint: SHA256:0oDYmXRFrGuT4yyd0NLAAVyk0l/Aygu+iV88W2eq+/s
  public key:  ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFRgw1xN2rjmlIFbAPsp7cc6SJcm0h5IMvrL8o6CyLh9
  ```
  1Password generated the keypair in-place. The private half lives
  only in the operator MacBook's 1Password Dev vault.
- MacBook chezmoi conf.d applied (commit `f0fb9c1`,
  [macbook-ssh-conf-d-desktop-2jj3187-apply-2026-05-15.md](./macbook-ssh-conf-d-desktop-2jj3187-apply-2026-05-15.md)).
  `ssh -G desktop-2jj3187` resolves to `jeffr` / `192.168.0.217` /
  HostKeyAlias `192.168.0.217` / IdentityFile
  `~/.ssh/id_ed25519_desktop_2jj3187_admin.1password.pub`.
- Phase 0 baseline applied 2026-05-15T03:26:52Z
  ([apply record](./desktop-2jj3187-terminal-admin-baseline-apply-2026-05-15.md));
  confirmed expected state (OpenSSH absent, RDP intact, BitLocker off,
  admin token elevated).
- v0.3.0 install attempted; halted at S1, no host mutation. Packet
  marked superseded, evidence preserved.

## Authority

- This directive applies on `DESKTOP-2JJ3187` only.
- DESKTOP-2JJ3187 lifecycle_phase is **2** today. Phase 3
  (`install-shell-lane`) is opened by the v0.4.0 install packet
  below — but only after the reconciliation apply record commits.
- Spec authority:
  [windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md)
  v0.5.0 — note especially §Packet Artifact Separation, §Encoding
  Contract, §Cross-Shell Data Normalization, §Structured Evidence,
  and §Packet-Defect Halt Rule (the new policy that mandates this
  sequence change).

## New Policy: Packet-Defect Halt Rule

Per spec v0.5.0 §Packet-Defect Halt Rule:

> A mutating administrative packet may not be locally repaired by the
> operating agent after a parser, encoding, quoting, serialization, or
> state-normalization failure. These are packet defects. The agent
> must preserve evidence, halt, and hand back for a new packet version.

This applies for the v0.4.0 install below. If anything halts the
script — fingerprint mismatch, `sshd -t` failure, capability state
returning anything other than `Installed` or `NotPresent`, identity
mismatch, encoding mismatch — **do not attempt local repair**. Halt,
preserve the evidence directory and any snapshot subfolder, and hand
back to system-config for a new packet version.

The presence of an "interactive patch and re-run" option in the
operating environment does not authorize that path.

## Reading list (read FIRST, before acting)

In this order:

1. [windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md)
   v0.5.0 — Authority, Invariants, Device Lifecycle, Stop Rules,
   and the new packet-defect / encoding / normalization sections.
2. [current-status.yaml](./current-status.yaml) — find
   `devices[].device == "desktop-2jj3187"`. The reconciliation packet
   should be in `prepared_packets[]` with `state: approval-required`;
   the v0.4.0 install should be `state:
   approval-required-blocked-on-reconciliation`.
3. [desktop-2jj3187-reconciliation-2026-05-15.md](./desktop-2jj3187-reconciliation-2026-05-15.md)
   — read-only reconciliation runbook. Names its executable as
   `scripts/device-admin/desktop-2jj3187-reconciliation-v0.1.0.ps1`
   (sha256 `4cd75bcb...8b43`).
4. [desktop-2jj3187-ssh-lane-install-v0.4.0-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-v0.4.0-2026-05-15.md)
   — Phase 3 install runbook (read only after reconciliation lands).
   Names its executable as
   `scripts/device-admin/desktop-2jj3187-ssh-lane-install-v0.4.0.ps1`
   (sha256 `8bc1b29b...4e0c`).
5. [desktop-2jj3187-ssh-lane-install-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-2026-05-15.md)
   (v0.3.0 superseded) — read only for the postmortem record. Do
   NOT execute. Includes a SUPERSEDED notice at the top explaining
   the two packet defects.

## Step 1 — Reconciliation (read-only)

Goal: confirm the host has not drifted from the Phase 0 baseline and
that no v0.3.0 mutation occurred, before any v0.4.0 mutation runs.

1. RDP into DESKTOP-2JJ3187.
2. Open **elevated Windows PowerShell 5.1**, not pwsh 7. Confirm
   `$PSVersionTable.PSVersion` is `5.1.x`.
3. **Verify script sha256**:

   ```powershell
   $expected = '4cd75bcb8f31857d53a02a2de29fa94f73700c882ebb6b739154f26261dc8b43'
   $path     = '<full-path-to>\desktop-2jj3187-reconciliation-v0.1.0.ps1'
   $actual   = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLower()
   if ($actual -ne $expected) { throw "sha256 mismatch: $actual vs $expected" }
   ```

   If sha256 does not match, halt and hand back.

4. **Run the script** via `powershell.exe -File`:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File $path
   ```

5. The script writes
   `C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-reconciliation-<timestamp>\08-summary.json`.
   **Return the contents of `08-summary.json` verbatim** to
   system-config as the hand-back.

**Hand-back checkpoint.** Do not proceed to Step 2 until system-config
has committed
`docs/device-admin/desktop-2jj3187-reconciliation-apply-2026-05-15.md`
and confirmed the summary fields match the expected values listed in
the reconciliation packet (`openssh_capability_state: NotPresent`,
no SSH files, RDP intact, no v0.3.0 mutation evidence).

## Step 2 — v0.4.0 SSH Lane Install (live change)

**Only after system-config commits the reconciliation apply record.**

1. Still in elevated Windows PowerShell 5.1. Confirm
   `$PSVersionTable.PSVersion.Major -eq 5`.
2. **Verify script sha256**:

   ```powershell
   $expected = '8bc1b29bb0391ca55c2262a0847c546e0252347c93e784e1c9358085bc474e0c'
   $path     = '<full-path-to>\desktop-2jj3187-ssh-lane-install-v0.4.0.ps1'
   $actual   = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLower()
   if ($actual -ne $expected) { throw "sha256 mismatch: $actual vs $expected" }
   ```

3. **Run the script**:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File $path
   ```

4. Steps S0 → S8 run automatically with idempotent gates and
   read-back. Snapshot backups of `sshd_config`, the drop-in, and
   `administrators_authorized_keys` land in
   `<evidence-dir>\snapshot\` before any edit. Evidence lands in
   `C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-install-<timestamp>\`.

5. On a clean finish, **return `08-summary.json` verbatim** to
   system-config.

## Step 3 — MacBook real-auth probe

From the **operator MacBook** terminal:

```bash
ssh desktop-2jj3187 'cmd /c "hostname && whoami"'
```

Expected:

```text
DESKTOP-2JJ3187
desktop-2jj3187\jeffr
```

If `Permission denied (publickey)`: verify the on-host
`administrators_authorized_keys` fingerprint matches
`SHA256:0oDYmXRFrGuT4yyd0NLAAVyk0l/Aygu+iV88W2eq+/s` and the file ACL
is `Administrators + SYSTEM` only.

If TCP timeout: verify `Jefahnierocks SSH LAN TCP 22` is Enabled,
Private, RemoteAddress `192.168.0.0/24`; `Get-Service sshd` Running.

## Hard Stops

Stop and hand back to system-config rather than improvising if any of:

- Identity proof returns a different hostname or admin username.
- `$PSVersionTable.PSVersion.Major` is not `5` (you are in pwsh 7).
  Close the window and open Windows PowerShell instead.
- Script sha256 does not match the value declared in the corresponding
  packet.
- The v0.3.0 evidence directory or the v0.3.0 install script has been
  deleted, renamed, or modified — the postmortem trail must be
  preserved.
- The script's own logic throws: any of the documented halt classes
  (capability enum mismatch, sshd -t failure, fingerprint mismatch,
  effective-config readback missing a directive).
- A command would touch any out-of-scope surface (BitLocker,
  Defender exclusions, Codex sandbox accounts, network profile,
  DNS/DHCP/OPNsense, Cloudflare, WARP, 1Password, RDP rules, WinRM,
  Secure Boot).

When a halt occurs, **preserve everything in place**. Do not
re-encode, re-save, edit, or otherwise modify the script. Do not
delete or rotate the evidence directory. Surface the failure class
in the hand-back; system-config issues a new packet version with the
fix.

## Out of Scope

- BitLocker / Secure Boot decisions (separate future packets).
- Defender exclusions audit.
- Cloudflare WARP enrollment (blocked on cloudflare-dns Windows
  multi-user rebaseline).
- Cloudflared service cleanup.
- ssh-hardening tightening (separate post-install packet).
- Known-hosts reconciliation (separate post-install packet).

## Return Format

Step 1: return the body of
`<evidence-dir>\08-summary.json` verbatim. The JSON is the
canonical hand-back; no prose summary required.

Step 2: same, the body of the install run's
`<evidence-dir>\08-summary.json`.

Place private raw evidence outside the repo if you copy it to the
MacBook for analysis (operator-controlled path like
`~/Library/Logs/device-admin/2026-05-15/`); the repo's `.gitignore`
already excludes any `docs/device-admin/<device>-*-yyyymmddThhmmssZ/`
directory.

## Cross-References

- [windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md) v0.5.0
- [current-status.yaml](./current-status.yaml)
- [desktop-2jj3187-reconciliation-2026-05-15.md](./desktop-2jj3187-reconciliation-2026-05-15.md)
- [desktop-2jj3187-ssh-lane-install-v0.4.0-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-v0.4.0-2026-05-15.md)
- [desktop-2jj3187-ssh-lane-install-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-2026-05-15.md) (v0.3.0 SUPERSEDED — preserved for postmortem)
- [desktop-2jj3187-terminal-admin-baseline-apply-2026-05-15.md](./desktop-2jj3187-terminal-admin-baseline-apply-2026-05-15.md)
- [macbook-ssh-conf-d-desktop-2jj3187-apply-2026-05-15.md](./macbook-ssh-conf-d-desktop-2jj3187-apply-2026-05-15.md)
- [handback-format.md](./handback-format.md)

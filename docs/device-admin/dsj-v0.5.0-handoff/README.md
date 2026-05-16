---
title: DESKTOP-2JJ3187 v0.5.0 SSH Lane Install - Handoff Bundle (SUPERSEDED)
category: operations
component: device_admin
status: superseded
version: 0.1.0
last_updated: 2026-05-16
tags: [device-admin, desktop-2jj3187, windows, openssh, handoff, bundle, superseded]
priority: high
---

# DESKTOP-2JJ3187 v0.5.0 SSH Lane Install - Handoff Bundle (SUPERSEDED)

> **SUPERSEDED 2026-05-16** by
> `../dsj-service-mode-restart-handoff/`.
>
> The v0.5.0 install packet ran successfully (all 23 acceptance-
> gate fields true; apply record committed in
> `docs/device-admin/desktop-2jj3187-ssh-lane-install-v0.5.0-apply-2026-05-16.md`).
> The MacBook real-auth probe then failed at SSH KEX. Diagnostics
> traced the cause to `Add-WindowsCapability` not creating the
> `sshd` virtual user / NTFS ACL that privsep requires on
> Win 11 24H2. Full RCA:
> `docs/device-admin/desktop-2jj3187-ssh-service-mode-rca-2026-05-16.md`.
>
> **Do not use this bundle for new work.** Use
> `../dsj-service-mode-restart-handoff/` instead — it contains
> the RCA-anchored fix block + the v0.2.0 diagnostic fallback.
> This bundle is preserved as historical reference for the v0.5.0
> install attempt only.

This folder is a **transient snapshot** of the documents and the
executable script that the Windows-side agent or operator on
`DESKTOP-2JJ3187` needs to apply the v0.5.0 SSH lane install.

Canonical copies live at their normal repo paths. This bundle is a
flat folder so the entire set can be copied or zipped and dropped
into the RDP session in one step. Relative `[link](./other.md)`
references inside these documents resolve to the sibling files in
this same folder.

## Transfer

From the MacBook, this folder is at:

```text
/Users/verlyn13/Organizations/jefahnierocks/system-config/docs/device-admin/dsj-v0.5.0-handoff/
```

Copy the entire folder to the Windows host. A reasonable target on
DESKTOP-2JJ3187 (writable by `jeffr`, outside the evidence dir):

```text
C:\Users\jeffr\Documents\device-admin\dsj-v0.5.0-handoff\
```

(The script invocation in §Execute below uses
`<full-path-to>\desktop-2jj3187-ssh-lane-install-v0.5.0.ps1`, which
in that target path is
`C:\Users\jeffr\Documents\device-admin\dsj-v0.5.0-handoff\desktop-2jj3187-ssh-lane-install-v0.5.0.ps1`.)

## Reading order (entry point first)

| # | File | Why |
|---|---|---|
| 1 | `desktop-2jj3187-windows-side-directive-2026-05-15.md` | **Entry point.** The agent directive — what to do, in what sequence, with what halt rules. Read first. |
| 2 | `windows-terminal-admin-spec.md` | The fleet spec. Pay attention to §Windows OpenSSH Defaults (new in this iteration), §Encoding Contract, §Cross-Shell Data Normalization, §Packet-Defect Halt Rule. |
| 3 | `desktop-2jj3187-ssh-lane-install-v0.4.0-incident-2026-05-15.md` | Postmortem for the v0.4.0 attempt. Explains why v0.5.0 exists and what host state v0.4.0 left behind (capability installed, sshd Running+Automatic, Match block in place, drop-in written, admin key in `administrators_authorized_keys`, firewall rule active). |
| 4 | `desktop-2jj3187-ssh-lane-install-v0.5.0-2026-05-15.md` | The active install runbook. New S3b step injects `Include sshd_config.d/*.conf` at the top of `sshd_config`. Idempotent against the v0.4.0 partial-apply host state. |
| 5 | `desktop-2jj3187-ssh-lane-install-v0.5.0.ps1` | The executable. Don't transcribe — run this exact file. sha256 `a4df7f944ba87bce439af03698ba715c6a4e871e7887ebfa49aa39ad1240928c`. |
| 6 | `desktop-2jj3187-reconciliation-apply-2026-05-15.md` | Apply record for the pre-v0.4.0 reconciliation (2026-05-15T23:36:40Z). For context; do not re-run reconciliation. |
| 7 | `desktop-2jj3187-terminal-admin-baseline-apply-2026-05-15.md` | Phase 0 baseline apply record (2026-05-15T03:26:52Z). For context. |
| 8 | `desktop-2jj3187-reconciliation-2026-05-15.md` | Reconciliation packet (already applied; here for runbook reference). |
| 9 | `desktop-2jj3187-ssh-lane-install-v0.4.0-2026-05-15.md` | v0.4.0 packet, **SUPERSEDED**. Do not execute. Preserved for postmortem. |
| 10 | `desktop-2jj3187-ssh-lane-install-2026-05-15.md` | v0.3.0 packet, **SUPERSEDED**. Do not execute. Preserved for postmortem. |
| 11 | `handback-format.md` | Hand-back JSON schema reference. |

## Verify integrity before running

The executable's sha256 must match the value declared in the v0.5.0
packet. From elevated Windows PowerShell 5.1:

```powershell
$expected = 'a4df7f944ba87bce439af03698ba715c6a4e871e7887ebfa49aa39ad1240928c'
$path     = 'C:\Users\jeffr\Documents\device-admin\dsj-v0.5.0-handoff\desktop-2jj3187-ssh-lane-install-v0.5.0.ps1'
$actual   = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLower()
if ($actual -ne $expected) { throw "sha256 mismatch: $actual vs $expected" }
```

Halt and hand back if the hash does not match. Do not run a script
whose hash does not match the packet reference.

## Execute

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
  'C:\Users\jeffr\Documents\device-admin\dsj-v0.5.0-handoff\desktop-2jj3187-ssh-lane-install-v0.5.0.ps1'
```

Confirm `$PSVersionTable.PSVersion.Major -eq 5` first — do **not**
run from pwsh 7. The DISM `Get-WindowsCapability` call inside S1
needs WinPS 5.1.

Evidence lands at
`C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-install-<UTC-timestamp>\`
(a new directory alongside the preserved v0.4.0 evidence dir).

## Return path

Return `<evidence-dir>\08-summary.json` verbatim to the system-
config operator (the MacBook side). That JSON is the canonical
hand-back. The seven `effective_config` flags must all be `true`;
any `false` is a packet defect → halt per spec §Packet-Defect
Halt Rule.

## Preservation requirements (Hard Stops)

- **v0.4.0 on-host evidence dir** must remain untouched. Do not
  delete, rename, or rotate
  `C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-install-<v0.4.0-timestamp>\`.
- **v0.3.0 and v0.4.0 packet markdown files in this bundle** must
  remain unmodified. Both carry SUPERSEDED notices. Do not run
  them.
- **The v0.5.0 `.ps1` file** must remain unmodified. If you find
  yourself wanting to edit it on the host to fix something — halt
  and hand back instead. That is the packet-defect halt rule.

## Bundle source

This bundle was assembled from
`docs/device-admin/` and `scripts/device-admin/` in the
`jefahnierocks/system-config` repo, MacBook side. The repo HEAD
when this bundle was assembled is recorded in the commit that
adds this folder. To refresh the bundle against the latest repo
state, the operator can rerun the bundle-assembly step.

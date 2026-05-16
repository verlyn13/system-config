---
title: DESKTOP-2JJ3187 Windows-Side Directive - 2026-05-15
category: operations
component: device_admin
status: active
version: 0.4.0
last_updated: 2026-05-16
tags: [device-admin, desktop-2jj3187, windows, directive, agent-handoff, phase-3]
priority: high
---

# DESKTOP-2JJ3187 Windows-Side Directive - 2026-05-15

**v0.4.0 update (2026-05-16)**: SSH lane **functionally proven**.
The operator manually ran the diagnostic-equivalent (Stop-Service
sshd; `C:\Windows\System32\OpenSSH\sshd.exe -d -d -d` in
foreground) and the MacBook real-auth probe completed end-to-end
against the foreground sshd: KEX (curve25519-sha256 +
ssh-ed25519), auth (`Accepted publickey for jeffr` with matching
fingerprint), command exec (`hostname` returned `DESKTOP-2JJ3187`),
clean disconnect. TOFU prompt was answered; ED25519 host-key
`SHA256:OFNLsVw4RJlChJef1Db+eelKZnqJfPsVYLkNPVED6V8` persisted to
MacBook `known_hosts`.

Remaining issue is **service-mode-specific**: when sshd runs under
the Windows Service Control Manager (rather than under jeffr's
interactive admin token) the per-connection privsep child path
fails silently. The foreground log shows Microsoft uses sshd's
own `-y` and `-z` flags (not `sshd-session.exe`) for the
network/user children; the parent log line
`debug1: Not running as SYSTEM: skipping loading user profile`
hints that the SYSTEM-context spawn path is where the failure
sits.

Next step: **`Start-Service sshd`** on the host (it's currently
stopped after the foreground test), then re-probe from MacBook.
If the service-mode sshd now passes (a clean Stop/Start may be
enough), Phase 3 is done. If KEX reset returns, run Microsoft's
`install-sshd.ps1` to reset the service to known-good account +
permissions. v0.2.0 diagnostic packet remains drafted as a
fallback for deeper investigation if `install-sshd.ps1` doesn't
fix it.

This is the directive for an **agent or operator running on
DESKTOP-2JJ3187 in an elevated Windows PowerShell 5.1 session**. The
MacBook-side prep (1Password item, chezmoi conf.d) is complete; the
Windows-side work is what remains.

**v0.3.0 update (2026-05-15)**: this directive supersedes the v0.2.0
sequence that referenced the v0.4.0 install packet. The v0.4.0
install attempt halted at §S7 because Microsoft's default
`sshd_config` does not contain an `Include` directive — the drop-in
at `C:\ProgramData\ssh\sshd_config.d\20-jefahnierocks-admin.conf`
was silently ignored. **S1-S6 mutations did occur** (capability
installed, service running, Match block in place, drop-in written,
admin key in `administrators_authorized_keys`, firewall rule);
none are out of scope or harmful. Spec gets a new
[§Windows OpenSSH Defaults](./windows-terminal-admin-spec.md)
section. Full root-cause in
[desktop-2jj3187-ssh-lane-install-v0.4.0-incident-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-v0.4.0-incident-2026-05-15.md).
New sequence: **reconciliation (already applied) → v0.5.0 install**.

**v0.2.0 history (2026-05-15)**: this directive previously
superseded the v0.1.0 sequence that referenced the v0.3.0 install
packet. The v0.3.0 install attempt halted in §S1 due to packet
defects (UTF-8-without-BOM encoding under WinPS 5.1, then
enum-as-integer JSON serialization). **No host mutation occurred
in v0.3.0.** Spec was bumped to v0.5.0 with new rules.

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
- Reconciliation applied 2026-05-15T23:36:40Z
  ([apply record](./desktop-2jj3187-reconciliation-apply-2026-05-15.md),
  commit `4fef412`). All 20 expected fields matched; no v0.3.0
  mutation, no drift from Phase 0 baseline.
- v0.4.0 install attempted; halted at S7. **Partial apply through
  S6** (OpenSSH capability installed, sshd Running+Automatic, Match
  block in place, drop-in written at
  `C:\ProgramData\ssh\sshd_config.d\20-jefahnierocks-admin.conf`,
  admin key in `administrators_authorized_keys`,
  `Jefahnierocks SSH LAN TCP 22` rule active). v0.4.0 packet marked
  SUPERSEDED; on-host evidence dir preserved untouched. Root cause:
  Microsoft's default `sshd_config` has no `Include` directive;
  drop-in was silently ignored by `sshd`.
- v0.3.0 install attempted; halted at S1, no host mutation. Packet
  marked superseded, evidence preserved.

## Authority

- This directive applies on `DESKTOP-2JJ3187` only.
- DESKTOP-2JJ3187 lifecycle_phase is **2** today. Phase 3
  (`install-shell-lane`) is opened by the v0.5.0 install packet
  below — the reconciliation apply record is already committed.
- Spec authority:
  [windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md)
  v0.5.0+ — note especially §Packet Artifact Separation,
  §Encoding Contract, §Cross-Shell Data Normalization,
  §Structured Evidence, §Windows OpenSSH Defaults (new; the
  Microsoft `sshd_config` does not include drop-ins by default —
  the lesson behind this v0.3.0 directive update), and §Packet-
  Defect Halt Rule.

## New Policy: Packet-Defect Halt Rule

Per spec v0.5.0 §Packet-Defect Halt Rule:

> A mutating administrative packet may not be locally repaired by the
> operating agent after a parser, encoding, quoting, serialization, or
> state-normalization failure. These are packet defects. The agent
> must preserve evidence, halt, and hand back for a new packet version.

This applies for the v0.5.0 install below. If anything halts the
script — fingerprint mismatch, `sshd -t` failure, capability state
returning anything other than `Installed` or `NotPresent`, identity
mismatch, encoding mismatch, S3b read-back failure, S7 effective-
config readback missing a directive — **do not attempt local
repair**. Halt, preserve the evidence directory and any snapshot
subfolder, and hand back to system-config for a new packet version.

The v0.4.0 attempt demonstrated this rule working as intended:
the operating agent halted at S7 without attempting to inject the
`Include` directive locally. That made the postmortem clean and
the v0.5.0 fix targeted. Continue this discipline.

The presence of an "interactive patch and re-run" option in the
operating environment does not authorize that path.

## Reading list (read FIRST, before acting)

In this order:

1. [windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md)
   v0.5.0+ — Authority, Invariants, Device Lifecycle, Stop Rules,
   the new §Windows OpenSSH Defaults section, and the existing
   packet-defect / encoding / normalization sections.
2. [current-status.yaml](./current-status.yaml) — find
   `devices[].device == "desktop-2jj3187"`. The reconciliation packet
   is in `applied_packets[]` (committed 2026-05-15T23:36:40Z); the
   v0.5.0 install is in `prepared_packets[]` with `state:
   approval-required`.
3. [desktop-2jj3187-ssh-lane-install-v0.4.0-incident-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-v0.4.0-incident-2026-05-15.md)
   — postmortem for the v0.4.0 halt at S7. Names the host state
   left behind by v0.4.0 (capability installed, service running,
   Match block in place, drop-in written, admin key + firewall
   rule), and the assumption that broke (no `Include` directive in
   Microsoft's default `sshd_config`).
4. [desktop-2jj3187-ssh-lane-install-v0.5.0-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-v0.5.0-2026-05-15.md)
   — Phase 3 install runbook. Names its executable as
   `scripts/device-admin/desktop-2jj3187-ssh-lane-install-v0.5.0.ps1`
   (sha256 `a4df7f944ba87bce439af03698ba715c6a4e871e7887ebfa49aa39ad1240928c`).
5. [desktop-2jj3187-ssh-lane-install-v0.4.0-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-v0.4.0-2026-05-15.md)
   (v0.4.0 SUPERSEDED) — read only for postmortem context. Do
   NOT execute.
6. [desktop-2jj3187-ssh-lane-install-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-2026-05-15.md)
   (v0.3.0 SUPERSEDED) — read only for postmortem context. Do
   NOT execute.

## Step 1 — Reconciliation (already applied; reference only)

The read-only reconciliation packet
([desktop-2jj3187-reconciliation-2026-05-15.md](./desktop-2jj3187-reconciliation-2026-05-15.md))
was applied 2026-05-15T23:36:40Z. Apply record:
[desktop-2jj3187-reconciliation-apply-2026-05-15.md](./desktop-2jj3187-reconciliation-apply-2026-05-15.md)
(commit `4fef412`). All 20 expected hand-back fields matched.
Nothing to do for this step.

## Step 2 — v0.5.0 SSH Lane Install (live change)

1. RDP into DESKTOP-2JJ3187 as `DESKTOP-2JJ3187\jeffr`.
2. Open **elevated Windows PowerShell 5.1**, not pwsh 7. Confirm
   `$PSVersionTable.PSVersion.Major -eq 5`.
3. **Verify script sha256**:

   ```powershell
   $expected = 'a4df7f944ba87bce439af03698ba715c6a4e871e7887ebfa49aa39ad1240928c'
   $path     = '<full-path-to>\desktop-2jj3187-ssh-lane-install-v0.5.0.ps1'
   $actual   = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLower()
   if ($actual -ne $expected) { throw "sha256 mismatch: $actual vs $expected" }
   ```

4. **Confirm the v0.4.0 evidence directory is intact**:

   ```powershell
   Get-ChildItem 'C:\Users\Public\Documents\jefahnierocks-device-admin' |
     Select-Object Name, LastWriteTime
   ```

   Do not delete, rename, or rotate the
   `desktop-2jj3187-ssh-install-<v0.4.0-timestamp>` directory.
   v0.5.0 writes a new timestamped dir alongside it.

5. **Run the script**:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File $path
   ```

6. Steps S0 → S8 run automatically with idempotent gates and
   read-back. v0.4.0's S1-S6 mutations are still in place; v0.5.0
   reads each as already-done and only S3b (Include injection) +
   S7 (restart + readback) do new work. Snapshot backups land in
   `<evidence-dir>\snapshot\` before any edit. Evidence lands in
   `C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-install-<v0.5.0-timestamp>\`.

7. On a clean finish, **return `08-summary.json` verbatim** to
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
- The v0.3.0 or v0.4.0 evidence directory or its install script has
  been deleted, renamed, or modified — the postmortem trail must
  be preserved.
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

- [windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md) v0.5.0+ — includes §Windows OpenSSH Defaults
- [current-status.yaml](./current-status.yaml)
- [desktop-2jj3187-ssh-lane-install-v0.5.0-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-v0.5.0-2026-05-15.md) — active install packet
- [desktop-2jj3187-ssh-lane-install-v0.4.0-incident-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-v0.4.0-incident-2026-05-15.md) — v0.4.0 postmortem
- [desktop-2jj3187-ssh-lane-install-v0.4.0-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-v0.4.0-2026-05-15.md) (v0.4.0 SUPERSEDED — preserved for postmortem)
- [desktop-2jj3187-ssh-lane-install-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-2026-05-15.md) (v0.3.0 SUPERSEDED — preserved for postmortem)
- [desktop-2jj3187-reconciliation-2026-05-15.md](./desktop-2jj3187-reconciliation-2026-05-15.md)
- [desktop-2jj3187-reconciliation-apply-2026-05-15.md](./desktop-2jj3187-reconciliation-apply-2026-05-15.md)
- [desktop-2jj3187-terminal-admin-baseline-apply-2026-05-15.md](./desktop-2jj3187-terminal-admin-baseline-apply-2026-05-15.md)
- [macbook-ssh-conf-d-desktop-2jj3187-apply-2026-05-15.md](./macbook-ssh-conf-d-desktop-2jj3187-apply-2026-05-15.md)
- [handback-format.md](./handback-format.md)
- Upstream Microsoft sshd_config default: https://raw.githubusercontent.com/PowerShell/openssh-portable/latestw_all/contrib/win32/openssh/sshd_config

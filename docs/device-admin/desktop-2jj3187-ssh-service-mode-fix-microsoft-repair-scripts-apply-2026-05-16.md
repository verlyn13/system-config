---
title: DESKTOP-2JJ3187 Service-Mode Fix-Block + v0.2.0 Diagnostic Apply - 2026-05-16
category: operations
component: device_admin
status: applied-bug-persists
version: 0.1.0
last_updated: 2026-05-16
tags: [device-admin, desktop-2jj3187, windows, openssh, service-mode, applied, hypothesis-discipline, bug-persists]
priority: high
---

# DESKTOP-2JJ3187 Service-Mode Fix-Block + v0.2.0 Diagnostic Apply - 2026-05-16

Apply record for the operator's RCA-anchored fix-block attempt
(Step 1), the operator-authorized continuation (Step 1b), and
the v0.2.0 diagnostic packet. All three ran; **service-mode SSH
KEX reset persists** after the fix-block completes. This apply
record records facts and frames candidate hypotheses; **no root
cause is asserted** until a controlled test confirms one.

## Hypothesis Discipline Note (read first)

The on-host hand-back labels its CBS-package-servicing finding
as "the actual root cause" / "decisive new finding". The prior
RCA doc this commit chain produced
([desktop-2jj3187-ssh-service-mode-rca-2026-05-16.md](./desktop-2jj3187-ssh-service-mode-rca-2026-05-16.md))
labeled the missing-`sshd`-virtual-user theory as "## Root
Cause". Both framings were over-confident: the RCA's
"missing privsep user" claim was refuted by Step 1b (the user
was created, ACLs applied, bug persists); the on-host agent's
"CBS package servicing failure is the actual root cause" is
a high-quality lead but has not been tested by a controlled
intervention. **Both are hypotheses, not confirmed causes.**

This apply record uses the strict discipline going forward:
findings are evidence; explanations are candidate hypotheses
with explicit confidence; root cause is only claimed after a
controlled test that varies only the proposed cause and
produces the predicted outcome.

The new spec section
[`§Hypothesis vs Confirmed Root Cause Discipline`](./windows-terminal-admin-spec.md)
codifies this rule.

## Apply Context

```text
device:                DESKTOP-2JJ3187
applied_at:            2026-05-16T17:03Z (Step 1 start) -> 2026-05-16T17:17Z (v0.2.0 finish)
applied_by:            DESKTOP-2JJ3187\jeffr (elevated Windows PowerShell 5.1)
session_class:        scoped-live-change
final_state:           sshd service Running+Automatic, LocalSystem account, listening on
                       0.0.0.0:22 and [::]:22; sshd virtual local user CREATED by
                       install-sshd.ps1; NTFS ACLs on C:\ProgramData\ssh\ APPLIED by
                       FixHostFilePermissions.ps1; service-mode SSH still RSTs at
                       SSH_MSG_KEXINIT (LAN + loopback both reproduce).
on_host_evidence_dirs: (all preserved untouched per spec §Packet-Defect Halt Rule)
  - desktop-2jj3187-step1-fix-block-20260516T170319Z\
  - desktop-2jj3187-step1b-continuation-20260516T171242Z\
  - desktop-2jj3187-ssh-kex-diagnostic-v020-20260516T171717Z\
  - desktop-2jj3187-ssh-install-20260516T020851Z\ (v0.5.0, preserved)
  - desktop-2jj3187-ssh-kex-diagnostic-20260516T024628Z\ (v0.1.0 diagnostic, preserved)
  - desktop-2jj3187-baseline-20260515T032652Z\ (Phase 0, preserved)
```

## Sequence executed on host

### Step 1: RCA-anchored fix-block

The operator on DESKTOP-2JJ3187 ran the fix block from
[dsj-service-mode-restart-handoff/README.md](./dsj-service-mode-restart-handoff/README.md)
§Step 1 verbatim via `step1-fix-block-runner-2026-05-16.ps1`.

**Halted at line 52 of `install-sshd.ps1`** because the README's
runtime-fetch list was missing the file `Openssh-events.man`
(capital O). The README listed only:

```
install-sshd.ps1
FixHostFilePermissions.ps1
OpenSSHUtils.psm1
OpenSSHUtils.psd1
```

and used `Invoke-WebRequest` against the lowercase URL
`.../openssh-events.man` — GitHub raw returned 404. The
upstream file is named `Openssh-events.man` (capital initial).
`install-sshd.ps1` requires the manifest file to register the
ETW event provider; without it, manifest parsing fails at line
52 and the script halts.

**Host-state mutation that DID occur before the halt:**
`install-sshd.ps1` lines 33 and 39 ran first, which **delete
the `sshd` and `ssh-agent` service entries** as part of the
install's clean-slate setup. After the halt, the host was left
with:

- Service entries `sshd` and `ssh-agent` DELETED (Step 1 did
  not get to re-create them).
- All other Step 1 fix-block actions (Stop-Service, virtual-
  user removal, sshd_config debug-line strip, four `.ps1` /
  `.psm1` / `.psd1` files placed in
  `C:\Windows\System32\OpenSSH\`) successfully applied.

Step 1 evidence:
`desktop-2jj3187-step1-fix-block-20260516T170319Z\08-summary.json`.

This is a **packet defect, not a host defect**: the README's
fetch list was incomplete (case mismatch in one filename;
missing the manifest file entirely). The on-host agent
correctly halted per §Packet-Defect Halt Rule.

### Step 1b: operator-authorized continuation

Operator authorized in-session continuation. Spec basis:
§Session Class definitions allow scoped-live-change with
explicit operator approval in-session. The continuation is a
new operation (recovery from a halt), not a local repair of
the failed packet, so it is permitted.

`step1b-continuation-runner-2026-05-16.ps1`:

1. Fetched `Openssh-events.man` from upstream (capital O URL).
   sha256:
   `eb10aca47da16f9aaf71304deb38eef84647a91f5202abd94a5500d4a8dafa0d`.
2. Placed in `C:\Windows\System32\OpenSSH\openssh-events.man`
   (lowercase name on-disk matches what install-sshd.ps1
   expects).
3. Re-ran `install-sshd.ps1` to completion (no halt this time).
4. Ran `FixHostFilePermissions.ps1 -Confirm:$false`.
5. Ran `Set-Service sshd -StartupType Automatic` and
   `Start-Service sshd`.

Post-Step-1b host state:
- `sshd` and `ssh-agent` service entries RE-CREATED.
- sshd service Running, Automatic, LocalSystem account.
- sshd listening on `0.0.0.0:22` and `[::]:22`.
- `sshd -t` exits 0 (config syntax valid).
- `sshd` virtual local user EXISTS (verified per
  hand-back summary).
- NTFS ACLs on `C:\ProgramData\ssh\` APPLIED per
  FixHostFilePermissions.ps1.

Step 1b evidence:
`desktop-2jj3187-step1b-continuation-20260516T171242Z\08-summary.json`.

**This Step 1b outcome refutes the original RCA hypothesis**
([desktop-2jj3187-ssh-service-mode-rca-2026-05-16.md](./desktop-2jj3187-ssh-service-mode-rca-2026-05-16.md)
§Root Cause): the missing-`sshd`-virtual-user theory predicted
that running `install-sshd.ps1 + FixHostFilePermissions.ps1`
would resolve the KEX reset. It did not. The RCA's claim was a
hypothesis, not a confirmed cause; it has now been refuted.

### Step 1c: loopback probe immediately after Step 1b

`ssh -vv -o BatchMode=yes 127.0.0.1` from the host:

```
debug1: Local version string SSH-2.0-OpenSSH_for_Windows_9.5
debug1: SSH2_MSG_KEXINIT sent
Connection reset by 127.0.0.1 port 22
```

Service-mode KEX reset PERSISTS. Same symptom as v0.5.0 and the
v0.1.0 diagnostic loopback probe.

### Step 2: v0.2.0 diagnostic packet

`desktop-2jj3187-ssh-kex-reset-diagnostic-v0.2.0.ps1` ran under
elevated WinPS 5.1. sha256 verified
(`cbe8294f0da5f0ff9d63f677069a8c51ac06ba599892996f7621ab5f56788eb1`).
No halts. D9 foreground sshd -ddd + loopback probe completed;
sshd service restored at D9 end.

Evidence:
`desktop-2jj3187-ssh-kex-diagnostic-v020-20260516T171717Z\10-summary.json`
plus 18 supporting files (binary inventory, Defender state,
WER dump search, Application log, ACLs, foreground sshd debug
log, loopback probe stderr).

## Hand-Back Summary (verbatim, from on-host)

The on-host agent wrote a `hand-back-summary.md` into the v0.2.0
evidence directory. The full text is preserved at
`C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-kex-diagnostic-v020-20260516T171717Z\hand-back-summary.md`.

The agent's labelling has been reframed in this apply record
per the Hypothesis Discipline Note above. The agent's evidence
collection and procedural discipline were sound; the
"root cause" / "decisive finding" language is what required
correction.

## Evidence (priority files, all on-host)

In
`C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-kex-diagnostic-v020-20260516T171717Z\`:

| File | Role |
|---|---|
| `10-summary.json` | Top-level diagnostic summary |
| `09-foreground-sshd.log` | Full sshd `-ddd` output (12090 bytes). Network child spawn ok; KEX completes; userauth reached; client closes (no IdentityFile in probe). Includes `get_passwd: lookup_sid() failed: 1332.` at startup. |
| `09-loopback-probe.txt` | ssh -vvv probe stdout+stderr |
| `09-result.json` | D9 state machine record |
| `04b-application-events.json` | **Application log entries flagged by on-host agent** — contains three `CbsPackageServicingFailure2` events from 2026-05-16T00:02:40Z-00:02:52Z for OpenSSH-Server-Package, HRESULT 0x80070002, package state Absent/Superseded |
| `02b-openssh-binaries.json` | OpenSSH binary inventory + Authenticode signatures. Shows version split: sshd.exe + sftp-server.exe + ssh-shellhost.exe + sshd_config_default at 9.5.0.1 / 2024-04-01; all client binaries (ssh.exe, ssh-agent.exe, etc.) at 9.5.5.1 / 2026-05-12 |
| `05b-sshd-logs-dir-acl.json` | `C:\ProgramData\ssh\logs` ACL — clean (Administrators owner, SYSTEM + Administrators FullControl). Win32-OpenSSH #2282 ruled out. |
| `06b-defender-state.json` | Get-MpComputerStatus output |
| `06b-defender-prefs.json` | Get-MpPreference output (exclusions, ASR rules, etc.) |
| `06b-defender-threats.json` | Get-MpThreatDetection output |
| `06c-wer-dumps.json` | WER ReportArchive / ReportQueue / Temp — all empty. Per-connection sshd child is not crashing in a way that generates a WER dump (or WER LocalDumps registry config is needed to capture). |

Plus Step 1 / Step 1b evidence in sibling directories:
- `desktop-2jj3187-step1-fix-block-20260516T170319Z\`
- `desktop-2jj3187-step1b-continuation-20260516T171242Z\`

## Candidate hypotheses (none confirmed)

Listed by current confidence after Step 1b refuted the original
RCA's "missing privsep user" claim.

### H1: Half-applied OpenSSH-Server-Package CBS servicing (HIGH-VALUE LEAD; NOT CONFIRMED)

**Evidence:**
- Three `CbsPackageServicingFailure2` Application-log events
  from 2026-05-16T00:02:40Z-00:02:52Z (yesterday during the
  v0.4.0/v0.5.0 attempt window):
  - Package: `OpenSSH-Server-Package` v10.0.26100.1
  - HRESULT: `0x80070002` (`ERROR_FILE_NOT_FOUND`)
  - Phase: `Execute`
  - State: `Absent` / Dispose: `Superseded`
  - Provider: DISM Package Manager Provider
- Binary version split: server-side binaries (sshd.exe et al.)
  at 9.5.0.1 / 2024-04-01; client-side binaries (ssh.exe et
  al.) at 9.5.5.1 / 2026-05-12. Consistent with the
  OpenSSH.Client capability install completing while
  OpenSSH.Server capability install failed at CBS Execute.
- `install-sshd.ps1` / `FixHostFilePermissions.ps1` /
  `OpenSSHUtils.psm1` / `OpenSSHUtils.psd1` /
  `Openssh-events.man` were absent from
  `C:\Windows\System32\OpenSSH\` until Step 1 / Step 1b
  fetched them. A complete server-capability install would
  have placed them.

**Why it's a HYPOTHESIS, not a confirmed cause:**
- The CBS events occurred yesterday; the KEX reset has been
  observed since at least v0.4.0 (2026-05-15). The temporal
  correlation is suggestive but does not prove that the CBS
  failure produced the specific service-mode child-spawn
  failure we see.
- The 9.5.0.1 vs 9.5.5.1 version split may or may not be
  abnormal; Microsoft does not guarantee server + client
  binaries are bumped in lockstep on every capability update.
  An additional clean-install comparison is needed.
- `install-sshd.ps1` ran cleanly in Step 1b and the failure
  still reproduces. That weakens the "missing payload state"
  framing; the runtime-fetched scripts may have produced the
  same end-state the failed CBS commit would have, in which
  case the CBS failure is a red herring.

**What would confirm:**
- `Remove-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0`
- Reboot or `dism /online /Cleanup-Image /StartComponentCleanup`
- `Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0`
- Verify: `Get-WindowsPackage -Online | Where PackageName -like
  '*OpenSSH-Server*'` shows `PackageState: Installed` and
  no new `CbsPackageServicingFailure*` Application events.
- Verify: `sshd.exe` version is 9.5.5.1 (matching client
  binaries).
- Test: real MacBook `ssh desktop-2jj3187 'hostname'` succeeds.
- If all three predictions hold, H1 is confirmed.
- If reset persists, H1 is refuted; move to H2 or look further.

### H2: SID / account-resolution failure in the service-mode child process (HIGH-VALUE LEAD; NOT CONFIRMED)

**Evidence:**
- `get_passwd: lookup_sid() failed: 1332.` (`ERROR_NONE_MAPPED`)
  appears in the foreground sshd `-ddd` log at startup. Per
  Microsoft `LookupAccountSidA` documentation, error 1332
  indicates the SID could not be resolved to an account name.
- In foreground mode (sshd running as `jeffr` interactive
  admin), the error is logged at startup but is non-fatal —
  KEX completes successfully.
- In service mode (sshd running as `LocalSystem`), the
  per-connection child path is different (sshd.exe `-y` is
  spawned for the network child rather than the foreground
  inline path), and the service-mode child appears to die
  silently before any log emission.
- Upstream Win32-OpenSSH issue #2403 documents
  `lookup_sid() failed: 1788` causing `sshd-session.exe`
  termination in a different version; the symptom is similar
  but the version + binary differs.

**Why it's a HYPOTHESIS, not a confirmed cause:**
- The exact SID failing the lookup is unknown — could be the
  privsep user's SID, an orphaned SID in a host-key or
  authorized_keys ACL, an LSA-internal token SID, or
  something else.
- The foreground vs service-mode behavior split is well-
  observed but the specific code path that diverges has not
  been captured (would require WER LocalDump or live process
  trace of the service-mode child during a connection attempt).
- H2 may be the SURFACE manifestation of H1 (the version-split
  9.5.0.1 server with newer expectations is more sensitive to
  LSA quirks). H2 and H1 are not mutually exclusive.

**What would confirm:**
- Configure WER LocalDumps for `sshd.exe` and
  `sshd-session.exe` paths.
- Trigger a loopback connection probe under service mode.
- Capture the resulting `.dmp` file.
- Analyze the dump for the failure point: which SID, which
  API call, which token state.
- If the dump names the specific SID + lookup site, H2 is
  confirmed at that level of specificity.

### H3: Inbox / FOD / GitHub binary version mismatch beyond just sshd.exe (LOW CONFIDENCE; NOT TESTED)

**Evidence:**
- Microsoft's troubleshooting guide for `Error 1053 and OpenSSH
  Server Service Doesn't Start` explicitly warns that mismatched
  OpenSSH Client, Server, and `libcrypto.dll` versions can
  prevent the service from starting, especially when GitHub
  packages are mixed with inbox/FOD components.
- The host has not been audited for `libcrypto.dll` location,
  version, or alternative copies in PATH or in the GitHub
  Win32-OpenSSH install directory.

**Why it's a HYPOTHESIS, not a confirmed cause:**
- The sshd service IS running in our case (it accepts TCP and
  emits banner). Error 1053 is about the service failing to
  start at all, which doesn't match our symptom exactly.
- But a partial DLL mismatch could allow the parent to start
  while the child spawn fails — distinct from full service
  failure.

**What would confirm:**
- Inventory `libcrypto.dll` across `C:\Windows\System32\OpenSSH\`,
  `C:\Windows\System32\`, and any `C:\Program Files\OpenSSH-Win64\`
  (GitHub install path).
- Compare versions / hashes to expected matching pairs.

### H4: Defender / EDR child-process interception (RULED OUT pending evidence)

**Evidence:**
- Defender `Get-MpComputerStatus` shows RealTimeProtection
  enabled but no recent `Microsoft-Windows-Windows
  Defender/Operational` block events for the OpenSSH paths.
- No Defender exclusion specifically for OpenSSH; no recent
  threats detected for the OpenSSH binary paths.
- v0.2.0 D6b evidence captured Defender state at run time;
  no anomaly that points at OpenSSH interception.

H4 is not currently a leading hypothesis. Listed for
completeness so the designer doesn't have to re-derive it.

## What does NOT close the loop

The fix-block (Step 1 + Step 1b) and the v0.2.0 diagnostic
together did substantial work, but did not produce a
controlled test of any hypothesis above. Step 1b's outcome
**refuted** the prior "missing privsep user" hypothesis, which
was useful negative information; it did not generate a
controlled test of any positive hypothesis.

Going forward, every diagnostic packet should specify in
advance:

1. The hypothesis(es) the packet is designed to test.
2. The intervention or measurement that will distinguish
   "hypothesis confirmed" from "hypothesis refuted" from
   "test inconclusive".
3. The pre-registered prediction: what evidence pattern
   would confirm, what would refute, what would be ambiguous.

This is enforced by the new
[§Hypothesis vs Confirmed Root Cause Discipline](./windows-terminal-admin-spec.md)
spec section.

## Workflow defects identified

These are process defects in the README + handback fix block,
to be remembered for future Windows packets. They do not
explain the KEX reset (that is the host-side bug being chased),
but they affect packet reliability:

### W1: README fetch list missed `Openssh-events.man` (case mismatch + omitted file)

The README's runtime-fetch list named four files. The actual
required set is five — the manifest file is required by
`install-sshd.ps1` and is missing from both the README and
the four files in the fetch list. Additionally, the upstream
filename is `Openssh-events.man` (capital O), not
`openssh-events.man`.

Fix: future Windows OpenSSH install packets enumerate the
five upstream files explicitly, with sha256 pins, and
preflight-check all five before invoking any installer.

### W2: `install-sshd.ps1` is destructive before dependency-check

Microsoft's `install-sshd.ps1` deletes the `sshd` and
`ssh-agent` service entries at lines 33 and 39, BEFORE
attempting to parse the manifest file at line 52. If the
manifest is missing, the service entries are gone by the
time the script halts.

Fix: future install packets should snapshot the service
state before invoking `install-sshd.ps1`, OR pre-flight-check
all required files (including the manifest) before invoking
it.

### W3: Windows `sudo` is not Linux `sudo`

The on-host agent encountered failures attempting
`sudo --status` and similar. Microsoft's Windows 11
`sudo.exe` is a much smaller utility than Linux `sudo`:
no `--status`, `-v`, `-l`. Inline execution quoting through
`sudo powershell.exe -Command "..."` is a quoting trap
between pwsh 7 / sudo / WinPS 5.1.

Captured as new spec section
[§Windows-Sudo Is Not Linux-Sudo](./windows-terminal-admin-spec.md).

## Apply outcome summary

| Question | Answer |
|---|---|
| Did Step 1 / Step 1b / v0.2.0 run? | Yes, all three. |
| Did Step 1 + Step 1b complete the `install-sshd.ps1` + `FixHostFilePermissions.ps1` recovery? | Yes. |
| Did the service-mode SSH KEX reset get fixed? | **No.** Same RST at `SSH2_MSG_KEXINIT` from both LAN and loopback. |
| Did the original RCA's "missing privsep user" hypothesis hold? | **No — refuted by Step 1b.** |
| Did a new root cause get confirmed? | **No — only candidate hypotheses identified.** |
| What's the next step? | A read-mostly evidence + scoped child-process-capture diagnostic (v0.3.0), NOT another repair attempt. |
| Is RDP affected? | No. RDP remains the canonical admin lane. |
| Should DSJ remain Phase 2 `rdp-only-host`? | Yes. No change until service-mode SSH is verified working end-to-end. |

## After This Apply

`docs/device-admin/current-status.yaml.devices[desktop-2jj3187]`:

- Move all three (Step 1 fix-block, Step 1b continuation,
  v0.2.0 diagnostic) to `applied_packets[]` with this apply
  record reference.
- Approval_required[] entry for
  `desktop-2jj3187-service-mode-fix-microsoft-repair-scripts`
  -> `state: applied-bug-persists`, with notes explicitly
  stating "the fix-block was applied as designed but did NOT
  resolve the service-mode KEX reset; the original RCA
  hypothesis is refuted; candidate hypotheses listed in apply
  record".
- blocked_items[] entry
  `desktop-2jj3187-service-mode-sshd-kex-reset` updated:
  narrative shift from "service-mode bug isolated, fix block
  pending" to "service-mode bug persists after fix-block;
  multiple candidate hypotheses pending controlled test in
  v0.3.0 diagnostic".
- Add `prepared_packets[]` entry for the planned v0.3.0
  evidence-collection diagnostic (read-mostly + WER LocalDump
  capture during service-mode probe; NOT another repair).
- Keep lifecycle_phase: 2 / classification: rdp-only-host.
- next_recommended_action repointed to the v0.3.0 evidence-
  collection diagnostic.

## Cross-References

- [desktop-2jj3187-ssh-service-mode-rca-2026-05-16.md](./desktop-2jj3187-ssh-service-mode-rca-2026-05-16.md) (original RCA; original `## Root Cause` hypothesis refuted by Step 1b — see addendum at the bottom)
- [desktop-2jj3187-ssh-kex-reset-diagnostic-apply-2026-05-16.md](./desktop-2jj3187-ssh-kex-reset-diagnostic-apply-2026-05-16.md) (v0.1.0 diagnostic apply record + foreground-success finding)
- [desktop-2jj3187-ssh-lane-install-v0.5.0-apply-2026-05-16.md](./desktop-2jj3187-ssh-lane-install-v0.5.0-apply-2026-05-16.md) (v0.5.0 install apply record + verification-gap finding)
- [windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md) — `§Hypothesis vs Confirmed Root Cause Discipline` (new), `§Windows-Sudo Is Not Linux-Sudo` (new), `§Packet-Defect Halt Rule` (existing)
- [dsj-service-mode-restart-handoff/README.md](./dsj-service-mode-restart-handoff/README.md) (the README with the fix-block that halted)
- [current-status.yaml](./current-status.yaml)
- Microsoft `LookupAccountSidA` docs: https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-lookupaccountsida
- Microsoft OpenSSH Error 1053 troubleshooting: https://learn.microsoft.com/en-us/troubleshoot/windows-server/system-management-components/openssh-server-service-wont-start-error-1053
- Win32-OpenSSH #1476 (`get_passwd: LookupAccountName() failed: 1332`): https://github.com/PowerShell/Win32-OpenSSH/issues/1476
- Win32-OpenSSH #1817 (sshd virtual user required + creation issues): https://github.com/PowerShell/Win32-OpenSSH/issues/1817
- Win32-OpenSSH #2403 (sshd-session.exe SID lookup failure): https://github.com/PowerShell/Win32-OpenSSH/issues/2403
- Upstream `openssh-events.man` in `PowerShell/openssh-portable` `latestw_all` branch: https://github.com/PowerShell/openssh-portable/tree/latestw_all/contrib/win32/openssh

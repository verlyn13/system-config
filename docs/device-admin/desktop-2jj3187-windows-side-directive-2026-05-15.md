---
title: DESKTOP-2JJ3187 Windows-Side Directive - 2026-05-15
category: operations
component: device_admin
status: active
version: 0.1.0
last_updated: 2026-05-15
tags: [device-admin, desktop-2jj3187, windows, directive, agent-handoff, phase-3]
priority: high
---

# DESKTOP-2JJ3187 Windows-Side Directive - 2026-05-15

This is the directive for an **agent or operator running on
DESKTOP-2JJ3187 in an elevated PowerShell session**. The MacBook-side
prep (1Password item, chezmoi conf.d) is complete; the Windows-side
work is what remains.

This directive is small. Authority and procedure live in the packets
linked below; this doc just sequences them and states the
stop-on-handback rule.

## Context (already done on the MacBook side)

- 1Password admin key item created 2026-05-14T19:05:13-08:00:
  ```text
  op://Dev/jefahnierocks-device-desktop-2jj3187-admin-ssh-verlyn13
  fingerprint: SHA256:0oDYmXRFrGuT4yyd0NLAAVyk0l/Aygu+iV88W2eq+/s
  public key:  ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFRgw1xN2rjmlIFbAPsp7cc6SJcm0h5IMvrL8o6CyLh9
  ```
  1Password generated the keypair in-place. The private half lives
  only in the operator MacBook's 1Password Dev vault.
- MacBook chezmoi conf.d applied
  ([macbook-ssh-conf-d-desktop-2jj3187-apply-2026-05-15.md](./macbook-ssh-conf-d-desktop-2jj3187-apply-2026-05-15.md)):
  `ssh -G desktop-2jj3187` on the MacBook resolves to `jeffr` /
  `192.168.0.217` with HostKeyAlias `192.168.0.217` and IdentityFile
  `~/.ssh/id_ed25519_desktop_2jj3187_admin.1password.pub`. On-disk
  fingerprint matches the 1P-source fingerprint end-to-end.
- The public-key body and fingerprint are pinned in §S5 of
  [desktop-2jj3187-ssh-lane-install-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-2026-05-15.md)
  v0.2.0 for paste-and-run. No live key material crosses the
  network or shell argv.

## Authority

- This directive applies on `DESKTOP-2JJ3187` only.
- The canonical procedures live in the two packets linked below.
- This directive does not authorize any change beyond what the
  packets explicitly authorize.
- DESKTOP-2JJ3187 lifecycle_phase is **2** today. Phase 3
  (`install-shell-lane`) is opened by the install packet below;
  Phase 4+ are out of scope for this directive.

## Reading list (read FIRST, before acting)

In this order:

1. [windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md)
   — Authority, Invariants, Device Lifecycle, Stop Rules, Evidence
   Writer Pattern. The spec is Windows-only; DESKTOP-2JJ3187 follows
   it.
2. [current-status.yaml](./current-status.yaml) — find
   `devices[].device == "desktop-2jj3187"` block. Confirm
   `applied_packets[macbook-ssh-conf-d-desktop-2jj3187]` is recorded.
3. [windows-pc.md](./windows-pc.md) — device record for
   DESKTOP-2JJ3187.
4. [handoff-desktop-2jj3187.md](./handoff-desktop-2jj3187.md) — local
   agent handoff with Hard Stops.
5. [desktop-2jj3187-terminal-admin-baseline-2026-05-15.md](./desktop-2jj3187-terminal-admin-baseline-2026-05-15.md)
   — Phase 0 packet (read-only).
6. [desktop-2jj3187-ssh-lane-install-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-2026-05-15.md)
   v0.2.0 — Phase 3 packet (greenfield install). Do NOT execute
   until step 1 below is complete and system-config has confirmed
   the baseline findings.

## Step 1 — Phase 0 baseline (read-only)

Apply
[desktop-2jj3187-terminal-admin-baseline-2026-05-15.md](./desktop-2jj3187-terminal-admin-baseline-2026-05-15.md)
exactly:

1. RDP into DESKTOP-2JJ3187 from the MacBook Windows App profile.
2. Open elevated PowerShell as `DESKTOP-2JJ3187\jeffr`.
3. Verify the identity proof block (`hostname`, `whoami`,
   `is_admin_role=True`, `High Mandatory Level`).
4. Copy-paste the §Read-Only Probe Script verbatim and run it.
5. The script writes to
   `C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-baseline-<timestamp>\`.

When the script finishes, return a redacted summary using the
§Return Shape block in the baseline packet. Do **not** print Wi-Fi
PSKs, BitLocker recovery values, Defender exclusion contents, or
private identity SIDs. Send the summary back to system-config so the
apply record can be committed.

**Hand-back checkpoint.** Do not proceed to Step 2 until
system-config has confirmed the baseline findings (the expected
state holds, no surprises). The baseline may surface facts that
require an addendum to the install packet — for example, an existing
`Get-WindowsCapability OpenSSH.Server` state of `Installed-Stopped`
instead of `NotPresent`.

## Step 2 — Phase 3 SSH lane install (live change)

**Wait for system-config confirmation that the baseline is clean
before starting Step 2.**

Apply
[desktop-2jj3187-ssh-lane-install-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-2026-05-15.md)
v0.2.0 exactly:

1. Still in the same elevated PowerShell session as
   `DESKTOP-2JJ3187\jeffr`. Re-verify the identity proof and the
   high-integrity admin token.
2. Run S0 (snapshot) → S1 (Add-WindowsCapability OpenSSH.Server) →
   S2 (Set-Service sshd Automatic + Start) → S3 (verify Match Group
   administrators block) → S4 (install hardening drop-in) → S5
   (paste-and-install pinned public key, ACL, fingerprint match
   gate) → S6 (replace default broad firewall rule with named
   scoped rule) → S7 (Restart-Service sshd, conditional sshd -T
   confirm).
3. Evidence lands at
   `C:\Users\Public\Documents\jefahnierocks-device-admin\desktop-2jj3187-ssh-install-<timestamp>\`.

If any step fails the embedded validation (sshd -t, fingerprint
match, ACL set), the script throws — follow the §Rollback section
of the install packet to revert.

## Step 3 — MacBook real-auth probe (after Step 2)

From the **operator MacBook** terminal (not on DESKTOP-2JJ3187):

```bash
ssh desktop-2jj3187 'cmd /c "hostname && whoami"'
```

Expected:

```text
DESKTOP-2JJ3187
desktop-2jj3187\jeffr
```

If `Permission denied (publickey)`: re-check fingerprint match
between the 1Password item and
`C:\ProgramData\ssh\administrators_authorized_keys`; re-check ACL
is `Administrators + SYSTEM` only; re-check sshd -T effective
config shows
`authorizedkeysfile __PROGRAMDATA__/ssh/administrators_authorized_keys`.

If TCP timeout: re-check `Jefahnierocks SSH LAN TCP 22` is Enabled,
Private, RemoteAddress `192.168.0.0/24`; confirm `Get-Service sshd`
is Running.

Once Step 3 passes, the device's lifecycle_phase becomes 3 and
classification becomes `reference-ssh-host`. Return a redacted
summary using §Return Shape of the install packet to system-config
for the apply record.

## Hard Stops

Stop and hand back to system-config rather than improvising if any of:

- Identity proof returns a different hostname or admin username.
- `Get-WindowsCapability` returns OpenSSH.Server in an unexpected
  state (anything other than `NotPresent` or `Installed`).
- `sshd -t` fails at any point after a config change.
- ACL set on `administrators_authorized_keys` or the drop-in fails.
- The on-disk fingerprint does not match the pinned 1P-source value.
- A command would touch any out-of-scope surface (accounts, groups,
  BitLocker, Defender exclusions, Codex sandbox accounts, network
  profile, DNS, DHCP, OPNsense, Cloudflare, WARP, 1Password,
  scheduled tasks, RDP rules, WinRM).
- The MacBook real-auth probe fails after Step 2 — do **not**
  attempt to "fix" by relaxing PasswordAuthentication or
  StrictModes; surface the failure for diagnosis.

## Out of Scope

- BitLocker / Secure Boot decisions (separate future packet).
- Defender exclusions audit (separate future packet).
- Cloudflare WARP enrollment (blocked on cloudflare-dns Windows
  multi-user rebaseline; tracked in system-config
  `handback-request-cloudflare-dns-windows-multi-user-2026-05-15.md`).
- Cloudflared service cleanup (separate future packet).
- DadAdmin-style legacy admin cleanup (DESKTOP-2JJ3187 has no
  equivalent to MAMAWORK's DadAdmin per current intake).

## Return Format

For each step that returns a hand-back, follow the §Return Shape
section of the corresponding packet. Keep evidence non-secret —
fingerprints, statuses, counts of rules, profile names. No keys,
recovery values, identifiers that imply private identity, or
session cookies.

Place private raw evidence (if any) outside the repo:

```text
~/Library/Logs/device-admin/2026-05-15/   # on the operator MacBook
C:\Users\Public\Documents\jefahnierocks-device-admin\   # on DESKTOP-2JJ3187
```

## Cross-References

- [windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md)
- [current-status.yaml](./current-status.yaml)
- [desktop-2jj3187-terminal-admin-baseline-2026-05-15.md](./desktop-2jj3187-terminal-admin-baseline-2026-05-15.md)
- [desktop-2jj3187-ssh-lane-install-2026-05-15.md](./desktop-2jj3187-ssh-lane-install-2026-05-15.md)
  v0.2.0 (pinned public key + fingerprint in §S5)
- [macbook-ssh-conf-d-desktop-2jj3187-apply-2026-05-15.md](./macbook-ssh-conf-d-desktop-2jj3187-apply-2026-05-15.md)
- [handback-format.md](./handback-format.md)

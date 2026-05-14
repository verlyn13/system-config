---
title: Device Agent Handoff - MAMAWORK Follow-up
category: operations
component: device_admin
status: active
version: 0.1.0
last_updated: 2026-05-14
tags: [device-admin, handoff, windows, mamawork, openssh, follow-up]
priority: high
---

# Device Agent Handoff - MAMAWORK Follow-up

This is the follow-up handoff for `MAMAWORK`. The initial inventory
pass is complete - see
[`windows-pc-mamawork.md`](./windows-pc-mamawork.md). This document
captures the **operator-side answers and decisions** still required
before any live elevated change on MAMAWORK is authorized.

## Source Of The Intake

The intake script
([`handoff-windows-lan-intake.md`](./handoff-windows-lan-intake.md))
was run on MAMAWORK by `MAMAWORK\jeffr` in elevated PowerShell 7.6.1
on 2026-05-13 and wrote its output to:

```text
C:\Users\Public\Documents\jefahnierocks-device-admin\windows-lan-intake-20260513-145504\
```

The operator copied the bundle to the MacBook at
`/Users/verlyn13/Downloads/mamaworkpc/` for review. The non-secret
summary is ingested into
[`windows-pc-mamawork.md`](./windows-pc-mamawork.md); the raw bundle
itself is **not** committed to this repo.

## What This Handoff Does Not Do

This handoff is documentation/coordination only. It does **not**
authorize any of:

- Enabling, restricting, or modifying OpenSSH server config on
  MAMAWORK.
- Changing the `Dad Remote Management` Windows Firewall rule scope
  (still `Profile=Any`).
- Enabling or modifying RDP, WinRM, PowerShell Remoting, any VNC
  product, or any third-party remote-admin agent.
- Creating, deleting, disabling, or changing any local user, MS
  Account, group, password, UAC, or local security policy.
- Installing, uninstalling, enrolling, or configuring WARP,
  `cloudflared`, Tailscale, or any other VPN / overlay.
- BitLocker enable, Secure Boot enable, TPM clearing, firmware
  changes.
- Backup install/configuration.
- HomeNetOps OPNsense, DHCP, Unbound DNS, or WoL changes.
- Cloudflare account changes, WARP enrollment, Access policy, Tunnel
  creation, or Zero Trust profile assignment.
- 1Password item creation, edit, or secret update.
- Rebooting, shutting down, sleeping, or waking MAMAWORK.

Every one of those is a future approval-gated packet. Approval
phrases will be quoted in those packets when drafted.

## Operator Questions To Resolve

Each question gates a separate future packet. Returning the answers
allows the corresponding packet to be authored. Answers may be
returned as a short markdown reply, in a follow-up
[`handback-format.md`](./handback-format.md)-style reply, or in
direct chat.

1. **Does `DadAdmin_WinNet` private key still exist on `fedora-top`
   for `verlyn13`?** Check via `for k in
   ~/.ssh/id_*; do ssh-keygen -lf "$k" 2>/dev/null; done` on
   `fedora-top` and look for fingerprint
   `SHA256:7WrWkYGE4aRGSXm2Sih5o+m+yUpMobpjM0Nd32CRXTk`. The point
   of this question is **only** to decide whether MAMAWORK SSH
   bootstrap can reuse an existing intended key or needs a fresh
   keypair. `DadAdmin_WinNet` is **legacy / bootstrap context** for
   the prior Fedora-to-MAMAWORK remote development setup and is
   **not** the Fedora admin-backup key path. Do not repurpose it
   for Fedora admin backup; that role belongs to the separate
   [fedora-top-admin-backup-ssh-key-strategy-packet-2026-05-14.md](./fedora-top-admin-backup-ssh-key-strategy-packet-2026-05-14.md).
   If the private key is found, record only the fingerprint match
   (already known) in the reply. If the private key is gone or
   continuity is unclear, the future
   `mamawork-ssh-key-bootstrap` packet will generate a fresh
   keypair on `fedora-top` and add the new public key to
   `C:\ProgramData\ssh\administrators_authorized_keys` on
   MAMAWORK in an elevated-write packet.
2. **Which Microsoft Account maps to which household member?**
   (`ahnie`, `axelp`, `ilage`, `jeffr`, `wynst`).
3. **Is `ahnie`'s membership in MAMAWORK `Administrators` intended?**
   The reading of the household stance is that family MS Accounts
   are regular users by default unless a device-specific record
   justifies otherwise. If `ahnie` should remain an admin on
   MAMAWORK, that justification belongs in the device record.
4. **What is the physical room / admin context for MAMAWORK?**
5. **Sleep-with-WoL or stay-awake** for remote administration?
6. **Ethernet-only long term** or expect Wi-Fi to become primary?
   (Wi-Fi DHCP would change the LAN IP if enabled.)
7. **Wake from full shutdown, sleep, or both?**
8. **BitLocker is off across C:.** Intentional, undecided, or
   future-enable intent?
9. **Secure Boot is disabled.** Intentional?
10. **Windows Hello / PIN in use for sign-in?**
11. **`DadAdmin` purpose.** Should it remain, or be replaced by a
    1Password-managed unique per-device credential?
12. **`CodexSandboxOnline`, `CodexSandboxOffline`** - OpenAI Codex
    sandbox accounts? Intentional? `CodexSandboxOffline` logged in
    `2026-05-13 13:50:05` - is that the expected workflow?
13. **`WsiAccount`** - purpose and ownership?
14. **Defender exclusions** (1 path, 1 process, 1 extension, 1 ASR
    rule) - what workload requires them? Operator may want to
    audit values directly in the Defender GUI rather than have an
    agent collect them.
15. **Other local-admin credentials slated for 1Password rotation?**
16. **Workloads that must not be interrupted** on MAMAWORK?
17. **Backup/restore plan** - acceptable to defer, or schedule a
    separate backup-plan packet?

## Next Live-Action Packets That Need These Answers

| Future packet | Gating answers | Notes |
|---|---|---|
| `mamawork-ssh-key-bootstrap` | Q1 | If `DadAdmin_WinNet` private key is **on** `fedora-top`, this packet is mostly verification + known_hosts. If **not**, it generates a new keypair on `fedora-top`, adds the public half to MAMAWORK's `administrators_authorized_keys`, and rotates trust. |
| `mamawork-ssh-hardening` | Q3, Q11, Q12, Q13, plus the open `sshd_config` decisions in the intake (StrictModes, AllowGroups, LogLevel) | Patterned after the fedora-top SSH hardening packet. Includes scoping the `Dad Remote Management` firewall rule to `Profile=Private`. |
| `mamawork-privilege-cleanup` | Q3, Q11, Q12, Q13, Q14 | Patterned after the fedora-top privilege cleanup. Removes drift from `Administrators` / `OpenSSH Users` etc., disables or repurposes unidentified local accounts. |
| `mamawork-defender-exclusions-audit` | Q14 | Likely operator-led via Defender GUI; system-config will only record outcomes. |
| `mamawork-backup-plan` | Q15, Q17 | Storage strategy + scheduled backup target. |
| `mamawork-bitlocker-securboot` | Q8, Q9 | Single combined packet; significant operator interaction required. |
| `mamawork-cloudflare-warp-cloudflared-cutover` | gated on `cloudflare-dns` handback (see [`handback-request-cloudflare-dns-2026-05-13.md`](./handback-request-cloudflare-dns-2026-05-13.md)) | Likely shares the same Cloudflare config as the fedora-top cutover; profile assignment per the household stance (kids' learning device administered by adult). |

## HomeNetOps Coordination (Already Captured)

MAMAWORK currently uses a host-side static IP `192.168.0.101`. The
`mamawork.home.arpa` FQDN does **not** yet resolve on the LAN. The
formal request to HomeNetOps for an OPNsense static-DHCP reservation
plus Unbound host override is in
[`handback-request-homenetops-2026-05-13.md`](./handback-request-homenetops-2026-05-13.md).
No HomeNetOps live change happens from this repo.

## Cloudflare-DNS Coordination (Already Captured)

Per the household plan, MAMAWORK is a kids' learning device that
should sit under the same Cloudflare Zero Trust profile umbrella as
the rest of the family fleet. The formal request to `cloudflare-dns`
is in
[`handback-request-cloudflare-dns-2026-05-13.md`](./handback-request-cloudflare-dns-2026-05-13.md).
That request asks for the org-wide handback (Zero Trust / WARP /
Access / Tunnel posture) plus per-device profile recommendations for
both `fedora-top` (Wyn user, verlyn13 administrator) and MAMAWORK
(kids' learning device, verlyn13 administrator). No Cloudflare live
change happens from this repo.

## Redaction / Secret-Handling

- **Public keys, fingerprints, MAC addresses, IP addresses inside the
  home LAN, OS build numbers, hostnames** are non-secret and are
  recorded in `windows-pc-mamawork.md`.
- **Private SSH keys, account passwords, MS-Account credentials,
  recovery keys, BitLocker recovery values, Defender exclusion
  contents, browser-stored secrets, OAuth tokens, shell history,
  credential-manager values** are **not** captured by the intake
  script and must never appear in repo docs or in operator replies
  to this handoff.
- The BIOS serial number was redacted by the intake script to the
  last 4 characters in the operator-side bundle, and is intentionally
  not echoed in this repo (matching the
  [fedora-44-laptop.md](./fedora-44-laptop.md) "Serial/service tag"
  convention). If a future packet needs the serial for a support
  workflow, fetch it from the local bundle - do not write the value
  into a committed file.
- The intake bundle on the MacBook is local-only; do not commit it
  to any repo or share it externally without review.

## Related

- [`windows-pc-mamawork.md`](./windows-pc-mamawork.md)
- [`handoff-windows-lan-intake.md`](./handoff-windows-lan-intake.md)
- [`handback-request-cloudflare-dns-2026-05-13.md`](./handback-request-cloudflare-dns-2026-05-13.md)
- [`handback-request-homenetops-2026-05-13.md`](./handback-request-homenetops-2026-05-13.md)
- [`current-status.yaml`](./current-status.yaml)
- [`handback-format.md`](./handback-format.md)
- [`fedora-44-laptop.md`](./fedora-44-laptop.md)
- [`fedora-top-remote-admin-routing-design-2026-05-13.md`](./fedora-top-remote-admin-routing-design-2026-05-13.md)
- [`../ssh.md`](../ssh.md)
- [`../secrets.md`](../secrets.md)

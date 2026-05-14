---
title: MAMAWORK Mini-PC Device Administration Record
category: operations
component: device_admin
status: inventory-pending
version: 0.1.0
last_updated: 2026-05-14
tags: [device-admin, windows, mamawork, openssh, mini-pc, rdp, bitlocker, firewall, 1password]
priority: high
---

# MAMAWORK Mini-PC Device Administration Record

Second household Windows host. Hostname `MAMAWORK` (DNS host `MamaWork`).
Secondary developer / kids' learning machine; primary dev box has moved
to `fedora-top` (Fedora 44, user `verlyn13`).

This record ingests the elevated intake captured 2026-05-13 and tracks
the open follow-ups. No live changes have been authorized on `MAMAWORK`
from this repo. The host already has OpenSSH SSH Server running as an
inherited LAN admin path; that posture is documented but not yet
hardened from `system-config`.

## Source Input

Ingested source (operator-side bundle on the MacBook, **not committed
to this repo**):

```text
/Users/verlyn13/Downloads/mamaworkpc/
  windows-lan-intake-20260513-145504/   primary elevated intake
                                        (REPORT.md, SUMMARY.md, 20+
                                        per-section .txt + .json files)
  MAMAWORK-WMI-20260513-143254/         earlier WMI forensics bundle
                                        (PIA thread-quota
                                        investigation); not used as
                                        primary evidence here
  windows-lan-intake.ps1                hardened-1.0 (2026-05-13)
                                        intake script the operator ran
```

The intake script is a fixed copy of the read-only inventory tool
distributed via `handoff-windows-lan-intake.md`. The collection
completed at `2026-05-13T15:00:11-08:00` from an elevated PowerShell
7.6.1 session by `MAMAWORK\jeffr`. The script writes only under
`C:\Users\Public\Documents\jefahnierocks-device-admin\`. No
sensitive-by-design data was collected (no passwords, recovery keys,
private keys, bearer credentials, browser data, shell history, Wi-Fi
PSKs, or tunnel credential JSON).

The repo records non-secret facts only.

## Identity

| Field | Value |
|---|---|
| Device label | AZW SER mini-PC, secondary developer / kids' learning workstation |
| Hostname | `MAMAWORK` (DNS host casing `MamaWork`; registry mixed-case) |
| OS edition/version/build | Windows 11 Pro 25H2; build `10.0.26200.8457` (current GA per Microsoft release-info; bumped from `26200.8246` during 2026-05-13 reboot). Registry `ProductName` reads `Windows 10 Pro` - a known Win11 compatibility quirk; trust `DisplayVersion=25H2` and `CurrentBuild=26200`. |
| Domain/Workgroup | Workgroup `WORKGROUP`; not domain-joined |
| Owner/user | Jefahnierocks-owned; `jeffr` (Microsoft Account) is the current admin user; secondary dev / kids' learning |
| Family Microsoft Accounts on box | `ahnie`, `axelp`, `ilage`, `jeffr`, `wynst` (mapping each MS Account to a household member is a pending operator question) |
| Local admin (separate) | `DadAdmin` (enabled local account, last logon `2025-12-07 16:27:47`) - inherited admin path; replacement by a 1Password-managed unique per-device credential is a planned follow-up |
| Hardware | AZW SER, AMD Ryzen 7 5800H, 8 physical / 16 logical cores, ~28.9 GiB RAM, integrated Radeon |
| BIOS | American Megatrends `5800H603`, 2023-12-11. BIOS serial number is recorded in the operator-side intake bundle (redacted to last 4 characters by the intake script) and is intentionally omitted from this repo record, matching the [fedora-44-laptop.md](./fedora-44-laptop.md) convention. |
| TPM | AMD fTPM `3.84.0.5`, present/ready/enabled/owned, AutoProvisioning enabled, not locked out; `RestartPending=True` even after the 2026-05-13 reboot (minor, monitor) |
| Secure Boot | **Disabled** (UEFI in use; `Confirm-SecureBootUEFI` = False) |
| Physical / admin context | Mini-PC form factor; specific room placement is a pending operator question |

Accounts explicitly called out for human review (do-not-act-without-
confirmation per the source report):

- `CodexSandboxOffline` (local, enabled, logged in `2026-05-13 13:50:05`) -
  looks like an OpenAI Codex CLI sandbox account; intentional?
- `CodexSandboxOnline` (local, enabled, never logged in) - same family;
  intentional dormant?
- `WsiAccount` (local, disabled, last logon `2025-10-23 13:34:39`) -
  unidentified; ownership and purpose unknown.

Local groups present include the expected built-ins plus
`CodexSandboxUsers` ("Codex sandbox internal group (managed)") and the
standard `OpenSSH Users` group (membership not enumerated in the v1.0
intake; gap flagged for v1.1 of the inventory script).

## Network Identity

| Field | Value |
|---|---|
| Wired interface | `Ethernet 2`, Realtek PCIe GbE Family Controller #2, Up @ 1 Gbps |
| Wired MAC | `B0-41-6F-0E-B7-B6` (preferred admin path) |
| Wi-Fi interface | `Wi-Fi 2`, Intel AX200; Disconnected at capture time |
| Wi-Fi MAC | `48-AD-9A-82-15-81` |
| Bluetooth PAN MAC | `48-AD-9A-82-15-85` |
| Wi-Fi Direct VAs | `48-AD-9A-82-15-82`, `4A-AD-9A-82-15-81` (Microsoft Wi-Fi Direct VAs for Miracast / Nearby Sharing) |
| Current LAN IP | `192.168.0.101/24` - **static, host-side manual** (`DHCP Enabled = No`) |
| Default gateway | `192.168.0.1` (IPv4); `fe80::eaff:1eff:fed2:49c8` (IPv6 link-local) |
| Connection-specific DNS suffix | `home.arpa` |
| DNS resolvers | `8.8.8.8`, `8.8.4.4` (manual, intentional per report; no PIA residue) |
| Network category | `Private` (correct for LAN-scoped firewall rules) |
| HomeNetOps reservation | **PASS** as of 2026-05-14 (see [mamawork-homenetops-lan-identity-2026-05-14.md](./mamawork-homenetops-lan-identity-2026-05-14.md)). OPNsense static DHCP reservation bound for `B0-41-6F-0E-B7-B6` -> `192.168.0.101`, plus Unbound host override `mamawork.home.arpa -> 192.168.0.101`. ARP `permanent=false` until MAMAWORK switches from host-static to DHCP - optional follow-up packet flagged. |
| Default routes | Single path, Ethernet 2 -> `192.168.0.1`; no VPN/tunnel default route |
| WoL | Configured on Ethernet 2 (`Magic Packet`, `Pattern Match`, `Shutdown WoL`); also armed on Wi-Fi (less reliable). HomeNetOps WoL registration is also pending. |

## Administration Model

| Control | Target | Current status |
|---|---|---|
| Local admin credential | Unique per-device admin credential stored in 1Password only. | Planned. The inherited `DadAdmin` local account is the candidate to be replaced or supplemented by a 1Password-managed credential. No 1Password item exists yet. |
| 1Password local admin item | `jefahnierocks-device-mamawork-local-admin` (planned name only) | Planned; secret value not created here. |
| Recovery key item | Not applicable today; BitLocker is off, no recovery key exists. | Planned only if BitLocker is later enabled. |
| Administrative SSH | LAN-only OpenSSH from `fedora-top` (verlyn13) to MAMAWORK using a key whose private half lives on `fedora-top`. | OpenSSH SSH Server is running on `MAMAWORK` (port 22). A single admin key is authorized (`DadAdmin_WinNet`, ED25519, fingerprint `SHA256:7WrWkYGE4aRGSXm2Sih5o+m+yUpMobpjM0Nd32CRXTk`). Whether the matching private half exists on `fedora-top` after the prior workstation migration is an open question (see Open Questions). |
| RDP | Not approved on MAMAWORK today. | Disabled at registry (`fDenyTSConnections=1`), service (`TermService` stopped), and firewall (all three RDP firewall rules disabled). Not enabled by this repo. |
| WinRM / PSRemoting | Not in target state. | Stopped, no listeners, all WinRM firewall rules disabled. |
| Administrators group | `verlyn13`-equivalent path + emergency local admin only. | Currently 4 members: built-in `Administrator` (disabled), `ahnie` (MS Account, enabled), `DadAdmin` (local, enabled), `jeffr` (MS Account, enabled, this session). Reducing to a single per-device managed admin + named adult identities is a planned follow-up. |
| Family Microsoft Accounts | Regular-user role on this device; allow normal use/exploration; no authority to disrupt mission-critical services, routing, backups, device management, or security. | `ahnie` currently sits in `Administrators` (anomaly to confirm with the operator). The other family MS Accounts (`axelp`, `ilage`, `wynst`) are not in `Administrators` per the capture. |
| Defender / firewall / BitLocker / Secure Boot | Documented, not changed by this record. | See Security Posture below. |

## Remote Access

Preferred path:

- LAN-only OpenSSH SSH from `fedora-top` (verlyn13) to MAMAWORK,
  publickey-only, `DadAdmin@192.168.0.101`. No WAN exposure.
- Future off-LAN access via Cloudflare-controlled path or a
  private overlay, per the fedora-top
  [remote-admin routing design](./fedora-top-remote-admin-routing-design-2026-05-13.md);
  not authored for MAMAWORK yet.

Current state captured 2026-05-13:

- `sshd.exe` (PID `4652`) is listening on `0.0.0.0:22` and `[::]:22`.
- `ssh-agent` service is **Disabled** on the host.
- `sshd_config` (`C:\ProgramData\ssh\sshd_config`) highlights:
  - `Port 22`
  - `PubkeyAuthentication yes`, **`PasswordAuthentication no`**
  - `AuthorizedKeysFile .ssh/authorized_keys`; admins use the central
    `C:\ProgramData\ssh\administrators_authorized_keys`
  - `StrictModes no` (relaxed file-perm check; common Windows OpenSSH
    posture; document the reason or revisit)
  - `LogLevel DEBUG3` (very verbose; planned to lower to `INFO`)
  - `Subsystem sftp sftp-server.exe`
  - A `HostKey` line references a nonexistent `ssh_host_dsa_key`
    (harmless; sshd skips missing keys; planned cleanup)
- Custom firewall rule `Dad Remote Management` is the only allow path
  for port 22. **Enabled, Allow, Inbound, Profile=Any**. The "Any"
  profile covers Public and Domain in addition to Private; scoping to
  Profile=Private is a planned follow-up.
- Standard built-in `OpenSSH SSH Server (sshd)` firewall rule is **not
  present** as a named rule; the custom `Dad Remote Management` rule
  is what actually permits SSH today.
- Host keys (public, safe to record; both client-side and
  audit-relevant):
  - RSA-3072: `SHA256:YlSw9qCmmjkriAzELy6+xNFR02DUwEf7SFXvjwJCF7Q`
  - ECDSA-256: `SHA256:9jttrIlcNSlqoP7ndI3MAEZ5zyGWWKI41P+WV/U+3UU`
  - ED25519-256: `SHA256:iguuNG5MdURfv1nFwyTBDmY9EmFxEKHHDfYnNOv34hk`
  - Generated `2025-12-07 13:47` on this host (`system@MamaWork`).
  - The ED25519 key is the preferred client trust target.
- Authorized admin keys: a single ED25519 key labeled
  `DadAdmin_WinNet` with fingerprint
  `SHA256:7WrWkYGE4aRGSXm2Sih5o+m+yUpMobpjM0Nd32CRXTk`, present in both
  `C:\ProgramData\ssh\administrators_authorized_keys` and
  `C:\Users\DadAdmin\.ssh\authorized_keys` (per-profile copy is
  NTFS-ACL-protected: only `DadAdmin` and `SYSTEM` can read).
  **Classification:** `DadAdmin_WinNet` is **legacy / bootstrap
  context** for the prior Fedora-to-MAMAWORK remote-development path
  (when the primary dev host was a different machine). Its only
  current value is to test whether the matching private half still
  exists on `fedora-top` for `verlyn13` after the workstation
  migration. If the private half exists, MAMAWORK SSH bootstrap can
  reuse it; if it does not, MAMAWORK will get a freshly generated
  keypair via the future `mamawork-ssh-key-bootstrap` packet.
  `DadAdmin_WinNet` is **explicitly NOT the Fedora admin-backup
  key**; that role is filled by the separate
  [fedora-top-admin-backup-ssh-key-strategy-packet-2026-05-14.md](./fedora-top-admin-backup-ssh-key-strategy-packet-2026-05-14.md),
  which adds a second `verlyn13` admin key to `fedora-top` from a
  1Password-managed source. Do not reuse `DadAdmin_WinNet` for
  Fedora admin backup.
- Per-user `.ssh` directories observed:
  - `DadAdmin`: admin key present.
  - `DadAdmin.MamaWork`: duplicate profile, admin key also present.
  - `jeffr`: empty `authorized_keys`, plus a non-standard
    `authorized_keys.txt` of unknown content. The intake agent
    intentionally did **not** read that file in case it contains
    private-key material; rename/import or delete is a planned
    operator action.

Listening TCP ports captured (relevant subset):

```text
22     sshd                  (PID 4652)        0.0.0.0 + [::]
135    svchost (RPC endpoint mapper)
139    System (NetBIOS session)
445    System (SMB)
5040   svchost
5357   System (WS-Discovery)
7680   svchost (Delivery Optimization)
15292  Adobe Desktop Service (loopback only)
49664-49681 standard Windows RPC dynamic ports
59869  logioptionsplus_agent (Logitech Options+)
```

UDP highlights include NetBIOS Name/Datagram (137/138), SSDP (1900),
mDNS (5353 via Chrome), LLMNR (5355), and DCOM/UPnP dynamic ports.

Third-party remote-access tools: **none** detected. No TeamViewer,
AnyDesk, RustDesk, VNC, Parsec, Sunshine/Moonlight, Tailscale,
Cloudflare WARP, `cloudflared`, or comparable agent. Logitech
Options+ binds a LAN port for HID coordination; not a remote-admin
service.

## Security Posture

| Area | Target | Current status |
|---|---|---|
| Defender | Real-time on; signatures current; periodic full scan. | AM/AV/Antispyware/Behavior/IOAV/NIS/OnAccess/RealTime all `True`. Signatures updated `2026-05-13 06:34`. Last quick scan 2 days ago. Full scan never run (`FullScanAge=4294967295`). 1 exclusion path, 1 exclusion process, 1 exclusion extension, 1 ASR rule - **values intentionally not collected** by the script; needs a separate scoped review with the operator. |
| Windows Update | Current. | Patched 2026-05-13 with `KB5087051`, `KB5089549`, `KB5092762`. Prior `KB5088467` (2026-04-15), `KB5054156` (2025-10-18). Build `26200.8457` is current GA. |
| BitLocker | Decision deferred. | OFF on C: (`FullyDecrypted`, `ProtectionStatus=Off`, no key protectors, no recovery key). 929.56 GB OS volume. |
| TPM | Healthy, ready for future use. | Present, ready, enabled, owned, AutoProvisioning enabled, not locked out. `RestartPending=True` even after a fresh reboot (minor anomaly, monitor). |
| Secure Boot | Decision deferred. | Disabled. UEFI in use. |
| Firewall profiles | All three Enabled with effective Block-by-default inbound. | Domain/Private/Public all `Enabled`. `DefaultInboundAction = NotConfigured` (effective default Block). |
| RDP rules | Disabled until approved. | All three RDP firewall rules disabled. |
| WinRM rules | Disabled until approved. | All WinRM firewall rules disabled. |
| OpenSSH rule | LAN-only allow. | Currently single custom `Dad Remote Management` rule with `Profile=Any`; planned to scope to `Profile=Private`. |
| Backup / recovery | Not configured. | `wbadmin get versions` returns no backup. Single 1 TB NVMe SSD (`CT1000P3PSSD8`, Crucial P3 Plus); 374 GB free. No File History config. Backup plan is a planned follow-up given that this is also a kids' learning machine where data loss is likely. |
| Power / wake | Mini-PC always on AC; WoL armed. | `S3 + Hibernate + Hybrid Sleep + Fast Startup` available. Fast Startup ON (`HiberbootEnabled=1`). WoL enabled on Ethernet 2 (magic packet + pattern match + Shutdown WoL) and Wi-Fi. No active wake timers. Wake-armed HID keyboard x4 and mouse. |
| Compute / runtime | GPU/Hyper-V/WSL/Docker recorded for inventory. | Integrated AMD Radeon (driver `31.0.21912.14`, 3 GiB shared); no discrete GPU; `nvidia-smi` absent. WSL not installed. Docker not installed. Hyper-V services all stopped (Manual). `Get-WindowsCapability -Online` / `Get-WindowsOptionalFeature -Online` failed with "Class not registered" in pwsh 7; a follow-up elevated run from Windows PowerShell 5.1 is needed for the definitive optional-features inventory. |
| VPN / overlay clients | None. | WARP not installed (the `WarpJITSvc` service is .NET WARP JIT, name collision only). `cloudflared` not installed. Tailscale not installed. **PIA was uninstalled on 2026-05-13 ~14:42** by the operator after being identified as a WMI thread-quota culprit; re-verification confirms 12 PIA filesystem paths, 10 registry keys, 0 firewall rules, 0 services, 0 hidden adapters, 0 PnP devices remain - **all clean**. |

## Approval-Gated Build Phases

Do not execute these without explicit approval.

0. Establish or verify the LAN OpenSSH foothold from `fedora-top`
   to MAMAWORK.
   Current: SSH server is up, key is authorized. Open question:
   whether the matching `DadAdmin_WinNet` private key currently
   exists on `fedora-top` after the prior workstation migration.
1. Request HomeNetOps static DHCP/local DNS using
   `B0-41-6F-0E-B7-B6` -> `192.168.0.101`, FQDN
   `mamawork.home.arpa`. See the outbound HomeNetOps handback
   request.
2. Harden `sshd_config`:
   - scope `Dad Remote Management` firewall rule to
     `Profile=Private`;
   - optionally pin `ListenAddress 192.168.0.101`;
   - lower `LogLevel DEBUG3` to `INFO`;
   - remove the dead `HostKey ... ssh_host_dsa_key` line;
   - decide whether `StrictModes no` stays; document the reason if
     retained;
   - decide whether `AllowGroups OpenSSH Users` gates access (add
     `DadAdmin` to that group first);
   - reconcile `C:\Users\jeffr\.ssh\authorized_keys.txt`.
3. Privilege cleanup:
   - decide which of the four Administrators stay (`Administrator`
     is already disabled);
   - decide whether `ahnie`'s admin membership is intentional or
     drift;
   - decide on `DadAdmin` replacement by a 1Password-managed
     credential;
   - clarify the role of `CodexSandboxOnline`, `CodexSandboxOffline`,
     and `WsiAccount`.
4. Defender exclusions audit (1 path, 1 process, 1 extension, 1 ASR
   rule).
5. Decide BitLocker / Secure Boot posture.
6. Decide whether MAMAWORK is part of the Cloudflare WARP /
   `cloudflared` / Access design once `cloudflare-dns` returns its
   handback for `fedora-top` (the same design likely covers both
   devices). Until then, **MAMAWORK is LAN-only**.
7. Define a backup strategy for the kids' learning + dev workload
   (single 1 TB NVMe SSD today; no backup at all).
8. Run an elevated Windows PowerShell 5.1 pass to capture
   `Get-WindowsCapability -Online` / `Get-WindowsOptionalFeature
   -Online` (the pwsh 7 capture failed with "Class not registered").
9. Optionally pursue Windows App / RDP as a parallel admin path
   only if specifically approved alongside SSH.

## Evidence

Operator-side bundle (NOT in this repo):

```text
/Users/verlyn13/Downloads/mamaworkpc/windows-lan-intake-20260513-145504/
  REPORT.md                              consolidated narrative
  SUMMARY.md                             timing + completion
  00-admin-and-machine-summary.json      identity / hardware / OS
  01-identity-os.txt                     OS / domain / install
  02-firmware-tpm-secureboot-bitlocker.txt
  03-local-users-groups.txt              accounts + group memberships
  04-network-identity.txt                interfaces, routes, DNS
  05-listeners-and-processes.txt         TCP/UDP listeners + pids
  06-firewall-and-remote-access.txt      profiles + rules + RDP/WinRM
  07-services-remote-agents.txt          installed services posture
  08-cloudflare-tailscale-vpn.txt        no overlay clients present
  09-defender-update-security.txt        Defender + patches
  10-power-wake.txt                      power, WoL, sleep states
  11-storage-backup.txt                  disks + backup absence
  12-gpu-compute-virtualization.txt      GPU, WSL, Docker, Hyper-V
  13-installed-apps.txt                  installed apps inventory
  14-scheduled-tasks-startup-shares.txt  scheduled tasks + shares
  15-recent-system-events.txt            recent events
  16-environment-names-only.txt          env-var names only
  17-pia-cleanup-verification.txt        PIA uninstall verification
  18-wmi-quota-and-thread-events.txt     WMI thread quota events
  19-claude-audit-snapshot.txt           agent audit snapshot
```

System-config holds only the non-secret summary captured in this
record. The raw `.evtx` and `.csv` artifacts in
`/Users/verlyn13/Downloads/mamaworkpc/MAMAWORK-WMI-20260513-143254/`
are operator-side forensics and are not ingested here.

Useful non-secret proof commands for the next elevated pass:

- `Get-ComputerInfo | Select-Object CsName, OsName, OsDisplayVersion,
  OsBuildNumber, WindowsVersion, CsDomain, CsWorkgroup, TimeZone`
- `Get-NetAdapter -Physical`
- `Get-NetIPConfiguration`
- `Get-NetConnectionProfile`
- `Get-Service sshd, TermService, WinRM, ssh-agent`
- `Get-NetFirewallRule -DisplayName 'Dad Remote Management'`
- `Get-LocalGroupMember -Group Administrators`
- `Get-LocalGroupMember -Group 'OpenSSH Users'`
- `Get-LocalGroupMember -Group 'Remote Desktop Users'`

## Open Questions From The Intake

Operator answers needed for these items, all from the
2026-05-13 REPORT.md Step 3 list:

1. Does the `DadAdmin_WinNet` private key (fingerprint
   `SHA256:7WrWkYGE4aRGSXm2Sih5o+m+yUpMobpjM0Nd32CRXTk`) still exist
   on `fedora-top` for `verlyn13`? If not, a new keypair must be
   generated on `fedora-top` and the new public key added to
   `C:\ProgramData\ssh\administrators_authorized_keys` (live elevated
   change, out of scope here).
2. Which Microsoft Account maps to which household member
   (`ahnie`, `axelp`, `ilage`, `jeffr`, `wynst`)?
3. Physical room / admin context for the mini-PC?
4. Should MAMAWORK stay awake for remote administration or
   sleep-with-WoL-wakeup?
5. Is Ethernet 2 the long-term preferred path, or is Wi-Fi expected
   to become primary?
6. Wake from full shutdown, sleep, or both?
7. Is BitLocker-off on C: intentional, undecided, or post-this-pass
   intent?
8. Is Secure-Boot-off intentional?
9. Windows Hello / PIN in use for sign-in?
10. Who is `DadAdmin` actually for; is it slated to be replaced by a
    1Password-managed unique per-device credential?
11. `CodexSandboxOffline` and `CodexSandboxOnline` workflow scope and
    expected use?
12. `WsiAccount` purpose?
13. Defender exclusion subjects (1 path, 1 process, 1 extension, 1
    ASR rule) - what workload requires them?
14. Any other local-admin credentials slated for 1Password rotation?
15. Workloads that must not be interrupted on MAMAWORK?
16. Backup/restore plan acceptable to defer, or schedule a separate
    backup-plan task?

These should be answered in or with the
[handoff-mamawork.md](./handoff-mamawork.md) follow-up.

## Boundary Assertions

- `system-config` owns this record. No edit to MAMAWORK live state
  is authorized by ingesting the intake.
- HomeNetOps owns OPNsense, DHCP, Unbound DNS, NAT, HAProxy, WoL
  registration; the static DHCP + local DNS request for MAMAWORK
  belongs to HomeNetOps and is captured in the outbound
  [HomeNetOps handback request](./handback-request-homenetops-2026-05-13.md).
- `cloudflare-dns` owns Cloudflare DNS, Tunnel, Access, Gateway,
  WARP device enrollment, Zero Trust profile assignment, and
  adult-vs-kids profile membership. The authoritative
  [cloudflare-dns handback ingest](./cloudflare-dns-handback-ingest-2026-05-14.md)
  (citing cloudflare-dns commit `b5b9460`) recommends MAMAWORK ->
  **Kids profile** with one explicit trade-off: Kids profile is
  **locked**, so Mama (primary Litecky Editing Services user)
  cannot disconnect WARP on her Windows account. Every Litecky-
  required domain that the kids-controls Gateway policies would
  block must be added to the cloudflare-dns `01-custom-allow` list
  (precedence 10) **before** the MAMAWORK WARP cutover. Operator
  picks the WARP enrollment identity between
  `axelptjohnson@gmail.com` and `wynrjohnson@gmail.com`. **WARP is
  system-level**: one identity per machine, regardless of how many
  Windows user accounts exist on MAMAWORK. MAMAWORK may migrate to
  a separate Litecky Cloudflare org later; at that point profile
  placement revisits.

## Related

- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
- [handoff-mamawork.md](./handoff-mamawork.md)
- [handoff-windows-lan-intake.md](./handoff-windows-lan-intake.md) -
  generic Windows LAN intake script that the operator ran on
  MAMAWORK to produce the source bundle.
- [windows-pc.md](./windows-pc.md) - first Windows PC
  (`DESKTOP-2JJ3187`) for the parallel pattern.
- [fedora-44-laptop.md](./fedora-44-laptop.md) - primary dev box
  used to administer MAMAWORK over LAN.
- [fedora-top-remote-admin-routing-design-2026-05-13.md](./fedora-top-remote-admin-routing-design-2026-05-13.md) -
  the household routing design that will eventually cover MAMAWORK
  as well.
- [handback-request-cloudflare-dns-2026-05-13.md](./handback-request-cloudflare-dns-2026-05-13.md)
- [handback-request-homenetops-2026-05-13.md](./handback-request-homenetops-2026-05-13.md)
- [../ssh.md](../ssh.md)
- [../secrets.md](../secrets.md)

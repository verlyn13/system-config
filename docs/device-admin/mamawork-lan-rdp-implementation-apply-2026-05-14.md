---
title: MAMAWORK LAN RDP Implementation Apply - 2026-05-14
category: operations
component: device_admin
status: applied-host-side-lan-unreachable
version: 0.1.0
last_updated: 2026-05-14
tags: [device-admin, mamawork, windows, rdp, firewall, lan, evidence]
priority: high
---

# MAMAWORK LAN RDP Implementation Apply - 2026-05-14

The operator applied the
[mamawork-lan-rdp-implementation packet (2026-05-14)](./mamawork-lan-rdp-implementation-2026-05-14.md)
on MAMAWORK from an elevated PowerShell 7+ session at
`2026-05-14T08:56:39.1939876-08:00`. **Host-side state is correct
per the captured evidence**; **LAN inbound reachability is broken
for all TCP ports** (3389, 22, 445, 135, 139) from two
independent vantage points (MacBook and fedora-top), so RDP cannot
be used for remote administration yet. The same symptom blocks
SSH; the cause is at a layer above the per-rule allow list (see
"Outstanding Diagnostic" below).

No live `system-config` host change happened; the operator ran the
script on MAMAWORK and returned non-secret evidence which is
ingested here.

## Approval

Guardian approval matches the packet's "Required Approval Phrase"
section. Operator executed the documented script as
`MAMAWORK\jeffr` in an elevated PowerShell 7+ session and returned
the evidence in chat.

## Apply Sequence (Actual)

1. Operator opened elevated PowerShell 7+ on MAMAWORK as
   `MAMAWORK\jeffr`.
2. Ran the packet's documented script. The script's
   `Write-Evidence` helper (`| Tee-Object -FilePath ... -Append`)
   silently dropped multi-line formatted blocks during the
   first run, so the operator **re-captured** the evidence via
   direct `Set-Content` and tagged the resulting file
   `evidence_file: C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-rdp-lan-20260514-085426.txt`
   with the note
   `packet's Write-Evidence helper drops piped multi-line strings; re-captured by direct Set-Content`.
   The packet doc has been patched in the same commit as this
   apply record so the helper bug doesn't recur on the next
   Windows host.

3. Pre-apply state captured (per the packet); apply executed:
   - `Set-NetConnectionProfile -InterfaceIndex (Ethernet 2) -NetworkCategory Private`
   - `fDenyTSConnections = 0`
   - `UserAuthentication = 1` (NLA)
   - `TermService` set to `Automatic` and started (now `Running`)
   - Built-in `Remote Desktop` firewall group disabled
   - Custom rules created (`Jefahnierocks RDP LAN TCP 3389` and
     `Jefahnierocks RDP LAN UDP 3389`; Inbound Allow; Profile
     Private; RemoteAddress `192.168.0.0/24`)
   - `powercfg /hibernate off`; AC sleep/hibernate timeouts 0;
     hybrid sleep 0
   - Best-effort NIC wake-property idempotent enable (Magic
     Packet, Pattern Match, S0ix-magic-packet all `Enabled`)
4. Local 3389 probe on MAMAWORK: `Test-NetConnection 127.0.0.1:3389`
   returned `TcpTestSucceeded=True`.
5. Listener confirmed: `LISTEN` on `0.0.0.0:3389` and
   `[::]:3389`, PID `33520` (TermService).
6. From the MacBook (`192.168.0.0/24` LAN), `nc -vz -G 3
   192.168.0.101 3389`: **timeout**.
7. From `fedora-top` (`192.168.0.0/24` LAN), `nc -vz -w 3
   192.168.0.101 3389` and `mamawork.home.arpa 3389`:
   **timeout** for both.
8. Cross-port probes from fedora-top to MAMAWORK during the same
   window: TCP/22, TCP/445, TCP/135, TCP/139 all **timeout**.
   L2 ARP entry for `192.168.0.101` resolves to
   `b0:41:6f:0e:b7:b6` and is marked `REACHABLE` (LAN routing is
   fine).

## Evidence (Operator-Returned, Repo-Safe)

### Identity And Adapter

```text
timestamp:        2026-05-14T08:56:39.1939876-08:00 (re-captured post-apply)
operator:         MAMAWORK\jeffr (elevated High Mandatory Level)
hostname:         MamaWork
wired_adapter:    Ethernet 2  MAC B0-41-6F-0E-B7-B6  1 Gbps
wired_ipv4:       192.168.0.101/24
```

### Post-Apply Connection Profile

```text
InterfaceAlias    : Ethernet 2
NetworkCategory   : Private
IPv4Connectivity  : Internet
```

### Post-Apply RDP Registry

```text
fDenyTSConnections  : 0
UserAuthentication  : 1
```

### TermService

```text
Name       : TermService
Status     : Running
StartType  : Automatic
```

### Custom Firewall Rules (Jefahnierocks RDP LAN)

```text
Protocol  LocalPort  RemotePort  IcmpType  DynamicTarget
--------  ---------  ----------  --------  -------------
TCP       3389       Any         Any       Any
UDP       3389       Any         Any       Any

LocalAddress   RemoteAddress
------------   -------------
Any            192.168.0.0/255.255.255.0
Any            192.168.0.0/255.255.255.0
```

### Built-In Remote Desktop Group (All Disabled)

```text
DisplayName                          Enabled  Direction  Action
-----------                          -------  ---------  ------
Remote Desktop - User Mode (TCP-In)  False    Inbound    Allow
Remote Desktop - User Mode (UDP-In)  False    Inbound    Allow
Remote Desktop - Shadow (TCP-In)     False    Inbound    Allow
```

### Power Posture

```text
Sleep states available:    Standby (S3)
Sleep states unavailable:  S1 (no firmware), S2 (no firmware),
                           Hibernate (not enabled - correct),
                           S0ix (no firmware),
                           Hybrid Sleep (no hibernate),
                           Fast Startup (no hibernate)

powercfg /devicequery wake_armed:
  HID Keyboard Device
  HID-compliant mouse (002)
  HID Keyboard Device (006)
  HID Keyboard Device (007)
  HID Keyboard Device (008)
```

**Observation**: `Ethernet 2` is **not** listed in
`wake_armed` despite Magic Packet / Pattern Match advanced
properties being Enabled. The advanced property is one half of
the equation; the per-device wake-policy
(`powercfg /deviceenablewake "<friendly name or InstanceId>"`)
is the other half. WoL practical wake from sleep will not work
until both are present. This is **not** a regression caused by
this apply; it was the pre-apply state and is captured here for
the follow-up packet, not patched in this apply.

### NIC Advanced Wake Properties

```text
DisplayName                                                  DisplayValue
-----------                                                  ------------
Wake on magic packet when system is in the S0ix power state  Enabled
Wake on Magic Packet                                         Enabled
Wake on pattern match                                        Enabled
```

S0ix is unavailable on this firmware (see Power Posture); the
S0ix-specific magic-packet property has no practical effect, but
is harmless to leave Enabled.

### Local 3389 Probe (on MAMAWORK)

```text
ComputerName      : 127.0.0.1
RemotePort        : 3389
TcpTestSucceeded  : True
```

### Listener Binding

```text
LocalAddress  LocalPort  State   OwningProcess
------------  ---------  -----   -------------
::            3389       Listen  33520
0.0.0.0       3389       Listen  33520
```

### LAN Inbound Reachability (Probes From Two Vantage Points)

| From | Target | Result |
|---|---|---|
| MacBook (`192.168.0.0/24`) | `192.168.0.101:3389` | **timeout** |
| MacBook | `mamawork.home.arpa:3389` | **timeout** |
| fedora-top (`192.168.0.0/24`) | `192.168.0.101:3389` | **timeout** |
| fedora-top | `mamawork.home.arpa:3389` | **timeout** |
| fedora-top | `192.168.0.101:22` (SSH) | **timeout** |
| fedora-top | `192.168.0.101:445` (SMB) | **timeout** |
| fedora-top | `192.168.0.101:135` (RPC EPM) | **timeout** |
| fedora-top | `192.168.0.101:139` (NetBIOS) | **timeout** |
| fedora-top | L2 ARP for `192.168.0.101` | **REACHABLE** (`b0:41:6f:0e:b7:b6`, on `wlp0s20f3`) |
| fedora-top | DNS `mamawork.home.arpa` | resolves to `192.168.0.101` (via OPNsense Unbound) |

Every inbound TCP probe times out. UDP probes (NetBIOS Name 137,
Datagram 138) complete the send phase, which NCat can verify but
NCat cannot confirm the packet was actually received by an
application. The inbound-TCP timeout is uniform across ports and
across clients, which rules out per-port firewall rule
misconfiguration as the root cause.

## Outstanding Diagnostic

This is **not** an RDP packet bug. The RDP apply did everything the
packet documented; the post-apply state on MAMAWORK is exactly
what the packet target specified. The LAN-inbound-TCP timeout
affects **every** TCP port simultaneously, including SSH and SMB
which the RDP packet did not touch. The cause is on MAMAWORK,
above the per-rule firewall layer:

1. **Higher-priority Block rule** on the Private profile. Windows
   Firewall evaluates Block rules even when an Allow rule also
   matches; one Block-Inbound-TCP-Any rule on Private would
   suppress all of `3389`, `22`, `445`, `135`, `139`.
2. **Microsoft Defender ASR rule** silently dropping LAN inbound
   on this host. Intake noted MAMAWORK has 1 ASR rule configured;
   contents were intentionally not captured.
3. **Third-party / endpoint-protection WFP callout** invisible to
   `Get-NetFirewallRule` but enforced inside the Windows Filtering
   Platform.
4. **Network-identity drift** where MAMAWORK has memorized this
   LAN as `Public` in the network-list registry, even though the
   active-binding category currently shows `Private`. Inbound
   evaluation might use the memorized identity.
5. **A WSL2 / Hyper-V virtual switch** intercepting the inbound
   path and never forwarding it to the host firewall's Private
   profile evaluation. The intake captured `Hyper-V: all
   `vmic*` services Stopped`, so this is unlikely but should be
   confirmed.

The next step is the read-only investigation packet -
[mamawork-ssh-investigation-packet-2026-05-14.md](./mamawork-ssh-investigation-packet-2026-05-14.md)
- **broadened from TCP/22 to include TCP/3389, TCP/445, TCP/135,
TCP/139**, plus temporary firewall logging
(`Set-NetFirewallProfile -Name Private -LogBlocked True`) to see
the actual block/allow decision in the firewall log during a
fresh external probe. Adapting the existing approved investigation
procedure to also enumerate Block rules and to enable LogBlocked
is within the spirit of its "read-only diagnostic" approval; if
the operator prefers an explicit re-approval, the packet can be
versioned with the broadened scope.

Until the diagnostic completes, **MAMAWORK has no remote-admin
path from MacBook or fedora-top** beyond physical access.

## Boundary Assertions

The apply did NOT change any of the following:

- `sshd`, `sshd_config`, `C:\ProgramData\ssh\administrators_authorized_keys`,
  or any `.ssh\authorized_keys` (those are the separate
  `mamawork-ssh-key-bootstrap` packet, which the operator has NOT
  yet reported as applied).
- Cloudflare, WARP, `cloudflared`, Tailscale (still installed but
  not in use on MAMAWORK), OPNsense, DNS, DHCP, 1Password.
- Accounts, group memberships, the duplicate `DadAdmin.MamaWork`
  profile.
- BitLocker (still off), Secure Boot (still off), TPM (still
  unowned).
- The host-static-vs-DHCP question. MAMAWORK still uses
  host-side static IP `192.168.0.101`.
- Defender exclusions, ASR rules (still 1 configured; contents
  unknown).

## Rollback

If the operator decides to revert RDP before the diagnostic
completes (recommended NO — the host-side state is correct and
keeps cleanly even without LAN reachability):

```powershell
Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 1
Get-NetFirewallRule -DisplayName 'Jefahnierocks RDP LAN*' -ErrorAction SilentlyContinue |
  Remove-NetFirewallRule
Get-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue |
  Disable-NetFirewallRule
```

Power-readiness changes (`hibernate off`, AC sleep/hibernate 0,
hybrid sleep 0) are not rolled back. They're separate decisions
and the operator can revert them deliberately if desired.

## Windows App Smoke

Not testable from outside MAMAWORK yet. Use
[windows-app-mamawork.md](./windows-app-mamawork.md) for the
profile when LAN inbound is restored.

## Remaining Blockers

- **The LAN-inbound-TCP blackhole investigation**. Highest
  priority for MAMAWORK; same packet unblocks both SSH and RDP.
- **MAMAWORK SSH key bootstrap apply status**: the operator
  returned BIOS + RDP evidence but did **not** include
  SSH-key-bootstrap evidence. The packet is approved; status is
  ambiguous - either not yet applied, or applied but evidence
  unreturned. Awaiting confirmation.
- **WoL NIC wake-policy**: `Ethernet 2` is not in `wake_armed`.
  The advanced properties are correct; the per-device wake
  policy (`powercfg /deviceenablewake`) needs one more step. The
  BIOS inspection confirms S3 + Wake-on-PME at the firmware
  level, so a follow-up packet `mamawork-nic-wake-enable` can
  close the gap once the inbound investigation is resolved.
- **BIOS ErP / AC-restore / WoL-from-S5**: not exposed in this
  BIOS revision; documented in
  [mamawork-bios-wol-inspection-2026-05-14.md](./mamawork-bios-wol-inspection-2026-05-14.md).
  Not a regression; not a current blocker for LAN admin.
- The MAMAWORK host-static-vs-DHCP decision (separate packet,
  deferred until LAN admin is stable).

## Related

- [mamawork-lan-rdp-implementation-2026-05-14.md](./mamawork-lan-rdp-implementation-2026-05-14.md) -
  packet (Write-Evidence helper bug patched in the same commit
  as this apply record).
- [mamawork-bios-wol-inspection-2026-05-14.md](./mamawork-bios-wol-inspection-2026-05-14.md) -
  BIOS inspection ingest from the same operator session.
- [mamawork-ssh-investigation-packet-2026-05-14.md](./mamawork-ssh-investigation-packet-2026-05-14.md) -
  read-only investigation; the broader inbound-TCP-blackhole
  finding makes its scope effectively also cover TCP/3389/445/etc.
- [mamawork-ssh-key-bootstrap-packet-2026-05-14.md](./mamawork-ssh-key-bootstrap-packet-2026-05-14.md) -
  parallel packet; status currently unconfirmed.
- [mamawork-homenetops-lan-identity-2026-05-14.md](./mamawork-homenetops-lan-identity-2026-05-14.md) -
  LAN identity PASS (rules out OPNsense as the cause).
- [windows-pc-mamawork.md](./windows-pc-mamawork.md)
- [windows-app-mamawork.md](./windows-app-mamawork.md)
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
- [../secrets.md](../secrets.md)

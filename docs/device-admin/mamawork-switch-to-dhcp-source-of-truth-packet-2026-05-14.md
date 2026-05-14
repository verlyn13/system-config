---
title: MAMAWORK Host-Static-to-DHCP Source-Of-Truth Packet - 2026-05-14
category: operations
component: device_admin
status: prepared-optional
version: 0.1.0
last_updated: 2026-05-14
tags: [device-admin, mamawork, windows, dhcp, networking, optional]
priority: medium
---

# MAMAWORK Host-Static-to-DHCP Source-Of-Truth Packet - 2026-05-14

This is an **optional** packet that switches MAMAWORK from a
Windows-side static IP configuration to DHCP. After the switch, the
OPNsense static reservation (already bound for MAC
`B0-41-6F-0E-B7-B6` -> `192.168.0.101`) becomes the single source of
truth for MAMAWORK's address. That allows the OPNsense ISC static-ARP
defense layer to activate (which it cannot do today because MAMAWORK
is using a host-side static IP rather than leasing the address from
OPNsense).

This packet is **intentionally separate** from the
[MAMAWORK Windows-side SSH investigation packet](./mamawork-ssh-investigation-packet-2026-05-14.md)
and from any future SSH-remediation packet. Switching the IP-source-of-
truth carries a small reconnect risk; bundling it with SSH debugging
would conflate two failure modes.

Preparation only. No live change is authorized by approving this
document.

## Scope

In scope (when approved live, future packet):

- On MAMAWORK, change the IPv4 configuration on the active wired
  Ethernet adapter (`Ethernet 2`) from **manual / static** to
  **DHCP-assigned**, including:
  - IPv4 address: stop setting `192.168.0.101` host-side; obtain
    via DHCP (OPNsense will return the same address via the
    existing reservation).
  - IPv4 gateway: stop setting `192.168.0.1` host-side; obtain via
    DHCP.
  - IPv4 DNS: switch from manual `8.8.8.8 / 8.8.4.4` to
    DHCP-supplied DNS (OPNsense Unbound, `192.168.0.1`).
- Confirm post-switch that the address came from OPNsense (lease
  visible in OPNsense, ARP entry becomes `permanent=true`).
- Confirm LAN reachability after the switch:
  - `mamawork.home.arpa` still resolves to `192.168.0.101`.
  - SSH/RDP/Defender posture is unchanged on the host.
  - Outbound resolution still works.

Out of scope (separate packets, or out of `system-config` authority):

- Any OPNsense / HomeNetOps change. The OPNsense reservation
  already exists; this packet does not modify it. If the operator
  wants the reservation modified, that is a separate HomeNetOps
  request.
- Any SSH service / sshd_config / firewall / authorized_keys
  change. The SSH investigation packet covers that. This packet
  intentionally does not bundle SSH debugging.
- IPv6 address configuration. The 2026-05-13 intake showed IPv6
  link-local only on the wired interface; no change here.
- Switching to a different DNS suffix or DNS resolver beyond what
  OPNsense returns.
- Wi-Fi changes. The wired interface is the primary admin path.
- Adding or removing accounts, group memberships, RDP, WinRM,
  Tailscale, WARP, cloudflared, 1Password items.

## Why It Matters

| Today (host-static) | After (DHCP) |
|---|---|
| Address is assigned by Windows network config; OPNsense reservation is informational | Address is leased from OPNsense; reservation is authoritative |
| `arp permanent=false` on `LAN/igc1`: OPNsense ISC static-ARP defense **does not** activate | `arp permanent=true`: OPNsense binds the L2/L3 pair at the appliance; a host that tries to impersonate `192.168.0.101` is rejected at the appliance |
| If MAMAWORK's host-static config drifts (different IP, different gateway, different DNS) it goes unnoticed by OPNsense | OPNsense is the single point of truth; drift is impossible because the host gets its values from DHCP |
| DNS resolvers point at Google (`8.8.8.8 / 8.8.4.4`) by manual config | DNS resolvers come from OPNsense Unbound, which gives MAMAWORK the same split-DNS view the rest of the LAN sees |
| Small chance of address conflict if a future device is misconfigured | OPNsense conflict detection works correctly because OPNsense knows all the leases |

The change is a small but real defense-in-depth improvement.

## Why It Is Optional / Risk

- The switch happens on the wired adapter while the operator is
  using that wired adapter for remote administration. There is a
  brief window where the adapter renegotiates and the operator may
  see a single SSH/RDP session drop.
- If the DHCP lease for some reason fails to return `192.168.0.101`
  (for example: reservation accidentally removed, ARP cache stale on
  appliance, lease-time interaction), MAMAWORK could end up on a
  different RFC1918 address or briefly without one.
- The intake's WoL configuration is on the wired NIC; the switch to
  DHCP should not change WoL behavior, but it should be re-verified
  after the switch.
- Rollback is to restore the host-static config the way it was at
  pre-apply (the snapshot below captures it exactly), which is
  simple but adds another reconnect.

For these reasons the packet is **not bundled with anything that is
itself sensitive to a brief connectivity drop**. In particular it is
not bundled with the SSH investigation packet, the SSH key bootstrap
packet, or the privilege cleanup packet. Each of those should be
applied first or after, never during.

## Verified Current State

From the 2026-05-13 intake (file paths under `windows-pc-mamawork.md`
"Network Identity"):

```text
Wired interface:        Ethernet 2 (Realtek PCIe GbE, Up @ 1 Gbps)
Wired MAC:              B0-41-6F-0E-B7-B6
IPv4 address:           192.168.0.101/24  (DHCP Enabled = No; manual)
Default gateway:        192.168.0.1
IPv4 DNS:               8.8.8.8, 8.8.4.4  (manual)
Connection DNS suffix:  home.arpa
Network category:       Private
```

OPNsense state from the 2026-05-14 HomeNetOps PASS hand-back:

```text
Static DHCP reservation:  B0-41-6F-0E-B7-B6 -> 192.168.0.101 (bound)
Unbound override:         mamawork.home.arpa -> 192.168.0.101
ARP permanent:            false (because MAMAWORK is using host-side
                                  static IP, OPNsense did not assign
                                  the address)
```

The OPNsense reservation is what makes this packet safe: the
DHCP-assigned address will be the same `192.168.0.101` MAMAWORK has
today.

## Apply Sequence (proposed; not authorised by this preparation)

The future live apply does the following from an **elevated**
PowerShell session on MAMAWORK. The operator should plan for the
brief disconnect described above (use a local console / KVM /
nearby session, not the remote SSH session being debugged).

### Step 1 - Snapshot pre-apply config

```powershell
$Root = 'C:\Users\Public\Documents\jefahnierocks-device-admin'
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$OutDir = Join-Path $Root "mamawork-static-to-dhcp-$Timestamp"
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

Get-NetAdapter -Physical |
  Select-Object Name, Status, LinkSpeed, MacAddress, InterfaceDescription |
  Export-Csv -Path "$OutDir/netadapter-before.csv" -NoTypeInformation

Get-NetIPConfiguration |
  Select-Object InterfaceAlias, IPv4Address, IPv6Address, DNSServer |
  Export-Csv -Path "$OutDir/ipconfig-before.csv" -NoTypeInformation

Get-NetIPAddress -AddressFamily IPv4 |
  Select-Object InterfaceAlias, IPAddress, PrefixLength, PrefixOrigin, SuffixOrigin, AddressState |
  Export-Csv -Path "$OutDir/ipaddress-before.csv" -NoTypeInformation

Get-NetRoute -AddressFamily IPv4 |
  Select-Object InterfaceAlias, DestinationPrefix, NextHop, RouteMetric |
  Export-Csv -Path "$OutDir/routes-before.csv" -NoTypeInformation

Get-DnsClientServerAddress -AddressFamily IPv4 |
  Select-Object InterfaceAlias, ServerAddresses |
  Export-Csv -Path "$OutDir/dns-before.csv" -NoTypeInformation
```

Returns the exact values to restore in rollback.

### Step 2 - Switch the wired adapter to DHCP

```powershell
$alias = 'Ethernet 2'   # verify against Step 1 before running

# Remove the static IPv4 binding
Remove-NetIPAddress -InterfaceAlias $alias -AddressFamily IPv4 -Confirm:$false
# Remove the manual default gateway
Remove-NetRoute -InterfaceAlias $alias -DestinationPrefix '0.0.0.0/0' -Confirm:$false -ErrorAction SilentlyContinue
# Set IPv4 to DHCP
Set-NetIPInterface -InterfaceAlias $alias -Dhcp Enabled
# Reset DNS to DHCP-supplied
Set-DnsClientServerAddress -InterfaceAlias $alias -ResetServerAddresses

# Trigger a fresh lease
ipconfig /release  $alias
ipconfig /renew    $alias
```

`Remove-NetIPAddress` and `Remove-NetRoute` will briefly remove the
LAN IPv4 binding before `Set-NetIPInterface ... -Dhcp Enabled` and
`ipconfig /renew` re-acquire the lease. Expect a 2-10 second
connectivity gap.

### Step 3 - Verify the lease came from OPNsense and is `.101`

```powershell
Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias $alias |
  Select-Object IPAddress, PrefixOrigin, SuffixOrigin

ipconfig /all | Select-String -Pattern "(IPv4|Default Gateway|DNS Servers|DHCP Server|Lease|Subnet)"
```

`PrefixOrigin` and `SuffixOrigin` must be `Dhcp`. `IPAddress` must
be `192.168.0.101`. `DHCP Server` must be `192.168.0.1` (OPNsense).
`DNS Servers` must include `192.168.0.1`.

### Step 4 - Verify LAN reachability and split DNS

```powershell
Resolve-DnsName mamawork.home.arpa | Select-Object Name, IPAddress
Test-NetConnection -ComputerName 192.168.0.1 -Port 53
```

`mamawork.home.arpa` must resolve to `192.168.0.101`.

From `fedora-top` (or any other LAN client), independently:

```bash
dig @192.168.0.1 mamawork.home.arpa +short          # expect 192.168.0.101
ping -c 2 192.168.0.101                              # may return - Windows ICMP may still drop, that is OK
```

### Step 5 - Verify OPNsense sees the lease as `permanent=true`

This step is HomeNetOps-side, not `system-config`-side. Either ask
HomeNetOps to confirm via the OPNsense UI / API / handback, or
include a brief confirmation in the apply record citing the
operator's view of the OPNsense ARP table for `LAN/igc1`.

Expected post-apply: ARP entry `192.168.0.101 b0:41:6f:0e:b7:b6 ...
permanent=true` on `LAN/igc1`.

### Step 6 - Rollback (if needed)

If the lease did not come back as `192.168.0.101`, or DNS broke, or
the operator decides to revert:

```powershell
$alias = 'Ethernet 2'
# Re-set the static IPv4 the way it was at pre-apply
New-NetIPAddress -InterfaceAlias $alias `
  -IPAddress 192.168.0.101 -PrefixLength 24 -DefaultGateway 192.168.0.1
Set-DnsClientServerAddress -InterfaceAlias $alias -ServerAddresses 8.8.8.8,8.8.4.4
Set-NetIPInterface -InterfaceAlias $alias -Dhcp Disabled
```

The exact values come from the Step 1 snapshot, not from this packet
text - use the snapshot in case anything in this packet is stale.

## Required Approval Phrase

```text
I approve applying the MAMAWORK host-static-to-DHCP source-of-truth
packet live now: from an elevated PowerShell session on MAMAWORK,
snapshot the current Get-NetAdapter / Get-NetIPConfiguration /
Get-NetIPAddress / Get-NetRoute / Get-DnsClientServerAddress output
to C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-
static-to-dhcp-<timestamp>; on the wired adapter "Ethernet 2",
Remove-NetIPAddress for the IPv4 binding, Remove-NetRoute for the
0.0.0.0/0 default route, Set-NetIPInterface -Dhcp Enabled,
Set-DnsClientServerAddress -ResetServerAddresses,
ipconfig /release + /renew; verify PrefixOrigin/SuffixOrigin is
Dhcp, IPAddress is 192.168.0.101, DHCP Server is 192.168.0.1, DNS
includes 192.168.0.1, Resolve-DnsName mamawork.home.arpa returns
192.168.0.101, and Test-NetConnection 192.168.0.1:53 succeeds;
roll back to the snapshot values if anything fails. Do not touch
sshd, sshd_config, authorized_keys, Windows Firewall, RDP, WinRM,
network profile category, accounts, groups, BitLocker, Secure
Boot, TPM, Tailscale, WARP, cloudflared, Cloudflare, OPNsense
(beyond observing the resulting lease), or 1Password.
```

## Evidence Template

```text
timestamp:
operator:
elevation: yes/no
snapshot path:
pre-apply IPv4 / gateway / DNS values:
post-apply PrefixOrigin / SuffixOrigin (must be Dhcp):
post-apply IPAddress (must be 192.168.0.101):
post-apply DHCP Server (must be 192.168.0.1):
post-apply DNS Servers list:
Resolve-DnsName mamawork.home.arpa:
OPNsense ARP for LAN/igc1 (HomeNetOps confirms permanent=true): yes/no
rollback used: yes/no
remaining blockers:
```

## Related

- [mamawork-homenetops-lan-identity-2026-05-14.md](./mamawork-homenetops-lan-identity-2026-05-14.md) -
  records the host-static-vs-DHCP gap this packet closes.
- [windows-pc-mamawork.md](./windows-pc-mamawork.md)
- [handoff-mamawork.md](./handoff-mamawork.md)
- [mamawork-ssh-investigation-packet-2026-05-14.md](./mamawork-ssh-investigation-packet-2026-05-14.md) -
  intentionally separate packet so SSH debugging and IP-source-of-
  truth changes never share a maintenance window.
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
- [../secrets.md](../secrets.md)

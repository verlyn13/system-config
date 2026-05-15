---
title: MAMAWORK Inbound TCP Blackhole Remediation Packet - 2026-05-14
category: operations
component: device_admin
status: applied
version: 0.2.0
last_updated: 2026-05-14
tags: [device-admin, mamawork, windows, firewall, network-identity, rdp, ssh, lan]
priority: high
---

> **2026-05-14 v0.2.0 changes**: applied live 2026-05-14T14:47:40
> AKDT (Option B); see
> [mamawork-inbound-tcp-blackhole-remediation-apply-2026-05-14.md](./mamawork-inbound-tcp-blackhole-remediation-apply-2026-05-14.md).
> One packet bug fixed in the Phase 1 + Phase 2 PowerShell blocks:
> `Write-Evidence` previously declared `param([string]$Message)`
> without `[Parameter(ValueFromPipeline=$true)]`, so the documented
> `Format-List | Out-String | Write-Evidence` calls silently
> dropped the piped state body and captured only the literal
> `Write-Evidence "header"` calls. Function now declares
> `ValueFromPipeline=$true` with a `process` block. Same bug is
> present in
> [mamawork-lan-rdp-implementation-2026-05-14.md](./mamawork-lan-rdp-implementation-2026-05-14.md)
> and patched there in its own v0.3.0 bump.

# MAMAWORK Inbound TCP Blackhole Remediation Packet - 2026-05-14

Closes the LAN-inbound-TCP blackhole identified by the
[2026-05-14 Phase-1 + Phase-4 diagnostic](./mamawork-lan-rdp-implementation-apply-2026-05-14.md)
on MAMAWORK. Two issues are addressed:

1. **Network-identity drift** (primary, blocks RDP/SMB/everything).
   The live wired binding on `Ethernet 2` is classified `Public`
   under an ephemeral `Unidentified network` profile that matches
   NEITHER of the two stored registry profiles for this LAN. All
   `Jefahnierocks RDP LAN` rules are scoped `Profile=Private`, so
   every inbound TCP probe is blocked by the default-deny on the
   Public profile.
2. **`Dad Remote Management` SSH rule's narrow `RemoteAddress`**
   (`192.168.0.200`, which is not the fedora-top IP). The rule's
   `Profile=Any` means it would have allowed SSH on Public too, but
   only from `.200` - so even after the network-identity fix, SSH
   from fedora-top (`192.168.0.206`) and the MacBook still won't
   reach MAMAWORK without an additional rule change.

Operator-applied on MAMAWORK from an elevated PowerShell 7+
session. No `system-config` host change is authorized by approving
this document; the operator executes the procedure on MAMAWORK
directly and returns a non-secret summary.

Hard boundary preserved: **no public WAN administrative exposure**.
All rules remain LAN-only and Private-profile-only after this
remediation.

## Scope

In scope:

- Reclassify the live wired binding on the `Ethernet 2` adapter to
  `NetworkCategory=Private` via `Set-NetConnectionProfile`. This is
  the immediate fix for the LAN blackhole; it does NOT modify the
  stored "Bob's Internet" or "Bob's Internet 2" registry profiles.
- One of two operator-selected SSH rule changes (**Option A** or
  **Option B**, explained below).
- Snapshot relevant state before and after, including the live
  connection profile, the firewall rules touching TCP/22 + TCP/3389,
  and the per-interface listener bindings.
- Evidence captured to
  `C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-inbound-blackhole-remediation-<timestamp>.txt`.

Out of scope:

- Editing or deleting the stored `NetworkList\Profiles\{...}`
  registry entries (the stale `Bob's Internet 2` Public profile).
  Registry cleanup is destructive; a separate future packet
  (`mamawork-network-list-registry-cleanup-packet`) addresses
  whether to rename/delete the dormant profile and how to prevent
  future drift.
- Investigating WHY identification drifted in the first place (PIA
  VPN uninstall residue, periodic DnsSuffix toggling, OPNsense DHCP
  options, etc.). The fix here closes the symptom; the root-cause
  analysis is the next step IF drift recurs.
- Any `sshd_config`, `administrators_authorized_keys`, or
  `authorized_keys` change. Those are the separate
  [mamawork-ssh-key-bootstrap packet (2026-05-14)](./mamawork-ssh-key-bootstrap-packet-2026-05-14.md)
  and a future `mamawork-ssh-hardening` packet.
- Cloudflare, WARP, Tunnel, Access, OPNsense, DNS, DHCP, 1Password,
  WinRM, BitLocker, Secure Boot, Defender, ASR.
- Switching MAMAWORK from host-static IP to DHCP - separate
  [mamawork-switch-to-dhcp-source-of-truth packet (2026-05-14)](./mamawork-switch-to-dhcp-source-of-truth-packet-2026-05-14.md).
- Touching the broad `Remote Assistance (DCOM-In)` rule
  (`Profile=Domain`, port 135), which is dormant in this household
  (no domain join) and harmless.
- WoL per-device wake policy
  (`powercfg /deviceenablewake "Ethernet 2"`) - separate small
  follow-up packet after this remediation lands.

## Verified Current State (from 2026-05-14 diagnostic)

```text
hostname:                 MAMAWORK
adapter:                  Ethernet 2  (InterfaceIndex 9)
adapter MAC:              B0-41-6F-0E-B7-B6
wired IPv4:               192.168.0.101/24
gateway:                  192.168.0.1 (gateway MAC e8:ff:1e:d2:49:c8)

live profile (the bug):
  InterfaceAlias          Ethernet 2
  Name                    "Unidentified network"
  NetworkCategory         Public            <-- root cause
  IPv4Connectivity        Internet
  live InstanceID         {65CC43CF-...}    <-- matches neither stored profile

stored registry profiles for this LAN
(HKLM:\Software\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles\):
  {8854EE83-...}  ProfileName "Bob's Internet"    Category 1 (Private)
                  Signature   first match on gateway MAC, last byte 08000000
                  Created     2024-09-09
                  LastConn    2026-05-14
  {3A38DDB2-...}  ProfileName "Bob's Internet 2"  Category 0 (Public)
                  Signature   first match on gateway MAC, last byte 08040000
                  Created     2025-05-14
                  LastConn    2026-05-14
  (live binding signature matches NEITHER of the above)

listener health:
  TCP/22    sshd  binding 0.0.0.0:22  AND [::]:22  - running
  TCP/3389  svchost (TermService)     0.0.0.0:3389 AND [::]:3389 - running
  TCP/445   System server             0.0.0.0:445  AND [::]:445  - running

inbound rules (enabled, LAN-relevant):
  "Jefahnierocks RDP LAN TCP 3389"  Allow  Private  TCP 3389   192.168.0.0/24
  "Jefahnierocks RDP LAN UDP 3389"  Allow  Private  UDP 3389   192.168.0.0/24
  "Dad Remote Management"           Allow  Any      TCP 22     RemoteAddress=192.168.0.200
  Remote Assistance (DCOM-In)       Allow  Domain   TCP 135    Any

enabled inbound Block rules: 2
  both are program-scoped to Reolink \Camera\rqd.exe; not LAN-relevant.

net effect on this LAN with NetworkCategory=Public:
  RDP/3389 from LAN     -> dropped (rule is Private-only)
  SMB/445 from LAN      -> dropped (no Private-or-Any rule)
  RPC/135 from LAN      -> dropped (Domain-only rule)
  SSH/22 from LAN       -> dropped UNLESS source is 192.168.0.200
  every LAN probe       -> default-deny / inbound
```

The diagnostic captured these facts on
`2026-05-14T<diagnostic-timestamp>` from the operator's
`mamawork-inbound-blackhole-diagnostic-<timestamp>.txt` evidence
file. The block on RDP and the block on SSH come from the same
underlying cause; fixing the live binding's `NetworkCategory`
restores RDP/SMB immediately, and the SSH rule change (Option A or
B below) restores SSH.

## The Two SSH Rule Options

The network-identity reclassification alone unblocks RDP and SMB.
SSH still needs ONE of the following operator-selected changes to
also work from fedora-top and MacBook.

### Option A: Widen the existing `Dad Remote Management` rule

Modify in place: set `RemoteAddress` from `192.168.0.200` to
`192.168.0.0/24`, set `Profile` from `Any` to `Private`.

Pros:

- Single SSH rule; no duplicates.
- Keeps the existing rule's name/intent traceable to its history.

Cons:

- Mutates a rule whose original author / intent the operator does
  not currently recall (per the diagnostic). Modifying it loses
  that history.
- The `mamawork-ssh-hardening` packet later may want a different
  name/structure for this rule, so this in-place edit may be
  re-edited again.

### Option B (recommended): Add a new `Jefahnierocks SSH LAN TCP 22` rule

Create new rule mirroring the RDP rule naming pattern:

```text
DisplayName    Jefahnierocks SSH LAN TCP 22
Direction      Inbound
Action         Allow
Enabled        True
Profile        Private
Protocol       TCP
LocalPort      22
RemoteAddress  192.168.0.0/24
Description    Allow SSH from trusted home LAN only for
               Jefahnierocks administration of MAMAWORK.
```

Leave `Dad Remote Management` untouched.

Pros:

- Mirrors the working `Jefahnierocks RDP LAN TCP 3389` rule
  pattern - easy to reason about as a pair.
- Additive only. Rollback is removing one named rule with no
  effect on the existing `Dad Remote Management` rule.
- Preserves the existing rule's audit trail; the
  `mamawork-ssh-hardening` packet can decide later whether to
  disable/remove the legacy rule deliberately.
- Lower blast radius if the legacy rule turns out to have been
  scoped to `.200` for an intentional purpose we have not yet
  recalled.

Cons:

- Two SSH inbound rules co-exist on the host until
  `mamawork-ssh-hardening` consolidates them. The narrow legacy
  rule is dead (no host on the LAN currently uses `.200`), so this
  duplication is logical noise, not a functional risk.

**This packet recommends Option B.** It is additive, mirrors the
RDP rule pattern, and leaves the SSH-hardening packet free to make
the final consolidation decision deliberately. The operator picks
A or B when quoting the approval phrase.

## Elevated Windows PowerShell Script - Phase 1 (Required)

Run from an Administrator PowerShell 7+ session on MAMAWORK. This
phase is **required**; it closes the LAN blackhole for RDP and SMB.

```powershell
# Jefahnierocks MAMAWORK inbound TCP blackhole remediation - Phase 1
# Network-identity reclassification on live Ethernet 2 binding.
# Run from Administrator PowerShell 7+ on MAMAWORK.

$ErrorActionPreference = 'Stop'

$ExpectedHostname = 'MAMAWORK'
$TrustedLan = '192.168.0.0/24'
$ExpectedWiredMac = 'B0-41-6F-0E-B7-B6'
$EvidenceDir = 'C:\Users\Public\Documents\jefahnierocks-device-admin'
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$EvidencePath = Join-Path $EvidenceDir "mamawork-inbound-blackhole-remediation-$Timestamp.txt"

New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

function Write-Evidence {
  # Pipeline-aware (v0.2.0): the documented call sites use
  # `... | Format-List | Out-String | Write-Evidence`, which only
  # captures the piped state body if $Message has ValueFromPipeline.
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline = $true, Position = 0)]
    [AllowEmptyString()]
    [AllowNull()]
    [string]$Message
  )
  process {
    Add-Content -Path $EvidencePath -Value $Message
    Write-Host $Message
  }
}

Write-Evidence "timestamp: $(Get-Date -Format o)"
Write-Evidence "scope: MAMAWORK inbound TCP blackhole remediation, Phase 1 network-identity, no secrets"
Write-Evidence "hostname: $(hostname)"

if ((hostname) -ne $ExpectedHostname) {
  throw "Unexpected hostname. Expected $ExpectedHostname."
}

$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
  [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $IsAdmin) {
  throw 'This script must run from Administrator PowerShell.'
}

$Adapter = Get-NetAdapter -Physical |
  Where-Object { $_.MacAddress -eq $ExpectedWiredMac -and $_.Status -eq 'Up' } |
  Select-Object -First 1

if (-not $Adapter) {
  throw "Expected wired adapter $ExpectedWiredMac is not up."
}

$IPv4 = Get-NetIPAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv4 |
  Where-Object { $_.IPAddress -like '192.168.0.*' } |
  Select-Object -First 1

if (-not $IPv4) {
  throw 'Expected 192.168.0.0/24 Ethernet IPv4 address was not found.'
}

Write-Evidence "wired_adapter: $($Adapter.Name) ifIndex=$($Adapter.ifIndex) $($Adapter.MacAddress) $($Adapter.LinkSpeed)"
Write-Evidence "wired_ipv4: $($IPv4.IPAddress)/$($IPv4.PrefixLength)"

# ---- PRE-STATE ----

Write-Evidence ''
Write-Evidence 'pre_state_connection_profile:'
Get-NetConnectionProfile -InterfaceIndex $Adapter.ifIndex |
  Select-Object Name, InterfaceAlias, NetworkCategory, IPv4Connectivity, IPv6Connectivity |
  Format-List |
  Out-String |
  Write-Evidence

Write-Evidence 'pre_state_listener_22_3389_445:'
Get-NetTCPConnection -State Listen |
  Where-Object { $_.LocalPort -in 22, 3389, 445 } |
  Select-Object LocalAddress, LocalPort, State, OwningProcess |
  Format-Table -AutoSize |
  Out-String |
  Write-Evidence

Write-Evidence 'pre_state_inbound_rules_for_22_and_3389:'
$relevant = @('Jefahnierocks RDP LAN TCP 3389',
              'Jefahnierocks RDP LAN UDP 3389',
              'Dad Remote Management',
              'Jefahnierocks SSH LAN TCP 22')
foreach ($name in $relevant) {
  $rule = Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue
  if ($null -ne $rule) {
    Write-Evidence "rule_present: $name"
    $rule | Select-Object DisplayName, Enabled, Direction, Action, Profile |
      Format-List | Out-String | Write-Evidence
    $rule | Get-NetFirewallPortFilter |
      Format-Table -AutoSize | Out-String | Write-Evidence
    $rule | Get-NetFirewallAddressFilter |
      Format-Table -AutoSize | Out-String | Write-Evidence
  } else {
    Write-Evidence "rule_absent: $name"
  }
}

# ---- APPLY: Reclassify live binding to Private ----

Write-Evidence ''
Write-Evidence 'apply_phase_1_set_network_category_to_private:'
Set-NetConnectionProfile -InterfaceIndex $Adapter.ifIndex -NetworkCategory Private

# ---- POST-STATE ----

Write-Evidence ''
Write-Evidence 'post_state_connection_profile:'
Get-NetConnectionProfile -InterfaceIndex $Adapter.ifIndex |
  Select-Object Name, InterfaceAlias, NetworkCategory, IPv4Connectivity, IPv6Connectivity |
  Format-List |
  Out-String |
  Write-Evidence

Write-Evidence 'post_state_listener_22_3389_445:'
Get-NetTCPConnection -State Listen |
  Where-Object { $_.LocalPort -in 22, 3389, 445 } |
  Select-Object LocalAddress, LocalPort, State, OwningProcess |
  Format-Table -AutoSize |
  Out-String |
  Write-Evidence

Write-Evidence ''
Write-Evidence "status: completed MAMAWORK inbound blackhole remediation Phase 1"
Write-Evidence "evidence_file: $EvidencePath"

Write-Host ''
Write-Host "Phase 1 complete. RDP and SMB should now be reachable from the LAN."
Write-Host "Run Phase 2 (Option A or B) to also restore SSH from fedora-top + MacBook."
```

## Elevated Windows PowerShell Script - Phase 2 (Operator Picks A or B)

After Phase 1 succeeds, the operator runs **exactly one** of the
following blocks. Both extend the same evidence file written by
Phase 1.

### Phase 2 - Option A: Widen `Dad Remote Management`

```powershell
$EvidenceDir = 'C:\Users\Public\Documents\jefahnierocks-device-admin'
$EvidencePath = (Get-ChildItem -Path $EvidenceDir -Filter 'mamawork-inbound-blackhole-remediation-*.txt' |
  Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName

function Write-Evidence {
  # Pipeline-aware (v0.2.0): the documented call sites use
  # `... | Format-List | Out-String | Write-Evidence`, which only
  # captures the piped state body if $Message has ValueFromPipeline.
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline = $true, Position = 0)]
    [AllowEmptyString()]
    [AllowNull()]
    [string]$Message
  )
  process {
    Add-Content -Path $EvidencePath -Value $Message
    Write-Host $Message
  }
}

Write-Evidence ''
Write-Evidence 'apply_phase_2_option_A_widen_dad_remote_management:'

Set-NetFirewallRule -DisplayName 'Dad Remote Management' -Profile Private
Get-NetFirewallRule -DisplayName 'Dad Remote Management' |
  Get-NetFirewallAddressFilter |
  Set-NetFirewallAddressFilter -RemoteAddress '192.168.0.0/24'

Write-Evidence 'post_state_dad_remote_management:'
$r = Get-NetFirewallRule -DisplayName 'Dad Remote Management'
$r | Select-Object DisplayName, Enabled, Direction, Action, Profile |
  Format-List | Out-String | Write-Evidence
$r | Get-NetFirewallPortFilter |
  Format-Table -AutoSize | Out-String | Write-Evidence
$r | Get-NetFirewallAddressFilter |
  Format-Table -AutoSize | Out-String | Write-Evidence

Write-Evidence ''
Write-Evidence 'status: completed MAMAWORK inbound blackhole remediation Phase 2 Option A'
```

### Phase 2 - Option B (recommended): Add new `Jefahnierocks SSH LAN TCP 22` rule

```powershell
$EvidenceDir = 'C:\Users\Public\Documents\jefahnierocks-device-admin'
$EvidencePath = (Get-ChildItem -Path $EvidenceDir -Filter 'mamawork-inbound-blackhole-remediation-*.txt' |
  Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName

function Write-Evidence {
  # Pipeline-aware (v0.2.0): the documented call sites use
  # `... | Format-List | Out-String | Write-Evidence`, which only
  # captures the piped state body if $Message has ValueFromPipeline.
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline = $true, Position = 0)]
    [AllowEmptyString()]
    [AllowNull()]
    [string]$Message
  )
  process {
    Add-Content -Path $EvidencePath -Value $Message
    Write-Host $Message
  }
}

Write-Evidence ''
Write-Evidence 'apply_phase_2_option_B_add_jefahnierocks_ssh_lan_rule:'

# Idempotent: remove any prior occurrence of the same DisplayName first.
Get-NetFirewallRule -DisplayName 'Jefahnierocks SSH LAN TCP 22' -ErrorAction SilentlyContinue |
  Remove-NetFirewallRule

New-NetFirewallRule `
  -DisplayName 'Jefahnierocks SSH LAN TCP 22' `
  -Direction Inbound `
  -Action Allow `
  -Enabled True `
  -Profile Private `
  -Protocol TCP `
  -LocalPort 22 `
  -RemoteAddress '192.168.0.0/24' `
  -Description 'Allow SSH from trusted home LAN only for Jefahnierocks administration of MAMAWORK.'

Write-Evidence 'post_state_jefahnierocks_ssh_lan_tcp_22:'
$r = Get-NetFirewallRule -DisplayName 'Jefahnierocks SSH LAN TCP 22'
$r | Select-Object DisplayName, Enabled, Direction, Action, Profile |
  Format-List | Out-String | Write-Evidence
$r | Get-NetFirewallPortFilter |
  Format-Table -AutoSize | Out-String | Write-Evidence
$r | Get-NetFirewallAddressFilter |
  Format-Table -AutoSize | Out-String | Write-Evidence

Write-Evidence 'post_state_dad_remote_management_left_unchanged:'
$r = Get-NetFirewallRule -DisplayName 'Dad Remote Management'
$r | Select-Object DisplayName, Enabled, Direction, Action, Profile |
  Format-List | Out-String | Write-Evidence
$r | Get-NetFirewallAddressFilter |
  Format-Table -AutoSize | Out-String | Write-Evidence

Write-Evidence ''
Write-Evidence 'status: completed MAMAWORK inbound blackhole remediation Phase 2 Option B'
```

## LAN-Side Verification (From fedora-top And MacBook)

After Phase 1 + Phase 2 complete, run the same probe set the
diagnostic used. Expect all four to succeed.

```bash
# From MacBook (any 192.168.0.0/24 host):
nc -vz -G 3 192.168.0.101 3389
nc -vz -G 3 mamawork.home.arpa 3389
nc -vz -G 3 192.168.0.101 22
nc -vz -G 3 mamawork.home.arpa 22

# From fedora-top:
nc -vz -w 3 192.168.0.101 3389
nc -vz -w 3 192.168.0.101 22
```

The full success criteria:

| Probe | Pass criterion | Phase that fixed it |
|---|---|---|
| TCP/3389 from MacBook | succeeded | Phase 1 |
| TCP/3389 from fedora-top | succeeded | Phase 1 |
| TCP/22 from fedora-top | succeeded | Phase 2 (A or B) |
| TCP/22 from MacBook | succeeded | Phase 2 (A or B) |
| Windows App GUI from MacBook | full session | Phase 1 + RDP pkt |

SSH authentication will only succeed end-to-end after the
`mamawork-ssh-key-bootstrap` packet is applied (the new 1Password
admin key SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY must
be installed in `administrators_authorized_keys` first). The
key-bootstrap and this remediation are independent and can be
applied in either order on MAMAWORK locally.

## Rollback

### Rollback Phase 2 Option A

```powershell
# Restore Dad Remote Management to its prior Profile=Any +
# RemoteAddress=192.168.0.200 form.
Set-NetFirewallRule -DisplayName 'Dad Remote Management' -Profile Any
Get-NetFirewallRule -DisplayName 'Dad Remote Management' |
  Get-NetFirewallAddressFilter |
  Set-NetFirewallAddressFilter -RemoteAddress '192.168.0.200'
```

### Rollback Phase 2 Option B

```powershell
Get-NetFirewallRule -DisplayName 'Jefahnierocks SSH LAN TCP 22' -ErrorAction SilentlyContinue |
  Remove-NetFirewallRule
```

### Rollback Phase 1 (re-classify back to Public)

Not recommended - the live binding being Public was the bug. But
if the operator deliberately wants to revert:

```powershell
$Adapter = Get-NetAdapter -Physical |
  Where-Object { $_.MacAddress -eq 'B0-41-6F-0E-B7-B6' -and $_.Status -eq 'Up' } |
  Select-Object -First 1
Set-NetConnectionProfile -InterfaceIndex $Adapter.ifIndex -NetworkCategory Public
```

Reverting Phase 1 will re-enable the inbound TCP blackhole.

## Boundary Assertions (Post-Apply)

After this packet applies, the following remain **unchanged**:

- `sshd`, `sshd_config`,
  `C:\ProgramData\ssh\administrators_authorized_keys`,
  `C:\Users\DadAdmin\.ssh\authorized_keys`,
  `C:\Users\jeffr\.ssh\authorized_keys`,
  `C:\Users\jeffr\.ssh\authorized_keys.txt`. The SSH key bootstrap
  is a separate packet.
- `HKLM:\Software\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles\*`
  registry entries. The stale `Bob's Internet 2` Public profile
  remains for future deliberate cleanup.
- The Windows-default behavior when the network is unidentified
  (Public). The fix here is a one-shot live-binding reclassification;
  if Windows next time fails to match the stored Private profile,
  the operator may need to reclassify again. Recurrence becomes
  the trigger for the registry-cleanup packet.
- Cloudflare, WARP, `cloudflared`, Tailscale (retained logged out),
  OPNsense, DNS, DHCP, 1Password, WinRM, BitLocker, Secure Boot,
  TPM, Defender, ASR.
- Accounts, group memberships, the duplicate `DadAdmin.MamaWork`
  profile.
- Power-readiness state established by the RDP packet (`hibernate
  off`, AC sleep/hibernate 0, hybrid sleep 0, NIC wake properties
  Enabled).
- WoL per-device wake policy on `Ethernet 2` -
  `powercfg /deviceenablewake "Ethernet 2"` is a separate small
  follow-up packet, not in scope here.

## Required Approval Phrase

The operator quotes the approval phrase corresponding to their
chosen SSH option.

### If choosing Option A (widen `Dad Remote Management`)

```text
I approve applying the MAMAWORK inbound TCP blackhole remediation
packet live now on MAMAWORK using Option A (widen Dad Remote
Management). From an elevated PowerShell 7+ session as
MAMAWORK\<admin>, run Phase 1 (Set-NetConnectionProfile
-InterfaceIndex <Ethernet 2 ifIndex> -NetworkCategory Private) and
then Phase 2 Option A (Set-NetFirewallRule -DisplayName 'Dad
Remote Management' -Profile Private; Set-NetFirewallAddressFilter
-RemoteAddress 192.168.0.0/24 on that rule's address filter).
Snapshot pre-state and post-state for the live connection profile,
listener bindings on TCP 22 / 3389 / 445, and the four named
inbound rules. Write evidence to
C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-inbound-blackhole-remediation-<timestamp>.txt.
Do NOT touch sshd / sshd_config / authorized_keys, do NOT enable
WinRM or PSRemoting, do NOT change accounts/groups, do NOT enable
BitLocker or Secure Boot, do NOT touch Cloudflare / Tailscale /
WARP / cloudflared / OPNsense / DNS / DHCP / 1Password, do NOT
delete or modify any HKLM NetworkList\Profiles registry entry, do
NOT change powercfg or NIC wake state, do NOT switch from
host-static to DHCP. Then from MacBook + fedora-top verify
nc -vz 192.168.0.101 3389, nc -vz 192.168.0.101 22, nc -vz
mamawork.home.arpa 3389, nc -vz mamawork.home.arpa 22 all succeed.
```

### If choosing Option B (add `Jefahnierocks SSH LAN TCP 22`)

```text
I approve applying the MAMAWORK inbound TCP blackhole remediation
packet live now on MAMAWORK using Option B (add a new
Jefahnierocks SSH LAN TCP 22 rule). From an elevated PowerShell
7+ session as MAMAWORK\<admin>, run Phase 1 (Set-NetConnectionProfile
-InterfaceIndex <Ethernet 2 ifIndex> -NetworkCategory Private) and
then Phase 2 Option B (New-NetFirewallRule -DisplayName
'Jefahnierocks SSH LAN TCP 22' -Direction Inbound -Action Allow
-Enabled True -Profile Private -Protocol TCP -LocalPort 22
-RemoteAddress 192.168.0.0/24). Leave the Dad Remote Management
rule untouched. Snapshot pre-state and post-state for the live
connection profile, listener bindings on TCP 22 / 3389 / 445, and
the four named inbound rules. Write evidence to
C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-inbound-blackhole-remediation-<timestamp>.txt.
Do NOT touch sshd / sshd_config / authorized_keys, do NOT enable
WinRM or PSRemoting, do NOT change accounts/groups, do NOT enable
BitLocker or Secure Boot, do NOT touch Cloudflare / Tailscale /
WARP / cloudflared / OPNsense / DNS / DHCP / 1Password, do NOT
delete or modify any HKLM NetworkList\Profiles registry entry, do
NOT change powercfg or NIC wake state, do NOT switch from
host-static to DHCP. Then from MacBook + fedora-top verify
nc -vz 192.168.0.101 3389, nc -vz 192.168.0.101 22, nc -vz
mamawork.home.arpa 3389, nc -vz mamawork.home.arpa 22 all succeed.
```

## Evidence Template (Operator Hand-Back)

```text
timestamp:
operator:                                  MAMAWORK\<admin>
elevation:                                 yes/no
hostname:                                  MAMAWORK
wired_adapter:                             Ethernet 2 (ifIndex <n>)
wired_adapter_mac:                         B0-41-6F-0E-B7-B6
wired_ipv4:                                192.168.0.101/24

pre_apply_NetworkCategory:                 Public
pre_apply_profile_Name:                    Unidentified network
pre_apply_listener_22:                     LISTEN on 0.0.0.0:22 + [::]:22
pre_apply_listener_3389:                   LISTEN on 0.0.0.0:3389 + [::]:3389
pre_apply_listener_445:                    LISTEN on 0.0.0.0:445 + [::]:445
pre_apply_rule_jefahnierocks_rdp_lan_tcp:  Allow Private TCP 3389 192.168.0.0/24
pre_apply_rule_jefahnierocks_rdp_lan_udp:  Allow Private UDP 3389 192.168.0.0/24
pre_apply_rule_dad_remote_management:      Allow Any TCP 22 RemoteAddress=192.168.0.200
pre_apply_rule_jefahnierocks_ssh_lan_tcp:  absent

option_applied:                            A | B

post_apply_NetworkCategory:                Private
post_apply_listener_22:                    LISTEN on 0.0.0.0:22 + [::]:22 (unchanged)
post_apply_listener_3389:                  LISTEN on 0.0.0.0:3389 + [::]:3389 (unchanged)
post_apply_listener_445:                   LISTEN on 0.0.0.0:445 + [::]:445 (unchanged)
post_apply_rule_dad_remote_management:     <Option A: Allow Private TCP 22 192.168.0.0/24
                                            Option B: unchanged>
post_apply_rule_jefahnierocks_ssh_lan_tcp: <Option A: absent
                                            Option B: Allow Private TCP 22 192.168.0.0/24>

macbook_nc_192.168.0.101_3389:             Succeeded / Failed
macbook_nc_mamawork.home.arpa_3389:        Succeeded / Failed
macbook_nc_192.168.0.101_22:               Succeeded / Failed
macbook_nc_mamawork.home.arpa_22:          Succeeded / Failed
fedora_top_nc_192.168.0.101_3389:          Succeeded / Failed
fedora_top_nc_192.168.0.101_22:            Succeeded / Failed
windows_app_gui_from_macbook:              Succeeded / Failed / Not yet tested

evidence_file_path:                        C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-inbound-blackhole-remediation-<timestamp>.txt
credentials_in_repo_chat_argv:             None
remaining_blockers:
```

Do NOT paste passwords, saved credentials, RDP credential blobs,
Wi-Fi PSKs, browser data, BitLocker recovery material, or any
secret value into the hand-back.

## Sequencing With Other MAMAWORK Packets

This packet does NOT depend on (and is not blocked by):

- `mamawork-ssh-key-bootstrap-packet-2026-05-14.md` - independent;
  key bootstrap writes to `authorized_keys` files, not firewall or
  network profile. Can be applied in either order on MAMAWORK
  locally.
- `mamawork-switch-to-dhcp-source-of-truth-packet-2026-05-14.md` -
  approved-deferred-by-operator; remains deferred. After this
  remediation lands and LAN admin is stable, that DHCP packet may
  be scheduled.

This packet IS the prerequisite for:

- Reopening practical WoL testing (deferred in
  [mamawork-bios-wol-inspection-2026-05-14.md](./mamawork-bios-wol-inspection-2026-05-14.md);
  successful wake is only useful if SSH/RDP are reachable
  immediately after wake).
- The future `mamawork-nic-wake-enable-packet`
  (`powercfg /deviceenablewake "Ethernet 2"`).
- The future `mamawork-ssh-hardening` packet (which consolidates
  the SSH rule set, narrows `sshd_config`, and may remove the
  legacy `Dad Remote Management` rule if Option B was chosen here).

## Related

- [mamawork-lan-rdp-implementation-2026-05-14.md](./mamawork-lan-rdp-implementation-2026-05-14.md) -
  RDP packet that applied host-side-correct on 2026-05-14 but
  proved LAN-unreachable; this remediation closes that gap.
- [mamawork-lan-rdp-implementation-apply-2026-05-14.md](./mamawork-lan-rdp-implementation-apply-2026-05-14.md) -
  apply record where the LAN inbound TCP blackhole was first
  surfaced from two vantage points.
- [mamawork-ssh-investigation-packet-2026-05-14.md](./mamawork-ssh-investigation-packet-2026-05-14.md) -
  read-only investigation; the Phase 1 + Phase 4 outcomes from
  that investigation are the source of this remediation's
  verified state and verdict.
- [mamawork-ssh-key-bootstrap-packet-2026-05-14.md](./mamawork-ssh-key-bootstrap-packet-2026-05-14.md) -
  parallel packet; required to make SSH authentication work end
  to end after this remediation restores TCP/22 reachability.
- [mamawork-bios-wol-inspection-2026-05-14.md](./mamawork-bios-wol-inspection-2026-05-14.md) -
  BIOS posture; WoL practical tests are deferred until after this
  remediation.
- [windows-pc-mamawork.md](./windows-pc-mamawork.md)
- [current-status.yaml](./current-status.yaml)
- [handback-format.md](./handback-format.md)
- [../secrets.md](../secrets.md)

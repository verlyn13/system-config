---
title: MAMAWORK SSH + PowerShell Remote Administration Readiness - 2026-05-14
category: operations
component: device_admin
status: ready-for-ssh-driven-powershell
version: 0.3.0
last_updated: 2026-05-15
tags: [device-admin, mamawork, windows, openssh, powershell, remote-admin]
priority: high
---

# MAMAWORK SSH + PowerShell Remote Administration Readiness - 2026-05-14

This records readiness for the intended operating model:

```text
Primary admin lane:  MacBook -> SSH -> MAMAWORK as MAMAWORK\jeffr
Command model:       SSH transport, PowerShell commands/scripts
Credential model:    1Password SSH agent on the MacBook; no 1Password install on MAMAWORK
WinRM model:         Not primary; remains stopped/disabled by firewall
RDP model:           Secondary/fallback; works, but conflicts with active console session
Reusable spec:       windows-terminal-admin-spec.md
```

## Ready Now

SSH transport and auth are ready:

```text
MacBook real-auth verification:
  ssh ... jeffr@mamawork.home.arpa 'cmd /c "hostname && whoami"'
  returned:
    MamaWork
    mamawork\jeffr

Server-side conditional sshd verification:
  sshd.exe -T -C user=jeffr,host=mamawork.home.arpa,addr=127.0.0.1
  returns:
    pubkeyauthentication yes
    passwordauthentication no
    kbdinteractiveauthentication yes
    strictmodes no
    loglevel DEBUG3
    authorizedkeysfile __PROGRAMDATA__/ssh/administrators_authorized_keys
```

Service and listener state checked from MAMAWORK:

```text
sshd:        Running, Automatic, LocalSystem, PID 11844
TCP/22:      listening on 0.0.0.0:22 and [::]:22
TermService: Running, Automatic, NetworkService, PID 1876
TCP/3389:    listening on 0.0.0.0:3389 and [::]:3389
WinRM:       Stopped, Manual
ssh-agent:   Stopped, Disabled
```

Firewall posture:

```text
Jefahnierocks SSH LAN TCP 22:       Enabled=True, Profile=Private, TCP/22, RemoteAddress=192.168.0.0/24
Dad Remote Management:              Enabled=False, Profile=Any, TCP/22
Jefahnierocks RDP LAN TCP 3389:     Enabled=True, Profile=Private, TCP/3389, RemoteAddress=192.168.0.0/24
Jefahnierocks RDP LAN UDP 3389:     Enabled=True, Profile=Private, UDP/3389, RemoteAddress=192.168.0.0/24
Windows Remote Management rules:    Disabled
```

PowerShell availability:

```text
PowerShell 7:       7.6.1
pwsh.exe path:      C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.1.0_x64__8wekyb3d8bbwe\pwsh.exe
Windows PowerShell: C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe
```

Token/elevation proof from the MacBook terminal session on 2026-05-14:

```text
hostname=MAMAWORK
whoami=MamaWork\jeffr
is_admin_role=True
Mandatory Label\High Mandatory Level present
```

Practical explicit command pattern that was used before the short
`ssh mamawork` alias was applied:

```bash
ssh \
  -i ~/.ssh/id_ed25519_mamawork_admin.1password.pub \
  -o IdentityAgent="$HOME/.1password-ssh-agent.sock" \
  -o IdentitiesOnly=yes \
  -o PreferredAuthentications=publickey \
  -o BatchMode=yes \
  -o ConnectTimeout=5 \
  -o ControlMaster=no \
  -o ControlPath=none \
  -o HostKeyAlias=192.168.0.101 \
  jeffr@mamawork.home.arpa \
  'powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ProgressPreference = ''SilentlyContinue''; Get-Service sshd,TermService,WinRM | Select-Object Name,Status,StartType"'
```

For PowerShell 7 specifically, prefer an explicit command after the
MacBook SSH config is streamlined. This now works:

```bash
ssh mamawork \
  'pwsh -NoLogo -NoProfile -Command "$PSVersionTable.PSVersion; hostname; whoami"'
```

## Not Yet Ready: PowerShell Remoting Over SSH Subsystem

This host is not yet configured for native PowerShell remoting over SSH
using `Enter-PSSession -HostName` or `New-PSSession -HostName`.

Current `sshd_config` subsystem inventory:

```text
Subsystem sftp sftp-server.exe
```

There is no `Subsystem powershell ... -sshs` line yet.

Also, PowerShell 7 is currently reached through a WindowsApps package
path. That works for interactive `pwsh` discovery, but it is brittle
for an sshd subsystem because the package-version path can change:

```text
C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.1.0_x64__8wekyb3d8bbwe\pwsh.exe
```

Preferred future hardening/setup:

```text
1. Install or confirm MSI-style PowerShell 7 path:
   C:\Program Files\PowerShell\7\pwsh.exe

2. Add the PowerShell SSH subsystem:
   Subsystem powershell C:/Program Files/PowerShell/7/pwsh.exe -sshs -NoLogo -NoProfile

3. Validate from the MacBook:
   New-PSSession -HostName mamawork.home.arpa -UserName jeffr -SSHTransport
   Invoke-Command -HostName mamawork.home.arpa -UserName jeffr -ScriptBlock { hostname; whoami; $PSVersionTable.PSVersion }

4. Only after validation, decide whether to make PowerShell 7 the default SSH shell.
```

Do not use WinRM as the primary lane unless explicitly re-scoped. The
current posture intentionally keeps WinRM stopped and its firewall rules
disabled.

## Remaining Setup Before Declaring This The Primary Admin Model

1. The MacBook-side `macbook-ssh-conf-d-streamline` packet is applied.
   `ssh mamawork` now uses:

```text
Host mamawork mamawork.home.arpa 192.168.0.101
  User jeffr
  IdentityFile ~/.ssh/id_ed25519_mamawork_admin.1password.pub
  HostKeyAlias 192.168.0.101
```

The 2026-05-14 terminal trial showed broad `chezmoi diff` includes
unrelated local workstation drift. The SSH streamline was applied with
target-scoped `chezmoi apply --dry-run` and `chezmoi apply` for only
the three SSH targets. See
[macbook-ssh-conf-d-streamline-apply-2026-05-14.md](./macbook-ssh-conf-d-streamline-apply-2026-05-14.md)
and [windows-terminal-admin-spec.md](./windows-terminal-admin-spec.md).

2. Keep `RDP` available as fallback only. It works, but Windows 11 Pro
   prompts the active console user to log out; SSH is the concurrent
   admin lane.

3. Draft a small `mamawork-powershell-over-ssh-subsystem` packet if
   native PowerShell remoting sessions are wanted. That packet should
   install/confirm stable PowerShell 7, append the subsystem, run
   `sshd -t`, restart sshd, and validate from the MacBook.

4. Future `mamawork-ssh-hardening` should clean the stale DSA host-key
   reference, lower `LogLevel DEBUG3` to `INFO`, decide on `StrictModes`,
   decide on `AllowGroups`, and remove disabled legacy SSH surface.

## Boundary Notes

No live change was made by this readiness check. It did not touch:

```text
sshd_config
administrators_authorized_keys
per-user .ssh files
accounts or groups
ahnie
DadAdmin
RDP rules
WinRM service or firewall state
Cloudflare / WARP / DNS / DHCP / OPNsense
1Password items
```

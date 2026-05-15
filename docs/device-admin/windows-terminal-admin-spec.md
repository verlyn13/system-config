---
title: Windows Terminal Administration Spec
category: operations
component: device_admin
status: active
version: 0.3.0
last_updated: 2026-05-15
tags: [device-admin, windows, openssh, powershell, terminal-admin, evidence]
priority: high
---

# Windows Terminal Administration Spec

This is the operating spec for Windows administration from the MacBook
terminal. MAMAWORK is the first full SSH implementation, DESKTOP-2JJ3187
is the current RDP-only Windows peer, and future Windows PCs should follow
the same shape unless a packet records why they diverge.

## Authority

Authoritative state lives in:

- [current-status.yaml](./current-status.yaml)
- the per-device record, for example
  [windows-pc-mamawork.md](./windows-pc-mamawork.md)
- the shared Windows PC record
  [windows-pc.md](./windows-pc.md)
- the packet and apply records under `docs/device-admin/`

This spec defines procedure. It does not authorize a live change by itself.
Live host changes still require a scoped packet or a clearly approved terminal
session with evidence capture.

## Management Lanes

| Lane | Default posture | Notes |
|---|---|---|
| OpenSSH command execution | Primary terminal-admin lane | MacBook SSH client authenticates through the MacBook 1Password SSH agent. 1Password is not installed on the Windows host. |
| Explicit PowerShell over SSH | Primary command model | Invoke `powershell.exe` or `pwsh` explicitly through SSH. Do not assume the remote shell parses Unix-style syntax. |
| Native PowerShell remoting over SSH | Optional future lane | Requires an `sshd_config` `Subsystem powershell ... -sshs` line and a stable PowerShell 7 path. |
| WinRM / PSRemoting | Exception lane | Keep stopped and firewall-disabled unless a later packet names the need, source range, rollback, and validation. |
| RDP / Windows App | GUI fallback | Useful for interactive GUI work, but on Windows 11 Pro it can displace the active console user. Prefer SSH when another person is using the console. |
| Cloudflare WARP / Tunnel / Access | Future transport | Governed by `cloudflare-dns`; do not treat WARP enrollment as a substitute for local SSH correctness. |

## Fleet Standard

Windows hosts should be managed as a family of similar devices:

| Surface | Fleet default |
|---|---|
| Admin client | Operator MacBook first. Other clients require their own proof and key material. |
| Local transport | LAN or private-overlay OpenSSH for shell; LAN/private RDP for GUI fallback. No public WAN exposure. |
| SSH identity | One operator admin user per device and one device-scoped public key served by the MacBook 1Password SSH agent. |
| 1Password item naming | `op://Dev/jefahnierocks-device-<device>-admin-ssh-verlyn13` for SSH keys; `op://Dev/jefahnierocks-device-<device>-local-admin` for local admin credentials when created. |
| SSH client alias | `Host <device> <device>.home.arpa <ip>` with `User <approved-admin>`, `IdentityFile ~/.ssh/id_ed25519_<device>_admin.1password.pub`, and temporary `HostKeyAlias <ip>` until FQDN known_hosts reconciliation lands. |
| Windows OpenSSH admin keys | Administrators use `C:\ProgramData\ssh\administrators_authorized_keys` plus the standard `Match Group administrators` block. Do not rely on per-user admin `authorized_keys` files. |
| Firewall names | Prefer explicit `Jefahnierocks SSH LAN TCP 22` and `Jefahnierocks RDP LAN TCP/UDP 3389` rules scoped to Private profile and the approved LAN/private source range. |
| WinRM | Disabled by default across Windows hosts. |
| WARP on multi-user Windows | Prefer Cloudflare One Client Windows multi-user mode so admin/adult and kid profiles can differ per Windows account. |

Current fleet posture:

| Device | Current terminal-admin status | Next convergence step |
|---|---|---|
| MAMAWORK | SSH over LAN works from the MacBook as `MAMAWORK\jeffr`; `ssh mamawork` is streamlined and explicit PowerShell command execution is ready. | Continue with scoped read-only baselines and hardening packets. |
| DESKTOP-2JJ3187 | LAN RDP is verified; OpenSSH Server is intentionally not installed or active. | If shell administration is needed, draft a Windows OpenSSH packet that follows this spec rather than copying MAMAWORK artifacts blindly. |
| future Windows PC | Not onboarded. | Start from the intake/handoff pattern, then converge on this same lane naming, evidence, and stop rules. |

## Session Classes

Use these classes when naming packets, notes, and handbacks:

| Class | Examples | Evidence requirement |
|---|---|---|
| `read-only-probe` | `hostname`, `whoami`, service state, firewall reads, `sshd -T` | Record command, timestamp, target, and non-secret output if it changes status. |
| `scoped-live-change` | firewall rule add, `sshd_config` edit, account change, service restart | Packet required unless the operator explicitly approves the exact terminal action in-session. Include snapshot, apply, validation, and rollback or hard-stop semantics. |
| `workstation-config-change` | MacBook `~/.ssh/conf.d/` or public-key file under chezmoi | Use target-scoped `chezmoi diff` / dry-run / apply. Do not run a broad `chezmoi apply` when unrelated drift is present. |
| `gui-fallback` | RDP session for GUI-only settings | Record that the console-user impact was accepted. Do not save credentials in Windows App. |

## Preflight

Before a Windows terminal-admin session:

1. Read the device block in [current-status.yaml](./current-status.yaml).
2. Confirm the target path is the intended lane: LAN SSH, Cloudflare Access,
   or an explicitly approved fallback.
3. Confirm MacBook SSH client config with `ssh -G <host>` if using a short
   alias. If it does not show the intended `user`, `hostname`, `identityfile`,
   and `hostkeyalias`, use the explicit SSH option set instead.
4. Run a read-only identity proof before changing anything:

```bash
ssh <target> 'cmd /c "hostname && whoami"'
```

5. For elevated or admin-impacting work, also verify the Windows token from
   PowerShell:

```powershell
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
"hostname=$env:COMPUTERNAME"
"whoami=$($identity.Name)"
"is_admin_role=$($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))"
whoami /groups
```

Expect `is_admin_role=True` and `Mandatory Label\High Mandatory Level` before
running a change that requires an elevated token.

## SSH Client Rules

Until a host alias is proven with `ssh -G`, use an explicit command shape. For
MAMAWORK this is the verified form:

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
  'cmd /c "hostname && whoami"'
```

After a MacBook SSH conf.d packet applies, the short alias is usable only if
this parse check matches the packet:

```bash
ssh -G mamawork | grep -iE '^(user|identityfile|hostname|hostkeyalias)'
```

## Windows Command Rules

Always invoke the intended Windows shell explicitly.

For Windows PowerShell 5.1:

```bash
ssh <target> \
  'powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ProgressPreference = ''SilentlyContinue''; Get-Service sshd,TermService,WinRM | Select-Object Name,Status,StartType"'
```

For PowerShell 7:

```bash
ssh <target> \
  'pwsh -NoLogo -NoProfile -NonInteractive -Command "$PSVersionTable.PSVersion; hostname; whoami"'
```

For multi-line scripts, prefer `-EncodedCommand` generated locally from
UTF-16LE text. That avoids quoting bugs across zsh, ssh, the Windows default
shell, and PowerShell.

Set `$ProgressPreference = 'SilentlyContinue'` for evidence commands. The
first PowerShell module load can otherwise emit CLIXML progress records into
stdout, which is noisy but not a failure.

## Packet Standards For Live Changes

Every Windows live-change packet should have:

- exact scope and explicit out-of-scope list
- operator approval phrase
- preflight reads and a stop rule if preflight does not match the expected state
- snapshot of files, registry keys, service config, or rules it might change
- idempotent decision branch where possible
- `sshd -t` or equivalent syntax validation before restarting `sshd`
- hard-stop and rollback on validation failure
- post-apply read-back from the Windows host
- independent client-side proof from the MacBook when the change is about
  reachability or authentication
- clear statement of active-console impact, if any

Do not bundle unrelated risk classes. Network identity, firewall, SSH auth,
account cleanup, Cloudflare enrollment, BitLocker, and backup should be
separate packets unless there is a specific reason to join them.

## Evidence Writer Pattern

Use an evidence writer that handles pipeline input correctly. This exact bug
has already appeared in MAMAWORK packet work.

```powershell
function Write-Evidence {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [AllowEmptyString()]
    [string] $Message
  )

  process {
    Add-Content -LiteralPath $EvidencePath -Value $Message -Encoding utf8
  }
}
```

When capturing formatted objects, use `Out-String -Width 240` before
`Write-Evidence`. Do not write secrets, tokens, passwords, recovery keys, or
private-key material into evidence.

## Chezmoi Workstation Changes

MacBook-side setup is part of the admin lane, but it is still a live
workstation config change. Use target-scoped commands.

For the MAMAWORK/fedora-top SSH conf.d streamline:

```bash
chezmoi diff \
  ~/.ssh/conf.d/windows.conf \
  ~/.ssh/conf.d/fedora-top.conf \
  ~/.ssh/id_ed25519_mamawork_admin.1password.pub

chezmoi apply --dry-run \
  ~/.ssh/conf.d/windows.conf \
  ~/.ssh/conf.d/fedora-top.conf \
  ~/.ssh/id_ed25519_mamawork_admin.1password.pub

chezmoi apply \
  ~/.ssh/conf.d/windows.conf \
  ~/.ssh/conf.d/fedora-top.conf \
  ~/.ssh/id_ed25519_mamawork_admin.1password.pub
```

Do not use broad `chezmoi apply` for a device-admin packet when full
`chezmoi diff` includes unrelated local drift.

## Stop Rules

Stop and document rather than improvising if:

- `ssh -G` points at the wrong user, identity, host, or host-key alias
- the remote identity proof is not the expected hostname and Windows user
- admin/elevation proof is required but the token is not admin/high integrity
- `sshd -t` fails after an SSH config edit
- a firewall rule or network profile read-back differs from the planned target
- the command would modify `ahnie`, kid accounts, DadAdmin, BitLocker, WARP,
  Cloudflare, DNS, DHCP, OPNsense, or 1Password outside the current packet scope
- RDP would disrupt the active console user and that impact was not accepted

## First MAMAWORK Lessons

Captured during the first MacBook terminal-admin session on 2026-05-14
America/Anchorage / 2026-05-15 UTC:

- The MAMAWORK SSH server is usable from the MacBook with explicit options.
  `powershell.exe` returned version `5.1.26100.8457`, `hostname` returned
  `MamaWork`, and `whoami` returned `mamawork\jeffr`.
- `pwsh` is callable over SSH and reports PowerShell `7.6.1`.
- `sshd` and `TermService` are running automatic; `WinRM` is stopped manual.
- The Windows SSH session for `jeffr` has an admin/high-integrity token:
  `is_admin_role=True` and `Mandatory Label\High Mandatory Level`.
- Before the MacBook conf.d packet, `ssh mamawork` resolved to the default Mac
  user and default identity list. After
  [macbook-ssh-conf-d-streamline-apply-2026-05-14.md](./macbook-ssh-conf-d-streamline-apply-2026-05-14.md),
  it resolves to `jeffr`, `192.168.0.101`,
  `~/.ssh/id_ed25519_mamawork_admin.1password.pub`, and
  `HostKeyAlias 192.168.0.101`.
- A full `chezmoi diff` currently includes unrelated workstation drift outside
  the SSH packet. The MacBook SSH streamline must use target-scoped diff,
  dry-run, and apply.
- Windows OpenSSH command strings are not POSIX shell strings. Use `cmd /c` for
  simple Windows proof commands and invoke `powershell.exe` or `pwsh`
  explicitly for management.

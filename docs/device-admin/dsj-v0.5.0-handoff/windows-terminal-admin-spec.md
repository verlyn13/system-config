---
title: Windows Terminal Administration Spec
category: operations
component: device_admin
status: active
version: 0.5.0
last_updated: 2026-05-15
tags: [device-admin, windows, openssh, powershell, terminal-admin, evidence, lifecycle, packet-defect, encoding]
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

## Invariants And Future-State

### Invariants

These do not vary across Windows hosts in this fleet:

- **One operator admin user per device.** Do not share an admin identity
  across hosts. MAMAWORK uses `MAMAWORK\jeffr`; another host will have its
  own intentional admin account name.
- **One device-scoped 1Password SSH key per host.** The canonical item
  pattern is `op://Dev/jefahnierocks-device-<device>-admin-ssh-verlyn13`.
  Reusing a key across devices breaks rotation, incident scope, and the
  per-device audit trail.
- **Private key material stays in 1Password on the operator MacBook.** The
  private half is never installed on a managed Windows host. Only the public
  key body reaches Windows.
- **No public WAN exposure for SSH, RDP, WinRM, or any remote-admin
  service.** LAN or private-overlay only; Cloudflare Access in front of a
  Tunnel is the only sanctioned off-LAN path and is owned by `cloudflare-dns`.

### Future-State (Deferred)

These are intentionally out of scope for the current household-scale fleet.
They become candidate work only if the fleet scales materially or a
managed-device policy requires them:

- **Windows LAPS / Intune LAPS** for local admin password rotation. The
  current model is 1Password-held local admin credentials with manual
  rotation. LAPS is the right direction only if Entra/Intune is adopted.
- **Microsoft Entra / Intune join** for centralized policy and managed-device
  enrollment. Not justified at 2–3 devices.
- **Native PowerShell remoting over SSH subsystem** (Mode B,
  `New-PSSession -HostName ... -SSHTransport`). Mode A
  (`ssh host 'pwsh -Command ...'`) covers all current needs and avoids the
  WindowsApps-versioned `pwsh.exe` path stability problem.
- **Cloudflare Tunnel + Access for SSH** as the off-LAN admin path. Recorded
  as the target architecture in `cloudflare-dns-handback-ingest-2026-05-14.md`;
  not implemented.

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

## Device Lifecycle

Each Windows host moves through the same seven phases. Phase status per
device lives in `current-status.yaml.devices[].lifecycle_phase`, and the
classification label lives in `current-status.yaml.devices[].classification`.

| Phase | Name | Goal | Typical packet shape |
|---|---|---|---|
| 0 | `intake` | Capture non-secret current state under a `read-only-probe` session. Identify Windows edition/version/build, accounts, services, firewall profile and rules, OpenSSH state, scheduled tasks by principal, BitLocker/Defender state, optional features. | `<device>-terminal-admin-baseline` |
| 1 | `classify` | Assign a `classification` label and decide whether the host converges on the MAMAWORK SSH model or stays GUI-only. | Decision recorded in `current-status.yaml`; no live change. |
| 2 | `normalize-network` | Confirm hostname, DNS, DHCP, network profile (Private), and firewall scope (LAN/private only). HomeNetOps owns DHCP and Unbound; this repo owns Windows profile and firewall rule names. | HomeNetOps handback for DHCP/DNS; Windows packet for profile and scoped firewall rules. |
| 3 | `install-shell-lane` | Install/verify OpenSSH Server, install the device-scoped admin public key into `administrators_authorized_keys`, restore the standard `Match Group administrators` block, and prove MacBook auth as the intended admin user. | `<device>-ssh-key-bootstrap`, `<device>-sshd-admin-match-block`, `macbook-ssh-conf-d-streamline` |
| 4 | `harden` | Clean stale `sshd_config`, decide `StrictModes` / `AllowGroups` / `LogLevel`, remove legacy SSH and firewall surface, reconcile per-user `authorized_keys`, and decide per-user privilege cleanup. | `<device>-ssh-hardening`, `<device>-privilege-cleanup` |
| 5 | `off-lan` | Enroll in Cloudflare WARP under the Windows multi-user model (admin / adult / kid profile separation). Optional: front SSH with a Cloudflare Tunnel + Access app. | Blocked on `cloudflare-dns` Pulumi rebaseline; packet draft only. |
| 6 | `recovery` | Decide BitLocker / Secure Boot stance, define backup target and restore drill, document a local-admin break-glass path. | `<device>-bitlocker-securboot`, `<device>-backup-plan`, `<device>-defender-exclusions-audit` |

### Classification Labels

| Label | Meaning |
|---|---|
| `reference-ssh-host` | Converged on the MAMAWORK SSH model. SSH is the primary admin lane; RDP is fallback. |
| `rdp-only-host` | GUI/RDP is the primary admin lane by intentional decision. SSH is not installed and is not the next packet. |
| `not-yet-onboarded` | No `system-config` per-device record yet. Pre-intake. |
| `legacy-risk-host` | Host has known unmanaged admin surface or legacy credentials that block convergence; needs a remediation packet before any normal phase work. |
| `cloudflare-ready` | Phase 5 can start; `cloudflare-dns` policy supports the host's profile assignment. |
| `cloudflare-blocked` | Phase 5 is gated on `cloudflare-dns` work (typically Windows multi-user rebaseline). |

### Phase Completion And Skipping

A phase is "complete" when the named packet for that phase is applied
and its apply record is committed. A phase can be explicitly skipped —
for example DESKTOP-2JJ3187 phase 3 is intentionally not started
because the host is RDP-only — but the skip must be recorded as a note
on the device's `current-status.yaml` block.

Current per-device phase (2026-05-15):

| Device | `lifecycle_phase` | `classification` | Notes |
|---|---|---|---|
| MAMAWORK | 3 complete; entering 4 | `reference-ssh-host` | Cloudflare phase 5 `cloudflare-blocked` pending multi-user rebaseline. |
| DESKTOP-2JJ3187 | 2 complete; 3 intentionally skipped | `rdp-only-host` | Reclassify to `reference-ssh-host` only if an OpenSSH packet is explicitly drafted. |
| future Windows PC | 0 | `not-yet-onboarded` | Phase 0 read-only intake first; do not copy MAMAWORK artifacts blindly. |

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

## Packet Artifact Separation

Mutating packets must separate the **prose runbook** (Markdown, for
humans and reviewers) from the **executable artifact** (a `.ps1`
script the operator launches). The DESKTOP-2JJ3187 v0.3.0 failure on
2026-05-15 demonstrated why: when the operator was expected to
"transcribe" the script out of a Markdown code block to a `.ps1` and
run it, the round-trip introduced both an encoding defect (non-ASCII
punctuation under WinPS 5.1) and a re-saved-file mutation that was
not authorized by the packet.

Layout for any mutating Windows packet:

```text
docs/device-admin/<device>-<purpose>-YYYY-MM-DD.md     # prose runbook
scripts/device-admin/<device>-<purpose>-vX.Y.Z.ps1     # executable
scripts/device-admin/<device>-<purpose>-validate-vX.Y.Z.ps1   # optional read-only validator
```

The Markdown runbook **references** the script by stable identity:

```text
script:    scripts/device-admin/<device>-<purpose>-vX.Y.Z.ps1
sha256:    <hex digest>
encoding:  ASCII or UTF-8 with BOM
shell:     C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
invocation: powershell.exe -NoProfile -ExecutionPolicy Bypass -File <script>
```

Read-only-probe packets (Phase 0 baselines, reconciliation packets)
may keep their script inline in Markdown because the operator
extracting them carries no host-mutation risk. Mutating packets
must not.

The operating agent runs the named `.ps1`. The agent does not
reconstruct, re-encode, or otherwise re-author the script. If the
script does not match its declared sha256 or encoding, halt.

## Encoding Contract

PowerShell shell defaults differ:

- **Windows PowerShell 5.1** defaults to Windows-1252 on machines
  with a Western-locale default. A `.ps1` saved as UTF-8 without BOM
  containing non-ASCII bytes (em-dashes, smart quotes, special
  spaces) is read as mojibake and fails to parse.
- **PowerShell 7+** defaults to UTF-8 without BOM. ASCII bytes are
  identical either way.

Contract for `.ps1` files in `scripts/device-admin/`:

- **Prefer ASCII-only.** Use `--` not `—`, `'...'` not `'...'`,
  regular space not non-breaking space. Reserve typographic
  punctuation for prose docs.
- If non-ASCII is necessary, save the file as **UTF-8 with BOM**
  and state `encoding: UTF-8 with BOM` in the Markdown runbook's
  script reference.
- Validate ASCII-only with `LC_ALL=C grep -Pn '[^\x00-\x7F]'
  <script>.ps1` from the MacBook before committing; the line should
  return no matches.

Reload an existing UTF-8-without-BOM script as UTF-8-with-BOM only
under an explicit re-encode packet — not as an ad hoc fix during a
mutating run.

## Cross-Shell Data Normalization

Whenever PowerShell objects cross a process boundary via JSON, CLIXML,
or any text serialization, normalize complex types in the **producing**
shell first. `ConvertTo-Json` serializes enums as their integer
backing value; an outer shell that compares against the string name
will misclassify the state.

The DESKTOP-2JJ3187 v0.3.0 failure was exactly this:
`Get-WindowsCapability` returned a `WindowsCapability` whose `State`
is a `Microsoft.Dism.Commands.PackageFeatureState` enum.
`ConvertTo-Json -Compress` produced `"State":0` for `NotPresent`,
which the outer script compared against `'NotPresent'` and rejected.

Canonical pattern for cross-process boundaries:

```powershell
$cap = Get-WindowsCapability -Online -Name 'OpenSSH.Server*' |
  Select-Object -First 1

[pscustomobject]@{
  Name       = [string]$cap.Name
  State      = $cap.State.ToString()
  StateInt   = [int]$cap.State
  StateType  = $cap.State.GetType().FullName
} | ConvertTo-Json -Compress
```

Then compare only against the normalized string:

```powershell
switch ($cap.State) {
  'Installed'   { 'skip install' }
  'NotPresent'  { 'run Add-WindowsCapability' }
  default       { throw "Unexpected state: $($cap.State)" }
}
```

Always capture both human-readable form and diagnostic form so a
mismatch surfaces as data, not as a halt-with-no-context.

## Structured Evidence

Evidence files that drive decisions must be machine-readable.
`Format-Table -AutoSize` elided the `Principal` column on the
DESKTOP-2JJ3187 Phase 0 baseline because the terminal was narrower
than the natural column width. This is fine for human-glance display
but unacceptable for evidence that gates further packets.

For each evidence concern, write a JSON or NDJSON file under the
host evidence directory:

```powershell
Get-ScheduledTask |
  Select-Object TaskPath, TaskName, State,
    @{n='Principal'; e={ $_.Principal.UserId }} |
  ConvertTo-Json -Depth 5 |
  Set-Content -LiteralPath (Join-Path $EvidenceDir '08-scheduled-tasks.json') -Encoding utf8
```

Format-Table-rendered text files may accompany the JSON as a human
summary, but the JSON is the canonical evidence the apply record
should cite.

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

## Windows OpenSSH Defaults

Windows OpenSSH is not a Linux distro's OpenSSH. Before designing any
packet that edits `sshd_config` or relies on its parse behavior,
consult the upstream Microsoft source — do not assume Linux-distro
defaults transfer.

Authoritative source for what `Add-WindowsCapability OpenSSH.Server*`
installs at `C:\ProgramData\ssh\sshd_config`:

```text
https://raw.githubusercontent.com/PowerShell/openssh-portable/latestw_all/contrib/win32/openssh/sshd_config
```

(File: `contrib/win32/openssh/sshd_config` on the `latestw_all`
branch of `PowerShell/openssh-portable`. The shipped Windows binary
copies this file into `C:\ProgramData\ssh\sshd_config` on first
capability install.)

The DESKTOP-2JJ3187 v0.4.0 install failure crystallized two facts
that diverge from common Linux-distro defaults and must be encoded
in any future Windows-OpenSSH packet:

### No `Include` directive in default `sshd_config`

OpenSSH 8.2+ supports an `Include` directive. Most Linux distros
ship `sshd_config` with `Include /etc/ssh/sshd_config.d/*.conf`
near the top, so dropping files into `sshd_config.d/` activates
new directives. **Microsoft's default `sshd_config` does not
include any `Include` directive.** A drop-in file at
`C:\ProgramData\ssh\sshd_config.d\<name>.conf` is silently
ignored unless `sshd_config` is mutated to read it.

**Spec requirement:** any packet that uses a drop-in file under
`C:\ProgramData\ssh\sshd_config.d\` must also ensure
`Include sshd_config.d/*.conf` is present in `sshd_config`,
idempotently, with a snapshot of the pre-edit file. Place the
`Include` directive at the top of `sshd_config`, above any
`Match` block. Relative paths in `Include` are resolved relative
to the directory of the file doing the including.

**Spec alternative:** a packet may choose to edit `sshd_config`
directly (append directives to the file's global scope, above
the trailing `Match Group administrators` block) and skip the
drop-in entirely. Either pattern is acceptable; mixing them
without an `Include` injection is not.

### `Match Group administrators` block is at the bottom by default

Microsoft's default `sshd_config` ships with two non-commented
directives:

```text
AuthorizedKeysFile      .ssh/authorized_keys
Subsystem       sftp    sftp-server.exe
```

followed by the standard admin-group block at the **end** of the
file:

```text
Match Group administrators
       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
```

That block has been the default since OpenSSH-on-Windows v7.7.1.0
(Windows 10 1809). Packets must treat its presence as expected and
no-op the "ensure Match block" step if the regex already finds it,
rather than appending a duplicate.

Directives placed **after** this `Match` block in `sshd_config`
itself, or in a drop-in file that gets `Include`-d after this
`Match` block, are scoped to the admin group only. Global
directives (`PasswordAuthentication`, `KbdInteractiveAuthentication`,
`AllowGroups`, etc.) must precede any `Match` block. This is the
reason the §No `Include` directive rule above specifies
**top-of-file** placement for the `Include` line.

### Forward slashes in paths

`sshd_config` uses POSIX-style forward-slash paths even on Windows.
Microsoft's default uses `__PROGRAMDATA__/ssh/administrators_authorized_keys`
not `__PROGRAMDATA__\ssh\administrators_authorized_keys`. Match the
upstream form in any new directive.

### Verification before drafting

Before drafting a packet that touches `sshd_config`, an operator
or agent must read the upstream file referenced above and confirm
the current behavior. If Microsoft has changed the default (added
or removed `Include`, moved the `Match` block, etc.) the spec
section above must be updated before the packet ships.

The DESKTOP-2JJ3187 v0.4.0 attempt halted at S7 because the packet
was designed against the Linux-distro `Include` convention without
this verification step. The post-mortem is
`docs/device-admin/desktop-2jj3187-ssh-lane-install-v0.4.0-incident-2026-05-15.md`.

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
- a script's actual sha256 does not match the value declared in the Markdown
  runbook's script reference
- a `.ps1` file's encoding does not match its declared encoding (per
  §Encoding Contract)
- a cross-shell value's normalized type (string, int, enum name) does not
  match the script's expected shape (per §Cross-Shell Data Normalization)

## Packet-Defect Halt Rule

A **mutating** administrative packet may not be locally repaired by the
operating agent after any of:

- parser error (PowerShell `ParserError`, syntax failure before any
  mutation has occurred)
- encoding mismatch (mojibake, BOM/no-BOM mismatch, non-ASCII bytes
  the producing shell could not interpret)
- quoting failure (nested `-Command`, here-string interpolation, escape
  errors)
- serialization mismatch (enum-to-int, string-to-bool, JSON round-trip
  loss between producer and consumer shells)
- state-normalization mismatch (e.g., a comparison against a string name
  where the value arrived as an integer)
- script-file sha256 or encoding does not match the Markdown runbook's
  declared reference

These are **packet defects**, not host defects. The agent must:

1. Preserve evidence and the failed script verbatim. Do not overwrite,
   re-encode, or re-author.
2. Preserve the on-host evidence directory. Do not delete or rotate it.
3. Halt the run.
4. Return a hand-back to system-config naming the failure class.
5. Wait for a new packet version. A patched live script is not an
   approved packet.

The presence of an "interactive patch and re-run" option in the
operating environment does not authorize that path. The correct
answer for any of the failure classes above is **halt and hand back**.

This rule applies to packets in the `scoped-live-change` session
class. `read-only-probe` packets may continue past a single command
failure if the failed command is non-mutating and the rest of the
evidence is still useful (the baseline's `Get-WindowsCapability`
"Class not registered" was an example: the agent surfaced the issue,
continued the rest of the read-only probe, and handed back).

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

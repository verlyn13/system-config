# MAMAWORK hand-back - sshd admin Match block apply, 2026-05-14

Packet applied:
`mamawork-sshd-admin-match-block-packet-2026-05-14.md`

Apply wrapper:
`apply-mamawork-sshd-admin-match-block-2026-05-14.ps1`

Evidence slot:
`C:\Users\Public\Documents\jefahnierocks-device-admin\mamawork-sshd-admin-match-block-20260514-161232\`

## Apply Result

```text
timestamp:                         2026-05-14T16:12:32.9515181-08:00
operator:                          MAMAWORK\jeffr
elevation:                         True
scope:                             MAMAWORK sshd admin Match block restoration
status:                            completed
sshd restart:                      completed; service Running afterward
listener TCP/22 after restart:      0.0.0.0:22 and [::]:22, PID 11844
```

The packet did apply the intended fix:

```text
C:\ProgramData\ssh\sshd_config

line 51: Match Group administrators
line 52:     AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
```

The pre-existing commented block remains commented at lines 45-46.
The active block is the new appended one at lines 51-52.

## Packet Phases

```text
PHASE 1:
  before state:                    no active Match blocks in sshd_config
  sshd -T before:                   authorizedkeysfile .ssh/authorized_keys
  OpenSSH/Operational tail:         2 events captured, both old server-listening events from 2025-12-07

PHASE 2:
  decision:                         append standard Windows OpenSSH admin Match block

PHASE 3:
  status:                           Match block appended
  verification:                     active Match block found at line 51

PHASE 4:
  sshd -t:                          passed, exit 0
  warning emitted:                  Unable to load host key: __PROGRAMDATA__/ssh/ssh_host_dsa_key
  assessment:                       non-fatal existing stale DSA HostKey reference; defer to ssh-hardening

PHASE 5:
  sshd before restart:              Running / Automatic
  sshd after restart:               Running / Automatic
  status:                           restarted successfully

PHASE 6:
  global sshd -T after:             still shows authorizedkeysfile .ssh/authorized_keys
  assessment:                       expected for unconditional/global view; Match directives require sshd -T -C
  final file check:                 line 51: Match Group administrators
  listener TCP/22:                  listening on IPv4 and IPv6
```

## Direct Verification After Cut-Off

I ran the missing server-side conditional verification after the prior
session cut off. This is the important evidence:

```text
command:
  C:\Windows\System32\OpenSSH\sshd.exe -T -C user=jeffr,host=mamawork.home.arpa,addr=127.0.0.1

exit:
  0

relevant output:
  pubkeyauthentication yes
  passwordauthentication no
  kbdinteractiveauthentication yes
  strictmodes no
  authorizedkeyscommand none
  authorizedkeyscommanduser none
  loglevel DEBUG3
  authorizedkeysfile __PROGRAMDATA__/ssh/administrators_authorized_keys
```

This proves the active `Match Group administrators` block fires for
`MAMAWORK\jeffr` and points sshd at the system-wide
`administrators_authorized_keys` file.

Service and listener evidence:

```text
sshd service:
  Status:                           Running
  StartType:                        Automatic
  StartName:                        LocalSystem
  ProcessId:                        11844
  Path:                             C:\WINDOWS\System32\OpenSSH\sshd.exe
  StartTime:                        2026-05-14 16:12:33 -08:00

TCP/22:
  ::                                Listen, PID 11844
  0.0.0.0                           Listen, PID 11844
```

Key-path evidence carried forward from the streamline slot:

```text
administrators_authorized_keys fingerprint:
  256 SHA256:qilvkR7/539qqRoWurVdAgoXL1Wol7WzbD0tHlha0QY verlyn13@mamawork-admin (ED25519)

administrators_authorized_keys ACL:
  NT AUTHORITY\SYSTEM:              FullControl
  BUILTIN\Administrators:           FullControl
```

Current shell/elevation note:

```text
whoami:                             mamawork\jeffr
integrity:                          High Mandatory Level
local admin token:                  BUILTIN\Administrators enabled
```

## What Still Needs MacBook Verification

There is no private key in `C:\Users\jeffr\.ssh` on MAMAWORK:

```text
C:\Users\jeffr\.ssh\
  authorized_keys.txt
  known_hosts
```

So the real 1Password-agent-backed auth probe cannot be run from this
Windows host. The closing test remains the MacBook-side probe:

```bash
ssh -i ~/.ssh/id_ed25519_mamawork_admin.1password.pub \
    -o IdentityAgent="$HOME/.1password-ssh-agent.sock" \
    -o IdentitiesOnly=yes \
    -o PreferredAuthentications=publickey \
    -o BatchMode=yes \
    -o ConnectTimeout=5 \
    -o ControlMaster=no \
    -o ControlPath=none \
    -o HostKeyAlias=192.168.0.101 \
    jeffr@mamawork.home.arpa 'hostname; whoami'
```

Expected result:

```text
MAMAWORK
mamawork\jeffr
```

If that passes, the MAMAWORK SSH lockout is closed.

If it fails, do not revisit ACL/BOM/Match-block theory. The current
server-side evidence rules those out for `jeffr`. Capture the immediate
OpenSSH/Operational tail and the MacBook `ssh -vvv` public-key offer
sequence, then diagnose the next layer directly.

## Notable Wrinkles

1. `sshd -t` and `sshd -T -C` emit:

```text
Unable to load host key: __PROGRAMDATA__/ssh/ssh_host_dsa_key
```

This did not make `sshd -t` fail and did not stop sshd from restarting
or listening. It is a stale DSA HostKey reference and belongs in the
future `mamawork-ssh-hardening` packet.

2. `sshd -T -C user=DadAdmin,...` exits 255 with:

```text
ga_init, unable to resolve user dadadmin
```

This is not part of the closing success criterion, which is
`jeffr@mamawork.home.arpa`. No `DadAdmin` account state was modified.
Treat `DadAdmin` SSH behavior as a separate diagnostic only if it still
matters after `jeffr` is verified from the MacBook.

3. `OpenSSH/Operational` is enabled but the unfiltered evidence slot only
captured two old 2025-12-07 server-listening events. It did not record
fresh restart/auth detail during this apply. If the MacBook auth probe
fails, capture both sides immediately:

```powershell
Get-WinEvent -LogName 'OpenSSH/Operational' -MaxEvents 50 |
  Select-Object TimeCreated, Id, LevelDisplayName, Message
```

## Boundaries Honored

Unchanged by this packet and by the follow-up verification:

```text
administrators_authorized_keys content
per-user C:\Users\*\.ssh files
ahnie account
DadAdmin account
kid accounts
jeffr Microsoft Account
built-in Administrator
RDP rules and RDP service state
WinRM / PSRemoting
BitLocker / Secure Boot / TPM
Defender / ASR
powercfg / NIC wake
HKLM NetworkList registry
Cloudflare / WARP / cloudflared / Tailscale / OPNsense / DNS / DHCP
1Password items or secrets
```

`ahnie` was not used as a test subject and was not modified.

## File Map

```text
C:\Users\Public\Documents\jefahnierocks-device-admin\
|-- apply-mamawork-sshd-admin-match-block-2026-05-14.ps1
|-- mamawork-sshd-admin-match-block-packet-2026-05-14.md
|-- handback-mamawork-sshd-admin-match-block-2026-05-14.md
`-- mamawork-sshd-admin-match-block-20260514-161232\
    |-- match-block.txt
    |-- openssh_operational_unfiltered.csv
    |-- sshd_config.acl.before.txt
    |-- sshd_config.before
    |-- sshd_config.after
    |-- sshd_T_effective.before.txt
    |-- sshd_T_effective.after.txt
    `-- sshd_t_validate.txt
```


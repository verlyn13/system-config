---
title: Fedora Top Phase 1 SSH Foothold Evidence - 2026-05-13
category: operations
component: device_admin
status: blocked-macbook-key
version: 0.1.0
last_updated: 2026-05-13
tags: [device-admin, fedora, ssh, evidence, lan]
priority: high
---

# Fedora Top Phase 1 SSH Foothold Evidence - 2026-05-13

This record ingests the Fedora-side Phase 1 SSH foothold report and the
MacBook-side LAN smoke test result for `fedora-top`.

The result is partial: `fedora-top` is reachable on TCP `22` from the MacBook,
but MacBook public-key login as `verlyn13` is not yet working.

Do not proceed to SSH hardening, password-SSH disablement, firewall narrowing,
privilege cleanup, Docker/Infisical changes, WARP/Cloudflare work, Tailscale
changes, power-policy changes, or reboot until MacBook public-key SSH login is
proven.

## Source Evidence

| Source | Scope | Repo-safe handling |
|---|---|---|
| `/Users/verlyn13/Downloads/fedora-top-phase-1-ssh-foothold-report-2026-05-13.md` | Fedora-side Phase 1 report from the local Fedora agent | Ingested as redacted facts; no raw public key lines, passwords, private keys, recovery keys, login URLs, or shell history copied. |
| MacBook LAN smoke test from this `system-config` session at `2026-05-13T08:31:32-08:00` | `nc`, temporary `ssh-keyscan` known-hosts file, BatchMode SSH public-key attempt, and SSH-agent fingerprint check | No permanent `known_hosts` change made; temporary known-hosts file removed; fingerprints only. |

## Fedora-Side Verified State

| Item | Observed |
|---|---|
| Device | `fedora-top` |
| Fedora version | Fedora Linux 44 Workstation |
| Kernel | `7.0.4-200.fc44.x86_64` |
| Hardware | Lenovo ThinkPad X1 Carbon Gen 10 |
| Active interface | Wi-Fi `wlp0s20f3` |
| Current LAN IP | `192.168.0.206/24` |
| Default gateway | `192.168.0.1` |
| Wi-Fi MAC | `66:B5:8C:F5:45:74` |
| AC power | Connected |
| Battery | `80%`, `pending-charge` |
| `sshd` enablement | Enabled |
| `sshd` runtime | Active |
| TCP 22 listener | Present on `0.0.0.0:22` and `[::]:22` |
| `firewalld` | Running |
| Active Wi-Fi zone | `FedoraWorkstation` |
| Wi-Fi zone exposure | `ssh`, `mdns`, `samba-client`, and broad high TCP/UDP ports remain allowed |
| Docker zone | Active on Docker bridge interfaces |
| `/home/verlyn13/.ssh` | Exists, `700`, `verlyn13:verlyn13` |
| `/home/verlyn13/.ssh/authorized_keys` | Exists, `600`, `verlyn13:verlyn13` |

The Fedora-side agent made no system configuration change and did not add a
new public key because no approved MacBook public key line was provided in
that session.

## Authorized Key Findings

The Fedora-side agent listed only public-key fingerprints and comments from
`/home/verlyn13/.ssh/authorized_keys`:

| Fingerprint | Comment |
|---|---|
| `SHA256:xHbcJoWrOxffuoiu+jS+8i9rUovVeUFeO6Y9A5WMpS4` | `verlyn13@wsl-fedora42-to-thinkpad-t440s` |
| `SHA256:V3oZ/zOfm/IHLHF0i+nT7R6OItQbw/2N2CZq7iS3pNg` | `ansible@hetzner.hq` |
| `SHA256:V3oZ/zOfm/IHLHF0i+nT7R6OItQbw/2N2CZq7iS3pNg` | `ansible@hetzner.hq` |

The duplicate `ansible@hetzner.hq` public-key entry should be cleaned up
later, but do not edit `authorized_keys` until the approved MacBook key is
selected and login is tested.

## MacBook-Side Smoke Test

From the MacBook:

```bash
nc -vz -G 3 192.168.0.206 22
```

Result:

```text
Connection to 192.168.0.206 port 22 [tcp/ssh] succeeded.
```

Interpretation: the LAN path from the MacBook to Fedora TCP `22` is open.

The SSH login attempt used a temporary `known_hosts` file built from
`ssh-keyscan`; it did not persist a host-key entry to the MacBook:

```bash
ssh -o UserKnownHostsFile=<temporary-file> \
  -o StrictHostKeyChecking=yes \
  -o BatchMode=yes \
  -o ConnectTimeout=5 \
  -o PreferredAuthentications=publickey \
  verlyn13@192.168.0.206 \
  'hostname; whoami; id; sudo -n true || echo sudo-needs-human'
```

Result:

```text
verlyn13@192.168.0.206: Permission denied (publickey,gssapi-keyex,gssapi-with-mic,password).
```

Interpretation: MacBook-to-Fedora SSH is not established yet. Do not disable
password SSH or harden SSH until public-key login succeeds.

## MacBook SSH Client Findings

`ssh -G 192.168.0.206` showed the managed workstation SSH posture:

- `user verlyn13`
- `identitiesonly yes`
- `pubkeyauthentication true`
- `identityagent /Users/verlyn13/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`
- `preferredauthentications publickey`

`ssh-add -l` without `SSH_AUTH_SOCK` could not reach an authentication agent.
With `SSH_AUTH_SOCK` set to the 1Password agent socket, the MacBook listed
1Password agent fingerprints, but none matched the Fedora-side
`authorized_keys` fingerprints above.

The SSH debug attempt offered the local public key:

```text
SHA256:dvFc8TNaUeE/BR4qxiqrd3kqmnqnHokhiIsGWC68ykc
```

That offered key is not present in the Fedora-side authorized-key fingerprints.

## Current Blocker

The approved MacBook public key for `verlyn13@fedora-top` has not been
installed or selected.

One of these needs to happen next:

1. Choose the intended 1Password-backed MacBook SSH key, provide exactly that
   public key line to the Fedora-side agent, and add it to
   `/home/verlyn13/.ssh/authorized_keys` under the existing Phase 1 exception.
2. Alternatively, approve use of the offered local public key fingerprinted as
   `SHA256:dvFc8TNaUeE/BR4qxiqrd3kqmnqnHokhiIsGWC68ykc`, then provide its
   public key line to the Fedora-side agent.

Do not use a human workstation key for unattended automation. This key is for
human interactive administration only.

## Next Safe Step

Select one approved MacBook public key line and have the Fedora-side agent add
it for `verlyn13`, then rerun:

```bash
nc -vz -G 3 192.168.0.206 22
ssh verlyn13@192.168.0.206 'hostname; whoami; id; sudo -n true || echo sudo-needs-human'
```

Expected successful result:

- `nc` succeeds.
- SSH logs in as `verlyn13`.
- `hostname` returns `fedora-top`.
- `whoami` returns `verlyn13`.
- `sudo -n true` either succeeds or prints `sudo-needs-human`.

Only after that succeeds should the remote baseline and hardening sequence in
[`fedora-top-complete-instructions.md`](./fedora-top-complete-instructions.md)
continue.


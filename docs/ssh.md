---
title: SSH Policy
category: reference
component: ssh_policy
status: active
version: 1.1.1
last_updated: 2026-05-02
tags: [ssh, git, signing, 1password, security, agentic]
priority: high
---

# SSH Policy

This document is the live system-wide policy for SSH authentication, SSH-based
Git signing, and workstation SSH compatibility on this system.

Use this document for current SSH behavior, boundaries, and migration targets.
Use [`docs/secrets.md`](./secrets.md) for everyday secret-handling policy.

## Intent

The SSH model for this system must satisfy all of the following:

1. Keep human interactive private keys out of repo-managed files and, where
   practical, off disk entirely.
2. Support secure local development and secure human-supervised agentic work.
3. Keep project repos compatible with the workstation baseline without making
   them depend on hidden user-global behavior.
4. Separate human identities from unattended machine identities.

## Scope Ownership

`system-config` owns the nonsecret workstation SSH baseline:

- base `~/.ssh/config` policy
- default agent selection
- forwarding defaults
- compatibility guidance
- doctor checks for SSH posture

`system-config` does not own:

- private keys
- host-specific secrets
- `known_hosts`, `authorized_keys`, or control sockets
- project-specific deploy credentials
- unattended machine identity issuance

Projects own their own remote workflow documentation and any project-specific
automation identity model.

## Required Policy

- Human interactive SSH on this workstation should use the 1Password SSH agent.
- OpenSSH remains the client and policy layer.
- Agent forwarding is disabled by default.
- Commits must be signed using the approved Git signing configuration.
- SSH-based Git signing is an approved implementation of signed-commit policy.
- Human workstation identities must not become unattended machine identities.
- Projects must not require undocumented user-global SSH aliases or private key
  filenames to function.

## Workstation Baseline

The approved default workstation baseline is:

- 1Password SSH agent via `IdentityAgent` once the desktop agent is enabled
- managed `~/.config/1Password/ssh/agent.toml` so the SSH agent can use keys
  from the pinned `Dev` vault on `my.1password.com`
- `ForwardAgent no` at the global default level
- `IdentitiesOnly yes` at the global default level
- host-specific overrides only where explicitly needed
- public-key `IdentityFile` paths for 1Password-backed host mappings
- managed `~/.ssh/allowed_signers` aligned with the active SSH signing identity

The base `~/.ssh/config` managed by this repo should remain small and should
continue to include `~/.ssh/conf.d/*.conf` for host-specific modules.

Nonsecret host-specific modules may be managed by this repo under
`home/private_dot_ssh/private_conf.d/`. Machine-local or secret-bearing SSH state remains
unmanaged.

The managed baseline is intentionally staged:

- this repo enables `IdentityAgent` only when `ssh.use_1password_agent` is
  true and the 1Password agent socket exists at apply time
- host mappings migrate one logical identity at a time through explicit entries
  under `ssh.host_migrations`
- if a host migration path is not configured or the referenced `.pub` file does
  not exist yet, that host keeps its existing private-key `IdentityFile`
- this allows gradual cutover: for example, the default GitHub personal path
  can move to 1Password while Hetzner, mesh, or router access stays on the
  existing private keys until those identities are migrated separately

Host-specific modules, whether managed or still local during migration, must
align with this policy:

- prefer public-key `IdentityFile` paths ending in `.pub` for 1Password-backed
  identities
- do not enable `ForwardAgent yes` except for explicitly trusted hosts that
  require it
- do not encode project contracts that depend on local alias names alone

## Git Signing

Signed commits are required.

The current approved workstation implementation is SSH-based Git signing:

- `gpg.format=ssh`
- `commit.gpgsign=true`
- `user.signingkey=<public-key path>`
- `gpg.ssh.allowedsignersfile=~/.ssh/allowed_signers`
- `gpg.ssh.program=/Applications/1Password.app/Contents/MacOS/op-ssh-sign`
  when the signing key is a 1Password-managed `SSH Key` item rather than a
  private key that still exists on disk

This policy is outcome-based, not tool-name-based. The governing control is
that commits are signed and verifiable.

The `allowed_signers` file managed by this repo is nonsecret and should include
the current primary signing identity plus any explicitly retained legacy signing
identities that still need local verification support.

## Agentic Use

Human-supervised local agents may use the human interactive SSH identity only
when the human remains in the loop for authorization.

Do not configure the workstation so that all applications are broadly approved
to use all SSH keys by default. If broader approval is ever needed for a
specific application, treat it as an explicit exception.

## Machine Identities

1Password SSH agent is the workstation human-identity UX. It is not the system
machine-identity platform.

Unattended agents, CI, servers, runners, and remote automations must use
separate nonhuman credentials, such as:

- deploy keys
- GitHub Apps
- OIDC or workload identity
- short-lived SSH certificates
- other explicitly scoped machine identities

Do not reuse personal workstation identities as shared automation credentials.

## Compatibility Contract For Projects

Projects compatible with this system should assume:

- OpenSSH-compatible remote URLs and hostnames
- signed commits are required
- project secrets stay in project `.envrc` or project-native tooling
- project docs may describe bastions, jump hosts, and forwarding needs, but
  should not require private key material to live in the repo

Projects should not assume:

- a specific unmanaged SSH alias exists on every workstation
- private keys are present on disk
- user-global shell aliases or startup files are part of the project contract

If a project needs a special SSH flow, document it in the project repo in
`AGENTS.md`, `CLAUDE.md`, or `.workspace/workspace.toml`.

## Unsupported Or Conditional Clients

The preferred path is OpenSSH and Git clients that respect `IdentityAgent` or
`SSH_AUTH_SOCK`.

Some clients may not support the 1Password SSH agent directly. In those cases:

- prefer an OpenSSH-compatible alternative
- or use an SSH tunnel created from the terminal and connect the client through
  `localhost`

Client compatibility should follow current vendor support guidance rather than
guesswork.

## Verification

Useful checks:

```bash
ng-doctor ssh
ssh -G github.com | rg '^(identityagent|forwardagent|identityfile|identitiesonly) '
cat ~/.config/1Password/ssh/agent.toml
git config --global -l | rg '^(gpg\\.format|commit\\.gpgsign|user\\.signingkey|gpg\\.ssh\\.)'
ssh -T git@github.com
git log --show-signature -1
```

## Related

- [`AGENTS.md`](../AGENTS.md)
- [`README.md`](../README.md)
- [`docs/secrets.md`](./secrets.md)
- [`docs/security-hardening-implementation-plan.md`](./security-hardening-implementation-plan.md)
- [`docs/agentic-tooling.md`](./agentic-tooling.md)

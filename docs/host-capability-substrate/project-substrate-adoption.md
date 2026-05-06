---
title: Project Substrate Adoption
category: policy
component: host_capability_substrate
status: active
version: 0.1.0
last_updated: 2026-05-06
tags: [substrate, project-infrastructure, runners, proxmox, github-actions, policy]
priority: high
---

# Project Substrate Adoption

Host-local adoption guidance for project use of the shared substrate until HCS
is primary for typed evidence and operation gating.

Source authority: Citadel PR #37, merged to
`The-Nash-Group/citadel-config` at
`46c55857427af4b887194277bac2218c20b595b6`.

Read with:

- Citadel standard:
  `/Users/verlyn13/Organizations/the-nash-group/the-citadel/docs/project-substrate-control-plane-standard.md`
- Citadel example contract:
  `/Users/verlyn13/Organizations/the-nash-group/the-citadel/docs/reference/project-substrate-contract.example.yaml`
- Host-local policy snapshot:
  [`../../policies/host-capability-substrate/project-substrate-admission.yaml`](../../policies/host-capability-substrate/project-substrate-admission.yaml)

## Purpose

The first Proxmox substrate is both trusted GitHub Actions compute and a
project-scoped infrastructure surface. Project agents must treat admission as a
contracted, evidence-backed operation, not as permission to mutate the host.

`system-config` owns the transitional host-local policy surface because the
live policy is host-adjacent and must stay available before the HCS kernel owns
the typed evidence model. Project repos own their own contract and evidence.
Citadel owns GitHub control-plane admission. The substrate owner owns Proxmox
host implementation.

## Ownership Boundary

| Surface | Current owner | Rule |
| --- | --- | --- |
| GitHub runner groups, selected repository access, repository rulesets, workflow policy checks | Citadel | Project agents request admission; they do not self-register runner access. |
| Physical Proxmox host, VM templates, storage, network, backups | `runner-substrate` | Project agents do not use the Proxmox console as their normal path. |
| Host-local policy adoption and generated policy snapshots | `system-config` | This repo is the live policy surface until HCS is primary. |
| Project substrate contract and project evidence | Project repo | The contract is non-secret and committed before shared capacity is used. |
| Typed evidence model, freshness, operation gating | HCS | Future owner after the schema/policy lane lands. |

## Project Contract

Every admitted project carries a non-secret substrate contract before it uses
shared substrate capacity.

Recommended project path:

```text
docs/infrastructure/project-substrate-contract.yaml
```

Use the Citadel example contract shape at:

```text
/Users/verlyn13/Organizations/the-nash-group/the-citadel/docs/reference/project-substrate-contract.example.yaml
```

The contract declares the workload lanes, owner, authority repo, resource
budget, network profile, storage profile, backup profile, machine identities,
secret references, IaC owner, required evidence, teardown policy, Guardian
approval, and status. Secret references are references only; never paste
secret values into the contract.

Lifecycle states:

| State | Meaning |
| --- | --- |
| `draft` | Contract exists but does not authorize provisioning. |
| `accepted` | Structure is approved; provisioning may be planned but not applied. |
| `provisionable` | IaC and identity prerequisites are ready for reviewed apply. |
| `active` | Workload may run within the declared scope. |
| `suspended` | Workload must not run until a blocking issue is resolved. |
| `retired` | Workload is decommissioned and closeout evidence is recorded. |

No project becomes `active` from parent status alone. Active use requires the
contract, scoped identity, IaC, lane-specific access, and evidence gates that
apply to the declared lane.

## Lane 1: CI Execution

The CI execution lane is for GitHub Actions jobs on trusted self-hosted
hardware.

Required controls:

- Runner group access is managed by Citadel.
- Workflows use `runs-on.group` plus explicit labels.
- Generic `runs-on: self-hosted` is forbidden.
- Hosted smoke checks remain present for self-hosted workflows.
- Public fork pull-request code does not run on self-hosted hardware.
- Apply or deploy jobs use the IaC runner group and a protected environment.
- Runner registration uses short-lived material only.
- Runner tokens, JIT configs, private keys, and personal credentials never
  enter git, docs, chat, or OpenTofu state.

Minimum evidence:

- Citadel selected-repository access for the target runner group.
- Workflow policy check result.
- Runner group and label mapping.
- Hosted smoke check status.
- Proof that public fork PRs cannot reach self-hosted runners.
- Short-lived runner registration procedure.

## Lane 2: Project Infrastructure

The project infrastructure lane is for project-scoped VMs, containers, dev
services, databases, preview environments, build caches, and service stacks.

Required controls:

- Every workload has a project substrate contract before provisioning.
- Provisioning and teardown are idempotent and IaC-owned.
- The contract declares CPU, memory, storage, concurrency, and runtime limits.
- The network profile declares management access, egress, ingress, LAN or VPN
  dependencies, and firewall or reverse-proxy ownership.
- Storage is classified as `ephemeral`, `rebuildable`,
  `persistent_project_data`, or `regulated_or_sensitive`.
- Persistent project data has backup and restore expectations before active
  use.
- Ephemeral containers and VMs have explicit cleanup rules.
- Project agents mutate only their declared project scope.
- Host-level Proxmox operations remain outside project repos.

Minimum evidence:

- VM/container template or image source.
- Network profile.
- Storage and backup profile.
- Restore expectation when data is persistent.
- Runtime secret reference inventory.
- Teardown evidence for ephemeral resources.

## Machine Identities

Project infrastructure uses purpose-scoped machine identities.

Canonical logical form:

```text
machine/<entity>/<project>/<purpose>
```

Rules:

- Do not use personal credentials for project infrastructure.
- Do not share one broad machine identity across unrelated projects.
- Prefer short-lived platform-native identities where supported.
- 1Password may custody bootstrap or integration material; it does not make a
  broad credential acceptable.
- OpenTofu may reference secret names, item aliases, or provider-managed
  identifiers. It must not persist secret values.
- Identity issuance, rotation, and retirement evidence is separate from
  workload admission evidence.

## Stop Rules

Stop and return to Guardian review when any of these occur:

- A project attempts direct host SSH, Docker, or Proxmox console mutation as its
  normal path.
- Proxmox console state drifts from IaC or is changed outside the substrate
  owner.
- A project wants broad parent, human, or unrelated project credentials instead
  of scoped machine identities.
- Secret values, runner tokens, JIT configs, private keys, or recovery material
  would enter git, docs, chat, local files, or OpenTofu state.
- A project workload wants shared substrate capacity before a reviewed contract
  exists.
- Proxmox management, VM management, runner VM management, or privileged service
  surfaces would become publicly reachable.
- Persistent project data would run before backup and restore expectations
  exist.
- Public fork pull-request code would reach trusted self-hosted runners.
- A docs, project, or Citadel PR would register runners, mutate providers,
  create credentials, or alter Proxmox state as a side effect.

## Agent Workflow

For a project that wants substrate access:

1. Add `docs/infrastructure/project-substrate-contract.yaml` using the Citadel
   example shape.
2. Declare one or both lanes: `ci_execution`, `project_infrastructure`.
3. Fill in resource, network, storage, backup, teardown, machine identity, and
   IaC ownership fields before asking for active use.
4. Keep secret references as names or `op://` references only.
5. Record evidence in stable project paths; do not rely on chat transcripts.
6. Stop before any direct host mutation, provider mutation, runner
   registration, credential creation, or Proxmox console action.

This doc does not grant execution authority. It tells project agents what must
exist before the substrate owner, Citadel, or future HCS policy can admit the
workload.

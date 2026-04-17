---
title: Workspace Management Design
category: design
component: workspace_management
status: proposed
version: 1.2.1
last_updated: 2026-04-15
tags: [workspace, orbstack, podman, proof-of-concept, resource-management]
priority: high
---

# Workspace Management Design

This document defines the minimal local workspace-management design that fits the current `system-config` paradigm.

Projects that need to configure themselves to be compatible with this system should also follow [`docs/agentic-tooling.md`](./agentic-tooling.md), which defines the project-local tool, env, instruction, and workspace-compatibility expectations.
For live system-wide secret-handling rules, use [`docs/secrets.md`](./secrets.md); this document only assigns ownership boundaries around project secrets and `.envrc`.

It intentionally does not design a full platform. It makes only the choices needed to decide:

- what belongs in `system-config`
- what belongs in user-level config
- what belongs in each project
- how one real proof-of-concept project is enrolled:
  - `/Users/verlyn13/Repos/verlyn13/manim`

Current scope:

- one enabled proof-of-concept project
- local-only on this Mac
- OrbStack as the substrate and Podman as the managed container runtime
- `experiment`-class lifecycle semantics for the proof of concept
- no IaC or PaC enforcement yet, but a manifest shape that can survive later IaC and policy adoption

Current operator shape:

- `manim` is the first enabled simple test
- `budget-triage`, `scopecam-engine`, and `flux` remain explicit configured roots in the user config so trust stays narrow and path-based
- the initial launcher exposes config inspection, host access, and doctor checks only

## Constraints

This design must conform to the current repo contract:

- zsh is the only managed interactive shell
- XDG is the user-level config boundary
- project runtime and secret decisions stay in `.mise.toml` and `.envrc`
- project MCP stays in `.mcp.json`
- `system-config` manages substrate and integration, not project internals

## Minimal Decisions

### 1. Host substrate

Initial substrate choice:

- OrbStack stays the macOS-level app/runtime substrate.
- Podman is the container runtime used for workspace-managed containers.
- `system-config` owns those choices in v1. User-level config does not choose a different provider or runtime.

Not chosen in v1:

- Apple Containerization
- Colima multi-instance
- Kubernetes as the default workspace substrate
- a separate repo for workspace management

Reason:

- the current design goal is a stable local substrate, not backend pluggability
- OrbStack already gives the Linux boundary needed for real resource controls
- Podman in that boundary keeps the future command and policy surface narrow

### 2. Isolation model

Initial isolation model:

- one dedicated user-level workspace host inside OrbStack
- Podman runs inside that workspace host when a project actually uses managed containers
- a project may still be workspace-enrolled with `driver = "none"` while it standardizes identity, lifecycle, metadata, and limits
- stronger isolation remains a future decision

Explicitly deferred:

- hard per-project VM isolation
- multiple runtime backends
- automatic scheduler behavior across projects

Reason:

- a single workspace host is the smallest design that can standardize project behavior
- some projects need workspace metadata before they need managed containers
- hard isolation is a later tradeoff, not a day-one requirement

### 3. Command surface

Initial command surface:

- a future host-side `workspace` launcher becomes the canonical entrypoint
- project repos are not required to rewrite their current development commands on day 1

The launcher is responsible for:

- locating a project workspace manifest
- selecting the workspace host
- dispatching workspace lifecycle commands

Not chosen in v1:

- shell aliases as the primary interface
- direct user editing of OrbStack internals
- project scripts that assume Podman on the macOS host directly

### 4. Resource model

Initial resource model has only two active control layers:

1. user-level host ceiling
2. project-level requested limits

Host ceiling:

- configured at user scope
- applies to the dedicated workspace host

Project requested limits:

- declared in each project workspace manifest
- map to local-process expectations or future container limits

Limit precedence:

- effective project CPU limit = project request when set, capped by the user-level host ceiling
- effective project memory limit = project request when set, capped by the user-level host ceiling
- if a project omits a request, the user-level default project limit applies
- user config sets ceilings and defaults; project config requests within that envelope

Not chosen in v1:

- host-wide fair scheduling across all workspaces
- disk quotas as a first-class enforced contract
- automatic rebalancing

Reason:

- CPU and memory are the immediate concern
- hard scheduling policy can wait until multiple active workspace-managed projects exist

### 5. Mount and state model

Initial mount and state model:

- an enrolled project root is an exact path, not a broad glob
- project source remains project-owned and is mounted into the workspace host when needed
- project-local manifests stay in the repo
- workspace-managed runtime state lives under `~/.local/state/workspaces/<slug>/`

Project-owned files remain the source of truth for:

- `.mise.toml`
- `.envrc`
- `.mcp.json`
- `.workspace/workspace.toml`

Project owners should use [`docs/agentic-tooling.md`](./agentic-tooling.md) as the compatibility guide for how those files should be shaped.

Reason:

- the workspace layer should not absorb project runtime, env, or MCP ownership
- exact-path enrollment keeps trust explicit and reversible

### 6. Metadata and service model

Every enrolled project must declare:

- workspace class
- lifecycle
- owner and subsidiary
- requested resources
- stable labels
- service categories

Labels must be simple stable strings so they can become future IaC and PaC selectors.

Service categories describe the intended role and policy shape even if no managed container is enabled yet.

Recommended service categories:

- `application`
- `worker`
- `quality-gate`
- `observability`
- `data`

### 7. Scope ownership

| Scope | Owns | Does not own |
|------|------|---------------|
| `system-config` | OrbStack and Podman boundary, workspace launcher shape, user config template shape, doctor hooks, docs | project manifests, project secrets, project service definitions |
| user-level XDG config | workspace host identity, host ceilings, default project limits, exact enrolled project roots | runtime backend choice, project env, project MCP, project task logic |
| project repo | `.workspace/workspace.toml`, requested resources, lifecycle metadata, labels, service categories, compose file path if used | host runtime choice, global caps, host app settings |

## File Layout

These are the managed surfaces this design assumes.

### In `system-config`

Initial files:

```text
home/dot_config/workspaces/config.toml.tmpl
home/dot_local/bin/executable_workspace.tmpl
home/dot_local/bin/executable_workspace-doctor.tmpl
docs/workspace-management.md
```

### User-level deployed paths

```text
~/.config/workspaces/config.toml
~/.local/state/workspaces/
~/.local/bin/workspace
~/.local/bin/workspace-doctor
```

### Project-level shape

Each enrolled project may add:

```text
.workspace/workspace.toml
.workspace/README.md
```

Those files are project-owned and checked in.

## Config Shape

### User-level config

Canonical path:

- `~/.config/workspaces/config.toml`

Minimal shape:

```toml
version = 1

[host]
machine = "workspace-host"

[limits]
host_cpus = 8
host_memory = "16GiB"
default_project_cpus = 2
default_project_memory = "4GiB"

[projects.manim]
path = "/Users/verlyn13/Repos/verlyn13/manim"
enabled = true
notes = "Simple workspace-contract proof of concept"

[projects.budget-triage]
path = "/Users/verlyn13/Repos/verlyn13/budget-triage-11-5-2025"
enabled = false
notes = "Planned first real workspace-managed infra project"

[projects.scopecam-engine]
path = "/Users/verlyn13/Repos/verlyn13/scopecam-engine"
enabled = false
notes = "Enrolled project; no containerized workspace by default"

[projects.flux]
path = "/Users/verlyn13/ai/flux"
enabled = false
notes = "Planned first real workspace-managed infra project"
```

Important policy:

- use exact project paths for enrollment
- do not broaden this into `~/Repos/**` or `~/ai/**` globs
- do not add runtime backend knobs to user config in v1
- keep planned projects explicit in config even before they are enabled

Initial command surface now implemented:

- `workspace list`
- `workspace show <slug>`
- `workspace path <slug>`
- `workspace host-machine`
- `workspace host-shell`
- `workspace host-run <command> [args...]`
- `workspace doctor`

### Project manifest

Canonical path:

- `.workspace/workspace.toml`

Minimal shape:

```toml
version = 1

[workspace]
name = "manim"
workspace_id = "hp-manim-0001"
class = "experiment"
lifecycle = "experimental"
driver = "none"
sunset_date = "2026-06-07"

[ownership]
subsidiary = "happy-patterns"
primary_owner = "verlyn13"
guardian_accounts = ["verlyn13", "happy-patterns"]
github_repository = "verlyn13/manim"

[resources]
cpus = 2
memory = "4GiB"

[labels]
subsidiary = "happy-patterns"
workspace_class = "experiment"
lifecycle = "experimental"
owner = "verlyn13"
project_type = "python"
```

Minimal rules:

- project manifests do not choose OrbStack
- project manifests do not choose Podman
- project manifests do not contain secrets
- project manifests keep runtime pins in `.mise.toml`
- project manifests define stable metadata even if managed containers are not enabled yet

## Proof Of Concept

### manim

Observed shape:

- `.mise.toml` present
- `.envrc` present
- `pyproject.toml` present
- no compose stack

Initial workspace role:

- single proof-of-concept project
- `experiment` class with an explicit sunset date
- local-only, low-risk, low-stakes project

Initial driver choice:

- `none`

Reason:

- the project is real, but it does not need managed containers to establish the correct workspace contract
- runtime and packaging are already project-local and decided
- the proof of concept should validate identity, lifecycle, labels, and resource shape before it validates container orchestration

Other explicit configured roots remain in reserve:

- `budget-triage`
- `scopecam-engine`
- `flux`

They stay explicit in user config so the future launcher can work from exact trusted paths rather than broad host globs.

Container position:

- no managed containers are enabled by default
- the manifest still defines service categories for future container roles
- if containers are added later, each one must declare a stable role and stay local-only by default

Project-local runtime remains the source of truth:

- Python 3.13
- `uv`
- `ruff`
- project package metadata in `pyproject.toml`

## Recommended Labels And Metadata

The proof of concept should use these stable values:

- `subsidiary = happy-patterns`
- `workspace_class = experiment`
- `lifecycle = experimental`
- `owner = verlyn13`
- `repo = verlyn13/manim`
- `project_type = python`
- `workload = animation`
- `risk = low`
- `data_classification = internal`
- `host_platform = orbstack-local`
- `cost_center = happy-patterns/development`

These are chosen because they are:

- understandable without local tribal knowledge
- stable enough to become future IaC and PaC selectors
- narrow enough for a low-risk proof of concept

## Deferred

These are intentionally not decided in this design:

- rootful versus rootless Podman inside the workspace host
- whether `manim` should later gain an optional render container
- whether a future quality-gate container should exist for lint and test tasks
- whether host ceilings should be dynamic by power or battery state
- whether future stronger isolation should move to Apple Containerization or Colima multi-instance
- any remote-host IaC adapter, identity provider, or policy-engine wiring

Those are second-step decisions. The first step is to establish correct ownership and a narrow manifest shape.

## Decision Summary

If this proceeds, the minimal standard is:

1. `system-config` chooses OrbStack and Podman in v1; user config does not.
2. user-level XDG config explicitly enrolls one exact project path for the proof of concept.
3. `manim` owns `.workspace/workspace.toml` and any workspace-local README.
4. the proof of concept uses an `experiment` lifecycle with an absolute sunset date.
5. no managed containers are required by default for the proof of concept.
6. labels, ownership metadata, and service categories are required from day one so later IaC and PaC adoption has a stable shape to inherit.

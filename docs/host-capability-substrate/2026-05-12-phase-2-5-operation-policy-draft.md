---
title: HCS Phase 2.5 Operation Policy Draft
category: policy-draft
component: host_capability_substrate
status: draft
version: 0.1.0
last_updated: 2026-05-12
tags: [hcs, policy, operation-shape, gateway, phase-2-5]
priority: high
---

# HCS Phase 2.5 Operation Policy Draft

Draft only. This does not activate `tiers.yaml` and does not grant execution
authority. The canonical live target remains:

```text
policies/host-capability-substrate/tiers.yaml
```

Activation requires HCS policy review and human approval. Until then, this file
is a review packet for the Phase 2.5 policy lane.

## Source Authority

- HCS current truth: `jefahnierocks/host-capability-substrate` commit
  `f8792b3` (`D-045`)
- Source schema: `OperationShape.schema_version == "0.2.0"`
- Operation classes: ADR 0029, ADR 0036, ADR 0047
- Foundational execute-lane schemas present: `Decision`, `ApprovalGrant`,
  `Lease`, `Run`, `Principal`, `Session`
- Live policy boundary: `system-config/policies/host-capability-substrate/`

## Draft Policy Shape

```yaml
---
policy_version: "0.1.0"
kind: host_capability_substrate.operation_tiers
status: proposed
last_updated: "2026-05-12"

schema_refs:
  operation_shape_schema_version: "0.2.0"
  decision_schema_version: "0.1.0"
  approval_grant_schema_version: "0.1.0"
  lease_schema_version: "0.1.0"
  run_schema_version: "0.1.0"

tiers:
  read-safe: "No host/project mutation; no approval needed."
  write-local: "Writes local agent/session/workspace-adjacent state only."
  write-project: "Writes project worktree or project-scoped resources."
  write-host: "Writes user-level host state."
  write-destructive: "Hard to reverse, external, protected, or destructive mutation; human approval required."
  forbidden: "Not exposed by HCS; no escalation path."

operation_class_defaults:
  read_only_diagnostic:
    default_tier: read-safe
    approval_required: false
    notes: "Host observation only; gateway may still reject stale, sandbox, or self-asserted evidence chains."

  agent_internal_state:
    default_tier: write-local
    approval_required: false
    notes: "Agent/session bookkeeping; no host mutation. Cross-session or host-state effects require a narrower future policy rule."

  workspace_verify:
    default_tier: read-safe
    approval_required: false
    notes: "Verification command shape only; no shell-string intent and no host mutation. Failures emit typed Decisions."

  cleanup_plan:
    default_tier: read-safe
    approval_required: false
    notes: "Plan construction only. Produces typed candidate OperationShape records and a DerivedSummary; execution remains separate and gated."

  worktree_mutation:
    default_tier: write-project
    approval_required: true
    requires_active_lease: true
    sandbox_acquire: blocked
    notes: "Project worktree mutation requires lease discipline and sandbox-acquire rejection per ADR 0052."

  destructive_git:
    default_tier: write-destructive
    approval_required: true
    requires_deletion_authority: true
    notes: "Destructive local or remote Git mutation. Approval cannot clear stale or missing deletion authority."

  merge_or_push:
    default_tier: write-destructive
    approval_required: true
    notes: "Protected merge/push path. Grant binds source ref, target ref, commit SHA, and evidence."

  external_control_plane_mutation:
    default_tier: write-destructive
    approval_required: true
    notes: "Provider/control-plane mutation. Mapped to write-destructive until policy vocabulary gains a distinct external-control-plane tier."

non_escalable_forbidden_patterns:
  - pattern: '\bsudo\b'
    reason_kind: operation_class_unregistered
    notes: "No hidden sudo retry path."
  - pattern: '\bspctl\s+--master-disable\b'
    reason_kind: operation_class_unregistered
    notes: "Gatekeeper disable is forbidden, not approvable."
  - pattern: '\bdefaults\s+write\b'
    reason_kind: operation_class_unregistered
    notes: "Broad defaults mutation stays unregistered until a typed capability exists."
  - pattern: '\brm\s+-[A-Za-z]*[rR][A-Za-z]*[fF]?\s+/'
    reason_kind: operation_class_unregistered
    notes: "Root-recursive deletion family is forbidden."

cross_record_rules:
  self_approval_rejection:
    applies_to:
      - destructive_git
      - external_control_plane_mutation
      - worktree_mutation
      - merge_or_push
      - cleanup_plan
    comparison: "ApprovalGrant.grantor_principal_ref == consuming Session.principal_id"
    enforcement_layer: ring_1_mint_api

  producer_disjointness:
    applies_to:
      - decision_to_approval_grant
      - lease_acquire_to_authorizing_decision
      - run_record_to_authorizing_decision
    walk_depth_limit: 64
    cycle_rejection_reason_kind: audit_chain_corruption_detected
    enforcement_layer: ring_1_mint_api

  force_break:
    current_posture: blocked_until_kernel_dashboard_producer_adr
    notes: "Lease.force_break_grant_id is shaped but operationally unreachable until the dashboard producer/grant-kind change-set lands."
```

## Review Blockers Before Activation

1. `hcs-policy-reviewer` must check escalation holes, forbidden-operation leaks,
   tier vocabulary fit, and whether `external_control_plane_mutation` should
   remain `write-destructive` or trigger a tier vocabulary amendment.
2. Human approval must explicitly convert this draft into live
   `policies/host-capability-substrate/tiers.yaml`.
3. HCS must either land the `PolicyRule` Ring 0 entity or explicitly accept a
   transitional YAML-only shape for Phase 2.5.
4. The future policy lint path must reject `approval_required` on `forbidden`
   entries and reject any non-escalable forbidden pattern with an approval path.

## Current Non-Claims

- No HCS kernel consumes this draft.
- No hooks, adapters, dashboard routes, or MCP tools enforce it.
- No live execution authority changes.
- No provider, Git, shell, launchd, filesystem, or 1Password mutation is
  authorized by this draft.

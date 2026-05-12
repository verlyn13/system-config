---
title: HCS Phase 2.5 Reviewer Resolution Packet
category: policy-review
component: host_capability_substrate
status: blocked-pending-activation-fixes
version: 0.1.0
last_updated: 2026-05-12
tags: [hcs, policy, operation-shape, gateway, phase-2-5, review]
priority: high
---

# HCS Phase 2.5 Reviewer Resolution Packet

This packet records the required reviewer objections on the Phase 2.5 operation
policy draft:

```text
docs/host-capability-substrate/2026-05-12-phase-2-5-operation-policy-draft.md
```

Verdict: the draft is safe only while inert. The four human decisions are now
resolved below, but do not convert it to live
`policies/host-capability-substrate/tiers.yaml` until the activation fixes
below are resolved.

## Review Inputs

- HCS source truth: `jefahnierocks/host-capability-substrate` commit
  `f8792b3`
- Current decision row: D-045, not D-042
- system-config policy-draft commit: `89ffa39`
- Reviewers:
  - `hcs-policy-reviewer`: activation would under-specify invariants 1, 2, 6,
    7, 16, 17, and the live-policy boundary.
  - `hcs-security-reviewer`: activation as written risks invariants 2, 4, 6,
    7, 8, 13, and 16.
  - `hcs-ontology-reviewer`: operation-class keys align with
    `operationShapeOperationClassSchema`; `approvalGrantKindSchema` and
    `leaseKindSchema` references show no drift; reason-kind drift includes
    both `operation_class_unregistered` and `audit_chain_corruption_detected`.
  - `hcs-architect`: tier vocabulary fits as policy authority vocabulary, not
    architecture-ring vocabulary; live `cross_record_rules` must use structured
    declarative predicates, not free-form expressions or kernel algorithms.

## Four Human Decisions

### 1. Self-Approval Canonicalization Location

Question: should the live policy encode the Principal canonicalization recipe,
or cite the entity ADR/registry as the owner?

Required resolution: the live policy must not rely on raw string equality.
It must either cite or restate the accepted Principal mint rule:
NFC normalization, Unicode `Cf` strip, Unicode-aware lowercase fold, and
leading/trailing whitespace trim at Principal mint time. Comparison remains
typed Principal ID equality after mint, not compare-time normalization.

Source anchors:
- HCS ontology registry: self-approval rejection rule and Principal mint recipe
- ADR 0054 / D-043: Principal canonicalization closes zero-width-character
  evasion
- ADR 0055 / D-044: Session closes typed consuming-session `principal_id`

### 2. `agent_internal_state` Narrowing

Question: should `agent_internal_state` be session-local only?

Required resolution: before activation, define `agent_internal_state` as
session-local execution-context state only. Cross-session shared state, HCS
runtime state, host-backed coordination state, or anything with host/external
side effects must reject or reclassify; it must not inherit
`approval_required: false`.

Reviewer reason: the draft's note currently admits the under-classification
risk instead of resolving it.

### 3. `external_control_plane_mutation` Tier Vocabulary

Question: should external control-plane mutation remain `write-destructive`, or
does it need a distinct tier?

Required resolution: a human must choose one. Either:

- Keep `external_control_plane_mutation` at `write-destructive`, but require
  typed provider evidence, minimal-request plan, target binding, fanout/quota
  evidence, secret-reference separation, receipts, gateway review,
  ApprovalGrant consumption, broker FSM, dashboard review, audit, and any
  applicable lease checks.
- Create a distinct tier for external-control-plane mutation and define those
  same evidence and approval requirements there.

Do not leave "until future vocabulary" in live policy.

### 4. `write-host` Posture

Question: reserve `write-host` or remove it from v0.1.0?

Required resolution: because no operation class maps to `write-host` in the
draft, the live policy must either:

- mark `write-host` reserved/inert with no active mappings, or
- remove it until a scoped host-mutation capability lands with explicit
  approval/dashboard gates.

It must not become a fallback bucket for host mutation.

## Human Decisions Resolved 2026-05-12

Accepted human-authority resolutions:

1. **Self-approval canonicalization location**: live policy cites ADR 0054 and
   the HCS ontology registry as the source of truth. The policy YAML stays
   compact; HCS owns the Principal mint canonicalization recipe and typed
   Principal equality rule.
2. **`agent_internal_state` boundary**: narrow to session-local
   execution-context state only. Cross-session shared state, HCS runtime state,
   host-backed coordination state, or anything with host/external side effects
   must reject or reclassify; it does not inherit `approval_required: false`.
3. **`external_control_plane_mutation` tier vocabulary**: keep at
   `write-destructive` with the full evidence, approval, grant, lease,
   dashboard, and audit bind set.
4. **`write-host` posture**: remove from v0.1.0. Add it back only when an
   operation class lands that owns scoped host mutation with explicit
   approval/dashboard gates.

These resolutions close Lane A only. The Non-Negotiable Activation Fixes below
remain reviewer blockers and still gate any live `tiers.yaml` activation.

## Non-Negotiable Activation Fixes

These are not optional human-preference decisions; they are reviewer blockers.

1. Canonical policy must classify typed operation/capability families, not
   primary shell regex strings. Regex literals may remain only as renderer,
   hook, or lint defense-in-depth.
2. Broad `approval_required: true` booleans are not activation-grade. Mutating
   classes need exact operation scope, single use, `valid_until`, producer
   restrictions, dashboard visibility, evidence-bound scope, and
   `required_grant_kind` / grant-kind compatibility.
3. Sandbox-acquire policy belongs in a per-`lease_kind` rule table. `worktree`
   lease acquire is blocked when the requesting Session's
   `ExecutionContext.sandbox != "none"`.
4. Forbidden rejection reason kinds must be source-defined or explicitly
   covered by transitional lint. `operation_class_unregistered` and
   `audit_chain_corruption_detected` are not currently Zod-defined in
   `decisionReasonKindSchema`; the former appears in draft forbidden-pattern
   entries and the latter appears as `cycle_rejection_reason_kind`.
5. Activation-grade YAML needs `schema_version`, structured provenance, and
   evidence/source references. PolicyRule is not a prerequisite for file-based
   policy authority in system-config, but it remains the future materialized
   Ring 0 policy-record entity.
6. External-control-plane mutation requires invariant-16 typed provider
   evidence before any executable path; approval alone is not enough.
7. Policy lint must reject forbidden entries with approval paths, broad grant
   scopes, grant reuse, missing provider evidence for external mutation,
   sandboxed worktree lease acquire, invalid reason kinds, and any raw secret
   material in policy or rendered command surfaces.
8. Live `cross_record_rules` must be structured declarative policy records:
   field references, operator, constants, source refs, and enforcement-layer
   refs. No free-form comparison expressions, graph-walk pseudocode, or kernel
   implementation algorithm belongs in YAML.

## Ordering

1. Human decisions resolved on 2026-05-12; activation fixes remain blocking.
2. Revise the draft into an activation-grade `tiers.yaml` candidate.
3. Add policy lint fixtures for the reviewer-required cases.
4. Only after human approval, convert the draft into live
   `policies/host-capability-substrate/tiers.yaml`.
5. Vendor the reviewed snapshot into HCS `policies/generated-snapshot/`.
6. Do not scope the first Ring 1 service ADR until the live policy and snapshot
   exist and are citable.

## Skeleton Target

The non-authoritative activation-shape skeleton lives at:

```text
docs/host-capability-substrate/tiers.yaml.v0.2.0-skeleton.yaml
```

It is a structure proposal only. It has `status:
skeleton_draft_non_authoritative`, does not create live policy authority, and
must not be copied to `policies/host-capability-substrate/tiers.yaml` without
the ordering above.

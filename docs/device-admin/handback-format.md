---
title: Device-Admin Handback Format
category: operations
component: device_admin
status: active
version: 1.0.0
last_updated: 2026-05-13
tags: [device-admin, handback, status, automation]
priority: high
---

# Device-Admin Handback Format

This doc describes the lightweight handback/status loop the
`system-config` repo uses to track device administration. Two artifacts
form the contract:

- [`current-status.yaml`](./current-status.yaml) - machine-readable
  per-device state. Pure YAML. Non-secret only. The authoritative
  current state for every device under `docs/device-admin/`.
- Detailed evidence docs - the per-packet `*-packet-*.md` and
  `*-apply-*.md` files alongside this file. They contain the full
  redacted evidence. `current-status.yaml` links to them rather than
  duplicating their content.

The intent is that future agents can read `current-status.yaml` once,
know which device is where in the admin lifecycle, and decide whether
to read deeper docs.

## When To Update `current-status.yaml`

Update this file in the same commit that:

- adds or modifies a `*-packet-*.md` (prepared, version bump, scope
  change)
- adds a `*-apply-*.md` (live apply just happened) and updates the
  corresponding packet's status to `applied`
- removes a packet from approval-required state because an external
  decision unblocked it
- introduces a new device

Do **not** update this file for transient session work that does not
land in a commit. Do not include secrets, fingerprints of private keys,
passwords, recovery codes, or hostnames that are not already public in
this repo.

## Packet State Vocabulary

The directive that introduced this format established five packet
states. Use only these tokens:

| State | Meaning |
|---|---|
| `applied` | The packet was applied live, an apply record exists, and the post-apply validation succeeded. Recorded in `applied_packets[]`. |
| `prepared` | A packet doc exists with status `prepared` in its frontmatter, but has not yet been surfaced for approval. Goes in `prepared_packets[]`. |
| `approval-required` | A packet doc exists and has been surfaced to the human; an approval phrase is pending. Also goes in `prepared_packets[]` with an explicit `approval_phrase_excerpt`. |
| `blocked` | The work cannot proceed without an external decision or piece of state. Goes in `blocked_items[]` with `owner: human` (or `owner: <other-repo>`). |
| `planned` | The packet does not yet exist. Tracked in `next_recommended_action` or in `approval_required[]` with a note that the approval phrase will be supplied when the packet is drafted. |

A packet may move between states. The history lives in commit messages
and in the `*-apply-*.md` files; this YAML always reflects the current
state only.

## YAML Schema (Authoritative)

```yaml
schema_version: 1            # bump on breaking schema changes
last_updated: 2026-MM-DDTHH:MM:SSZ   # ISO-8601 UTC

devices:
  - device: <short-id>
    owner: <entity>
    hostname: <local-hostname>
    fqdn: <fqdn-on-admin-path>
    ip: <current-ip-on-admin-path>

    remote_admin_paths:
      - kind: ssh                        # ssh | cockpit | cloudflare-access | tailscale | ...
        target: <user>@<host>            # or URL for non-ssh paths
        notes: >-
          short non-secret note (e.g. HostKeyAlias workarounds,
          required client options, LAN-vs-private path constraints)

    current_management_status: >-
      one-paragraph English description of how managed the device is
      right now and which broad areas remain pending. Must mention
      whether the device is LAN-only or off-LAN-reachable.

    applied_packets:
      - name: <packet-name>              # e.g. ssh-hardening
        packet_doc: docs/device-admin/<packet-doc>.md
        apply_record: docs/device-admin/<apply-doc>.md
        packet_commit: <short-sha>       # commit that landed the packet
        apply_commit: <short-sha>        # commit that landed the apply
        applied_at: 2026-MM-DDTHH:MM:SSZ

    prepared_packets:
      - name: <packet-name>
        packet_doc: docs/device-admin/<packet-doc>.md
        packet_commit: <short-sha>
        prepared_at: 2026-MM-DDTHH:MM:SSZ
        state: approval-required        # or: prepared
        approval_phrase_excerpt: >-
          first ~15 words of the required approval phrase, with a
          pointer to the full phrase in the packet doc

    blocked_items:
      - item: <slug>
        owner: human                    # or: <other-repo>
        notes: >-
          what is blocked and why

    approval_required:
      - action: <action-slug>
        state: planned                  # or: prepared | approval-required
        approval_phrase: >-
          either the literal required phrase, OR a note that the phrase
          will be supplied when the packet is drafted

    next_recommended_action:
      summary: >-
        short paragraph describing the natural next packet
      preferred_packet: <packet-slug>
      preferred_packet_status: planned   # or: prepared | approval-required
      preferred_packet_blockers:
        - slug: <short-slug>
          note: >-
            one-line note about what is blocked
      handback_to_human: true | false

    last_verified: 2026-MM-DDTHH:MM:SSZ
    latest_system_config_commit: <short-sha>
```

`schema_version: 1` is the only currently defined schema. Adding new
**optional** fields does not require a bump. Removing or renaming any
field above does.

## Handback Template For Future Agents

When an agent (Claude Code, Codex, or human-operated) finishes a
directive lane, return the following handback to the human first,
**before** any prose explanation. Keep it under ~40 lines. Point to
detailed docs for anything longer.

```text
repo:                       <repo name>
branch:                     <git branch>
status:                     <clean | dirty>
commit:                     <short-sha + commit subject>

scope:                      <e.g. "fedora-top firewalld narrowing apply">
device:                     <device-id from current-status.yaml>
applied | prepared | none:  <one of these>

packet documents:
  - <path/to/packet.md>
  - <path/to/apply.md>      (only if an apply happened in this turn)

files changed in repo:
  - <path>
  - <path>

live changes made:          <none | one-line summary or "see apply doc">

verification summary:       <one-line PASS/FAIL summary or short bullet list>

remaining blockers:
  - <slug>: <one-line>
  - <slug>: <one-line>

next recommended action:    <copy from current-status.yaml
                             next_recommended_action.preferred_packet>

approval_required_next:     <copy approval phrase or "not yet drafted">

detail docs:                <bulleted list of relevant *-apply-*.md or
                             *-packet-*.md files for the human to read
                             when they have time>
```

Rules of thumb:

- Lead with the handback block. Never bury it under prose. The human
  should be able to forward this block to another agent verbatim.
- Match the slugs in the handback to those in `current-status.yaml`
  so a downstream agent can grep both.
- If the lane was preparation-only, set `live changes made: none` and
  omit the apply doc from `packet documents`.
- If the lane was apply, include both the packet and the apply doc.
- For `live changes made`, prefer terse references like
  "see `*-apply-*.md`" rather than re-stating snapshot paths or
  per-step output. Snapshots and per-step output live in the apply
  doc.

## Directive Conventions That Pair With This Format

A directive should mention `current-status.yaml` explicitly when:

- the human wants the agent to assume a particular packet has been
  applied (the directive can say "see `current-status.yaml`
  fedora-top.applied_packets[]")
- the human wants to skip context-rebuilding ("read
  `current-status.yaml` first, then the relevant `*-apply-*.md`")
- a directive spans multiple devices ("see `current-status.yaml` for
  the active-device list")

An agent receiving any device-admin directive should read
`current-status.yaml` early, before re-reading individual docs, and
should re-read it after any commit that lands on a device the
directive scopes.

## Non-Goals

- This file is **not** a substitute for the per-packet `*-packet-*.md`
  and `*-apply-*.md` documents. Those are the authoritative evidence.
- This file does **not** carry secrets, fingerprints of private keys,
  passwords, IP addresses outside the home LAN, or any data covered
  by [`../secrets.md`](../secrets.md).
- This file does **not** record commit history. Commit history is in
  git. The YAML records the current state and the latest commit per
  packet.
- This file is **not** a plan. Plans belong in the
  `next_recommended_action` block of the device and, if the work is
  large enough, in a dedicated planning doc that the YAML can link to.

## Related

- [`./current-status.yaml`](./current-status.yaml) - the current state
- [`./fedora-44-laptop.md`](./fedora-44-laptop.md) - master record for `fedora-top`
- [`./onboarding-2026-05-12.md`](./onboarding-2026-05-12.md) - parent onboarding doc
- [`../secrets.md`](../secrets.md) - what must never appear in this file
- [`../ssh.md`](../ssh.md) - SSH client policy that constrains
  `remote_admin_paths`

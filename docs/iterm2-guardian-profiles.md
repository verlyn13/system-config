---
title: iTerm2 Guardian Profiles
category: operations
component: iterm2
status: active
version: 1.0.0
last_updated: 2026-05-09
tags: [iterm2, dynamic-profiles, automatic-profile-switching, the-nash-group]
priority: medium
---

# iTerm2 Guardian Profiles

This document records the repo-owned iTerm2 adaptation of the Guardian profile
idea for `~/Organizations/the-nash-group`.

iTerm2 is still a presentation and safety-signaling layer. It is not an
authority boundary, a credential broker, or a policy engine. Parent/child
authority remains governed by The Nash Group repos and the operational records
there.

## Managed profiles

| File | Profile | Match scope | Visual contract |
|------|---------|-------------|-----------------|
| `iterm2/profiles/10-nash-guardian-l0.json` | `Guardian L0` | Parent repo top-level and parent-owned subdirectories | Deep charcoal, bronze/gold accents, sapphire interaction color, badge `THE GUARDIAN L0` |
| `iterm2/profiles/11-nash-repos.json` | `Nash Repo` | Known nested Git repos under the org directory | Distinct steel/teal palette, badge `TNG REPO` |

Both profiles inherit the managed `Dev` profile for baseline behavior. Neither
profile sets a command, working directory, environment block, or secret.

## Why there are two profiles

The parent root `/Users/verlyn13/Organizations/the-nash-group` carries Parent L0
governance context. Nested repositories under that directory carry child or
subsidiary repo context. They need a visible distinction, but the child profile
must not inherit the Guardian palette or badge.

The `Guardian L0` APS rules match the parent tree. The `Nash Repo` rules use
host-qualified path rules for each known nested Git repo so they outrank the
parent wildcard rule when the shell reports a child-repo path.

## Badge behavior

The iTerm2 profile includes static badge text so the badge appears early during
profile switching. The zsh iTerm2 hook also computes a badge at prompt time:

- If `ITERM_BADGE_TEXT` is set by direnv, that explicit project value wins.
- If the current Git top-level is the parent root, the prompt badge is
  `THE GUARDIAN L0`.
- If the current Git top-level is a nested Nash repo, the prompt badge is
  `TNG REPO: <repo-name>`.
- Outside the Nash org tree, the badge clears.

The hook only runs in interactive iTerm2 shells and is skipped in
`NG_MODE=agentic`.

## Customization rules

Use `scripts/install-iterm2-profiles.sh`; do not paste unmanaged JSON directly
into `~/Library/Application Support/iTerm2/DynamicProfiles`.

Keep `Rewritable: false`. If a GUI experiment is useful, copy the profile as
JSON from iTerm2, translate the change back into `iterm2/profiles/`, and rerun
the installer.

Keep Guardian-specific colors only in `Guardian L0`. Child or subsidiary
profiles must use a separate palette and badge.

Add a new nested repo by appending two APS rules to `Nash Repo`:

```text
*:/Users/verlyn13/Organizations/the-nash-group/<repo>
*:/Users/verlyn13/Organizations/the-nash-group/<repo>/*
```

Avoid iTerm2 triggers until the target scripts exist and are versioned. The
pasted trigger idea for `.claude/orchestration/*.md` is intentionally not wired
because no repo-owned handler script exists here.

Global iTerm2 preferences such as GPU rendering, iCloud sync, and history
storage remain manual host preferences. This repo manages Dynamic Profiles and
the default bookmark only.

## Install and verify

```bash
scripts/install-iterm2-profiles.sh
```

Then open a new iTerm2 session and verify:

1. `cd ~/Organizations/the-nash-group` switches to `Guardian L0`.
2. `cd ~/Organizations/the-nash-group/the-covenant` switches to `Nash Repo`.
3. `cd ~` reverts to the original session profile and clears the prompt badge.

Automatic Profile Switching requires iTerm2 shell integration. If switching
does not occur, first verify the shell-integration installer and a new iTerm2
tab before editing profile JSON.

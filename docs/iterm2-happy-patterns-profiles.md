---
title: iTerm2 Happy Patterns Profiles
category: operations
component: iterm2
status: active
version: 1.0.0
last_updated: 2026-05-09
tags: [iterm2, dynamic-profiles, automatic-profile-switching, happy-patterns]
priority: medium
---

# iTerm2 Happy Patterns Profiles

This document records the repo-owned iTerm2 adaptation of the Happy Patterns
Professional profile idea for `~/Organizations/happy-patterns`.

iTerm2 remains a presentation and safety-signaling layer. Evidence discipline,
privacy/security commitments, scoped PRs, and project authority still come from
the relevant repo contracts and `system-config` shell policy, not from the
terminal profile.

## Managed profiles

| File | Profile | Match scope | Visual contract |
|------|---------|-------------|-----------------|
| `iterm2/profiles/30-happy-patterns-professional.json` | `Happy Patterns Professional` | Happy Patterns org root and non-repo workspace paths | Deep olive-charcoal, warm cream text, terracotta interaction color, sage status accent, badge `HAPPY PATTERNS` |
| `iterm2/profiles/31-happy-patterns-repos.json` | `Happy Patterns Repo` | Manual/fallback profile for future nested repos | Professional base with generic repo badge `HP REPO` |
| `iterm2/profiles/32-happy-patterns-scopecam.json` | `Happy Patterns ScopeCam` | `apps/scopecam` | Professional base with sensor-teal accent, badge `SCOPECAM` |
| `iterm2/profiles/33-happy-patterns-site.json` | `Happy Patterns Site` | `apps/happy-patterns-org.github.io` | Professional base with warm web/gold accent, badge `HP SITE` |
| `iterm2/profiles/34-happy-patterns-records.json` | `Happy Patterns Records` | `records` | Professional base with records/rose accent, badge `HP RECORDS` |

All profiles inherit the managed `Dev` profile directly or through
`Happy Patterns Professional` for baseline behavior. No profile sets a command,
working directory, environment block, trigger, or secret.

## Why there are project profiles

`/Users/verlyn13/Organizations/happy-patterns` is the professional client and
product workspace. The child repos represent different work modes: camera/app
delivery (`ScopeCam`), public site/content (`Site`), and organizational records
(`Records`). They need to be visually distinct while still sharing a calm,
brand-aligned professional baseline.

The `Happy Patterns Professional` APS rules match the org tree. Dedicated
project profiles use host-qualified path rules for each current nested Git repo
so they outrank the parent wildcard rule when shell integration reports a
child-repo path. The generic `Happy Patterns Repo` profile is kept as a
manual/fallback template and intentionally has no APS bindings today.

## Badge behavior

The iTerm2 profile includes static badge text so the badge appears early during
profile switching. The zsh iTerm2 hook also computes a badge at prompt time:

- If `ITERM_BADGE_TEXT` is set by direnv, that explicit project value wins.
- If the current Git top-level is the Happy Patterns org root, the prompt badge
  is `HAPPY PATTERNS`.
- If the current Git top-level is a known nested Happy Patterns repo, the
  prompt badge uses the project-specific label: `SCOPECAM`, `HP SITE`, or
  `HP RECORDS`.
- If the current Git top-level is an unprofiled nested Happy Patterns repo, the
  prompt badge falls back to `HP REPO: <repo-name>`.
- Outside managed org trees, the badge clears.

The hook only runs in interactive iTerm2 shells and is skipped in
`NG_MODE=agentic`.

## Customization rules

Use `scripts/install-iterm2-profiles.sh`; do not paste unmanaged JSON directly
into `~/Library/Application Support/iTerm2/DynamicProfiles`.

Keep `Rewritable: false`. If a GUI experiment is useful, copy the profile as
JSON from iTerm2, translate the change back into `iterm2/profiles/`, and rerun
the installer.

Keep the Happy Patterns palette scoped to the Happy Patterns profiles. Do not
inherit this palette into The Nash Group Guardian profiles or Jefahnierocks
Explorer profiles.

Add a new nested repo by copying one of the project profile files, giving it a
fresh GUID from `uuidgen`, and adding two APS rules:

```text
*:/Users/verlyn13/Organizations/happy-patterns/<repo>
*:/Users/verlyn13/Organizations/happy-patterns/<repo>/*
```

Then add the same repo label to `_iterm2_resolve_happy_patterns_badge` in
`home/dot_config/zshrc.d/zz-iterm2.zsh`.

Do not enable iTerm2 triggers for project documents until the target handler
scripts exist and are versioned. The terminal can signal context, but it should
not invent agent behavior outside repo contracts.

Clipboard write access remains disabled through the inherited `Dev` baseline.
That keeps OSC 52 / OSC 1337 clipboard-write injection blocked for the same
reason documented in `docs/iterm2-profile-redesign.md`.

Global iTerm2 preferences such as GPU rendering, iCloud sync, and history
storage remain manual host preferences. This repo manages Dynamic Profiles and
the default bookmark only.

## Install and verify

```bash
scripts/install-iterm2-profiles.sh
```

Then open a new iTerm2 session and verify:

1. `cd ~/Organizations/happy-patterns` switches to `Happy Patterns Professional`.
2. `cd ~/Organizations/happy-patterns/apps/scopecam` switches to `Happy Patterns ScopeCam`.
3. `cd ~/Organizations/happy-patterns/apps/happy-patterns-org.github.io` switches to `Happy Patterns Site`.
4. `cd ~/Organizations/happy-patterns/records` switches to `Happy Patterns Records`.
5. `cd ~` reverts to the original session profile and clears the prompt badge.

Automatic Profile Switching requires iTerm2 shell integration. If switching
does not occur, first verify the shell-integration installer and a new iTerm2
tab before editing profile JSON.

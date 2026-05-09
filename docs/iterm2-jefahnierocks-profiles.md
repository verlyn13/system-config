---
title: iTerm2 Jefahnierocks Profiles
category: operations
component: iterm2
status: active
version: 1.0.0
last_updated: 2026-05-09
tags: [iterm2, dynamic-profiles, automatic-profile-switching, jefahnierocks]
priority: medium
---

# iTerm2 Jefahnierocks Profiles

This document records the repo-owned iTerm2 adaptation of the Jefahnierocks
Explorer profile idea for `~/Organizations/jefahnierocks`.

iTerm2 remains a presentation and safety-signaling layer. Clean commits,
secret handling, and project authority still come from the relevant repo
contracts and `system-config` shell policy, not from the terminal profile.

## Managed profiles

| File | Profile | Match scope | Visual contract |
|------|---------|-------------|-----------------|
| `iterm2/profiles/20-jefahnierocks-explorer.json` | `Jefahnierocks Explorer` | Jefahnierocks org root and non-repo workspace paths | Deep indigo, electric teal interaction color, coral/gold accents, badge `JEF AHNIE ROCKS • EXPLORER` |
| `iterm2/profiles/21-jefahnierocks-repos.json` | `Jefahnierocks Repo` | Known nested Git repos under the Jefahnierocks org directory | Same Explorer palette, repo-scoped badge `JEF REPO` |

Both profiles inherit the managed `Dev` profile for baseline behavior. Neither
profile sets a command, working directory, environment block, trigger, or
secret.

## Why there are two profiles

`/Users/verlyn13/Organizations/jefahnierocks` is the personal upstream,
creative, academic, family-tooling, and systems workspace. Its nested Git repos
need lightweight repo-specific context without creating a new handmade profile
for every project.

The `Jefahnierocks Explorer` APS rules match the org tree. The
`Jefahnierocks Repo` rules use host-qualified path rules for each known nested
Git repo so they outrank the parent wildcard rule when shell integration reports
a child-repo path.

## Badge behavior

The iTerm2 profile includes static badge text so the badge appears early during
profile switching. The zsh iTerm2 hook also computes a badge at prompt time:

- If `ITERM_BADGE_TEXT` is set by direnv, that explicit project value wins.
- If the current Git top-level is the Jefahnierocks org root, the prompt badge
  is `JEF AHNIE ROCKS • EXPLORER`.
- If the current Git top-level is a nested Jefahnierocks repo, the prompt badge
  is `JEF REPO: <repo-name>`.
- Outside managed org trees, the badge clears.

The hook only runs in interactive iTerm2 shells and is skipped in
`NG_MODE=agentic`.

## Customization rules

Use `scripts/install-iterm2-profiles.sh`; do not paste unmanaged JSON directly
into `~/Library/Application Support/iTerm2/DynamicProfiles`.

Keep `Rewritable: false`. If a GUI experiment is useful, copy the profile as
JSON from iTerm2, translate the change back into `iterm2/profiles/`, and rerun
the installer.

Keep the Explorer palette scoped to the Jefahnierocks profiles. Do not inherit
this palette into The Nash Group Guardian profiles or any future LLC/product
profile without a deliberate design decision.

Add a new nested repo by appending two APS rules to `Jefahnierocks Repo`:

```text
*:/Users/verlyn13/Organizations/jefahnierocks/<repo>
*:/Users/verlyn13/Organizations/jefahnierocks/<repo>/*
```

Do not enable iTerm2 triggers for `CLAUDE.md`, `AGENTS.md`, or similar files
until the target handler scripts exist and are versioned. The terminal can
signal context, but it should not invent agent behavior outside repo contracts.

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

1. `cd ~/Organizations/jefahnierocks` switches to `Jefahnierocks Explorer`.
2. `cd ~/Organizations/jefahnierocks/system-config` switches to `Jefahnierocks Repo`.
3. `cd ~` reverts to the original session profile and clears the prompt badge.

Automatic Profile Switching requires iTerm2 shell integration. If switching
does not occur, first verify the shell-integration installer and a new iTerm2
tab before editing profile JSON.

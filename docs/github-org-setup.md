---
title: GitHub Org Configuration
category: reference
component: github_org
status: active
version: 1.0.0
last_updated: 2026-05-08
tags: [github, org, ruleset, branch-protection, codeowners, teams]
priority: high
---

# GitHub Org Configuration

Captures the GitHub-side configuration for `jefahnierocks/system-config`
so it can be reproduced if rulesets, teams, or branch protection are
lost (e.g., after another transfer).

GitHub UI state is not version-controlled. This file is the closest
substitute and the canonical recipe for recreating the setup via `gh`.

## Org

- Login: `jefahnierocks`
- Plan: `team` (rulesets and team-level access controls available)

## Teams

| Team | Slug | Permission on repo | Purpose |
|------|------|--------------------|---------|
| `system-config maintainers` | `system-config-maintainers` | `admin` | Bypass actor for main ruleset; CODEOWNERS target |

Membership is managed at the org level. Today: `verlyn13` as `maintainer`.

## Branch ruleset on `main`

Active ruleset enforces three rules on the default branch:

| Rule | Effect |
|------|--------|
| `deletion` | Cannot delete `main` |
| `non_fast_forward` | Cannot force-push to `main` |
| `required_linear_history` | All merges must produce a linear history (no merge commits) |

Bypass actors: `system-config-maintainers` team, `always` mode (members
can override the rules when needed for emergencies).

No required PR review or required status checks today — single-developer
direct-push workflow is preserved. Add either when the contributor set
or workflow demands it.

## CODEOWNERS

`.github/CODEOWNERS` routes review requests for all paths to the
maintainers team. Useful once collaborators are added; benign for the
single-developer case today.

## Reproduce

If teams, ruleset, or CODEOWNERS are lost, the following recreates the
configuration. Run as an org admin authenticated to `gh`.

```bash
# 1. Create team
gh api -X POST /orgs/jefahnierocks/teams \
  -f name='system-config-maintainers' \
  -f description='Maintainers for system-config repo. Bypass actors for main ruleset.' \
  -f privacy='closed'

# 2. Add yourself as team maintainer (substitute your login)
gh api -X PUT /orgs/jefahnierocks/teams/system-config-maintainers/memberships/verlyn13 \
  -f role='maintainer'

# 3. Grant team admin on the repo
gh api -X PUT /orgs/jefahnierocks/teams/system-config-maintainers/repos/jefahnierocks/system-config \
  -f permission='admin'

# 4. Capture the team id for the ruleset bypass list
TEAM_ID=$(gh api /orgs/jefahnierocks/teams/system-config-maintainers --jq .id)

# 5. Create the ruleset (template — substitute $TEAM_ID into actor_id)
cat > /tmp/ruleset-main.json <<JSON
{
  "name": "main: no-force-push, no-delete, linear-history",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {"include": ["~DEFAULT_BRANCH"], "exclude": []}
  },
  "rules": [
    {"type": "deletion"},
    {"type": "non_fast_forward"},
    {"type": "required_linear_history"}
  ],
  "bypass_actors": [
    {"actor_id": $TEAM_ID, "actor_type": "Team", "bypass_mode": "always"}
  ]
}
JSON
gh api -X POST /repos/jefahnierocks/system-config/rulesets --input /tmp/ruleset-main.json
rm /tmp/ruleset-main.json
```

CODEOWNERS is a regular committed file at `.github/CODEOWNERS`; recreate
by checking it in.

## When to extend

Add a required-status-check rule once a status check exists that is
worth blocking pushes on (the existing `Repo Validation` workflow is a
candidate, but it runs *after* push, so requiring it would block fast
single-dev iteration).

Add required PR reviews once a second contributor exists.

Add an `authorized pushers` allowlist once direct push is no longer the
norm (today, the bypass actor list and the no-restriction-on-pushers
default are equivalent for a single-developer org).

## Related

- [`.github/CODEOWNERS`](../.github/CODEOWNERS)
- `docs/host-capability-substrate/0001-repo-boundary-decision.md` — system-config and HCS repo ownership decisions under `jefahnierocks` org

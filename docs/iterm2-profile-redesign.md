---
title: iTerm2 Profile Redesign (Hybrid)
category: design
component: iterm2
status: active
version: 0.6.0
last_updated: 2026-05-09
tags: [iterm2, dynamic-profiles, automatic-profile-switching, shell-integration, direnv]
priority: medium
---

# iTerm2 Profile Redesign (Hybrid)

Redesign for `iterm2/` after the 2026-05-08 retirement (HEAD `8cdc6e6`). Adopts iTerm2 3.7-line capabilities (shell integration, Automatic Profile Switching, escape-code-driven runtime mutation) to decouple presentation from filesystem layout.

This doc is the authoritative reference for implementation. Schema claims here are verified against current iTerm2 3.7 documentation (cited inline). Do not implement against unverified claims.

Current implementation status (2026-05-09): Phase A is landed. Phase B has a
managed Dev profile, deterministic Default Bookmark setter, fail-closed
profile validation, Nash path-scoped profiles, Jefahnierocks org/project-scoped
profiles, Happy Patterns org/project-scoped profiles, and a managed
`tokyonight-moon.itermcolors` preset that the installer validates. Color Preset
import remains manual until a known-good `Custom Color Presets` preference
schema is captured. Phase C (`Bound Hosts`) for SSH safety has not started.

2026-05-08 consult pass: the high-level decisions below still stand, but three
implementation details changed after deeper shell/direnv inspection:

1. Source iTerm2 shell integration at the end of zsh startup, not mid-stack.
2. Do not emit terminal escape codes directly from `.envrc`; direnv captures
   `.envrc` output for shell export and side effects can corrupt the eval stream.
3. Treat profile/plist validation and clipboard access as explicit safety gates
   before any profile is installed as the default.

2026-05-08 second consult pass: shell-integration acquisition is now repo-owned
and auditable, utilities are scoped out of Phase A, empty-badge semantics are
explicit, and offline shell startup is verified safe:

4. Shell-integration script is installed by `scripts/install-iterm2-shell-integration.sh`
   with a pinned SHA-256. The upstream `install_shell_integration.sh` is
   explicitly NOT used because it mutates dotfiles directly, conflicting with the
   chezmoi/zshrc.d source-of-truth model.
5. Shell-integration **utilities** package (`~/.iterm2/`) is out of scope for
   Phase A. Escape codes are the supported runtime path. If utilities are needed
   later, that's a separate Phase B/C decision (app-bundled at
   `/Applications/iTerm.app/Contents/Resources/utilities` with a managed PATH
   entry, vs repo-owned install of `~/.iterm2/`). Phase A must not depend on them.
6. Empty `ITERM_BADGE_TEXT` means "clear the badge" (explicit), not "fall back to
   the profile's static `Badge Text`". Tab color remains the primary SSH safety
   signal; APS profile switch may reapply static badge text and that's acceptable.
7. Static iTerm2 profile with GUID `904E3177-4CE0-4D77-B7B6-38F2E2769773`
   (current Default Bookmark) is left in place. Setting `Default Bookmark Guid`
   to the managed Dev profile is sufficient; do not delete the seeded default.
8. Installer mutates `DynamicProfiles/` only after **all** managed sources pass
   validation (JSON, plist, GUID conflicts, parent ordering). On any failure, the
   pre-existing managed symlinks are left untouched.
9. Offline shell startup is a hard requirement. All Phase A runtime paths
   (`zz-iterm2.zsh` source, badge precmd hook, agentic wrapper, direnv badge
   helper) verified to make zero network calls. Only the one-time installer
   requires internet. See the "Offline guarantees" section below.

## Goals

1. **Project-path independence by default** — default and reusable profiles must
   not bake `~/Organizations/...` into JSON. Explicit authority-zone profiles
   may use documented local paths when their purpose is path-specific visual
   signaling.
2. **Decoupled agentic mode** — `NG_MODE=agentic` must work from any launcher (any iTerm2 profile, ssh, tmux, alternate terminal), not only the agentic profile.
3. **Deterministic Default Bookmark** across machines.
4. **SSH safety colors automatic** when ssh'd to a marked host, no wrapper required for the common path.
5. **Themes runtime-swappable** — Color Presets, not per-profile palettes.
6. **Forward-compatible** — schema choices must survive iTerm2 minor-version drift.

## Verified iTerm2 3.7 schema (2026-05-08)

Verified against iTerm2 3.7.0beta1 (installed) and current docs at iterm2.com.

### Dynamic Profiles

| Key | Type | Notes |
|-----|------|-------|
| `Profiles` | array | Top-level wrapper; one or more profile dicts inside. |
| `Name` | string | Required. Display name. |
| `Guid` | string | Required. UUID (`uuidgen`). Identity is GUID, not name. |
| `Dynamic Profile Parent GUID` | string | **Preferred** parent reference (since 3.4.9). Rename-safe. Takes precedence over Parent Name. |
| `Dynamic Profile Parent Name` | string | Legacy parent reference. Falls back to default profile if name is unresolvable. |
| `Rewritable` | bool | If `true`, iTerm2 may write back to the file when settings change in UI. **We set `false`** (or omit) so the repo stays canonical. |
| `Tags` | array of strings | Searchable tags in profile picker. |
| `Bound Hosts` | array of strings | APS rules. Schema below. |

Reference: [Dynamic Profiles documentation](https://iterm2.com/documentation-dynamic-profiles.html).

> "Every profile preference that iTerm2 supports may be an attribute of a Dynamic Profile." For any key not listed above, the canonical workflow is: define in iTerm2 GUI, then `Settings → Profiles → Other Actions → Copy Profile as JSON` to extract.

Operational constraints from the same doc:

- iTerm2 reloads all files in `~/Library/Application Support/iTerm2/DynamicProfiles` when that directory changes.
- Every file in that directory must be a valid property list; one malformed file can stop profile changes from being processed.
- Dynamic profiles load by filename order. Parent profiles must be in an earlier file than children.
- A dynamic profile whose `Guid` equals an existing static profile is ignored.

Installer implication: validate every managed profile with `jq` and `plutil -convert xml1 -o /dev/null`, check managed GUIDs against both managed dynamic profiles and real static profile GUIDs, then update symlinks. When reading `New Bookmarks`, entries marked `Is Dynamic Profile` are iTerm2's loaded dynamic-profile mirror and must not be treated as static conflicts. Do not symlink first and hope iTerm2 rejects only the bad file.

### Automatic Profile Switching (`Bound Hosts`)

Reference: [Automatic Profile Switching documentation](https://iterm2.com/documentation-automatic-profile-switching.html).

- JSON key: **`"Bound Hosts"`** (with space). Confirmed against real-world dynamic profile JSON in the wild.
- Value: array of pattern strings.
- Each pattern uses this grammar:

| Form | Example | Matches |
|------|---------|---------|
| Bare hostname | `host.example.com` | DNS name reported by remote shell-integration |
| IP literal | `10.0.0.5` | IP reported by remote shell-integration |
| Wildcarded host | `*.hetzner.cloud` | Any subdomain |
| User+host | `root@host.example.com` | User reported as logged-in |
| Path | `/Users/me/code` | Working directory (reported via `CurrentDir`) |
| Host+path | `host.example.com:/srv` | Host AND path |
| Job | `&emacs*` | Foreground job name (`&` prefix) |
| Sticky | `!host.example.com` | Stays selected across changes (`!` prefix) |

**Critical prerequisite**: APS requires shell-integration installed on **every machine and account** where switching should fire. Without shell-integration, the remote shell never reports `RemoteHost`/`CurrentDir`, so no path/host rules can match. Cited verbatim:

> "You must install Shell Integration on all machines and all user accounts where you plan to use Automatic Profile Switching."

### Runtime escape codes (used in lieu of CLIs)

Reference: [Escape Codes documentation](https://iterm2.com/documentation-escape-codes.html), [Badges documentation](https://iterm2.com/documentation-badges.html).

Several CLI helpers commonly attributed to iTerm2 (`it2profile`, `it2setbadge`, `it2setvar`) **are not present** in the current iTerm2 3.7 utilities documentation. The supported baseline path for badges/user vars/profile mutation is escape codes directly:

| Action | Escape sequence | Encoding |
|--------|-----------------|----------|
| Set badge | `OSC 1337 ; SetBadgeFormat=B64 ST` | Value base64-encoded |
| Switch profile | `OSC 1337 ; SetProfile=NAME ST` | Plain |
| Set user var | `OSC 1337 ; SetUserVar=KEY=B64VALUE ST` | Value base64-encoded |
| Set tab color | `OSC 1337 ; SetColors=tab=COLOR ST` | Plain (or `bg`/`curbg`) |
| Report cwd | `OSC 1337 ; CurrentDir=PATH ST` | Plain (sent by shell-integration) |
| Report host | `OSC 1337 ; RemoteHost=USER@HOST ST` | Plain (sent by shell-integration) |

OSC = `\e]` (`0x1b 0x5d`). ST = `\a` (`0x07`) or `\e\\`. Example badge:

```bash
printf '\e]1337;SetBadgeFormat=%s\a' "$(printf '%s' "Nash / system-config" | base64 | tr -d '\n')"
```

### Available shell-integration utilities (3.7)

Per [utilities documentation](https://iterm2.com/documentation-utilities.html), the supported set is:

`imgcat`, `imgls`, `it2attention`, `it2check`, `it2copy`, `it2dl`, `it2getvar`, `it2setcolor`, `it2setkeylabel`, `it2ul`, `it2universion`.

Of these, `it2getvar` and `it2setcolor` are the only plausible helpers for this redesign. `it2setcolor preset <name>` can switch a session to an installed Color Preset, but implementation must not depend on it unless the utilities package is installed and detected. Escape codes remain the no-extra-utility path.

### Shell integration install

Reference: [Shell Integration documentation](https://iterm2.com/documentation-shell-integration.html).

```bash
curl -L https://iterm2.com/shell_integration/zsh -o ~/.iterm2_shell_integration.zsh
# in zshrc.d module:
[[ -r ~/.iterm2_shell_integration.zsh ]] && source ~/.iterm2_shell_integration.zsh
```

iTerm2 3.5+ supports auto-loading; we'll explicitly source it for determinism. Confirmed compatible with bash, zsh, fish (≥2.3), tcsh, xonsh (≥3.6.10).

Shell integration is not a passive include. The current zsh script:

- appends `iterm2_precmd` to `precmd_functions`;
- appends `iterm2_preexec` to `preexec_functions`;
- decorates `PS1` with prompt boundary escape codes;
- prints `RemoteHost`, `CurrentDir`, and `ShellIntegrationVersion=14` at load.

Therefore source it **after** starship, direnv, and machine-local prompt hooks. The official zsh install guidance also says to load it at the end of `.zshrc` because earlier scripts may overwrite settings it needs.

Remote host note: the workstation zsh module may gate on `TERM_PROGRAM=iTerm.app`, but remote host shell-integration installs should not add that gate. Over SSH, the remote account may not receive `TERM_PROGRAM`, and APS still depends on the remote shell reporting `RemoteHost` and `CurrentDir`.

## Architecture

Hybrid (Option 3): minimal presentation profiles, declarative SSH safety via APS, behavior driven by shell + escape codes.

### Layer responsibilities

| Layer | Owns | Source of truth |
|-------|------|-----------------|
| iTerm2 Dynamic Profiles | Presentation (font, scrollback, status bar), APS rules for SSH | `iterm2/profiles/*.json` |
| iTerm2 Color Presets | Color palette | `iterm2/color-presets/*.itermcolors` |
| zsh shell layer | NG_MODE gating, prompt | `home/dot_config/zshrc.d/` |
| zsh shell-integration | Reports cwd/host to iTerm2; enables APS | `~/.iterm2_shell_integration.zsh` (sourced in new module `zz-iterm2.zsh`) |
| direnv | Per-project badge text as environment, not terminal output | `~/.config/direnv/direnvrc` (helper) + per-project `.envrc` (call) |
| Wrapper script | Agentic mode entry from any context | `home/dot_local/bin/executable_agentic` |
| SSH client | Host aliases, identity, agent forwarding | `~/.ssh/config` (unchanged) |

### File layout (proposed)

```
iterm2/
├── README.md                              # Updated: describes hybrid design + re-enable workflow
├── profiles/
│   ├── 00-dev.json                        # Default profile (presentation only)
│   └── 05-dev-ssh.json                    # SSH variant, parented to Dev, with Bound Hosts
├── color-presets/
│   └── tokyonight-moon.itermcolors        # Imported via UI or scripts/install-color-presets.sh
├── retired/                               # Kept until Phase D cleanup
└── themes/                                # Removed in Phase D (superseded by color-presets/)
```

### Profile shapes

#### `iterm2/profiles/00-dev.json` (Dev — default)

Presentation only. No working directory, no command, no env block, no color palette inline.

```json
{
  "Profiles": [{
    "Name": "Dev",
    "Guid": "REPLACE-WITH-uuidgen-OUTPUT",
    "Tags": ["workstation"],
    "Rewritable": false,

    "Normal Font": "FiraCode-Regular 13",
    "Use Bold Font": true,
    "Use Italic Font": true,
    "Draw Powerline Glyphs": true,
    "ASCII Anti Aliased": true,
    "Non-ASCII Anti Aliased": true,

    "Unlimited Scrollback": true,
    "Columns": 120,
    "Rows": 36,

    "Option Key Sends": 2,
    "Right Option Key Sends": 2,

    "Allow Title Setting": true,
    "Allow Clipboard Access From Terminal": false,
    "Close Sessions On End": true,

    "Custom Command": "No",
    "Custom Directory": "No"
  }]
}
```

Notes:
- `Custom Directory: "No"` lets iTerm2 use whatever the user chose at launch (default behavior). Replaces the retired hardcoded `~/Organizations`.
- `Custom Command: "No"` uses the user's login shell (zsh by passwd). The agentic wrapper handles `NG_MODE`.
- No `Set Environment Variables` block — env state is shell-driven.
- Color values come from the applied Color Preset, not from this file.
- Clipboard write access is disabled by default. Enable it only with an explicit decision to support `it2copy`/OSC clipboard flows.

#### `iterm2/profiles/05-dev-ssh.json` (Dev SSH — APS variant)

Inherits Dev. Overrides only what differs.

```json
{
  "Profiles": [{
    "Name": "Dev SSH",
    "Guid": "REPLACE-WITH-uuidgen-OUTPUT",
    "Dynamic Profile Parent GUID": "GUID-OF-Dev-PROFILE-ABOVE",
    "Tags": ["workstation", "ssh"],
    "Rewritable": false,

    "Bound Hosts": [
      "REPLACE-WITH-VERIFIED-HETZNER-HOSTNAMES"
    ],

    "Badge Text": "SSH",
    "Use Tab Color": true,
    "Tab Color": {
      "Red Component": 0.7,
      "Green Component": 0.1,
      "Blue Component": 0.1,
      "Alpha Component": 1.0
    }
  }]
}
```

Notes:
- `Dynamic Profile Parent GUID` is rename-safe; preferred over `Dynamic Profile Parent Name`.
- `Bound Hosts` patterns match what the **remote host's** shell-integration reports as `RemoteHost`. They are *not* matched against local SSH config aliases. Phase C verification step nails down the actual values.
- Tab color (red) is set via the iTerm2 profile preference, not via runtime escape — it sticks across resize/detach.
- No background-color override at the profile level — preserves the Color Preset palette. Use `Tab Color` and `Badge Text` for safety signaling.

### Shell layer changes

#### New module `home/dot_config/zshrc.d/zz-iterm2.zsh`

```zsh
# zz-iterm2.zsh — iTerm2 shell integration and terminal-side status.
# GATE: interactive-only (skipped when NG_MODE=agentic) — keeps agentic startup budget.
[[ "$NG_MODE" == "agentic" ]] && return 0
[[ -o interactive ]] || return 0

# Only inside iTerm2.
[[ "$TERM_PROGRAM" != "iTerm.app" ]] && return 0

# Source after starship, direnv, and 99-local so the vendor hook sees final prompt state.
[[ -r "$HOME/.iterm2_shell_integration.zsh" ]] &&
  source "$HOME/.iterm2_shell_integration.zsh"

_iterm2_emit_badge() {
  # Empty ITERM_BADGE_TEXT explicitly clears the badge (does not fall through
  # to the profile's static Badge Text). APS profile switches may reapply the
  # destination profile's static badge; that is accepted behavior — tab color
  # is the primary SSH safety signal, not badge text.
  local badge="${ITERM_BADGE_TEXT:-}"
  [[ "${_ITERM2_LAST_BADGE_TEXT-__unset__}" == "$badge" ]] && return 0
  _ITERM2_LAST_BADGE_TEXT="$badge"
  printf '\e]1337;SetBadgeFormat=%s\a' \
    "$(printf '%s' "$badge" | base64 | tr -d '\n')"
}

typeset -ga precmd_functions
precmd_functions=(${precmd_functions:#_iterm2_emit_badge} _iterm2_emit_badge)
```

#### direnv badge helper

In `home/dot_config/direnv/direnvrc.tmpl` (or appended to existing), add an
environment-only helper:

```bash
use_iterm_badge() {
  export ITERM_BADGE_TEXT="$*"
}
```

Per-project `.envrc` calls it:

```bash
use_iterm_badge "Nash / system-config"
```

The zsh `precmd` hook emits the actual `SetBadgeFormat` escape after direnv has
loaded or unloaded the project environment. When the user `cd`s out of the
project, direnv removes `ITERM_BADGE_TEXT`; the next prompt emits an empty badge
once and clears the terminal-side state.

#### Agentic wrapper `home/dot_local/bin/executable_agentic`

```bash
#!/usr/bin/env bash
# agentic — entry into NG_MODE=agentic from any context.
exec env NG_MODE=agentic /bin/zsh -l "$@"
```

Invocation: bare `agentic` from any shell, or bind it as a profile's Custom Command if a dedicated launcher is desired later.

### Default Bookmark setter (installer extension)

Append to `scripts/install-iterm2-profiles.sh`:

```bash
# Set Default Bookmark deterministically to our Dev profile.
DEV_PROFILE="$PROFILES_SRC/00-dev.json"
if [[ -f "$DEV_PROFILE" ]] && command -v jq &>/dev/null; then
  DEV_GUID="$(jq -r '.Profiles[0].Guid' "$DEV_PROFILE")"
  if [[ -n "$DEV_GUID" && "$DEV_GUID" != "null" ]]; then
    defaults write com.googlecode.iterm2 "Default Bookmark Guid" "$DEV_GUID"
    killall cfprefsd 2>/dev/null || true
    echo "Default Bookmark Guid → $DEV_GUID"
  fi
fi
```

`killall cfprefsd` follows the plist-cache gotcha documented in `AGENTS.md`.
After writing, the installer must read back `Default Bookmark Guid` and fail if
it did not land. If iTerm2 is running, print a warning that the user may need a
new window or restart to observe the new default profile.

## Offline guarantees

Hard requirement: shells and terminal sessions must come up cleanly with no live
internet connection. All Phase A runtime paths verified network-free.

| Path | Network at runtime? | Notes |
|------|---------------------|-------|
| `zz-iterm2.zsh` source-time | No | `[[ -r ... ]] && source` — graceful when shell-integration absent. |
| `~/.iterm2_shell_integration.zsh` body | No | Audited 2026-05-08 against pinned SHA. Only local commands: `printf`, `base64`, `tr`, `whence`, `hostname -f`. No `curl`/`wget`/`http`. |
| `_iterm2_emit_badge` precmd hook | No | Pure `printf` + `base64` of resolved badge text. Local-only. |
| Org badge fallback | No | Runs `git -C "$PWD" rev-parse --show-toplevel` only under managed org roots, cached by `PWD`. No network. |
| `agentic` wrapper | No | `exec env NG_MODE=agentic /bin/zsh -l`. No I/O. |
| `use_iterm_badge` direnv helper | No | `export ITERM_BADGE_TEXT="$*"`. Env mutation only. |
| `ng-doctor iterm2_shell_integration` probe | No | Local SHA compare against pinned value. |
| `scripts/install-iterm2-shell-integration.sh` (default mode) | **Yes** | One-time fetch via `curl`. Acceptable: install is a deliberate, online action. |
| `scripts/install-iterm2-shell-integration.sh --verify` | No | SHA compare on local file. |

`hostname -f` inside shell-integration may briefly stall if DNS is misconfigured
(macOS resolver fallthrough); it does not fail. If observed, set
`iterm2_hostname=$(hostname -s)` before sourcing shell-integration to bypass FQDN
resolution.

If the user is offline and `~/.iterm2_shell_integration.zsh` is not yet
installed, `zz-iterm2.zsh` skips silently — no error, no degraded shell. APS
won't fire and `RemoteHost`/`CurrentDir` won't be reported, which is the only
behavioral degradation. The badge precmd hook still works (env-driven).

## Phased plan

Each phase is a separate commit, independently reversible.

### Phase A — Foundation (no profile changes)

A1. Install shell-integration script via the repo-owned installer:
`scripts/install-iterm2-shell-integration.sh`. The installer pins the upstream
URL and SHA-256, fails closed on mismatch, and refuses to run iTerm2's upstream
`install_shell_integration.sh` (which mutates dotfiles). The installed file at
`~/.iterm2_shell_integration.zsh` is a generated host artifact, not chezmoi-tracked.
The pinned SHA is the only authority over what content is acceptable; bumping it
is a deliberate, reviewed commit.
A2. Add `home/dot_config/zshrc.d/zz-iterm2.zsh` (interactive-only, iTerm-only,
source-last gate). Add a one-line note to `home/dot_config/zshrc.d/99-local.zsh`
explaining that iTerm2 shell-integration loads in a later module.
A3. Add `home/dot_local/bin/executable_agentic` wrapper.
A4. Add `use_iterm_badge` helper to `home/dot_config/direnv/direnvrc.tmpl`.
A5. ng-doctor probe `iterm2_shell_integration` already added (skips if iTerm2
absent or installer missing; passes when `--verify` confirms pinned SHA).
A6. Apply via chezmoi; new shell + verify badge updates from a project `.envrc`.

**Acceptance**: Open a fresh iTerm2 tab, `cd` into a project with
`use_iterm_badge "..."` in `.envrc`, see badge update; `cd` out and see it clear.
Run `agentic` from any shell and verify `NG_MODE=agentic` propagates while
`iterm2_precmd` is absent from `precmd_functions`. Re-measure `ng-doctor agentic`.
Confirm `ng-doctor iterm2` passes (`iterm2_shell_integration` shows OK).
Confirm offline startup: disable network, open a fresh iTerm2 tab, verify shell
comes up without errors and badge precmd fires.

### Phase B — Single profile (replaces all retired)

B0. **Done.** `scripts/install-iterm2-profiles.sh` validates managed JSON/plist
files, fails on duplicate managed GUIDs, fails when a managed GUID matches a
real static iTerm2 profile, ignores iTerm2's `Is Dynamic Profile` mirror entries
when reading `New Bookmarks`, and fails if a child references a parent GUID not
loaded earlier.
B1. **Done.** Dev profile GUID:
`C4668B75-BF86-4207-B268-CA34ED11AAD8`.
B2. **Done.** `iterm2/profiles/00-dev.json` is the managed Dev profile.
B3. **Done.** `iterm2/color-presets/tokyonight-moon.itermcolors` is the managed
Color Preset artifact converted from `iterm2/themes/tokyonight-moon.json`.
B4. **Partial.** Manual/UI import remains the current proof path. Scripted
import is intentionally deferred until the `Custom Color Presets` schema is
copied from a known-good export. Do not direct-write that preference yet.
B5. **Done.** `scripts/install-iterm2-profiles.sh` sets `Default Bookmark Guid`
to the managed Dev profile.
**Leave the static profile with GUID `904E3177-4CE0-4D77-B7B6-38F2E2769773` (the
current Default Bookmark) in place** — setting `Default Bookmark Guid` to our
managed Dev profile is sufficient. Do not delete iTerm2's seeded default profile.
B6. **Current verification.** The installer passes with one managed profile and
one managed color preset. `ng-doctor`'s iTerm2 category passes its current
checks. It does not yet prove color import or badge behavior.
B7. **Done.** `Guardian L0` and `Nash Repo` profiles add path-scoped visual
signaling for `/Users/verlyn13/Organizations/the-nash-group`. This is a
documented exception to default project-path independence because the profile's
purpose is to distinguish Parent L0 context from nested repo context. See
`docs/iterm2-guardian-profiles.md`.
B8. **Done.** `Jefahnierocks Explorer` and `Jefahnierocks Repo` profiles add
path-scoped visual signaling for `/Users/verlyn13/Organizations/jefahnierocks`.
This follows the same exception model without adding commands, env blocks,
triggers, or secrets. See `docs/iterm2-jefahnierocks-profiles.md`.
B9. **Done.** Current nested Jefahnierocks repos have dedicated project profiles
with unique badges and tab/bold accents: `system-config`,
`host-capability-substrate`, `flux`, and `flux-deploy`. The generic
`Jefahnierocks Repo` profile remains as a manual/fallback template with no APS
bindings to avoid profile-switching ties.
B10. **Done.** Happy Patterns has a dedicated professional org profile plus
project profiles for `apps/scopecam`, `apps/happy-patterns-org.github.io`, and
`records`. The generic `Happy Patterns Repo` profile remains as a
manual/fallback template with no APS bindings.

**Acceptance remaining**: manually import/apply the Color Preset, verify the
new-window visual state, verify org-specific APS switches, and verify badge
updates per direnv/path fallback. Scripted color import waits for a captured
preference schema.

### Phase C — SSH variant (`Bound Hosts`)

C1. Verify reported hostnames on each Hetzner box:
`ssh hetzner-secure 'printf "%s@%s\n" "$USER" "$(hostname -f 2>/dev/null || hostname)"'` etc.
Record the exact `user@hostname` pairs that shell-integration will report.
C2. Install shell-integration on each Hetzner account that should trigger APS
(one-time per host/account). Do not gate the remote script on `TERM_PROGRAM`.
For root or accounts where login-script mutation is undesirable, use iTerm2
Triggers to report user/host or keep a wrapper fallback.
C3. Author `iterm2/profiles/05-dev-ssh.json` with `Bound Hosts` populated from C1 results.
C4. Apply installer.
C5. SSH to each host; verify auto-switch to Dev SSH profile. Disconnect; verify auto-switch back to Dev.

**Acceptance**: APS triggers cleanly on every Hetzner host. Tab color flips red on connect, returns on disconnect.

### Phase D — Cleanup

D1. Delete `iterm2/retired/` (commit message: `chore(iterm2): remove retired profiles after redesign soak`).
D2. Delete `iterm2/themes/` (superseded by `color-presets/`).
D3. Update `iterm2/README.md` to describe the hybrid design (parent file structure + APS behavior + re-enable still possible).
D4. Do not make cleanup depend on Codex memory updates. If session memory should
be updated, ask for that explicitly after the repo work lands.

## Risks / verifications still pending

| # | Risk | Mitigation |
|---|------|-----------|
| R1 | iTerm2 3.7.0beta1 may ship schema changes before final 3.7.0 | Re-verify Dynamic Profiles + Bound Hosts schema before each phase commit. |
| R2 | `Bound Hosts` patterns match reported hostnames, not SSH aliases. Hetzner default hostnames are dynamic IPs | Phase C1 verification step. May require setting stable hostnames on each box. |
| R3 | Profile switches may reset badge state without changing `ITERM_BADGE_TEXT` | Verify in Phase A5. If observed, remove the badge hook's last-value cache and re-emit every prompt. |
| R4 | Default Bookmark write requires `killall cfprefsd` to land — macOS plist cache gotcha | Already in installer above; confirm via `defaults read` after run. |
| R5 | Shell-integration adds startup cost (~50ms typical) | Module is interactive-only (skipped in agentic). Re-measure agentic startup after Phase A. |
| R6 | Color Preset import idempotency depends on chosen mechanism | Phase B4 spike: try `defaults import`, `open` URL, and direct plist key write; pick the cleanest. |
| R7 | `Dynamic Profile Parent GUID` requires 3.4.9+ — confirmed installed (3.7.0beta1) but worth re-checking on any new machine | ng-doctor or installer can `defaults read` the iTerm2 version and warn. |
| R8 | Direct terminal output from `.envrc` can corrupt `direnv export zsh` output | `.envrc` only exports `ITERM_BADGE_TEXT`; zsh emits the badge in `precmd`. |
| R9 | iTerm2 shell integration mutates `PS1`, `precmd_functions`, and `preexec_functions` | Source it last (`zz-iterm2.zsh`), skip in `NG_MODE=agentic`, inspect hook order after install. |
| R10 | One malformed DynamicProfiles plist can block all iTerm2 profile reloads | Installer validates managed files before symlinking and fails closed. |
| R11 | `Allow Clipboard Access From Terminal` lets terminal programs write the clipboard | Decided `false` on Dev 2026-05-08 (see Decisions baked in). Closes OSC 52 / 1337 SetClipboard injection vector relevant to the agentic workload on this host. Re-evaluate only if a concrete neovim/tmux relay friction is observed. |
| R12 | Shell integration skips tmux/screen by default | Do not claim APS/cwd reporting inside tmux unless `ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX` is deliberately tested. |
| R13 | `defaults write` to `Default Bookmark Guid` can race with a running iTerm2 prefs cache | Read back after write, kill `cfprefsd`, warn if iTerm2 is running, and verify with a new window. |
| R14 | Offline shell startup must remain clean | All runtime paths verified network-free (see "Offline guarantees"). Installer is the only network-dependent action; it is one-time and explicitly online. |
| R15 | Upstream shell-integration script changes invalidate the pinned SHA | Installer fails closed on mismatch with both expected and actual SHA. Bumping `EXPECTED_SHA` in `scripts/install-iterm2-shell-integration.sh` is a deliberate, reviewed commit; do not paper over a mismatch. |
| R16 | Installing iTerm2 utilities (`~/.iterm2/`) silently mutates `~/.iterm2_shell_integration.zsh` (appends aliases) and breaks SHA pinning | Phase A explicitly does not install utilities. If utilities become required, the decision is a separate Phase B/C item: prefer `/Applications/iTerm.app/Contents/Resources/utilities` with a managed PATH entry over `~/.iterm2/`. |
| R17 | Org path APS could choose the parent profile over a child wildcard rule | Child repo rules are host-qualified (`*:/path`) while parent rules are path-only, so child rules have a higher APS score. |

## Decisions baked in (vs the Option-list discussion)

| Decision | Choice | Why |
|----------|--------|-----|
| Badge owner | direnv exports text; zsh emits badge escape | Project-path independent without unsafe `.envrc` terminal output. |
| Agentic invocation | Wrapper script (no profile) | Decouples agentic from iTerm2 entirely. |
| SSH safety | APS (declarative `Bound Hosts`) with wrapper as fallback if APS misses | Cleanest auto-switch; wrapper is escape hatch. |
| Themes | Color Presets (runtime-swappable) | Decouples palette from profile; rebrand by import. |
| Default Bookmark | Installer sets it deterministically | Consistent setup across machines; matches "deterministic" goal. |
| Shell-integration scope | Interactive only (skipped in agentic) | Preserves agentic startup budget. |
| Clipboard write (`Allow Clipboard Access From Terminal`) | `false` on Dev (and inherited by SSH variant in Phase C) | Closes OSC 52 / OSC 1337 SetClipboard injection vector. This workstation runs agentic tools (Claude Code, Codex, MCP) that pipe untrusted remote text through the terminal — any such text containing a clipboard-write escape would silently overwrite the system clipboard. Industry default for hardened multi-host setups. Read access (paste) unaffected. Escape hatch: edit the field to `true` in `iterm2/profiles/00-dev.json` and re-run `scripts/install-iterm2-profiles.sh`; iTerm2 reloads dynamically. Add a sibling "Dev (clipboard)" profile only if friction emerges in practice — do not pre-build. Decided 2026-05-08. |
| Nash Guardian profiles | Path-scoped visual exception | The user explicitly wants Parent L0 and nested-repo visual separation for `~/Organizations/the-nash-group`; the exception is documented and does not set commands, env, working directories, or secrets. |
| Jefahnierocks Explorer profiles | Path-scoped visual exception | The user explicitly wants personal Explorer and nested-repo visual separation for `~/Organizations/jefahnierocks`; the exception is documented and keeps clipboard/triggers/global preferences under existing policy. |
| Happy Patterns Professional profiles | Path-scoped visual exception | The user explicitly wants professional org and nested-repo visual separation for `~/Organizations/happy-patterns`; the exception is documented and keeps clipboard/triggers/global preferences under existing policy. |

## Out of scope

- Triggers (regex on output → action). Useful but adds maintenance; revisit after redesign settles.
- Custom Python status bar components. Optional; the standard built-ins (hostname, cwd, clock) cover current needs.
- Tmux integration mode (`tmux -CC`). Orthogonal.
- Per-project profile overrides via direnv. Possible via `printf '\e]1337;SetProfile=NAME\a'` but adds runtime profile churn; defer.
- iTerm2 **utilities package** (`~/.iterm2/`: `it2copy`, `it2setcolor`, `imgcat`, `it2getvar`, etc.). Phase A is escape-code only. If utilities become necessary later, that's a separate decision documented as part of the Phase B/C scope expansion. Two viable shapes if/when revisited: (a) use the app-bundled set at `/Applications/iTerm.app/Contents/Resources/utilities/` with a managed PATH entry; (b) repo-owned install of `~/.iterm2/`. Do **not** run iTerm2's combined `install_shell_integration_and_utilities.sh` — it appends aliases to the shell-integration file and breaks SHA pinning.

## References

- [Dynamic Profiles documentation](https://iterm2.com/documentation-dynamic-profiles.html)
- [Automatic Profile Switching documentation](https://iterm2.com/documentation-automatic-profile-switching.html)
- [Shell Integration documentation](https://iterm2.com/documentation-shell-integration.html)
- [Utilities documentation](https://iterm2.com/documentation-utilities.html)
- [Escape Codes documentation](https://iterm2.com/documentation-escape-codes.html)
- [Badges documentation](https://iterm2.com/documentation-badges.html)
- Real-world `Bound Hosts` examples: [bedezign/ssh-to-iterm2](https://github.com/bedezign/ssh-to-iterm2), [AlexRex/mac-setup](https://github.com/AlexRex/mac-setup/blob/master/iterm2-profile.json)
- Retired predecessor: `iterm2/retired/` (kept until Phase D)
- ng-doctor source-driven check: `home/dot_local/bin/executable_ng-doctor.tmpl` § iterm2

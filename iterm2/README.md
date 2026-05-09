# iTerm2 Dynamic Profiles

iTerm2 is an adapter layer, not a system boundary. Shell/runtime policy lives in chezmoi-managed shell config. iTerm2-managed artifacts are limited to profile presentation and session entrypoints.

## Active managed profiles

| File | Profile name | Purpose |
|------|--------------|---------|
| `profiles/00-dev.json` | `Dev` | Default presentation profile (font, scrollback, key bindings). No working directory, no command, no env block — behavior is shell-driven. |
| `profiles/10-nash-guardian-l0.json` | `Guardian L0` | Path-scoped Parent L0 visual profile for `/Users/verlyn13/Organizations/the-nash-group`. |
| `profiles/11-nash-repos.json` | `Nash Repo` | Distinct path-scoped visual profile for known nested repos under The Nash Group org directory. |

The Dev profile is set as iTerm2's Default Bookmark by `scripts/install-iterm2-profiles.sh`. The pre-existing static default profile (GUID `904E3177-…`) is **not** removed; we only redirect `Default Bookmark Guid` to the managed Dev profile.

Current status: Phase B is partially landed. The Dev profile, Default Bookmark,
and Nash path-scoped visual profiles are managed. The
`color-presets/tokyonight-moon.itermcolors` preset is validated by the
installer. Color Preset import/application is still manual; the repo does not
write iTerm2's `Custom Color Presets` preference yet.

## Authoritative design

`docs/iterm2-profile-redesign.md` is the authoritative design document. Phase A (shell-integration foundation) landed 2026-05-08. Phase B (managed Dev profile) is the active phase. Phases C (SSH variant via `Bound Hosts`) and D (cleanup) follow.

`docs/iterm2-guardian-profiles.md` records the repo-owned Guardian/Nash profile
customization rules.

## Directories

| Path | Purpose |
|------|---------|
| `profiles/` | Active source for `scripts/install-iterm2-profiles.sh`. Each `*.json` becomes a symlink in iTerm2's `DynamicProfiles/`. |
| `color-presets/` | Active source for managed `.itermcolors` color presets. The installer validates these files but does not import them into iTerm2 preferences yet. |
| `retired/` | Historical profiles from the pre-redesign era, suffix-marked `[retired]`. Kept until Phase D cleanup. |
| `themes/` | Color-only reference presets (tokyonight-moon, tokyonight-storm, wild-cherry). Not loaded as profiles. Superseded by `color-presets/` in Phase B. |

## Installer

```bash
scripts/install-iterm2-profiles.sh
```

Behavior:

1. **Validate** every `iterm2/profiles/*.json` (jq + plutil), check GUID conflicts (managed-vs-managed and managed-vs-static), check parent ordering, and validate managed `.itermcolors` presets. Fail-closed — on any validation failure, existing symlinks are left intact.
2. **Install symlinks** into `~/Library/Application Support/iTerm2/DynamicProfiles/`, removing stale managed entries whose source is gone.
3. **GUID-uniqueness sanity** across the whole `DynamicProfiles/` directory (includes app-managed files like `OrbStack.json`).
4. **Default Bookmark** — if `00-dev.json` exists, set its GUID as `Default Bookmark Guid` in `com.googlecode.iterm2.plist` (idempotent, with `killall cfprefsd` and read-back).

## Adding a profile

```bash
uuidgen              # generate a fresh GUID
# author iterm2/profiles/NN-name.json with that GUID
scripts/install-iterm2-profiles.sh
```

iTerm2 watches `DynamicProfiles/` and reloads automatically; no restart needed.

## Re-enabling a retired profile

```bash
git mv iterm2/retired/<file>.json iterm2/profiles/
# strip the "[retired]" suffix from the Name field
scripts/install-iterm2-profiles.sh
```

## Policy

- `LoadPrefsFromCustomFolder`: disabled. Standard macOS prefs path.
- Dynamic profiles only when active; do not manage `com.googlecode.iterm2.plist` directly except for `Default Bookmark Guid` via the installer.
- Color Preset import remains manual until the `Custom Color Presets` preference schema is captured from a known-good iTerm2 export. Do not direct-write that preference from this repo yet.
- zsh is the only managed shell entrypoint, ever (no fish — see `feedback_avoid_fish.md`).
- HCS uses whichever profile is active; it does not own its own iTerm2 profile (per HCS boundary §11.1).

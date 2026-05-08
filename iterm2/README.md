# iTerm2 Dynamic Profiles

iTerm2 is an adapter layer, not a system boundary. Shell/runtime policy lives in chezmoi-managed shell config. iTerm2-managed artifacts are limited to profile presentation and session entrypoints.

## Current state — no managed dynamic profiles

The previously-managed profiles (NG Base, Dev (zsh), Agentic (zsh), 3 Hetzner SSH profiles) are **retired**. iTerm2 falls back to its built-in Default profile (whatever `Default Bookmark Guid` resolves to in `com.googlecode.iterm2.plist`).

The retired JSONs are kept in [`retired/`](./retired/) as historical reference. Each profile's `Name` field carries a `[retired]` suffix so it's obvious they are not the active config if anyone loads them by hand.

## Directories

| Path | Purpose |
|------|---------|
| `profiles/` | Active source for `scripts/install-iterm2-profiles.sh`. Currently empty (only `.gitkeep`). Drop a JSON here to re-activate it. |
| `retired/` | Historical profiles, suffix-marked, not installed. |
| `themes/` | Color-only reference presets (tokyonight-moon, tokyonight-storm, wild-cherry). Not loaded as profiles. |

## Installer

```bash
scripts/install-iterm2-profiles.sh
```

Behavior unchanged. With `profiles/` empty, the script:

- removes any stale managed symlinks in `~/Library/Application Support/iTerm2/DynamicProfiles/` whose source no longer exists,
- installs nothing,
- runs the GUID-uniqueness check on whatever remains in DynamicProfiles (e.g., app-managed `OrbStack.json`).

## Re-enabling a profile

```bash
git mv iterm2/retired/<file>.json iterm2/profiles/
# remove the "[retired]" suffix from the Name field
scripts/install-iterm2-profiles.sh
```

iTerm2 watches DynamicProfiles and reloads automatically; no restart needed.

## Policy

- `LoadPrefsFromCustomFolder`: disabled. Standard macOS prefs path.
- Dynamic profiles only when active; do not manage `com.googlecode.iterm2.plist` directly.
- zsh is the only managed shell entrypoint, ever (no fish — see `feedback_avoid_fish.md`).
- HCS uses whichever profile is active; it does not own its own iTerm2 profile (per HCS boundary §11.1).

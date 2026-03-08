# iTerm2 Dynamic Profiles

iTerm2 is an adapter layer, not a system boundary. Shell/runtime policy lives in
chezmoi-managed shell config. iTerm2-managed artifacts are limited to profile
presentation and session entrypoints.

## Profile Architecture

One base parent profile + thin child profiles that override only command/env/working-dir.

| File | Profiles | Purpose |
|------|----------|---------|
| `00-base.json` | NG Base | Shared colors (Tokyo Night Moon), font, terminal settings. No command. |
| `01-dev-zsh.json` | Dev (zsh) | Day-to-day development. `/bin/zsh -l`, starship prompt. |
| `02-agentic-zsh.json` | Agentic (zsh) | AI agent sessions. `/bin/zsh -l` with `NG_MODE=agentic`. |
| `03-human-fish.json` | Human (fish) | Interactive human use. `/opt/homebrew/bin/fish -l`. |
| `10-servers.json` | 3 Hetzner SSH profiles | Production/Docker/Tailscale. Standalone (own colors). |

## Ownership

| Source | Owner | Managed by |
|--------|-------|------------|
| `00-*.json` through `10-*.json` | system-config | `scripts/install-iterm2-profiles.sh` |
| `OrbStack.json` | OrbStack app | OrbStack (do not modify) |

No other files should exist in `~/Library/Application Support/iTerm2/DynamicProfiles/`.

## Themes

Color-only presets in `themes/`. Not loaded as dynamic profiles — reference files
for manual import or for overriding the base profile's colors.

- `tokyonight-moon.json` — default (used by base profile)
- `tokyonight-storm.json` — darker variant
- `wild-cherry.json` — pink/cherry accent palette

## Installation

```bash
scripts/install-iterm2-profiles.sh
```

Symlinks profile JSONs directly into `~/Library/Application Support/iTerm2/DynamicProfiles/`.
Idempotent. Includes GUID conflict check.

## Policy

- `LoadPrefsFromCustomFolder`: disabled. iTerm2 uses standard macOS preferences.
- `Rewritable`: omitted (defaults to false). JSON files are source of truth.
- Dynamic profiles only — no profiles baked into the plist.
- Files numbered for load order (iTerm2 loads alphabetically; parents before children).

# iTerm2 Dynamic Profiles

iTerm2 is an adapter layer, not a system boundary. Shell/runtime policy lives in chezmoi-managed shell config. iTerm2-managed artifacts are limited to profile presentation and session entrypoints.

## Profile Architecture

One base parent profile plus thin child profiles that override only command, env, or working directory.

| File | Profiles | Purpose |
|------|----------|---------|
| `00-base.json` | NG Base | Shared colors, font, and terminal settings. No command. |
| `01-dev-zsh.json` | Dev (zsh) | Day-to-day development. `/bin/zsh -l`. |
| `02-agentic-zsh.json` | Agentic (zsh) | AI agent sessions. `/bin/zsh -l` with `NG_MODE=agentic`. |
| `10-servers.json` | Hetzner SSH profiles | Standalone server profiles. |

## Ownership

| Source | Owner | Managed by |
|--------|-------|------------|
| `00-*.json` through `10-*.json` | system-config | `scripts/install-iterm2-profiles.sh` |
| `OrbStack.json` | OrbStack app | OrbStack (do not modify) |

The installer removes stale managed symlinks for deleted profiles before re-linking the current set.

## Themes

Color-only presets live in `themes/`. They are not loaded as dynamic profiles.

## Installation

```bash
scripts/install-iterm2-profiles.sh
```

The script symlinks profile JSONs into `~/Library/Application Support/iTerm2/DynamicProfiles/`, verifies GUID uniqueness, and is safe to rerun.

## Policy

- `LoadPrefsFromCustomFolder`: disabled
- Dynamic profiles only; do not manage `com.googlecode.iterm2.plist`
- Files are numbered for load order
- zsh is the only managed shell entrypoint in these profiles

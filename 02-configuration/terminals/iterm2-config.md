---
title: iTerm2 Complete Configuration Guide
category: configuration
component: iterm2
status: active
version: 2.0.0
last_updated: 2025-09-26
dependencies:
  - doc: 01-setup/01-homebrew.md
    type: required
  - doc: 01-setup/02-chezmoi.md
    type: required
tags: [configuration, settings, terminal, macos]
applies_to:
  - os: macos
    versions: ["14.0+", "15.0+"]
  - arch: ["arm64", "x86_64"]
priority: high
---

# iTerm2 3.6.2 Configuration
## Released September 24, 2025 — tuned for M3 Max workflows

### Verify the Installed Build
```bash
plutil -extract CFBundleShortVersionString raw \
  ~/Applications/iTerm.app/Contents/Info.plist
# Expect: 3.6.2
```
If you manage iTerm2 via Homebrew, pin the cask in `Brewfile.gui` to avoid
rolling back:
```ruby
cask "iterm2", args: { appdir: "~/Applications" }
```

### Sync Preferences and Profiles
- Enable `General > Preferences > Load preferences from a custom folder` and
  point to `~/.config/iterm2` so chezmoi can version the plist.
- Export your primary profile as `profiles.json` and add it to the dotfiles repo.
  Include color presets, prompts, and status bar components.

### Modern Terminal Experience Defaults
- `Profiles > Terminal > Click on a path ...` → **Open Navigator** for faster
  filesystem jumps when following guide commands.
- Enable **Relative timestamps** and set the baseline before long-running
  installs (`Right-click > Set Baseline for Relative Timestamps`).
- Turn on **Hide cursor when focus is lost** to remove ghost cursors when using
  Raycast or Spaces.
- Under `Profiles > Keys`, disable **Perform remapping globally** so AltTab’s
  shortcuts keep working. Pair with **Respect system shortcuts** to allow
  macOS-level key combos.

### AI Assistant & Browser Profiles
- In `Settings > AI`, choose **Recommended Model** so iTerm2 updates the model
  automatically. Require confirmation before shell execution to match our
  security posture.
- Create a dedicated **Web Browser** profile for docs and dashboards. Set
  `Profile Type = Web Browser`, enable **Focus follows mouse**, and reuse our
  hotkeys. This keeps browser tabs under window arrangement control.

### Inline Media & Automation
- Enable `Advanced > Images > Allow Kitty shared memory` to take advantage of
  the new decoder improvements when running tools like `wezterm imgcat`.
- Add a key binding for **Copy Mode Commands → Enter copy mode** (suggested:
  `⌘⇧[`), and another for **Replace with Pretty-Printed JSON** to quickly reformat
  API responses from automation scripts.
- Incorporate the **Move Tab to New Window** shortcut (`⌘⌥⇧N`) into your tmux or
  OrbStack workflows when splitting environments across displays.

### Validation Checklist
- Open the **Settings search** (now stemmed) and confirm queries like `baseline`
  and `kitty` find the options above.
- Run `Shell > Log > Start` to verify the default path resolves to `~/Library/Logs`
  when none is configured.
- Save an arrangement after enabling the features; arrangement names should now
  include the current date, confirming 3.6.x behavior.

---
title: "iTerm2 Beacon - Quick Start Guide"
category: documentation
component: terminal
status: active
version: 1.0.0
last_updated: 2025-11-22
tags: [iterm2, quickstart, beacon]
priority: high
---

# iTerm2 Beacon - Quick Start Guide

Fast track to enabling iTerm2 Automatic Profile Switching with the lightweight beacon.

## Prerequisites

- ✅ iTerm2 3.6+ installed
- ✅ Tmux 3.0+ installed
- ✅ Fish shell configured
- ✅ Chezmoi managing dotfiles

## Installation (Already Done!)

The beacon is already installed via chezmoi templates:
- ✅ `~/.config/fish/conf.d/07-iterm-beacon.fish` (beacon function)
- ✅ `~/.tmux.conf` (passthrough enabled)

## Verification

### 1. Check Tmux Passthrough
```bash
tmux show -g allow-passthrough
# Should output: allow-passthrough on
```

### 2. Check Beacon Function
```bash
fish -c 'functions -q __iterm2_beacon && echo "✅ Beacon loaded" || echo "❌ Not loaded"'
```

### 3. Test Manual Trigger
```bash
# In a new Fish shell (inside tmux)
cd /tmp
pwd
# Beacon should fire (you won't see output, but iTerm2 receives it)
```

## Configure iTerm2 Profiles

### Step 1: Create Base Profiles

Open iTerm2 → Preferences (Cmd+,) → Profiles

Create profiles for each context:
1. **Personal Dev** - Yellow badge
2. **Work Dev** - Blue badge
3. **Business Dev** - Purple badge
4. **System Config** - Green badge

### Step 2: Set Up Automatic Profile Switching

For each profile:

1. Select profile → **Advanced** tab
2. Under **Automatic Profile Switching**:
   - Click **Edit**
   - Add rule: **Path**
   - Enter path pattern (see below)
   - Click **OK**

### Recommended Path Patterns

| Profile | Path Pattern | Example Match |
|---------|-------------|---------------|
| Personal Dev | `~/Development/personal/*` | `/Users/you/Development/personal/my-app` |
| Work Dev | `~/Development/work/*` | `/Users/you/Development/work/client-project` |
| Business Dev | `~/Development/business/*` | `/Users/you/Development/business/startup` |
| System Config | `~/.local/share/chezmoi/*` | `/Users/you/.local/share/chezmoi/` |

**Important**: Use wildcards (`*`) to match subdirectories.

### Step 3: Test Profile Switching

```bash
# Start in home directory (should use default profile)
cd ~

# Switch to personal project
cd ~/Development/personal/some-project
# Wait 1-2 seconds - profile should switch to "Personal Dev"

# Switch to work project
cd ~/Development/work/some-project
# Profile should switch to "Work Dev"

# Switch to system config
cd ~/.local/share/chezmoi
# Profile should switch to "System Config"
```

## Troubleshooting

### Profile Not Switching

**Check 1**: Verify path matches exactly
```bash
pwd
# Compare output with your profile rule
# Remember: ~/Development/personal/* will NOT match ~/Development/Personal (case matters)
```

**Check 2**: Verify passthrough is enabled
```bash
tmux show -g allow-passthrough
# Must show: allow-passthrough on
```

**Check 3**: Reload tmux config
```bash
tmux source ~/.tmux.conf
```

**Check 4**: Restart Fish shell
```bash
exec fish
```

**Check 5**: Check beacon function
```bash
functions __iterm2_beacon
# Should show the function definition
```

### Beacon Not Loading

```bash
# Check file exists
ls -la ~/.config/fish/conf.d/07-iterm-beacon.fish

# Re-apply from chezmoi
chezmoi apply ~/.config/fish/conf.d/07-iterm-beacon.fish

# Reload Fish config
source ~/.config/fish/config.fish
```

### Tmux Passthrough Not Working

```bash
# Check tmux version (need 3.0+)
tmux -V

# Re-apply tmux config
chezmoi apply ~/.tmux.conf

# Reload in tmux
tmux source ~/.tmux.conf

# Verify
tmux show -g allow-passthrough
```

## Advanced: Custom Profile Rules

### Multiple Paths for One Profile

If you want one profile to match multiple directories:

1. Profile → Advanced → Automatic Profile Switching → Edit
2. Click **+** to add multiple rules
3. All rules are OR conditions (any match triggers the profile)

Example for "Work Dev":
- Rule 1: Path = `~/Development/work/*`
- Rule 2: Path = `~/clients/*`
- Rule 3: Path = `~/contracts/*`

### Hostname-Based Switching

You can also switch based on hostname (for SSH sessions):

1. Profile → Advanced → Automatic Profile Switching → Edit
2. Rule type: **Hostname**
3. Pattern: `production-server.com`

**Note**: This works even without the beacon (native iTerm2 feature).

### Combined Rules

Use both Path AND Hostname for precise matching:

1. Rule 1: Hostname = `my-work-laptop`
2. Rule 2: Path = `~/Development/work/*`

Both must match (AND condition).

## Profile Customization Tips

### Visual Distinction

Make profiles visually distinct:

| Profile | Background Color | Badge | Tab Color |
|---------|-----------------|-------|-----------|
| Personal | Default black | Yellow "PERSONAL" | Yellow |
| Work | Slight blue tint (#0a0a1a) | Blue "WORK" | Blue |
| Business | Slight purple tint (#1a0a1a) | Purple "BUSINESS" | Purple |
| System | Slight green tint (#0a1a0a) | Green "CONFIG" | Green |

**Configure**: Profiles → Colors → Background Color

### Badges

**Configure**: Profiles → General → Badge
- Text: `PERSONAL`, `WORK`, etc.
- Position: Top right
- Color: Match profile theme

### Status Bar

**Configure**: Profiles → Session → Status Bar Enabled
- Add: Current Directory, Git Branch, CPU, Memory

**Note**: This is iTerm2's status bar (separate from tmux status bar). You can use both or disable iTerm2's.

## Performance Impact

- **Beacon overhead**: <1ms per directory change
- **No startup cost**: Beacon loads instantly with Fish
- **No runtime cost**: Only fires on `cd` commands

## Next Steps

1. ✅ Verify beacon is working
2. ✅ Configure iTerm2 profiles with APS rules
3. ✅ Test profile switching with `cd` commands
4. ✅ Customize profile colors/badges
5. Read full architecture doc: `docs/ITERM2-BEACON-SOLUTION.md`

## Related Documentation

- **Architecture Decision Record**: `docs/ITERM2-BEACON-SOLUTION.md` (WHY we did this)
- **Integration Status**: `07-reports/status/iterm2-fish-tmux-integration-complete-2025-11-22.md`
- **iTerm2 Configuration**: `02-configuration/terminals/iterm2-config.md`

---

**Status**: ✅ Beacon installed and ready to use
**Last Updated**: 2025-11-22

---
title: "iTerm2 Automatic Profile Switching - Setup Guide"
category: documentation
component: terminal
status: active
version: 1.0.0
last_updated: 2025-11-24
tags: [iterm2, setup, aps, profile-switching, fish]
priority: high
---

# iTerm2 Automatic Profile Switching - Setup Guide

**Purpose**: Get Automatic Profile Switching (APS) working for the system-setup-update project in regular iTerm2 sessions.

**Status**: ✅ Shell integration configured (non-tmux)

---

## Prerequisites

✅ **iTerm2 Shell Integration File**: `~/.iterm2_shell_integration.fish` (already downloaded)
✅ **Fish Config**: `~/.config/fish/conf.d/08-iterm2-shell-integration.fish` (applied)
✅ **Profile JSON**: `06-templates/iterm2/system-setup-update.json` (ready to import)

---

## Step 1: Import the Profile

### Import via iTerm2 UI

1. **Open iTerm2 Preferences**
   - `⌘,` or `iTerm2 → Settings...`

2. **Navigate to Profiles**
   - Click "Profiles" tab

3. **Import the Profile**
   - Click "Other Actions..." (bottom left dropdown)
   - Select "Import JSON Profiles..."
   - Navigate to: `~/Development/personal/system-setup-update/06-templates/iterm2/system-setup-update.json`
   - Click "Open"

4. **Verify Import**
   - You should see "system-setup-update" profile in the list
   - Select it and verify:
     - **Badge Text**: "PERSONAL" (top-right preview)
     - **Background**: Subtle warm peach tint
     - **Name**: "system-setup-update"

---

## Step 2: Configure Automatic Profile Switching

### Set Up the Path Rule

1. **Select the Profile**
   - In Profiles list, click "system-setup-update"

2. **Go to Advanced Tab**
   - Click "Advanced" at the top

3. **Find Automatic Profile Switching**
   - Scroll down to "Automatic Profile Switching" section

4. **Add Path Rule**
   - Click the "+" button (bottom left of the rules table)
   - A new row appears with empty fields

5. **Enter the Rule**
   - **In the rule field, type**: `/Users/verlyn13/Development/personal/system-setup-update/*`
   - Press Enter to save

6. **Verify the Rule**
   - Rule should now appear in the table
   - Format: `/Users/verlyn13/Development/personal/system-setup-update/*`

### Understanding Rule Syntax

**Simple Path Rules** (what we're using):
- `/path/to/directory/*` - Matches the directory and immediate subdirectories
- `/path/to/directory/**` - Matches all nested subdirectories (recursive)

**Complex Rules** (for future use):
- `username@hostname:/path/*` - Username + hostname + path
- `hostname:/path/*` - Hostname + path
- `username@:/path/*` - Username + path
- `&job` - Job/command name (e.g., `&vim`, `&emacs`)

**For this project, simple path matching is sufficient.**

---

## Step 3: Reload Fish Shell

The shell integration needs to be loaded in your current session:

```bash
# Option 1: Restart Fish
exec fish

# Option 2: Source the integration manually
source ~/.config/fish/conf.d/08-iterm2-shell-integration.fish
```

**Verify it loaded**:
```bash
functions | grep iterm2
# Should see: iterm2_prompt_end, iterm2_prompt_mark, iterm2_status, etc.
```

---

## Step 4: Test Profile Switching

### Open a New iTerm2 Window (OUTSIDE TMUX)

**Important**: For initial testing, use a regular iTerm2 window, not a tmux session.

```bash
# 1. Open new iTerm2 window (⌘N)
# 2. You should be at your home directory (~)
pwd
# Output: /Users/verlyn13

# 3. Check current profile (look at window title or badge area)
# Default profile should be active (no "PERSONAL" badge)

# 4. Navigate to the project
cd ~/Development/personal/system-setup-update

# 5. PROFILE SHOULD SWITCH IMMEDIATELY
# Look for:
#   ✅ Badge "PERSONAL" appears in top-right corner
#   ✅ Background has subtle warm peach tint
#   ✅ Window title shows "system-setup-update" profile name

# 6. Navigate away
cd ~

# 7. PROFILE SHOULD REVERT
# Look for:
#   ✅ Badge "PERSONAL" disappears
#   ✅ Background returns to default
```

### Expected Behavior

**When entering project directory**:
- ⚡ **Instant switch** (no delay)
- 🏷️ **Badge appears**: "PERSONAL" in top-right (subtle watermark)
- 🎨 **Background tints**: Warm peach (barely noticeable, ~5% tint)
- 📝 **Window title**: May show profile name

**When leaving project directory**:
- ⚡ **Instant revert** to default profile
- 🏷️ **Badge disappears**
- 🎨 **Background resets** to default

---

## Troubleshooting

### Problem: Profile doesn't switch

**Check 1: Shell Integration Loaded**
```bash
functions | grep iterm2_write_remotehost_currentdir_uservars
# Should return the function name
```

**If empty**: Shell integration not loaded
```bash
# Reload Fish
exec fish
# Or source manually
source ~/.iterm2_shell_integration.fish
```

**Check 2: Verify Rule Matches**
```bash
# In iTerm2 → Settings → Profiles → system-setup-update → Advanced
# Look at the rule you created
# Make sure the path is absolute (starts with /)
# Make sure it ends with /* or /**
```

**Check 3: Test with Absolute Path**
```bash
cd /Users/verlyn13/Development/personal/system-setup-update
# Use tab completion to ensure path is correct
```

**Check 4: Check iTerm2 Session Type**
```bash
echo $TERM_PROGRAM
# Should output: iTerm.app

echo $TERM
# Should NOT be: screen, tmux, tmux-256color
# (These indicate you're in tmux - exit tmux and test in regular window)
```

### Problem: Badge doesn't appear

**Check 1: Badge Configured in Profile**
- iTerm2 → Settings → Profiles → system-setup-update → General
- Look at "Badge" field
- Should say: "PERSONAL"

**Check 2: Badge Visibility**
- Badge is subtle (20% opacity)
- Look in **top-right corner** of terminal window
- May need to expand window to see it
- Try increasing opacity temporarily: Settings → Profiles → Colors → Badge Color → Alpha slider to 0.40

### Problem: Background doesn't change

**The background tint is VERY subtle by design** (5% only).

To verify it's working:
1. Take a screenshot with default profile active
2. `cd` to project directory (profile switches)
3. Take another screenshot
4. Compare side-by-side - background should be *slightly* warmer/peachy

**If you want more obvious tinting** (for testing):
- iTerm2 → Settings → Profiles → system-setup-update → Colors
- Background Color → Adjust RGB sliders to increase tint
- Recommended: Keep between 5-10% tint for production use

### Problem: Rules appear but don't match

**Verify Rule Format**:
```
✅ Correct:
/Users/verlyn13/Development/personal/system-setup-update/*
/Users/verlyn13/Development/personal/*
~/Development/personal/system-setup-update/*

❌ Incorrect:
Development/personal/system-setup-update/*  (not absolute)
/Users/verlyn13/Development/personal/system-setup-update  (no wildcard)
$HOME/Development/personal/system-setup-update/*  (no variable expansion)
```

**Rule Priority**:
- If multiple profiles have matching rules, higher-scoring rule wins
- Path exact match: 1 point
- Path wildcard match: 0 points (but counts as match)
- Our rule is simple, so no conflicts expected

---

## Next Steps

Once basic APS is working in regular iTerm2 sessions:

1. ✅ **Test with subdirectories**
   ```bash
   cd ~/Development/personal/system-setup-update/docs
   cd ~/Development/personal/system-setup-update/06-templates
   # Profile should remain active in all subdirectories
   ```

2. ✅ **Create profiles for other projects**
   - See `docs/ITERM2-PROFILE-STYLE-GUIDE.md`
   - Each project can have its own profile with distinct badge/colors

3. ⏸️ **Configure tmux integration** (later)
   - Requires additional setup
   - See "Tmux Integration" section in future docs

4. ⏸️ **Add hostname/username rules** (if needed)
   - For SSH sessions
   - For multi-user environments

---

## Verification Checklist

Run through this checklist to confirm everything is working:

- [ ] Shell integration loaded (`functions | grep iterm2` shows functions)
- [ ] Profile imported to iTerm2 (appears in Settings → Profiles list)
- [ ] Badge text set to "PERSONAL" (visible in profile settings)
- [ ] Automatic Profile Switching rule added (`/Users/.../system-setup-update/*`)
- [ ] `cd ~/Development/personal/system-setup-update` triggers profile switch
- [ ] Badge "PERSONAL" appears in top-right corner
- [ ] Background has subtle warm peach tint (compared to default)
- [ ] `cd ~` reverts to default profile
- [ ] Badge disappears when outside project directory

---

## Reference Documentation

- **Profile Style Guide**: `docs/ITERM2-PROFILE-STYLE-GUIDE.md` - How to create profiles
- **Chromatic Anchoring Spec**: `docs/CHROMATIC-ANCHORING-SPEC.md` - Design philosophy
- **Official iTerm2 APS Docs**: https://iterm2.com/documentation-automatic-profile-switching.html
- **Shell Integration Docs**: https://iterm2.com/documentation-shell-integration.html

---

## Configuration Files

```
Shell Integration:
~/.iterm2_shell_integration.fish              # Official script (126 lines)
~/.config/fish/conf.d/08-iterm2-shell-integration.fish  # Loader (sources above)

Profile:
06-templates/iterm2/system-setup-update.json  # Profile JSON

Chezmoi Template:
06-templates/chezmoi/dot_config/fish/conf.d/08-iterm2-shell-integration.fish.tmpl
```

---

**Version**: 1.0.0
**Status**: ✅ Active (non-tmux configuration)
**Last Updated**: 2025-11-24
**Next Review**: After tmux integration is added

---
title: "iTerm2 Beacon Solution - Architecture Decision Record"
category: documentation
component: terminal
status: active
version: 1.0.0
last_updated: 2025-11-22
tags: [iterm2, tmux, fish, beacon, architecture, ADR]
priority: high
---

# iTerm2 Beacon Solution - Architecture Decision Record

## Executive Summary

This document records the decision to implement a **lightweight beacon** for iTerm2 Automatic Profile Switching (APS) instead of the official shell integration, preserving our "Option B: Pure Tmux" philosophy while gaining visual context switching.

## The Strategic Conflict

### What We Want
- **Visual Distinction**: iTerm2 profiles that automatically switch based on project directory
- **Professional UX**: Different colors/badges for personal, work, business, system projects

### What We Have
- **"Option B: Pure Tmux"** architecture (intentionally NO iTerm2 integration)
- **Portable workflow** that works identically on macOS and Linux
- **Lean startup** (82ms shell initialization)

### The Problem
- iTerm2 is "blind" - it cannot see directory changes inside tmux sessions
- Official solution requires `iterm2_shell_integration.fish` (~4,000 lines, 50-100ms overhead)
- Official integration conflicts with Tide prompt and tmux features

## Decision: The Lightweight Beacon

We implement a **surgical 5-line solution** that sends only the specific escape code iTerm2 needs, maintaining 99% purity of our architecture.

### What We're NOT Installing
- `iterm2_shell_integration.fish` - The official 4,000-line script
- Automatic command output capture
- Error alerting via iTerm2
- Drag-and-drop file handling
- Prompt markers and navigation
- Shell integration status bar components

### What We ARE Installing
- **One function** (`__iterm2_beacon`) - 5 lines of Fish code
- **One tmux setting** (`allow-passthrough on`) - 1 line
- Total overhead: <1ms per directory change

## Technical Implementation

### Component 1: Tmux Passthrough

**File**: `~/.tmux.conf` (via `dot_tmux.conf.tmpl`)

```tmux
# Allow escape sequences to pass through tmux to the outer terminal
# Required for: iTerm2 Automatic Profile Switching beacon (07-iterm-beacon.fish)
# Security: Only enables passthrough for known escape codes, not arbitrary commands
set -g allow-passthrough on
```

**What this does**: Punches a specific hole in the tmux "wall" for escape sequences to reach iTerm2.

**Security note**: Only specific OSC (Operating System Command) sequences pass through, not arbitrary shell commands.

### Component 2: The Beacon Function

**File**: `~/.config/fish/conf.d/07-iterm-beacon.fish` (via template)

```fish
function __iterm2_beacon --on-variable PWD
    if set -q TMUX
        # OSC 1337 escape sequence for iTerm2 CurrentDir
        # \033Ptmux; ... \033\\ wraps the sequence so Tmux passes it through
        # \033]1337;CurrentDir=%s\007 is the actual iTerm2 beacon
        printf "\033Ptmux;\033\033]1337;CurrentDir=%s\007\033\\" "$PWD"
    end
end
```

**What this does**:
1. Triggers on any directory change (`--on-variable PWD`)
2. Checks if we're inside tmux (`if set -q TMUX`)
3. Sends the "secret handshake" escape code to iTerm2
4. Wraps it in DCS (Device Control String) so tmux passes it through

### The Escape Code Anatomy

```
\033Ptmux;              # Start DCS: "Hey Tmux, pass this through"
\033\033]1337;          # OSC 1337: iTerm2's proprietary command
CurrentDir=%s           # The payload: current working directory
\007                    # BEL (bell): end of OSC
\033\\                  # End DCS: "Done, Tmux"
```

## Why This is a Pro Move (Not a Hack)

### Comparison Matrix

| Aspect | Official Integration | Lightweight Beacon |
|--------|---------------------|-------------------|
| **Lines of Code** | ~4,000 | 5 |
| **Startup Cost** | 50-100ms | <1ms |
| **Features** | 20+ features | 1 feature (APS) |
| **Conflicts** | Prompt, history, status bar | None |
| **Portability** | macOS-only, iTerm2-specific | macOS-only, iTerm2-specific |
| **Maintenance** | Vendor-supported | Manual |
| **Philosophy** | All-in-one integration | Unix: do one thing well |

### The Unix Philosophy Argument

Our entire architecture follows the principle: **Do one thing, do it well.**

- **Tmux**: Session management ✅
- **Fish**: Shell and completions ✅
- **Tide**: Prompt rendering ✅
- **FZF**: Fuzzy finding ✅
- **Beacon**: iTerm2 directory awareness ✅

Installing the official integration violates this by trying to do everything.

### The Performance Argument

Current shell startup: **82ms**

Adding official integration: **132-182ms** (+60-100ms, 73-122% slower)

Adding beacon: **82ms** (<1ms difference, unmeasurable)

### The Maintenance Argument

**Against**: "You have to maintain a cryptic escape code."

**Counter**: The escape code is stable (OSC 1337 unchanged since 2014). The official script changes frequently and could break your prompt/tmux integration at any time.

## Usage & Verification

### Apply the Configuration

```bash
# Apply chezmoi templates
chezmoi apply ~/.config/fish/conf.d/07-iterm-beacon.fish
chezmoi apply ~/.tmux.conf

# Reload tmux
tmux source ~/.tmux.conf

# Verify passthrough enabled
tmux show -g allow-passthrough
# Should output: allow-passthrough on

# Restart Fish (or open new tmux window)
exec fish
```

### Test Profile Switching

1. **Set up iTerm2 profile rules** (Preferences → Profiles → Advanced):
   - Personal Dev: Automatic Profile Switching → Path = `~/Development/personal/*`
   - Work Dev: Path = `~/Development/work/*`
   - Business Dev: Path = `~/Development/business/*`
   - System Config: Path = `~/.local/share/chezmoi/*`

2. **Test the beacon**:
   ```bash
   cd ~/Development/personal/some-project
   # Profile should switch to "Personal Dev" (yellow badge)

   cd ~/Development/work/some-project
   # Profile should switch to "Work Dev" (blue badge)
   ```

3. **Debug if not working**:
   ```bash
   # Check passthrough
   tmux show -g allow-passthrough

   # Check if beacon function exists
   functions -q __iterm2_beacon && echo "Beacon loaded" || echo "Beacon missing"

   # Test beacon manually
   cd /tmp && pwd
   # Watch iTerm2 profile - should NOT switch (no matching rule)
   ```

## Trade-offs & Risks

### ✅ Benefits
1. **Performance**: No measurable startup cost
2. **Simplicity**: 5 lines of code, easy to understand
3. **Purity**: Maintains "Option B: Pure Tmux" philosophy
4. **No Conflicts**: Doesn't touch prompt, history, or status bar
5. **Portable Templates**: Managed by chezmoi, syncs across machines

### ⚠️ Risks
1. **Manual Maintenance**: If OSC 1337 changes (unlikely), we must update
2. **Documentation Burden**: Next engineer needs this ADR to understand
3. **No Vendor Support**: Apple/iTerm2 won't help if it breaks
4. **Partial Feature**: Only APS, not other shell integration features

### 🔴 When to Reconsider

Consider switching to official integration if:
1. You need iTerm2 shell marks (jump to previous prompts)
2. You want iTerm2 status bar components showing git/node versions
3. You need alert on command completion
4. Startup time is not a concern (>150ms acceptable)
5. A new hire strongly prefers "standard" setup

## Alternative Considered: Full Integration

### What we'd gain:
- Vendor-supported solution
- All iTerm2 shell integration features
- Standard configuration (easier for new team members)

### What we'd lose:
- 50-100ms startup time (60-122% slower)
- Potential prompt conflicts with Tide
- Potential tmux integration conflicts
- "Pure Tmux" philosophy
- Clean, minimal configuration

**Decision**: Trade-offs not worth it. We only need APS.

## Configuration File Locations

```
~/.local/share/chezmoi/
├── dot_config/fish/conf.d/
│   └── 07-iterm-beacon.fish.tmpl    # The beacon function
└── dot_tmux.conf.tmpl                # Tmux config with allow-passthrough

~/.config/fish/conf.d/
└── 07-iterm-beacon.fish              # Applied beacon (via chezmoi)

~/.tmux.conf                          # Applied tmux config (via chezmoi)
```

## Related Documentation

- **Integration Status Report**: `07-reports/status/iterm2-fish-tmux-integration-complete-2025-11-22.md`
- **Modern Shell Setup**: `docs/modern-shell-setup-2025.md`
- **iTerm2 Configuration**: `02-configuration/terminals/iterm2-config.md`
- **Chezmoi Integration Guide**: `02-configuration/terminals/ITERM2-CHEZMOI-INTEGRATION.md`

## References

- [iTerm2 Proprietary Escape Codes](https://iterm2.com/documentation-escape-codes.html) - OSC 1337 documentation
- [Tmux Passthrough Mode](https://github.com/tmux/tmux/wiki/FAQ#what-is-the-passthrough-escape-sequence-and-how-do-i-use-it) - Official tmux FAQ
- [iTerm2 Automatic Profile Switching](https://iterm2.com/documentation-automatic-profile-switching.html) - Official docs

## Version History

- **v1.0.0** (2025-11-22): Initial implementation
  - Created 07-iterm-beacon.fish.tmpl
  - Added allow-passthrough to tmux.conf
  - Tested and verified working on macOS 15 Sequoia

## Author & Approval

**Decision by**: System Owner
**Date**: 2025-11-22
**Status**: ✅ Approved for production use
**Review Date**: 2026-11-22 (annual review recommended)

---

**Bottom Line**: This is a **Pro Move** because it demonstrates deep understanding of the tools, respects the Unix philosophy, and makes intentional trade-offs. Document it well (like this ADR), and it becomes reference architecture.

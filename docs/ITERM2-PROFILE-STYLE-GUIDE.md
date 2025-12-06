---
title: "iTerm2 Profile Style Guide - Chromatic Anchoring"
category: documentation
component: terminal
status: active
version: 1.0.0
last_updated: 2025-11-24
tags: [iterm2, design, chromatic-anchoring, style-guide, ux]
priority: high
---

# iTerm2 Profile Style Guide
## Chromatic Anchoring Design System

**Purpose**: This guide provides step-by-step instructions for creating distinctive iTerm2 profiles that automatically switch based on project directory, providing subliminal context awareness through color psychology.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Design Philosophy](#design-philosophy)
3. [Organization Color Selection](#organization-color-selection)
4. [Creating a New Profile](#creating-a-new-profile)
5. [Setting Up Automatic Profile Switching](#setting-up-automatic-profile-switching)
6. [Testing and Verification](#testing-and-verification)
7. [Appendix: Color Reference](#appendix-color-reference)

---

## Quick Start

### For This Project (system-setup-update)

**Profile Created**: ✅ `system-setup-update` (Personal Development category)

**To Import and Use**:

```bash
# 1. Import the profile to iTerm2
# iTerm2 → Preferences → Profiles → Other Actions... → Import JSON Profiles...
# Select: /Users/verlyn13/Development/personal/system-setup-update/06-templates/iterm2/system-setup-update.json

# 2. Set up Automatic Profile Switching
# iTerm2 → Preferences → Profiles → Select "system-setup-update"
# → Advanced → Automatic Profile Switching
# Add Rule: "Path" → "~/Development/personal/system-setup-update/*"

# 3. Test it works
cd ~/Development/personal/system-setup-update
# You should see the profile switch to "system-setup-update" with "PERSONAL" badge
```

---

## Design Philosophy

### The Three-Layer System

Chromatic Anchoring treats your terminal as a **physical room** rather than a flat page. When you switch projects, you **step into a different room** with a distinct atmosphere.

**Layer 1: The Canvas** (iTerm2 Profile)
- **Background Tint**: 95% black + 5% organization color
- **The Badge**: Large typographic watermark for instant context

**Layer 2: The HUD** (Tmux Status Bar)
- **Position**: Top of screen
- **Style**: "Pill" modules with organization colors

**Layer 3: The Interaction** (Fish + Tide Prompt)
- **Colors**: IMMUTABLE (Catppuccin Mocha preserved for muscle memory)
- **Layout**: Multi-line, asynchronous

### Core Principles

1. ✅ **Consistency**: Syntax highlighting NEVER changes (muscle memory preserved)
2. ✅ **Differentiation**: Background and badge shift per organization
3. ✅ **Subliminal**: Peripheral vision knows context without reading labels

---

## Organization Color Selection

### Step 1: Define Your Archetype

Each organization should have a psychological "feeling" that maps to its purpose:

| Archetype | Feeling | Example Organizations |
|-----------|---------|---------------------|
| **The Vault** | Secure, authoritative | Corporate HQ, governance |
| **The Bedrock** | Heavy, immutable | Assets, finance, ledgers |
| **The Flow** | Fluid, interconnected | Services, APIs, data streams |
| **The Lab** | Experimental, creative | R&D, prototypes |
| **The Workshop** | Personal, warm | Personal projects, learning |

### Step 2: Choose Your Color from Catppuccin Mocha

All colors MUST come from the [Catppuccin Mocha palette](https://github.com/catppuccin/catppuccin) to maintain design consistency.

**Available Semantic Colors**:

| Color Name | Hex | RGB | Use Case |
|------------|-----|-----|----------|
| **Red** | `#f38ba8` | (243, 139, 168) | Critical, emergency |
| **Maroon** | `#eba0ac` | (235, 160, 172) | Warnings, caution |
| **Peach** | `#fab387` | (250, 179, 135) | Warm, personal, creative |
| **Yellow** | `#f9e2af` | (249, 226, 175) | Highlights, energy |
| **Green** | `#a6e3a1` | (166, 227, 161) | Growth, success |
| **Teal** | `#94e2d5` | (148, 226, 213) | Flow, water, services |
| **Sky** | `#89dceb` | (137, 220, 235) | Air, cloud, ephemeral |
| **Sapphire** | `#74c7ec` | (116, 199, 236) | Information, clarity |
| **Blue** | `#89b4fa` | (137, 180, 250) | Corporate, trust |
| **Lavender** | `#b4befe` | (180, 190, 254) | Calm, professional |
| **Mauve** | `#cba6f7` | (203, 166, 247) | Creative, abstract |
| **Pink** | `#f5c2e7` | (245, 194, 231) | Accent, special |

**Neutral Tones** (for monochrome themes):

| Color Name | Hex | RGB | Use Case |
|------------|-----|-----|----------|
| **Surface2** | `#585b70` | (88, 91, 112) | Stone, industrial |
| **Overlay0** | `#6c7086` | (108, 112, 134) | Concrete, neutral |

### Step 3: Calculate Your Background Tint

**Formula**: Mix 95% base + 5% tint color

```python
def calculate_background(base_hex, tint_hex):
    """
    Calculate iTerm2 background RGB values

    Args:
        base_hex: "#1e1e2e" (Catppuccin base) or "#11111b" (Catppuccin crust)
        tint_hex: Organization color from Catppuccin Mocha

    Returns:
        RGB tuple in 0-1 range (for iTerm2 JSON)
    """
    # Convert hex to 0-1 range
    base_r, base_g, base_b = [int(base_hex[i:i+2], 16) / 255 for i in (1, 3, 5)]
    tint_r, tint_g, tint_b = [int(tint_hex[i:i+2], 16) / 255 for i in (1, 3, 5)]

    # Mix: 95% base + 5% tint
    mixed_r = base_r * 0.95 + tint_r * 0.05
    mixed_g = base_g * 0.95 + tint_g * 0.05
    mixed_b = base_b * 0.95 + tint_b * 0.05

    return (round(mixed_r, 4), round(mixed_g, 4), round(mixed_b, 4))

# Example: Personal Development
base = "#1e1e2e"  # Catppuccin base
tint = "#fab387"  # Catppuccin peach
result = calculate_background(base, tint)
# Result: (0.1608, 0.1469, 0.1978)
```

**Online Calculator**: Use https://peko.github.io/catppuccin-palette/ for visual mixing

---

## Creating a New Profile

### Method 1: Clone and Modify Existing Profile (Recommended)

**Step-by-Step**:

1. **Open iTerm2 Preferences**
   - `iTerm2 → Preferences → Profiles`

2. **Duplicate an Existing Profile**
   - Select any profile → Click "+" (bottom left) → "Duplicate Profile"
   - Or right-click profile → "Duplicate Profile"

3. **Name Your Profile**
   - General tab → Name: `your-project-name`
   - Description: `Organization Name - Project Type`

4. **Set Working Directory**
   - General tab → Working Directory → "Directory:"
   - Enter: `/Users/verlyn13/Development/[org]/[project]`

5. **Configure Background Color**
   - Colors tab → Basic Colors → Background
   - Click color swatch → RGB Sliders
   - Enter calculated RGB values (0-1 range):
     - Red: `0.xxxx`
     - Green: `0.xxxx`
     - Blue: `0.xxxx`

6. **Configure Badge**
   - General tab → Badge
   - Text: `YOUR_ORG_NAME` (uppercase, short, 4-10 characters)
   - Font: Click "Configure Badge Font"
     - Font: **Helvetica Bold** or **Impact**
     - Size: **72**

7. **Set Badge Color**
   - Colors tab → Badge Color
   - Click color swatch → RGB Sliders
   - Enter tint color RGB + Alpha 0.20:
     - Red: `0.xxxx` (tint color)
     - Green: `0.xxxx` (tint color)
     - Blue: `0.xxxx` (tint color)
     - Alpha: `0.20` (20% opacity)

8. **Verify ANSI Colors** (DO NOT CHANGE)
   - Colors tab → Basic Colors → ANSI Colors
   - Should be Catppuccin Mocha (all profiles share these)
   - If not, import from `06-templates/iterm2/catppuccin-mocha-ansi.json`

### Method 2: Import JSON Template

**Step-by-Step**:

1. **Create JSON File**
   - Copy template: `06-templates/iterm2/system-setup-update.json`
   - Rename: `your-project-name.json`

2. **Edit JSON Values**
   - Replace `"Name"`: `"your-project-name"`
   - Replace `"Badge Text"`: `"YOUR_ORG"`
   - Update `"Background Color"` RGB values
   - Update `"Badge Color"` RGB values
   - Update `"Working Directory"`: path

3. **Import to iTerm2**
   - `iTerm2 → Preferences → Profiles`
   - `Other Actions... → Import JSON Profiles...`
   - Select your JSON file
   - Choose: "Replace" or "New" profile

---

## Setting Up Automatic Profile Switching

### Prerequisites

✅ **Beacon Must Be Active**: Verify `~/.config/fish/conf.d/07-iterm-beacon.fish` exists
✅ **Tmux Passthrough Enabled**: `tmux show -g allow-passthrough` returns "on"

### Configuration Steps

1. **Open Profile Settings**
   - `iTerm2 → Preferences → Profiles`
   - Select your profile

2. **Add Automatic Profile Switching Rule**
   - Advanced tab → Automatic Profile Switching
   - Click "+" to add rule

3. **Configure Path Rule**
   - Type: **Path**
   - Pattern: `~/Development/[org]/[project]/*`
   - Example: `~/Development/personal/system-setup-update/*`

4. **Add Multiple Paths (Optional)**
   - Click "+" again for each additional path
   - Example patterns:
     ```
     ~/Development/personal/*           # All personal projects
     ~/experiments/*                     # Experimental work
     ~/.local/share/[project]/*         # Config projects
     ```

5. **Test Pattern Matching**
   - Click "Edit..." on the rule
   - iTerm2 will show current directory and whether it matches
   - Adjust pattern if needed (wildcards: `*` for any, `**` for recursive)

### Common Path Patterns

| Pattern | Matches |
|---------|---------|
| `~/Development/personal/*` | Any direct subdirectory |
| `~/Development/personal/**` | All nested subdirectories |
| `~/Development/personal/system-*` | Projects starting with "system-" |
| `~/.local/share/chezmoi/*` | Chezmoi dotfiles directory |

---

## Testing and Verification

### Test Checklist

**✅ Profile Loads Correctly**

```bash
cd ~/Development/[org]/[project]
# Check: iTerm2 title bar shows profile name
# Check: Background has subtle tint (not solid black)
# Check: Badge visible in top-right corner (subtle watermark)
```

**✅ Colors Match Specification**

```bash
# Background should be BARELY tinted (5% only)
# If tint is obvious, reduce tint percentage

# Badge should be READABLE but SUBTLE
# If badge is too bright, reduce alpha to 0.15
# If badge is invisible, increase alpha to 0.25
```

**✅ ANSI Colors Unchanged**

```bash
# Run a command with colored output
ls --color=auto
# Colors should be identical across all profiles
# Red = errors, Green = success, Blue = functions
```

**✅ Profile Switches on Directory Change**

```bash
# Start in home directory (default profile)
cd ~

# Switch to project directory
cd ~/Development/personal/system-setup-update
# Profile should IMMEDIATELY switch to "system-setup-update"

# Switch to different organization
cd ~/Development/work/other-project
# Profile should switch to that project's profile
```

### Debugging Profile Switching

**Problem**: Profile doesn't switch

**Solutions**:

1. **Verify Beacon Function**
   ```bash
   functions -q __iterm2_beacon && echo "✅ Beacon loaded" || echo "❌ Beacon missing"
   ```

2. **Check Tmux Passthrough**
   ```bash
   tmux show -g allow-passthrough
   # Must return: allow-passthrough on
   ```

3. **Verify Path Pattern**
   - iTerm2 → Preferences → Profiles → [Your Profile] → Advanced
   - Check path pattern matches your actual directory
   - Use absolute path: `~/Development/...` not `$HOME/...`

4. **Manual Beacon Test**
   ```bash
   # Run beacon function manually
   __iterm2_beacon
   # Should trigger profile switch immediately
   ```

5. **Check iTerm2 Logs**
   - `iTerm2 → Help → Capture Debug Info`
   - Search for "Automatic Profile Switching" events

---

## Appendix: Color Reference

### Existing Organizational Profiles

**A. The Nash Group** (Corporate)
```yaml
Archetype: The Vault / HQ
Base: #1e1e2e (Catppuccin base)
Tint: #89b4fa (Catppuccin blue)
Background RGB: (0.1283, 0.1267, 0.2016)
Badge: "NASH"
Badge Color: #cdd6f4 (Catppuccin text) @ 20%
Paths: ~/Development/the-nash-group/*, ~/admin/*
```

**B. Jefahnie Rocks** (Assets)
```yaml
Archetype: The Bedrock / Foundation
Base: #11111b (Catppuccin crust - darker)
Tint: #585b70 (Catppuccin surface2 - stone)
Background RGB: (0.0806, 0.0812, 0.1226)
Badge: "ROCKS"
Badge Color: #6c7086 (Catppuccin overlay0) @ 20%
Paths: ~/Development/jefahnie-rocks/*, ~/Documents/finances/*
```

**C. Seven Springs** (Services)
```yaml
Archetype: The Flow / Water
Base: #1e1e2e (Catppuccin base)
Tint: #94e2d5 (Catppuccin teal)
Background RGB: (0.1407, 0.1560, 0.2132)
Badge: "SPRINGS"
Badge Color: #94e2d5 (Catppuccin teal) @ 20%
Paths: ~/Development/seven-springs/*, ~/api/*
```

**D. Happy Patterns** (R&D)
```yaml
Archetype: The Lab / Abstract
Base: #1e1e2e (Catppuccin base)
Tint: #cba6f7 (Catppuccin mauve)
Background RGB: (0.1580, 0.1293, 0.2216)
Badge: "HAPPY"
Badge Color: #f5c2e7 (Catppuccin pink) @ 20%
Paths: ~/Development/happy-patterns/*, ~/experiments/*
```

**E. Personal Development** ✅ (Active)
```yaml
Archetype: The Workshop / Home Studio
Base: #1e1e2e (Catppuccin base)
Tint: #fab387 (Catppuccin peach)
Background RGB: (0.1608, 0.1469, 0.1978)
Badge: "PERSONAL"
Badge Color: #fab387 (Catppuccin peach) @ 20%
Paths: ~/Development/personal/*, ~/.local/share/chezmoi/*
```

### Catppuccin Mocha ANSI Palette (IMMUTABLE)

**DO NOT CHANGE THESE** - Shared across all profiles for muscle memory:

```json
{
  "Ansi 0 Color": {"Red": 0.2706, "Green": 0.2784, "Blue": 0.3529},
  "Ansi 1 Color": {"Red": 0.9529, "Green": 0.5451, "Blue": 0.6588},
  "Ansi 2 Color": {"Red": 0.6510, "Green": 0.8902, "Blue": 0.6314},
  "Ansi 3 Color": {"Red": 0.9765, "Green": 0.8863, "Blue": 0.6863},
  "Ansi 4 Color": {"Red": 0.5373, "Green": 0.7059, "Blue": 0.9804},
  "Ansi 5 Color": {"Red": 0.9608, "Green": 0.7608, "Blue": 0.9059},
  "Ansi 6 Color": {"Red": 0.5804, "Green": 0.8863, "Blue": 0.8353},
  "Ansi 7 Color": {"Red": 0.7294, "Green": 0.7608, "Blue": 0.8706},
  "Ansi 8 Color": {"Red": 0.3451, "Green": 0.3569, "Blue": 0.4392},
  "Ansi 9 Color": {"Red": 0.9216, "Green": 0.6275, "Blue": 0.6745},
  "Ansi 10 Color": {"Red": 0.6510, "Green": 0.8902, "Blue": 0.6314},
  "Ansi 11 Color": {"Red": 0.9765, "Green": 0.8863, "Blue": 0.6863},
  "Ansi 12 Color": {"Red": 0.4549, "Green": 0.7804, "Blue": 0.9255},
  "Ansi 13 Color": {"Red": 0.7961, "Green": 0.6510, "Blue": 0.9686},
  "Ansi 14 Color": {"Red": 0.5373, "Green": 0.8627, "Blue": 0.9216},
  "Ansi 15 Color": {"Red": 0.8039, "Green": 0.8392, "Blue": 0.9569}
}
```

---

## Related Documentation

- **Chromatic Anchoring Spec**: `docs/CHROMATIC-ANCHORING-SPEC.md`
- **iTerm2 Beacon Solution**: `docs/ITERM2-BEACON-SOLUTION.md`
- **iTerm2 Configuration Guide**: `02-configuration/terminals/iterm2-config.md`
- **Modern Shell Setup**: `docs/modern-shell-setup-2025.md`

---

## Version History

- **v1.0.0** (2025-11-24): Initial style guide creation
  - Added Personal Development organization
  - Documented profile creation workflow
  - Added automatic profile switching setup
  - Created color reference tables

---

**Status**: ✅ Active
**Next Review**: When adding 6th organization or after 6 months
**Maintainer**: System Owner

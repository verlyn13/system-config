---
title: "iTerm2 Configuration for Modern Shell Setup"
category: documentation
component: terminal
status: stable
version: 2.0.0
last_updated: 2025-11-21
tags: [iterm2, terminal, tmux, configuration, modern]
priority: high
related: [modern-shell-setup-2025.md, iterm2-config.md]
---

# iTerm2 Configuration for Modern Shell Setup

This guide configures iTerm2 as a **beautiful frame** for your tmux-based workflow (Option B: Pure Tmux).

## Philosophy

With our modern shell setup:
- **iTerm2** = Terminal emulator (the window)
- **Tmux** = Session manager (the brains)
- **Fish** = Shell (the interface)

iTerm2 becomes a simple, beautiful window into your tmux sessions. All session management, windowing, and persistence is handled by tmux.

---

## Quick Configuration Checklist

- [ ] Install a Nerd Font
- [ ] Set font in iTerm2
- [ ] Configure Option/Alt keys
- [ ] Enable clipboard access
- [ ] Set terminal type
- [ ] Import color scheme
- [ ] Disable native tab bar (optional)
- [ ] Set up profiles (optional)

---

## Step-by-Step Configuration

### 1. Font Configuration (Essential)

**Why:** Nerd Fonts include thousands of icons used by modern prompts and file listings.

#### Install Nerd Fonts

```bash
# Choose one (or install multiple):
brew install --cask font-hack-nerd-font              # Recommended
brew install --cask font-meslo-lg-nerd-font          # Used by Powerlevel10k
brew install --cask font-jetbrains-mono-nerd-font    # Great for coding
brew install --cask font-fira-code-nerd-font         # Popular with ligatures
```

#### Configure in iTerm2

1. Open **iTerm2 → Preferences** (`Cmd+,`)
2. Navigate to **Profiles → Text**
3. Click **Change Font** under "Font"
4. Search for your installed Nerd Font:
   - **Hack Nerd Font Mono** (size 13-14)
   - **MesloLGS NF** (size 13)
   - **JetBrainsMono Nerd Font** (size 13-14)
5. Recommended settings:
   - ✅ **Use ligatures** (if font supports it - Fira Code, JetBrains Mono)
   - ✅ **Anti-aliased**
   - Vertical spacing: 100%
   - Horizontal spacing: 100%

**Test icons work:**
```bash
echo "   "
# Should show: folder, gear, git branch icons
```

---

### 2. Key Binding Configuration (Essential)

**Why:** Enables Alt/Option key combinations in Fish and Tmux.

#### Configure Option Keys

1. Open **iTerm2 → Preferences** (`Cmd+,`)
2. Navigate to **Profiles → Keys**
3. Click **Key Mappings** tab
4. At the bottom, configure:
   - **Left Option (⌥) key:** `Esc+`
   - **Right Option (⌥) key:** `Normal`

**Why these settings:**
- **Left Option = Esc+**: Allows `Alt+key` combinations (e.g., `Alt+h` in vim, `Alt+Left` in tmux)
- **Right Option = Normal**: Allows typing special characters (e.g., `[`, `]`, `\` on non-US keyboards)

**Test it works:**
```bash
# In tmux, try:
Alt+Left   # Should switch to previous window
Alt+Right  # Should switch to next window
```

---

### 3. Clipboard Integration (Essential)

**Why:** Allows tmux and terminal applications to access the system clipboard.

#### Enable Clipboard Access

1. Open **iTerm2 → Preferences** (`Cmd+,`)
2. Navigate to **General → Selection**
3. Enable:
   - ✅ **Applications in terminal may access clipboard**

4. Navigate to **Profiles → Terminal**
5. Ensure:
   - ✅ **Terminal may enable paste bracketing**

**Test it works:**
```fish
# In tmux, enter copy mode
Ctrl+a [

# Select text with mouse or vim keys (v to start selection)
# Press 'y' to copy

# Should copy to system clipboard (test with Cmd+V in another app)
```

---

### 4. Terminal Type (Essential)

**Why:** Ensures proper color support and terminal capabilities.

#### Set Terminal Type

1. Open **iTerm2 → Preferences** (`Cmd+,`)
2. Navigate to **Profiles → Terminal**
3. Under **Terminal Emulation:**
   - **Report Terminal Type:** `xterm-256color`

**Verify:**
```fish
echo $TERM
# In iTerm2 (no tmux): xterm-256color
# In tmux: tmux-256color or screen-256color
```

**Test colors:**
```bash
curl -s https://gist.githubusercontent.com/lilydjwg/fdeaf79e921c2f413f44b6f613f6ad53/raw/94d8b2be62657e96488038b0e547e3009ed87d40/colors.py | python3
# Should show smooth color gradients
```

---

### 5. Color Scheme (Highly Recommended)

**Why:** Beautiful, consistent colors that match your tmux theme.

#### Recommended: Catppuccin Mocha

Our tmux configuration uses Catppuccin Mocha. Matching iTerm2 theme creates a cohesive look.

**Installation:**

1. Download [Catppuccin for iTerm2](https://github.com/catppuccin/iterm2)
   ```bash
   curl -O https://raw.githubusercontent.com/catppuccin/iterm2/main/colors/catppuccin-mocha.itermcolors
   ```

2. Import in iTerm2:
   - **Preferences → Profiles → Colors**
   - Click **Color Presets...** (bottom right)
   - Select **Import...**
   - Choose downloaded `.itermcolors` file
   - Select **catppuccin-mocha** from presets

#### Alternative Popular Themes

**Solarized Dark:**
```bash
curl -O https://raw.githubusercontent.com/altercation/solarized/master/iterm2-colors-solarized/Solarized%20Dark.itermcolors
```

**Nord:**
```bash
curl -O https://raw.githubusercontent.com/arcticicestudio/nord-iterm2/develop/src/xml/Nord.itermcolors
```

**Dracula:**
```bash
git clone https://github.com/dracula/iterm.git
# Then import Dracula.itermcolors
```

**Browse more:** [iTerm2 Color Schemes](https://iterm2colorschemes.com/)

---

### 6. Disable Native Tab Bar (Recommended for Option B)

**Why:** With tmux handling windows/tabs, iTerm2's native tabs are redundant.

#### Hide Tab Bar

1. Open **iTerm2 → Preferences** (`Cmd+,`)
2. Navigate to **Appearance → Tabs**
3. Disable:
   - ❌ **Show tab bar even when there is only one tab**

#### Disable Tab Bar Completely (Optional)

**View → Hide Tab Bar** (`Cmd+Shift+T`)

Or set in Preferences:
- **Appearance → General → Theme:** `Minimal`

**Result:** Clean, distraction-free terminal with only tmux status bar visible.

---

### 7. Window Appearance (Optional but Nice)

#### Transparency and Blur

1. **Profiles → Window**
2. Adjust:
   - **Transparency:** 5-15% (subtle)
   - **Blur:** 5-10 (makes text more readable over transparency)

#### Full Screen Behavior

1. **Profiles → Window**
2. Set:
   - **Style:** Full-Screen
   - **Screen:** Main Screen

3. **General → Window**
   - ✅ **Native full screen windows** (smooth animations)

**Use:** `Cmd+Return` to toggle full screen

---

### 8. Status Bar (Optional)

iTerm2 has its own status bar (separate from tmux). You can use both or disable iTerm2's.

#### Disable iTerm2 Status Bar (Recommended)

**View → Hide Status Bar**

Or in Preferences:
- **Profiles → Session**
- ❌ **Status bar enabled**

**Why:** Tmux status bar is more powerful and portable.

#### Enable iTerm2 Status Bar (Alternative)

If you want both:

1. **Profiles → Session**
2. ✅ **Status bar enabled**
3. Click **Configure Status Bar**
4. Add components (e.g., CPU, Memory, Network)

---

### 9. Keyboard Shortcuts (Power User)

#### Disable Conflicting Shortcuts

Some iTerm2 shortcuts conflict with tmux. Disable these:

1. **Preferences → Keys → Key Bindings**
2. Remove or change:
   - `Cmd+D` (conflicts with tmux split)
   - `Cmd+T` (use tmux windows instead)
   - `Cmd+W` (use tmux kill-window instead)
   - `Cmd+1-9` (use tmux window selection instead)

#### Recommended Custom Shortcuts

| Action | Shortcut | Command |
|--------|----------|---------|
| New tmux window | `Cmd+T` | Send text: `tmux new-window\n` |
| Tmux split vertical | `Cmd+D` | Send text: `tmux split-window -h\n` |
| Tmux split horizontal | `Cmd+Shift+D` | Send text: `tmux split-window -v\n` |
| Attach tmux | `Cmd+A` | Send text: `tmux attach\n` |

**To add:**
1. **Preferences → Keys → Key Bindings**
2. Click **+** to add new
3. Select **Keyboard Shortcut:** (press key combo)
4. **Action:** Send Text
5. Enter command with `\n` at end

---

### 10. Profiles (Advanced)

Create different profiles for different workflows.

#### Create Development Profile

1. **Preferences → Profiles**
2. Click **+** to duplicate **Default**
3. Rename to **"Development"**
4. Configure:
   - **General → Command:** Custom: `tmux new -s dev || tmux attach -s dev`
   - **Colors:** Catppuccin Mocha
   - **Window → Transparency:** 10%
   - **Keys:** Custom keybindings

#### Create Server Profile

For SSH sessions:

1. Duplicate **Default** → Rename to **"Server"**
2. Configure:
   - **General → Command:** Custom: `tmux new -s server || tmux attach -s server`
   - **Colors:** Solarized Dark (different color to distinguish)
   - **Terminal → Report Terminal Type:** `xterm-256color`
   - **Session → Automatically log:** `/tmp/server-session.log`

#### Set Default Profile

**Preferences → Profiles**
- Select your preferred profile
- Click **Other Actions... → Set as Default**

---

## Verification Checklist

After configuration, verify everything works:

### Visual Check

```fish
# Icons should render
echo "   "

# Colors should be vibrant
curl -s https://gist.githubusercontent.com/lilydjwg/fdeaf79e921c2f413f44b6f613f6ad53/raw/94d8b2be62657e96488038b0e547e3009ed87d40/colors.py | python3
```

### Tmux Integration

```fish
# Should auto-start tmux
# Check status bar at top

# Test prefix
Ctrl+a ?   # Should show tmux help

# Test split
Ctrl+a |   # Should split vertically
Ctrl+a -   # Should split horizontally

# Test vim keys
Ctrl+a h/j/k/l  # Should navigate panes
```

### Clipboard

```fish
# In tmux copy mode
Ctrl+a [
# Select text with mouse or 'v' then arrow keys
y  # Should copy to system clipboard
# Test paste with Cmd+V in another app
```

### Key Bindings

```fish
# Test Alt keys work
Alt+Left   # Should switch tmux window (if bound)
Alt+h      # Should work in vim (move left)
```

---

## Troubleshooting

### Icons Show as Boxes/Question Marks

**Problem:** Nerd Font not installed or not selected in iTerm2

**Solution:**
1. Install font: `brew install --cask font-hack-nerd-font`
2. Restart iTerm2
3. Select font in Preferences → Profiles → Text
4. Make sure to select the **"Mono"** variant (e.g., "Hack Nerd Font Mono")

### Colors Look Washed Out

**Problem:** Terminal type not set correctly

**Solution:**
1. Check `echo $TERM` (should be `xterm-256color` or `tmux-256color`)
2. Set in Preferences → Profiles → Terminal → Report Terminal Type
3. Restart terminal

### Alt/Option Keys Don't Work

**Problem:** Option key not configured as Meta key

**Solution:**
1. Preferences → Profiles → Keys
2. Left Option → `Esc+`
3. Right Option → `Normal` (or `Esc+` if you don't need special chars)

### Clipboard Copy Doesn't Work

**Problem:** Clipboard access disabled

**Solution:**
1. Preferences → General → Selection
2. Enable "Applications in terminal may access clipboard"
3. Restart iTerm2

### Tmux Doesn't Auto-Start

**Problem:** Fish tmux plugin not configured

**Solution:**
```fish
# Check variables
echo $fish_tmux_autostart  # Should be: true

# Check plugin installed
fisher list | grep tmux    # Should show: budimanjojo/tmux.fish

# Reinstall if needed
fisher install budimanjojo/tmux.fish
```

### Performance Issues

**Problem:** Terminal feels sluggish

**Solutions:**
1. Disable GPU rendering (Preferences → General → GPU Rendering)
2. Reduce transparency (Profiles → Window → Transparency → 0%)
3. Disable blur (Profiles → Window → Blur → 0)
4. Disable animations (Preferences → Advanced → "Animate" → NO)

---

## Advanced: Dynamic Profiles

For managing multiple iTerm2 profiles via chezmoi:

**Create:** `~/.config/iterm2/DynamicProfiles/base.json`

```json
{
  "Profiles": [
    {
      "Name": "Modern Shell",
      "Guid": "modern-shell-2025",
      "Custom Directory": "Yes",
      "Working Directory": "/Users/username",
      "Initial Text": "tmux attach || tmux new -s main",
      "Terminal Type": "xterm-256color",
      "Use Custom Command": "Yes",
      "Custom Command": "/opt/homebrew/bin/fish",
      "Font": "Hack Nerd Font Mono 13"
    }
  ]
}
```

Manage via chezmoi templates (see `02-configuration/terminals/ITERM2-CHEZMOI-INTEGRATION.md`).

---

## Recommended iTerm2 Settings Summary

### Minimal Setup (Essential)

| Setting | Value |
|---------|-------|
| **Font** | Hack Nerd Font Mono, 13pt |
| **Left Option** | Esc+ |
| **Right Option** | Normal |
| **Clipboard Access** | ✅ Enabled |
| **Terminal Type** | xterm-256color |
| **Color Scheme** | Catppuccin Mocha |

### Full Setup (Pro)

Add to minimal:

| Setting | Value |
|---------|-------|
| **Tab Bar** | ❌ Hidden |
| **Status Bar** | ❌ Disabled |
| **Transparency** | 10% |
| **Blur** | 5 |
| **Theme** | Minimal |
| **GPU Rendering** | ✅ Enabled (if no performance issues) |

---

## Import/Export Settings

### Export Your Configuration

1. **Preferences → General → Preferences**
2. ✅ **Load preferences from a custom folder or URL**
3. Choose: `~/.config/iterm2/`
4. ✅ **Save changes to folder when iTerm2 quits**

Now your iTerm2 settings are saved and can be managed by chezmoi!

### Import on New Machine

```bash
# Via chezmoi (if configured)
chezmoi apply

# Or manually
cp -r ~/path/to/iterm2/config/* ~/.config/iterm2/
# Restart iTerm2
```

---

## Integration with Modern Shell Setup

This iTerm2 configuration works seamlessly with:

- **Fish shell** (`config.fish`)
- **Tmux** (`tmux.conf`)
- **Starship/Tide** (prompt)
- **Fisher plugins** (fzf.fish, tmux.fish)

**See:** `docs/modern-shell-setup-2025.md` for the complete guide.

---

## Resources

### Official Documentation
- [iTerm2 Documentation](https://iterm2.com/documentation.html)
- [iTerm2 Features](https://iterm2.com/features.html)

### Color Schemes
- [iTerm2 Color Schemes](https://iterm2colorschemes.com/)
- [Catppuccin](https://github.com/catppuccin/iterm2)
- [Nord](https://github.com/arcticicestudio/nord-iterm2)
- [Dracula](https://draculatheme.com/iterm)

### Fonts
- [Nerd Fonts](https://www.nerdfonts.com/)
- [Programming Fonts](https://www.programmingfonts.org/)

### Related Repository Files
- **Modern Shell Setup:** `docs/modern-shell-setup-2025.md`
- **iTerm2 Setup Guide:** `01-setup/03-iterm2.md`
- **iTerm2 Config Reference:** `02-configuration/terminals/iterm2-config.md`
- **Chezmoi Integration:** `02-configuration/terminals/ITERM2-CHEZMOI-INTEGRATION.md`

---

## Quick Reference: Essential Shortcuts

### iTerm2
| Shortcut | Action |
|----------|--------|
| `Cmd+T` | New tab (or configure for tmux window) |
| `Cmd+D` | Split vertically (or configure for tmux split) |
| `Cmd+Shift+D` | Split horizontally (or configure for tmux split) |
| `Cmd+Return` | Toggle full screen |
| `Cmd+,` | Open preferences |
| `Cmd+K` | Clear buffer |

### Tmux (with our config)
| Shortcut | Action |
|----------|--------|
| `Ctrl+a c` | New window |
| `Ctrl+a \|` | Split vertical |
| `Ctrl+a -` | Split horizontal |
| `Ctrl+a h/j/k/l` | Navigate panes |
| `Ctrl+a [` | Copy mode |
| `Ctrl+a r` | Reload config |

---

**Next:** See `docs/modern-shell-setup-2025.md` for complete shell configuration.

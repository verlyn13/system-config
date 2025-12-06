---
title: "Complete Modern Shell Setup Guide"
category: documentation
component: shell
status: complete
version: 3.0.0
last_updated: 2025-11-21
tags: [fish, tmux, iterm2, direnv, complete, reference]
priority: critical
---

# Complete Modern Shell Setup Guide

## Architecture

```
iTerm2 (Beautiful window with Nerd Font)
  └─> Fish Shell (Interactive, with plugins)
        ├─> direnv (Project-level env vars)
        ├─> Tide (Minimalist prompt)
        └─> Tmux (Session management, persistence)
              └─> Your work happens here
```

---

## ✅ What's Installed

### Core Components
- **iTerm2** with dynamic profiles
- **Fish shell** with modern configuration
- **Tmux** with Catppuccin Mocha theme
- **Fisher** plugin manager
- **direnv** for project-level environment management

### Fish Plugins (via Fisher)
- `jorgebucaran/fisher` - Plugin manager
- `PatrickF1/fzf.fish` - Fuzzy finder integration
- `budimanjojo/tmux.fish` - Tmux auto-start
- `IlanCosman/tide@v6` - Modern, fast prompt

### Nerd Fonts Installed
- Hack Nerd Font (recommended)
- JetBrains Mono Nerd Font
- Fira Code Nerd Font
- Meslo LG Nerd Font

---

## 🎨 Visual Project Identifiers

### 1. iTerm2 Badge (Background Watermark)

**Automatically updates** when you `cd` to show:
- Current directory name
- Git branch (if in repo)

**Location**: `~/.config/fish/config.fish` (already configured)

**Function**: `update_iterm2_badge`
- Passes through tmux using escape sequences
- Updates on every directory change

**Enable in iTerm2**:
1. Open Preferences (`Cmd+,`)
2. **Profiles → General**
3. Under **Badge**, check **"Enabled"**
4. The badge will now show automatically

---

## 🔧 Project-Level Configuration

### direnv Integration

**Already configured** in `~/.config/fish/conf.d/02-direnv.fish`

**Usage**:

```bash
# In your project directory
cd ~/Development/my-project

# Create .envrc file
cat > .envrc << 'EOF'
# Project-specific environment
export PROJECT_ENV="development"
export API_KEY="dev_key_here"
export AWS_PROFILE="my-project-dev"

# Use mise for version management
use mise

# Source local secrets (gitignored)
source_env_if_exists .envrc.local
EOF

# Allow direnv to load it
direnv allow .

# Variables are now loaded!
echo $PROJECT_ENV  # => development

# When you leave the directory, they unload
cd ~
echo $PROJECT_ENV  # => (empty)
```

**Security**:
- direnv requires explicit `direnv allow` for new/modified `.envrc`
- Add `.envrc.local` to `.gitignore` for secrets

---

## 🚀 God-Mode Project Switching

### Tmux Sessionizer

Press **`Ctrl+F`** anywhere to:
1. Fuzzy-search your project directories
2. Instantly switch entire tmux session to that project
3. Create new session if it doesn't exist

**Searches**:
- `~/Development`
- `~/workspace`
- `~/code`
- `~/projects`

**Location**: `~/.local/bin/tmux-sessionizer`

**Keybinding**: `~/.config/fish/conf.d/05-keybindings.fish`

**Usage**:

```bash
# Interactive (fuzzy finder)
Ctrl+F

# Direct
tmux-sessionizer ~/Development/my-project
```

**Workflow**:
```
Ctrl+F → Select "budget-triage"
  → Switches to tmux session "budget-triage"
    → In ~/Development/budget-triage
      → All panes/windows preserved
```

---

## ⌨️ Key Bindings Reference

### Tmux (Prefix: `Ctrl+a`)

| Key | Action |
|-----|--------|
| `Ctrl+a c` | New window |
| `Ctrl+a \|` | Split vertical |
| `Ctrl+a -` | Split horizontal |
| `Ctrl+a h/j/k/l` | Navigate panes (vim-style) |
| `Ctrl+a [` | Copy mode |
| `Ctrl+a ]` | Paste |
| `Ctrl+a r` | Reload config |
| `Ctrl+a S` | Session switcher |
| `Ctrl+a X` | Kill session |
| `Alt+Left/Right` | Switch windows (no prefix!) |

### Fish Shell

| Key | Action |
|-----|--------|
| `Ctrl+F` | **Tmux sessionizer** (god-mode) |
| `Ctrl+R` | History search |
| `Ctrl+P/N` | Previous/Next history |
| `Up/Down` | Smart history (prefix search) |

### iTerm2

| Key | Action |
|-----|--------|
| `Cmd+T` | New tab |
| `Cmd+D` | Split vertically |
| `Cmd+Shift+D` | Split horizontally |
| `Cmd+Return` | Toggle full screen |
| `Cmd+K` | Clear buffer |

---

## 🎨 iTerm2 Font Configuration

**Required for proper icon rendering**

1. Open **iTerm2 → Preferences** (`Cmd+,`)
2. Navigate to **Profiles → Text**
3. Click **Change Font**
4. Select one of:
   - **Hack Nerd Font Mono** (size 13-14) ← Recommended
   - **JetBrainsMono Nerd Font** (size 13-14)
   - **MesloLGS NF** (size 13)
   - **FiraCode Nerd Font** (size 13-14)
5. Optional settings:
   - ✅ Use ligatures (for Fira Code/JetBrains Mono)
   - ✅ Anti-aliased
   - Vertical spacing: 100%
   - Horizontal spacing: 100%

**Test**:
```fish
echo "   "
# Should show: folder, gear, git branch icons
```

---

## 🎨 Tide Prompt Configuration

**Pre-configured** with Nash Group minimalist/brutalist aesthetic.

**Location**: `~/.config/fish/conf.d/06-tide-config.fish`

**Style**:
- Clean 2-line prompt
- Essential info only: pwd, git, status, time
- Green/red character (✓/✗ on error)
- Matches Catppuccin Mocha theme

**Customize**:
```fish
# Interactive configuration wizard
tide configure

# Or edit directly
vim ~/.config/fish/conf.d/06-tide-config.fish
```

---

## 📦 Chezmoi Management

### Fisher Automatic Updates

**Location**: `~/.local/share/chezmoi/run_onchange_install_fisher.sh.tmpl`

**Triggers**: Automatically runs when `fish_plugins` changes

**Manual update**:
```bash
fisher update
```

### Apply Changes

```bash
# Preview changes
chezmoi diff

# Apply all templates
chezmoi apply

# Edit and apply
chezmoi edit ~/.config/fish/config.fish
chezmoi apply
```

---

## 🔍 Troubleshooting

### Icons Show as Boxes

**Problem**: Nerd Font not configured in iTerm2

**Solution**:
1. Verify font installed: `brew list --cask | grep nerd-font`
2. Set in iTerm2: Preferences → Profiles → Text → Font
3. Restart iTerm2

### Tmux Doesn't Auto-Start

**Check**:
```fish
echo $fish_tmux_autostart  # Should be: true
fisher list | grep tmux    # Should show: budimanjojo/tmux.fish
```

**Fix**:
```fish
fisher update
exec fish
```

### direnv Not Loading

**Check**:
```fish
type -q direnv && echo "Installed" || echo "Not installed"
```

**Fix**:
```bash
brew install direnv
exec fish
```

### Badge Not Showing

1. iTerm2 → Preferences → Profiles → General
2. Check **"Badge: Enabled"**
3. Test: `cd ~/Development` (badge should update)

---

## 📝 Quick Start Workflow

### Daily Usage

1. **Open iTerm2** → Tmux auto-starts
2. **Press `Ctrl+F`** → Select project
3. **Work in project** → direnv loads env vars automatically
4. **Badge shows** → Current directory + git branch
5. **Switch projects** → `Ctrl+F` again

### Example Session

```fish
# Session 1: budget-triage (Ctrl+F → select)
~/Development/budget-triage [main]
❯ echo $PROJECT_ENV  # direnv loaded this
production

# Session 2: system-setup (Ctrl+F → select)
~/Development/personal/system-setup-update [main]
❯ echo $PROJECT_ENV  # different env
development

# List all sessions
❯ tmux ls
budget-triage: 3 windows
system-setup: 1 window
main: 1 window

# Switch sessions: Ctrl+F or Ctrl+a S
```

---

## 🎯 Next Steps

### Recommended

1. **Configure Tide colors**: `tide configure`
2. **Set up project .envrc files** for environment management
3. **Create tmux sessions** for each major project
4. **Learn tmux copy mode**: `Ctrl+a [` then vim keys

### Optional Plugins

```fish
# Node version manager
fisher install jorgebucaran/nvm.fish

# Bash script compatibility
fisher install edc/bass

# Abbreviation tips
fisher install gazorby/fish-abbreviation-tips

# Text expansion
fisher install nickeb96/puffer-fish
```

---

## 📚 Resources

### Documentation
- [Fish Shell](https://fishshell.com/docs/current/)
- [Tmux Manual](https://man7.org/linux/man-pages/man1/tmux.1.html)
- [direnv](https://direnv.net/)
- [Tide Prompt](https://github.com/IlanCosman/tide)
- [Fisher](https://github.com/jorgebucaran/fisher)

### Themes
- [Catppuccin](https://github.com/catppuccin/catppuccin)
- [Nerd Fonts](https://www.nerdfonts.com/)

### Related Files
- Fish config: `~/.config/fish/config.fish`
- Tmux config: `~/.tmux.conf`
- Tide config: `~/.config/fish/conf.d/06-tide-config.fish`
- direnv config: `~/.config/fish/conf.d/02-direnv.fish`
- Keybindings: `~/.config/fish/conf.d/05-keybindings.fish`

---

**Setup Status**: ✅ Complete

All components installed and configured. Restart terminal to see everything in action.

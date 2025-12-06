---
title: "Modern Shell Setup - Pro Guide (Late 2025 Edition)"
category: documentation
component: shell
status: stable
version: 2.0.0
last_updated: 2025-11-21
tags: [fish, tmux, fisher, tide, starship, modern, pro-level, setup]
priority: high
---

# Modern Shell Setup - Pro Guide (Late 2025 Edition)

This guide implements a **modern, pro-level shell configuration** that is:
- ✨ **Beautiful** - Modern prompts with icons and colors
- 🚀 **Productive** - Fuzzy finding, smart completions, and powerful workflows
- 🔄 **Portable** - Works on macOS and Linux, syncs via chezmoi
- 💪 **Professional** - Industry best practices and muscle memory that transfers everywhere

## Philosophy: Option B (Pure Tmux)

This setup uses **Option B: Pure Tmux workflow** which means:
- Tmux handles all session management (not iTerm2)
- Your workflow is 100% portable to Linux servers
- iTerm2 is just a "frame" for your tmux sessions
- All muscle memory transfers to any environment

---

## The Stack

### Core Components

| Component | Purpose | Why This One? |
|-----------|---------|---------------|
| **Fish** | Shell | Modern syntax, amazing tab completion, no configuration needed for basics |
| **Fisher** | Plugin manager | Fast, simple, declarative plugin management |
| **Tmux** | Terminal multiplexer | Industry standard, works everywhere, powerful session management |
| **Starship** or **Tide** | Prompt | Fast, beautiful, informative (choose one) |
| **fzf.fish** | Fuzzy finder | Search history, files, processes interactively |
| **Chezmoi** | Dotfile manager | Manages configuration across machines |
| **Nerd Font** | Icons | Beautiful icons in prompt and file listings |

### Plugin Trinity

1. **fzf.fish** - Fuzzy search everything (Ctrl+R for history, Ctrl+Alt+F for files)
2. **tmux.fish** - Auto-start tmux, seamless integration
3. **tide** - Modern, fast prompt (alternative to Starship)

---

## Quick Start

### 1. Prerequisites

```bash
# Install the foundation (via Homebrew)
brew install fish tmux chezmoi starship fzf fd eza bat

# Install a Nerd Font (required for icons)
brew install --cask font-hack-nerd-font
# OR
brew install --cask font-meslo-lg-nerd-font
# OR
brew install --cask font-jetbrains-mono-nerd-font
```

### 2. Apply Chezmoi Templates

Our templates are already configured in this repository:

```bash
# Apply all templates
chezmoi apply

# This will create:
# - ~/.config/fish/config.fish (main configuration)
# - ~/.config/fish/conf.d/06-tmux.fish (tmux helpers)
# - ~/.tmux.conf (tmux configuration)
# - And install Fisher + plugins via run_once script
```

### 3. Install Fisher and Plugins

The installation is automatic via the `run_once_20-install-fisher-plugins.fish` script, but you can also do it manually:

```fish
# Download and install Fisher
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher

# Install the essential plugins
fisher install PatrickF1/fzf.fish             # Fuzzy search
fisher install budimanjojo/tmux.fish          # Tmux auto-start
fisher install IlanCosman/tide@v6             # Modern prompt (optional)
```

### 4. Configure iTerm2

See the [iTerm2 Configuration Guide](#iterm2-configuration) below.

### 5. Restart Your Terminal

```bash
# Close and reopen iTerm2, or:
exec fish
```

Tmux should auto-start, and you'll see your beautiful new prompt!

---

## Architecture

### File Structure

```
~/.config/fish/
├── config.fish                 # Main configuration (chezmoi-managed)
├── conf.d/                     # Auto-loaded configurations
│   ├── 00-homebrew.fish        # Homebrew environment
│   ├── 01-mise.fish            # mise activation
│   ├── 02-direnv.fish          # direnv integration
│   ├── 03-starship.fish        # Starship prompt
│   ├── 04-paths.fish           # PATH management
│   ├── 05-keybindings.fish     # Custom key bindings
│   ├── 06-tmux.fish            # Tmux helpers (NEW)
│   └── 10-19-*.fish            # Tool-specific configs
├── functions/                  # Custom functions
└── fish_plugins                # Fisher plugin list

~/.tmux.conf                    # Tmux configuration (chezmoi-managed)
~/.config/starship.toml         # Starship prompt config
```

### Configuration Loading Order

1. **Environment Setup** (`config.fish`)
   - MISE trusted paths
   - Security settings
   - Tmux auto-start configuration

2. **Core Configurations** (`conf.d/00-05-*.fish`)
   - Loaded alphabetically
   - Homebrew, mise, direnv, prompt, paths, keybindings

3. **Extended Configurations** (`conf.d/06-19-*.fish`)
   - Tmux helpers
   - Tool integrations (Claude, Codex, etc.)

4. **Plugins** (Fisher-managed)
   - fzf.fish, tmux.fish, tide
   - Loaded by Fisher

---

## Features

### Tmux Integration

#### Auto-Start Behavior

Tmux automatically starts when you open a terminal, unless:
- Already inside tmux
- In an SSH session (configurable)
- In VSCode or other IDE terminal
- `TMUX_AUTOSTART_DISABLE` is set

#### Tmux Key Bindings

| Key | Action |
|-----|--------|
| `Ctrl+a` | Prefix (changed from `Ctrl+b`) |
| `Ctrl+a \|` | Split vertically |
| `Ctrl+a -` | Split horizontally |
| `Ctrl+a h/j/k/l` | Navigate panes (vim-style) |
| `Ctrl+a c` | New window |
| `Ctrl+a ,` | Rename window |
| `Ctrl+a [` | Enter copy mode |
| `Ctrl+a r` | Reload config |

#### Helper Functions

```fish
# Create/attach to named session
tms <session-name>

# Create development session (3 windows: editor, terminal, logs)
tmdev [session-name]

# Show tmux status
tmstat

# Create project session with custom layout
tmux_project <project-path>

# Kill all sessions except current
tmclean

# Reload tmux config
tmreload
```

### FZF Integration

| Key Binding | Action |
|-------------|--------|
| `Ctrl+R` | Search command history |
| `Ctrl+Alt+F` | Search files |
| `Ctrl+Alt+L` | Search git log |
| `Ctrl+Alt+S` | Search git status |
| `Ctrl+Alt+P` | Search processes |

### Fish Aliases

#### Safety Aliases
```fish
rm -i      # Confirm before delete
cp -i      # Confirm before overwrite
mv -i      # Confirm before overwrite
```

#### Enhanced Commands (if eza/bat installed)
```fish
ll         # Detailed list with icons
la         # List all with icons
lt         # Tree view with icons
```

#### Git Shortcuts
```fish
g          # git
gs         # git status
ga         # git add
gc         # git commit
gp         # git push
gl         # git pull
gd         # git diff
glog       # git log --oneline --graph
```

#### Tmux Shortcuts
```fish
ta         # tmux attach
tms        # tmux_session
tmdev      # tmux_dev
tmstat     # tmux_status
```

#### Chezmoi Shortcuts
```fish
cz         # chezmoi
cza        # chezmoi apply
czd        # chezmoi diff
cze        # chezmoi edit
czs        # chezmoi status
```

### Custom Functions

#### mkcd - Create and enter directory
```fish
mkcd ~/new/project/path
# Creates all parent directories and cd's into it
```

#### extract - Smart archive extractor
```fish
extract archive.tar.gz
extract file.zip
extract bundle.rar
# Automatically detects and extracts any archive format
```

#### note - Quick note taking
```fish
note "Remember to update the docs"
# Appends to ~/notes/YYYY-MM-DD.md with timestamp

note
# Opens today's note file in $EDITOR
```

#### weather - Get weather
```fish
weather Seattle
weather London
# Shows current weather from wttr.in
```

---

## Prompt Configuration

### Option A: Starship (Default)

**Pros:**
- Written in Rust (extremely fast)
- Works across all shells (bash, zsh, fish)
- Highly configurable
- Great default configuration

**Configuration:** `~/.config/starship.toml`

Our configuration shows:
- Username (only on SSH)
- Hostname (only on SSH)
- Current directory (truncated, blue)
- Git branch and status (green/red)
- Command duration (if > 2s)
- Exit status indicator (green ❯ / red ❯)

### Option B: Tide (Alternative)

**Pros:**
- Written in Fish (native integration)
- Beautiful interactive configuration wizard
- Slightly faster than Starship for Fish
- Two-line prompt option

**Switch to Tide:**

1. Disable Starship in `03-starship.fish`:
   ```fish
   # Comment out the starship init line
   ```

2. Install Tide (already done by Fisher script):
   ```fish
   fisher install IlanCosman/tide@v6
   ```

3. Run configuration wizard:
   ```fish
   tide configure
   ```

4. Restart shell

---

## iTerm2 Configuration

### Required Settings

#### 1. Font (Essential for icons)

`Preferences → Profiles → Text → Font`

Choose a **Nerd Font**:
- Hack Nerd Font
- MesloLGS NF
- JetBrains Mono Nerd Font

Size: 13-14pt recommended

Enable: **Use ligatures** (if font supports it)

#### 2. Key Bindings

`Preferences → Profiles → Keys → Key Mappings`

- **Left Option key:** `Esc+` (for meta/alt key)
- **Right Option key:** `Normal` (for special characters like [, ], etc.)

#### 3. Clipboard Integration

`Preferences → General → Selection`

Enable:
- ✅ Applications in terminal may access clipboard

`Preferences → Profiles → Terminal`

- Report Terminal Type: `xterm-256color`
- Enable: ✅ Terminal may enable paste bracketing

#### 4. Color Scheme (Optional but Beautiful)

`Preferences → Profiles → Colors`

Import a theme:
- **Catppuccin Mocha** (recommended, matches tmux theme)
- **Solarized Dark**
- **Nord**
- **Dracula**

Download themes from: [iTerm2 Color Schemes](https://iterm2colorschemes.com/)

#### 5. Disable Native Tabs (Important for Option B)

`Preferences → Appearance → Tabs`

- ❌ Show tab bar even when there is only one tab

`Preferences → Advanced`

Search for "tabs" and:
- Set "tmux Integration" options to disabled/default

This ensures tmux handles all windowing.

---

## Tmux Theme (Catppuccin Mocha)

The tmux configuration uses the **Catppuccin Mocha** color palette for a cohesive, modern look.

### Color Palette

- **Background:** `#1e1e2e` (dark gray-blue)
- **Foreground:** `#cdd6f4` (light blue-white)
- **Blue:** `#89b4fa` (active elements)
- **Green:** `#a6e3a1` (success, date)
- **Red:** `#f38ba8` (alerts, errors)
- **Purple:** `#cba6f7` (accents)

### Status Bar Layout

**Top of screen:**
```
[Session: main]  1:editor 2:terminal* 3:logs     hostname CPU: 15% 🔋85% 2025-11-21 14:32:45
```

- Left: Session name (blue background)
- Center: Window list (current highlighted)
- Right: Hostname, CPU, battery (macOS), date, time

**Customization:**

Edit `~/.tmux.conf`:
```tmux
# Move status bar to bottom
set -g status-position bottom

# Customize right status (example: add memory usage)
set -g status-right '... MEM: #(free | grep Mem | awk "{print \$3}") ...'
```

---

## Advanced Features

### Nested Tmux Sessions

When SSH'ing into a server that also uses tmux:

**Press `F12`** to toggle between local and remote tmux control.

- First `F12`: Disables local tmux, allows remote tmux to receive commands
- Second `F12`: Re-enables local tmux

Status bar changes color to indicate which tmux is active.

### Tmux Plugin Manager (TPM)

Optional but powerful. Uncomment the TPM section in `~/.tmux.conf`:

```bash
# Install TPM
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Uncomment in `~/.tmux.conf`:
```tmux
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'   # Save/restore sessions
set -g @plugin 'tmux-plugins/tmux-continuum'   # Auto-save sessions
run '~/.tmux/plugins/tpm/tpm'
```

Then: `Ctrl+a I` to install plugins

### Session Persistence

With tmux-resurrect and tmux-continuum plugins:

**Save session:** `Ctrl+a Ctrl+s`
**Restore session:** `Ctrl+a Ctrl+r`

Or enable auto-save:
```tmux
set -g @continuum-restore 'on'
```

Sessions survive reboots!

---

## Troubleshooting

### Tmux doesn't auto-start

**Check variables:**
```fish
echo $fish_tmux_autostart
# Should be: true
```

**Check if tmux.fish plugin is installed:**
```fish
fisher list | grep tmux
# Should show: budimanjojo/tmux.fish
```

**Disable for testing:**
```fish
set -gx TMUX_AUTOSTART_DISABLE 1
exec fish
```

### Icons/glyphs show as boxes

**Solution:** Install a Nerd Font and set it in iTerm2

```bash
brew install --cask font-hack-nerd-font
```

Then: iTerm2 → Preferences → Profiles → Text → Font → Hack Nerd Font

### Colors look wrong

**Check terminal type:**
```fish
echo $TERM
# Should be: xterm-256color (in iTerm2)
# Should be: tmux-256color or screen-256color (in tmux)
```

**Force true color in tmux:**

Already configured in our `tmux.conf`, but verify:
```tmux
set-option -sa terminal-overrides ",xterm*:Tc"
```

### Fisher plugins not loading

**Reinstall Fisher:**
```fish
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
```

**Update plugins:**
```fish
fisher update
```

**List installed plugins:**
```fish
fisher list
```

### Tmux prefix not working

**Check if prefix changed:**
```fish
tmux show-options -g | grep prefix
# Should show: prefix C-a
```

**Reload config:**
```fish
tmux source-file ~/.tmux.conf
```

Or: `Ctrl+a r` (if configured)

### Fish performance slow

**Disable auto-start temporarily:**
```fish
set -gx TMUX_AUTOSTART_DISABLE 1
```

**Check startup time:**
```fish
fish --profile /tmp/fish.prof -ic exit
cat /tmp/fish.prof
```

**Common culprits:**
- Too many plugins
- Slow network checks in conf.d scripts
- Complex prompt configurations

---

## Customization

### Machine-Specific Overrides

Create local configs (NOT managed by chezmoi):

**Fish:** `~/.config/fish/config.local.fish`
```fish
# Machine-specific aliases
alias deploy 'ssh production'
```

**Tmux:** `~/.tmux.local.conf`
```tmux
# Machine-specific bindings
bind-key C-x run-shell "custom-script"
```

These files are sourced at the end of the main configs.

### Disable Tmux Auto-Start for Specific Machines

Edit `~/.config/chezmoi/chezmoi.toml`:
```toml
headless = true
```

Or set environment variable:
```fish
set -U TMUX_AUTOSTART_DISABLE 1
```

### Change Tmux Prefix

Edit `~/.tmux.conf`:
```tmux
# Use Ctrl+s instead of Ctrl+a
unbind C-a
set -g prefix C-s
bind C-s send-prefix
```

Then reload: `tmux source-file ~/.tmux.conf`

---

## Migration from Other Setups

### From Bash/Zsh

1. **Keep bash/zsh available** (some scripts require it)
2. **Set Fish as default shell:**
   ```bash
   chsh -s /opt/homebrew/bin/fish
   ```
3. **Convert aliases** using our reference: `docs/fish-vs-bash-reference.md`
4. **Port functions** to Fish syntax

### From iTerm2 Native Tabs

1. **Close all iTerm2 tabs**
2. **Start fresh terminal** (tmux will auto-start)
3. **Create tmux windows** instead of iTerm2 tabs
   - `Ctrl+a c` instead of `Cmd+t`
4. **Update muscle memory:**
   - iTerm2 Cmd+number → Tmux Ctrl+a number
   - iTerm2 Cmd+d → Tmux Ctrl+a |
   - iTerm2 Cmd+Shift+d → Tmux Ctrl+a -

### From Screen

Tmux is largely compatible. Main changes:

| Screen | Tmux |
|--------|------|
| `Ctrl+a c` | `Ctrl+a c` (same) |
| `Ctrl+a n` | `Ctrl+a n` (same) |
| `Ctrl+a "` | `Ctrl+a w` (window list) |
| `Ctrl+a S` | `Ctrl+a -` (split horizontal) |
| `Ctrl+a \|` | `Ctrl+a \|` (split vertical) |

---

## Maintenance

### Update Plugins

```fish
fisher update
```

### Update Chezmoi Templates

```bash
# On main machine (this repo):
git pull origin main
chezmoi apply

# On other machines:
chezmoi update
```

### Backup Configuration

Chezmoi handles this automatically if you've set up a git repo:

```bash
chezmoi git add .
chezmoi git commit -m "Update configuration"
chezmoi git push
```

### Clean Start

If things get messed up:

```fish
# Remove Fisher and plugins
rm -rf ~/.config/fish/fish_plugins
rm -rf ~/.config/fish/functions/fisher.fish

# Re-run installer
~/.local/share/chezmoi/run_once_20-install-fisher-plugins.fish

# Or manually:
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
fisher install jorgebucaran/fisher PatrickF1/fzf.fish budimanjojo/tmux.fish IlanCosman/tide@v6
```

---

## Performance Benchmarks

With this configuration:

| Metric | Target | Typical |
|--------|--------|---------|
| **Shell startup** | < 100ms | ~50ms |
| **Prompt render** | < 10ms | ~5ms |
| **Tmux attach** | < 200ms | ~100ms |
| **FZF search (1000 files)** | < 50ms | ~30ms |

If your setup is slower, check:
1. Number of plugins
2. Complex prompt configurations
3. Network checks in startup scripts

---

## Resources

### Official Documentation

- [Fish Shell](https://fishshell.com/docs/current/)
- [Fisher](https://github.com/jorgebucaran/fisher)
- [Tmux](https://github.com/tmux/tmux/wiki)
- [Starship](https://starship.rs/)
- [Tide](https://github.com/IlanCosman/tide)
- [fzf](https://github.com/junegunn/fzf)
- [Chezmoi](https://www.chezmoi.io/)

### Plugins

- [fzf.fish](https://github.com/PatrickF1/fzf.fish)
- [tmux.fish](https://github.com/budimanjojo/tmux.fish)
- [Awesome Fish](https://github.com/jorgebucaran/awsm.fish) (plugin directory)

### Themes

- [Catppuccin](https://github.com/catppuccin/catppuccin)
- [iTerm2 Color Schemes](https://iterm2colorschemes.com/)

### Repository Files

- **Config template:** `06-templates/chezmoi/dot_config/fish/config.fish.tmpl`
- **Tmux template:** `06-templates/chezmoi/dot_tmux.conf.tmpl`
- **Fisher installer:** `06-templates/chezmoi/run_once_20-install-fisher-plugins.fish.tmpl`
- **Tmux helpers:** `06-templates/chezmoi/dot_config/fish/conf.d/06-tmux.fish.tmpl`
- **Fish vs Bash reference:** `docs/fish-vs-bash-reference.md`

---

## Next Steps

1. **Apply the configuration**
   ```bash
   chezmoi apply
   ```

2. **Restart terminal**
   ```bash
   exec fish
   ```

3. **Customize prompt** (if using Tide)
   ```fish
   tide configure
   ```

4. **Learn tmux basics**
   - Practice window and pane management
   - Customize keybindings to your preference

5. **Explore plugins**
   ```fish
   fisher list                    # See installed plugins
   # Browse: https://github.com/jorgebucaran/awsm.fish
   ```

6. **Set up on other machines**
   ```bash
   chezmoi init <your-dotfiles-repo>
   chezmoi apply
   ```

---

## Feedback and Contributions

This is a living configuration. Suggestions welcome!

- **Issues:** Found a bug? Open an issue
- **Improvements:** Better keybindings? Submit a PR
- **Questions:** Check `docs/fish-vs-bash-reference.md` first

Happy terminal-ing! 🚀

---
title: iTerm2 Chezmoi Integration
category: configuration
component: iterm2
status: active
version: 1.0.0
last_updated: 2025-09-26
tags: [configuration, settings, terminal, macos]
applies_to:
  - os: macos
    versions: ["14.0+", "15.0+"]
  - arch: ["arm64", "x86_64"]
priority: medium
---

# iTerm2 Chezmoi Integration Guide

## Overview

This document describes the tailored iTerm2 configuration that integrates with our chezmoi-based system configuration, leveraging Dynamic Profiles for machine-specific customization.

## Architecture

### 1. Dynamic Profiles Strategy

Instead of managing the monolithic `com.googlecode.iterm2.plist` file, we use iTerm2's Dynamic Profiles feature:

- **Location**: `~/.config/iterm2/DynamicProfiles/`
- **Format**: JSON templates processed by chezmoi
- **Auto-reload**: iTerm2 monitors and loads changes immediately
- **Inheritance**: Base profile + specialized profiles

### 2. Profile Structure

```
~/.local/share/chezmoi/dot_config/iterm2/DynamicProfiles/
├── base.json.tmpl           # Base configuration (fonts, colors, performance)
├── development.json.tmpl    # Development profiles (personal/work/business)
└── servers.json.tmpl        # Server connection profiles (conditional)
```

## Configuration Files

### Base Profile (`base.json.tmpl`)

The foundation profile that all others inherit from:

- **Name**: `{{ .hostname }}-base`
- **Shell**: Configured to use Fish from Homebrew
- **Font**: MesloLGS-NF (Nerd Font) with ligatures
- **Status Bar**: Shows hostname, path, git, memory, CPU
- **Triggers**: Highlights errors and warnings
- **Performance**: Optimized scrollback, GPU rendering support

Key Features:
- Smart cursor color
- Visual bell (no sound)
- Semantic history with VS Code integration
- 10,000 line scrollback buffer
- Solarized-inspired color scheme

### Development Profiles (`development.json.tmpl`)

Context-aware profiles for different development environments:

1. **Personal Dev**
   - Working Directory: `~/Development/personal`
   - Badge: "PERSONAL" (blue)
   - Auto-switches when entering personal projects
   - NPM build status triggers

2. **Work Dev** (conditional on `.is_work`)
   - Working Directory: `~/Development/work`
   - Badge: "WORK" (orange)
   - Slightly tinted background for visual distinction
   - JIRA ticket highlighting

3. **Business Dev**
   - Working Directory: `~/Development/business`
   - Badge: "BUSINESS" (purple)
   - Auto-switches for business projects

4. **System Config**
   - Working Directory: `~/.local/share/chezmoi`
   - Badge: "CONFIG" (green)
   - Special triggers for chezmoi and mise commands

### Server Profiles (`servers.json.tmpl`)

Conditional profiles for server management (requires `.has_hetzner = true`):

- **Web1**: Production web server (red badge, red-tinted background)
- **DB1**: Database server (orange badge, confirms before closing)
- **Staging**: Staging environment (yellow badge)

Safety features:
- Dangerous command highlighting (DROP, DELETE, sudo)
- Visual alerts for errors
- Confirmation prompts on production servers

## Chezmoi Data Integration

### New Configuration Variables

Added to `.chezmoi.toml.tmpl`:

```toml
iterm2_theme = "dark"    # Options: dark/light/auto
iterm2_gpu = true        # Enable GPU rendering
iterm2_ai = false        # Enable AI features
```

### Conditional Logic

Templates use chezmoi's Go template syntax with defensive guards:

```go
{{- if not (.headless | default false) -}}
  // GUI-specific configuration
{{- end -}}

{{- if .is_work -}}
  // Work-specific profiles
{{- end -}}
```

## Installation Process

### Run-Once Script (`run_once_07-configure-iterm2.sh.tmpl`)

Automated setup that:

1. **Installs iTerm2** if missing (via Homebrew)
2. **Creates directories** for configuration
3. **Links Dynamic Profiles** to iTerm2's monitored directory
4. **Configures preferences**:
   - Sets custom preferences folder
   - Enables/disables GPU rendering
   - Configures theme (dark/light/auto)
5. **Installs Shell Integration** for Fish
6. **Applies modern features**:
   - Navigator path clicks
   - Relative timestamps
   - Hide cursor on focus loss
7. **Creates validation script** for testing

## Profile Switching Rules

Automatic profile switching based on:

- **Directory**: Changes profile when entering specific paths
- **Hostname**: Maintains context across machines
- **Username**: Useful for sudo sessions

Example rules:
- `~/Development/personal/*` → Personal Dev profile
- `~/Development/work/*` → Work Dev profile
- `~/.local/share/chezmoi/*` → System Config profile

## Performance Optimizations

Based on iTerm2 reports analysis:

1. **GPU Rendering**: Enabled by default for M3 Max
2. **Ligatures**: Carefully managed (disabled for high-throughput)
3. **Scrollback**: Limited to 10,000 lines
4. **Background compression**: Enabled for inactive windows
5. **Smart triggers**: Regex patterns optimized for performance

## Security Features

1. **Server profiles**: Red backgrounds for production
2. **Dangerous commands**: Highlighted in triggers
3. **Clipboard access**: Controlled permissions
4. **AI features**: Require explicit opt-in
5. **Password manager**: Integrates with system keychain

## Validation

After setup, run:

```bash
~/.config/iterm2/validate-config.sh
```

This checks:
- iTerm2 version
- Dynamic Profiles loaded
- Custom preferences location
- GPU rendering status
- Shell integration

## Benefits

1. **Portable**: All configuration in version control
2. **Machine-specific**: Adapts to work/personal/server contexts
3. **Performance**: Leverages GPU, optimized for M3 Max
4. **Safe**: Visual cues for production environments
5. **Integrated**: Works with Fish, mise, and chezmoi
6. **Modern**: Uses iTerm2 3.6.2 features (Navigator, AI, etc.)

## Troubleshooting

### Profiles Not Loading

```bash
# Check symlinks
ls -la ~/Library/Application\ Support/iTerm2/DynamicProfiles/

# Verify JSON syntax
json_verify ~/.config/iterm2/DynamicProfiles/*.json
```

### GPU Rendering Issues

```bash
# Check status
defaults read com.googlecode.iterm2 DisableMetalRenderer

# Toggle GPU
defaults write com.googlecode.iterm2 DisableMetalRenderer -bool true
```

### Profile Switching Not Working

1. Ensure Shell Integration is installed
2. Check automatic switching rules match your paths
3. Verify `.chezmoi.toml` has correct data values

## Future Enhancements

1. **AI Integration**: Configure API keys when `.iterm2_ai = true`
2. **Theme Packs**: Additional color schemes based on preference
3. **Keyboard Shortcuts**: Custom key bindings for common tasks
4. **Status Bar Widgets**: Custom Python components
5. **tmux Integration**: Deep integration for remote sessions

## Resources

- [iTerm2 Dynamic Profiles Documentation](https://iterm2.com/documentation-dynamic-profiles.html)
- [Chezmoi Templates Guide](https://www.chezmoi.io/user-guide/templating/)
- [iTerm2 3.6.2 Release Notes](https://iterm2.com/downloads.html)
- Project Documentation: `docs/iterm-reports.md`
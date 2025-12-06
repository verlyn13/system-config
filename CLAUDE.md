---
title: AI Assistant Context
category: reference
component: ai-context
status: active
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---


# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository contains configuration documentation and templates for setting up a reproducible macOS development environment using chezmoi, Homebrew, Fish shell, and mise. It implements a phased approach to system configuration with emphasis on modularity and machine-specific customization.

## Key Architecture

### Documentation Structure
- **mac-dev-env-setup.md**: Main setup guide with 10 implementation phases
- **implementation-status.md**: Current state tracking (Phases 0-3 complete, 4 partial, 5-10 pending)
- **chezmoi-templates.md**: Template structure and examples for dotfiles management

### Chezmoi Configuration Architecture
The system uses chezmoi for dotfile management with this critical structure:
- **Source**: `~/.local/share/chezmoi/` - Template files and run_once scripts
- **Data**: `~/.config/chezmoi/chezmoi.toml` - Machine-specific values (NOT `.chezmoidata.toml`)
- **Templates**: Use Go template syntax with guards like `(.headless | default false)`

### Critical File Locations
```
~/.local/share/chezmoi/
├── .chezmoi.toml.tmpl          # Prompts for machine-specific data
├── run_once_*.sh.tmpl          # One-time setup scripts
├── dot_config/                 # Fish, mise configs
└── workspace/
    ├── dotfiles/               # Brewfiles and templates
    └── scripts/                # Helper scripts
```

## Common Commands

### Apply Configuration Changes
```bash
# Apply chezmoi changes (use after modifying templates)
chezmoi apply

# Dry run to preview changes
chezmoi apply --dry-run

# Regenerate config to eliminate template warnings
chezmoi init --apply
```

### Fix Common Issues
```bash
# If Claude CLI not found after setup
fish -c 'echo $PATH | tr " " "\n" | grep npm'  # Check if npm-global is in PATH

# Complete GUI app installation if timed out
cd ~/.local/share/chezmoi/workspace/dotfiles
brew bundle --file=Brewfile.gui

# Install mise-managed language tools
mise install
```

### Testing Configuration
```bash
# Test Fish shell configuration
fish -c 'claude --version'  # Should return version if PATH is correct

# Check chezmoi status
chezmoi status

# Verify mise configuration
mise doctor
```

## Template Syntax Requirements

### Chezmoi Templates Must Use Proper Guards
When accessing data values that might not exist:
```go
// CORRECT - Use defaults to prevent "map has no entry" errors
{{ if not (.headless | default false) -}}
{{ if eq (.shell | default "fish") "fish" -}}

// INCORRECT - Will fail if key doesn't exist
{{ if not .headless -}}
{{ if eq .shell "fish" -}}
```

### Required Data Keys in chezmoi.toml
The following keys must exist in `~/.config/chezmoi/chezmoi.toml`:
- `headless` (bool): Whether this is a headless server
- `android` (bool): Whether to install Android development tools
- `shell` (string): Default shell choice (usually "fish")

## Phase Implementation Status

Currently tracking 10 phases of setup:
- **Phase 0-3**: ✅ Complete (Foundation, Homebrew, Dotfiles, Fish)
- **Phase 4**: ⏸️ Partial (mise version management)
- **Phase 5-10**: ❌ Not started (Security, Containers, Android, Bootstrap, Templates, Optimization)

## Gopass Secret Management

For complete gopass usage instructions, see:
- **Definitive Guide**: `docs/guides/GOPASS-DEFINITIVE-GUIDE.md`
- **Quick Reference**: `~/.config/gopass/README-AGENTS.md`
- **Passphrase**: Always `escapable diameter silk discover`

## AI CLI Tools Configuration

### Claude Code CLI
- **Installation**: npm global (`@anthropic-ai/claude-code`)
- **Version**: 2.0.34 (current)
- **Location**: `~/.npm-global/bin/claude`
- **Fish config**: `~/.config/fish/conf.d/10-claude.fish` (managed via chezmoi)
- **Fish template**: `06-templates/chezmoi/dot_config/fish/conf.d/10-claude.fish.tmpl`
- **Global config**: `~/.claude/` (**direct management, NOT chezmoi**)
  - `settings.json` - Tool permissions, environment variables (Node 24, Biome)
  - `CLAUDE.md` - Global development context
  - `commands/` - Slash commands (dev, ops, research)
  - `agents/` - Pre-configured agents (architect, security, tester, docs, reviewer, explorer)
  - `README.md` - Configuration documentation
- **Config templates**: `06-templates/chezmoi/dot_claude/` (reference only, for future migration)
- **Installer**: `06-templates/chezmoi/run_once_10-install-claude.sh.tmpl`
- **Documentation**: `docs/claude-cli-setup.md`, `~/.claude/README.md`
- **Migration guide**: `docs/CLAUDE-CONFIG-CHEZMOI-MIGRATION.md` (future)
- **Update method**: `npm update -g @anthropic-ai/claude-code`
- **Settings**: Subscription-based auth (default), API auth available
- **Formatting**: Uses Biome for JS/TS (NOT Prettier)
- **Management philosophy**: Direct editing for flexibility during active CLI development
- **Aliases**:
  - `cc` - Claude with default model (Sonnet 4.5)
  - `ccc` - Continue conversation
  - `ccp` - Plan/headless mode
  - `ccplan` - Force Opus model with API auth
  - `claude_check_updates` - Check for CLI updates

### Gemini CLI
- **Config**: `~/.config/fish/conf.d/11-gemini.fish`
- **Settings**: `~/.gemini/settings.json`
- **API Key**: Stored in gopass at `gemini/api-keys/development`
- **Aliases**: `gc` (gemini), `gcp` (prompt mode), `gcflash` (fast model)
- **Context**: Project-specific in `.gemini/GEMINI.md`

### Codex CLI
- **Installation**: Homebrew (`brew install openai/openai/codex`)
- **Location**: `/opt/homebrew/bin/codex` (via PATH)
- **Config**: `~/.codex/config.toml` (single global file; not in chezmoi)
- **Fish config**: `~/.config/fish/conf.d/12-codex.fish`
- **Template**: `06-templates/chezmoi/dot_config/fish/conf.d/12-codex.fish.tmpl`
- **Installer**: `06-templates/chezmoi/run_once_12-install-codex.sh.tmpl`
- **Documentation**: `docs/codex-cli-setup.md`
- **Config guide**: `02-configuration/tools/codex-cli.md`
- **Update script**: `scripts/update-codex-cli.sh`
- **Aliases**:
  - `codex` / `cx` - Codex CLI
  - `cxp <profile>` - Profile selector
  - `cxfast` - Fast profile
  - `cxreview` - Review profile
  - `codex_check_updates` - Check for updates
  - `codex_status` - Show status

### Windsurf AI IDE
- **Installation**: Homebrew cask (`brew install --cask windsurf`)
- **Type**: Agentic IDE with AI Flow paradigm (by Codeium)
- **Location**: `/Applications/Windsurf.app`
- **CLI Binary**: `/Applications/Windsurf.app/Contents/Resources/app/bin/windsurf`
- **Fish config**: `~/.config/fish/conf.d/13-windsurf.fish`
- **Template**: `06-templates/chezmoi/dot_config/fish/conf.d/13-windsurf.fish.tmpl`
- **Installer**: `06-templates/chezmoi/run_once_13-install-windsurf.sh.tmpl`
- **Brewfile**: Listed in `workspace/dotfiles/Brewfile.gui`
- **Documentation**: https://docs.windsurf.com/
- **Aliases**:
  - `windsurf` - Windsurf CLI
  - `ws` - Short alias
  - `wso` - Open current directory
  - `wsn` - New window
  - `windsurf_check_updates` - Check for updates
  - `windsurf_status` - Show installation status

### Sentry CLI
- **Installation**: npm global (`@sentry/cli`)
- **Location**: `~/.npm-global/bin/sentry-cli`
- **Fish config**: `~/.config/fish/conf.d/14-sentry.fish`
- **Template**: `06-templates/chezmoi/dot_config/fish/conf.d/14-sentry.fish.tmpl`
- **Installer**: `06-templates/chezmoi/run_once_14-install-sentry.sh.tmpl`
- **Documentation**: `docs/sentry-cli-setup.md`
- **Update script**: `scripts/update-sentry-cli.sh`
- **Settings**: Environment variables (SENTRY_AUTH_TOKEN, SENTRY_ORG, SENTRY_PROJECT)
- **Auth**: gopass integration at `sentry/auth-token`
- **Aliases**:
  - `sentry` / `sentry-cli` - Sentry CLI
  - `sentry-upload` - Upload source maps
  - `sentry-releases` - Manage releases
  - `sentry-info` - Show configuration
  - `sentry-login` - Authenticate
  - `sentry_check_updates` - Check for updates
  - `sentry_status` - Show installation status

### Vercel CLI
- **Installation**: npm global (`vercel`)
- **Location**: `~/.npm-global/bin/vercel`
- **Fish config**: `~/.config/fish/conf.d/15-vercel.fish`
- **Template**: `06-templates/chezmoi/dot_config/fish/conf.d/15-vercel.fish.tmpl`
- **Installer**: `06-templates/chezmoi/run_once_15-install-vercel.sh.tmpl`
- **Documentation**: `docs/vercel-cli-setup.md`
- **Update script**: `scripts/update-vercel-cli.sh`
- **Settings**: Environment variables (VERCEL_TOKEN, VERCEL_ORG_ID, VERCEL_PROJECT_ID)
- **Auth**: Interactive login or gopass integration at `vercel/token`
- **Aliases**:
  - `vercel` / `vc` - Vercel CLI
  - `vercel-deploy` - Deploy to production
  - `vercel-preview` - Deploy to preview
  - `vercel-dev` - Local dev server
  - `vercel-logs` - View deployment logs
  - `vercel-env` - Manage environment variables
  - `vercel-pull` - Pull env vars locally
  - `vercel-link` - Link directory to project
  - `vercel-list` - List deployments
  - `vercel-prod` - Deploy + Sentry release
  - `vercel-staging` - Preview + Sentry release
  - `vercel_check_updates` - Check for updates
  - `vercel_status` - Show installation status

### Supabase CLI
- **Installation**: Homebrew tap (`supabase/tap/supabase`)
- **Version**: 2.53.6 (current)
- **Location**: `/opt/homebrew/bin/supabase`
- **Fish config**: `~/.config/fish/conf.d/16-supabase.fish`
- **Template**: `06-templates/chezmoi/dot_config/fish/conf.d/16-supabase.fish.tmpl`
- **Installer**: `06-templates/chezmoi/run_once_16-install-supabase.sh.tmpl`
- **Update script**: `scripts/update-supabase-cli.sh`
- **Settings**: Environment variables (SUPABASE_ACCESS_TOKEN, SUPABASE_PROJECT_ID)
- **Auth**: gopass integration at `supabase/access-token`
- **Requirements**: Docker (via OrbStack or Docker Desktop) for local development
- **Aliases**:
  - `supabase` - Supabase CLI
  - `supabase-start` / `sb-dev` - Start local stack
  - `supabase-stop` - Stop local stack
  - `supabase-status` - Show services status
  - `supabase-db` - Database commands
  - `supabase-db-diff` - Generate migration
  - `supabase-db-push` - Push schema to remote
  - `supabase-db-pull` - Pull schema from remote
  - `supabase-migration` - Manage migrations
  - `supabase-functions` - Manage Edge Functions
  - `supabase-gen` / `sb-types` - Generate TypeScript types
  - `sb-studio` - Open Supabase Studio
  - `supabase_check_updates` - Check for updates
  - `supabase_status` - Show installation status

### OrbStack
- **Installation**: Homebrew cask (`brew install --cask orbstack`)
- **Version**: Check with `orb version`
- **Type**: Docker Desktop replacement with container and Linux VM support
- **Location**: `/Applications/OrbStack.app`
- **CLI binaries**: `/Applications/OrbStack.app/Contents/MacOS/bin/`
- **Fish config**: `~/.config/fish/conf.d/17-orbstack.fish`
- **Template**: `06-templates/chezmoi/dot_config/fish/conf.d/17-orbstack.fish.tmpl`
- **Installer**: `06-templates/chezmoi/run_once_17-install-orbstack.sh.tmpl`
- **Brewfile**: Listed in `workspace/dotfiles/Brewfile.gui`
- **Documentation**: `docs/orbstack-setup.md`, https://docs.orbstack.dev/
- **Update script**: `scripts/update-orbstack.sh`
- **Settings**: Configured via OrbStack GUI application
- **Features**: Docker Engine, Linux VMs, Kubernetes, lower resource usage than Docker Desktop
- **Aliases**:
  - `orb`, `orbctl` - OrbStack management CLIs (native commands, not aliases)
  - `docker`, `docker-compose` - Docker CLIs (native commands via OrbStack)
  - `orbstart` - Start OrbStack (`orb start`)
  - `orbstop` - Stop OrbStack (`orb stop`)
  - `orbrestart` - Restart OrbStack (`orb restart`)
  - `orbstatus` - Show running status (`orb status`)
  - `orbinfo` - Show system information (`orb info`)
  - `orbopen` - Open OrbStack application
  - `dps` - List running containers (`docker ps`)
  - `dpsa` - List all containers (`docker ps -a`)
  - `dimages` - List Docker images
  - `dclean` - Clean up unused Docker resources (with confirmation)
  - `orbstack_status` - Comprehensive installation and status check (Fish)
  - `orbstack_check_updates` - Check for updates

### Tailscale
- **Installation**: Official .pkg installer from https://tailscale.com/download/macos (recommended)
- **Version**: 1.90.6 (current) - Check with `tailscale version`
- **Type**: Mesh VPN based on WireGuard
- **Location**: `/Applications/Tailscale.app`
- **CLI binary**: `/Applications/Tailscale.app/Contents/MacOS/tailscale`
- **Fish config**: `~/.config/fish/conf.d/18-tailscale.fish` (adds CLI to PATH automatically)
- **Template**: `06-templates/chezmoi/dot_config/fish/conf.d/18-tailscale.fish.tmpl`
- **Installer**: `06-templates/chezmoi/run_once_18-install-tailscale.sh.tmpl` (downloads and installs .pkg)
- **Documentation**: https://tailscale.com/kb/
- **Settings**: Configured via Tailscale GUI or CLI
- **System Extension**: Requires macOS system extension approval (System Settings → Privacy & Security)
- **Features**: Zero-config VPN, WireGuard-based mesh networking, secure remote access
- **Update method**: Download latest .pkg from https://tailscale.com/download/macos or check via app menu
- **Aliases**:
  - `tailscale` - Tailscale CLI (native command, requires sudo for up/down)
  - `tsup` - Connect to Tailscale network (`sudo tailscale up`)
  - `tsdown` - Disconnect from Tailscale (`sudo tailscale down`)
  - `tsstatus` - Show connection status (`tailscale status`)
  - `tsip` - Show Tailscale IP addresses (`tailscale ip`)
  - `tsping <device>` - Ping a device on network
  - `tsnetcheck` - Check network connectivity
  - `tsfile` - Send/receive files via Tailscale
  - `tsssh <device>` - SSH to a device on network
  - `tsopen` - Open Tailscale GUI application
  - `tailscale_status` - Comprehensive installation and status check (Fish)
  - `tailscale_check_updates` - Check for updates

### direnv (Environment Variable Management)
- **Installation**: Homebrew (`brew install direnv`)
- **Version**: 2.37.1 (current)
- **Location**: `/opt/homebrew/bin/direnv`
- **Purpose**: Automatic per-directory environment variable loading/unloading
- **Fish config**: `~/.config/fish/conf.d/02-direnv.fish` (chezmoi-managed)
- **Template**: `06-templates/chezmoi/dot_config/fish/conf.d/02-direnv.fish.tmpl`
- **direnv config**: `~/.config/direnv/direnv.toml` (chezmoi-managed)
- **Config template**: `06-templates/chezmoi/dot_config/direnv/direnv.toml.tmpl`
- **Helper functions**: `~/.config/direnv/direnvrc` (chezmoi-managed)
- **Documentation**: `docs/direnv-setup.md`
- **Key features**:
  - Automatic environment loading on `cd` into directories with `.envrc`
  - Unloads variables when leaving directory (project isolation)
  - Security: Requires explicit `direnv allow .` for new/modified `.envrc` files
  - Integration with mise for version management
  - Uses Homebrew Bash (`/opt/homebrew/bin/bash`) instead of Apple's `/bin/bash` to avoid crashes on macOS Sequoia
- **Common usage**:
  ```bash
  # Create .envrc in project
  echo 'export API_KEY="secret"' > .envrc
  direnv allow .

  # Verify
  cd project/      # Variables load automatically
  echo $API_KEY    # "secret"
  cd ..            # Variables unload
  echo $API_KEY    # (empty)
  ```
- **Standard pattern** (with mise):
  ```bash
  # .envrc - Standard pattern for projects
  use mise
  export PROJECT_NAME="$(basename $PWD)"
  source_env_if_exists .envrc.local  # Gitignored secrets
  ```
- **Infrastructure projects**: See `/Users/verlyn13/Development/the-nash-group/the-citadel/.envrc.template` for Terraform/IaC pattern with `TF_VAR_*` secrets
- **Verification**:
  ```bash
  fish -c 'type -q direnv && echo "✅ direnv configured" || echo "❌ not configured"'
  ```

## Known Issues and Solutions

### Terminal Key Bindings (Paste, History Navigation)
Fish shell key bindings configured in `~/.config/fish/conf.d/05-keybindings.fish`:
- **Up/Down arrows**: Smart history search (searches with prefix if text entered)
- **Ctrl+P/N**: History navigation (Emacs-style)
- **Ctrl+R**: History pager
- **Paste (⌘V)**: Handled by iTerm2, requires proper configuration

iTerm2 Configuration Requirements:
1. **Settings → Profiles → Keys → Key Mappings**:
   - Left Option key: "Esc+" (for meta/alt key)
   - Right Option key: "Normal" (for special characters)
2. **Settings → General → Selection**:
   - ✓ "Applications in terminal may access clipboard"
3. **Settings → Profiles → Terminal**:
   - Report Terminal Type: xterm-256color
   - ✓ "Terminal may enable paste bracketing"

Run `scripts/iterm2-setup.sh` for complete configuration guide.

### PATH Configuration
If tools aren't accessible after setup, ensure `~/.config/fish/conf.d/04-paths.fish` exists with:
```fish
fish_add_path ~/.npm-global/bin
fish_add_path ~/bin
fish_add_path ~/.local/bin
```

### Template Errors
If you see "map has no entry for key" errors:
1. Add missing keys to `~/.config/chezmoi/chezmoi.toml`
2. Update templates to use `| default` guards
3. Run `chezmoi apply` again

### Homebrew Bundle Timeouts
GUI applications can timeout during installation. Continue with:
```bash
cd ~/.local/share/chezmoi/workspace/dotfiles
brew bundle --file=Brewfile.gui
```

## Project Initialization

Use the provided script to bootstrap new projects:
```bash
~/.local/share/chezmoi/workspace/scripts/init-project.sh [project-path]
```

This creates:
- `.mise.toml` with common tasks (test, lint, format, dev, build, clean)
- `.envrc` for direnv integration
- Git initialization if not present

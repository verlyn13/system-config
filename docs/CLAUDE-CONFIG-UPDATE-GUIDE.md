---
title: Claude Code Configuration Update Guide
category: guide
component: claude-config-update
status: deprecated
version: 1.0.0
last_updated: 2025-11-07
tags: [claude-code, configuration, chezmoi, biome]
priority: high
---

# Claude Code Configuration Update Guide

> **Deprecated**: References `06-templates/chezmoi/dot_claude/` templates that were removed in commit 41d95ab. Do not follow these instructions. See `docs/claude-cli-setup.md` instead.

## Overview

This guide walks through safely applying the updated global Claude Code CLI configuration that includes:

- **Node 24 compatibility** (not Node 20)
- **Biome v2.3+ formatting** (instead of Prettier)
- **Enhanced environment variables** for performance and behavior
- **Pre-configured agents** for specialized tasks
- **Slash commands** for autonomous workflows
- **Global hooks** for auto-formatting and git integration
- **MCP servers** for enhanced capabilities

## Safety First

This configuration update is designed to be **safe and non-destructive**:

- ✅ Templates are managed via chezmoi (version controlled)
- ✅ Preview changes before applying with `chezmoi diff`
- ✅ Existing project-specific `.claude/` configs remain independent
- ✅ All changes can be rolled back via git
- ✅ Fish shell remains functional even if Claude config fails

## Prerequisites

Verify your environment before applying:

```bash
# Check Node version (should be 24.x)
mise current | grep node

# Check Biome is installed
which biome && biome --version

# Check chezmoi is working
chezmoi status

# Verify Claude CLI is installed
claude --version
```

Expected output:
- Node: `node 24.11.0` (or similar 24.x version)
- Biome: `Version: 2.3.2` (or higher)
- Claude: `2.0.34` (or higher)

## Step 1: Preview Changes

**IMPORTANT: Always preview before applying!**

```bash
# See what would change
chezmoi diff

# Specific to Claude configuration
chezmoi diff ~/.claude
chezmoi diff ~/.config/fish/conf.d/10-claude.fish
```

Review the output carefully. You should see:
- New files in `~/.claude/` directory
- Updates to `~/.config/fish/conf.d/10-claude.fish`
- No unexpected changes to other files

## Step 2: Backup Current Configuration

Create a safety backup:

```bash
# Backup current Claude config (if exists)
if [ -d ~/.claude ]; then
    cp -r ~/.claude ~/.claude.backup-$(date +%Y%m%d)
fi

# Backup Fish config
cp ~/.config/fish/conf.d/10-claude.fish \
   ~/.config/fish/conf.d/10-claude.fish.backup-$(date +%Y%m%d)
```

## Step 3: Apply Configuration

Apply the changes in stages:

### Stage 1: Apply Fish Configuration Only

```bash
# Apply just the Fish shell config
chezmoi apply ~/.config/fish/conf.d/10-claude.fish

# Test that Fish still works
fish -c "echo 'Fish shell OK'"

# Test that Claude command still works
fish -c "claude --version"
```

If this fails, restore backup:
```bash
cp ~/.config/fish/conf.d/10-claude.fish.backup-$(date +%Y%m%d) \
   ~/.config/fish/conf.d/10-claude.fish
```

### Stage 2: Apply Global Claude Configuration

```bash
# Apply Claude global config
chezmoi apply ~/.claude/

# Verify files were created
ls -la ~/.claude/
ls -la ~/.claude/commands/
ls -la ~/.claude/agents/
```

### Stage 3: Verify Environment Variables

Start a new Fish shell and verify:

```bash
# Start new shell to pick up changes
exec fish

# Check key variables are set
echo $BASH_DEFAULT_TIMEOUT_MS      # Should be 600000
echo $CLAUDE_BASH_NO_LOGIN         # Should be 1
echo $USE_BUILTIN_RIPGREP          # Should be 1
echo $DISABLE_TELEMETRY            # Should be true
```

## Step 4: Test Functionality

### Test Basic Commands

```bash
# Test basic Claude commands
cc --version              # Should work
ccc --help               # Should work
ccp --help               # Should work

# Test new commands
ccm --help               # Multi-directory support
cco --help               # Opus model
```

### Test Hooks (Optional)

Create a test file to verify auto-formatting:

```bash
cd /tmp
mkdir claude-config-test
cd claude-config-test

# Create a poorly formatted TypeScript file
cat > test.ts << 'EOF'
const foo={bar:1,baz:2};
function hello(  name  :  string  )  {
return `Hello ${name}`;
}
EOF

# Start Claude and ask it to write this file
# (This should trigger the Biome formatting hook)
```

### Test Agents (Optional)

```bash
# Test a simple agent invocation
claude "@explorer what is the structure of this project?"
```

### Test Slash Commands (Optional)

```bash
# Test a slash command
claude /research:investigate "how do MCP servers work?"
```

## Step 5: Verify Integration with Existing Projects

Test with an existing project that has `.claude/` config:

```bash
cd ~/path/to/existing/project

# If project has .claude/config.json, verify it still works
claude "describe this project"

# The project-specific config should take precedence
# while global config provides defaults
```

## Rollback Procedure

If anything goes wrong, restore from backups:

```bash
# Restore Fish config
cp ~/.config/fish/conf.d/10-claude.fish.backup-$(date +%Y%m%d) \
   ~/.config/fish/conf.d/10-claude.fish

# Restore Claude config (if needed)
rm -rf ~/.claude
cp -r ~/.claude.backup-$(date +%Y%m%d) ~/.claude

# Restart shell
exec fish
```

## Common Issues and Solutions

### Issue: Fish Shell Doesn't Load

**Symptoms**: Error messages when starting Fish shell

**Solution**:
```bash
# Check Fish config syntax
fish -n ~/.config/fish/conf.d/10-claude.fish

# If syntax errors, restore backup
cp ~/.config/fish/conf.d/10-claude.fish.backup-$(date +%Y%m%d) \
   ~/.config/fish/conf.d/10-claude.fish
```

### Issue: Claude Command Not Found

**Symptoms**: `command not found: claude`

**Solution**:
```bash
# Verify ~/.local/bin is in PATH
echo $PATH | grep local/bin

# If not found, check Fish path config
cat ~/.config/fish/conf.d/04-paths.fish

# Verify Claude binary exists
ls -la ~/.local/bin/claude

# Reinstall if needed (native installer)
curl -fsSL https://claude.ai/install.sh | bash
```

### Issue: Environment Variables Not Set

**Symptoms**: Variables like `$BASH_DEFAULT_TIMEOUT_MS` are empty

**Solution**:
```bash
# Ensure you started a NEW Fish shell after applying
exec fish

# If still empty, check if config file is sourced
fish -c 'source ~/.config/fish/conf.d/10-claude.fish; echo $BASH_DEFAULT_TIMEOUT_MS'
```

### Issue: Biome Not Formatting

**Symptoms**: Auto-formatting doesn't happen

**Solution**:
```bash
# Verify Biome is installed and in PATH
which biome
biome --version

# Install Biome if needed (via npm or mise)
npm install -g @biomejs/biome
# OR
mise use -g npm:@biomejs/biome@2.3.4
```

### Issue: MCP Servers Fail to Start

**Symptoms**: Error messages about MCP servers

**Solution**:
```bash
# MCP servers require environment variables
# Set these in your shell or .envrc:

export GITHUB_TOKEN="your-token"
export BRAVE_API_KEY="your-key"
export POSTGRES_CONNECTION_STRING="your-connection"

# Or comment out MCP servers in ~/.claude/claude.json
```

## Verification Checklist

After applying all changes, verify:

- [ ] Fish shell starts without errors
- [ ] `claude --version` works
- [ ] Environment variables are set (`echo $BASH_DEFAULT_TIMEOUT_MS`)
- [ ] All command aliases work (`cc`, `ccc`, `ccp`, `ccm`, `cco`)
- [ ] Global config exists (`ls ~/.claude/`)
- [ ] Biome formatting available (`which biome`)
- [ ] Project-specific configs still work
- [ ] No broken shell scripts

## Post-Update

### Update Other Machines

Once verified on one machine, apply to others:

```bash
# Commit the chezmoi templates
git add 06-templates/chezmoi/dot_claude/
git add 06-templates/chezmoi/dot_config/fish/conf.d/10-claude.fish.tmpl
git commit -m "feat(claude): update global config with Biome and Node 24 support"
git push

# On other machines
cd ~/Development/personal/system-setup-update
git pull
chezmoi apply
```

### Keep Configuration Updated

```bash
# Check for Claude CLI updates regularly
claude_check_updates

# Update when available (native installer)
claude update
```

## Configuration Customization

### Add Custom Slash Commands

```bash
# Edit template
chezmoi edit ~/.claude/commands/dev/my-command.md

# Apply
chezmoi apply
```

### Add Custom Agent

```bash
# Edit template
chezmoi edit ~/.claude/agents/my-agent.md

# Apply
chezmoi apply
```

### Modify Hooks

```bash
# Edit settings template
chezmoi edit ~/.claude/settings.json

# Apply
chezmoi apply
```

## Architecture Notes

### Why Biome Instead of Prettier?

- **Performance**: Biome is 25x faster than Prettier
- **All-in-one**: Combines formatting and linting
- **Better defaults**: Optimized for modern JavaScript/TypeScript
- **Node 24 compatibility**: Fully compatible with latest Node

### Why Node 24?

- **Latest LTS**: Long-term support
- **Performance**: V8 improvements
- **Security**: Latest security patches
- **Compatibility**: Required by modern tooling

### Configuration Hierarchy

1. **Project-specific** (`.claude/` in project): Highest priority
2. **Global** (`~/.claude/`): Default for all projects
3. **Environment variables**: Runtime overrides

## Support and Documentation

- [Claude CLI Setup Documentation](./claude-cli-setup.md)
- [Global Claude Context](../06-templates/chezmoi/dot_claude/CLAUDE.md)
- [Global Config README](../06-templates/chezmoi/dot_claude/README.md)
- [Official Claude Code Docs](https://docs.anthropic.com/en/docs/claude-code/overview)

## Summary

This configuration update provides:
- ✅ Modern tooling (Node 24, Biome 2.3+)
- ✅ Enhanced automation (hooks, agents, slash commands)
- ✅ Better performance (optimized timeouts, built-in ripgrep)
- ✅ Improved security (explicit allow/deny lists)
- ✅ Reproducibility (managed via chezmoi)

Follow this guide carefully to ensure a smooth, non-disruptive update.

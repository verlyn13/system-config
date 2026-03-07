---
title: Claude Code Configuration - Chezmoi Migration Guide
category: guide
component: claude-config-migration
status: deprecated
version: 1.0.0
last_updated: 2025-11-07
tags: [claude-code, chezmoi, migration, future]
priority: low
---

# Claude Code Configuration - Future Chezmoi Migration Guide

> **Deprecated**: The decision was made to manage `~/.claude/` directly (not via chezmoi) due to rapid CLI evolution. This doc is retained for historical reference only.

## Current State

**As of 2025-11-07**, Claude Code CLI configuration is managed **directly** in `~/.claude/` and **not** through chezmoi.

### Why Not Chezmoi Now?

1. **Rapid Evolution**: Claude Code CLI is actively evolving (v2.0.34 → v3.0+)
2. **Format Changes**: Configuration format/structure still stabilizing
3. **Complexity**: Managing through chezmoi adds testing overhead
4. **Flexibility**: Direct management allows quick adjustments during active development

### Current Management Pattern

```
~/.claude/                     # Direct management (NOT chezmoi)
├── settings.json              # Hand-edited
├── CLAUDE.md                  # Hand-edited
├── commands/                  # Direct copy from templates
└── agents/                    # Direct copy from templates

06-templates/chezmoi/dot_claude/   # Reference templates only
├── settings.json.tmpl         # NOT ACTIVE - for future use
├── CLAUDE.md                  # Source of truth (copy from here)
├── commands/                  # Source of truth (copy from here)
└── agents/                    # Source of truth (copy from here)
```

## When to Migrate to Chezmoi

### Trigger Conditions

Migrate when **ALL** of these are true:

1. ✅ Claude Code CLI reaches stable v3.0+ (or format stabilizes)
2. ✅ No configuration format changes in last 6 months
3. ✅ You have 2-4 hours for thorough testing
4. ✅ You have backup and rollback plan ready
5. ✅ Templates in `06-templates/chezmoi/dot_claude/` are updated and tested

## Migration Steps (Future)

### Pre-Migration Checklist

- [ ] Claude Code CLI version stable for 6+ months
- [ ] Current `~/.claude/` configuration working perfectly
- [ ] Templates in `06-templates/chezmoi/dot_claude/` updated
- [ ] Backup created: `cp -r ~/.claude ~/.claude.backup-$(date +%Y%m%d)`
- [ ] Test environment available
- [ ] Rollback plan documented

### Step 1: Update Templates

```bash
# 1. Copy current working config to templates
cd ~/Development/personal/system-setup-update

# 2. Update templates with current working versions
cp ~/.claude/settings.json 06-templates/chezmoi/dot_claude/settings.json.tmpl
cp ~/.claude/CLAUDE.md 06-templates/chezmoi/dot_claude/CLAUDE.md
cp -r ~/.claude/commands/* 06-templates/chezmoi/dot_claude/commands/
cp -r ~/.claude/agents/* 06-templates/chezmoi/dot_claude/agents/

# 3. Add chezmoi template variables where needed
# Edit templates to add {{ .chezmoi.homeDir }} etc.
```

### Step 2: Move to Chezmoi Source

```bash
# Copy templates to chezmoi source
cp -r 06-templates/chezmoi/dot_claude ~/.local/share/chezmoi/

# Verify structure
ls -la ~/.local/share/chezmoi/dot_claude/
```

### Step 3: Preview Changes

```bash
# See what chezmoi would change
chezmoi diff ~/.claude/

# Verify no unexpected changes
# Should show mainly template variable substitutions
```

### Step 4: Test Apply

```bash
# Backup current config one more time
cp -r ~/.claude ~/.claude.backup-pre-chezmoi

# Apply via chezmoi
chezmoi apply ~/.claude/

# Verify structure intact
ls -la ~/.claude/
```

### Step 5: Test Functionality

```bash
# Test basic commands
claude --version
claude "test command"

# Test slash commands
claude /dev:feature --help

# Test agents
claude "@architect what is a good architecture?"

# Verify settings applied
cat ~/.claude/settings.json | jq .
```

### Step 6: Update Documentation

```bash
# Update main README
# Change "Management: Direct" to "Management: Chezmoi"

# Update this file
# Change status from "draft" to "archived"
# Add completion date
```

### Rollback Procedure

If migration fails:

```bash
# Remove chezmoi-managed config
rm -rf ~/.claude

# Restore backup
cp -r ~/.claude.backup-pre-chezmoi ~/.claude

# Remove from chezmoi source
rm -rf ~/.local/share/chezmoi/dot_claude

# Restart shell
exec fish
```

## Template Variables (Future)

When migrating, add these chezmoi variables:

### settings.json.tmpl

```json
{
  "environment": {
    "AGENTIC_ENV_ROOT": "{{ .chezmoi.homeDir }}/.dotfiles",
    "AGENTIC_STATE_ROOT": "{{ .chezmoi.homeDir }}/.local/state/agentic"
  }
}
```

### claude.json.tmpl (if created)

```json
{
  "mcpServers": {
    "filesystem": {
      "args": [
        "{{ .chezmoi.homeDir }}",
        "{{ .chezmoi.homeDir }}/Development"
      ]
    }
  }
}
```

## Update Process (After Migration)

Once managed by chezmoi:

```bash
# Edit template
chezmoi edit ~/.claude/settings.json

# Preview changes
chezmoi diff

# Apply changes
chezmoi apply

# Commit to git
cd ~/Development/personal/system-setup-update
git add .local/share/chezmoi/dot_claude/
git commit -m "chore(claude): update configuration"
```

## Benefits After Migration

### Advantages

- ✅ Version controlled configuration
- ✅ Reproducible across machines
- ✅ Easy rollback via git
- ✅ Template variables for machine-specific values
- ✅ Single source of truth

### Tradeoffs

- ⚠️ More complex update process
- ⚠️ Requires chezmoi apply after edits
- ⚠️ Template syntax adds overhead
- ⚠️ Must understand chezmoi to modify

## Current Update Process (Direct Management)

Until migration:

```bash
# Edit directly
nano ~/.claude/settings.json
nano ~/.claude/CLAUDE.md

# Update templates as reference
cp ~/.claude/settings.json 06-templates/chezmoi/dot_claude/settings.json.tmpl
cp ~/.claude/CLAUDE.md 06-templates/chezmoi/dot_claude/CLAUDE.md

# Commit reference templates
cd ~/Development/personal/system-setup-update
git add 06-templates/chezmoi/dot_claude/
git commit -m "docs(claude): update reference templates"
```

## Migration Decision Matrix

| Scenario | Use Chezmoi? | Reason |
|----------|-------------|---------|
| Claude CLI changes monthly | ❌ No | Too unstable |
| Stable for 6+ months | ✅ Yes | Safe to automate |
| Single machine setup | ❌ No | Overhead not worth it |
| Multi-machine sync needed | ✅ Yes | Version control beneficial |
| Frequent config changes | ❌ No | Direct edit easier |
| Rare config changes | ✅ Yes | Reproducibility valuable |
| Learning chezmoi | ✅ Yes | Good practice |
| Time constrained | ❌ No | Use direct management |

## Status: Not Yet Migrated

**Current approach**: Direct management of `~/.claude/`
**Future approach**: Chezmoi-managed when stable
**Decision point**: Claude Code CLI v3.0+ or 6+ months stability

See `~/.claude/README.md` for current management documentation.

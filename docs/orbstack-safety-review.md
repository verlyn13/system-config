---
title: OrbStack Safety Review
category: reference
component: orbstack_safety
status: active
version: 1.0.0
last_updated: 2025-11-03
tags: [safety, review, orbstack]
priority: high
---

# OrbStack Configuration Safety Review

This document explains the safety review process for the OrbStack Fish shell configuration and the critical changes made to prevent breaking the shell environment.

## Executive Summary

**Status**: ✅ SAFE - Configuration revised to prevent conflicts
**Risk Level Before**: 🔴 HIGH - Would have broken existing docker commands
**Risk Level After**: 🟢 LOW - Only adds convenience aliases, no overrides

## Discovery Process

### Current System State

Investigation revealed that OrbStack is already installed and working:

```bash
# OrbStack version
$ orb version
Version: 2.0.3 (2000300)

# Docker is provided by OrbStack
$ ls -la /usr/local/bin/docker
lrwxr-xr-x@ 1 root wheel 53 Sep 25 19:37 /usr/local/bin/docker -> /Applications/OrbStack.app/Contents/MacOS/xbin/docker

# Multiple symlinks exist
$ which -a docker orb orbctl
/usr/local/bin/docker
/opt/homebrew/bin/docker-compose
/usr/local/bin/docker-compose
/opt/homebrew/bin/orb
/usr/local/bin/orb
/opt/homebrew/bin/orbctl
/usr/local/bin/orbctl
```

**Key Finding**: OrbStack automatically creates symlinks in both `/usr/local/bin` and `/opt/homebrew/bin`, making all commands immediately available without any PATH configuration needed.

## Critical Issues Found in Initial Configuration

### Issue 1: Function Overrides (CRITICAL)

**Problem**: The initial config defined Fish functions for `docker`, `docker-compose`, `orb`, and `orbctl`:

```fish
# DANGEROUS - DO NOT USE
function docker --description 'Docker CLI (via OrbStack)'
    __orbstack_exec docker $argv
end
```

**Why This is Dangerous**:
1. Fish functions take precedence over binaries in PATH
2. Overrides working native commands with wrapper functions
3. Any bugs in the wrapper break docker entirely
4. Adds unnecessary complexity and failure points
5. Would break existing workflows that expect native docker behavior

**Impact**: Would have completely broken docker commands if applied!

### Issue 2: Unnecessary PATH Manipulation

**Problem**: The initial config tried to add OrbStack paths to Fish PATH:

```fish
# UNNECESSARY - DO NOT USE
if test -d $ORBSTACK_BIN
    if not contains $ORBSTACK_BIN $PATH
        fish_add_path $ORBSTACK_BIN
    end
end
```

**Why This is Wrong**:
1. `/opt/homebrew/bin` is already in PATH (via Homebrew shellenv)
2. `/usr/local/bin` is already in PATH (macOS default)
3. Adding extra paths creates confusion about command resolution order
4. The binaries at `/Applications/OrbStack.app/Contents/MacOS/bin/` are just symlinks anyway

**Impact**: Confusing PATH order, potential for wrong binaries to be called

### Issue 3: Complex Wrapper Function

**Problem**: The `__orbstack_exec` function added unnecessary indirection:

```fish
# OVERENGINEERED - DO NOT USE
function __orbstack_exec --description 'Execute OrbStack CLI'
    set -l cmd $argv[1]
    set -e argv[1]
    # ... complex logic ...
end
```

**Why This is Bad**:
1. Adds latency to every command
2. Harder to debug when things go wrong
3. Obscures the actual command being run
4. No benefit over using native commands directly

## Safe Configuration Approach

### Principles

1. **Never override native commands**: Let docker, orb, orbctl work as installed
2. **No PATH manipulation**: Everything is already in PATH
3. **Only add convenience aliases**: Provide shortcuts with NEW names
4. **Keep it simple**: Direct calls to native commands, no wrappers
5. **Fail safely**: Check if commands exist before using them

### What the Safe Config Does

```fish
# Load completions (safe)
if test -f "$ORBSTACK_APP/Contents/Resources/completions/fish/orbctl.fish"
    source "$ORBSTACK_APP/Contents/Resources/completions/fish/orbctl.fish"
end

# Convenience alias with NEW name (safe)
function orbstart --description 'Start OrbStack'
    if type -q orb
        orb start $argv
    else
        echo "orb command not found. Install OrbStack: brew install --cask orbstack"
        return 127
    end
end
```

**Key Points**:
- Loads Fish completions from OrbStack bundle (safe)
- Defines NEW function names that don't conflict (`orbstart` not `orb`)
- Checks if command exists before calling it
- Calls native commands directly, no wrappers
- Fails gracefully with helpful error messages

### Commands Provided

**Safe aliases (new names, no conflicts)**:
- `orbstart`, `orbstop`, `orbrestart` - OrbStack lifecycle
- `orbopen` - Open GUI app
- `dps`, `dpsa`, `dimages`, `dclean` - Docker shortcuts
- `orbstack_status` - Diagnostic helper
- `orbstack_check_updates` - Update checker

**Native commands (unchanged, no overrides)**:
- `orb`, `orbctl` - OrbStack CLIs
- `docker`, `docker-compose` - Docker CLIs

## Compatibility Verification

### Checked Against Existing Configs

1. **16-supabase.fish**: Uses `docker ps` to check if Docker is running
   - ✅ Compatible - Native docker command still works

2. **20-functions.fish**: Lists `docker` in tool validation
   - ✅ Compatible - Native docker command still in PATH

3. **04-paths.fish**: Manages user bin paths
   - ✅ Compatible - No conflicts, no duplicate paths added

### Integration Points

The safe config integrates properly with:
- Homebrew shell environment (00-homebrew.fish)
- mise version management (01-mise.fish)
- direnv project environments (02-direnv.fish)
- PATH configuration (04-paths.fish)
- Supabase Docker requirements (16-supabase.fish)
- Shell utility functions (20-functions.fish)

## Testing Checklist

Before applying the configuration, verify:

- [ ] OrbStack is installed: `test -d /Applications/OrbStack.app`
- [ ] Native commands work: `which docker orb orbctl`
- [ ] Docker is provided by OrbStack: `ls -la /usr/local/bin/docker`
- [ ] No existing Fish function overrides: `type docker` should show path, not function
- [ ] New config doesn't define conflicting functions
- [ ] New config only adds convenience aliases

After applying the configuration:

- [ ] Native commands still work: `docker --version`, `orb version`
- [ ] New aliases work: `orbstart`, `dps`, etc.
- [ ] No errors loading Fish shell: `fish -c exit`
- [ ] Completions load: `orb <tab>` shows completions
- [ ] Status helper works: `orbstack_status`

## Discoverability for AI Agents

The configuration is designed to be discoverable:

1. **Clear naming**: Commands use obvious prefixes (`orb*` for OrbStack, `d*` for Docker shortcuts)
2. **Descriptions**: All functions have `--description` flag for `help` and completion
3. **Documentation**: Comprehensive docs in `docs/orbstack-setup.md`
4. **Status helper**: `orbstack_status` lists all available commands
5. **Context in CLAUDE.md**: AI agents can reference the command list

### Quick Reference for Agents

When working with OrbStack/Docker:
- Use `docker` directly for standard Docker operations
- Use `orb` directly for OrbStack management
- Use shortcuts for common tasks: `dps`, `dimages`, `orbstart`
- Use `orbstack_status` when troubleshooting
- Check docs: `docs/orbstack-setup.md`

## Rollback Plan

If any issues occur after applying:

```bash
# Remove the OrbStack config
rm ~/.config/fish/conf.d/17-orbstack.fish

# Restart shell
exec fish

# Verify native commands still work
docker --version
orb version
```

Native commands will continue to work since they were never overridden.

## Lessons Learned

1. **Always check existing state first**: OrbStack was already installed and working
2. **Don't override working commands**: Fish functions take precedence - use with caution
3. **Simplicity is safety**: Direct calls beat wrappers
4. **PATH is probably fine**: Check before adding to PATH
5. **Test with existing configs**: Verify no conflicts with other Fish configs
6. **Document native vs alias**: Make it clear what's an override vs convenience alias

## Approval

This configuration has been reviewed and is approved for deployment. It:
- ✅ Does not override any native commands
- ✅ Does not modify PATH unnecessarily
- ✅ Only adds convenience aliases with new names
- ✅ Fails gracefully when commands are missing
- ✅ Is compatible with existing Fish configurations
- ✅ Is discoverable for AI agents
- ✅ Includes comprehensive documentation

**Safe to apply**: `chezmoi apply`

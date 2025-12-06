---
title: "Project .envrc Migration Guide"
category: guides
component: direnv
status: active
version: "1.0.0"
last_updated: 2025-12-06
tags: [direnv, mise, environment, migration]
priority: high
---

# Project .envrc Migration Guide

This guide helps project agents update `.envrc` files to use the modern mise integration pattern.

## The Problem

Old `.envrc` files use `eval "$(mise activate bash)"` which:
- Creates shell hooks that conflict with direnv
- Causes MISE_SHELL to be set, which affects tool behavior
- Leads to PATH duplication and ordering issues

## The Solution

Replace `mise activate` with the `use mise` direnvrc helper, which:
- Uses `mise env -s bash` instead of activate (no hooks)
- Only activates when a mise config file exists
- Integrates cleanly with direnv's environment management

## Migration Steps

### 1. Find the Problem

Look for this pattern in your `.envrc`:

```bash
# OLD PATTERN - remove this:
eval "$(mise activate bash)"
```

### 2. Replace with New Pattern

```bash
# NEW PATTERN - use this:
use mise
```

### 3. Allow the Updated File

```bash
direnv allow
```

## Full .envrc Examples

### Minimal Project

```bash
# .envrc
use mise
```

### Standard Project (with local secrets)

```bash
# .envrc
use mise
source_env_if_exists .envrc.local
```

### Project with API Keys (gopass integration)

```bash
# .envrc
use mise

# API keys from gopass
export ANTHROPIC_API_KEY=$(gopass show anthropic/api-keys/project-name 2>/dev/null || echo "")
export OPENAI_API_KEY=$(gopass show openai/api-keys/project-name 2>/dev/null || echo "")

# Local overrides (gitignored)
source_env_if_exists .envrc.local
```

### Node.js Project

```bash
# .envrc
use mise
layout_node  # Adds node_modules/.bin to PATH
source_env_if_exists .envrc.local
```

### Python Project

```bash
# .envrc
use mise
layout python3  # Creates/activates .venv
source_env_if_exists .envrc.local
```

### Infrastructure/Terraform Project

```bash
# .envrc
use mise

# Terraform settings
export AWS_PROFILE="production"
export TF_VAR_environment="production"

# Secrets from gopass
export TF_VAR_db_password=$(gopass show infra/db/password 2>/dev/null || echo "")

source_env_if_exists .envrc.local
```

## Available Helpers

These functions are defined in `~/.config/direnv/direnvrc`:

| Helper | Purpose |
|--------|---------|
| `use mise` | Load mise tool versions from `.mise.toml` or `.tool-versions` |
| `dotenv` | Load `.env` file into environment |
| `dotenv_if_exists` | Load `.env` if it exists (no error if missing) |
| `source_env_if_exists` | Load `.envrc.local` for gitignored secrets |
| `layout_node` | Add `node_modules/.bin` to PATH |
| `layout python3` | Create and activate `.venv` |
| `use_project_name` | Set `PROJECT_NAME` from directory name |

## Verification

After updating `.envrc`:

```bash
# Check mise isn't activated (should be empty)
echo $MISE_SHELL

# Check node points to shims
which node
# Expected: ~/.local/share/mise/shims/node

# Check environment loads
cd out && cd -
# Should see: direnv: loading .envrc
```

## Common Issues

### "use: command not found"

Make sure `~/.config/direnv/direnvrc` exists with the `use_mise()` function.

### Environment not loading

Run `direnv allow` after modifying `.envrc`.

### Wrong tool version

Check that `.mise.toml` or `.tool-versions` exists in the project.

## Template for New Projects

Copy this as your starting `.envrc`:

```bash
# .envrc - Standard project environment
use mise
source_env_if_exists .envrc.local
```

And add `.envrc.local` to `.gitignore` for secrets.

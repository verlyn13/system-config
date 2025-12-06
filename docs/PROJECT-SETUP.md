---
title: Project-Level Setup Guide
category: guide
status: active
version: 1.0.0
last_updated: 2025-12-06
tags: [project, setup, configuration]
priority: high
---

# Project-Level Setup Guide

This guide explains how to configure projects to work with this system's tooling.

## Required Files

Every project should have these configuration files at the root:

### `.mise.toml` - Runtime Versions

```toml
[tools]
node = "24"           # Or your project's required version
# python = "3.12"     # If needed
# go = "latest"       # If needed

[tasks]
dev = "npm run dev"
test = "npm test"
build = "npm run build"
lint = "biome check ."
format = "biome format --write ."
```

### `.envrc` - Environment Variables

```bash
# Load mise-managed tool versions
use mise

# Project identification
export PROJECT_NAME="$(basename $PWD)"

# Load local secrets (gitignored)
source_env_if_exists .envrc.local
```

After creating `.envrc`, run:
```bash
direnv allow .
```

### `.envrc.local` - Local Secrets (Gitignored)

```bash
# API keys and secrets - DO NOT COMMIT
export API_KEY="your-key-here"
export DATABASE_URL="postgres://..."

# For Terraform projects
export TF_VAR_api_key="$(gopass show -o path/to/secret)"
```

## AI Assistant Configuration

### `.claude/settings.json` - Claude Code Project Settings

```json
{
  "permissions": {
    "allow": [
      "Bash(npm:*)",
      "Bash(biome:*)",
      "Bash(git:*)"
    ]
  }
}
```

### `CLAUDE.md` - Project Context

Create a `CLAUDE.md` at project root with:
- Project purpose and architecture
- Key commands (dev, test, build)
- Important file locations
- Project-specific conventions

### `.gemini/GEMINI.md` - Gemini Context

Similar to CLAUDE.md but for Gemini CLI.

## Code Quality

### `biome.json` - Formatting and Linting

```json
{
  "$schema": "https://biomejs.dev/schemas/2.0.0/schema.json",
  "organizeImports": { "enabled": true },
  "linter": { "enabled": true },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2
  }
}
```

**Important**: Use Biome, not Prettier. Run with:
```bash
biome check --apply .   # Lint and fix
biome format --write .  # Format only
```

## Git Configuration

### `.gitignore` - Standard Exclusions

```gitignore
# Dependencies
node_modules/

# Build
dist/
build/

# Environment
.env
.env.*
!.env.example
.envrc.local

# IDE
.idea/
.vscode/

# OS
.DS_Store

# Logs
*.log
```

## Directory Structure Convention

```
project/
├── .claude/           # Claude Code config
├── .gemini/           # Gemini CLI config
├── .envrc             # direnv (committed)
├── .envrc.local       # secrets (gitignored)
├── .mise.toml         # runtime versions
├── biome.json         # formatting/linting
├── CLAUDE.md          # AI context
├── src/               # source code
├── tests/             # test files
└── docs/              # documentation
```

## Quick Setup Script

Run this in a new project:

```bash
# Create mise config
cat > .mise.toml << 'EOF'
[tools]
node = "24"

[tasks]
dev = "npm run dev"
test = "npm test"
build = "npm run build"
EOF

# Create envrc
cat > .envrc << 'EOF'
use mise
export PROJECT_NAME="$(basename $PWD)"
source_env_if_exists .envrc.local
EOF

# Allow direnv
direnv allow .

# Initialize git if needed
git init 2>/dev/null || true

# Install dependencies
mise install
npm install
```

## Verification

After setup, verify with:

```bash
# Check mise
mise doctor

# Check direnv
direnv status

# Check tools are available
node --version
biome --version
```

## Integration with System Config

This project setup integrates with:

- **mise** (`~/.config/mise/config.toml`) - Global tool versions
- **direnv** (`~/.config/direnv/`) - Auto-loading environment
- **Fish shell** (`~/.config/fish/`) - Shell integration
- **Claude Code** (`~/.claude/`) - Global AI settings

For system-wide configuration, see: https://github.com/verlyn13/system-setup-update

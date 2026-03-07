---
title: Project-Level Setup Guide
category: guide
status: active
version: 2.0.0
last_updated: 2025-12-12
tags: [project, setup, configuration, mise, direnv, claude, biome]
priority: high
---

# Project-Level Setup Guide

This guide explains how to configure new projects to work with this system's tooling, shell environment, and AI assistants.

## Quick Start

Use the bootstrap script for new projects:

```bash
~/.local/share/chezmoi/workspace/scripts/init-project.sh /path/to/project
```

This creates all required configuration files and initializes the environment.

## Required Files

Every project should have these configuration files at the root:

### 1. `.mise.toml` - Runtime Versions & Tasks

```toml
[tools]
node = "24"              # Node 24 is the standard (via mise)
# python = "3.12"        # Uncomment if needed
# go = "latest"          # Uncomment if needed
# rust = "latest"        # Uncomment if needed

[tasks.dev]
run = "npm run dev"
description = "Start development server"

[tasks.test]
run = "npm test"
description = "Run test suite"

[tasks.build]
run = "npm run build"
description = "Build for production"

[tasks.lint]
run = "biome check ."
description = "Lint with Biome"

[tasks.format]
run = "biome format --write ."
description = "Format with Biome"

[tasks.clean]
run = "rm -rf dist node_modules"
description = "Clean build artifacts"
```

After creating, trust the config:
```bash
mise trust
mise install
```

### 2. `.envrc` - Environment Variables (direnv)

```bash
# Standard project .envrc pattern
# ================================

# Load mise-managed tool versions automatically
use mise

# Project identification
export PROJECT_NAME="$(basename $PWD)"
export PROJECT_ROOT="$PWD"

# Load local secrets (gitignored) - REQUIRED for API keys
source_env_if_exists .envrc.local

# Project-specific environment
# export NODE_ENV="development"
# export LOG_LEVEL="debug"
```

After creating `.envrc`, allow it:
```bash
direnv allow .
```

### 3. `.envrc.local` - Local Secrets (Gitignored)

```bash
# API keys and secrets - NEVER COMMIT THIS FILE
# =============================================

# API Keys (use gopass for secure retrieval)
export API_KEY="$(gopass show -o path/to/api-key)"
export DATABASE_URL="postgres://user:pass@localhost:5432/db"

# AI CLI tokens (if not using global config)
# export ANTHROPIC_API_KEY="$(gopass show -o anthropic/api-keys/opus)"
# export OPENAI_API_KEY="$(gopass show -o openai/api-key)"

# Terraform variables (for IaC projects)
# export TF_VAR_api_key="$(gopass show -o terraform/api-key)"
```

### 4. `biome.json` - Formatting and Linting

**Important**: Use Biome v2.3+, NOT Prettier.

```json
{
  "$schema": "https://biomejs.dev/schemas/2.0.6/schema.json",
  "vcs": {
    "enabled": true,
    "clientKind": "git",
    "useIgnoreFile": true
  },
  "organizeImports": {
    "enabled": true
  },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true
    }
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "single",
      "semicolons": "asNeeded"
    }
  }
}
```

Run Biome:
```bash
biome check --apply .   # Lint and auto-fix
biome format --write .  # Format only
biome check .           # Check without fixing
```

### 5. `.gitignore` - Standard Exclusions

```gitignore
# Dependencies
node_modules/
.venv/
vendor/

# Build outputs
dist/
build/
.next/
out/

# Environment (secrets)
.env
.env.*
!.env.example
.envrc.local

# mise local overrides
.mise.local.toml

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs and temp
*.log
tmp/
temp/
coverage/
.pytest_cache/
```

## MCP Server Configuration

### User-Level MCP Servers (Global)

User-level MCP servers are automatically available in all projects. They're managed centrally:

```bash
# Sync global MCP servers to all AI tools
~/Organizations/jefahnierocks/system-config/ai-tools/sync-to-tools.sh
```

**Available globally**: context7, github, memory, sequential-thinking, brave-search, firecrawl

These servers appear alongside any project-specific servers you configure.

### Project-Level MCP Servers

Each AI tool has a different mechanism for project-level MCP servers:

#### Claude Code CLI: `.mcp.json`

Create `.mcp.json` at project root (committed to git, shared with team):

```json
{
  "mcpServers": {
    "my-project-server": {
      "type": "stdio",
      "command": "tsx",
      "args": ["management/mcp-server.ts"],
      "env": {
        "NODE_ENV": "development"
      }
    }
  }
}
```

Claude Code auto-discovers this file and prompts for approval.

#### Cursor: `.cursor/mcp.json`

Create `.cursor/mcp.json` in project:

```json
{
  "mcpServers": {
    "my-project-server": {
      "command": "tsx",
      "args": ["management/mcp-server.ts"],
      "env": {
        "NODE_ENV": "development"
      }
    }
  }
}
```

#### Windsurf & Copilot CLI: direnv-Gated Wrappers

For tools that read from user-level config only, use wrapper scripts with direnv gating:

**1. Create wrapper scripts** (`scripts/mcp-wrappers/`):

```bash
#!/usr/bin/env bash
# scripts/mcp-wrappers/my-server-wrapper.sh

# Only start if project envrc sets the flag
if [ "$MY_PROJECT_MCP_ENABLED" != "true" ]; then
    exit 0
fi

cd /path/to/project
exec tsx management/mcp-server.ts
```

Make executable: `chmod +x scripts/mcp-wrappers/*.sh`

**2. Add flag to project `.envrc`**:

```bash
# .envrc
export MY_PROJECT_MCP_ENABLED=true
```

**3. Update user-level configs** to use wrappers:

`~/.codeium/windsurf/mcp_config.json`:
```json
{
  "mcpServers": {
    "my-project-server": {
      "command": "/path/to/project/scripts/mcp-wrappers/my-server-wrapper.sh",
      "args": []
    }
  }
}
```

`~/.copilot/mcp-config.json`:
```json
{
  "mcpServers": {
    "my-project-server": {
      "command": "/path/to/project/scripts/mcp-wrappers/my-server-wrapper.sh",
      "args": []
    }
  }
}
```

**How it works**:
- In the project directory: direnv sets `MY_PROJECT_MCP_ENABLED=true`, server starts
- In other directories: flag not set, wrapper exits gracefully (no tools appear)

#### Codex CLI: Project Config Override

Set `CODEX_CONFIG` in `.envrc` to use a project-specific config:

```bash
# .envrc
export CODEX_CONFIG="$PWD/.codex/config.toml"
```

### MCP Configuration Summary

| Tool | Project Config Location | Mechanism |
|------|------------------------|-----------|
| Claude Code CLI | `.mcp.json` | Auto-discovered |
| Cursor | `.cursor/mcp.json` | Project directory |
| Windsurf | User config + wrappers | direnv-gated |
| Copilot CLI | User config + wrappers | direnv-gated |
| Codex CLI | `.codex/config.toml` | CODEX_CONFIG env var |

## AI Assistant Configuration

### Claude Code (`.claude/` directory)

Create `.claude/settings.json` for project-specific Claude configuration:

```json
{
  "permissions": {
    "allow": [
      "Bash(npm:*)",
      "Bash(biome:*)",
      "Bash(git:*)",
      "Bash(mise:*)"
    ]
  }
}
```

For more permissive projects (extends global settings):

```json
{
  "permissions": {
    "allow": [
      "Bash(npm:*)",
      "Bash(pnpm:*)",
      "Bash(yarn:*)",
      "Bash(bun:*)",
      "Bash(biome:*)",
      "Bash(git:*)",
      "Bash(gh:*)",
      "Bash(mise:*)",
      "Bash(docker:*)",
      "Bash(docker-compose:*)",
      "Bash(pytest:*)",
      "Bash(cargo:*)",
      "Bash(go:*)"
    ],
    "deny": [
      "Read(**/.env)",
      "Read(**/.env.*)",
      "Read(**/.envrc.local)",
      "Write(**/.env)",
      "Write(**/.envrc.local)"
    ]
  }
}
```

### `CLAUDE.md` - Project Context for Claude

Create a `CLAUDE.md` at project root with:

```markdown
# Project Name

## Overview
Brief description of what this project does.

## Tech Stack
- Node.js 24 (via mise)
- TypeScript
- [Framework]
- [Database]

## Key Commands
- `mise run dev` - Start development
- `mise run test` - Run tests
- `mise run build` - Production build
- `biome check --apply .` - Lint and fix

## Directory Structure
- `src/` - Source code
- `tests/` - Test files
- `docs/` - Documentation

## Important Files
- `src/index.ts` - Entry point
- `src/config.ts` - Configuration

## Conventions
- Use Biome for formatting (NOT Prettier)
- Conventional commits required
- All functions need TypeScript types
```

### Codex CLI (`.codex/` or global)

Codex uses a single global config at `~/.codex/config.toml`. For project overrides, set in `.envrc`:

```bash
# In .envrc
export CODEX_SANDBOX="workspace-write"  # Or: off, workspace-read, full-auto
export CODEX_MODEL="gpt-4o"             # Or: o4-mini, o3
```

### Gemini CLI (`.gemini/GEMINI.md`)

Similar to CLAUDE.md but for Gemini context:

```markdown
# Project Context for Gemini

[Same structure as CLAUDE.md]
```

## TypeScript Configuration

### `tsconfig.json` - Strict Mode

```json
{
  "compilerOptions": {
    "target": "ES2024",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

## Git Hooks (Optional)

### Using Lefthook

Create `lefthook.yml`:

```yaml
pre-commit:
  parallel: true
  commands:
    biome:
      glob: "*.{js,ts,jsx,tsx,json}"
      run: biome check --apply {staged_files}
      stage_fixed: true

    types:
      glob: "*.{ts,tsx}"
      run: tsc --noEmit

commit-msg:
  commands:
    lint:
      run: |
        # Enforce conventional commits
        if ! grep -qE "^(feat|fix|docs|style|refactor|test|chore|perf|ci)(\(.+\))?: .+" "$1"; then
          echo "Error: Commit message must follow conventional commits format"
          exit 1
        fi
```

Install hooks:
```bash
lefthook install
```

## Complete Directory Structure

```
project/
├── .claude/               # Claude Code config
│   └── settings.json      # Project permissions
├── .cursor/               # Cursor config
│   └── mcp.json           # Cursor project MCP servers
├── .codex/                # Codex config (optional)
│   └── config.toml        # Project Codex config
├── .gemini/               # Gemini CLI config
│   └── GEMINI.md          # Gemini context
├── .mcp.json              # Claude Code project MCP servers
├── .envrc                 # direnv (committed)
├── .envrc.local           # secrets (gitignored)
├── .gitignore             # git exclusions
├── .mise.toml             # runtime versions + tasks
├── biome.json             # formatting/linting
├── lefthook.yml           # git hooks (optional)
├── tsconfig.json          # TypeScript config
├── package.json           # Node dependencies
├── CLAUDE.md              # AI context
├── README.md              # Project documentation
├── scripts/
│   └── mcp-wrappers/      # direnv-gated MCP wrappers (for Windsurf/Copilot)
├── src/                   # source code
├── tests/                 # test files
└── docs/                  # documentation
```

## Verification Checklist

After setup, verify with:

```bash
# Check mise is working
mise doctor
mise current

# Check direnv loaded
direnv status
echo $PROJECT_NAME

# Check tools are available
node --version    # Should show v24.x
biome --version   # Should work via npx or global

# Check git hooks (if using lefthook)
lefthook run pre-commit
```

## Integration with System Config

This project setup integrates with the global system configuration:

| Component | Global Location | Purpose |
|-----------|-----------------|---------|
| mise | `~/.config/mise/config.toml` | Global tool versions |
| direnv | `~/.config/direnv/` | Auto-loading environment |
| Fish shell | `~/.config/fish/conf.d/` | Shell integration |
| Claude Code | `~/.claude/` | Global AI settings & hooks |
| Codex | `~/.codex/config.toml` | Global Codex config |

## Troubleshooting

### direnv not loading

```bash
# Check if direnv is enabled
direnv status

# Re-allow the .envrc
direnv allow .

# Check for syntax errors
direnv edit
```

### mise tools not found

```bash
# Trust the config
mise trust

# Install tools
mise install

# Check PATH
echo $PATH | tr ':' '\n' | grep mise
```

### Biome not found

Biome should be a dev dependency or available via npx:

```bash
# Add as dev dependency
npm install -D @biomejs/biome

# Or use npx
npx biome check .
```

### Claude not recognizing project context

1. Ensure `CLAUDE.md` exists at project root
2. Check `.claude/settings.json` syntax is valid JSON
3. Restart Claude Code session

## Related Documentation

- [direnv Setup](./direnv-setup.md) - Detailed direnv configuration
- [Claude CLI Setup](./claude-cli-setup.md) - Claude Code configuration
- [Codex CLI Setup](./codex-cli-setup.md) - Codex configuration
- [System CLAUDE.md](../CLAUDE.md) - Global project context

---

Maintainer: System setup team
Last Reviewed: 2025-12-12

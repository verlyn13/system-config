# Claude Code Global Configuration

This directory contains global configuration for Claude Code CLI managed via chezmoi.

## Structure

```
~/.claude/                              # Active configuration (managed by chezmoi)
├── CLAUDE.md                           # Global development context
├── settings.json                       # Tool permissions, hooks, agents
├── claude.json                         # MCP servers configuration
├── commands/                           # Slash commands
│   ├── dev/
│   │   ├── feature.md                  # Feature development workflow
│   │   ├── pr-review.md                # Pull request review
│   │   ├── refactor.md                 # Safe refactoring
│   │   └── test-driven.md              # TDD workflow
│   ├── ops/
│   │   ├── debug.md                    # Debugging workflow
│   │   └── deploy.md                   # Deployment workflow
│   └── research/
│       └── investigate.md              # Technical investigation
└── agents/                             # Pre-configured agents
    ├── architect.md                    # System architecture (Opus)
    ├── security.md                     # Security analysis
    ├── tester.md                       # Test generation
    ├── docs.md                         # Documentation
    ├── reviewer.md                     # Code review
    └── explorer.md                     # Codebase exploration (Haiku)
```

## Features

### Hooks

Automatic commands that run at specific points:

- **SessionStart**: Show runtime versions via `mise current`
- **PostToolUse**: Auto-format files
  - JS/TS/JSON: Biome (NOT Prettier)
  - Python: ruff or black
  - Rust: rustfmt
  - Go: gofmt
  - Fish: fish_indent
  - Markdown: Biome
- **PreCompact**: Show git diff before compaction
- **SessionEnd**: Show final git status

### Agents

Pre-configured specialized agents:

```bash
# Use agents in conversations
claude "@architect design a microservices architecture"
claude "@security review this authentication code"
claude "@tester generate tests for this function"
claude "@docs write API documentation"
claude "@reviewer review this pull request"
claude "@explorer find all API endpoints"
```

### Slash Commands

Autonomous workflow templates:

```bash
# Development workflows
claude /dev:feature "Add user authentication"
claude /dev:pr-review "123"
claude /dev:refactor "UserService"
claude /dev:test-driven "calculateDiscount function"

# Operations workflows
claude /ops:debug "API returns 500 error"
claude /ops:deploy "staging"

# Research workflows
claude /research:investigate "best state management for React"
```

### Tool Permissions

Global permissions configured in `settings.json`:

**Allowed**:
- File operations: Read, Edit, MultiEdit, Write
- Search: Grep, Glob, LS
- Web: WebSearch, WebFetch
- Commands: git, gh, mise, docker, npm, pnpm, yarn, bun, node, biome
- Languages: python, cargo, go, make, terraform
- Utilities: curl, wget, jq, rg, fd, chezmoi, gopass

**Denied** (security):
- Reading secrets: .env files, .ssh, secrets/, *.pem, *.key
- Writing secrets: .env files, .ssh, secrets/
- Dangerous commands: rm -rf, sudo rm, dd, mkfs, shutdown, reboot
- Secret management: gopass rm/delete

### MCP Servers

Global MCP servers for enhanced capabilities:

- **filesystem**: Home directory and repos access
- **github**: GitHub API (requires GITHUB_TOKEN)
- **git**: Git operations
- **brave-search**: Web search (requires BRAVE_API_KEY)
- **postgres**: Database access (requires connection string)
- **docker**: Container management

## Configuration Management

### Apply Configuration

After editing templates in `06-templates/chezmoi/dot_claude/`:

```bash
chezmoi apply
```

This updates `~/.claude/` with your changes.

### Preview Changes

See what would change without applying:

```bash
chezmoi diff
```

### Edit Configuration

Edit the source templates:

```bash
# Edit global context
chezmoi edit ~/.claude/CLAUDE.md

# Edit settings
chezmoi edit ~/.claude/settings.json

# Edit MCP servers
chezmoi edit ~/.claude/claude.json

# Add new slash command
chezmoi edit ~/.claude/commands/dev/new-command.md
```

### Project-Specific Configuration

Projects can override global settings with local `.claude/` directories:

```json
// .claude/config.json
{
  "version": "1.0.0",
  "allowedTools": ["Read", "Grep", "Glob"],  // More restrictive
  "disallowedTools": ["Write"],              // Deny writes
  "customInstructions": {
    "projectType": "read-only"
  }
}
```

## Environment Variables

Set in `~/.config/fish/conf.d/10-claude.fish` (managed by chezmoi):

### Performance
- `BASH_DEFAULT_TIMEOUT_MS=600000` - 10 minute default timeout
- `BASH_MAX_TIMEOUT_MS=1800000` - 30 minute maximum
- `MCP_TIMEOUT=30000` - MCP server timeout
- `MCP_TOOL_TIMEOUT=120000` - MCP tool timeout

### Behavior
- `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=true` - Stay in project dir
- `USE_BUILTIN_RIPGREP=1` - Use built-in ripgrep
- `DISABLE_INTERLEAVED_THINKING=false` - Enable thinking mode

### Privacy
- `DISABLE_TELEMETRY=true` - No telemetry
- `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=true` - Minimal network

## Formatting Standards

This configuration enforces:

- **JavaScript/TypeScript**: Biome v2.3+ (NOT Prettier)
- **Python**: ruff (preferred) or black
- **Rust**: rustfmt
- **Go**: gofmt
- **Fish**: fish_indent
- **Markdown**: Biome

All formatting happens automatically via PostToolUse hooks.

## Node Version

Configuration assumes Node 24 (managed via mise):

```bash
mise use -g node@24
```

## Documentation

- [Claude CLI Setup](../../../../docs/claude-cli-setup.md)
- [Global Context](./CLAUDE.md)
- [Official Docs](https://docs.anthropic.com/en/docs/claude-code/overview)

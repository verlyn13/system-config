---
title: Gemini Cli
category: reference
component: gemini_cli
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---

# Gemini CLI Quick Reference

## Installation Status
- **Installed**: ✅ via Homebrew (`brew install gemini-cli`)
- **Version**: 0.6.1
- **Location**: `/opt/homebrew/bin/gemini`

## Configuration Files
- **Global Settings**: `~/.gemini/settings.json`
- **Global Context**: `~/.gemini/GEMINI.md`
- **Fish Config**: `~/.config/fish/conf.d/11-gemini.fish`
- **Project Settings**: `.gemini/settings.json` (per project)
- **Project Context**: `.gemini/GEMINI.md` (per project)

## API Key Management
The Gemini API key is stored securely in gopass:
```bash
# API key location in gopass
gemini/api-keys/development

# Load API key in Fish shell
gemini-load-key

# Key is auto-loaded on shell start if stored in gopass
# To view/update the key:
gopass show gemini/api-keys/development
gopass edit gemini/api-keys/development
```

## Command Aliases (Fish Shell)
| Alias | Command | Description |
|-------|---------|-------------|
| `gc` | `gemini` | Base Gemini CLI |
| `gcp` | `gemini -p` | Direct prompt mode |
| `gcm` | `gemini -m` | Model selection |
| `gcflash` | `gemini -m gemini-1.5-flash` | Fast model |
| `gcpro` | `gemini -m gemini-1.5-pro-latest` | Pro model |
| `gcclear` | `gemini /clear` | Clear conversation |
| `gcstats` | `gemini /stats` | Show token usage |
| `gctools` | `gemini /tools` | List available tools |
| `gcmemory` | `gemini /memory show` | Show context |
| `gcrefresh` | `gemini /memory refresh` | Reload context |

## Custom Functions
| Function | Description | Usage |
|----------|-------------|-------|
| `geminify` | Fix last command error | `geminify` |
| `gemini-smart` | Context-aware wrapper | `gemini-smart [prompt]` |
| `gemini-review` | Review code files | `gemini-review [files]` |
| `gemini-test` | Generate tests | `gemini-test <file>` |
| `gemini-explain` | Explain code | `gemini-explain <file>` |
| `gemini-commit` | Generate commit msg | `gemini-commit` |
| `gemini-init-project` | Initialize project | `gemini-init-project` |

## Models Available
- `gemini-2.5-pro` - Most capable model
- `gemini-2.5-flash` - Fast model with excellent price/performance (default)
- `gemini-2.5-flash-lite` - Even faster and more cost-efficient variant

## Project Setup
Initialize a new project with Gemini support:
```bash
cd your-project
gemini-init-project
```

This creates:
- `.gemini/GEMINI.md` - Project context for the AI
- `.gemini/settings.json` - Project-specific settings
- `.gemini/commands/` - Custom command directory

## Essential Commands
| Command | Description |
|---------|-------------|
| `/memory show` | Display full instructional context |
| `/memory refresh` | Reload context after editing |
| `/tools` | List all available tools |
| `/chat save <tag>` | Save conversation state |
| `/chat resume <tag>` | Resume saved conversation |
| `/settings` | Open configuration in editor |
| `/stats` | Show token usage and caching |
| `@path/to/file` | Include file content in prompt |
| `! <command>` | Execute shell command |
| `/quit` | Exit Gemini CLI |

## Security Configuration
The CLI is configured with Docker sandboxing for safe command execution:
```json
{
  "tools": {
    "sandbox": "docker",
    "allowed": [
      "run_shell_command(git)",
      "run_shell_command(npm)",
      "run_shell_command(mise)"
    ]
  }
}
```

## Token Caching
Using API key authentication enables automatic token caching:
- Reduces costs by caching system instructions and context
- Monitor savings with `/stats` command
- Cached tokens shown in statistics output

## MCP (Model Context Protocol) Integration
Configure custom tools via MCP servers in project settings:
```json
{
  "mcpServers": {
    "myServer": {
      "command": "python",
      "args": ["-m", "my_module.mcp_server"],
      "description": "Custom project tools"
    }
  }
}
```

## Tips
1. Use `gcflash` for quick, simple tasks to save tokens
2. Use `gcpro` for complex reasoning and code generation
3. Always store API keys in gopass, never in plain text
4. Create project-specific GEMINI.md files for better context
5. Use `/stats` regularly to monitor token usage
6. Leverage custom commands for repetitive tasks
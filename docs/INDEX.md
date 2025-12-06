---
title: Documentation Index
category: reference
component: index
status: active
version: 3.0.0
last_updated: 2025-12-06
tags: [navigation, docs]
priority: high
---

# Documentation Index

## CLI Tool Setup

| Tool | Guide | Purpose |
|------|-------|---------|
| Claude Code | [claude-cli-setup.md](claude-cli-setup.md) | AI coding assistant CLI |
| Codex | [codex-cli-setup.md](codex-cli-setup.md) | OpenAI Codex CLI |
| Copilot | [copilot-cli-setup.md](copilot-cli-setup.md) | GitHub Copilot CLI |
| Terraform | [terraform-cli-setup.md](terraform-cli-setup.md) | Infrastructure as code |
| Sentry | [sentry-cli-setup.md](sentry-cli-setup.md) | Error tracking CLI |
| Vercel | [vercel-cli-setup.md](vercel-cli-setup.md) | Deployment CLI |
| OrbStack | [orbstack-setup.md](orbstack-setup.md) | Docker/container management |
| direnv | [direnv-setup.md](direnv-setup.md) | Directory-based env vars |

## Shell & Terminal

| Guide | Purpose |
|-------|---------|
| [fish-vs-bash-reference.md](fish-vs-bash-reference.md) | Fish shell syntax reference |
| [modern-shell-setup-2025.md](modern-shell-setup-2025.md) | Modern shell configuration |
| [MODERN-SHELL-COMPLETE-GUIDE.md](MODERN-SHELL-COMPLETE-GUIDE.md) | Complete shell setup |
| [SHELL-CONFIG-SAFETY.md](SHELL-CONFIG-SAFETY.md) | Shell configuration safety |
| [iterm2-modern-setup.md](iterm2-modern-setup.md) | iTerm2 configuration |

## Configuration Guides

| Guide | Purpose |
|-------|---------|
| [guides/GOPASS-DEFINITIVE-GUIDE.md](guides/GOPASS-DEFINITIVE-GUIDE.md) | Password management with gopass |
| [guides/SECRETS-MANAGEMENT-GUIDE.md](guides/SECRETS-MANAGEMENT-GUIDE.md) | Secrets handling |
| [guides/MAINTENANCE-GUIDE.md](guides/MAINTENANCE-GUIDE.md) | System maintenance |
| [guides/ENVRC-MIGRATION-GUIDE.md](guides/ENVRC-MIGRATION-GUIDE.md) | direnv migration |

## Claude Code Configuration

| Guide | Purpose |
|-------|---------|
| [CLAUDE-CONFIG-UPDATE-GUIDE.md](CLAUDE-CONFIG-UPDATE-GUIDE.md) | Update configuration |
| [CLAUDE-CONFIG-SETUP-COMPLETE.md](CLAUDE-CONFIG-SETUP-COMPLETE.md) | Setup completion status |
| [CLAUDE-CONFIG-CHEZMOI-MIGRATION.md](CLAUDE-CONFIG-CHEZMOI-MIGRATION.md) | Future chezmoi migration |

## Document Standards

### Required Frontmatter
```yaml
---
title: Document Title
category: [setup|guide|reference]
status: [active|deprecated|draft]
version: X.Y.Z
last_updated: YYYY-MM-DD
tags: [tag1, tag2]
priority: [critical|high|medium|low]
---
```

### Categories
- `setup` - Installation and configuration
- `guide` - How-to documentation
- `reference` - Reference material

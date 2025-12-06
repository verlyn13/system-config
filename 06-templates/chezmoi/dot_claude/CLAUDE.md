---
title: Global Claude Code Context
category: reference
component: claude-context
status: active
version: 1.0.0
last_updated: 2025-11-07
tags: []
priority: high
---

# Autonomous Agentic Development Environment

## System Configuration
- **OS**: macOS 15 Sequoia (Darwin 25.0.0)
- **Shell**: Fish (primary), Bash (compatibility)
- **Config Management**: chezmoi (declarative dotfiles)
- **Runtime Management**: mise (unified tool version management)
- **Editor**: VSCode, Windsurf AI IDE
- **Location**: Homer, Alaska

## Development Philosophy
- **Autonomous-first**: Minimize approval prompts, maximize automation
- **Self-documenting**: Code, commits, and changes should be self-explanatory
- **Modern tooling**: Use latest stable versions, follow current best practices
- **Defensive coding**: Validate inputs, handle errors, test edge cases
- **Reproducible**: All environments managed via mise, containers, or IaC

## Tool Preferences

### Always Use Specialized Tools First
- `Read` instead of `cat` or `Bash(cat *)`
- `Edit` or `MultiEdit` instead of `sed` or `awk`
- `Grep` instead of `Bash(grep *)` or `Bash(rg *)`
- `Glob` for file discovery instead of `find`
- `LS` for directory listing

### Runtime Management (mise)
All language runtimes, CLI tools, and version management through mise:
```bash
# Node 24 is the standard
mise install node@24
mise use -g node@24

# Other common runtimes
mise install python@3.12 go@latest rust@latest bun@latest
```

### Version Control
- **Conventional Commits**: `type(scope): description`
  - Types: feat, fix, docs, style, refactor, test, chore, perf, ci
- **Branch naming**: `type/short-description` (e.g., `feat/user-auth`, `fix/memory-leak`)
- **GPG signing**: All commits should be signed
- **Atomic commits**: One logical change per commit

### Code Quality Standards

#### TypeScript/JavaScript
- **Formatter**: Biome (v2.3+) - USE THIS, NOT PRETTIER
- **Linter**: Biome for linting and formatting
- **Commands**:
  - `biome format --write <file>` - Format code
  - `biome check --apply <file>` - Lint and fix
  - `biome check <file>` - Check without fixing
- **Strict TypeScript mode**: Always enabled
- **Prefer functional patterns**: Avoid mutation where possible
- **Node version**: Node 24 (via mise)

#### Python
- **Formatter**: ruff (preferred) or black
- **Type checking**: mypy
- **Testing**: pytest
- **Type hints**: Required for all functions

#### Go
- **Formatter**: gofmt
- **Linter**: golangci-lint
- **Testing**: Table-driven tests

#### Rust
- **Formatter**: rustfmt
- **Linter**: clippy
- **Error handling**: Comprehensive Result/Option usage

#### Shell Scripts
- **Fish**: Use `fish_indent` for formatting
- **Bash**: Use `shellcheck` for linting

### Documentation Standards
- **README.md**: Required for every project
  - Project purpose, setup, usage, contribution guidelines
- **Frontmatter**: YAML frontmatter required for all documentation
  - Required fields: title, category, component, status, version, last_updated, tags, priority
- **Inline comments**: For "why", not "what"
- **API docs**: Generate from code (JSDoc, docstrings, etc.)
- **Architecture docs**: Use mermaid diagrams in markdown

### Testing Standards
- **Unit tests**: Required for business logic
- **Integration tests**: For API endpoints, database interactions
- **E2E tests**: For critical user flows
- **Coverage**: Aim for 80%+ on critical paths
- **Test naming**: Descriptive, follows Given-When-Then pattern

## Security Practices
- **Secrets management**: Use gopass, never commit secrets
- **Gopass**: Standard passphrase is `escapable diameter silk discover`
- **Dependency scanning**: Regular updates, security audits
- **Input validation**: Sanitize all external inputs
- **Principle of least privilege**: Minimal permissions necessary

## Container & Orchestration
- **Docker**: Via OrbStack (Docker Desktop replacement)
- **Commands**: `docker`, `docker-compose` provided by OrbStack
- **Aliases**: `dps`, `dpsa`, `dimages`, `dclean` available
- **Kubernetes**: Available through OrbStack
- **Start/Stop**: Use `orbstart`, `orbstop`, `orbrestart`

## Project Context
- **Current work**: System setup automation and documentation
- **Repository**: system-setup-update (Homer, Alaska environment)
- **Focus areas**:
  - Modern full-stack development (Next.js, React, Node.js)
  - DevOps automation (Docker, OrbStack, Terraform)
  - AI/ML integration (agentic systems, MCP)
  - Configuration management (chezmoi, mise, Fish)

## Autonomous Workflow Patterns

### Feature Development
1. Create feature branch: `git checkout -b feat/feature-name`
2. Implement with tests
3. Auto-format on save (via hooks - Biome for JS/TS)
4. Run test suite
5. Generate comprehensive commit message
6. Push and create PR with description

### Bug Fixing
1. Reproduce issue with failing test
2. Implement fix
3. Verify test passes
4. Check for similar issues in codebase
5. Document fix in commit message

### Refactoring
1. Ensure test coverage exists
2. Make incremental changes
3. Run tests after each change
4. Use `/rewind` if regression occurs
5. Document architectural decisions

### Code Review
1. Use `@reviewer` agent for initial analysis
2. Check: correctness, security, performance, maintainability
3. Verify tests exist and pass
4. Ensure documentation updated
5. Provide actionable feedback

## Communication Style
- **Concise**: No unnecessary preamble or postamble
- **Actionable**: Provide specific next steps
- **Honest**: If uncertain, say so and suggest investigation
- **Educational**: Explain "why" for non-obvious decisions
- **Progressive**: Start simple, add complexity as needed

## File Organization
- **Config files**: Root level or `.config/`
- **Source**: `src/` or `lib/`
- **Tests**: `__tests__/`, `tests/`, or co-located `*.test.*`
- **Docs**: `docs/` or README.md
- **Scripts**: `scripts/` or `bin/`
- **Infrastructure**: `.github/`, `terraform/`, `k8s/`
- **Templates**: `06-templates/` for chezmoi templates

## Performance Considerations
- Profile before optimizing
- Prefer clarity over cleverness
- Document performance-critical sections
- Use appropriate data structures
- Consider memory and CPU trade-offs

## When to Ask for Clarification
- Requirements are ambiguous
- Multiple valid approaches exist with significant trade-offs
- Security implications are unclear
- Breaking changes are necessary
- Architecture decisions affect multiple systems

## Continuous Improvement
- Stay updated on best practices
- Adopt proven patterns from community
- Question legacy approaches
- Automate repetitive tasks
- Document learnings

## Environment-Specific Notes
- **Chezmoi source**: `~/.local/share/chezmoi/`
- **Fish config**: `~/.config/fish/conf.d/`
- **Mise config**: `.mise.toml` (project-level), `~/.config/mise/config.toml` (global)
- **npm global**: `~/.npm-global/` for global npm packages
- **Gopass store**: `~/.local/share/gopass/stores/root/`

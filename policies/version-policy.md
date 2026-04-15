---
title: Version Management Policy
category: policy
component: versions
status: active
version: 1.0.0
last_updated: 2025-10-23
tags: [policy, compliance]
priority: medium
---


# Version Policy

> **Philosophy:** Learn and ship fast with "latest compatible" stacks while remaining reproducible and safe to upgrade.

## Core Principles

### 1. Separation of Concerns
- **Machine tools** (Homebrew, fish, mise, direnv, editors, OrbStack) are free to update anytime
- **Project versions** are the single source of truth, defined and enforced by:
  - `.mise.toml` for runtime versions
  - Lockfiles for dependencies (`pnpm-lock.yaml`, `uv.lock`, `Cargo.lock`, `go.sum`)
  - Gradle version catalogs and wrapper properties for Android

**If it isn't pinned in the repository, it doesn't exist.**

### 2. Two Rails Strategy

#### Stable Rail (main branch)
- **Runtimes:** LTS/stable versions
  - Node.js: 24 (LTS from October 2025)
  - Python: 3.13
  - Rust: stable channel
  - Go: 1.23.x
  - Java: Temurin 17 (for Android)
- **Dependencies:** Exact pins via lockfiles
- **Use for:** Production, teaching, publishing

#### Fast Rail (renovate branches)
- Tracks newest compatible versions
- Auto-updates via Renovate PRs
- Merges only when CI passes
- Use for: Early adoption, compatibility testing

---

## Tooling Stack

### Version Management
- **mise** manages all runtimes (.mise.toml)
- **direnv** loads project environments automatically
- **1Password CLI** provides secure credential management (never committed)

### Automation
- **Renovate** opens upgrade PRs with release notes and changelogs
- **GitHub Actions** validates all changes before merge
- **chezmoi** manages machine configurations (dotfiles)

---

## Update Cadence

### Scheduled Updates
- **Weekly:** Sunday 02:00 Alaska time (Renovate)
- **Security patches:** Auto-merged when CI passes
- **Major versions:** Grouped PRs, manual review required
- **Lockfile maintenance:** Weekly refresh

### Manual Updates
- Emergency security fixes: Immediate
- Breaking changes: After team discussion
- Experimental features: In feature branches only

---

## CI Requirements

All Renovate PRs must pass CI before merge:

| Language | Required Checks | Tools |
|----------|-----------------|-------|
| JavaScript | • Install with frozen lockfile<br>• Lint (if configured)<br>• Tests (if present)<br>• Type check (TypeScript)<br>• Build | pnpm/bun/npm |
| Python | • Sync with frozen lockfile<br>• Ruff lint/format<br>• Mypy (if configured)<br>• Pytest | uv |
| Go | • mod verify<br>• golangci-lint<br>• Tests with race detection<br>• Build | native |
| Rust | • Format check<br>• Clippy warnings<br>• Tests with --locked<br>• Release build | cargo |
| Android | • Wrapper validation<br>• assembleDebug<br>• Unit tests | Gradle |

---

## Language-Specific Standards

### JavaScript/TypeScript
```toml
# .mise.toml
[tools]
node = "24"  # LTS from Oct 2025
bun = "latest"
pnpm = "latest"
```
- Package manager: **pnpm** (primary), bun (alternative)
- Lockfile: `pnpm-lock.yaml` (always committed)
- Use `overrides` for problematic transitive dependencies
- `packageManager` field in package.json for Corepack

### Python
```toml
# .mise.toml
[tools]
python = "3.13"
uv = "latest"
```
- Package/environment manager: **uv**
- Lockfile: `uv.lock` (always committed)
- `pyproject.toml` must specify `requires-python = ">=3.13"`
- Virtual environments via `uv venv`

### Go
```toml
# .mise.toml
[tools]
go = "1.23"
```
- `go.mod` with `toolchain go1.23.x` directive
- Lockfile: `go.sum` (always committed)
- Use `go mod tidy` before commits

### Rust
```toml
# .mise.toml
[tools]
rust = "stable"
```
- `rust-toolchain.toml` for project overrides
- Lockfile: `Cargo.lock` (always committed)
- CI uses `--locked` flag

### Android/Gradle
```toml
# .mise.toml
[tools]
java = "temurin-17"
```
- Version catalog: `gradle/libs.versions.toml`
- Wrapper: `gradle-wrapper.properties`
- Use ARM64 system images locally (M3 optimization)

---

## Breaking Changes & Recovery

### Prevention
1. **Stabilization period:** 2 days for new releases (configurable)
2. **Test coverage:** Comprehensive CI before merge
3. **Gradual rollout:** Test in feature branches first

### Recovery Strategy
1. **Last Known Good (LKG) tags:** Auto-created on successful main builds
   - Format: `lkg-YYYY-MM-DD`
   - Usage: `git checkout lkg-2025-09-20`

2. **Rollback procedure:**
   ```bash
   # Option 1: Revert the PR
   git revert -m 1 <merge-commit>
   
   # Option 2: Reset to LKG
   git checkout lkg-YYYY-MM-DD
   git checkout -b hotfix/rollback-deps
   ```

3. **Issue tracking:** Create issue with:
   - Failing CI logs
   - Upstream issue references
   - Proposed fix timeline

---

## Project Templates

All new projects must include:

### Required Files
```
.
├── .mise.toml           # Runtime versions
├── .envrc               # direnv configuration
├── renovate.json        # Update automation
├── VERSION_POLICY.md    # This document
├── .github/
│   └── workflows/
│       └── ci.yml       # CI pipeline
└── [lockfiles]          # Language-specific locks
```

### Template Generator
Use the `new-project` fish function:
```fish
new-project node my-api      # Node.js project
new-project python ml-model  # Python project
new-project go cli-tool      # Go project
new-project rust wasm-lib    # Rust project
new-project android my-app   # Android project
```

---

## Changelog Management

### Automated
- **Renovate PRs** include upstream release notes
- **GitHub Releases** auto-generated from PR titles
- **Commit convention:** `deps:` prefix for dependency updates

### Manual (for releases)
- Maintain `CHANGELOG.md` for user-facing changes
- Use semantic versioning for libraries
- Tag releases: `v1.2.3`

---

## Experimental Workflows

For bleeding-edge testing:

```bash
# Create experimental branch
git checkout -b exp/latest-deps

# Update .mise.toml to latest
sed -i '' 's/"[0-9.]*"/"latest"/g' .mise.toml

# Upgrade all dependencies
uv lock --upgrade
pnpm update --latest
cargo update
go get -u ./...

# Test and iterate
```

---

## Security Protocol

### Automated Security Updates
- Renovate security patches: Auto-merge
- Dependabot alerts: Address within 48 hours
- CVSS score ≥ 7.0: Immediate action

### Manual Security Audits
- Monthly: `pnpm audit`, `uv audit`, `cargo audit`
- Quarterly: Full dependency review
- Annual: Security posture assessment

---

## Compliance & Deviations

### Standard Compliance
Projects adhering to this policy display:
```markdown
[![Version Policy](https://img.shields.io/badge/version-policy%20compliant-green)](./VERSION_POLICY.md)
```

### Approved Deviations
Document exceptions in a `DEVIATIONS.md` file:
- Rationale for deviation
- Scope (which components)
- Timeline for resolution
- Risk assessment

---

## Agent Interface

For AI/automation tools, expose version information:

### Version Endpoint
CI creates `versions.json` artifact:
```json
{
  "runtime": {
    "node": "24.0.0",
    "python": "3.13.0",
    "rust": "1.82.0"
  },
  "updated": "2025-09-20T02:00:00Z",
  "policy": "https://github.com/org/repo/blob/main/VERSION_POLICY.md"
}
```

### Structured Metadata
- `.mise.toml` for runtime versions
- `package.json#engines` for Node.js constraints
- `pyproject.toml#requires-python` for Python constraints
- Lockfiles for exact dependency resolution

---

## Questions?

- **Internal:** Create an issue in this repository
- **External:** See our public documentation
- **Security:** security@example.com

---

*Last updated: September 20, 2025*
*Policy version: 1.0.0*

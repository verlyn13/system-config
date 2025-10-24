---
title: Sentry Cli Setup
category: reference
component: sentry_cli_setup
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---


# Sentry CLI Setup

This document describes the installation and configuration of Sentry CLI in this development environment.

## Overview

- **Installation method**: npm global (`@sentry/cli`)
- **Current version**: Check with `sentry-cli --version`
- **Location**: `~/.npm-global/bin/sentry-cli`
- **Configuration**: Single Fish config managed via chezmoi
- **Documentation**: https://docs.sentry.io/cli/

## Installation

Sentry CLI is installed via npm and managed through chezmoi templates:

```bash
npm install -g @sentry/cli
```

### Automated Installation

The chezmoi template `run_once_14-install-sentry.sh` handles initial installation:

```bash
chezmoi apply
```

This script:
1. Checks if `sentry-cli` command exists
2. Installs `@sentry/cli` via npm if missing
3. Checks for available updates on each run
4. Provides installation location and version info

## Configuration

### Single Source of Truth

All Sentry CLI configuration is managed through:

**Template**: `06-templates/chezmoi/dot_config/fish/conf.d/14-sentry.fish.tmpl`
**Active config**: `~/.config/fish/conf.d/14-sentry.fish`

Apply changes with:

```bash
chezmoi apply
```

### Authentication

Sentry CLI supports multiple authentication methods. This system uses environment variables with gopass integration.

#### Option 1: Environment Variables (Recommended)

Set in your `.envrc` file:

```bash
export SENTRY_AUTH_TOKEN="your-auth-token"
export SENTRY_ORG="your-org-slug"
export SENTRY_PROJECT="your-project-slug"
```

#### Option 2: gopass Integration (Secure)

Store your auth token in gopass:

```bash
gopass insert sentry/auth-token
```

The Fish configuration automatically retrieves the token when needed:

```fish
# Default command to fetch token
SENTRY_AUTH_TOKEN_CMD="gopass show sentry/auth-token"
```

#### Option 3: Interactive Login

For initial setup:

```bash
sentry-cli login
```

This creates a `.sentryclirc` file in your home directory with credentials.

### Self-Hosted Sentry

If using a self-hosted Sentry instance, set:

```bash
export SENTRY_URL="https://sentry.your-domain.com"
```

## Commands

### Aliases and Functions

| Command | Description | Usage |
|---------|-------------|-------|
| `sentry` | Sentry CLI main command | `sentry --help` |
| `sentry-cli` | Explicit Sentry CLI command | `sentry-cli releases list` |
| `sentry-upload` | Upload source maps | `sentry-upload dist/` |
| `sentry-releases` | Manage releases | `sentry-releases new v1.0.0` |
| `sentry-info` | Show configuration | `sentry-info` |
| `sentry-login` | Authenticate | `sentry-login` |
| `sentry_check_updates` | Check for CLI updates | `sentry_check_updates` |
| `sentry_status` | Show installation status | `sentry_status` |

### Common Operations

#### Create a Release

```bash
# Create a new release
sentry-cli releases new "1.0.0"

# Associate commits with the release
sentry-cli releases set-commits "1.0.0" --auto

# Finalize the release
sentry-cli releases finalize "1.0.0"
```

#### Upload Source Maps

```bash
# Upload source maps for a release
sentry-cli sourcemaps upload \
  --release "1.0.0" \
  --org "your-org" \
  --project "your-project" \
  ./dist
```

#### Deploy Tracking

```bash
# Create a deploy
sentry-cli releases deploys "1.0.0" new -e production
```

#### Debug Info Upload (Native/Mobile)

```bash
# Upload debug symbols
sentry-cli upload-dif --org "your-org" --project "your-project" ./path/to/symbols
```

## Project-Specific Configuration

### Per-Project Setup with direnv

Create `.envrc` in your project root:

```bash
# .envrc
export SENTRY_ORG="my-company"
export SENTRY_PROJECT="my-app"
export SENTRY_AUTH_TOKEN="$(gopass show sentry/auth-token)"

# Optional: release version from git
export SENTRY_RELEASE="$(git describe --tags --always)"
```

### Configuration File

Alternatively, create `sentry.properties` in your project:

```properties
defaults.url=https://sentry.io/
defaults.org=my-company
defaults.project=my-app
auth.token=your-auth-token
```

Or `.sentryclirc`:

```ini
[auth]
token=your-auth-token

[defaults]
url=https://sentry.io/
org=my-company
project=my-app
```

## CI/CD Integration

### GitHub Actions

```yaml
- name: Install Sentry CLI
  run: npm install -g @sentry/cli

- name: Create Sentry Release
  env:
    SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
    SENTRY_ORG: my-company
    SENTRY_PROJECT: my-app
  run: |
    sentry-cli releases new "${{ github.sha }}"
    sentry-cli releases set-commits "${{ github.sha }}" --auto
    sentry-cli releases finalize "${{ github.sha }}"
```

### GitLab CI

```yaml
variables:
  SENTRY_ORG: my-company
  SENTRY_PROJECT: my-app

sentry_release:
  script:
    - npm install -g @sentry/cli
    - sentry-cli releases new "$CI_COMMIT_SHA"
    - sentry-cli releases set-commits "$CI_COMMIT_SHA" --auto
    - sentry-cli releases finalize "$CI_COMMIT_SHA"
```

## Version Management

### Check Current Version

```bash
sentry-cli --version
```

### Check for Updates

```bash
sentry_check_updates
```

### Update to Latest

```bash
npm update -g @sentry/cli
```

Or use the update script:

```bash
~/Development/personal/system-setup-update/scripts/update-sentry-cli.sh
```

### Pin Specific Version

```bash
npm install -g @sentry/cli@2.57.0
```

## Troubleshooting

### CLI Not Found After Installation

Check that npm global bin is in your PATH:

```bash
fish -c 'echo $PATH | tr " " "\n" | grep npm-global'
```

Should show: `~/.npm-global/bin`

If missing, check `~/.config/fish/conf.d/04-paths.fish`:

```fish
fish_add_path ~/.npm-global/bin
```

### Authentication Issues

Check authentication status:

```bash
sentry_status
```

Or directly:

```bash
sentry-cli info
```

If authentication fails:
1. Check `SENTRY_AUTH_TOKEN` is set: `echo $SENTRY_AUTH_TOKEN`
2. Verify gopass has the token: `gopass show sentry/auth-token`
3. Try interactive login: `sentry-cli login`

### Organization/Project Not Found

Ensure environment variables are set correctly:

```bash
echo $SENTRY_ORG
echo $SENTRY_PROJECT
```

Or pass them explicitly:

```bash
sentry-cli --org my-org --project my-project releases list
```

### Source Map Upload Failures

Common issues:
1. **Missing release**: Create release first with `sentry-cli releases new`
2. **Wrong paths**: Ensure source map paths match deployed URLs
3. **File format**: Verify source maps are valid JSON

Debug with verbose output:

```bash
sentry-cli --log-level=debug sourcemaps upload ./dist
```

## Best Practices

1. **Use Environment Variables**: Keep credentials out of version control
2. **Integrate with CI/CD**: Automate release creation and source map uploads
3. **Pin Versions in CI**: Use specific CLI version for reproducible builds
4. **Use Release Names**: Follow semantic versioning (e.g., `v1.2.3`)
5. **Associate Commits**: Link releases to commits for better debugging
6. **Clean Up Old Releases**: Periodically archive old releases to reduce clutter

## Additional Resources

- **Official Documentation**: https://docs.sentry.io/cli/
- **Installation Guide**: https://docs.sentry.io/cli/installation/
- **Configuration**: https://docs.sentry.io/cli/configuration/
- **Releases**: https://docs.sentry.io/cli/releases/
- **Source Maps**: https://docs.sentry.io/platforms/javascript/sourcemaps/
- **GitHub Repository**: https://github.com/getsentry/sentry-cli

## Related Files

- Fish config: `~/.config/fish/conf.d/14-sentry.fish`
- Installer: `~/.local/share/chezmoi/run_once_14-install-sentry.sh`
- Update script: `scripts/update-sentry-cli.sh`
- Template: `06-templates/chezmoi/dot_config/fish/conf.d/14-sentry.fish.tmpl`

---
title: Direnv Setup
category: reference
component: direnv_setup
status: active
version: 1.0.0
last_updated: 2025-11-20
tags: [direnv, environment, secrets, fish]
priority: high
---

# direnv Setup

This document describes how direnv is configured on this system for automatic environment variable loading and project isolation.

## Overview

- **Installation**: Homebrew (`brew install direnv`)
- **Version**: 2.37.1 (current)
- **Location**: `/opt/homebrew/bin/direnv`
- **Fish integration**: `~/.config/fish/conf.d/02-direnv.fish` (chezmoi-managed)
- **Config**: `~/.config/direnv/direnv.toml` (chezmoi-managed)
- **Helper functions**: `~/.config/direnv/direnvrc` (chezmoi-managed)

## Why direnv?

direnv provides automatic environment variable loading when entering/leaving directories:
- ✅ **Secret injection** - Load API tokens, credentials without committing to Git
- ✅ **Project isolation** - Each project gets its own environment
- ✅ **mise integration** - Automatic tool version switching per project
- ✅ **Zero friction** - Variables load/unload automatically on `cd`

## Configuration Files

### 1. Fish Shell Hook

**File**: `~/.config/fish/conf.d/02-direnv.fish`
**Template**: `06-templates/chezmoi/dot_config/fish/conf.d/02-direnv.fish.tmpl`

```fish
# Enable direnv hook in interactive shells only, with a safety self-test
if status is-interactive
    # Allow opt-out if troubleshooting
    if not set -q DIRENV_DISABLE
        if type -q direnv
            # Quick self-test: if export segfaults/fails, disable direnv for this session
            if not direnv export bash >/dev/null 2>/dev/null
                set -gx DIRENV_DISABLE 1
                echo "[direnv] Disabled automatically due to export failure. Investigate direnv install."
            else
                set -gx DIRENV_LOG_FORMAT ""
                direnv hook fish | source
            end
        end
    end
end
```

**Features**:
- Interactive shells only (avoids script interference)
- Self-test to detect crashes before hooking
- Opt-out via `DIRENV_DISABLE=1` environment variable
- Clean output (`DIRENV_LOG_FORMAT=""`)

### 2. direnv Configuration

**File**: `~/.config/direnv/direnv.toml`
**Template**: `06-templates/chezmoi/dot_config/direnv/direnv.toml.tmpl`

```toml
# direnv configuration (chezmoi-managed)
# Force direnv to use Homebrew bash instead of /bin/bash to avoid crashes on macOS Sequoia.
# See: shell-env-audit and diagnostics showing /bin/bash segfaulting during export.

bash_path = "/opt/homebrew/bin/bash"
```

**Why Homebrew bash?**
- Apple's `/bin/bash` crashes on macOS 26+ (Sequoia) during direnv export
- Homebrew's Bash is stable and actively maintained
- See: `07-reports/status/shell-env-audit-2025-09-30.md` for diagnostics

### 3. Helper Functions

**File**: `~/.config/direnv/direnvrc`
**Template**: `06-templates/chezmoi/dot_config/direnv/direnvrc.tmpl`

Contains custom direnv stdlib extensions (e.g., `use_mise()` function).

## Usage

### Basic Project Setup

1. **Create `.envrc` in your project**:
   ```bash
   cd your-project
   echo 'export PROJECT_ENV="development"' > .envrc
   direnv allow .   # Note: The dot is required!
   ```

2. **Add secrets** (never commit):
   ```bash
   echo 'export API_TOKEN="secret-value"' >> .envrc
   echo '.envrc' >> .gitignore
   direnv allow .   # Re-allow after modifying .envrc
   ```

3. **Test**:
   ```bash
   cd your-project   # direnv loads .envrc
   echo $API_TOKEN   # "secret-value"
   cd ..             # direnv unloads
   echo $API_TOKEN   # (empty)
   ```

### Integration with mise

For projects using mise for version management:

```bash
# .envrc
use mise
```

This automatically activates mise-managed tools when entering the directory.

### Advanced Pattern (mise + secrets)

```bash
# .envrc - Recommended pattern for most projects
use mise

# Project-specific environment
export PROJECT_NAME="my-project"
export ENVIRONMENT="development"

# Secrets (load from external source if available)
if [ -f .envrc.local ]; then
  source_env .envrc.local
fi
```

Then create `.envrc.local` (gitignored) for secrets:
```bash
# .envrc.local - Never commit this file
export DATABASE_URL="postgresql://..."
export API_KEY="sk-..."
```

### Terraform/Infrastructure Projects

For infrastructure-as-code projects (like `the-citadel`):

```bash
# .envrc
# HCP Terraform authentication
export TFE_TOKEN="your-terraform-cloud-token"

# Provider credentials (TF_VAR_* pattern)
export TF_VAR_github_token="ghp_..."
export TF_VAR_cloudflare_api_token="..."

# AWS/GCP (if not using OIDC)
# export AWS_ACCESS_KEY_ID="..."
# export AWS_SECRET_ACCESS_KEY="..."
```

See: `/Users/verlyn13/Development/the-nash-group/the-citadel/.envrc.template` for a complete example.

## Verification

### Check direnv is installed and configured

```bash
# Check installation
which direnv
direnv version

# Check Fish integration
fish -c 'type -q direnv && echo "✅ direnv configured" || echo "❌ direnv not configured"'

# Verify bash path
cat ~/.config/direnv/direnv.toml
```

### Test in a new project

```bash
cd /tmp
mkdir test-direnv
cd test-direnv
echo 'export TEST_VAR="it works"' > .envrc
direnv allow .
echo $TEST_VAR  # Should print: it works
cd ..
echo $TEST_VAR  # Should be empty
```

## Troubleshooting

### direnv not loading automatically

**Symptom**: `.envrc` files don't load when entering directories

**Solutions**:
1. Check Fish integration exists:
   ```bash
   ls -la ~/.config/fish/conf.d/02-direnv.fish
   ```

2. Verify direnv hook is loaded:
   ```fish
   fish -c 'functions | grep direnv'
   ```

3. Restart Fish shell:
   ```bash
   exec fish
   ```

### direnv crashes or segfaults

**Symptom**: Error messages about bash crashes

**Solution**: Ensure Homebrew bash is configured:
```bash
echo 'bash_path = "/opt/homebrew/bin/bash"' > ~/.config/direnv/direnv.toml
```

### .envrc changes not taking effect

**Symptom**: Modified `.envrc` not reloading

**Solutions**:
1. Re-allow the directory (note the dot!):
   ```bash
   direnv allow .
   ```

2. Force reload:
   ```bash
   direnv reload
   ```

3. Check for errors:
   ```bash
   direnv status
   ```

### `direnv allow` does nothing

**Symptom**: Running `direnv allow` (without arguments) shows no output and doesn't approve the `.envrc`

**Solution**: You must specify the directory, even if it's the current one:
```bash
# Wrong - does nothing
direnv allow

# Correct - approves .envrc in current directory
direnv allow .

# Also correct - explicit path
direnv allow /path/to/project
```

**Why**: direnv requires an explicit path argument for security - to prevent accidental approval of multiple directories.

### Opt-out of direnv for debugging

**Temporary** (current session only):
```fish
set -gx DIRENV_DISABLE 1
```

**Persistent** (add to Fish config):
```fish
echo 'set -gx DIRENV_DISABLE 1' >> ~/.config/fish/config.fish
```

## Security Best Practices

1. **Never commit `.envrc` with secrets**:
   ```bash
   echo '.envrc' >> .gitignore
   ```

2. **Use `.envrc.template` for documentation**:
   ```bash
   cp .envrc .envrc.template
   # Remove secrets from .envrc.template
   git add .envrc.template
   ```

3. **Separate public and private variables**:
   ```bash
   # .envrc (committed) - Public configuration
   use mise
   export PROJECT_NAME="my-project"
   source_env_if_exists .envrc.local

   # .envrc.local (gitignored) - Secrets only
   export DATABASE_PASSWORD="secret"
   ```

4. **Review direnv allow prompts**:
   - direnv requires explicit `direnv allow .` for new/modified `.envrc`
   - This prevents malicious `.envrc` from auto-executing

## Integration with This System

### Chezmoi Management

All direnv configuration is managed via chezmoi templates:

```
06-templates/chezmoi/
├── dot_config/fish/conf.d/02-direnv.fish.tmpl    # Fish hook
├── dot_config/direnv/direnv.toml.tmpl             # direnv config
└── dot_config/direnv/direnvrc.tmpl                # Helper functions
```

To apply changes:
```bash
chezmoi apply
```

### Load Order in Fish

The Fish configuration loads in this order:
1. `00-homebrew.fish` - Homebrew paths and environment
2. `01-mise.fish` - mise shims (if configured globally)
3. **`02-direnv.fish`** - direnv hook (project-specific overrides)
4. `03-starship.fish` - Prompt configuration
5. `04-paths.fish` - User binary paths
6. `10-claude.fish`, etc. - Tool-specific configurations

This ensures direnv can override mise and other environment settings on a per-project basis.

### Standard .envrc Pattern

The system uses a standard `.envrc` pattern across projects:

```bash
# .envrc - Standard pattern
# Load mise for version management
use mise

# Project metadata
export PROJECT_NAME="$(basename $PWD)"
export ENVIRONMENT="${ENVIRONMENT:-development}"

# Load local secrets if present
source_env_if_exists .envrc.local

# Tool-specific paths (if needed)
PATH_add bin
PATH_add scripts
```

Use `scripts/multirepo-align-env.sh` to standardize `.envrc` across multiple repositories.

## Related Documentation

- **Fish Shell Configuration**: `02-configuration/terminals/iterm2-config.md`
- **mise Integration**: `01-setup/05-mise.md` (when documented)
- **Secrets Management**: `docs/guides/SECRETS-MANAGEMENT-GUIDE.md`
- **Infrastructure Project**: `/Users/verlyn13/Development/the-nash-group/the-citadel/`
  - Setup guide: `docs/SINGLE-PLAYER-EMPIRE-MANAGEMENT.md`
  - Template: `.envrc.template`

## Update Management

direnv is installed via Homebrew:
```bash
brew upgrade direnv
```

No additional configuration needed - chezmoi templates remain compatible.

---

**Maintainer**: System setup team
**Last Reviewed**: 2025-11-20

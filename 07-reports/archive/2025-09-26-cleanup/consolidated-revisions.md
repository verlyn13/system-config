---
title: Consolidated Revisions
category: reference
component: consolidated_revisions
status: draft
version: 1.0.0
last_updated: 2025-09-26
tags: []
priority: medium
---

# Consolidated Revisions - Critical Updates & Fixes
## September 2025 - M3 Max Development Environment

---

## Executive Summary

These revisions address critical issues discovered in the initial setup and optimize the development workflow based on real-world usage patterns. The changes establish **Bun as the primary JavaScript runtime** while maintaining Node.js LTS for compatibility, fix Android SDK paths, improve security configurations, and streamline CI/CD workflows.

---

## 🔴 Critical Fixes

### 1. Fish Shell - Homebrew Initialization
**Problem:** Incorrect syntax for Homebrew initialization in Fish shell  
**Fix:** Use command substitution with `eval`

```fish
# ❌ WRONG
/opt/homebrew/bin/brew shellenv | source

# ✅ CORRECT
eval (/opt/homebrew/bin/brew shellenv)
```

### 2. Android SDK Paths
**Problem:** Legacy `tools` directory no longer exists in modern Android SDK  
**Fix:** Use modern `cmdline-tools` layout

```bash
# ❌ OLD (broken)
export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$PATH"

# ✅ NEW (correct)
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
```

### 3. mise Trust Configuration
**Problem:** Constant prompts for mise configuration trust  
**Fix:** Set trusted paths environment variable

```fish
# Add to config.fish
set -gx MISE_TRUSTED_CONFIG_PATHS "$HOME" "$HOME/Development"
```

### 4. Spotlight Exclusions
**Problem:** `mdutil -i off` is fragile and doesn't persist  
**Fix:** Use sentinel files that Spotlight respects

```bash
# ❌ UNRELIABLE
sudo mdutil -i off ~/Development

# ✅ PERSISTENT
mkdir -p "$HOME/Development"
touch "$HOME/Development/.metadata_never_index"
```

### 5. SSH Agent Forwarding
**Problem:** Global `ForwardAgent yes` is a security risk  
**Fix:** Enable only per-host where needed

```sshconfig
# ❌ DANGEROUS (in Host *)
ForwardAgent yes

# ✅ SECURE (only for bastion)
Host bastion
  ForwardAgent yes
  
Host web1
  ProxyJump bastion
  # No ForwardAgent here
```

---

## 🔄 Architecture Changes

### JavaScript Runtime Strategy

**New Hierarchy:**
1. **Bun** - Primary runtime and package manager
2. **Node.js 24 LTS** - Compatibility rail
3. **pnpm** - Only via Corepack when forced by platform

```toml
# Global mise config
[tools]
node = "24"       # Compatibility
bun = "latest"    # Primary
# NO global pnpm
```

```json
// package.json
{
  "packageManager": "bun@1",
  "scripts": {
    "dev": "bun --hot src/index.ts",
    "build": "bun build src/index.ts --outdir dist",
    "test": "bun test"
  }
}
```

### CI/CD Standardization

**All tools via mise** - No more ad-hoc installers:

```yaml
# ❌ OLD - Multiple tool installers
- run: curl -fsSL https://bun.sh/install | bash
- run: curl -LsSf https://astral.sh/uv/install.sh | sh

# ✅ NEW - Single source of truth
- run: |
    curl https://mise.run | sh
    mise install
```

### Secret Management Improvements

**Safer gopass templating** with fallback:

```fish
# ❌ Can fail if secret doesn't exist
set -gx TOKEN "{{ gopass "dev/token" }}"

# ✅ Safe with fallback
{{- with secret "gopass:dev/token" -}}
set -gx TOKEN "{{ .Value }}"
{{- end }}
```

---

## 📁 File Updates Required

### 1. `~/.config/fish/config.fish`
```fish
# Minimal config - features in conf.d/
eval (/opt/homebrew/bin/brew shellenv)
mise activate fish | source
direnv hook fish | source
starship init fish | source
zoxide init fish | source
fzf --fish | source
set -gx MISE_TRUSTED_CONFIG_PATHS "$HOME" "$HOME/Development"
```

### 2. `~/.config/mise/config.toml`
```toml
[tools]
node = "24"
bun = "latest"
python = "3.13"
uv = "latest"
go = "latest"
rust = "stable"
java = "temurin-17"
# r = "latest"  # Uncomment if needed

[env]
BUN_INSTALL = "~/.bun"
GOPATH = "~/go"
EDITOR = "nvim"
```

### 3. Project `.envrc` Template
```bash
use mise
PATH_add bin
PATH_add node_modules/.bin
use dotenv_if_exists .env.local

if command -v gopass >/dev/null 2>&1; then
  export DATABASE_URL="$(gopass show dev/database_url 2>/dev/null || true)"
fi

# Modern Android paths
export ANDROID_HOME="$HOME/Library/Android/sdk"
PATH_add "$ANDROID_HOME/emulator"
PATH_add "$ANDROID_HOME/platform-tools"
PATH_add "$ANDROID_HOME/cmdline-tools/latest/bin"
```

### 4. SSH Configuration
```sshconfig
# ~/.ssh/config
Host *
  ServerAliveInterval 30
  ServerAliveCountMax 60
  TCPKeepAlive yes
  Compression yes
  AddKeysToAgent yes
  IdentitiesOnly yes
  PreferredAuthentications publickey
  # NO global ForwardAgent

Include ~/.ssh/conf.d/*.conf
```

### 5. Git Commit Signing
```bash
# ~/.ssh/allowed_signers
personal@example.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...
work@company.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...
```

---

## 🆕 New Features

### Vercel Deployment Support
```json
// vercel.json
{
  "installCommand": "bun install --frozen-lockfile",
  "buildCommand": "bun run build",
  "env": { "BUN_INSTALL_GLOBAL": "1" }
}
```

### CI pnpm Fallback Toggle
```yaml
# In GitHub Actions
- name: Install deps
  run: |
    if [ "${{ vars.BUN_FALLBACK }}" = "1" ]; then
      corepack enable && corepack prepare pnpm@9 --activate
      mise exec -- pnpm install --frozen-lockfile
    else
      mise exec -- bun install --frozen-lockfile
    fi
```

### Optional R Support
```toml
# In .mise.toml (when needed)
[tools]
r = "latest"
```

---

## 🚀 Migration Guide

### For Existing Setup

1. **Update Fish config:**
   ```fish
   chezmoi edit ~/.config/fish/config.fish
   # Fix brew shellenv line
   # Add MISE_TRUSTED_CONFIG_PATHS
   chezmoi apply
   ```

2. **Update mise config:**
   ```fish
   chezmoi edit ~/.config/mise/config.toml
   # Remove pnpm
   # Add java = "temurin-17"
   chezmoi apply
   ```

3. **Fix Android paths in projects:**
   ```bash
   # In each Android project's .envrc
   # Replace /tools/bin with /cmdline-tools/latest/bin
   direnv allow
   ```

4. **Update SSH config:**
   ```bash
   chezmoi edit ~/.ssh/config
   # Remove global ForwardAgent
   chezmoi apply
   ```

5. **Switch to Bun:**
   ```bash
   # In Node projects
   rm -rf node_modules package-lock.json yarn.lock pnpm-lock.yaml
   echo 'packageManager: "bun@1"' >> package.json
   bun install
   ```

### For New Projects

Use updated templates:
```fish
new-project node my-app  # Uses Bun by default
cd my-app
cat package.json         # Should show packageManager: "bun@1"
```

---

## 🔍 Verification

Run these commands to verify all fixes are applied:

```fish
# Check Fish shell
echo $PATH | grep homebrew  # Should show /opt/homebrew paths

# Check mise trust
echo $MISE_TRUSTED_CONFIG_PATHS  # Should show your paths

# Check Android (in Android project)
which adb  # Should resolve
echo $ANDROID_HOME  # Should be set

# Check Bun
bun --version  # Should work globally
which bun      # Should be in ~/.bun/bin

# Check SSH
grep ForwardAgent ~/.ssh/config  # Should NOT be in Host *

# Check Spotlight exclusions
ls -la ~/Development/.metadata_never_index  # Should exist
```

---

## 📋 Summary

These revisions transform the setup from "theoretically correct" to "production-ready" by:

1. **Fixing critical path and initialization issues** that would break the environment
2. **Establishing Bun as primary** while maintaining compatibility rails
3. **Improving security** by scoping agent forwarding and secret access
4. **Streamlining CI/CD** with single tool installation method
5. **Adding platform support** for Vercel and other deployment targets

The revised architecture maintains the "thin machine, thick projects" philosophy while ensuring everything actually works in practice.

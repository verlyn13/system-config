---
title: 07 Infisical
category: setup
component: 07_infisical
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: [installation, setup]
applies_to:
  - os: macos
    versions: ["14.0+", "15.0+"]
  - arch: ["arm64", "x86_64"]
priority: medium
---


# Infisical CLI Installation and Configuration

> **Self-hosted secrets management for Trinity platform**
>
> Infisical provides unified secrets management across three business entities (Personal, Litecky, Happy) with fine-grained access control and automation capabilities.

## 🎯 Quick Install

```bash
brew install infisical
```

## 📋 Prerequisites

- ✅ Homebrew installed (see [01-homebrew.md](01-homebrew.md))
- ✅ Access to self-hosted Infisical instance at `infisical.jefahnierocks.com`
- ✅ User account created on Infisical instance
- ✅ Internet connection

## 🏗️ Architecture

### Self-Hosted Instance
- **URL**: `https://infisical.jefahnierocks.com`
- **Location**: Hetzner Ubuntu server
- **Backend**: `infisical/infisical:latest-postgres`
- **Database**: PostgreSQL 14-alpine
- **Access**: Via Cloudflare tunnel
- **Status**: ✅ Operational

### Trinity Contexts
The system supports three organizational contexts:
1. **personal** - Family budget & personal tech
2. **litecky** - Ahnie's editing business
3. **happy** - Verlyn's software business

## 🚀 Installation Steps

### Step 1: Install Infisical CLI

```bash
# Install via Homebrew
brew install infisical

# Verify installation
infisical --version
```

### Step 2: Configure Environment

The Fish shell configuration (`~/.config/fish/conf.d/41-infisical.fish`) automatically sets:

```fish
# Self-hosted instance URL
set -gx INFISICAL_API_URL "https://infisical.jefahnierocks.com/api"

# Default context
set -gx TRINITY_CONTEXT "personal"

# Disable telemetry
set -gx INFISICAL_TELEMETRY_ENABLED false
```

### Step 3: Authenticate

#### Option A: Interactive Login (Web Browser)
```bash
# Login via browser (recommended for initial setup)
infisical-login
```

This will:
1. Open your browser to `infisical.jefahnierocks.com`
2. Prompt for email/password + MFA
3. Save credentials to `~/.config/infisical`

#### Option B: Universal Auth (Automation)
For automated/scripted access:

```bash
# Store credentials in gopass first
gopass insert trinity/personal/client_id
gopass insert trinity/personal/client_secret

# Login using stored credentials
infisical-login-machine \
  (gopass show trinity/personal/client_id) \
  (gopass show trinity/personal/client_secret)
```

## 🔧 Configuration

### Fish Shell Integration

The configuration provides these helper functions:

#### Context Management
```fish
# Show current context
trinity-context

# Switch context
trinity-context litecky
trinity-context happy
trinity-context personal
```

#### Secret Operations
```fish
# Get a secret
infisical-get API_KEY dev
infisical-get DATABASE_URL prod

# Set a secret
infisical-set API_KEY "sk-abc123" dev

# List secrets in environment
infisical-list dev
infisical-list prod

# Export secrets as .env file
infisical-export dev .env
infisical-export prod .env.production
```

#### Run Commands with Secrets
```fish
# Inject secrets into command
infisical-run npm start
infisical-run --env prod node server.js
```

### Project Integration with direnv

Add to project `.envrc`:

```bash
# Use Infisical for secrets
use_infisical() {
  export INFISICAL_API_URL="https://infisical.jefahnierocks.com/api"

  # Export specific secrets
  export DATABASE_URL=$(infisical secrets get DATABASE_URL --env dev --plain)
  export API_KEY=$(infisical secrets get API_KEY --env dev --plain)
}

use_infisical

# Or inject all secrets
eval "$(infisical export --env dev --format dotenv)"
```

## 📂 Organizational Structure

### Project Hierarchy

```
infisical/
├── personal/                   # Family & personal tech
│   ├── /banking/
│   ├── /budgeting/
│   ├── /personal-tech/
│   └── /family/
│
├── litecky/                    # Ahnie's editing business
│   ├── /clients/
│   ├── /tools/
│   ├── /infrastructure/
│   └── /accounting/
│
└── happy/                      # Software development
    ├── /development/
    │   ├── /github/
    │   ├── /ai-providers/
    │   ├── /cloud-providers/
    │   └── /services/
    ├── /clients/
    ├── /products/
    └── /business/
```

### Environment Structure

Each project supports multiple environments:
- **dev** - Development environment
- **staging** - Staging/testing environment
- **prod** - Production environment

## 🔧 Troubleshooting

### Issue: "CLI not found"
```bash
# Check if installed
which infisical

# Install if missing
brew install infisical

# Verify
infisical --version
```

### Issue: "Authentication failed"
```bash
# Check domain configuration
echo $INFISICAL_API_URL
# Should show: https://infisical.jefahnierocks.com/api

# Re-authenticate
infisical-login
```

### Issue: "Cannot connect to server"
```bash
# Test server connectivity
curl https://infisical.jefahnierocks.com/api/status

# Should return: {"message":"Ok",...}
```

### Issue: "No secrets found"
```bash
# Check current project and environment
infisical secrets list --env dev

# Verify you're in the correct context
trinity-context
```

## 🚨 Security Best Practices

### DO's ✅
1. **Use contexts properly** - Always set correct context before operations
2. **Use Universal Auth for automation** - Never hardcode credentials
3. **Store Machine Identity credentials in gopass** - Use encrypted storage
4. **Use direnv for project secrets** - Load secrets on directory change
5. **Regular secret rotation** - Rotate sensitive credentials periodically
6. **Audit access logs** - Review who accessed what secrets

### DON'Ts ❌
1. **Never commit .env files** - Always gitignore them
2. **Don't share Machine Identity credentials** - Each service gets its own
3. **Avoid plain text exports** - Use `infisical run` instead
4. **Don't use production secrets in development** - Use separate environments
5. **Never log secret values** - Use `--plain` flag carefully

## 📊 Validation

### Quick Validation
```bash
# Check CLI installation
infisical --version

# Check authentication
infisical user get token

# Test connectivity
curl -s https://infisical.jefahnierocks.com/api/status | jq .

# Test secret retrieval
infisical secrets list --env dev
```

### Full Validation
```bash
# Run through all operations
trinity-context personal
infisical-list dev
infisical-get TEST_SECRET dev
infisical-export dev /tmp/test.env
cat /tmp/test.env && rm /tmp/test.env
```

## 🔗 Related Documentation

- [Prerequisites](00-prerequisites.md) - System requirements
- [Homebrew Setup](01-homebrew.md) - Package manager
- [Secrets Management Guide](../docs/guides/SECRETS-MANAGEMENT-GUIDE.md) - gopass integration
- [Trinity Architecture](../../infisical/README.md) - Platform overview
- [Hetzner Deployment](../../hetzner/services/infisical/README.md) - Server details

## 📚 References

- [Official Infisical Documentation](https://infisical.com/docs)
- [Infisical CLI Reference](https://infisical.com/docs/cli/overview)
- [Universal Auth](https://infisical.com/docs/documentation/platform/identities/universal-auth)
- [Self-Hosting Guide](https://infisical.com/docs/self-hosting/overview)

## 🎯 Quick Reference Card

```bash
# Essential Commands
infisical-login                          # Login via browser
trinity-context <context>                # Switch context
infisical-get <secret> [env]            # Get secret
infisical-set <name> <value> [env]      # Set secret
infisical-list [env]                    # List secrets
infisical-export [env] [file]           # Export to .env
infisical-run [--env <env>] <cmd>       # Run with secrets
infisical_check_updates                 # Check for updates

# Key Configuration
INFISICAL_API_URL=https://infisical.jefahnierocks.com/api
TRINITY_CONTEXT=personal|litecky|happy

# Credentials Location
~/.config/infisical/                    # CLI configuration
```

## ✅ Implementation Status

- [x] Infisical CLI installed via Homebrew
- [x] Fish shell integration configured
- [x] Helper functions created
- [x] Documentation written
- [ ] Universal Auth Machine Identities created
- [ ] Initial project structure in Infisical
- [ ] Secrets migrated from gopass (where applicable)
- [ ] direnv templates updated

---

*Documentation created: October 11, 2025*
*Installation validated on macOS 25.0.0 (Darwin)*

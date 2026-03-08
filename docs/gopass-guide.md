---
title: Gopass Definitive Guide
category: reference
component: gopass_definitive_guide
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---


# Gopass Secret Management - The Definitive Guide

## Quick Start - What You Need to Know

### For AI Agents (Claude Code, Copilot, etc.)
```bash
# Set the passphrase in your environment
export GOPASS_AGE_PASSWORD="escapable diameter silk discover"

# List all secrets
gopass list

# Get a secret
gopass show github/token

# Add a new secret
echo "my-secret-value" | gopass insert development/new-api-key
```

**That's it. The passphrase is always: `escapable diameter silk discover`**

### For Human Users (in Fish Shell)
```fish
# Use Touch ID for each command
gpt show github/token
gpt list

# Or enable for entire session
gopass-enable-touchid
gopass show github/token  # No password needed for this session
```

## How Gopass Works on This System

### The Setup
- **Encryption**: age (modern encryption, replacing GPG)
- **Passphrase**: `escapable diameter silk discover`
- **Store Location**: `~/.local/share/gopass/stores/root/`
- **Config**: `~/.config/gopass/config`

### Key Files
| File | Purpose |
|------|---------|
| `~/.config/gopass/age/identities` | Encrypted age identity (needs passphrase) |
| `~/.config/gopass/age/keys.txt` | Unencrypted backup key |
| `~/.local/share/gopass/stores/root/` | Your encrypted secrets |

## Basic Operations

### List Secrets
```bash
# Show all secrets
gopass list

# Show secrets in a specific path
gopass list github/
```

### Get a Secret
```bash
# Show the secret value
gopass show github/token

# Copy to clipboard (45 second timeout)
gopass show -c github/token

# Show just the password (first line)
gopass show -o github/token
```

### Add a Secret
```bash
# Simple secret (single line)
echo "secret-value" | gopass insert path/to/secret

# Multi-line secret (interactive)
gopass insert path/to/secret
# Type or paste your secret
# Press Ctrl+D when done

# From a file
gopass insert path/to/secret < secret.txt
```

### Update a Secret
```bash
# Replace existing secret (use -f to force)
echo "new-value" | gopass insert -f path/to/secret
```

### Delete a Secret
```bash
gopass rm path/to/secret
```

### Search for Secrets
```bash
# Find secrets by name
gopass find token

# Grep secret contents
gopass grep "api"
```

## Access Control

### AI Agents - Limited Access
Agents can ONLY access these paths:
- `github/*`
- `agent/*`
- `shared/*`
- `policy-as-code/*`
- `development/*`

To use the safe wrapper functions:
```bash
# Source the agent initialization
source ~/.config/gopass/agent-init.sh

# Use wrapper functions
agent_get_secret "github/token"
agent_list_secrets
```

### Human Users - Full Access
Full access to all secrets with Touch ID authentication.

## Secret Format

### Simple Secret
```
my-password-here
```

### Key-Value Secret
```
my-password
username: john.doe
url: https://example.com
notes: Additional information
```

Access specific values:
```bash
gopass show service/login         # Shows everything
gopass show service/login password # Shows first line
gopass show service/login username # Shows username value
```

### YAML Secret
```yaml
my-password
---
username: john.doe
email: john@example.com
api_keys:
  production: prod-key-123
  staging: stage-key-456
```

## Troubleshooting

### "Decryption failed: no identity matched"
**Problem**: Secret was encrypted with a different key
**Solution**: That secret cannot be decrypted with current key

### "No owner key found"
**Problem**: Identity not properly configured
**Solution**: Already fixed - the identity has been added

### "passphrase can't be empty"
**Problem**: Forgot to set GOPASS_AGE_PASSWORD
**Solution**: `export GOPASS_AGE_PASSWORD="escapable diameter silk discover"`

### Touch ID Not Working
**Problem**: Keychain not configured or app not authorized
**Solution**: Check System Settings → Privacy & Security → Touch ID

## For System Administrators

### Backup
```bash
# Export all secrets (encrypted)
gopass export --format yaml backup.yaml

# Backup the age identity (CRITICAL!)
cp -r ~/.config/gopass/age/ ~/secure-backup/
```

### Restore
```bash
# Restore age identity
cp -r ~/secure-backup/age/ ~/.config/gopass/

# Import secrets
gopass import backup.yaml
```

### Re-encrypt All Secrets
```bash
# If you change recipients
gopass fsck --decrypt
```

## Environment Variables

### Required for Agents
```bash
export GOPASS_AGE_PASSWORD="escapable diameter silk discover"
```

### Optional
```bash
export GOPASS_UMASK=0077        # File permissions (default)
export GOPASS_CLIP_TIME=45       # Clipboard timeout in seconds
export GOPASS_NOCOLOR=false     # Disable colors in output
```

## The Single Truth

**The passphrase is always**: `escapable diameter silk discover`

This passphrase:
- Decrypts the age identity in `~/.config/gopass/age/identities`
- Is stored in macOS Keychain for Touch ID access (human users)
- Must be set in GOPASS_AGE_PASSWORD environment variable (AI agents)

## Command Reference Card

| Action | Command | Example |
|--------|---------|---------|
| List all | `gopass list` | `gopass list` |
| Show secret | `gopass show PATH` | `gopass show github/token` |
| Copy to clipboard | `gopass show -c PATH` | `gopass show -c github/token` |
| Add secret | `echo VALUE \| gopass insert PATH` | `echo "abc123" \| gopass insert api/key` |
| Update secret | `echo VALUE \| gopass insert -f PATH` | `echo "new" \| gopass insert -f api/key` |
| Delete secret | `gopass rm PATH` | `gopass rm old/secret` |
| Find secrets | `gopass find TERM` | `gopass find token` |
| Search contents | `gopass grep TERM` | `gopass grep api` |

## DO NOT TRUST ANY OTHER DOCUMENTATION

This is the definitive guide. If you find conflicting information elsewhere, this document is correct.
---
title: Secrets Management Guide
category: reference
component: secrets_management_guide
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---


# 🔐 Secrets Management System Guide

**Last Updated:** September 25, 2025
**Status:** ✅ Fully Operational

---

## 📋 Quick Start

### Essential Configuration
```bash
# Required environment variable (already in Fish config)
export GOPASS_AGE_PASSWORD="gopass-keyring-password"

# Verify setup
gopass ls
```

---

## 🗝️ System Architecture

### Components
| Component | Location | Purpose |
|-----------|----------|---------|
| gopass | v1.15.18 (Homebrew) | Secret management CLI |
| age | v1.2.1 (Homebrew) | Encryption backend |
| pinentry-mac | v1.3.1.1 | GUI passphrase entry |
| Store | `~/.local/share/gopass/stores/root` | Local encrypted storage |
| Git Remote | `git@github.com:verlyn13/gopass-secrets.git` | Synced backup |

### Key Files
```
~/.config/gopass/
├── age/
│   ├── keys.txt        # Age private key
│   └── identities      # Encrypted keyring (DO NOT EDIT)
├── config              # gopass configuration
└── stores/
    └── root -> ~/.local/share/gopass/stores/root
```

### Critical Keys
- **Age Public Key:** `age1x00ljfwm8tzjvyzprs9szckgamg342z7jnxuzu4d6j0rzv5pl4ds40dtnz`
- **Age Private Key:** Located at `~/.config/gopass/age/keys.txt`
- **Keyring Passphrase:** `gopass-keyring-password` (protects age identity)

---

## 📝 Daily Usage

### 1. Creating Secrets

#### Interactive (Recommended for passwords)
```bash
# Create a new password interactively
gopass insert path/to/secret

# Example
gopass insert dev/database/prod_password
```

#### From Command Line
```bash
# Store a simple value
echo "value" | gopass insert -f path/to/secret

# Store API key
echo "sk-abc123..." | gopass insert -f dev/openai/api-key
```

#### Multi-line Secrets
```bash
# Store JSON config
cat config.json | gopass insert -f dev/app/config

# Store environment file
gopass insert -m dev/app/env < .env.template
```

#### Generate Password
```bash
# Generate and store 32-character password
gopass generate dev/app/admin_password 32

# With special characters
gopass generate -s dev/app/api_key 64

# Without symbols (alphanumeric only)
gopass generate -n dev/app/token 40
```

### 2. Retrieving Secrets

#### Basic Retrieval
```bash
# Show full entry (with metadata)
gopass show path/to/secret

# Get password only (for scripts)
gopass show -o path/to/secret

# Copy to clipboard (45 seconds)
gopass show -c path/to/secret
```

#### Search and List
```bash
# List all secrets
gopass ls

# List with tree view
gopass ls -t

# Search for secrets
gopass find api
gopass grep token

# Show all in a path
gopass ls dev/
```

### 3. Managing Secrets

#### Update
```bash
# Edit existing secret
gopass edit path/to/secret

# Replace value
echo "new-value" | gopass insert -f path/to/secret
```

#### Move/Rename
```bash
# Move secret
gopass mv old/path new/path

# Copy secret
gopass cp source/path dest/path
```

#### Delete
```bash
# Delete with confirmation
gopass rm path/to/secret

# Force delete (no confirmation)
gopass rm -f path/to/secret

# Delete entire folder
gopass rm -r folder/
```

### 4. Sync with Git

```bash
# Pull latest changes
gopass sync

# Push local changes
gopass sync

# Check git status
cd ~/.local/share/gopass/stores/root
git status

# Manual git operations
cd ~/.local/share/gopass/stores/root
git pull
git push
```

---

## 🐟 Fish Shell Integration

### Helper Functions (Already Configured)

```fish
# Store a secret
secret-store dev/api_key "value"
secret-store dev/password  # Interactive

# Get a secret
secret-get dev/api_key

# Generate password
secret-generate 32
```

### Auto-loading Secrets
Configured in `~/.config/fish/conf.d/40-secrets.fish`:
- Automatically loads GitHub token if available
- Sets GOPASS_AGE_PASSWORD on shell start
- Provides helper functions

---

## 🔧 Project Integration

### 1. Using direnv with .envrc
```bash
# In project .envrc file
export DATABASE_URL=$(gopass show -o dev/project/db_url)
export API_KEY=$(gopass show -o dev/project/api_key)
export AWS_SECRET_ACCESS_KEY=$(gopass show -o aws/secret_key)
```

### 2. Script Integration
```bash
#!/usr/bin/env bash
# Load secrets in scripts

# Set required passphrase
export GOPASS_AGE_PASSWORD="gopass-keyring-password"

# Get secrets
DB_PASS=$(gopass show -o prod/database/password)
API_TOKEN=$(gopass show -o services/api/token)

# Use in connection string
psql "postgresql://user:${DB_PASS}@host/db"
```

### 3. Docker Integration
```bash
# Pass secrets to Docker
docker run -e API_KEY="$(gopass show -o dev/api_key)" myapp

# Using docker-compose
export DB_PASSWORD=$(gopass show -o dev/db_password)
docker-compose up
```

---

## 📂 Organization Structure

### Recommended Hierarchy
```
gopass/
├── dev/                    # Development environment
│   ├── github_token
│   ├── api_keys/
│   │   ├── openai
│   │   └── anthropic
│   └── database/
│       ├── local_password
│       └── staging_password
├── prod/                   # Production credentials
│   ├── database/
│   ├── api/
│   └── certificates/
├── personal/              # Personal accounts
│   ├── banking/
│   ├── social/
│   └── email/
├── infrastructure/        # Cloud/Server access
│   ├── aws/
│   ├── digitalocean/
│   └── ssh/
└── projects/              # Project-specific
    ├── client-a/
    └── client-b/
```

---

## 🚨 Troubleshooting

### Common Issues

#### 1. "Decryption failed" Error
```bash
# Solution: Set keyring passphrase
export GOPASS_AGE_PASSWORD="gopass-keyring-password"

# If still failing, re-register identity
rm -f ~/.config/gopass/age/identities
gopass age identities add \
  $(cat ~/.config/gopass/age/keys.txt) \
  age1x00ljfwm8tzjvyzprs9szckgamg342z7jnxuzu4d6j0rzv5pl4ds40dtnz
```

#### 2. "No owner key found" Error
```bash
# Add yourself as recipient
gopass recipients add age1x00ljfwm8tzjvyzprs9szckgamg342z7jnxuzu4d6j0rzv5pl4ds40dtnz

# Re-encrypt all secrets
gopass fsck --decrypt
```

#### 3. Sync Issues
```bash
# Check remote
cd ~/.local/share/gopass/stores/root
git remote -v

# Force pull
git fetch --all
git reset --hard origin/main

# Force push (careful!)
git push --force
```

#### 4. Terminal Input Issues
```bash
# Install/reinstall pinentry
brew install pinentry-mac

# Configure
echo "pinentry-program $(brew --prefix)/bin/pinentry-mac" >> ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent
```

---

## 🔒 Security Best Practices

### DO's ✅
1. **Use generated passwords:** `gopass generate` for all new passwords
2. **Organize hierarchically:** Use folders to group related secrets
3. **Sync regularly:** `gopass sync` to keep backups current
4. **Use .envrc:** Load secrets via direnv for projects
5. **Rotate regularly:** Update critical passwords periodically
6. **Audit access:** Review `gopass recipients` periodically

### DON'Ts ❌
1. **Never commit .envrc** with actual values to git
2. **Don't store passphrase** in plain text files
3. **Avoid echo in history:** Use `gopass insert` interactively
4. **Don't share age key:** Keep `~/.config/gopass/age/keys.txt` private
5. **No plain text exports:** Always pipe directly to consumers

---

## 🔄 Backup and Recovery

### Backup Strategy
1. **Automatic:** Git sync to `github.com:verlyn13/gopass-secrets.git`
2. **Manual:** Export encrypted backup
   ```bash
   tar -czf gopass-backup-$(date +%Y%m%d).tar.gz \
     ~/.config/gopass \
     ~/.local/share/gopass/stores/root
   ```

### Recovery Process
1. **From Git:**
   ```bash
   # Clone repository
   git clone git@github.com:verlyn13/gopass-secrets.git ~/.local/share/gopass/stores/root

   # Restore age key (must have backup!)
   cp backup/keys.txt ~/.config/gopass/age/keys.txt

   # Register identity
   export GOPASS_AGE_PASSWORD="gopass-keyring-password"
   gopass age identities add $(cat ~/.config/gopass/age/keys.txt) age1x00ljfwm8tzjvyzprs9szckgamg342z7jnxuzu4d6j0rzv5pl4ds40dtnz
   ```

2. **From Backup Archive:**
   ```bash
   tar -xzf gopass-backup-*.tar.gz -C ~/
   ```

### Critical Files to Backup
- `~/.config/gopass/age/keys.txt` - **MOST IMPORTANT**
- `~/.local/share/gopass/stores/root/` - Secret store
- Passphrase: `gopass-keyring-password` (memorize or store securely)

---

## 📚 Advanced Usage

### Multiple Stores
```bash
# Add work store
gopass mounts add work ~/work-secrets
gopass init --store work

# Access mounted store
gopass show work/secret/path
```

### Team Sharing
```bash
# Add team member
gopass recipients add colleague@example.com

# Remove team member
gopass recipients remove colleague@example.com

# Re-encrypt after changes
gopass fsck --decrypt
```

### Templating
```bash
# Create template
cat > secret.tpl << 'EOF'
username: {{ .username }}
password: {{ gopass "dev/app/password" }}
api_key: {{ getenv "API_KEY" }}
EOF

# Use with gopass
gopass tpl < secret.tpl
```

---

## 🎯 Quick Reference Card

```bash
# Essential Commands
gopass ls                      # List all
gopass show path/to/secret    # View secret
gopass insert path/to/secret  # Create secret
gopass generate path 32       # Generate password
gopass rm path/to/secret      # Delete secret
gopass sync                   # Sync with git

# Must set in shell
export GOPASS_AGE_PASSWORD="gopass-keyring-password"

# Key locations
~/.config/gopass/age/keys.txt        # Age private key
~/.local/share/gopass/stores/root    # Secret store

# Emergency fix
rm -f ~/.config/gopass/age/identities
gopass age identities add $(cat ~/.config/gopass/age/keys.txt) age1x00ljfwm8tzjvyzprs9szckgamg342z7jnxuzu4d6j0rzv5pl4ds40dtnz
```

---

## ✅ Verification Checklist

- [ ] `gopass ls` shows secret tree
- [ ] Can create new secret: `echo test | gopass insert -f test/verify`
- [ ] Can retrieve secret: `gopass show test/verify`
- [ ] Can delete secret: `gopass rm -f test/verify`
- [ ] Git sync works: `gopass sync`
- [ ] Fish loads passphrase automatically
- [ ] Helper functions work: `secret-get`, `secret-store`

---

*Documentation created: September 25, 2025*
*System validated and operational*
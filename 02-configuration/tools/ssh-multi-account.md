---
title: SSH Multi-Account Configuration
category: configuration
component: ssh
status: active
version: 1.0.0
last_updated: 2025-10-23
tags: [configuration, settings, security, remote-access]
applies_to:
  - os: macos
    versions: ["14.0+", "15.0+"]
  - arch: ["arm64", "x86_64"]
priority: high
---


# Multi-Account & Remote Server Setup Guide
## Managing Multiple Git Identities and Server Access

---

## Overview

This guide configures:
- **Multiple GitHub accounts** (personal, work) with automatic identity switching
- **Hetzner server access** with templated SSH configurations  
- **Git URL shortcuts** for seamless repository management
- **Directory-based Git identity** switching
- **Secure credential management** via gopass

---

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   SSH Config    │────▶│  GitHub Accounts │────▶│   Repositories  │
│  (multi-host)   │     │  - personal      │     │  ghp:user/repo  │
│                 │     │  - work          │     │  ghw:org/repo   │
└─────────────────┘     └──────────────────┘     └─────────────────┘
         │                                                 │
         ▼                                                 ▼
┌─────────────────┐                              ┌─────────────────┐
│ Hetzner Servers │                              │   Git Config    │
│  - web1         │                              │  Conditional    │
│  - db1          │                              │   Includes      │
│  - staging      │                              └─────────────────┘
└─────────────────┘
```

---

## Configuration Steps

### 1. SSH Key Setup

#### Option A: Secretive (Hardware-Backed) - Recommended
```bash
# Install and open Secretive
brew install --cask secretive
open -a Secretive

# Create separate keys for each identity in the app
# These are stored in Secure Enclave and cannot be exported
```

#### Option B: Traditional SSH Keys
```bash
# Generate keys for each identity
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_personal \
  -C "personal@example.com"
  
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_work \
  -C "work@company.com"

# Store key PATHS in gopass (not the keys themselves!)
gopass insert ssh/personal/id_ed25519_path
# Enter: /Users/yourname/.ssh/id_ed25519_personal

gopass insert ssh/work/id_ed25519_path  
# Enter: /Users/yourname/.ssh/id_ed25519_work
```

### 2. GitHub Account Configuration

```bash
# Add SSH keys to each GitHub account
# Personal account
gh ssh-key add ~/.ssh/id_ed25519_personal.pub \
  --title "Personal Mac M3"

# Work account (using GH_HOST)
GH_HOST=github.com-work gh ssh-key add ~/.ssh/id_ed25519_work.pub \
  --title "Work Mac M3"

# Authenticate GitHub CLI with both accounts
gh auth login -h github.com          # Personal
gh auth login -h github.com-work     # Work

# Test connections
ssh -T git@github.com-personal       # Should greet personal username
ssh -T git@github.com-work           # Should greet work username
```

### 3. Configure chezmoi Data

Edit `~/.local/share/chezmoi/.chezmoidata.toml`:

```toml
[hetzner]
default_user = "root"
default_port = 22

[hetzner.hosts.web1]
host = "116.203.123.45"
user = "deploy"

[hetzner.hosts.db1]  
host = "116.203.123.46"
user = "postgres"
port = 2222

[hetzner.hosts.staging]
host = "staging.example.com"
user = "deploy"

# Optional: Multi-account email overrides
[git.personal]
email = "personal@example.com"

[git.work]
email = "work@company.com"
```

### 4. Apply Configuration

```bash
# Apply chezmoi templates
chezmoi apply

# This creates:
# - ~/.ssh/config with includes
# - ~/.ssh/conf.d/github.conf for multi-account
# - ~/.ssh/conf.d/hetzner.conf for servers
# - ~/.gitconfig with URL rewrites and conditional includes
# - Fish functions for multi-account operations
```

---

## Usage Patterns

### Git Repository Management

#### Cloning with Shortcuts
```bash
# Using fish functions
gclp username/repo           # Clone personal repo
gclw company/repo           # Clone work repo

# Using Git URL shortcuts
git clone ghp:username/repo  # Personal account
git clone ghw:company/repo   # Work account

# Traditional (still works)
git clone git@github.com-personal:username/repo.git
git clone git@github.com-work:company/repo.git
```

#### Automatic Identity Switching
```bash
# Projects in ~/personal/ use personal Git config
cd ~/personal/my-project
git config user.email        # Shows personal email

# Projects in ~/work/ use work Git config  
cd ~/work/company-project
git config user.email        # Shows work email
```

#### GitHub CLI Multi-Account
```bash
# Personal account operations
ghp repo create my-new-repo
ghp pr list
ghp issue create

# Work account operations
ghw repo list company
ghw pr review
ghw workflow run
```

### Remote Server Access

#### Direct SSH
```bash
# Connect to configured servers
ssh web1                     # Web server
ssh db1                      # Database server
ssh staging                  # Staging environment
```

#### File Transfer
```bash
# Deploy files to web server
rsyncw ./dist/ web1:/var/www/html/

# Backup database
ssh db1 "pg_dump mydb" > backup.sql

# Copy logs from staging
scp staging:/var/log/app.log ./
```

#### Hetzner Cloud Management
```bash
# Set token from gopass
export HCLOUD_TOKEN=$(gopass show cloud/hetzner/hcloud_token)

# Manage infrastructure
hcloud server list
hcloud server ssh web1
hcloud volume attach storage --server web1
```

---

## Project-Specific Configuration

### In `.envrc` for Project-Specific Secrets
```bash
# Load project-specific credentials
export GITHUB_TOKEN=$(gopass show work/github_token)
export HETZNER_TOKEN=$(gopass show cloud/hetzner/project_token)
export DEPLOY_KEY=$(gopass show deploy/project_key)

# Set project-specific Git identity (overrides directory-based)
export GIT_AUTHOR_EMAIL="project@specific.com"
export GIT_COMMITTER_EMAIL="project@specific.com"
```

### Repository-Specific SSH Keys
```bash
# In project's .git/config
[core]
    sshCommand = "ssh -i ~/.ssh/deploy_key"
```

---

## Advanced Patterns

### Bastion/Jump Host Configuration

Add to `~/.ssh/conf.d/hetzner.conf.tmpl`:
```
Host bastion
  HostName bastion.example.com
  User jump
  IdentityFile ~/.ssh/id_ed25519_bastion

Host web1
  HostName 10.0.1.10
  User deploy
  ProxyJump bastion
```

### Tailscale Integration

For Tailscale-connected servers:
```
Host *.tail
  User root
  ProxyCommand tailscale nc %h %p
```

### Per-Repository Deploy Keys

Store deploy key paths in gopass:
```bash
gopass insert deploy/repo1/key_path
# Enter: /Users/you/.ssh/deploy_repo1

# In chezmoi template
{{ $deploy_key := gopass "deploy/repo1/key_path" -}}
Host repo1-deploy
  HostName github.com
  User git
  IdentityFile {{ $deploy_key }}
```

---

## Troubleshooting

### SSH Key Issues
```bash
# Debug SSH connection
ssh -vvv git@github.com-personal

# Check which key is being used
ssh-add -l

# Clear SSH agent and re-add
ssh-add -D
ssh-add ~/.ssh/id_ed25519_personal
```

### Git Identity Confusion
```bash
# Check current config
git config --list --show-origin

# Override for single commit
git -c user.email="other@example.com" commit -m "Message"

# Fix wrong author on last commit
git commit --amend --author="Name <email@example.com>"
```

### GitHub CLI Auth Issues
```bash
# Check auth status
gh auth status
gh auth status -h github.com-work

# Re-authenticate
gh auth logout -h github.com-work
gh auth login -h github.com-work
```

---

## Security Best Practices

1. **Never store private keys in gopass** - Only store paths
2. **Use hardware-backed keys** when possible (Secretive)
3. **Rotate keys regularly** - Quarterly for production
4. **Separate deploy keys** from personal keys
5. **Audit key usage** with GitHub's security log

### Key Rotation Workflow
```bash
# Generate new key
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_personal_new

# Add to GitHub
gh ssh-key add ~/.ssh/id_ed25519_personal_new.pub

# Update gopass
gopass edit ssh/personal/id_ed25519_path

# Test before removing old key
ssh -T git@github.com-personal

# Remove old key from GitHub
gh ssh-key list
gh ssh-key delete <old-key-id>
```

---

## Integration with CI/CD

### GitHub Actions Secrets
```yaml
# Store in repository secrets
DEPLOY_SSH_KEY: ${{ secrets.DEPLOY_SSH_KEY }}
HETZNER_TOKEN: ${{ secrets.HETZNER_TOKEN }}

# Use in workflow
- name: Deploy to Hetzner
  run: |
    echo "${{ secrets.DEPLOY_SSH_KEY }}" > ~/.ssh/deploy_key
    chmod 600 ~/.ssh/deploy_key
    ssh -i ~/.ssh/deploy_key deploy@web1 "cd /app && git pull"
```

### Automated Deployments
```bash
# Create deploy script in project
cat > deploy.sh << 'EOF'
#!/bin/bash
set -e
HOST=$(gopass show deploy/host)
ssh $HOST "cd /app && docker-compose pull && docker-compose up -d"
EOF
```

---

## Summary

This multi-account setup provides:
- **Seamless identity switching** based on repository location
- **URL shortcuts** for quick cloning (`ghp:`, `ghw:`)
- **Centralized server inventory** via chezmoi templates
- **Secure credential management** with gopass
- **Fish helpers** for common multi-account operations

The configuration ensures you never accidentally commit with the wrong identity or push to the wrong account, while keeping all credentials secure and machine-portable.

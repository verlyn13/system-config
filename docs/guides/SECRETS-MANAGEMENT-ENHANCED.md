# Enhanced Secrets Management System
**Created**: 2025-09-28
**Status**: Implemented with Biometric Support
**Tools**: gopass + age + Fish functions + Touch ID

## Overview
This document describes the enhanced secrets management system that integrates gopass with project-specific workflows, providing secure, convenient access to credentials and sensitive data.

## Architecture

### 1. Base Layer: gopass + age
- **gopass**: Password store with Git backing
- **age**: Modern encryption (replacing GPG)
- **Touch ID**: Biometric authentication for passphrase (macOS)
- **Location**: `~/.local/share/gopass/stores/`
- **Config**: `~/.config/gopass/config`

### 2. Project Integration Layer
Two Fish functions provide seamless project integration:
- `claude_project`: Claude-specific project environments
- `project_secrets`: General project secrets management

### 3. Directory Structure
```
gopass/
├── projects/           # Project-specific secrets
│   ├── project-a/
│   ├── project-b/
│   └── project-c/
├── work/              # Work credentials
│   ├── maat-flex
│   └── maat-genai
├── personal/          # Personal credentials
└── cloudflare/        # Service credentials
```

## Usage Guide

### Project Secrets Management

#### Initialize Project Secrets
```fish
cd ~/Development/personal/my-project
project_secrets init
# Creates: gopass/projects/my-project/
```

#### Add Project Secret
```fish
project_secrets set api-key
# Interactive prompt for secret value
```

#### Load Project Secrets as Environment Variables
```fish
project_secrets env
# Exports all project secrets as env vars
# api-key → API_KEY
# db-password → DB_PASSWORD
```

#### Clean Environment
```fish
project_secrets clean
# Removes all project secrets from environment
```

### Claude Project Integration

#### Project Structure
```
.claude/
├── config.json         # Claude project config
└── environment.fish    # Project-specific environment
```

#### Auto-loading
When entering a directory with `.claude/`:
1. Automatically detects Claude project
2. Sources `environment.fish` if present
3. Sets `CLAUDE_PROJECT_ROOT`

#### Manual Loading
```fish
claude_project  # Load current project config
```

### Secure Workflows

#### Development Workflow with Touch ID
```fish
# 1. Enter project directory
cd ~/Development/work/api-server

# 2. Enable Touch ID for session (optional)
gopass-enable-touchid

# 3. Load project secrets
project_secrets env
# or use abbreviation: psenv
# or with Touch ID: pst env

# 4. Work with secrets available as env vars
npm run dev  # Has access to API_KEY, DB_PASSWORD, etc.

# 5. Clean up when done
project_secrets clean
gopass-disable-touchid  # If session auth was enabled
```

#### CI/CD Integration
```fish
# Export secrets for CI
gopass show -o projects/myapp/ci-token | pbcopy

# Bulk export
for secret in (gopass ls --flat projects/myapp/ci)
    echo (basename $secret)=(gopass show -o $secret)
end > .env.ci
```

### Security Best Practices

#### 1. Never Commit Secrets
- Add to `.gitignore`:
  ```
  .env*
  .claude/environment.fish
  *.key
  *.pem
  ```

#### 2. Use Project Isolation
- Each project has its own namespace
- Secrets don't leak between projects
- Easy to audit and rotate

#### 3. Regular Sync
```fish
gopass sync  # Pull latest changes
project_secrets sync  # Convenience wrapper
```

#### 4. Secure Deletion
```fish
# Remove secret permanently
gopass rm projects/old-project/api-key

# Remove entire project
gopass rm -r projects/old-project
```

## Abbreviations & Shortcuts

Fish abbreviations for quick access:
- `ps` → `project_secrets`
- `psenv` → `project_secrets env`
- `psclean` → `project_secrets clean`

## Troubleshooting

### Issue: "No owner key found"
```fish
# Ensure age key exists
age-keygen -y ~/.config/age/key.txt

# Verify gopass uses age
gopass config core.autoclip false
gopass config age.identity ~/.config/age/key.txt
```

### Issue: Secrets not loading
```fish
# Check gopass access
gopass ls projects/(basename (pwd))

# Verify secret exists
gopass show projects/(basename (pwd))/secret-name
```

### Issue: Environment not cleaned
```fish
# Force clean all PROJECT_ vars
set | grep "^PROJECT_" | cut -d' ' -f1 | xargs -I{} set -e {}
```

## Integration Examples

### Node.js Project
```javascript
// .claude/environment.fish
set -gx NODE_ENV development
set -gx API_BASE_URL http://localhost:3000

// Load secrets on start
project_secrets env

// Access in code
const apiKey = process.env.API_KEY
const dbUrl = process.env.DATABASE_URL
```

### Python Project
```python
# .claude/environment.fish
set -gx PYTHONPATH $CLAUDE_PROJECT_ROOT/src

# Load secrets
# project_secrets env

import os
api_key = os.environ.get('API_KEY')
db_password = os.environ.get('DB_PASSWORD')
```

### Docker Compose
```fish
# Load secrets before compose
project_secrets env
docker-compose up

# Or pass specific secrets
gopass show -o projects/myapp/db-password | docker secret create db_pass -
```

## Backup & Recovery

### Backup gopass
```fish
# Export all secrets (encrypted)
gopass export --format yaml > ~/secure-backup/gopass-backup.yaml

# Backup age key (CRITICAL)
cp ~/.config/age/key.txt ~/secure-backup/age-key.txt
chmod 600 ~/secure-backup/age-key.txt
```

### Restore
```fish
# Restore age key
cp ~/secure-backup/age-key.txt ~/.config/age/key.txt

# Import secrets
gopass import ~/secure-backup/gopass-backup.yaml
```

## Security Audit

Run periodic audits:
```fish
# Check for weak passwords
gopass audit

# List all secrets (for review)
gopass ls --flat

# Check last modified
for s in (gopass ls --flat)
    echo "$s: "(gopass show --info $s | grep Modified)
end
```

## Biometric Authentication (Touch ID)

**Status**: ✅ Implemented

Touch ID integration provides passwordless access to gopass:

### Quick Setup
```fish
# One-time setup
gopass-setup-touchid

# Use with Touch ID
gpt show github/token  # Per-command auth
gopass-enable-touchid  # Session-wide auth
```

### Available Commands
- `gpt` - Gopass with Touch ID per command
- `gopass-enable-touchid` - Enable for session
- `gopass-disable-touchid` - Disable for session
- `pst` - Project secrets with Touch ID

See [GOPASS-BIOMETRIC-AUTHENTICATION.md](./GOPASS-BIOMETRIC-AUTHENTICATION.md) for full details.

## Future Enhancements

1. ~~**Biometric Authentication**: Touch ID integration~~ ✅ Implemented
2. **Team Sharing**: Multi-recipient age encryption
3. **Rotation Automation**: Scheduled secret rotation
4. **Audit Logging**: Track all secret access
5. **Cloud Backup**: Encrypted backup to cloud storage

## Summary

This enhanced system provides:
- ✅ Secure storage with gopass + age
- ✅ Biometric authentication with Touch ID
- ✅ Project-specific secret namespaces
- ✅ Automatic environment loading
- ✅ Fish shell integration
- ✅ Simple, memorable commands
- ✅ Clean separation of concerns
- ✅ Chezmoi template management

The system maintains security while providing developer convenience, following the principle of "secure by default, convenient by design."
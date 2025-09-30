---
title: Gopass Biometric Authentication Guide
category: guide
component: security
status: active
version: 1.0.0
last_updated: 2025-09-28
tags: [security, gopass, age, touch-id, biometric, fish, chezmoi]
priority: high
---

# Gopass Biometric Authentication (Touch ID) Setup

## Overview

This guide describes how to enable Touch ID biometric authentication for gopass with age encryption on macOS. The setup integrates with our fish shell, mise, and chezmoi-managed dotfiles configuration.

## Architecture

### Components
1. **gopass** - Password store with Git backing
2. **age** - Modern encryption backend for gopass
3. **macOS Keychain** - Secure storage for age passphrase
4. **Touch ID** - Biometric authentication for keychain access
5. **Fish Shell** - Custom functions for Touch ID integration
6. **Chezmoi** - Template management for configuration

### Configuration Files
- `~/.config/gopass/config` - Gopass configuration
- `~/.config/gopass/age/keys.txt` - Age identity key
- `~/.config/fish/conf.d/50-gopass-biometric.fish` - Fish shell Touch ID functions
- `~/.config/chezmoi/chezmoi.toml` - Machine-specific settings

## Installation

### Prerequisites
- macOS with Touch ID enabled
- Gopass 1.15+ installed (`brew install gopass`)
- Age 1.2+ installed (`brew install age`)
- Fish shell configured
- Chezmoi managing dotfiles

### Step 1: Apply Chezmoi Template

The biometric authentication template has been added to chezmoi. Apply it:

```fish
# Apply the new configuration
chezmoi apply

# Or preview changes first
chezmoi diff
chezmoi apply --dry-run
```

### Step 2: Initial Setup

After applying chezmoi templates, set up Touch ID:

```fish
# Store your age passphrase in keychain
gopass-setup-touchid
```

You'll be prompted once for your age passphrase. It will be stored securely in macOS Keychain with Touch ID protection.

## Usage

### Per-Command Authentication

Use the `gpt` command (gopass with Touch ID):

```fish
# Use gopass with Touch ID authentication
gpt show github/token
gpt list
gpt insert work/api-key

# Abbreviation also available
gp show development/secret
```

Each command triggers Touch ID authentication.

### Session-Wide Authentication

Enable Touch ID for your entire terminal session:

```fish
# Enable for session
gopass-enable-touchid

# Now use regular gopass commands
gopass show github/token
gopass list

# Disable when done
gopass-disable-touchid
```

### Integration with Project Secrets

The biometric authentication integrates with the existing project secrets workflow:

```fish
# Use project secrets with Touch ID
project_secrets_touchid env

# Or use the abbreviation
pst env
```

## Configuration Options

### Chezmoi Template Variables

Configure in `~/.config/chezmoi/chezmoi.toml`:

```toml
[data]
  # Enable Touch ID by default for all gopass commands
  gopass_touchid_default = false  # Set to true to always use Touch ID
```

### Available Functions

| Function | Description | Example |
|----------|-------------|---------|
| `gpt` | Gopass with Touch ID | `gpt show secret` |
| `gopass-setup-touchid` | Initial setup | One-time setup |
| `gopass-enable-touchid` | Enable for session | Start of work session |
| `gopass-disable-touchid` | Disable for session | End of work session |
| `gopass-remove-touchid` | Remove from keychain | Clean up |
| `project_secrets_touchid` | Project secrets with Touch ID | `pst env` |

### Abbreviations

| Abbreviation | Command | Description |
|--------------|---------|-------------|
| `gp` | `gpt` | Quick gopass with Touch ID |
| `gpte` | `gopass-enable-touchid` | Enable for session |
| `gptd` | `gopass-disable-touchid` | Disable for session |
| `gpts` | `gopass-setup-touchid` | Setup Touch ID |
| `pst` | `project_secrets_touchid` | Project secrets with Touch ID |

## Security Considerations

### Keychain Protection
- Passphrase stored in macOS Keychain
- Protected by user login and Touch ID
- Requires biometric authentication for access
- Automatically locked when system sleeps/locks

### Session Security
- Session-wide authentication stores passphrase in environment variable
- Cleared when terminal closes or `gopass-disable-touchid` is run
- Only affects current shell session
- Does not persist across system restarts

### Best Practices
1. Use per-command authentication (`gpt`) for maximum security
2. Enable session authentication only for intensive work periods
3. Always disable session authentication when leaving workstation
4. Regularly rotate your age passphrase
5. Keep Touch ID sensors clean for reliable authentication

## Integration with Existing Workflows

### Development Workflow
```fish
# Morning setup
cd ~/Development/work/project
gopass-enable-touchid      # Authenticate once
project_secrets env         # Load project secrets
mise install               # Install dependencies
npm run dev                # Start development

# End of day
gopass-disable-touchid     # Clear session authentication
```

### CI/CD Secrets
```fish
# Export secrets for CI/CD
gpt show ci/github-token | pbcopy
gpt show ci/npm-token | mise set NPM_TOKEN
```

### Multi-Account Git
```fish
# Switch between accounts with Touch ID
gpt show github/personal-token | gh auth login --with-token
gpt show github/work-token | gh auth login --with-token
```

## Troubleshooting

### Touch ID Not Prompting

1. Check Touch ID is enabled:
   ```fish
   system_profiler SPHardwareDataType | grep "Touch ID"
   ```

2. Verify keychain entry exists:
   ```fish
   security find-generic-password -s "gopass-age-passphrase"
   ```

3. Reset if needed:
   ```fish
   gopass-remove-touchid
   gopass-setup-touchid
   ```

### Passphrase Not Found

If you get "No passphrase found in keychain":
```fish
# Re-run setup
gopass-setup-touchid
```

### Touch ID Fails

If Touch ID consistently fails:
1. Clean Touch ID sensor
2. Re-enroll fingerprints in System Preferences
3. Restart Terminal application
4. Use fallback password authentication

### Fish Functions Not Available

If functions aren't loaded:
```fish
# Reload fish configuration
source ~/.config/fish/config.fish

# Or apply chezmoi templates
chezmoi apply
```

## Maintenance

### Update Passphrase
```fish
# Change age passphrase
gopass age change-passphrase

# Update keychain
gopass-setup-touchid
```

### Backup Considerations
- Keychain entries are included in macOS backups
- Age keys should be backed up separately
- Consider using gopass sync for distributed backup

### Migration to New Machine
1. Install gopass and age
2. Restore age keys from backup
3. Clone gopass repository
4. Run `gopass-setup-touchid` on new machine

## Related Documentation

- [SECRETS-MANAGEMENT-ENHANCED.md](./SECRETS-MANAGEMENT-ENHANCED.md) - Overall secrets management
- [Fish Shell Configuration](../../01-setup/03-fish-shell.md) - Fish shell setup
- [Chezmoi Templates](../../06-templates/chezmoi/README.md) - Template management
- [Security Tools](../../01-setup/05-security.md) - Security tooling overview

## Support

For issues or questions:
1. Check this documentation
2. Review fish shell logs: `journalctl -f`
3. Verify gopass configuration: `gopass config`
4. Test age encryption: `echo "test" | age -r $(cat ~/.config/gopass/age/age-recipient.txt)`

## Version History

- **1.0.0** (2025-09-28) - Initial implementation with fish, chezmoi integration
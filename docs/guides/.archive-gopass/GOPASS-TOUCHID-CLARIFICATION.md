---
title: Gopass Touch ID Setup Clarification
category: guide
component: security
status: active
version: 1.1.0
last_updated: 2025-09-28
tags: [security, gopass, age, touch-id, migration]
priority: critical
---

# Gopass and Touch ID: Current Status and Clarification

## Important Discovery

After investigation, we've determined that **Touch ID is NOT needed for your current gopass setup**. Here's why:

## Your Current Configuration

### Age Key Setup
- **Location**: `~/.config/gopass/age/keys.txt`
- **Type**: Unencrypted age secret key
- **Passphrase Required**: NO
- **Key ID**: `AGE-SECRET-KEY-1UL24JLQFADF0E7SNNKXUDQUAQEZYH7PSXYEJE5EJU5QS88NNUVGSPJJ0ZC`
- **Public Key**: `age1x00ljfwm8tzjvyzprs9szckgamg342z7jnxuzu4d6j0rzv5pl4ds40dtnz`

### What Happened
1. You migrated from an old gopass store to a new one
2. The old store used a different age key (stored at `~/.config/age/key.txt`)
3. The new store uses an unencrypted key that doesn't require a passphrase
4. Old secrets cannot be decrypted with the new key (they need to be re-encrypted or re-added)

## Touch ID Status

### Why Touch ID Isn't Needed
Your current age key (`~/.config/gopass/age/keys.txt`) is:
- Stored in plain text
- Does not require a passphrase to use
- Can be used directly by gopass without authentication

### When Touch ID Would Be Useful
Touch ID would only be beneficial if:
1. You encrypt your age private key with a passphrase
2. You want an additional layer of security
3. You store that passphrase in the macOS Keychain

## Current Working Commands

Since your age key doesn't require a passphrase, you can use gopass normally:

```fish
# These work without any authentication:
gopass list
gopass show secret-name
gopass insert new-secret
```

## If You Want Touch ID Security (Optional)

If you want to add Touch ID protection to your gopass setup:

### Option 1: Encrypt Your Age Key
```bash
# 1. Backup your current key
cp ~/.config/gopass/age/keys.txt ~/.config/gopass/age/keys.txt.backup

# 2. Create an encrypted version
age -p -o ~/.config/gopass/age/keys-encrypted.txt ~/.config/gopass/age/keys.txt

# 3. Update gopass config to use encrypted key
gopass config age.identity ~/.config/gopass/age/keys-encrypted.txt

# 4. Now you'll need a passphrase, which can be stored with Touch ID
```

### Option 2: Use the Current Touch ID Functions (No Real Security Benefit)
The Touch ID functions we set up (`gpt`, `gopass-enable-touchid`, etc.) will work but provide no additional security since your key is already unencrypted.

## Cleanup Recommendations

### Remove Unnecessary Files
```bash
# Old age key (if no longer needed)
rm ~/.config/age/key.txt

# Encrypted identities file (not being used)
rm ~/.config/gopass/age/identities.backup

# Touch ID passphrase (not needed for unencrypted key)
security delete-generic-password -a $USER -s gopass-age-passphrase
```

### Keep Using Standard Gopass
```fish
# Just use gopass normally
gopass list
gopass show github/token
```

## Migration Notes

If you have old secrets that can't be decrypted:
1. They were encrypted with the old age key
2. You'll need to re-add them to the new store
3. Or restore the old key temporarily to migrate them

## Summary

- **Current Setup**: Unencrypted age key, no passphrase needed
- **Touch ID**: Not required for your current configuration
- **Security**: Your secrets are still encrypted with age, just the private key itself is unencrypted
- **Recommendation**: Use gopass normally without Touch ID unless you want to encrypt your private key
---
title: Gopass Final Status
category: reference
component: gopass_final_status
status: draft
version: 1.0.0
last_updated: 2025-10-23
tags: []
priority: medium
---


# Gopass with Touch ID: Final Status Report

## ✅ What's Working

### Touch ID Integration
- **Passphrase Storage**: Successfully stored in macOS Keychain
- **Touch ID Prompt**: Works when retrieving passphrase via `security find-generic-password`
- **Fish Functions**: All biometric functions installed and working:
  - `gpt` - Wrapper for gopass with Touch ID
  - `gopass-enable-touchid` - Enables session authentication
  - `gopass-setup-touchid` - Initial setup
  - `gopass-disable-touchid` - Disables session

### Gopass Core
- **Configuration**: Properly configured at `~/.config/gopass/config`
- **Recipients**: Correctly set to `age1x00ljfwm8tzjvyzprs9szckgamg342z7jnxuzu4d6j0rzv5pl4ds40dtnz`
- **Listing**: `gopass list` works with passphrase
- **File Permissions**: Fixed by `gopass fsck`

## ❌ What's NOT Working

### Critical Issues
1. **Cannot Decrypt Existing Secrets**
   - All 136 existing secrets were encrypted with a different age key
   - Error: "failed to decrypt: no identity matched any of the recipients"
   - These secrets need to be re-encrypted with the current key

2. **Cannot Create New Secrets**
   - Error: "No owner key found. Make sure your key is fully trusted"
   - Even with correct passphrase, gopass cannot encrypt new secrets
   - The identity/key trust relationship is broken

## Root Cause Analysis

### The Problem
There's a mismatch between:
1. The age key that encrypted the existing secrets (old key)
2. The current age key in `~/.config/gopass/age/keys.txt` (new key)
3. The encrypted identities file that requires the passphrase

### Why Touch ID Setup Doesn't Matter Yet
Touch ID is successfully configured, but it's irrelevant because:
- Gopass can't decrypt any existing secrets (wrong key)
- Gopass can't create new secrets (trust issue)
- The underlying encryption/decryption is broken

## Required Actions to Fix

### Option 1: Restore Old Key
If you have the original age key that encrypted the secrets:
1. Replace `~/.config/gopass/age/keys.txt` with the original key
2. Test decryption of existing secrets
3. Then Touch ID will work for those secrets

### Option 2: Re-encrypt All Secrets
If you have access to the decrypted values:
1. Export all secrets from a working backup
2. Re-import them with the current key
3. Touch ID will work for the new secrets

### Option 3: Start Fresh
If the old secrets are not recoverable:
1. Archive the current store: `mv ~/.local/share/gopass/stores/root ~/.local/share/gopass/stores/root.old`
2. Initialize a new store: `gopass init`
3. Add all secrets fresh
4. Touch ID will work immediately

## Touch ID Summary

**Status**: ✅ Configured and Ready
**Blocking Issue**: Gopass encryption/decryption is broken
**When It Will Work**: After fixing the key/trust issues above

The Touch ID integration is properly set up and will work perfectly once the underlying gopass encryption issues are resolved. The passphrase "escapable diameter silk discover" is stored in the keychain and can be retrieved with Touch ID authentication.
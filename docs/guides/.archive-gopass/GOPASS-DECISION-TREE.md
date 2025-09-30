---
title: Gopass Setup Decision Tree
category: guide
component: security
status: active
version: 1.0.0
last_updated: 2025-09-28
tags: [security, gopass, age, decision-tree]
priority: critical
---

# Gopass Configuration: Simple Decision Tree

## START HERE: What Are You?

### Option A: I am Claude Code / AI Agent
**Your passphrase is:** `escapable diameter silk discover`
**Your access:** Limited to development paths only
**How to use:**
```bash
export GOPASS_AGE_PASSWORD="escapable diameter silk discover"
gopass list              # Works
gopass show github/token # Works if in allowed paths
```

### Option B: I am the Human User (verlyn13)
**Your setup:** Touch ID via macOS Keychain
**Your access:** Full access to all secrets

#### Step 1: Is Touch ID Set Up?
Check if passphrase is in keychain:
```bash
security find-generic-password -s gopass-age-passphrase -w
```

- **If it returns the passphrase:** Touch ID is set up ✅ → Go to Step 2
- **If it returns error:** Touch ID is NOT set up ❌ → Run this:
  ```bash
  security add-generic-password \
    -a $USER \
    -s gopass-age-passphrase \
    -w "escapable diameter silk discover" \
    -T /Applications/iTerm.app \
    -T /System/Applications/Utilities/Terminal.app \
    -U
  ```

#### Step 2: Use Gopass
**In Fish Shell:**
```fish
# Option 1: Per-command (Touch ID each time)
gpt show github/token

# Option 2: Session-wide (Touch ID once)
gopass-enable-touchid
gopass show github/token
gopass list
```

**In Bash/Zsh:**
```bash
# Get passphrase from keychain (triggers Touch ID)
PASS=$(security find-generic-password -s gopass-age-passphrase -w)
GOPASS_AGE_PASSWORD="$PASS" gopass show github/token
```

## TROUBLESHOOTING

### "Decryption failed: no identity matched"
**Problem:** Secret was encrypted with different key
**Solution:** That secret cannot be decrypted with current key. Re-add it.

### "No owner key found"
**Problem:** Recipients not properly configured
**Solution:**
```bash
gopass recipients add --force age1x00ljfwm8tzjvyzprs9szckgamg342z7jnxuzu4d6j0rzv5pl4ds40dtnz
```

### "passphrase can't be empty"
**Problem:** No passphrase provided
**Solution:** Set `GOPASS_AGE_PASSWORD="escapable diameter silk discover"`

## KEY FILES

| File | Purpose | Contents |
|------|---------|----------|
| `~/.config/gopass/age/keys.txt` | Unencrypted age private key | Plain text key |
| `~/.config/gopass/age/identities` | Encrypted age private key | Needs passphrase to decrypt |
| `~/.config/gopass/config` | Gopass configuration | Points to keys.txt |
| `~/.local/share/gopass/stores/root/` | Encrypted secrets | Your actual passwords |

## THE TRUTH

1. **Passphrase:** Always `"escapable diameter silk discover"`
2. **The identities file:** Encrypted with the passphrase
3. **The keys.txt file:** Not encrypted, but gopass prefers identities
4. **Touch ID:** Stores the passphrase in macOS Keychain for convenience
5. **Current key public:** `age1x00ljfwm8tzjvyzprs9szckgamg342z7jnxuzu4d6j0rzv5pl4ds40dtnz`
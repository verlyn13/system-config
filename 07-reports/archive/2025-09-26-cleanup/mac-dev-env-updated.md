---
title: Mac Dev Env Updated
category: reference
component: mac_dev_env_updated
status: draft
version: 1.0.0
last_updated: 2025-09-26
tags: []
priority: medium
---

# Quick Implementation Guide
## M3 Max Development Environment - September 2025

---

## 🚀 Phase 1: Initial Bootstrap (30 minutes)

### Step 1: Core Installation
```bash
# 1. Install Homebrew (if not present)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

# 2. Install chezmoi and essential tools
brew install chezmoi git gh

# 3. Fork the starter template (or use your existing dotfiles)
gh repo fork https://github.com/yourusername/m3-max-dotfiles --clone
```

### Step 2: Initialize chezmoi
```bash
# Initialize and apply dotfiles
chezmoi init --apply ./m3-max-dotfiles

# You'll be prompted for:
# - Email
# - Full name  
# - GitHub username
# - Work machine? (y/n)
# - Android development? (y/n)
```

### Step 3: Complete Installation
```bash
# Install all packages from generated Brewfile
brew bundle --file=~/Brewfile

# Set fish as default shell
echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/fish

# Restart terminal
exec fish
```

### Step 4: Verify Setup
```fish
# Run system check
mise doctor
chezmoi doctor
direnv version
docker --version | grep -i orbstack

# Install language runtimes
mise install
```

---

## 🔐 Phase 2: Security Setup (15 minutes)

### Step 1: Initialize gopass
```fish
# Generate age key
age-keygen > ~/.config/age/key.txt
chmod 600 ~/.config/age/key.txt

# Initialize gopass with age
gopass init --crypto age

# Configure
gopass config autoclip false
gopass config notifications false
```

### Step 2: Setup SSH Keys
```fish
# Option A: Hardware-backed (Secretive - Recommended)
open -a Secretive
# Create keys in app - stored in Secure Enclave, non-exportable

# Option B: Traditional SSH keys for each account
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_personal -C "personal@example.com"
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_work -C "work@company.com"

# Store key paths in gopass (not the keys themselves!)
gopass insert ssh/personal/id_ed25519_path
# Enter: /Users/yourname/.ssh/id_ed25519_personal
gopass insert ssh/work/id_ed25519_path
# Enter: /Users/yourname/.ssh/id_ed25519_work
```

### Step 3: Configure GitHub Multi-Account
```fish
# Authenticate with both GitHub accounts
gh auth login -h github.com          # Personal account
gh auth login -h github.com-work     # Work account

# Add SSH keys to GitHub
gh ssh-key add ~/.ssh/id_ed25519_personal.pub --title "Personal Mac"
GH_HOST=github.com-work gh ssh-key add ~/.ssh/id_ed25519_work.pub --title "Work Mac"

# Test connections
ssh -T git@github.com-personal
ssh -T git@github.com-work
```

### Step 4: Store Initial Secrets
```fish
# Development tokens
gopass insert dev/github_token
gopass insert dev/openai_api_key
gopass insert dev/database_url

# Work-specific (if applicable)
gopass insert work/github_token
gopass insert work/jira_token

# Cloud providers
gopass insert cloud/hetzner/hcloud_token
gopass insert cloud/aws/access_key_id
```

---

## 📦 Phase 3: First Project (5 minutes)

### Step 1: Create Project
```fish
# Navigate to development directory
cd ~/Development

# Create new Node.js project
new-project node my-api

# This creates:
# - .mise.toml (Node 24, latest tools)
# - .envrc (direnv config)
# - package.json
# - renovate.json
# - VERSION_POLICY.md
```

### Step 2: Initialize Git and Renovate
```fish
cd my-api
git init
gh repo create --private
git add .
git commit -m "Initial commit"
git push -u origin main

# Enable Renovate
# Go to: https://github.com/apps/renovate
# Install and configure for your repo
```

### Step 3: Setup CI
```fish
# Copy CI workflow
mkdir -p .github/workflows
cp ~/.local/share/chezmoi/.chezmoitemplates/ci.yml .github/workflows/

# Commit CI configuration
git add .github
git commit -m "Add CI workflow"
git push
```

---

## 🔄 Phase 4: Daily Workflow

### Morning Routine
```fish
# Update machine tools (weekly)
brewup                  # brew update && upgrade
mise upgrade           # Update language tools

# Check for updates
gh pr list --label dependencies  # Review Renovate PRs
```

### Starting Work on Project
```fish
cd ~/Development/my-project
# Environment loads automatically via direnv!

# Verify correct versions
node --version  # Should be 24.x
python --version  # Should be 3.13.x

# Install/update dependencies
pnpm install --frozen-lockfile
```

### Multi-Account Git Workflow
```fish
# Clone repositories using shortcuts
gclp yourusername/personal-project     # Clones with personal account
gclw company/work-project              # Clones with work account

# Or use full shortcuts
git clone ghp:yourusername/dotfiles    # Personal
git clone ghw:company/internal-tool    # Work

# Projects automatically use correct identity
cd ~/personal/my-project               # Uses personal Git config
cd ~/work/company-project             # Uses work Git config

# GitHub CLI with different accounts
ghp repo create my-personal-repo       # Creates on personal account
ghw issue list                         # Lists issues on work account
```

### Remote Server Management
```fish
# SSH to Hetzner servers (configured in .chezmoidata.toml)
ssh web1                               # Connects to web server
ssh db1                                # Connects to database server

# Sync files
rsyncw ./dist/ web1:/var/www/html/    # Deploy to web server

# Hetzner Cloud CLI
export HCLOUD_TOKEN=$(gopass show cloud/hetzner/hcloud_token)
hcloud server list
```

---

## 🎯 Quick Reference

### Project Commands
```fish
# Create projects
new-project node api          # Node.js
new-project python ml         # Python
new-project go service        # Go
new-project rust cli          # Rust
new-project android app       # Android

# Navigate
dev                           # Go to ~/Development
z project-name               # Jump to project (zoxide)
```

### Version Management
```fish
# Check versions
mise list                    # All installed tools
mise current                # Current project versions

# Update project runtime
mise use node@24            # Set Node 24 for project
mise use python@3.13        # Set Python 3.13
```

### Secret Management
```fish
# Store secrets
gopass insert dev/api_key
gopass generate dev/token 32

# Use in projects (.envrc)
export API_KEY=$(gopass show dev/api_key)
```

### Container Operations
```fish
# Docker (via OrbStack)
docker compose up -d
docker ps
orbctl restart              # Restart OrbStack
```

### Android Development
```fish
# Launch emulator
emulator @Pixel_8_Pro_API_34

# Build and install
./gradlew assembleDebug
adb install app/build/outputs/apk/debug/app-debug.apk
```

---

## 📊 Monitoring & Maintenance

### Weekly Checklist
- [ ] Review and merge Renovate PRs
- [ ] Update machine tools: `brewup`
- [ ] Check security updates: `gh pr list --label security`
- [ ] Clean Docker: `docker system prune`
- [ ] Update dotfiles: `chezmoi update`

### Monthly Checklist
- [ ] Audit dependencies: `pnpm audit`, `uv audit`
- [ ] Review disk usage: `df -h`, `du -sh ~/Development/*`
- [ ] Update mise tools: `mise upgrade`
- [ ] Backup secrets: `gopass backup`

---

## 🚨 Troubleshooting

### Environment Not Loading
```fish
# Check direnv status
direnv status

# Re-allow if needed
direnv allow

# Verify .mise.toml exists
cat .mise.toml
```

### Version Conflicts
```fish
# Check what's providing a command
which node
mise which node

# Force reload
direnv reload
mise install --force
```

### Performance Issues
```fish
# Check resource usage
htop
docker stats

# Clean caches
pnpm store prune
cargo clean
go clean -cache
```

### Rollback After Bad Update
```fish
# Find last known good tag
git tag | grep lkg

# Checkout LKG
git checkout lkg-2025-09-19

# Or revert Renovate PR
git revert -m 1 HEAD
```

---

## 📚 Next Steps

1. **Customize fish**: Edit `~/.config/fish/conf.d/` files
2. **Add project templates**: Create templates in chezmoi for your stack
3. **Setup CI templates**: Standardize GitHub Actions workflows
4. **Configure Neovim**: Install LazyVim or your preferred config
5. **Team onboarding**: Share dotfiles repo with team

---

## 🔗 Resources

- [chezmoi Documentation](https://www.chezmoi.io/)
- [mise Documentation](https://mise.jdx.dev/)
- [Renovate Documentation](https://docs.renovatebot.com/)
- [Fish Shell Documentation](https://fishshell.com/docs/current/)
- [OrbStack Documentation](https://docs.orbstack.dev/)

---

*Remember: The goal is a thin machine layer with thick, self-contained projects. Let automation handle the updates while CI guards the gates.*

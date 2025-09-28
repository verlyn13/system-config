---
title: Validation Checklist
category: reference
component: validation_checklist
status: draft
version: 1.0.0
last_updated: 2025-09-26
tags: []
priority: medium
---

# System Setup Validation Checklist
## Progress and Compliance (PaC) System

### Validation Methodology
Each phase has specific validation criteria that must be met before marking as complete.
- ✅ = Validated and working
- ⚠️ = Partially working/needs attention
- ❌ = Not working/not implemented
- 🔄 = In progress

---

## Phase 0: Pre-flight Checks
### Requirements
- [ ] macOS version current (Sequoia 15.0+)
- [ ] Command Line Tools installed
- [ ] Basic directory structure exists

### Validation Commands
```bash
sw_vers -productVersion
xcode-select --version
ls -la ~/Development ~/workspace ~/library ~/archive
```

### Current Status: ✅ COMPLETE
- macOS Sequoia 15.0 installed
- Command Line Tools present
- Directory structure created

---

## Phase 1: Foundation - Homebrew & Core Tools
### Requirements
- [ ] Homebrew installed at `/opt/homebrew`
- [ ] Core packages from Brewfile.core installed
- [ ] Homebrew in PATH for all shells

### Validation Commands
```bash
# Check Homebrew
brew --version && which brew
# Verify core packages
brew list | grep -E "(git|chezmoi|mise|fish|starship|direnv|bat|eza|ripgrep)"
# Check PATH
echo $PATH | grep "/opt/homebrew/bin"
```

### Current Status: ✅ COMPLETE
- Homebrew 4.6.13 at `/opt/homebrew/bin/brew`
- All core packages installed
- PATH properly configured

---

## Phase 2: Dotfile Management with chezmoi
### Requirements
- [ ] chezmoi installed and initialized
- [ ] Templates in `~/.local/share/chezmoi/`
- [ ] Configuration in `~/.config/chezmoi/chezmoi.toml`
- [ ] Run-once scripts executable
- [ ] Template guards prevent errors

### Validation Commands
```bash
# Check chezmoi
chezmoi --version
chezmoi status
# Verify structure
ls -la ~/.local/share/chezmoi/
ls -la ~/.config/chezmoi/chezmoi.toml
# Test apply
chezmoi apply --dry-run
```

### Current Status: ✅ COMPLETE
- chezmoi v2.65.2 installed
- Templates properly structured
- Configuration data present with all required keys
- Templates hardened with default guards

---

## Phase 3: Fish Shell Configuration
### Requirements
- [ ] Fish is default shell
- [ ] Configuration in `~/.config/fish/`
- [ ] Modular conf.d structure working
- [ ] PATH includes user directories
- [ ] Claude CLI accessible

### Validation Commands
```bash
# Check shell
echo $SHELL
fish --version
# Verify configuration
ls -la ~/.config/fish/conf.d/
# Test PATH
fish -c 'echo $PATH | tr " " "\n" | grep -E "(npm-global|local/bin)"'
# Test Claude CLI
fish -c 'claude --version'
```

### Current Status: ✅ COMPLETE
- Fish 3.8.2 is default shell
- Modular conf.d with 00-homebrew through 04-paths
- PATH includes ~/.npm-global/bin, ~/bin, ~/.local/bin
- Claude CLI v1.0.126 accessible

---

## Phase 4: Version Management with mise
### Requirements
- [ ] mise installed and configured
- [ ] Global config at `~/.config/mise/config.toml`
- [ ] Core languages installed (Node, Python, Go, Rust)
- [ ] Project templates working
- [ ] direnv integration functional

### Validation Commands
```bash
# Check mise
mise --version
mise doctor
# Verify tools
mise list --installed
# Test project switching
cd ~/Development/test-project && mise which node
```

### Current Status: ⚠️ PARTIAL
- ✅ mise 2025.9.18 installed
- ✅ Global config exists
- ✅ Languages installed: Node 24.9.0, Python 3.13.7, Go 1.25.1, Bun 1.2.22, Java temurin-17
- ❌ Rust not installed (not in mise list)
- ❌ Project templates not tested
- ⚠️ uv not showing in mise list

---

## Phase 5: Security with gopass + age
### Requirements
- [ ] age installed and key generated
- [ ] gopass initialized with age backend
- [ ] Secret integration in templates
- [ ] Project .envrc template functional

### Validation Commands
```bash
# Check tools
age --version
gopass --version
# Verify configuration
ls -la ~/.config/age/key.txt
gopass config
```

### Current Status: ❌ NOT STARTED
- age and gopass installed via Homebrew
- No age key generated
- gopass not initialized

---

## Phase 6: Containerization with OrbStack
### Requirements
- [ ] OrbStack installed
- [ ] Docker CLI working
- [ ] Docker Compose available
- [ ] Optimal settings configured

### Validation Commands
```bash
# Check OrbStack
pgrep -x OrbStack
# Verify Docker
docker --version
docker compose version
docker info | grep -i orbstack
```

### Current Status: ⚠️ PARTIAL
- ✅ OrbStack installed (cask in Brewfile.gui)
- ❌ Not running/configured
- ❌ Docker CLI not tested

---

## Phase 7: Android Development
### Requirements
- [ ] Android Studio installed
- [ ] SDK at ~/Library/Android/sdk
- [ ] ANDROID_HOME configured
- [ ] Platform tools in PATH
- [ ] Gradle optimizations applied

### Validation Commands
```bash
# Check installation
ls -la /Applications/Android\ Studio.app
# Verify SDK
ls -la ~/Library/Android/sdk
# Check environment
echo $ANDROID_HOME
which adb
```

### Current Status: ❌ NOT STARTED
- Android packages not installed (user opted out)
- `android = false` in chezmoi config

---

## Phase 8: Bootstrap Script
### Requirements
- [ ] install.sh exists in chezmoi repo
- [ ] Script is executable
- [ ] Handles all phases correctly
- [ ] Idempotent execution

### Validation Commands
```bash
# Check script
ls -la ~/.local/share/chezmoi/install.sh
# Verify idempotency markers
grep -E "(command -v|if \[)" ~/.local/share/chezmoi/install.sh
```

### Current Status: ❌ NOT CREATED
- No bootstrap script exists
- Manual setup performed instead

---

## Phase 9: Project Templates
### Requirements
- [ ] Project creation functions defined
- [ ] Templates for each language
- [ ] mise.toml templates working
- [ ] .envrc templates functional

### Validation Commands
```bash
# Check functions
fish -c 'functions new-project'
# Test project creation
fish -c 'new-project node test-node'
ls -la ~/Development/test-node/.mise.toml
```

### Current Status: ⚠️ PARTIAL
- ✅ Template files exist in workspace/dotfiles/templates/
- ✅ init-project.sh script exists
- ❌ new-project function not defined in Fish
- ❌ Not tested end-to-end

---

## Phase 10: System Optimization
### Requirements
- [ ] Spotlight exclusions configured
- [ ] Time Machine exclusions set
- [ ] File descriptor limits increased
- [ ] High Power Mode enabled (M3 Max)

### Validation Commands
```bash
# Check Spotlight exclusions
mdutil -s ~/Development
# Verify Time Machine
tmutil isexcluded ~/Development
# Check limits
launchctl limit maxfiles
```

### Current Status: ❌ NOT STARTED
- No optimizations applied
- Default macOS settings in use

---

## Overall Progress Summary

### Completion Metrics
- **Fully Complete**: 4/11 phases (36%)
- **Partial**: 2/11 phases (18%)
- **Not Started**: 5/11 phases (45%)

### Critical Path Items
1. ✅ Foundation working (Homebrew, Fish, chezmoi)
2. ✅ Claude CLI accessible
3. ⚠️ mise needs Rust and uv verification
4. ❌ Security layer not initialized
5. ❌ Bootstrap automation missing

### Risk Assessment
- **Low Risk**: Core development environment functional
- **Medium Risk**: No automated recovery (missing bootstrap)
- **High Risk**: Secrets management not configured

### Recommended Priority Actions
1. Complete Phase 4: Install Rust, verify uv, test project templates
2. Create Phase 8: Write bootstrap.sh for disaster recovery
3. Initialize Phase 5: Set up gopass + age for secrets
4. Test Phase 9: Verify project template functions
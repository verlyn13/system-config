---
title: macOS Development Environment Setup
category: setup
component: prerequisites
status: active
version: 3.0.0
last_updated: 2025-09-26
dependencies:
tags: [installation, setup]
applies_to:
  - os: macos
    versions: ["14.0+", "15.0+"]
  - arch: ["arm64", "x86_64"]
priority: critical
---

# M3 Max Development Environment Setup
## Architected for Reproducibility, Security, and Developer Experience

---

## Phase 1: Foundation - Homebrew & Core Tools

### 1.1 Install Homebrew (Apple Silicon)
```bash
# Install Homebrew to /opt/homebrew (ARM64 native)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Temporarily add to current shell
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### 1.2 Modular Brewfile Structure
Instead of a monolithic Brewfile, we'll use a templated approach with chezmoi for machine-specific configurations.

Create these base files in your dotfiles repo:

#### `Brewfile.core` (Always installed)
```ruby
tap "homebrew/bundle"
tap "homebrew/services"

# Core CLI essentials
brew "git"
brew "coreutils"
brew "jq"
brew "tree"
brew "htop"
brew "chezmoi"         # Dotfile manager
brew "direnv"          # Directory environments
brew "mise"            # Version manager
brew "fish"            # Shell
brew "starship"        # Prompt
brew "fzf"             # Fuzzy finder
brew "ripgrep"         # Fast grep
brew "bat"             # Better cat
brew "eza"             # Modern ls
brew "zoxide"          # Smart cd
```

#### `Brewfile.dev` (Development tools)
```ruby
# Development tools
brew "gh"              # GitHub CLI
brew "lazygit"         # Git UI
brew "neovim"          # Editor
brew "tmux"            # Terminal multiplexer
brew "watchman"        # File watcher
brew "gopass"          # Password manager
brew "age"             # Encryption
```

#### `Brewfile.gui` (GUI applications)
```ruby
# GUI Applications
cask "iterm2"
cask "visual-studio-code"
cask "cursor"
cask "windsurf"
cask "rectangle"
cask "orbstack"
cask "raycast"
cask "shottr"
cask "secretive"
```

> After installation, follow the recommendations in
> [`iterm2-config.md`](iterm2-config.md) to enable the 3.6.2 developer
> experience defaults (AI assistant, Navigator integration, modern key
> bindings, and image enhancements).

#### `Brewfile.android` (Android development)
```ruby
# Android development
cask "android-studio"
cask "android-platform-tools"
brew "gradle"
```

---

## Phase 2: Dotfile Management with chezmoi

### 2.1 Initialize chezmoi
```bash
# Install chezmoi
brew install chezmoi

# Initialize with your dotfiles repo (create one first if needed)
chezmoi init --apply git@github.com:yourusername/dotfiles.git

# Or start fresh
chezmoi init
```

### 2.2 chezmoi Directory Structure
```
~/.local/share/chezmoi/
├── .chezmoi.toml.tmpl           # Machine-specific config
├── .chezmoidata.toml            # Shared data
├── Brewfile.tmpl                # Dynamic Brewfile
├── dot_config/
│   ├── fish/
│   │   ├── config.fish.tmpl
│   │   └── conf.d/
│   │       ├── 00-path.fish
│   │       ├── 10-aliases.fish.tmpl
│   │       ├── 20-functions.fish
│   │       └── 30-completions.fish
│   ├── mise/
│   │   └── config.toml.tmpl
│   ├── starship.toml
│   └── git/
│       └── config.tmpl
├── dot_envrc.tmpl               # Global .envrc template
└── install.sh                   # Bootstrap script
```

### 2.3 Machine Configuration
Create `.chezmoi.toml.tmpl`:
```toml
{{- $email := promptStringOnce . "email" "Git email" -}}
{{- $name := promptStringOnce . "name" "Full name" -}}
{{- $is_work := promptBoolOnce . "is_work" "Is this a work machine" -}}
{{- $has_android := promptBoolOnce . "has_android" "Include Android development" -}}
{{- $headless := promptBoolOnce . "headless" "Configure as headless setup" -}}

[data]
email = {{ $email | quote }}
name = {{ $name | quote }}
is_work = {{ $is_work }}
has_android = {{ $has_android }}
headless = {{ $headless }}

[data.packages]
core = true
dev = true
gui = {{ not $headless }}
android = {{ $has_android }}
```

> Existing installs: after pulling template updates, run `chezmoi init --apply` to regenerate your config prompts or add missing keys (for example `headless = false` and `android = false`) under the `[data]` section in `~/.config/chezmoi/chezmoi.toml` before running `chezmoi apply`.

### 2.4 Dynamic Brewfile Template
Create `Brewfile.tmpl`:
```ruby
# Generated Brewfile for {{ .chezmoi.hostname }}

# Core packages (always installed)
{{ include "Brewfile.core" }}

{{ if .packages.dev -}}
# Development tools
{{ include "Brewfile.dev" }}
{{- end }}

{{ if .packages.gui -}}
# GUI applications
{{ include "Brewfile.gui" }}
{{- end }}

{{ if .packages.android -}}
# Android development
{{ include "Brewfile.android" }}
{{- end }}
```

---

## Phase 3: Fish Shell Configuration (Modular)

### 3.1 Main Config (Minimal)
Create `dot_config/fish/config.fish.tmpl`:
```fish
# ~/.config/fish/config.fish
# Minimal config - all features in conf.d/

# Homebrew (Apple Silicon)
if test -x /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
end

# Version manager
mise activate fish | source

# Directory environments
direnv hook fish | source

# Prompt
starship init fish | source

# Smart cd
zoxide init fish | source

# Fuzzy finder
fzf --fish | source
```

### 3.2 Modular Configuration Files

#### `dot_config/fish/conf.d/00-homebrew.fish`
```fish
# Ensure Homebrew is available in new shells
if test -x /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
else if test -x /usr/local/bin/brew
    eval (/usr/local/bin/brew shellenv)
end
```

#### `dot_config/fish/conf.d/01-mise.fish`
```fish
# Activate mise so language/tool shims are ready
if type -q mise
    mise activate fish | source
end
```

#### `dot_config/fish/conf.d/02-direnv.fish`
```fish
# Enable direnv for per-project environment loading
if type -q direnv
    direnv hook fish | source
end
```

#### `dot_config/fish/conf.d/03-starship.fish`
```fish
# Prompt customization
if type -q starship
    starship init fish | source
end
```

#### `dot_config/fish/conf.d/04-paths.fish`
```fish
# Ensure user-installed CLIs are on PATH
fish_add_path ~/.npm-global/bin
fish_add_path ~/bin
fish_add_path ~/.local/bin
fish_add_path ~/.bun/bin
fish_add_path ~/.local/share/go/workspace/bin
```

---

## Phase 4: Version Management with mise

### 4.1 Global mise Configuration
Create `dot_config/mise/config.toml`:
```toml
# Global mise configuration for development environment
# Migration ID: 20250925-171224

[tools]
node = "24"
bun = "latest"
python = "3.13"
go = "latest"
rust = "stable"
java = "temurin-17"
uv = "latest"

[settings]
experimental = true
trusted_config_paths = [
    "~/Development/**",
    "~/workspace/**"
]
legacy_version_file = false
idiomatic_version_file_enable_tools = ["python", "node", "ruby"]
plugin_autoupdate_last_check_duration = "7d"
jobs = 4

[env]
MISE_FISH_AUTO_ACTIVATE = "1"
MISE_LOG_LEVEL = "info"
MISE_EXPERIMENTAL = "1"
EDITOR = "nvim"
VISUAL = "nvim"
MAKEFLAGS = "-j10"
CARGO_BUILD_JOBS = "10"
NODE_OPTIONS = "--max-old-space-size=8192"
BUN_INSTALL = "~/.bun"
GOPATH = "~/.local/share/go/workspace"
```

### 4.2 Project-Level Configuration
`workspace/dotfiles/templates/mise.toml` seeds new projects with opinionated tasks:
```toml
# Project-specific mise configuration template
# Copy to project root and customize as needed

[tools]
# Override global versions if needed
# node = "20"     # Use specific Node version
# python = "3.12" # Use specific Python version

[env]
# Project environment variables
PROJECT_NAME = "{{project_name}}"
ENVIRONMENT = "development"

[tasks.test]
description = "Run project tests"
run = """
if [ -f "package.json" ]; then
    npm test
elif [ -f "Cargo.toml" ]; then
    cargo test
elif [ -f "go.mod" ]; then
    go test ./...
elif [ -f "pytest.ini" ] || [ -f "setup.cfg" ]; then
    pytest
else
    echo "No test runner detected"
fi
"""

[tasks.lint]
description = "Run project linting"
run = """
if [ -f "package.json" ]; then
    npm run lint || npx eslint .
elif [ -f "Cargo.toml" ]; then
    cargo clippy
elif [ -f "go.mod" ]; then
    golangci-lint run
elif [ -f ".ruff.toml" ] || [ -f "pyproject.toml" ]; then
    ruff check .
else
    echo "No linter detected"
fi
"""

[tasks.format]
description = "Format project code"
run = """
if [ -f "package.json" ]; then
    npx prettier --write .
elif [ -f "Cargo.toml" ]; then
    cargo fmt
elif [ -f "go.mod" ]; then
    go fmt ./...
elif [ -f "pyproject.toml" ]; then
    black . && isort .
else
    echo "No formatter detected"
fi
"""

[tasks.dev]
description = "Start development server"
run = """
if [ -f "package.json" ]; then
    if [ -f "bun.lockb" ]; then
        bun dev
    else
        npm run dev
    fi
elif [ -f "Cargo.toml" ]; then
    cargo watch -x run
elif [ -f "go.mod" ]; then
    go run .
elif [ -f "manage.py" ]; then
    python manage.py runserver
else
    echo "No dev server detected"
fi
"""

[tasks.build]
description = "Build project"
run = """
if [ -f "package.json" ]; then
    if [ -f "bun.lockb" ]; then
        bun run build
    else
        npm run build
    fi
elif [ -f "Cargo.toml" ]; then
    cargo build --release
elif [ -f "go.mod" ]; then
    go build -o bin/$(basename $PWD)
elif [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
    python -m build
else
    echo "No build system detected"
fi
"""

[tasks.clean]
description = "Clean build artifacts"
run = """
rm -rf node_modules dist build target bin .pytest_cache .ruff_cache __pycache__ .coverage
echo "✓ Cleaned build artifacts"
"""
```

---

## Phase 5: Security with gopass + age

### 5.1 Initialize gopass with age
```bash
# Generate age key
mkdir -p ~/.config/age
age-keygen > ~/.config/age/key.txt
chmod 600 ~/.config/age/key.txt

# Initialize gopass
gopass init --crypto age

# Configure
gopass config autoclip false
gopass config notifications false
```

### 5.2 chezmoi Secret Integration
In templates, reference secrets:
```fish
# Example in 10-aliases.fish.tmpl
{{ if (gopass "dev/github_token") -}}
set -x GITHUB_TOKEN "{{ gopass "dev/github_token" }}"
{{- end }}
```

### 5.3 Project .envrc Template
Create `dot_envrc.tmpl` for project templates:
```bash
# Load mise tools
use mise

# Add project directories to PATH
PATH_add bin
PATH_add node_modules/.bin

# Load local secrets (not in git)
[[ -f .env.local ]] && dotenv .env.local

# Pull secrets from gopass (if available)
if command -v gopass &> /dev/null; then
    export DATABASE_URL="$(gopass show dev/database_url 2>/dev/null || echo '')"
    export API_KEY="$(gopass show dev/api_key 2>/dev/null || echo '')"
fi

# Android paths (modern layout)
{{ if .packages.android -}}
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
{{- end }}
```

---

## Phase 6: Containerization with OrbStack

### 6.1 OrbStack Configuration
```bash
# Install via Brewfile (already included)
# Launch OrbStack
open -a OrbStack

# Verify Docker compatibility
docker --version
docker compose version
```

### 6.2 Optimal Settings
Configure in OrbStack preferences:
- Memory: Dynamic (auto-adjusts, max 24GB)
- CPUs: 10-12 cores
- Disk: 100GB
- Enable Rosetta for x86 emulation
- File sharing: Use "Fast" mode

---

## Phase 7: Android Development

### 7.1 Android Studio Setup
```bash
# Open Android Studio (installed via Brewfile)
open -a "Android Studio"

# Setup Wizard:
# 1. Custom installation
# 2. SDK location: ~/Library/Android/sdk
# 3. Install all SDK components
# 4. Allocate 8GB RAM for IDE
```

### 7.2 AVD Configuration (M3 Optimized)
Create AVD with these settings:
- Device: Pixel 8 Pro
- System Image: **Android 14 - arm64-v8a** (critical!)
- Graphics: **Hardware - GLES 2.0**
- RAM: 8GB
- VM Heap: 512MB
- Disable "Device Frame"

### 7.3 Gradle Optimization
Create `~/.gradle/gradle.properties`:
```properties
# M3 Max optimizations
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configuration-cache=true
org.gradle.jvmargs=-Xmx8g -XX:MaxMetaspaceSize=2g -XX:+UseG1GC
org.gradle.workers.max=12
```

---

## Phase 8: Bootstrap Script

### 8.1 Minimal Bootstrap
Create `install.sh` in chezmoi repo:
```bash
#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Bootstrapping M3 Max development environment..."

# Install Homebrew
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install chezmoi and apply dotfiles
if ! command -v chezmoi &> /dev/null; then
    echo "Installing chezmoi..."
    brew install chezmoi
fi

# Apply chezmoi (this handles everything else)
echo "Applying dotfiles..."
chezmoi init --apply git@github.com:yourusername/dotfiles.git

# Install Brewfile packages
echo "Installing packages..."
brew bundle --file="$(chezmoi source-path)/Brewfile"

# Set fish as default shell
if [[ "$SHELL" != *"fish"* ]]; then
    echo "Setting fish as default shell..."
    echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
    chsh -s /opt/homebrew/bin/fish
fi

# Install mise tools
echo "Installing language runtimes..."
mise install

# macOS settings
echo "Configuring macOS..."
# Disable press-and-hold for keys
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true
# Enable Touch ID for sudo
sudo bash -c 'echo "auth sufficient pam_tid.so" > /etc/pam.d/sudo_local'

echo "✅ Setup complete! Please restart your terminal."
```

---

## Phase 9: Project Templates

### 9.1 Create Project Template Function
Add to `dot_config/fish/conf.d/20-functions.fish`:
```fish
function new-project
    set -l type $argv[1]
    set -l name $argv[2]
    
    mkcd $DEV_HOME/$name
    git init
    
    switch $type
        case node
            echo "[tools]
node = \"24\"
bun = \"latest\"
pnpm = \"latest\"" > .mise.toml
            bun init -y
            
        case python
            echo "[tools]
python = \"3.13\"
uv = \"latest\"" > .mise.toml
            uv init
            
        case go
            echo "[tools]
go = \"latest\"" > .mise.toml
            go mod init github.com/$USER/$name
            
        case rust
            echo "[tools]
rust = \"stable\"" > .mise.toml
            cargo init
            
        case android
            echo "[tools]
node = \"24\"
java = \"17\"" > .mise.toml
            # Android project setup would go here
            
        case '*'
            echo "Unknown project type: $type"
            echo "Available types: node, python, go, rust, android"
            return 1
    end
    
    echo "use mise
PATH_add bin" > .envrc
    
    direnv allow
    echo "✅ Created $type project: $name"
end
```

---

## Phase 10: System Optimization

### 10.1 Performance Tuning
```bash
# Spotlight exclusions (add via System Settings → Spotlight → Privacy)
~/Development
~/.gradle
~/Library/Android
node_modules

# Time Machine exclusions
sudo tmutil addexclusion -p ~/Development
sudo tmutil addexclusion -p ~/.gradle
sudo tmutil addexclusion -p ~/Library/Android/sdk
```

### 10.2 M3 Max Specific Settings
```bash
# Enable High Power Mode (via System Settings → Battery)
sudo pmset -a highpowermode 1

# Increase file descriptor limits
echo "limit maxfiles 65536 200000" | sudo tee -a /etc/launchd.conf
```

---

## Workflow Commands Reference

### Daily Operations
```fish
# Update everything
chezmoi update                    # Pull latest dotfiles
brewup                            # Update Homebrew packages
mise upgrade                      # Update language runtimes

# Create projects
new-project node my-api          # Node.js project
new-project python ml-project    # Python project
new-project rust cli-tool        # Rust project

# Project navigation
dev                               # Go to ~/Development
z project-name                    # Jump to project (zoxide)

# Secret management
gopass insert dev/api_key        # Store secret
gopass show dev/api_key          # Retrieve secret
gopass generate dev/token 32     # Generate secure token

# Container operations
docker compose up -d              # Start services
orbctl restart                    # Restart OrbStack

# Android development
emulator @Pixel_8_Pro_API_34    # Launch AVD
adb devices                      # List devices
./gradlew assembleDebug         # Build APK
```

---

## Verification Checklist

```fish
# System check
mise doctor
chezmoi doctor
direnv status
docker info | grep -i orbstack

# Version check
node --version    # 24.x (global default)
python --version  # 3.13.x
bun --version
go version
rustc --version

# Test project isolation
cd ~/Development/project1  # Auto-loads environment
cd ~/Development/project2  # Auto-switches versions

# Verify secrets
gopass list
```

---

## Key Architectural Decisions

### Core Philosophy: Thin Machine, Thick Projects
1. **chezmoi for machine baseline**: Only tools, not versions - keeps machine layer thin and updateable
2. **Projects own version truth**: Every repo contains `.mise.toml`, lockfiles, and `VERSION_POLICY.md`
3. **Two rails strategy**: Stable (LTS) for production, Fast (latest) for experimentation
4. **Automated updates via Renovate**: Weekly PRs with changelogs, CI-gated merges
5. **mise + direnv synergy**: Zero-friction project isolation with automatic environment switching
6. **gopass + age**: Modern secrets that are pulled at edges, never stored globally
7. **OrbStack**: Native Apple Silicon performance for containerization

### Implementation Standards
- **Lockfiles everywhere**: `pnpm-lock.yaml`, `uv.lock`, `Cargo.lock`, `go.sum` - all committed
- **CI as guardrail**: Every change validated before merge, versions recorded
- **LKG tags**: Automatic "last known good" tags for easy rollback
- **Project templates**: New projects start compliant with `.mise.toml`, `.envrc`, `renovate.json`

This architecture provides:
- **Reproducibility**: Projects are self-contained and version-locked
- **Agility**: Machine tools update freely, project versions controlled
- **Security**: Hardware-backed keys, scoped secrets
- **Performance**: Native ARM64 throughout, optimized for M3
- **Automation**: Renovate + CI handle the update cycle
- **Agentic Readiness**: Predictable structure, machine-readable version metadata

## Related Documents

This setup is supported by additional configuration files:
1. **[Renovate Configuration](renovate.json)** - Automated dependency management
2. **[CI Workflow](.github/workflows/ci.yml)** - Multi-language testing with mise
3. **[Version Policy](VERSION_POLICY.md)** - Complete versioning standards
4. **[chezmoi Structure](docs/chezmoi-structure.md)** - Dotfiles organization guide

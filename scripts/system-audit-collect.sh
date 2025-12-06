#!/usr/bin/env bash
# File: scripts/system-audit-collect.sh
# Purpose: Collect complete system audit data
# Version: 2.0.0 - Includes checks for the three critical "invisible" failure modes

set -euo pipefail

AUDIT_DIR="/tmp/system-audit-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$AUDIT_DIR"

echo "System Configuration Audit v2.0.0"
echo "=================================="
echo "Output directory: $AUDIT_DIR"
echo ""
echo "This audit includes checks for:"
echo "  1. Login Shell Loophole (macOS path_helper reset)"
echo "  2. Universal Variable Ghost (fish_user_paths)"
echo "  3. Architecture Split (Rosetta vs ARM64)"
echo ""

# Layer 1: iTerm2 & tmux
echo "Layer 1: iTerm2 & tmux..."
{
  echo "=== Terminal Info ==="
  echo "TERM: $TERM"
  echo "TERM_PROGRAM: ${TERM_PROGRAM:-Not set}"

  echo -e "\n=== THE LOGIN SHELL LOOPHOLE CHECK (CRITICAL) ==="
  fish -c 'status is-login && echo "⚠️  LOGIN SHELL - PATH may be reset by macOS path_helper" || echo "✅ Non-login shell"'
  echo ""
  echo "Shell Level (SHLVL): $SHLVL"
  echo "  Expected: 1 in iTerm2, 2 inside tmux"
  if [ -n "$TMUX" ]; then
    echo "  Context: Inside tmux"
    [ "$SHLVL" -eq 1 ] && echo "  ⚠️  WARNING: SHLVL should be 2 inside tmux! tmux may be launching login shells."
  else
    echo "  Context: Direct in iTerm2"
  fi
  echo ""
  if command -v tmux &> /dev/null; then
    echo "tmux configuration:"
    tmux show-options -g default-command 2>/dev/null || echo "  default-command: Not set (uses default shell)"
    tmux show-options -g default-shell 2>/dev/null || echo "  default-shell: Not set"
  fi

  echo -e "\n=== tmux Sessions ==="
  tmux list-sessions 2>/dev/null || echo "No tmux sessions"

  echo -e "\n=== Tmux Plugins (TPM) ==="
  ls -la ~/.tmux/plugins/ 2>/dev/null || echo "No TPM plugins found"

  echo -e "\n=== iTerm2 Preferences ==="
  echo "Location: ~/Library/Preferences/com.googlecode.iterm2.plist"
  echo "Manual check required for:"
  echo "  - Font configuration (Settings → Profiles → Text)"
  echo "  - Key mappings (Settings → Profiles → Keys)"
  echo "  - Shell launch command (Settings → Profiles → General)"
} > "$AUDIT_DIR/layer1-iterm2-tmux.txt"

# Layer 2: mise
echo "Layer 2: mise..."
{
  echo "=== Global mise config ==="
  cat ~/.config/mise/config.toml

  echo -e "\n=== Local mise config ==="
  cat .mise.toml 2>/dev/null || echo "No local .mise.toml"

  echo -e "\n=== mise list ==="
  mise list

  echo -e "\n=== mise current ==="
  mise current

  echo -e "\n=== PATH hierarchy ==="
  echo "$PATH" | tr ' ' '\n' | nl

  echo -e "\n=== Shim resolution ==="
  echo "node: $(which -a node 2>/dev/null || echo 'Not found')"
  echo "python: $(which -a python 2>/dev/null || echo 'Not found')"
  echo "python3: $(which -a python3 2>/dev/null || echo 'Not found')"
  echo "ruby: $(which -a ruby 2>/dev/null || echo 'Not found')"
  echo "go: $(which -a go 2>/dev/null || echo 'Not found')"

  echo -e "\n=== mise doctor ==="
  mise doctor
} > "$AUDIT_DIR/layer2-mise.txt"

# Layer 3: Fish
echo "Layer 3: Fish..."
{
  echo "=== Fish config files ==="
  ls -1 ~/.config/fish/config.fish
  ls -1 ~/.config/fish/conf.d/*.fish 2>/dev/null | sort

  echo -e "\n=== Functions ==="
  fish -c "functions" | head -50

  echo -e "\n=== Abbreviations ==="
  fish -c "abbr --show"

  echo -e "\n=== Environment variables ==="
  fish -c "set -x | grep -E 'PATH|NODE|PYTHON|GO|RUST|MISE|HOMEBREW|EDITOR|VISUAL'"

  echo -e "\n=== Universal variables ==="
  fish -c "set -U" | head -30

  echo -e "\n=== THE UNIVERSAL VARIABLE 'GHOST' CHECK (CRITICAL) ==="
  echo "fish_user_paths (Universal Path - stored in fish_variables):"
  fish -c 'echo $fish_user_paths'
  echo ""
  echo "⚠️  WARNING: These paths are PERMANENT and persist across restarts"
  echo "    They are stored in ~/.config/fish/fish_variables (binary file)"
  echo "    They OVERRIDE your config files without appearing in them"
  echo "    If you see bad paths here, clear with: set -U fish_user_paths"

  echo -e "\n=== PATH modifications in configs ==="
  grep -n "fish_add_path\|set -x PATH" ~/.config/fish/config.fish ~/.config/fish/conf.d/*.fish 2>/dev/null || echo "No PATH modifications found"

  echo -e "\n=== Secret sourcing ==="
  grep -n "gopass\|op\|1password\|\.env" ~/.config/fish/conf.d/*.fish 2>/dev/null || echo "No secret sourcing found"
} > "$AUDIT_DIR/layer3-fish.txt"

# Profile Fish startup (with timeout for safety)
echo "Profiling Fish startup..."
if command -v timeout &> /dev/null; then
  timeout 5s fish --profile "$AUDIT_DIR/fish_startup.prof" -c exit 2>/dev/null || echo "WARNING: Profiling timed out (shell config may be broken)" > "$AUDIT_DIR/fish_startup.prof"
elif command -v gtimeout &> /dev/null; then
  gtimeout 5s fish --profile "$AUDIT_DIR/fish_startup.prof" -c exit 2>/dev/null || echo "WARNING: Profiling timed out (shell config may be broken)" > "$AUDIT_DIR/fish_startup.prof"
else
  fish --profile "$AUDIT_DIR/fish_startup.prof" -c exit
fi
sort -k2 -rn "$AUDIT_DIR/fish_startup.prof" 2>/dev/null | head -20 > "$AUDIT_DIR/fish_startup_top20.txt"

# Layer 4: chezmoi
echo "Layer 4: chezmoi..."
{
  echo "=== Unmanaged files ==="
  chezmoi unmanaged

  echo -e "\n=== Status ==="
  chezmoi status

  echo -e "\n=== Diff ==="
  chezmoi diff

  echo -e "\n=== chezmoi data ==="
  chezmoi data

  echo -e "\n=== .chezmoiignore ==="
  cat ~/.local/share/chezmoi/.chezmoiignore 2>/dev/null || echo "No .chezmoiignore file"

  echo -e "\n=== Source git status ==="
  cd ~/.local/share/chezmoi && git status
} > "$AUDIT_DIR/layer4-chezmoi.txt"

# System info
echo "Collecting system info..."
{
  echo "=== System ==="
  uname -a
  sw_vers

  echo -e "\n=== THE ARCHITECTURE SPLIT CHECK (Apple Silicon) ==="
  echo "Architecture (native vs Rosetta):"
  arch
  echo "Expected: arm64 (native) or i386 (Rosetta emulation)"
  echo ""
  echo "Active Homebrew:"
  which brew
  echo "Expected: /opt/homebrew/bin/brew (native) or /usr/local/bin/brew (Intel)"
  echo ""
  echo "Note: If running under Rosetta, mise may compile wrong binaries"
  echo "      This causes performance hits or 'symbol not found' errors"

  echo -e "\n=== Homebrew ==="
  brew --version
  brew --prefix
  echo "Homebrew architecture:"
  file $(which brew)

  echo -e "\n=== Installed formulae (first 50) ==="
  brew list --formula | head -50

  echo -e "\n=== Installed casks (first 30) ==="
  brew list --cask | head -30
} > "$AUDIT_DIR/system-info.txt"

echo ""
echo "Audit data collection complete!"
echo "Results in: $AUDIT_DIR"
echo ""
echo "Files created:"
ls -lh "$AUDIT_DIR"
echo ""
echo "Next steps:"
echo "  1. Review all .txt files in $AUDIT_DIR"
echo "  2. Fill out Phase 3 Information Report template"
echo "  3. Identify conflicts and drift"
echo "  4. Create remediation plan"

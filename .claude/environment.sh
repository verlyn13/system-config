#!/usr/bin/env bash
# Project-specific environment variables for Claude

# Source this file before running Claude commands
# Example: source .claude/environment.sh && claude

# Project identification
export CLAUDE_PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export CLAUDE_PROJECT_CONFIG="$CLAUDE_PROJECT_ROOT/.claude/config.json"

# Add project-specific aliases
alias claude-project='bash "$CLAUDE_PROJECT_ROOT/.claude/claude-wrapper.sh"'
alias claude-config='jq . "$CLAUDE_PROJECT_CONFIG"'
alias claude-edit-config='$EDITOR "$CLAUDE_PROJECT_CONFIG"'

echo "Claude project environment loaded for: $(basename "$CLAUDE_PROJECT_ROOT")"
echo "Use 'claude-project' to run Claude with project configuration"

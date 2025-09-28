#!/usr/bin/env bash
# Project-specific Claude wrapper script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$SCRIPT_DIR/config.json"

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Claude config file not found at $CONFIG_FILE"
    echo "Run: claude-project-setup.sh to initialize project configuration"
    exit 1
fi

# Parse configuration
ALLOWED_TOOLS=$(jq -r '.allowedTools | if . == ["*"] then "*" else join(",") end' "$CONFIG_FILE" 2>/dev/null || echo "")
DISALLOWED_TOOLS=$(jq -r '.disallowedTools | join(",")' "$CONFIG_FILE" 2>/dev/null || echo "")
VERBOSE=$(jq -r '.customInstructions.preferences.verboseMode // false' "$CONFIG_FILE" 2>/dev/null || echo "false")

# Build claude command arguments
CLAUDE_ARGS=()

if [[ -n "$ALLOWED_TOOLS" && "$ALLOWED_TOOLS" != "null" ]]; then
    CLAUDE_ARGS+=(--allowedTools "$ALLOWED_TOOLS")
fi

if [[ -n "$DISALLOWED_TOOLS" && "$DISALLOWED_TOOLS" != "null" ]]; then
    CLAUDE_ARGS+=(--disallowedTools "$DISALLOWED_TOOLS")
fi

if [[ "$VERBOSE" == "true" ]]; then
    CLAUDE_ARGS+=(--verbose)
fi

# Change to project directory
cd "$PROJECT_DIR"

# Execute claude with project-specific configuration
exec claude "${CLAUDE_ARGS[@]}" "$@"

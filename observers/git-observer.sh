#!/bin/bash
# Simplified Git Observer - outputs NDJSON for git repository status

set -euo pipefail

# Arguments
PROJECT_PATH="${1:?Project path required}"
PROJECT_ID="${2:?Project ID required}"

# Generate metadata
RUN_ID=$(uuidgen | tr '[:upper:]' '[:lower:]' 2>/dev/null || echo "$(date +%s)-$$")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Check if directory exists
if [[ ! -d "$PROJECT_PATH" ]]; then
    echo "{\"apiVersion\":\"obs.v1\",\"run_id\":\"$RUN_ID\",\"timestamp\":\"$TIMESTAMP\",\"project_id\":\"$PROJECT_ID\",\"observer\":\"git\",\"status\":\"error\",\"error\":\"Project path does not exist\"}"
    exit 0
fi

# Check if it's a git repo
if [[ ! -d "$PROJECT_PATH/.git" ]]; then
    echo "{\"apiVersion\":\"obs.v1\",\"run_id\":\"$RUN_ID\",\"timestamp\":\"$TIMESTAMP\",\"project_id\":\"$PROJECT_ID\",\"observer\":\"git\",\"status\":\"skip\",\"message\":\"Not a git repository\"}"
    exit 0
fi

# Gather git information (with safe defaults)
cd "$PROJECT_PATH" 2>/dev/null || exit 1

BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "unknown")
COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "none")
DIRTY_COUNT=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ' || echo "0")
REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")

# Determine status
if [[ "$DIRTY_COUNT" -gt 0 ]]; then
    STATUS="dirty"
else
    STATUS="clean"
fi

# Output single line NDJSON
echo "{\"apiVersion\":\"obs.v1\",\"run_id\":\"$RUN_ID\",\"timestamp\":\"$TIMESTAMP\",\"project_id\":\"$PROJECT_ID\",\"observer\":\"git\",\"status\":\"ok\",\"data\":{\"branch\":\"$BRANCH\",\"commit\":\"$COMMIT\",\"dirty_files\":$DIRTY_COUNT,\"repo_status\":\"$STATUS\",\"remote_url\":\"$REMOTE_URL\"}}"
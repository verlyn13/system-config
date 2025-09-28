#!/bin/bash
# Repo Observer - Safe, read-only git repository analysis
# Outputs NDJSON conforming to observer.output.schema.json

set -euo pipefail

# Configuration
readonly PROJECT_PATH="${1:?Project path required}"
readonly PROJECT_ID="${2:?Project ID required}"
readonly RUN_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
readonly TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
readonly TIMEOUT=5

# Safety: Validate path is within allowed roots
validate_path() {
    local path="$1"
    local allowed_roots=(
        "$HOME/Development/personal"
        "$HOME/Development/work"
        "$HOME/Development/business"
        "$HOME/workspace/projects"
    )

    local realpath=$(realpath "$path")
    for root in "${allowed_roots[@]}"; do
        if [[ "$realpath" == "$root"* ]]; then
            return 0
        fi
    done

    echo "Error: Path not in allowed roots: $path" >&2
    exit 1
}

# Execute git command with timeout
git_exec() {
    timeout "$TIMEOUT" git -C "$PROJECT_PATH" "$@" 2>/dev/null || echo ""
}

# Redact potential credentials from URLs (user:pass@ or token@)
redact_url() {
    local url="$1"
    # Remove userinfo if present: scheme://userinfo@host -> scheme://host
    echo "$url" | sed -E 's#^(https?://)[^/@]+@#\1#'
}

# Get repository status
get_repo_status() {
    local branch=$(git_exec branch --show-current)
    local status=$(git_exec status --porcelain=v2 -b)

    # Parse ahead/behind
    local ahead=0
    local behind=0
    if [[ "$status" =~ \#\ branch\.ab\ \+([0-9]+)\ -([0-9]+) ]]; then
        ahead="${BASH_REMATCH[1]}"
        behind="${BASH_REMATCH[2]}"
    fi

    # Count dirty and untracked files
    local dirty=$(echo "$status" | grep -c '^[12] ' || true)
    local untracked=$(echo "$status" | grep -c '^? ' || true)

    # Check if HEAD is signed
    local signed=0
    if git_exec verify-commit HEAD &>/dev/null; then
        signed=1
    fi

    # Get remote URL
    local repo_url=$(git_exec config --get remote.origin.url || echo "")
    # Redact any embedded credentials
    repo_url=$(redact_url "$repo_url")

    echo "{
        \"branch\": \"$branch\",
        \"ahead\": $ahead,
        \"behind\": $behind,
        \"dirty\": $dirty,
        \"untracked\": $untracked,
        \"signed\": $signed,
        \"url\": \"$repo_url\"
    }"
}

# Determine status based on metrics
determine_status() {
    local behind="$1"
    local dirty="$2"

    if [[ "$behind" -gt 10 ]] || [[ "$dirty" -gt 20 ]]; then
        echo "fail"
    elif [[ "$behind" -gt 0 ]] || [[ "$dirty" -gt 0 ]]; then
        echo "warn"
    else
        echo "ok"
    fi
}

# Main execution
main() {
    validate_path "$PROJECT_PATH"

    local start_time=$(date +%s%3N)

    # Check if directory exists and is a git repo
    if [[ ! -d "$PROJECT_PATH/.git" ]]; then
        cat <<EOF
{
    "apiVersion": "obs.v1",
    "run_id": "$RUN_ID",
    "timestamp": "$TIMESTAMP",
    "project_id": "$PROJECT_ID",
    "observer": "repo",
    "summary": "Not a git repository",
    "metrics": {"error": 1},
    "status": "fail",
    "error": {
        "code": "NOT_GIT_REPO",
        "message": "Directory is not a git repository"
    }
}
EOF
        exit 0
    fi

    # Get repository information
    local repo_info=$(get_repo_status)
    local branch=$(echo "$repo_info" | jq -r '.branch')
    local ahead=$(echo "$repo_info" | jq -r '.ahead')
    local behind=$(echo "$repo_info" | jq -r '.behind')
    local dirty=$(echo "$repo_info" | jq -r '.dirty')
    local untracked=$(echo "$repo_info" | jq -r '.untracked')
    local signed=$(echo "$repo_info" | jq -r '.signed')
    local url=$(echo "$repo_info" | jq -r '.url')

    # Calculate latency
    local end_time=$(date +%s%3N)
    local latency=$((end_time - start_time))

    # Determine overall status
    local status=$(determine_status "$behind" "$dirty")

    # Create summary
    local summary="Branch: $branch, ${ahead}↑ ${behind}↓, ${dirty} dirty, ${untracked} untracked"

    # Output NDJSON
    cat <<EOF
{
    "apiVersion": "obs.v1",
    "run_id": "$RUN_ID",
    "timestamp": "$TIMESTAMP",
    "project_id": "$PROJECT_ID",
    "observer": "repo",
    "summary": "$summary",
    "metrics": {
        "ahead": $ahead,
        "behind": $behind,
        "dirty_files": $dirty,
        "untracked": $untracked,
        "signed_head": $signed,
        "latency_ms": $latency
    },
    "status": "$status",
    "links": {
        "repo": "$url"
    }
}
EOF
}

# Run main function
main

#!/bin/bash
# Observation Runner - Orchestrates project observers
# Usage: obs-run.sh [--project <id>] [--observers <list>] [--all]

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OBSERVERS_DIR="$SCRIPT_DIR/../observers"
readonly REGISTRY_PATH="$HOME/.local/share/devops-mcp/project-registry.json"
readonly OUTPUT_DIR="$HOME/.local/share/devops-mcp/observations"
readonly LOG_FILE="$HOME/.local/share/devops-mcp/logs/obs-run.log"

# Default observers
readonly DEFAULT_OBSERVERS="repo deps"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$(dirname "$LOG_FILE")"

# Parse command line arguments
parse_args() {
    PROJECT_ID=""
    OBSERVERS="$DEFAULT_OBSERVERS"
    RUN_ALL=false
    SCHEDULE=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --project|-p)
                PROJECT_ID="$2"
                shift 2
                ;;
            --observers|-o)
                OBSERVERS="$2"
                shift 2
                ;;
            --all|-a)
                RUN_ALL=true
                shift
                ;;
            --schedule|-s)
                SCHEDULE="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                show_help
                exit 1
                ;;
        esac
    done
}

# Show help
show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Run observers for projects to collect metrics and status.

Options:
    -p, --project <id>      Run for specific project ID
    -o, --observers <list>  Space-separated list of observers (default: repo deps)
    -a, --all              Run for all discovered projects
    -s, --schedule <type>   Schedule type (hourly, daily, weekly)
    -h, --help             Show this help message

Examples:
    $(basename "$0") --project github:personal/devops-mcp
    $(basename "$0") --all --observers "repo deps build"
    $(basename "$0") --schedule hourly

Available observers:
    repo    - Repository status (branch, commits, dirty files)
    deps    - Dependencies analysis (outdated, vulnerable)
    build   - Build health (if implemented)
    quality - Code quality metrics (if implemented)
EOF
}

# Load project registry
load_registry() {
    if [[ ! -f "$REGISTRY_PATH" ]]; then
        echo "Error: Project registry not found. Run project discovery first." >&2
        exit 1
    fi

    cat "$REGISTRY_PATH"
}

# Get project path from registry
get_project_path() {
    local project_id="$1"
    local registry="$2"

    echo "$registry" | jq -r ".projects[] | select(.id == \"$project_id\") | .path"
}

# Run observer for a project
run_observer() {
    local observer="$1"
    local project_id="$2"
    local project_path="$3"

    local observer_script="$OBSERVERS_DIR/${observer}-observer.sh"

    if [[ ! -x "$observer_script" ]]; then
        echo "Warning: Observer script not found or not executable: $observer_script" >&2
        return 1
    fi

    # Run observer and capture output
    local output
    if output=$("$observer_script" "$project_path" "$project_id" 2>&1); then
        echo "$output"
        return 0
    else
        # Create error output
        cat <<EOF
{
    "apiVersion": "obs.v1",
    "run_id": "$(uuidgen | tr '[:upper:]' '[:lower:]')",
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "project_id": "$project_id",
    "observer": "$observer",
    "summary": "Observer failed",
    "metrics": {"error": 1},
    "status": "fail",
    "error": {
        "code": "OBSERVER_FAILED",
        "message": "Observer execution failed"
    }
}
EOF
        return 1
    fi
}

# Save observation to file
save_observation() {
    local project_id="$1"
    local observation="$2"

    local project_dir="$OUTPUT_DIR/$(echo "$project_id" | tr ':/' '__')"
    mkdir -p "$project_dir"

    local output_file="$project_dir/observations.ndjson"

    # Append to NDJSON file (compact)
    if command -v jq >/dev/null 2>&1; then
        echo "$observation" | jq -c . >> "$output_file"
        echo "$observation" | jq . > "$project_dir/latest.json"
    else
        # Fallback: remove newlines to approximate compact JSON
        echo "$observation" | tr -d '\n' >> "$output_file"
        echo "$observation" > "$project_dir/latest.json"
    fi
}

# Run observers for a single project
process_project() {
    local project_id="$1"
    local project_path="$2"
    local observers="$3"

    echo "🔍 Processing project: $project_id" >&2

    for observer in $observers; do
        echo "  Running observer: $observer" >&2

        if observation=$(run_observer "$observer" "$project_id" "$project_path"); then
            # Save observation
            save_observation "$project_id" "$observation"

            # Extract status for logging
            local status=$(echo "$observation" | jq -r '.status')
            echo "  ✓ $observer: $status" >&2
        else
            echo "  ✗ $observer: failed" >&2
        fi
    done
}

# Process scheduled observations
process_schedule() {
    local schedule="$1"

    case "$schedule" in
        hourly)
            OBSERVERS="repo deps"
            ;;
        daily)
            OBSERVERS="repo deps build quality"
            ;;
        weekly)
            OBSERVERS="repo deps build quality security sbom"
            ;;
        *)
            echo "Unknown schedule: $schedule" >&2
            exit 1
            ;;
    esac

    RUN_ALL=true
}

# Main execution
main() {
    parse_args "$@"

    # Handle scheduled runs
    if [[ -n "$SCHEDULE" ]]; then
        process_schedule "$SCHEDULE"
    fi

    # Load registry
    local registry=$(load_registry)

    # Log run start
    echo "[$(date)] Starting observation run" >> "$LOG_FILE"

    if [[ "$RUN_ALL" == true ]]; then
        # Run for all projects
        echo "📊 Running observers for all projects..." >&2

        local project_count=$(echo "$registry" | jq '.projects | length')
        local current=0

        echo "$registry" | jq -r '.projects[] | "\(.id)|\(.path)"' | while IFS='|' read -r id path; do
            current=$((current + 1))
            echo "[$current/$project_count] $id" >&2
            process_project "$id" "$path" "$OBSERVERS"
        done
    elif [[ -n "$PROJECT_ID" ]]; then
        # Run for specific project
        local project_path=$(get_project_path "$PROJECT_ID" "$registry")

        if [[ -z "$project_path" ]]; then
            echo "Error: Project not found: $PROJECT_ID" >&2
            exit 1
        fi

        process_project "$PROJECT_ID" "$project_path" "$OBSERVERS"
    else
        echo "Error: Specify --project <id> or --all" >&2
        show_help
        exit 1
    fi

    # Log run complete
    echo "[$(date)] Observation run complete" >> "$LOG_FILE"
    echo "✅ Observation run complete" >&2
}

# Run main
main "$@"

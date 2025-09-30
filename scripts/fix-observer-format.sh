#!/bin/bash
# Fix observer scripts to output proper NDJSON format

set -euo pipefail

OBSERVERS_DIR="$(dirname "$0")/../observers"

echo "Fixing observer output format to NDJSON..."

for observer_file in "$OBSERVERS_DIR"/*.sh; do
    echo "Processing: $(basename "$observer_file")"

    # Create backup
    cp "$observer_file" "${observer_file}.backup"

    # Replace multi-line cat <<EOF with single-line JSON using jq -c
    # This is complex, so we'll use a more targeted approach

    # First, let's create a simple test to see current format
    if grep -q 'cat <<EOF' "$observer_file"; then
        echo "  - Found heredoc JSON output, needs conversion to NDJSON"

        # Use sed to replace the heredoc patterns with jq -c
        # This is tricky because the JSON spans multiple lines

        # For now, let's create new fixed versions
        case "$(basename "$observer_file")" in
            repo-observer.sh)
                cat > "${observer_file}.fixed" << 'SCRIPT_END'
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
        "$HOME/Development"
        "$HOME/workspace"
        "/tmp/claude"
    )

    for root in "${allowed_roots[@]}"; do
        if [[ "$path" == "$root"* ]]; then
            return 0
        fi
    done

    echo "Error: Path outside allowed roots" >&2
    exit 1
}

# Check if directory is a git repository
is_git_repo() {
    [[ -d "$1/.git" ]] || git -C "$1" rev-parse --git-dir >/dev/null 2>&1
}

# Safe git command wrapper with timeout
safe_git() {
    timeout "$TIMEOUT" git -C "$PROJECT_PATH" "$@" 2>/dev/null || echo ""
}

# Get repository info
get_repo_info() {
    local branch=$(safe_git symbolic-ref --short HEAD || echo "detached")
    local ahead=$(safe_git rev-list --count HEAD@{upstream}..HEAD 2>/dev/null || echo 0)
    local behind=$(safe_git rev-list --count HEAD..HEAD@{upstream} 2>/dev/null || echo 0)
    local dirty=$(safe_git status --porcelain | wc -l | tr -d ' ')
    local untracked=$(safe_git ls-files --others --exclude-standard | wc -l | tr -d ' ')
    local signed=$(safe_git log -1 --format='%G?' | grep -q 'G' && echo true || echo false)
    local url=$(safe_git config --get remote.origin.url || echo "none")

    # Output as compact JSON
    echo "{\"branch\":\"$branch\",\"ahead\":$ahead,\"behind\":$behind,\"dirty\":$dirty,\"untracked\":$untracked,\"signed\":$signed,\"url\":\"$url\"}"
}

# Main execution
main() {
    # Validate path
    validate_path "$PROJECT_PATH"

    # Check if git repo
    if ! is_git_repo "$PROJECT_PATH"; then
        # Output single line JSON for non-git repo
        jq -nc \
            --arg run_id "$RUN_ID" \
            --arg timestamp "$TIMESTAMP" \
            --arg project_id "$PROJECT_ID" \
            '{
                apiVersion: "obs.v1",
                run_id: $run_id,
                timestamp: $timestamp,
                project_id: $project_id,
                observer: "repo",
                summary: "Not a git repository",
                metrics: {error: 1},
                status: "fail",
                error: {
                    code: "NOT_GIT_REPO",
                    message: "Directory is not a git repository"
                }
            }'
        exit 0
    fi

    # Gather repository information
    local repo_info=$(get_repo_info)

    # Parse JSON values
    local branch=$(echo "$repo_info" | jq -r '.branch')
    local ahead=$(echo "$repo_info" | jq -r '.ahead')
    local behind=$(echo "$repo_info" | jq -r '.behind')
    local dirty=$(echo "$repo_info" | jq -r '.dirty')
    local untracked=$(echo "$repo_info" | jq -r '.untracked')
    local signed=$(echo "$repo_info" | jq -r '.signed')
    local url=$(echo "$repo_info" | jq -r '.url')

    # Calculate summary
    local summary="Branch: $branch"
    [[ $dirty -gt 0 ]] && summary="$summary, $dirty uncommitted changes"
    [[ $ahead -gt 0 ]] && summary="$summary, $ahead commits ahead"
    [[ $behind -gt 0 ]] && summary="$summary, $behind commits behind"

    # Output compact NDJSON
    jq -nc \
        --arg run_id "$RUN_ID" \
        --arg timestamp "$TIMESTAMP" \
        --arg project_id "$PROJECT_ID" \
        --arg summary "$summary" \
        --arg branch "$branch" \
        --argjson ahead "$ahead" \
        --argjson behind "$behind" \
        --argjson dirty "$dirty" \
        --argjson untracked "$untracked" \
        --argjson signed "$signed" \
        --arg url "$url" \
        '{
            apiVersion: "obs.v1",
            run_id: $run_id,
            timestamp: $timestamp,
            project_id: $project_id,
            observer: "repo",
            summary: $summary,
            metrics: {
                branch: $branch,
                ahead: $ahead,
                behind: $behind,
                dirty_files: $dirty,
                untracked_files: $untracked,
                signed_commits: $signed
            },
            status: "ok",
            metadata: {
                remote_url: $url,
                observation_time: $timestamp
            }
        }'
}

# Run main function
main
SCRIPT_END
                chmod +x "${observer_file}.fixed"
                mv "${observer_file}.fixed" "$observer_file"
                echo "  ✓ Fixed repo-observer.sh"
                ;;

            build-observer.sh|deps-observer.sh|quality-observer.sh|sbom-observer.sh)
                echo "  - Skipping $(basename "$observer_file") for now (needs similar fix)"
                ;;
        esac
    else
        echo "  - Already using proper format or needs manual review"
    fi
done

echo "Done! Testing repo observer output format..."

# Test the fixed observer
PROJECT_PATH="/Users/verlyn13/Development/personal/system-setup-update"
PROJECT_ID="72f3db5d08f6"

echo "Running test..."
output=$("$OBSERVERS_DIR/repo-observer.sh" "$PROJECT_PATH" "$PROJECT_ID")

# Verify it's valid NDJSON (single line JSON)
if echo "$output" | jq -c . >/dev/null 2>&1; then
    echo "✓ Output is valid JSON"

    # Check it's a single line
    line_count=$(echo "$output" | wc -l | tr -d ' ')
    if [[ $line_count -eq 1 ]]; then
        echo "✓ Output is single-line NDJSON"
    else
        echo "✗ Output has $line_count lines, should be 1"
    fi
else
    echo "✗ Output is not valid JSON"
fi
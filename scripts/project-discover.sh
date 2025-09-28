#!/bin/bash
# Project Discovery - Finds all projects with manifests
# Outputs registry JSON and updates cache

set -euo pipefail

# Configuration
readonly ALLOWED_ROOTS=(
    "$HOME/Development/personal"
    "$HOME/Development/work"
    "$HOME/Development/business"
    "$HOME/workspace/projects"
)
readonly MAX_DEPTH=3
readonly MANIFEST_FILE="project.manifest.yaml"
readonly REGISTRY_PATH="$HOME/.local/share/devops-mcp/project-registry.json"
readonly SCHEMA_PATH="$(dirname "$0")/../schema/project.manifest.schema.json"

# Ensure output directory exists
mkdir -p "$(dirname "$REGISTRY_PATH")"

# Validate manifest against schema
validate_manifest() {
    local manifest_path="$1"

    if command -v ajv &>/dev/null; then
        # Use ajv if available for JSON schema validation
        # First convert YAML to JSON
        local json_content=$(yq eval -o=json "$manifest_path" 2>/dev/null)
        if [[ -z "$json_content" ]]; then
            return 1
        fi

        echo "$json_content" | ajv validate -s "$SCHEMA_PATH" --strict=false &>/dev/null
        return $?
    else
        # Basic validation - just check required fields
        local has_version=$(yq eval '.apiVersion' "$manifest_path" 2>/dev/null)
        local has_id=$(yq eval '.project.id' "$manifest_path" 2>/dev/null)

        if [[ "$has_version" == "devops.v1" ]] && [[ -n "$has_id" ]]; then
            return 0
        else
            return 1
        fi
    fi
}

# Find projects recursively
find_projects() {
    local root="$1"
    local depth="${2:-0}"

    if [[ "$depth" -ge "$MAX_DEPTH" ]]; then
        return
    fi

    # Check for manifest in current directory
    local manifest_path="$root/$MANIFEST_FILE"
    if [[ -f "$manifest_path" ]]; then
        if validate_manifest "$manifest_path"; then
            local project_id=$(yq eval '.project.id' "$manifest_path")
            local project_name=$(yq eval '.project.name' "$manifest_path")
            local project_tier=$(yq eval '.project.tier' "$manifest_path")
            local project_kind=$(yq eval '.project.kind' "$manifest_path")
            local project_org=$(yq eval '.project.org' "$manifest_path")

            # Convert full manifest to JSON for registry
            local manifest_json=$(yq eval -o=json "$manifest_path" | jq -c .)

            echo "{
                \"id\": \"$project_id\",
                \"name\": \"$project_name\",
                \"tier\": \"$project_tier\",
                \"kind\": \"$project_kind\",
                \"org\": \"$project_org\",
                \"path\": \"$root\",
                \"manifest_path\": \"$manifest_path\",
                \"manifest\": $manifest_json,
                \"discovered_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
            }"
        else
            echo "Warning: Invalid manifest at $manifest_path" >&2
        fi
    fi

    # Recurse into subdirectories
    for dir in "$root"/*; do
        if [[ -d "$dir" ]] && [[ ! -L "$dir" ]]; then
            # Skip hidden directories and node_modules
            local basename=$(basename "$dir")
            if [[ "$basename" != "."* ]] && [[ "$basename" != "node_modules" ]]; then
                find_projects "$dir" $((depth + 1))
            fi
        fi
    done
}

# Main execution
main() {
    echo "🔍 Discovering projects in allowed roots..." >&2

    # Collect all projects
    local projects="["
    local first=true

    for root in "${ALLOWED_ROOTS[@]}"; do
        if [[ -d "$root" ]]; then
            echo "  Scanning: $root" >&2

            while IFS= read -r project_json; do
                if [[ -n "$project_json" ]]; then
                    if [[ "$first" == true ]]; then
                        projects="$projects$project_json"
                        first=false
                    else
                        projects="$projects,$project_json"
                    fi
                fi
            done < <(find_projects "$root")
        fi
    done

    projects="$projects]"

    # Create registry object
    local registry=$(cat <<EOF
{
    "version": "1.0.0",
    "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "discovery": {
        "roots": $(printf '%s\n' "${ALLOWED_ROOTS[@]}" | jq -R . | jq -s .),
        "max_depth": $MAX_DEPTH
    },
    "projects": $projects
}
EOF
)

    # Save to registry file
    echo "$registry" | jq . > "$REGISTRY_PATH"

    # Output summary
    local project_count=$(echo "$registry" | jq '.projects | length')
    local by_tier=$(echo "$registry" | jq '.projects | group_by(.tier) | map({tier: .[0].tier, count: length})')
    local by_kind=$(echo "$registry" | jq '.projects | group_by(.kind) | map({kind: .[0].kind, count: length})')

    cat <<EOF
{
    "discovered": $project_count,
    "registry_path": "$REGISTRY_PATH",
    "by_tier": $by_tier,
    "by_kind": $by_kind,
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

    echo "✅ Discovery complete: $project_count projects found" >&2
}

# Check dependencies
check_dependencies() {
    if ! command -v yq &>/dev/null; then
        echo "Error: yq is required for YAML parsing" >&2
        echo "Install with: brew install yq" >&2
        exit 1
    fi

    if ! command -v jq &>/dev/null; then
        echo "Error: jq is required for JSON processing" >&2
        echo "Install with: brew install jq" >&2
        exit 1
    fi
}

# Run checks and main
check_dependencies
main
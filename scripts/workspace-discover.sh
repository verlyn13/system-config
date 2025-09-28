#!/bin/bash
# Workspace Discovery - Finds and registers all workspaces and their projects
# Usage: workspace-discover.sh [--config <file>] [--validate] [--force]

set -euo pipefail

# Configuration
readonly CONFIG_FILE="${WORKSPACE_CONFIG:-$HOME/.config/workspace/config.yaml}"
readonly REGISTRY_FILE="$HOME/.local/share/workspace/registry.json"
readonly SCHEMA_FILE="$(dirname "$0")/../schema/workspace.config.schema.json"
readonly TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Ensure directories exist
mkdir -p "$(dirname "$REGISTRY_FILE")"

# Parse arguments
VALIDATE=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --validate)
            VALIDATE=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --help)
            cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Discover and register workspaces and their projects.

Options:
    --config <file>  Use alternate config file (default: ~/.config/workspace/config.yaml)
    --validate       Validate configuration against schema
    --force          Force re-discovery even if cache is fresh
    --help           Show this help message

Examples:
    $(basename "$0")
    $(basename "$0") --validate
    $(basename "$0") --config ./workspace.yaml --force
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Validate configuration file
validate_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}Error: Configuration file not found: $CONFIG_FILE${NC}" >&2
        exit 1
    fi

    if [[ "$VALIDATE" == true ]] && command -v ajv &>/dev/null; then
        echo "Validating configuration against schema..."
        local json_config=$(yq eval -o=json "$CONFIG_FILE")

        if echo "$json_config" | ajv validate -s "$SCHEMA_FILE" --strict=false; then
            echo -e "${GREEN}✓ Configuration valid${NC}"
        else
            echo -e "${RED}✗ Configuration invalid${NC}" >&2
            exit 1
        fi
    fi
}

# Discover projects in a workspace
discover_projects() {
    local workspace_name="$1"
    local root="$2"
    local depth="${3:-3}"
    local tier="${4:-development}"

    # Expand home directory
    root="${root/#\~/$HOME}"

    if [[ ! -d "$root" ]]; then
        echo -e "${YELLOW}Warning: Workspace root does not exist: $root${NC}" >&2
        return
    fi

    echo -e "${BLUE}  Discovering projects in $workspace_name...${NC}" >&2

    local projects=()
    local project_count=0

    # Find project manifests
    while IFS= read -r manifest; do
        if [[ -f "$manifest" ]]; then
            local project_dir=$(dirname "$manifest")
            local project_id=$(yq eval '.project.id // ""' "$manifest" 2>/dev/null)

            if [[ -n "$project_id" ]]; then
                local project_json=$(yq eval -o=json "$manifest" 2>/dev/null | jq -c .)

                projects+=("{
                    \"id\": \"$project_id\",
                    \"path\": \"$project_dir\",
                    \"workspace\": \"$workspace_name\",
                    \"tier\": \"$tier\",
                    \"manifest\": $project_json
                }")

                ((project_count++))
                echo -e "    ${GREEN}✓${NC} Found: $project_id" >&2
            fi
        fi
    done < <(find "$root" -maxdepth "$depth" -name "project.manifest.yaml" 2>/dev/null)

    # Also find git repositories without manifests
    while IFS= read -r git_dir; do
        local project_dir=$(dirname "$git_dir")
        local project_name=$(basename "$project_dir")

        # Skip if we already have a manifest for this project
        if [[ ! -f "$project_dir/project.manifest.yaml" ]]; then
            # Generate a basic ID
            local project_id="git:$workspace_name/$project_name"

            projects+=("{
                \"id\": \"$project_id\",
                \"path\": \"$project_dir\",
                \"workspace\": \"$workspace_name\",
                \"tier\": \"$tier\",
                \"manifest\": null,
                \"discovered_by\": \"git\"
            }")

            ((project_count++))
            echo -e "    ${YELLOW}○${NC} Git repo: $project_name (no manifest)" >&2
        fi
    done < <(find "$root" -maxdepth "$depth" -type d -name ".git" 2>/dev/null)

    echo -e "    Total: $project_count projects" >&2

    # Return projects as JSON array
    if [[ ${#projects[@]} -gt 0 ]]; then
        printf '%s\n' "${projects[@]}" | jq -s '.'
    else
        echo "[]"
    fi
}

# Main discovery process
discover_all() {
    echo -e "${BLUE}🔍 Starting workspace discovery...${NC}" >&2
    echo -e "  Config: $CONFIG_FILE" >&2

    local workspaces_json="[]"
    local all_projects_json="[]"

    # Parse workspace configuration
    local workspace_names=$(yq eval '.workspaces | keys | .[]' "$CONFIG_FILE" 2>/dev/null)

    for workspace in $workspace_names; do
        echo -e "\n${BLUE}Workspace: $workspace${NC}" >&2

        # Get workspace configuration
        local root=$(yq eval ".workspaces.$workspace.root" "$CONFIG_FILE")
        local profile=$(yq eval ".workspaces.$workspace.profile" "$CONFIG_FILE")
        local tier=$(yq eval ".workspaces.$workspace.tier" "$CONFIG_FILE")
        local github=$(yq eval ".workspaces.$workspace.github // \"\"" "$CONFIG_FILE")
        local depth=$(yq eval ".workspaces.$workspace.discovery.depth // 3" "$CONFIG_FILE")
        local enabled=$(yq eval ".workspaces.$workspace.discovery.enabled // true" "$CONFIG_FILE")

        if [[ "$enabled" != "true" ]]; then
            echo -e "  ${YELLOW}⊘ Discovery disabled${NC}" >&2
            continue
        fi

        # Discover projects in workspace
        local projects_json=$(discover_projects "$workspace" "$root" "$depth" "$tier")
        local project_count=$(echo "$projects_json" | jq '. | length')

        # Add workspace to registry
        local workspace_json=$(cat <<EOF
{
    "name": "$workspace",
    "root": "$root",
    "profile": "$profile",
    "tier": "$tier",
    "github": "$github",
    "projectCount": $project_count,
    "lastScanned": "$TIMESTAMP"
}
EOF
)
        workspaces_json=$(echo "$workspaces_json" | jq ". + [$workspace_json]")

        # Add projects to registry
        all_projects_json=$(echo "$all_projects_json" | jq ". + $projects_json")
    done

    # Create registry
    local registry=$(cat <<EOF
{
    "version": "2.0.0",
    "generated": "$TIMESTAMP",
    "config": "$CONFIG_FILE",
    "workspaces": $workspaces_json,
    "projects": $all_projects_json,
    "stats": {
        "totalWorkspaces": $(echo "$workspaces_json" | jq '. | length'),
        "totalProjects": $(echo "$all_projects_json" | jq '. | length'),
        "byTier": $(echo "$all_projects_json" | jq 'group_by(.tier) | map({tier: .[0].tier, count: length})'),
        "byWorkspace": $(echo "$all_projects_json" | jq 'group_by(.workspace) | map({workspace: .[0].workspace, count: length})')
    }
}
EOF
)

    # Save registry
    echo "$registry" | jq '.' > "$REGISTRY_FILE"

    # Output summary
    echo
    echo -e "${GREEN}✅ Discovery complete${NC}"
    echo "$registry" | jq '.stats'
    echo
    echo "Registry saved to: $REGISTRY_FILE"
}

# Check if registry needs update
check_cache() {
    if [[ "$FORCE" == true ]]; then
        return 1
    fi

    if [[ ! -f "$REGISTRY_FILE" ]]; then
        return 1
    fi

    # Check if registry is older than 1 hour
    local registry_age=$(($(date +%s) - $(stat -f%m "$REGISTRY_FILE" 2>/dev/null || stat -c%Y "$REGISTRY_FILE")))
    if [[ $registry_age -gt 3600 ]]; then
        return 1
    fi

    echo -e "${GREEN}Registry is fresh (< 1 hour old). Use --force to re-discover.${NC}"
    cat "$REGISTRY_FILE" | jq '.stats'
    return 0
}

# Main execution
main() {
    # Validate configuration
    validate_config

    # Check cache
    if ! check_cache; then
        # Run discovery
        discover_all
    fi

    # Run post-discovery hook if defined
    local post_hook=$(yq eval '.hooks.postDiscovery // ""' "$CONFIG_FILE")
    if [[ -n "$post_hook" ]] && [[ -x "$post_hook" ]]; then
        echo "Running post-discovery hook: $post_hook"
        "$post_hook" "$REGISTRY_FILE"
    fi
}

# Check dependencies
if ! command -v yq &>/dev/null; then
    echo -e "${RED}Error: yq is required${NC}" >&2
    echo "Install with: brew install yq" >&2
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo -e "${RED}Error: jq is required${NC}" >&2
    echo "Install with: brew install jq" >&2
    exit 1
fi

# Run main
main
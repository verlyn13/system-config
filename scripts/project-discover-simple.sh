#!/bin/bash
# Simple Project Discovery - Detects projects by common markers
# Writes to shared registry location for MCP and HTTP Bridge

set -euo pipefail

# Configuration - CRITICAL: Shared location for MCP and Bridge
readonly DATA_DIR="$HOME/.local/share/devops-mcp"
readonly REGISTRY_FILE="$DATA_DIR/project-registry.json"
readonly TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Discovery roots (can be overridden by DEVOPS_MCP_ROOTS env var)
if [[ -n "${DEVOPS_MCP_ROOTS:-}" ]]; then
    IFS=',' read -ra ROOTS <<< "$DEVOPS_MCP_ROOTS"
else
    ROOTS=(
        "$HOME/Development/personal"
        "$HOME/Development/work"
        "$HOME/Development/business"
        "$HOME/Development/business-org"
    )
fi

# Ensure directory exists
mkdir -p "$DATA_DIR"

# Generate project ID (SHA1 hash of path)
generate_id() {
    echo -n "$1" | sha1sum | cut -c1-12
}

# Detect project type
detect_project() {
    local dir="$1"
    local detectors=()
    local kind="generic"

    # Check for various project markers
    [[ -d "$dir/.git" ]] && detectors+=("git")
    [[ -f "$dir/package.json" ]] && { detectors+=("node"); kind="node"; }
    [[ -f "$dir/go.mod" ]] && { detectors+=("go"); kind=$([[ "$kind" == "node" ]] && echo "mix" || echo "go"); }
    [[ -f "$dir/pyproject.toml" || -f "$dir/requirements.txt" ]] && {
        detectors+=("python")
        kind=$([[ "$kind" == "generic" ]] && echo "python" || echo "mix")
    }
    [[ -f "$dir/Cargo.toml" ]] && { detectors+=("rust"); kind=$([[ "$kind" == "generic" ]] && echo "rust" || echo "mix"); }
    [[ -f "$dir/mise.toml" || -f "$dir/.mise.toml" ]] && detectors+=("mise")
    [[ -f "$dir/project.manifest.yaml" ]] && detectors+=("manifest")
    [[ -f "$dir/Makefile" ]] && detectors+=("make")
    [[ -f "$dir/docker-compose.yml" || -f "$dir/docker-compose.yaml" ]] && detectors+=("docker")

    # Must have at least git or another marker
    if [[ ${#detectors[@]} -eq 0 ]]; then
        return 1
    fi

    echo "${detectors[@]}|$kind"
    return 0
}

# Main discovery
main() {
    echo "🔍 Starting project discovery..." >&2
    echo "  Registry: $REGISTRY_FILE" >&2
    echo "  Roots: ${ROOTS[*]}" >&2
    echo >&2

    local projects=()
    local total=0

    for root in "${ROOTS[@]}"; do
        # Expand tilde
        root="${root/#\~/$HOME}"

        if [[ ! -d "$root" ]]; then
            echo "  ⚠ Root does not exist: $root" >&2
            continue
        fi

        echo "📁 Scanning: $root" >&2
        local count=0

        # Find all directories with depth limit (skip the root itself)
        while IFS= read -r dir; do
            # Skip the root directory itself
            [[ "$dir" == "$root" ]] && continue

            if result=$(detect_project "$dir"); then
                IFS='|' read -r detectors_str kind <<< "$result"
                IFS=' ' read -ra detectors_arr <<< "$detectors_str"

                local name=$(basename "$dir")
                local id=$(generate_id "$dir")
                local workspace=$(basename "$(dirname "$dir")")

                # Create JSON object
                local project_json=$(cat <<EOF
{
  "id": "$id",
  "name": "$name",
  "path": "$dir",
  "workspace": "$workspace",
  "kind": "$kind",
  "detectors": [$(printf '"%s",' "${detectors_arr[@]}" | sed 's/,$//')]
}
EOF
)
                projects+=("$project_json")
                ((count++))
                ((total++))
                echo "  ✓ $name ($kind)" >&2
            fi
        done < <(/usr/bin/find "$root" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | grep -v '/\.' | grep -v node_modules | grep -v vendor)

        echo "  Found: $count projects" >&2
        echo >&2
    done

    # Build projects array
    local projects_json="[]"
    if [[ ${#projects[@]} -gt 0 ]]; then
        projects_json=$(printf '%s\n' "${projects[@]}" | jq -s '.')
    fi

    # Calculate statistics
    local by_kind="[]"
    local by_workspace="[]"
    if [[ "$total" -gt 0 ]]; then
        by_kind=$(echo "$projects_json" | jq '[group_by(.kind)[] | {kind: .[0].kind, count: length}]')
        by_workspace=$(echo "$projects_json" | jq '[group_by(.workspace)[] | {workspace: .[0].workspace, count: length}]')
    fi

    # Create registry
    local registry=$(cat <<EOF
{
  "version": "2.0.0",
  "generated": "$TIMESTAMP",
  "discovered": $total,
  "projects": $projects_json,
  "stats": {
    "total": $total,
    "byKind": $by_kind,
    "byWorkspace": $by_workspace
  }
}
EOF
)

    # Save to registry file
    echo "$registry" | jq '.' > "$REGISTRY_FILE"

    # Output summary for caller
    echo "$registry" | jq '{discovered: .discovered, registry_path: "'$REGISTRY_FILE'", stats: .stats}'

    echo "✅ Discovery complete: $total projects found" >&2
    echo "   Registry: $REGISTRY_FILE" >&2
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
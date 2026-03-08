#!/usr/bin/env bash
#
# sync-mcp.sh - Propagate global MCP server definitions to AI tool configs
#
# Syncs mcp-servers.json to each tool's expected user-level config location.
# Secrets are pulled from gopass. Works with Fish and Zsh shells.
#
# Usage: ./sync-mcp.sh [--dry-run]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="$SCRIPT_DIR/mcp-servers.json"

# Tool config locations (user-level)
CLAUDE_CODE_CONFIG="$HOME/.claude.json"
CURSOR_CONFIG="$HOME/.cursor/mcp.json"
WINDSURF_CONFIG="$HOME/.codeium/windsurf/mcp_config.json"
COPILOT_CONFIG="$HOME/.copilot/mcp-config.json"
CODEX_CONFIG="$HOME/.codex/config.toml"

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# Check dependencies
command -v jq &>/dev/null || { echo "Error: jq required"; exit 1; }
command -v gopass &>/dev/null || { echo "Error: gopass required for secrets"; exit 1; }

# Get secret from gopass (returns empty string if not found)
get_secret() {
    gopass show -o "$1" 2>/dev/null || echo ""
}

# Strip metadata keys (keys starting with _) and expand secrets
prepare_servers() {
    local content
    content=$(cat "$SOURCE_FILE" | jq 'walk(if type == "object" then with_entries(select(.key | startswith("_") | not)) else . end)')

    # Expand secrets from gopass
    local github_token brave_key firecrawl_key
    github_token=$(get_secret "github/dev-tools-token")
    brave_key=$(get_secret "brave/api-key")
    firecrawl_key=$(get_secret "firecrawl/api-key")

    content=$(echo "$content" | sed "s|\${GITHUB_TOKEN}|$github_token|g")
    content=$(echo "$content" | sed "s|\${BRAVE_API_KEY}|$brave_key|g")
    content=$(echo "$content" | sed "s|\${FIRECRAWL_API_KEY}|$firecrawl_key|g")
    content=$(echo "$content" | sed "s|\${HOME}|$HOME|g")

    echo "$content"
}

# Create memory directory for persistent memory MCP
ensure_memory_dir() {
    local dir="$HOME/.local/share/ai-memory"
    if [[ ! -d "$dir" ]]; then
        $DRY_RUN && echo "  Would create: $dir" || mkdir -p "$dir"
    fi
}

# Merge global servers into JSON config (Claude, Cursor, Windsurf, Copilot)
sync_json_config() {
    local name="$1"
    local config_path="$2"
    local servers="$3"

    echo "$name: $config_path"

    if $DRY_RUN; then
        echo "  Would merge $(echo "$servers" | jq 'keys | length') global servers"
        return
    fi

    mkdir -p "$(dirname "$config_path")"

    if [[ -f "$config_path" ]]; then
        # Merge: existing servers + global servers (global wins on conflict)
        jq --argjson new "$servers" '.mcpServers = (.mcpServers // {}) + $new' "$config_path" > "${config_path}.tmp"
        mv "${config_path}.tmp" "$config_path"
    else
        echo "{\"mcpServers\": $servers}" | jq '.' > "$config_path"
    fi
    echo "  Synced $(echo "$servers" | jq 'keys | length') global servers"
}

# Append MCP servers to Codex TOML config
sync_codex_toml() {
    local servers_json="$1"

    echo "Codex CLI: $CODEX_CONFIG"

    # Check if global servers already present
    if [[ -f "$CODEX_CONFIG" ]] && grep -q "\[mcp_servers.context7\]" "$CODEX_CONFIG" 2>/dev/null; then
        echo "  Skipped - global MCP servers already present"
        return
    fi

    if $DRY_RUN; then
        echo "  Would append [mcp_servers.*] sections"
        return
    fi

    mkdir -p "$(dirname "$CODEX_CONFIG")"

    # Generate TOML from JSON using jq
    local toml_content
    toml_content=$(echo "$servers_json" | jq -r '
        to_entries[] |
        "\n[mcp_servers.\(.key)]" +
        (if .value.url then "\nurl = \"\(.value.url)\"" else "" end) +
        (if .value.command then "\ncommand = \"\(.value.command)\"" else "" end) +
        (if .value.args then "\nargs = \(.value.args | tojson)" else "" end) +
        (if .value.env then
            "\n\n[mcp_servers.\(.key).env]" +
            (.value.env | to_entries | map("\n\(.key) = \"\(.value)\"") | join(""))
        else "" end)
    ')

    local count
    count=$(echo "$servers_json" | jq 'keys | length')

    if [[ -f "$CODEX_CONFIG" ]]; then
        printf "%s\n" "$toml_content" >> "$CODEX_CONFIG"
    else
        printf "# Codex Configuration\n%s\n" "$toml_content" > "$CODEX_CONFIG"
    fi
    echo "  Appended $count server sections"
}

# Main
echo "Syncing global MCP servers"
echo "Source: $SOURCE_FILE"
echo ""
$DRY_RUN && echo "[DRY RUN]" && echo ""

# Prepare servers with secrets injected
SERVERS=$(prepare_servers | jq '.mcpServers')

ensure_memory_dir
sync_json_config "Claude Code CLI" "$CLAUDE_CODE_CONFIG" "$SERVERS"
sync_json_config "Cursor" "$CURSOR_CONFIG" "$SERVERS"
sync_json_config "Windsurf" "$WINDSURF_CONFIG" "$SERVERS"
sync_json_config "Copilot CLI" "$COPILOT_CONFIG" "$SERVERS"
sync_codex_toml "$SERVERS"

echo ""
echo "Done. Project-specific MCP servers in each config remain unchanged."

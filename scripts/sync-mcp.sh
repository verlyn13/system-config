#!/usr/bin/env bash
#
# sync-mcp.sh - Propagate the global MCP baseline to supported AI tool configs
#
# Syncs scripts/mcp-servers.json to each tool's expected user-level config
# location. Project-specific servers stay in each project's .mcp.json.
# Secrets are resolved by runtime wrapper commands, not persisted into config.
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

# GitHub MCP is rendered per-host rather than from mcp-servers.json:
# - Claude/Cursor/Windsurf: stdio wrapper that relays to the remote server
# - Copilot CLI: skipped (built-in github-mcp-server ships with the tool)
# - Codex CLI: direct remote HTTP with bearer_token_env_var
GITHUB_REMOTE_URL="https://api.githubcopilot.com/mcp/x/all"
GITHUB_WRAPPER_PATH="$HOME/.local/bin/mcp-github-server"
GITHUB_ENV_VAR="GITHUB_PERSONAL_ACCESS_TOKEN"

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# Check dependencies
command -v jq &>/dev/null || { echo "Error: jq required"; exit 1; }

# Strip metadata keys (keys starting with _) and expand ${HOME}
prepare_servers() {
    local content
    content=$(jq 'walk(if type == "object" then with_entries(select(.key | startswith("_") | not)) else . end)' "$SOURCE_FILE")
    content="${content//\$\{HOME\}/$HOME}"

    echo "$content"
}

# Create memory directory for persistent memory MCP
ensure_memory_dir() {
    local dir="$HOME/.local/share/ai-memory"
    if [[ ! -d "$dir" ]]; then
        if $DRY_RUN; then
            echo "  Would create: $dir"
        else
            mkdir -p "$dir"
        fi
    fi
}

# Merge global servers into JSON config (Claude, Cursor, Windsurf, Copilot)
sync_json_config() {
    local name="$1"
    local config_path="$2"
    local servers="$3"
    local managed_keys="$4"

    echo "$name: $config_path"

    if $DRY_RUN; then
        echo "  Would merge $(echo "$servers" | jq 'keys | length') global servers"
        return
    fi

    mkdir -p "$(dirname "$config_path")"

    if [[ -f "$config_path" ]]; then
        jq --argjson new "$servers" --argjson keys "$managed_keys" '
            .mcpServers = (
                reduce $keys[] as $key ((.mcpServers // {}); del(.[$key])) + $new
            )
        ' "$config_path" > "${config_path}.tmp"
        mv "${config_path}.tmp" "$config_path"
    else
        echo "{\"mcpServers\": $servers}" | jq '.' > "$config_path"
    fi
    echo "  Synced $(echo "$servers" | jq 'keys | length') global servers"
}

# Generate Codex TOML from the global server JSON
generate_codex_toml() {
    local servers_json="$1"

    echo "$servers_json" | jq -r '
        to_entries[] |
        "\n[mcp_servers.\(.key)]" +
        (if .value.url then "\nurl = \"\(.value.url)\"" else "" end) +
        (if .value.bearer_token_env_var then "\nbearer_token_env_var = \"\(.value.bearer_token_env_var)\"" else "" end) +
        (if .value.command then "\ncommand = \"\(.value.command)\"" else "" end) +
        (if .value.args then "\nargs = \(.value.args | tojson)" else "" end) +
        (if .value.env then
            "\n\n[mcp_servers.\(.key).env]" +
            (.value.env | to_entries | map("\n\(.key) = \"\(.value)\"") | join(""))
        else "" end)
    '
}

# Replace the managed MCP block in Codex TOML config
sync_codex_toml() {
    local servers_json="$1"
    local begin_marker="# BEGIN system-config managed MCP servers"
    local end_marker="# END system-config managed MCP servers"

    echo "Codex CLI: $CODEX_CONFIG"

    if $DRY_RUN; then
        echo "  Would replace managed [mcp_servers.*] block"
        return
    fi

    mkdir -p "$(dirname "$CODEX_CONFIG")"

    local tmp_file managed_block toml_content count
    tmp_file="$(mktemp)"
    managed_block="$(mktemp)"
    toml_content="$(generate_codex_toml "$servers_json")"
    count=$(echo "$servers_json" | jq 'keys | length')

    {
        printf "%s\n" "$begin_marker"
        printf "%s\n" "$toml_content"
        printf "\n%s\n" "$end_marker"
    } > "$managed_block"

    if [[ -f "$CODEX_CONFIG" ]]; then
        awk -v begin="$begin_marker" -v end="$end_marker" '
            $0 == begin { skip = 1; next }
            $0 == end { skip = 0; next }
            !skip { print }
        ' "$CODEX_CONFIG" > "$tmp_file"
    else
        : > "$tmp_file"
    fi

    if [[ ! -s "$tmp_file" ]]; then
        printf "# Codex Configuration\n" > "$tmp_file"
    fi

    if [[ -s "$tmp_file" ]]; then
        printf "\n" >> "$tmp_file"
    fi
    cat "$managed_block" >> "$tmp_file"
    mv "$tmp_file" "$CODEX_CONFIG"
    rm -f "$managed_block"

    echo "  Synced $count server sections"
}

# Main
echo "Syncing global MCP servers"
echo "Source: $SOURCE_FILE"
echo ""
$DRY_RUN && echo "[DRY RUN]" && echo ""

# Baseline servers (github intentionally absent — rendered per host below)
BASE_SERVERS=$(prepare_servers | jq '.mcpServers')

# Managed keys include "github" so any pre-existing github entry on a target
# gets cleaned up on sync, even if this script does not write a new one.
MANAGED_KEYS=$(echo "$BASE_SERVERS" | jq '. + {github: null} | keys')

# Per-host github rendering
GITHUB_STDIO=$(jq -n --arg cmd "$GITHUB_WRAPPER_PATH" \
    '{type: "stdio", command: $cmd}')
GITHUB_CODEX=$(jq -n \
    --arg url "$GITHUB_REMOTE_URL" \
    --arg env "$GITHUB_ENV_VAR" \
    '{url: $url, bearer_token_env_var: $env}')

SERVERS_WITH_STDIO=$(echo "$BASE_SERVERS" \
    | jq --argjson gh "$GITHUB_STDIO" '. + {github: $gh}')
SERVERS_WITH_CODEX=$(echo "$BASE_SERVERS" \
    | jq --argjson gh "$GITHUB_CODEX" '. + {github: $gh}')

ensure_memory_dir

# stdio-wrapper hosts
sync_json_config "Claude Code CLI" "$CLAUDE_CODE_CONFIG" "$SERVERS_WITH_STDIO" "$MANAGED_KEYS"
sync_json_config "Cursor"          "$CURSOR_CONFIG"      "$SERVERS_WITH_STDIO" "$MANAGED_KEYS"
sync_json_config "Windsurf"        "$WINDSURF_CONFIG"    "$SERVERS_WITH_STDIO" "$MANAGED_KEYS"

# Copilot: skip github (built-in); any existing github key is removed via MANAGED_KEYS
sync_json_config "Copilot CLI"     "$COPILOT_CONFIG"     "$BASE_SERVERS"       "$MANAGED_KEYS"

# Codex: direct remote HTTP for github
sync_codex_toml "$SERVERS_WITH_CODEX"

echo ""
echo "Done. Project-specific MCP servers remain project-scoped."

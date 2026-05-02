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
CLAUDE_DESKTOP_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
CURSOR_CONFIG="$HOME/.cursor/mcp.json"
WINDSURF_CONFIG="$HOME/.codeium/windsurf/mcp_config.json"
COPILOT_CONFIG="$HOME/.copilot/mcp-config.json"
CODEX_CONFIG="$HOME/.codex/config.toml"

# mcp-remote version used for HTTP→stdio relay when the target host's config
# file does not natively accept remote-HTTP MCP entries (Claude Desktop).
# Keep in lockstep with the wrappers in home/dot_local/bin/.
MCP_REMOTE_VERSION="0.1.38"
MCP_NPX_WRAPPER_PATH="$HOME/.local/bin/mcp-npx"

# GitHub MCP is rendered per-host rather than from mcp-servers.json:
# - Claude Code: stdio wrapper (SDK OAuth/DCR discovery breaks on static bearer)
# - Claude Desktop: stdio wrapper (same reason; app's config file is stdio-only)
# - Cursor: stdio wrapper (OAuth has open bugs; env interp quirks)
# - Windsurf: native serverUrl, OAuth 2.1 + PKCE (shipped 1.12.41, Dec 2025)
# - Codex: stdio wrapper (same no-global-secret contract as Claude/GUI hosts)
# - Copilot CLI: skipped (built-in github-mcp-server ships with the tool)
GITHUB_BASE_URL="https://api.githubcopilot.com/mcp/"
GITHUB_WRAPPER_PATH="$HOME/.local/bin/mcp-github-server"

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
        (if .value.http_headers then
            "\nhttp_headers = { " +
            (.value.http_headers | to_entries | map("\"\(.key)\" = \"\(.value)\"") | join(", ")) +
            " }"
        else "" end) +
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

# Transform the cross-tool server set into Claude Desktop's native shape:
# - Remove type field (Claude Desktop's config file is stdio-only: command+args+env)
# - Wrap type:"http" entries via `mcp-npx -y mcp-remote@VERSION <url>` as stdio
# - stdio entries pass through (strip type)
#
# Why all stdio: Claude Desktop's claude_desktop_config.json file format
# historically only accepts command-based entries. Remote MCP servers are
# configured via the app's Settings → Connectors UI (separate store). To keep
# one consistent surface for programmatic management, we relay HTTP remotes
# through mcp-remote the same way the github/cloudflare wrappers do.
transform_for_claude_desktop() {
    local servers_json="$1"
    echo "$servers_json" | jq \
        --arg mcp_npx "$MCP_NPX_WRAPPER_PATH" \
        --arg mcp_remote "mcp-remote@${MCP_REMOTE_VERSION}" '
        with_entries(
            .value as $v |
            if ($v.type // "stdio") == "http" then
                .value = { command: $mcp_npx, args: ["-y", $mcp_remote, $v.url] }
            else
                .value = ($v | del(.type))
            end
        )
    '
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

# Per-host github rendering. Four distinct shapes.

# Claude Code and Cursor both use the stdio wrapper (mcp-remote via ~/.local/bin).
#
# Rationale: Claude Code's and Cursor's MCP SDKs both attempt OAuth discovery
# when the server advertises Protected Resource Metadata (RFC 9728). GitHub's
# remote MCP server does advertise it, but points at github.com/login/oauth,
# which does NOT support Dynamic Client Registration. Both SDKs then error
# out with "SDK auth failed: Incompatible auth server" before falling back
# to the static Authorization bearer header we provided. The stdio wrapper
# sidesteps this entirely: the client sees a plain stdio MCP server, and
# mcp-remote handles the HTTPS call to GitHub with a pre-authenticated
# bearer that bypasses OAuth discovery.
GITHUB_STDIO_WRAPPER=$(jq -n --arg cmd "$GITHUB_WRAPPER_PATH" \
    '{type: "stdio", command: $cmd}')

# Windsurf: native serverUrl, OAuth 2.1 + PKCE handled by Windsurf itself
# (shipped 1.12.41, Dec 2025). No auth field — Windsurf is expected to
# negotiate OAuth via Protected Resource Metadata discovery (RFC 9728) on
# first connect. Fallback: if Windsurf's SDK also fails on DCR like Claude
# Code / Cursor do, reuse GITHUB_STDIO_WRAPPER.
GITHUB_WINDSURF=$(jq -n --arg url "$GITHUB_BASE_URL" \
    '{serverUrl: $url}')

# Codex: stdio wrapper. This keeps bare `codex` launches working without
# exporting GITHUB_PAT globally or requiring every session to be started via
# `op run --env-file`.
GITHUB_CODEX="$GITHUB_STDIO_WRAPPER"

SERVERS_WITH_WRAPPER=$(echo "$BASE_SERVERS"  | jq --argjson gh "$GITHUB_STDIO_WRAPPER" '. + {github: $gh}')
SERVERS_WITH_WINDSURF=$(echo "$BASE_SERVERS" | jq --argjson gh "$GITHUB_WINDSURF"       '. + {github: $gh}')
SERVERS_WITH_CODEX=$(echo "$BASE_SERVERS"    | jq --argjson gh "$GITHUB_CODEX"          '. + {github: $gh}')

# Claude Desktop: stdio-only config format. Reuse the CLI-host github stdio
# wrapper, then transform the whole set to Claude Desktop's
# native shape (strip type, wrap HTTP via mcp-remote).
SERVERS_CLAUDE_DESKTOP=$(transform_for_claude_desktop "$SERVERS_WITH_WRAPPER")

ensure_memory_dir

sync_json_config "Claude Code CLI" "$CLAUDE_CODE_CONFIG"    "$SERVERS_WITH_WRAPPER"  "$MANAGED_KEYS"
sync_json_config "Claude Desktop"  "$CLAUDE_DESKTOP_CONFIG" "$SERVERS_CLAUDE_DESKTOP" "$MANAGED_KEYS"
sync_json_config "Cursor"          "$CURSOR_CONFIG"         "$SERVERS_WITH_WRAPPER"  "$MANAGED_KEYS"
sync_json_config "Windsurf"        "$WINDSURF_CONFIG"       "$SERVERS_WITH_WINDSURF" "$MANAGED_KEYS"

# Copilot: skip github (built-in); any existing github key is removed via MANAGED_KEYS.
sync_json_config "Copilot CLI"     "$COPILOT_CONFIG"        "$BASE_SERVERS"          "$MANAGED_KEYS"

# Codex: stdio wrapper with 1Password fallback.
sync_codex_toml "$SERVERS_WITH_CODEX"

echo ""
echo "Done. Project-specific MCP servers remain project-scoped."

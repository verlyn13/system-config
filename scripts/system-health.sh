#!/usr/bin/env bash
# System health dashboard - real-time monitoring of all components
set -euo pipefail

# Configuration
readonly BRIDGE_URL="http://127.0.0.1:7171"
readonly REGISTRY_FILE="$HOME/.local/share/devops-mcp/project-registry.json"
readonly OBSERVATIONS_DIR="$HOME/.local/share/devops-mcp/observations"
readonly UPDATE_INTERVAL=5  # seconds

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# Clear screen and move cursor to top
clear_screen() {
    printf '\033[2J\033[H'
}

# Draw a box
draw_box() {
    local width=$1
    local title=$2
    local color=${3:-$BLUE}

    echo -e "${color}┌─ ${BOLD}$title${NC}${color} $(printf '─%.0s' $(seq 1 $((width - ${#title} - 4))))┐${NC}"
}

draw_box_end() {
    local width=$1
    local color=${2:-$BLUE}
    echo -e "${color}└$(printf '─%.0s' $(seq 1 $((width - 2))))┘${NC}"
}

# Format timestamp
format_time() {
    local timestamp=$1
    date -r "$timestamp" "+%H:%M:%S" 2>/dev/null || echo "N/A"
}

# Get service status
check_service_status() {
    local url=$1
    if curl -s --fail --max-time 1 "$url" > /dev/null 2>&1; then
        echo "ok"
    else
        echo "down"
    fi
}

# Get metrics
get_metrics() {
    # Registry metrics
    local registry_exists="no"
    local registry_projects=0
    local registry_age="N/A"

    if [[ -f "$REGISTRY_FILE" ]]; then
        registry_exists="yes"
        registry_projects=$(jq -r '.projects | length // 0' "$REGISTRY_FILE" 2>/dev/null || echo 0)
        local mtime=$(stat -f %m "$REGISTRY_FILE" 2>/dev/null || stat -c %Y "$REGISTRY_FILE" 2>/dev/null)
        local now=$(date +%s)
        local age_seconds=$((now - mtime))
        if [[ $age_seconds -lt 60 ]]; then
            registry_age="${age_seconds}s ago"
        elif [[ $age_seconds -lt 3600 ]]; then
            registry_age="$((age_seconds / 60))m ago"
        else
            registry_age="$((age_seconds / 3600))h ago"
        fi
    fi

    # Observation metrics
    local obs_count=0
    local latest_obs="N/A"
    if [[ -d "$OBSERVATIONS_DIR" ]]; then
        obs_count=$(find "$OBSERVATIONS_DIR" -name "*.ndjson" 2>/dev/null | wc -l | tr -d ' ')
        local latest_file=$(find "$OBSERVATIONS_DIR" -name "*.ndjson" -type f 2>/dev/null | xargs ls -t 2>/dev/null | head -1)
        if [[ -n "$latest_file" ]]; then
            local mtime=$(stat -f %m "$latest_file" 2>/dev/null || stat -c %Y "$latest_file" 2>/dev/null)
            latest_obs=$(format_time "$mtime")
        fi
    fi

    # Bridge status
    local bridge_status=$(check_service_status "$BRIDGE_URL/api/projects")
    local bridge_health="N/A"
    local bridge_projects=0

    if [[ "$bridge_status" == "ok" ]]; then
        local status_json=$(curl -s "$BRIDGE_URL/api/self-status" 2>/dev/null)
        bridge_health=$(echo "$status_json" | jq -r '.health // "unknown"' 2>/dev/null || echo "error")
        bridge_projects=$(curl -s "$BRIDGE_URL/api/projects" 2>/dev/null | jq -r '.projects | length // 0' 2>/dev/null || echo 0)
    fi

    # Output all metrics
    echo "$registry_exists|$registry_projects|$registry_age|$obs_count|$latest_obs|$bridge_status|$bridge_health|$bridge_projects"
}

# Display dashboard
display_dashboard() {
    local metrics=$1
    IFS='|' read -r registry_exists registry_projects registry_age obs_count latest_obs bridge_status bridge_health bridge_projects <<< "$metrics"

    clear_screen

    # Header
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║               SYSTEM HEALTH DASHBOARD                           ║${NC}"
    echo -e "${BOLD}${CYAN}║                $(date '+%Y-%m-%d %H:%M:%S')                       ║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}\n"

    # Services Status
    draw_box 68 "Service Status" "$MAGENTA"

    # HTTP Bridge
    local bridge_indicator="${GREEN}● ONLINE${NC}"
    local bridge_color=$GREEN
    if [[ "$bridge_status" != "ok" ]]; then
        bridge_indicator="${RED}● OFFLINE${NC}"
        bridge_color=$RED
    elif [[ "$bridge_health" != "ok" && "$bridge_health" != "N/A" ]]; then
        bridge_indicator="${YELLOW}● DEGRADED${NC}"
        bridge_color=$YELLOW
    fi

    echo -e "${MAGENTA}│${NC} HTTP Bridge (port 7171):  $bridge_indicator"
    echo -e "${MAGENTA}│${NC}   Health: ${bridge_color}$bridge_health${NC}    Projects served: ${BOLD}$bridge_projects${NC}"
    echo -e "${MAGENTA}│${NC}"

    # MCP Server (check if running via processes)
    local mcp_running="unknown"
    if pgrep -f "devops-mcp" > /dev/null 2>&1; then
        mcp_running="ok"
        echo -e "${MAGENTA}│${NC} MCP Server:               ${GREEN}● RUNNING${NC}"
    else
        echo -e "${MAGENTA}│${NC} MCP Server:               ${YELLOW}● NOT DETECTED${NC}"
    fi

    draw_box_end 68 "$MAGENTA"
    echo

    # Registry Status
    draw_box 68 "Registry Status" "$BLUE"

    if [[ "$registry_exists" == "yes" ]]; then
        echo -e "${BLUE}│${NC} Status:        ${GREEN}ACTIVE${NC}"
        echo -e "${BLUE}│${NC} Projects:      ${BOLD}$registry_projects${NC}"
        echo -e "${BLUE}│${NC} Last updated:  $registry_age"

        # Sync status
        if [[ $registry_projects -eq $bridge_projects ]]; then
            echo -e "${BLUE}│${NC} Sync:          ${GREEN}✓ In sync with bridge${NC}"
        else
            echo -e "${BLUE}│${NC} Sync:          ${YELLOW}⚠ Bridge has different count ($bridge_projects)${NC}"
        fi
    else
        echo -e "${BLUE}│${NC} Status:        ${RED}MISSING${NC}"
        echo -e "${BLUE}│${NC} Run discovery: ${YELLOW}curl http://localhost:7171/api/discover${NC}"
    fi

    draw_box_end 68 "$BLUE"
    echo

    # Observations Status
    draw_box 68 "Observations" "$CYAN"

    echo -e "${CYAN}│${NC} Total files:   ${BOLD}$obs_count${NC}"
    echo -e "${CYAN}│${NC} Latest:        $latest_obs"

    if [[ $obs_count -eq 0 ]]; then
        echo -e "${CYAN}│${NC} ${YELLOW}No observations yet. Run an observer to generate data.${NC}"
    fi

    draw_box_end 68 "$CYAN"
    echo

    # Quick Actions
    draw_box 68 "Quick Actions" "$YELLOW"
    echo -e "${YELLOW}│${NC} ${BOLD}d${NC} - Run discovery    ${BOLD}v${NC} - Validate integration    ${BOLD}q${NC} - Quit"
    echo -e "${YELLOW}│${NC} ${BOLD}r${NC} - Refresh now      ${BOLD}o${NC} - Run observer (git)"
    draw_box_end 68 "$YELLOW"
    echo

    # Status line
    echo -e "${BLUE}Auto-refresh every ${UPDATE_INTERVAL}s | Press key for action | Ctrl+C to exit${NC}"
}

# Run discovery
run_discovery() {
    echo -e "\n${YELLOW}Running project discovery...${NC}"
    curl -s "$BRIDGE_URL/api/discover" | jq '.'
    echo -e "\n${GREEN}Discovery complete. Press any key to continue...${NC}"
    read -n 1 -s
}

# Run validation
run_validation() {
    echo -e "\n${YELLOW}Running integration validation...${NC}"
    "$(dirname "$0")/validate-integration.sh"
    echo -e "\n${GREEN}Validation complete. Press any key to continue...${NC}"
    read -n 1 -s
}

# Run observer
run_observer() {
    echo -e "\n${YELLOW}Select a project to observe (or press Enter to cancel):${NC}"

    # Get first 5 projects
    local projects=$(jq -r '.projects[:5] | .[] | "\(.id) - \(.name)"' "$REGISTRY_FILE" 2>/dev/null)

    if [[ -z "$projects" ]]; then
        echo -e "${RED}No projects found. Run discovery first.${NC}"
        read -n 1 -s
        return
    fi

    echo "$projects" | nl -v 1
    echo -n "Selection: "
    read -r selection

    if [[ -z "$selection" ]]; then
        return
    fi

    local project_id=$(echo "$projects" | sed -n "${selection}p" | cut -d' ' -f1)

    if [[ -n "$project_id" ]]; then
        echo -e "${YELLOW}Running git observer for project $project_id...${NC}"
        curl -X POST "$BRIDGE_URL/api/tools/project_obs_run" \
             -H "Content-Type: application/json" \
             -d "{\"project_id\": \"$project_id\", \"observer\": \"git\"}" | jq '.'
        echo -e "\n${GREEN}Observer complete. Press any key to continue...${NC}"
        read -n 1 -s
    fi
}

# Main loop
main() {
    # Trap Ctrl+C
    trap "echo -e '\n${GREEN}Exiting...${NC}'; exit 0" INT

    while true; do
        # Get current metrics
        metrics=$(get_metrics)

        # Display dashboard
        display_dashboard "$metrics"

        # Wait for input with timeout
        if read -t "$UPDATE_INTERVAL" -n 1 -s key; then
            case "$key" in
                d|D) run_discovery ;;
                v|V) run_validation ;;
                o|O) run_observer ;;
                r|R) continue ;;
                q|Q) echo -e "\n${GREEN}Exiting...${NC}"; exit 0 ;;
            esac
        fi
    done
}

# Run main
main "$@"
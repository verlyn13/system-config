#!/bin/bash
# Dependencies Observer - Analyzes package manager dependencies
# Supports npm, pip, cargo with safe execution

set -euo pipefail

# Configuration
readonly PROJECT_PATH="${1:?Project path required}"
readonly PROJECT_ID="${2:?Project ID required}"
readonly PACKAGE_MANAGER="${3:-auto}"
readonly RUN_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
readonly TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
readonly TIMEOUT=30

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

# Detect package manager
detect_package_manager() {
    if [[ -f "$PROJECT_PATH/package.json" ]]; then
        echo "npm"
    elif [[ -f "$PROJECT_PATH/requirements.txt" ]] || [[ -f "$PROJECT_PATH/pyproject.toml" ]]; then
        echo "pip"
    elif [[ -f "$PROJECT_PATH/Cargo.toml" ]]; then
        echo "cargo"
    elif [[ -f "$PROJECT_PATH/go.mod" ]]; then
        echo "go"
    else
        echo "unknown"
    fi
}

# Check npm dependencies
check_npm() {
    cd "$PROJECT_PATH" || return 1

    # Get outdated packages (npm outdated exits non-zero when packages are outdated)
    local outdated_json=$(timeout "$TIMEOUT" npm outdated --json 2>/dev/null || echo '{}')
    local outdated_count=$(echo "$outdated_json" | jq 'length')
    local outdated_major=0

    # Count major version differences
    if [[ "$outdated_count" -gt 0 ]]; then
        outdated_major=$(echo "$outdated_json" | jq '
            [.[] | select(.wanted != .latest) |
             if (.current | split(".")[0]) != (.latest | split(".")[0])
             then 1 else 0 end
            ] | add // 0
        ')
    fi

    # Run security audit (also may exit non-zero)
    local audit_json=$(timeout "$TIMEOUT" npm audit --json 2>/dev/null || echo '{"metadata": {"vulnerabilities": {}}}')
    local vuln_total=$(echo "$audit_json" | jq '.metadata.vulnerabilities.total // 0')
    local vuln_critical=$(echo "$audit_json" | jq '.metadata.vulnerabilities.critical // 0')
    local vuln_high=$(echo "$audit_json" | jq '.metadata.vulnerabilities.high // 0')

    echo "{
        \"outdated\": $outdated_count,
        \"outdated_major\": $outdated_major,
        \"vulnerable\": $vuln_total,
        \"vuln_critical\": $vuln_critical,
        \"vuln_high\": $vuln_high
    }"
}

# Check Python dependencies
check_pip() {
    cd "$PROJECT_PATH" || return 1

    # Check for virtual environment
    local pip_cmd="pip"
    if [[ -f ".venv/bin/pip" ]]; then
        pip_cmd=".venv/bin/pip"
    elif [[ -f "venv/bin/pip" ]]; then
        pip_cmd="venv/bin/pip"
    fi

    # Get outdated packages
    local outdated_json=$($pip_cmd list --outdated --format=json 2>/dev/null || echo '[]')
    local outdated_count=$(echo "$outdated_json" | jq 'length')

    # Count major version differences
    local outdated_major=0
    if [[ "$outdated_count" -gt 0 ]]; then
        outdated_major=$(echo "$outdated_json" | jq '
            [.[] |
             if (.version | split(".")[0]) != (.latest_version | split(".")[0])
             then 1 else 0 end
            ] | add // 0
        ')
    fi

    # Check for pip-audit if available
    local vuln_total=0
    local vuln_critical=0
    if command -v pip-audit &>/dev/null; then
        local audit_json=$(timeout "$TIMEOUT" pip-audit --format json 2>/dev/null || echo '[]')
        vuln_total=$(echo "$audit_json" | jq 'length')
        vuln_critical=$(echo "$audit_json" | jq '[.[] | select(.severity == "CRITICAL")] | length')
    fi

    echo "{
        \"outdated\": $outdated_count,
        \"outdated_major\": $outdated_major,
        \"vulnerable\": $vuln_total,
        \"vuln_critical\": $vuln_critical,
        \"vuln_high\": 0
    }"
}

# Check Rust dependencies
check_cargo() {
    cd "$PROJECT_PATH" || return 1

    # Check for outdated crates
    local outdated_count=0
    if command -v cargo-outdated &>/dev/null; then
        outdated_count=$(timeout "$TIMEOUT" cargo outdated --format json 2>/dev/null | jq '.dependencies | length' || echo "0")
    fi

    # Check for security vulnerabilities
    local vuln_total=0
    local vuln_critical=0
    if command -v cargo-audit &>/dev/null; then
        local audit_json=$(timeout "$TIMEOUT" cargo audit --json 2>/dev/null || echo '{"vulnerabilities": {"count": 0}}')
        vuln_total=$(echo "$audit_json" | jq '.vulnerabilities.count // 0')
    fi

    echo "{
        \"outdated\": $outdated_count,
        \"outdated_major\": 0,
        \"vulnerable\": $vuln_total,
        \"vuln_critical\": $vuln_critical,
        \"vuln_high\": 0
    }"
}

# Determine status based on metrics
determine_status() {
    local outdated="$1"
    local vulnerable="$2"
    local vuln_critical="$3"

    if [[ "$vuln_critical" -gt 0 ]]; then
        echo "fail"
    elif [[ "$vulnerable" -gt 0 ]] || [[ "$outdated" -gt 10 ]]; then
        echo "warn"
    else
        echo "ok"
    fi
}

# Main execution
main() {
    validate_path "$PROJECT_PATH"
    local start_time=$(date +%s)

    # Detect or use specified package manager
    local pm="$PACKAGE_MANAGER"
    if [[ "$pm" == "auto" ]]; then
        pm=$(detect_package_manager)
    fi

    if [[ "$pm" == "unknown" ]]; then
        jq -nc \
          --arg run_id "$RUN_ID" --arg timestamp "$TIMESTAMP" --arg project_id "$PROJECT_ID" \
          '{apiVersion:"obs.v1",run_id:$run_id,timestamp:$timestamp,project_id:$project_id,observer:"deps",summary:"No supported package manager found",metrics:{error:1},status:"fail",error:{code:"NO_PACKAGE_MANAGER",message:"Could not detect package manager"}}'
        exit 0
    fi

    # Check dependencies based on package manager
    local deps_info
    case "$pm" in
        npm)
            deps_info=$(check_npm)
            ;;
        pip)
            deps_info=$(check_pip)
            ;;
        cargo)
            deps_info=$(check_cargo)
            ;;
        *)
            deps_info='{"outdated": 0, "vulnerable": 0, "vuln_critical": 0}'
            ;;
    esac

    # Extract metrics
    local outdated=$(echo "$deps_info" | jq -r '.outdated')
    local outdated_major=$(echo "$deps_info" | jq -r '.outdated_major // 0')
    local vulnerable=$(echo "$deps_info" | jq -r '.vulnerable')
    local vuln_critical=$(echo "$deps_info" | jq -r '.vuln_critical')
    local vuln_high=$(echo "$deps_info" | jq -r '.vuln_high // 0')

    # Calculate latency
    local end_time=$(date +%s)
    local latency=$((end_time - start_time))

    # Determine status
    local status=$(determine_status "$outdated" "$vulnerable" "$vuln_critical")

    # Create summary
    local summary="${outdated} outdated, ${vulnerable} vulnerable"
    if [[ "$vuln_critical" -gt 0 ]]; then
        summary="$summary (${vuln_critical} CRITICAL)"
    fi

    # Output NDJSON
    jq -nc \
      --arg run_id "$RUN_ID" \
      --arg timestamp "$TIMESTAMP" \
      --arg project_id "$PROJECT_ID" \
      --arg observer "deps" \
      --arg summary "$summary" \
      --arg pm "$pm" \
      --arg status "$status" \
      --argjson outdated "$outdated" \
      --argjson outdated_major "$outdated_major" \
      --argjson vulnerable "$vulnerable" \
      --argjson vuln_critical "$vuln_critical" \
      --argjson vuln_high "$vuln_high" \
      --argjson latency "$latency" \
      '{apiVersion:"obs.v1",run_id:$run_id,timestamp:$timestamp,project_id:$project_id,observer:$observer,summary:$summary,metrics:{package_manager:$pm,outdated:$outdated,outdated_major:$outdated_major,vulnerable:$vulnerable,vuln_critical:$vuln_critical,vuln_high:$vuln_high,latency_ms:$latency},status:$status}'
}

# Run main function
main

#!/usr/bin/env bash
# Enhanced client generation with Docker Engine v28.x + Compose v2.39+ patterns
set -euo pipefail

# Version compatibility checks
check_docker_versions() {
    local docker_version docker_major compose_version compose_major compose_minor

    if ! command -v docker >/dev/null 2>&1; then
        echo "❌ Docker not found. Please install Docker Engine v28.x" >&2
        exit 1
    fi

    docker_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "0.0.0")
    docker_major=$(echo "$docker_version" | cut -d. -f1)

    if [[ $docker_major -lt 28 ]]; then
        echo "⚠️  Docker Engine v$docker_version detected. Recommend upgrading to v28.x for latest features" >&2
    fi

    if ! command -v docker compose >/dev/null 2>&1; then
        echo "❌ Docker Compose v2 not found. Please upgrade to Compose v2.38.1+" >&2
        exit 1
    fi

    compose_version=$(docker compose version --short 2>/dev/null | sed 's/^v//')
    compose_major=$(echo "$compose_version" | cut -d. -f1)
    compose_minor=$(echo "$compose_version" | cut -d. -f2)

    if [[ $compose_major -lt 2 ]] || [[ $compose_major -eq 2 && $compose_minor -lt 38 ]]; then
        echo "⚠️  Docker Compose v$compose_version detected. Recommend v2.38.1+ for latest features" >&2
    fi

    echo "✅ Docker Engine v$docker_version + Compose v$compose_version"
}

# Generate client using modern Docker patterns
generate_client_modern() {
    local service_url="$1"
    local output_dir="$2"
    local service_name="$3"

    echo "🔧 Generating $service_name client using Docker..."

    # Create output directory
    mkdir -p "$output_dir"

    # Use BuildKit with explicit features
    export DOCKER_BUILDKIT=1
    export BUILDKIT_PROGRESS=plain

    # Modern docker run with enhanced security and performance
    docker run --rm \
        --security-opt no-new-privileges:true \
        --read-only \
        --tmpfs /tmp \
        --user "$(id -u):$(id -g)" \
        --mount type=bind,source="$(pwd)/$output_dir",target=/local/output \
        --network host \
        openapitools/openapi-generator-cli:latest \
        generate \
        -g typescript-axios \
        -o /local/output \
        -i "$service_url/openapi.yaml" \
        --skip-validate-spec \
        --enable-post-process-file \
        --additional-properties=withInterfaces=true,modelPropertyNaming=camelCase

    echo "✅ $service_name client generated in $output_dir"
}

# Generate using Compose for complex scenarios
generate_with_compose() {
    local service_name="$1"

    echo "🔧 Using Docker Compose for $service_name generation..."

    # Use modern compose v2 syntax with profiles
    docker compose --profile tools run --rm client-generator \
        generate -g typescript-axios \
        -o "/local/generated/$service_name-client" \
        -i "http://bridge:7171/openapi.yaml" \
        --skip-validate-spec

    echo "✅ $service_name client generated via Compose"
}

# Main execution
main() {
    local mode="${1:-direct}"
    local service="${2:-bridge}"
    local url="${3:-http://127.0.0.1:7171}"
    local output="${4:-generated/${service}-client}"

    echo "🚀 Client Generation with 2025 Docker Patterns"
    echo "================================================"

    # Version checks
    check_docker_versions

    case "$mode" in
        "compose")
            generate_with_compose "$service"
            ;;
        "direct"|*)
            generate_client_modern "$url" "$output" "$service"
            ;;
    esac

    echo ""
    echo "🎉 Client generation complete!"
    echo "📁 Output: $output"
    echo "📖 See docs/guides/client-generation.md for integration guidance"
}

# Handle script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
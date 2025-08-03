#!/bin/bash
# OpenCode Container Build Script - Streamlined for local development

set -e

# === CONFIGURATION ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOCKER_CONTEXT="$PROJECT_ROOT/docker/opencode"

# Load logging module
source "$SCRIPT_DIR/lib/logging.sh" && setup_logging "build.sh"

# === FUNCTIONS ===

# Display usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Build OpenCode container for local development.

OPTIONS:
    -o, --openrouter-api-key KEY  Set OPENROUTER_API_KEY (required)
    -g, --github-token TOKEN      Set GITHUB_TOKEN (optional)
    -m, --magic-key KEY          Set TWENTY_FIRST_API_KEY (optional)
    -tf, --terraform-token TOKEN Set TF_CLOUD_TOKEN (optional, READ-ONLY)
    -gcp, --gcp-credentials PATH Set GOOGLE_APPLICATION_CREDENTIALS (optional, READ-ONLY)
    -t, --tag TAG                Docker image tag (default: latest)
    -n, --no-cache               Build without Docker cache
    -h, --help                   Show this help message

EXAMPLES:
    $0 --openrouter-api-key "your-api-key"
    $0 -o "your-api-key" -g "your-github-token" --no-cache
    $0 -o "your-api-key" -tf "your-readonly-tf-token" -gcp "/path/to/service-account.json"

SECURITY NOTE:
    Terraform and GCP credentials MUST be READ-ONLY for security compliance.

After building, start OpenCode: ./scripts/start-opencode.sh
EOF
}

# Check prerequisites and validate inputs
check_prerequisites() {
    # Check Docker and Docker Compose
    command -v docker >/dev/null || { log_error "prerequisites" "Docker not found"; exit 1; }
    docker info >/dev/null 2>&1 || { log_error "prerequisites" "Docker daemon not running"; exit 1; }

    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        log_error "prerequisites" "Docker Compose not found"
        exit 1
    fi

    # Check project structure
    [[ -f "$PROJECT_ROOT/docker-compose.yml" ]] || {
        log_error "prerequisites" "Run script from project root (docker-compose.yml not found)"
        exit 1
    }

    log_info "prerequisites" "Prerequisites validated"
}

# Validate API key and setup directories
validate_and_setup() {
    local api_key="$1"

    [[ -n "$api_key" ]] || {
        log_error "validation" "OpenRouter API key required (use -o or set OPENROUTER_API_KEY)"
        exit 1
    }

    [[ ${#api_key} -ge 20 ]] || log_warn "validation" "API key seems short, please verify"

    # Create required directories
    mkdir -p "$PROJECT_ROOT/.opencode/agent" "$PROJECT_ROOT/.ai/templates" "$PROJECT_ROOT/.ai/standards" || {
        log_error "setup" "Failed to create directories"
        exit 1
    }

    log_info "validation" "API key validated and directories created"
}

# Build Docker image
build_image() {
    local tag="$1"
    local no_cache="$2"

    local build_args=""
    [[ "$no_cache" == "true" ]] && build_args="--no-cache"

    log_info "docker_build" "Building OpenCode image: horizon-sdlc/opencode:$tag"

    if docker build $build_args -t "horizon-sdlc/opencode:$tag" "$DOCKER_CONTEXT"; then
        log_info "docker_build" "Image built successfully"
    else
        log_error "docker_build" "Build failed"
        exit 1
    fi
}

# Create environment file
create_env_file() {
    local api_key="$1" github_token="$2" magic_key="$3" tf_token="$4" gcp_credentials="$5"
    local env_file="$PROJECT_ROOT/.env"

    cat > "$env_file" << EOF
# OpenCode Environment Configuration - Generated $(date +%Y-%m-%d)
OPENROUTER_API_KEY=$api_key
GITHUB_TOKEN=${github_token:-}
TWENTY_FIRST_API_KEY=${magic_key:-}

# Terraform Cloud integration (READ-ONLY)
TF_CLOUD_TOKEN=${tf_token:-}

# Google Cloud Platform credentials (READ-ONLY)
GOOGLE_APPLICATION_CREDENTIALS=${gcp_credentials:-}

# Container configuration
NODE_ENV=production
LOG_LEVEL=info
MCP_SERVER_TIMEOUT=30000
MCP_SERVER_RETRIES=3
EOF

    chmod 600 "$env_file" 2>/dev/null || log_warn "env_setup" "Could not secure .env file permissions"
    log_info "env_setup" "Environment file created: $env_file"

    # Validate credentials if provided
    if [[ -n "$tf_token" ]]; then
        log_info "env_setup" "Terraform Cloud token configured (ensure it's READ-ONLY)"
    fi

    if [[ -n "$gcp_credentials" ]]; then
        if [[ -f "$gcp_credentials" ]]; then
            log_info "env_setup" "GCP credentials file configured: $gcp_credentials"
        else
            log_warn "env_setup" "GCP credentials file not found: $gcp_credentials"
        fi
    fi
}

# Comprehensive container cleanup function
cleanup_test_containers() {
    local compose_cmd="$1"
    log_info "cleanup" "Cleaning up test containers..."

    # Stop and remove containers
    $compose_cmd down --timeout 10 >/dev/null 2>&1 || true
    docker rm -f horizon-opencode >/dev/null 2>&1 || true

    # Remove any orphaned containers with the same image
    docker ps -a --filter "ancestor=horizon-sdlc/opencode:latest" --format "{{.ID}}" | xargs -r docker rm -f >/dev/null 2>&1 || true
}

# Test container functionality with robust cleanup
test_container() {
    log_info "container_test" "Testing container functionality..."

    # Detect compose command
    local compose_cmd="docker-compose"
    command -v docker >/dev/null && docker compose version >/dev/null 2>&1 && compose_cmd="docker compose"

    # Setup cleanup trap for this function
    trap "cleanup_test_containers '$compose_cmd'" EXIT ERR

    # Initial cleanup
    cleanup_test_containers "$compose_cmd"

    # Test container startup
    if ! $compose_cmd up -d opencode >/dev/null 2>&1; then
        log_error "container_test" "Failed to start container for testing"
        cleanup_test_containers "$compose_cmd"
        exit 1
    fi

    # Wait for container to be ready
    sleep 3

    # Test OpenCode functionality
    if test_output=$($compose_cmd exec -T opencode opencode --print-logs --version 2>&1); then
        log_info "container_test" "Test passed - OpenCode version: $test_output"
        cleanup_test_containers "$compose_cmd"
        trap - EXIT ERR  # Remove trap on success
    else
        log_error "container_test" "Test failed: $test_output"
        cleanup_test_containers "$compose_cmd"
        exit 1
    fi
}

# === MAIN EXECUTION ===
main() {
    local api_key="" github_token="" magic_key="" tf_token="" gcp_credentials="" tag="latest" no_cache="false"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -o|--openrouter-api-key) api_key="$2"; shift 2 ;;
            -g|--github-token) github_token="$2"; shift 2 ;;
            -m|--magic-key) magic_key="$2"; shift 2 ;;
            -tf|--terraform-token) tf_token="$2"; shift 2 ;;
            -gcp|--gcp-credentials) gcp_credentials="$2"; shift 2 ;;
            -t|--tag) tag="$2"; shift 2 ;;
            -n|--no-cache) no_cache="true"; shift ;;
            -h|--help) usage; exit 0 ;;
            *) log_error "args" "Unknown option: $1. Use --help for usage."; exit 1 ;;
        esac
    done

    # Use environment variables as fallback
    api_key="${api_key:-$OPENROUTER_API_KEY}"
    github_token="${github_token:-$GITHUB_TOKEN}"
    magic_key="${magic_key:-$TWENTY_FIRST_API_KEY}"
    tf_token="${tf_token:-$TF_CLOUD_TOKEN}"
    gcp_credentials="${gcp_credentials:-$GOOGLE_APPLICATION_CREDENTIALS}"

    log_info "build_start" "Starting OpenCode container build..."

    # Execute build process
    check_prerequisites
    validate_and_setup "$api_key"
    build_image "$tag" "$no_cache"
    create_env_file "$api_key" "$github_token" "$magic_key" "$tf_token" "$gcp_credentials"
    test_container

    log_info "build_complete" "Build completed successfully!"
    log_info "next_steps" "Start OpenCode: ./scripts/start-opencode.sh"

    cleanup_logging "build.sh"
}

# === EXECUTION ===
trap 'cleanup_logging "build.sh"; exit 1' INT TERM
main "$@"


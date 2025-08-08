#!/bin/bash
# OpenCode Container Startup Script - Enhanced with environment configuration
# Usage: ./start-opencode.sh [OPTIONS]

set -euo pipefail

# === CONFIGURATION ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE_FILE="docker-compose.yml"
SERVICE_NAME="opencode"
DEBUG_MODE=false
PRINT_LOGS=false

# Load logging module
source "$SCRIPT_DIR/lib/logging.sh" && setup_logging "start-opencode.sh"

# === CORE FUNCTIONS ===

# Display usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Start OpenCode container with optional environment configuration.

OPTIONS:
    -o, --openrouter-api-key KEY  Set OPENROUTER_API_KEY (required if no .env exists)
    -g, --github-token TOKEN      Set GITHUB_TOKEN (optional)
    -m, --magic-key KEY          Set TWENTY_FIRST_API_KEY (optional)
    -tf, --terraform-token TOKEN Set TF_CLOUD_TOKEN (optional, READ-ONLY)
    -gcp, --gcp-credentials PATH Set GOOGLE_APPLICATION_CREDENTIALS (optional, READ-ONLY)
    --debug, bash                Start in debug mode with interactive bash shell
    --print-logs                 Start OpenCode with console logging enabled
    -h, --help                   Show this help message

EXAMPLES:
    $0                                                    Start with existing .env file
    $0 --openrouter-api-key "your-api-key"              Start with API key configuration
    $0 -o "your-api-key" -g "your-github-token"         Start with multiple configurations
    $0 --debug                                           Start in debug mode
    $0 -o "your-api-key" --print-logs                   Start with API key and console logging

SECURITY NOTE:
    Terraform and GCP credentials MUST be READ-ONLY for security compliance.

BACKWARD COMPATIBILITY:
    If no API key parameters are provided, the script will use an existing .env file.
    If .env file doesn't exist and no parameters are provided, the script will exit with an error.
EOF
}

# Check prerequisites (Docker Compose, files, environment)
check_prerequisites() {
    local require_env_file="$1"

    # Detect Docker Compose command
    if command -v docker-compose &>/dev/null; then
        COMPOSE_CMD="docker-compose"
    elif command -v docker &>/dev/null && docker compose version &>/dev/null; then
        COMPOSE_CMD="docker compose"
    else
        log_error "prerequisites" "Docker Compose not found. Please install Docker Compose."
        exit 1
    fi

    # Check required files
    [[ -f "$COMPOSE_FILE" ]] || { log_error "prerequisites" "Docker Compose file not found: $COMPOSE_FILE"; exit 1; }

    # Check .env file only if required (backward compatibility)
    if [[ "$require_env_file" == "true" ]]; then
        [[ -f ".env" ]] || {
            log_error "prerequisites" ".env file required with OPENROUTER_API_KEY. Use --openrouter-api-key to create one."
            exit 1
        }
    fi

    log_info "prerequisites" "Using $COMPOSE_CMD with $COMPOSE_FILE"
}

# Validate API key and setup directories
validate_and_setup() {
    local api_key="$1"

    [[ -n "$api_key" ]] || {
        log_error "validation" "OpenRouter API key required (use -o or ensure .env file exists)"
        exit 1
    }

    [[ ${#api_key} -ge 20 ]] || log_warn "validation" "API key seems short, please verify"

    # Create required directories if they don't exist
    mkdir -p "$PROJECT_ROOT/.opencode/agent" "$PROJECT_ROOT/.ai/templates" "$PROJECT_ROOT/.ai/standards" || {
        log_error "setup" "Failed to create directories"
        exit 1
    }

    log_info "validation" "API key validated and directories created"
}

# Create or update environment file
create_or_update_env_file() {
    local api_key="$1" github_token="$2" magic_key="$3" tf_token="$4" gcp_credentials="$5"
    local env_file="$PROJECT_ROOT/.env"
    local backup_created=false

    # Backup existing .env file if it exists
    if [[ -f "$env_file" ]]; then
        cp "$env_file" "$env_file.backup.$(date +%Y%m%d_%H%M%S)"
        backup_created=true
        log_info "env_setup" "Existing .env file backed up"
    fi

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

    if [[ "$backup_created" == "true" ]]; then
        log_info "env_setup" "Environment file updated: $env_file"
    else
        log_info "env_setup" "Environment file created: $env_file"
    fi

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
cleanup_containers() {
    log_info "cleanup" "Cleaning up containers..."

    # Stop and remove containers with timeout
    $COMPOSE_CMD down --timeout 10 >/dev/null 2>&1 || true
    docker rm -f horizon-opencode >/dev/null 2>&1 || true

    # Remove any orphaned containers with the same image
    docker ps -a --filter "ancestor=horizon-sdlc/opencode:latest" --format "{{.ID}}" | xargs -r docker rm -f >/dev/null 2>&1 || true
}

# Start container service with robust error handling
start_container() {
    local container_args=()

    # Determine container startup arguments based on mode
    if [[ "$DEBUG_MODE" == "true" ]]; then
        container_args=("--debug")
    elif [[ "$PRINT_LOGS" == "true" ]]; then
        container_args=("--print-logs")
    fi

    # Initial cleanup to prevent conflicts
    cleanup_containers

    log_info "startup" "Starting OpenCode service..."

    # For interactive TUI mode, run container directly attached to terminal
    if [[ "$DEBUG_MODE" != "true" ]]; then
        log_info "startup" "Starting OpenCode TUI in interactive mode..."

        # Run container interactively with TTY allocation
        if [[ ${#container_args[@]} -gt 0 ]]; then
            exec $COMPOSE_CMD run --rm --name "horizon-opencode" "$SERVICE_NAME" "${container_args[@]}"
        else
            exec $COMPOSE_CMD run --rm --name "horizon-opencode" "$SERVICE_NAME"
        fi
    else
        # For debug mode, start detached and then exec into it
        if [[ ${#container_args[@]} -gt 0 ]]; then
            # Use docker-compose run for containers that need arguments passed to entrypoint
            if ! $COMPOSE_CMD run --rm -d --name "horizon-opencode" "$SERVICE_NAME" "${container_args[@]}" >/dev/null 2>&1; then
                log_error "startup" "Failed to start service with arguments: ${container_args[*]}"
                cleanup_containers
                exit 1
            fi
        else
            # Use docker-compose up for normal startup
            if ! $COMPOSE_CMD up -d "$SERVICE_NAME" >/dev/null 2>&1; then
                log_error "startup" "Failed to start service"
                cleanup_containers
                exit 1
            fi
        fi

        # Wait for container readiness with timeout
        local attempt=1
        local max_attempts=10

        while [[ $attempt -le $max_attempts ]]; do
            if docker ps --filter "name=horizon-opencode" --filter "status=running" | grep -q "horizon-opencode"; then
                log_info "startup" "Container ready"
                return 0
            fi

            log_info "startup" "Waiting for container... (attempt $attempt/$max_attempts)"
            sleep 2 && ((attempt++))
        done

        log_error "startup" "Container failed to start within expected time"
        cleanup_containers
        exit 1
    fi
}

# Execute container session based on mode
execute_container_session() {
    # Only needed for debug mode since normal mode runs interactively
    if [[ "$DEBUG_MODE" == "true" ]]; then
        local session_description=""

        # Determine session type based on flags
        if [[ "$PRINT_LOGS" == "true" ]]; then
            session_description="debug mode with console logging"
        else
            session_description="debug shell"
        fi

        log_info "session" "Starting $session_description session (Ctrl+C to exit)"
        log_info "session" "Container started in debug mode - you now have a bash shell"

        if docker exec -it "horizon-opencode" bash; then
            log_info "session" "Debug session ended successfully"
        else
            log_warn "session" "Debug session ended with error"
        fi
    fi
    # For normal mode, the container is already running interactively via exec in start_container()
}

# Cleanup on exit - use comprehensive cleanup
cleanup() {
    cleanup_containers
    cleanup_logging "start-opencode.sh"
}

# === ARGUMENT PARSING ===
parse_args() {
    local api_key="" github_token="" magic_key="" tf_token="" gcp_credentials=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -o|--openrouter-api-key) api_key="$2"; shift 2 ;;
            -g|--github-token) github_token="$2"; shift 2 ;;
            -m|--magic-key) magic_key="$2"; shift 2 ;;
            -tf|--terraform-token) tf_token="$2"; shift 2 ;;
            -gcp|--gcp-credentials) gcp_credentials="$2"; shift 2 ;;
            --debug|bash)
                DEBUG_MODE=true
                shift
                ;;
            --print-logs)
                PRINT_LOGS=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "args" "Unknown option: $1. Use --help for usage."
                exit 1
                ;;
        esac
    done

    # Use environment variables as fallback (handle unset variables safely)
    api_key="${api_key:-${OPENROUTER_API_KEY:-}}"
    github_token="${github_token:-${GITHUB_TOKEN:-}}"
    magic_key="${magic_key:-${TWENTY_FIRST_API_KEY:-}}"
    tf_token="${tf_token:-${TF_CLOUD_TOKEN:-}}"
    gcp_credentials="${gcp_credentials:-${GOOGLE_APPLICATION_CREDENTIALS:-}}"

    # Return parsed values via global variables for main function
    PARSED_API_KEY="$api_key"
    PARSED_GITHUB_TOKEN="$github_token"
    PARSED_MAGIC_KEY="$magic_key"
    PARSED_TF_TOKEN="$tf_token"
    PARSED_GCP_CREDENTIALS="$gcp_credentials"
}

# === MAIN EXECUTION ===
main() {
    parse_args "$@"

    local mode_description=""
    if [[ "$DEBUG_MODE" == "true" && "$PRINT_LOGS" == "true" ]]; then
        mode_description="DEBUG + CONSOLE LOGGING"
    elif [[ "$DEBUG_MODE" == "true" ]]; then
        mode_description="DEBUG"
    elif [[ "$PRINT_LOGS" == "true" ]]; then
        mode_description="CONSOLE LOGGING"
    else
        mode_description="INTERACTIVE TUI"
    fi

    log_info "main" "Starting OpenCode Development Environment ($mode_description mode)"

    # Determine if we need to create/update .env file
    local need_env_creation=false
    local require_existing_env=true

    if [[ -n "$PARSED_API_KEY" ]]; then
        need_env_creation=true
        require_existing_env=false
        log_info "main" "API key provided - will create/update .env file"
    elif [[ ! -f ".env" ]]; then
        log_error "main" "No .env file found and no API key provided. Use --openrouter-api-key or create .env file."
        exit 1
    else
        log_info "main" "Using existing .env file"
    fi

    # Setup and checks
    trap cleanup SIGINT SIGTERM
    check_prerequisites "$require_existing_env"

    # Create or update environment file if API key was provided
    if [[ "$need_env_creation" == "true" ]]; then
        validate_and_setup "$PARSED_API_KEY"
        create_or_update_env_file "$PARSED_API_KEY" "$PARSED_GITHUB_TOKEN" "$PARSED_MAGIC_KEY" "$PARSED_TF_TOKEN" "$PARSED_GCP_CREDENTIALS"
    fi

    # Start container - for normal mode this will exec and not return
    start_container

    # Execute container session (only reached in debug mode)
    execute_container_session

    log_info "main" "Session complete. Use '$COMPOSE_CMD down' to cleanup."
}

# === EXECUTION ===
trap 'cleanup; exit 1' INT TERM
main "$@"
cleanup_logging "start-opencode.sh"

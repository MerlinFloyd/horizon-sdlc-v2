#!/bin/bash
# OpenCode Container Startup Script - Streamlined for Docker Compose management
# Usage: ./start-opencode.sh [--debug|bash] [--print-logs]

set -euo pipefail

# === CONFIGURATION ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="docker-compose.yml"
SERVICE_NAME="opencode"
DEBUG_MODE=false
PRINT_LOGS=false

# Load logging module
source "$SCRIPT_DIR/lib/logging.sh" && setup_logging "start-opencode.sh"

# === CORE FUNCTIONS ===

# Check prerequisites (Docker Compose, files, environment)
check_prerequisites() {
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
    [[ -f ".env" ]] || {
        log_error "prerequisites" ".env file required with OPENROUTER_API_KEY and optional GITHUB_TOKEN"
        exit 1
    }

    log_info "prerequisites" "Using $COMPOSE_CMD with $COMPOSE_FILE"
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

    # Start container with appropriate arguments
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
}

# Execute container session based on mode
execute_container_session() {
    local session_description=""

    # Determine session type based on flags
    if [[ "$DEBUG_MODE" == "true" && "$PRINT_LOGS" == "true" ]]; then
        session_description="debug mode with console logging"
    elif [[ "$DEBUG_MODE" == "true" ]]; then
        session_description="debug shell"
    elif [[ "$PRINT_LOGS" == "true" ]]; then
        session_description="console logging mode"
    else
        session_description="normal mode"
    fi

    log_info "session" "Starting $session_description session (Ctrl+C to exit)"

    # Handle different session types
    if [[ "$DEBUG_MODE" == "true" ]]; then
        # For debug mode, attach to the running container with bash
        log_info "session" "Container started in debug mode - you now have a bash shell"

        if docker exec -it "horizon-opencode" bash; then
            log_info "session" "Debug session ended successfully"
        else
            log_warn "session" "Debug session ended with error"
        fi
    else
        # For normal mode, follow the logs
        log_info "session" "Following OpenCode container logs (Ctrl+C to stop)"

        if docker logs -f "horizon-opencode"; then
            log_info "session" "Log following ended successfully"
        else
            log_warn "session" "Log following ended with error"
        fi
    fi
}

# Cleanup on exit - use comprehensive cleanup
cleanup() {
    cleanup_containers
    cleanup_logging "start-opencode.sh"
}

# === ARGUMENT PARSING ===
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --debug|bash)
                DEBUG_MODE=true
                shift
                ;;
            --print-logs)
                PRINT_LOGS=true
                shift
                ;;
            -h|--help)
                cat << EOF
Usage: $0 [--debug|bash] [--print-logs]

Options:
  --debug, bash    Start in debug mode with interactive bash shell
  --print-logs     Start OpenCode with console logging enabled
  -h, --help       Show this help message

Examples:
  $0                        Start OpenCode normally
  $0 --debug                Start in debug mode
  $0 --print-logs           Start with console logging
  $0 --debug --print-logs   Start in debug mode with console logging
EOF
                exit 0
                ;;
            *)
                log_error "args" "Unknown option: $1. Use --help for usage."
                exit 1
                ;;
        esac
    done
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
        mode_description="NORMAL"
    fi

    log_info "main" "Starting OpenCode Development Environment ($mode_description mode)"

    # Setup and checks
    trap cleanup SIGINT SIGTERM
    check_prerequisites
    start_container

    # Execute container session
    execute_container_session

    log_info "main" "Session complete. Use '$COMPOSE_CMD down' to cleanup."
}

# === EXECUTION ===
trap 'cleanup; exit 1' INT TERM
main "$@"
cleanup_logging "start-opencode.sh"

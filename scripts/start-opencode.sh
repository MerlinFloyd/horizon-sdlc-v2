#!/bin/bash

# start-opencode.sh
# Script to start OpenCode container services and attach to interactive terminal
# Usage: ./start-opencode.sh [--debug|bash]
#   --debug or bash: Start container in debug mode with interactive bash shell

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load centralized logging module
source "$SCRIPT_DIR/lib/logging.sh"

# Initialize logging
setup_logging "start-opencode.sh"

# Configuration
COMPOSE_FILE="docker-compose.yml"
SERVICE_NAME="opencode"
DEBUG_MODE=false

# Function to print colored output (backward compatibility)
print_status() {
    log_info "general" "$1"
}

print_success() {
    log_info "general" "$1"
}

print_warning() {
    log_warn "general" "$1"
}

print_error() {
    log_error "general" "$1"
}

# Function to check if docker-compose is available
check_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        print_error "Neither 'docker-compose' nor 'docker compose' is available"
        print_error "Please install Docker Compose to continue"
        exit 1
    fi
    print_status "Using: $COMPOSE_CMD"
}

# Function to check if compose file exists
check_compose_file() {
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        print_error "Docker Compose file not found: $COMPOSE_FILE"
        print_error "Please ensure you're running this script from the project root directory"
        exit 1
    fi
    print_status "Found Docker Compose file: $COMPOSE_FILE"
}

# Function to check for required .env file
check_environment() {
    local env_file=".env"

    if [[ ! -f "$env_file" ]]; then
        print_error ".env file not found in current directory"
        print_error "The .env file is required for the OpenCode container to function properly"
        print_error "Please create a .env file with the necessary environment variables:"
        print_error "  OPENROUTER_API_KEY=your_api_key_here"
        print_error "  GITHUB_TOKEN=your_github_token_here (optional)"
        print_error ""
        print_error "Example .env file content:"
        print_error "  OPENROUTER_API_KEY=sk-or-v1-..."
        print_error "  GITHUB_TOKEN=ghp_..."
        exit 1
    else
        print_success "Found .env file: $env_file"
        print_status "Environment variables will be loaded by Docker Compose"
    fi
}

# Function to cleanup on exit
cleanup() {
    local exit_code=$?
    echo
    print_status "Received interrupt signal, cleaning up..."
    
    # Stop the containers gracefully
    print_status "Stopping OpenCode containers..."
    cd "$(dirname "$COMPOSE_FILE")"
    $COMPOSE_CMD -f "$(basename "$COMPOSE_FILE")" down --timeout 10
    
    print_success "Cleanup completed"
    exit $exit_code
}

# Function to wait for container to be ready
wait_for_container() {
    local max_attempts=15
    local attempt=1

    print_status "Waiting for container to be ready..."

    while [[ $attempt -le $max_attempts ]]; do
        # Check if service is running using Docker Compose
        if $COMPOSE_CMD ps --services --filter "status=running" | grep -q "$SERVICE_NAME"; then
            # Check if OpenCode has started by looking for its process
            if $COMPOSE_CMD exec -T "$SERVICE_NAME" pgrep -f "opencode" >/dev/null 2>&1; then
                print_success "Container is ready!"
                return 0
            fi
        fi

        printf "\r${BLUE}[INFO]${NC} Waiting for container... (%d/%d)" $attempt $max_attempts
        sleep 3
        ((attempt++))
    done

    echo
    print_error "Container failed to become ready within expected time"
    return 1
}

# Function to start services
start_services() {
    print_status "Starting OpenCode services..."

    # Check if service is already running
    if $COMPOSE_CMD ps --services --filter "status=running" | grep -q "$SERVICE_NAME"; then
        print_warning "Service is already running"
        return 0
    fi

    # Start services in detached mode
    if $COMPOSE_CMD up -d "$SERVICE_NAME"; then
        print_success "Services started successfully"
        return 0
    else
        print_error "Failed to start services"
        return 1
    fi
}

# Function to run container interactively
run_container_interactive() {
    if [[ "$DEBUG_MODE" == "true" ]]; then
        print_status "Starting OpenCode container in DEBUG mode..."
        print_status "This will give you direct access to a bash shell inside the container"
        print_status "Environment variables and workspace are configured and ready"
        print_status "Use 'opencode' command to start OpenCode manually"
        print_status "Use 'exit' to leave the container"
        echo

        # Use Docker Compose exec for debug session with bash
        if $COMPOSE_CMD exec "$SERVICE_NAME" --debug; then
            print_success "Debug session ended"
        else
            print_warning "Debug session exited with error"
            print_status "Check the output above for error details"
        fi
    else
        print_status "Starting OpenCode container interactively..."
        print_status "This will give you direct access to the OpenCode terminal"
        print_status "Use Ctrl+C to stop OpenCode and exit"
        echo

        # Use Docker Compose exec for interactive session
        # This leverages the proper volume mounts and environment from docker-compose.yml
        if $COMPOSE_CMD exec "$SERVICE_NAME" opencode; then
            print_success "OpenCode session ended"
        else
            print_warning "OpenCode container exited with error"
            print_status "Check the output above for error details"
            print_status "You can check logs with: $COMPOSE_CMD logs $SERVICE_NAME"
        fi
    fi
}

# Function to parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --debug|bash)
                DEBUG_MODE=true
                print_status "Debug mode enabled"
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [--debug|bash]"
                echo ""
                echo "Options:"
                echo "  --debug, bash    Start container in debug mode with interactive bash shell"
                echo "  -h, --help       Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0               Start OpenCode normally"
                echo "  $0 --debug       Start in debug mode"
                echo "  $0 bash          Start in debug mode (alternative syntax)"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                print_error "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Main execution
main() {
    # Parse command line arguments
    parse_arguments "$@"

    if [[ "$DEBUG_MODE" == "true" ]]; then
        print_status "Starting OpenCode Development Environment (DEBUG MODE)"
    else
        print_status "Starting OpenCode Development Environment"
    fi
    echo

    # Set up signal handlers for graceful shutdown
    trap cleanup SIGINT SIGTERM

    # Perform checks
    check_docker_compose
    check_compose_file
    check_environment

    echo
    
    # Start services using Docker Compose
    if ! start_services; then
        print_error "Failed to start services. Check the logs above."
        print_status "You can check logs with: $COMPOSE_CMD logs $SERVICE_NAME"
        exit 1
    fi

    # Wait for container to be ready
    if ! wait_for_container; then
        print_error "Container failed to become ready"
        print_status "You can check logs with: $COMPOSE_CMD logs $SERVICE_NAME"
        exit 1
    fi

    echo
    print_success "OpenCode container is ready!"
    if [[ "$DEBUG_MODE" == "true" ]]; then
        print_status "Starting debug session..."
    else
        print_status "Starting interactive OpenCode session..."
    fi
    echo

    # Run container interactively
    run_container_interactive

    echo
    if [[ "$DEBUG_MODE" == "true" ]]; then
        print_status "Debug session ended."
    else
        print_status "OpenCode session ended."
    fi
    print_status "To clean up, run: $COMPOSE_CMD down"
}

# Set up signal handlers for cleanup
trap 'cleanup_logging "start-opencode.sh"; exit 1' INT TERM

# Run main function
main "$@"

# Cleanup logging
cleanup_logging "start-opencode.sh"

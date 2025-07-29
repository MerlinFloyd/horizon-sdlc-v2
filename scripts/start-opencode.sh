#!/bin/bash

# start-opencode.sh
# Script to start OpenCode container services and attach to interactive terminal
# Usage: ./start-opencode.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.yml"
CONTAINER_NAME="horizon-opencode"
SERVICE_NAME="opencode"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
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
        print_error "Please ensure you're running this script from the docker/opencode directory"
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
        if docker ps --filter "name=$CONTAINER_NAME" --filter "status=running" --format "{{.Names}}" | grep -q "$CONTAINER_NAME"; then
            # For OpenCode, we just need the container to be running
            # Check if OpenCode has started by looking for its process
            if docker exec "$CONTAINER_NAME" pgrep -f "opencode" >/dev/null 2>&1; then
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

    # Change to the directory containing docker-compose.yml
    cd "$(dirname "$COMPOSE_FILE")"

    # Check if container is already running
    if docker ps --filter "name=$CONTAINER_NAME" --filter "status=running" --format "{{.Names}}" | grep -q "$CONTAINER_NAME"; then
        print_warning "Container is already running"
        return 0
    fi

    # Start services in detached mode first to set up networking
    if $COMPOSE_CMD -f "$(basename "$COMPOSE_FILE")" up --no-start "$SERVICE_NAME"; then
        print_success "Services prepared successfully"
        return 0
    else
        print_error "Failed to prepare services"
        return 1
    fi
}

# Function to run container interactively
run_container_interactive() {
    print_status "Starting OpenCode container interactively..."
    print_status "This will give you direct access to the OpenCode terminal"
    print_status "Use Ctrl+C to stop OpenCode and exit"
    echo

    # Use docker run directly for better TTY support
    local image_name="horizon-sdlc/opencode:latest"
    local workspace_mount="-v $(pwd):/workspace"
    local env_file="--env-file .env"

    # Run the container interactively with docker run
    if docker run --rm -it $workspace_mount $env_file $image_name; then
        print_success "OpenCode session ended"
    else
        print_warning "OpenCode container exited with error"
        print_status "Check the output above for error details"
    fi
}

# Main execution
main() {
    print_status "Starting OpenCode Development Environment"
    echo
    
    # Set up signal handlers for graceful shutdown
    trap cleanup SIGINT SIGTERM
    
    # Perform checks
    check_docker_compose
    check_compose_file
    check_environment
    
    echo
    
    # Prepare services (create containers but don't start them)
    if ! start_services; then
        print_error "Failed to prepare services. Check the logs above."
        exit 1
    fi

    echo
    print_success "OpenCode container is ready!"
    print_status "Starting interactive OpenCode session..."
    echo

    # Run container interactively
    run_container_interactive

    echo
    print_status "OpenCode session ended."
    print_status "To clean up, run: $COMPOSE_CMD -f $COMPOSE_FILE down"
}

# Run main function
main "$@"

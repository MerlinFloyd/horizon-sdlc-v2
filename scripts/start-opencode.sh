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

# Function to wait for container to be healthy
wait_for_container() {
    local max_attempts=30
    local attempt=1
    
    print_status "Waiting for container to be ready..."
    
    while [[ $attempt -le $max_attempts ]]; do
        if docker ps --filter "name=$CONTAINER_NAME" --filter "status=running" --format "{{.Names}}" | grep -q "$CONTAINER_NAME"; then
            # Check if container is healthy (if health check is defined)
            local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "none")
            
            if [[ "$health_status" == "healthy" ]] || [[ "$health_status" == "none" ]]; then
                print_success "Container is ready!"
                return 0
            fi
        fi
        
        printf "\r${BLUE}[INFO]${NC} Waiting for container... (%d/%d)" $attempt $max_attempts
        sleep 2
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
    
    # Start services in detached mode
    if $COMPOSE_CMD -f "$(basename "$COMPOSE_FILE")" up -d "$SERVICE_NAME"; then
        print_success "Services started successfully"
        return 0
    else
        print_error "Failed to start services"
        return 1
    fi
}

# Function to attach to container
attach_to_container() {
    print_status "Attaching to container terminal..."
    print_status "Use 'exit' or Ctrl+D to detach from container (containers will keep running)"
    print_status "Use Ctrl+C to stop containers and exit"
    echo
    
    # Attach to the running container with an interactive shell
    if docker exec -it "$CONTAINER_NAME" opencode; then
        print_success "Detached from container"
    else
        print_warning "Failed to attach to container or container exited"
        print_status "Container logs:"
        docker logs --tail 20 "$CONTAINER_NAME"
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
    
    # Start services
    if ! start_services; then
        print_error "Failed to start services. Check the logs above."
        exit 1
    fi
    
    # Wait for container to be ready
    if ! wait_for_container; then
        print_error "Container is not ready. Showing recent logs:"
        docker logs --tail 20 "$CONTAINER_NAME"
        exit 1
    fi
    
    echo
    print_success "OpenCode is ready!"
    print_status "Container: $CONTAINER_NAME"
    print_status "Web interface (if available): http://localhost:3000"
    echo
    
    # Attach to container
    attach_to_container
    
    echo
    print_status "Session ended. Containers are still running."
    print_status "To stop containers, run: $COMPOSE_CMD -f $COMPOSE_FILE down"
    print_status "To view logs, run: docker logs $CONTAINER_NAME"
}

# Run main function
main "$@"

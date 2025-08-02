#!/bin/bash

# Horizon SDLC OpenCode Container Build Script
# Builds and deploys the OpenCode container with MCP servers

set -e

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOCKER_CONTEXT="$PROJECT_ROOT/docker/opencode"

# Load centralized logging module
source "$SCRIPT_DIR/lib/logging.sh"

# Initialize logging
setup_logging "build.sh"

# Set GitHub Container Registry as default
DOCKER_REGISTRY="${DOCKER_REGISTRY:-ghcr.io/$(echo $GITHUB_REPOSITORY | tr '[:upper:]' '[:lower:]')}"

# Function to display usage information
usage() {
    log_info "help_display" "Displaying usage information"
    cat << EOF
Usage: $0 [OPTIONS]

Build and prepare the OpenCode container with MCP servers for interactive use.

OPTIONS:
    -o, --openrouter-api-key KEY Set OPENROUTER_API_KEY (required)
    -g, --github-token TOKEN Set GITHUB_TOKEN (optional)
    -m, --magic-key KEY     Set TWENTY_FIRST_API_KEY (optional)
    -t, --tag TAG           Docker image tag (default: latest)
    -n, --no-cache          Build without Docker cache
    -p, --push              Push image to registry after build
    -r, --registry URL      Docker registry URL for push
    -h, --help              Show this help message

EXAMPLES:
    # Basic build with OpenRouter API key
    $0 --openrouter-api-key "your-openrouter-api-key"

    # Build with GitHub integration
    $0 --openrouter-api-key "your-openrouter-api-key" --github-token "your-github-token"

    # Build and push to registry
    $0 --openrouter-api-key "your-openrouter-api-key" --push --registry "your-registry.com"

    # After building, start OpenCode interactively:
    ./scripts/start-opencode.sh

ENVIRONMENT VARIABLES:
    OPENROUTER_API_KEY      AI provider API key (can be set instead of --openrouter-api-key)
    GITHUB_TOKEN           GitHub token for MCP integration (can be set instead of --github-token)
    TWENTY_FIRST_API_KEY   Magic MCP server API key (can be set instead of --magic-key)
    DOCKER_REGISTRY        Default registry for push operations

EOF
}

# Function to validate prerequisites
validate_prerequisites() {
    log_info "prerequisite_check" "Validating prerequisites..."

    # Check Docker
    if ! command -v docker >/dev/null 2>&1; then
        log_error "prerequisite_check" "Docker is not installed or not in PATH"
        return 1
    fi
    log_debug "prerequisite_check" "Docker command found"

    # Check Docker Compose
    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        log_error "prerequisite_check" "Docker Compose is not installed or not in PATH"
        return 1
    fi
    log_debug "prerequisite_check" "Docker Compose found"

    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        log_error "prerequisite_check" "Docker daemon is not running"
        return 1
    fi
    log_debug "prerequisite_check" "Docker daemon is running"

    # Check if we're in the correct directory
    if [[ ! -f "$PROJECT_ROOT/docker-compose.yml" ]]; then
        log_error "prerequisite_check" "docker-compose.yml not found. Please run this script from the project root."
        return 1
    fi
    log_debug "prerequisite_check" "docker-compose.yml found"

    log_info "prerequisite_check" "Prerequisites validation passed"
    return 0
}

# Function to validate API key
validate_api_key() {
    local api_key="$1"

    log_info "api_validation" "Validating OpenRouter API key..."

    if [[ -z "$api_key" ]]; then
        log_error "api_validation" "OpenRouter API key is required. Use --openrouter-api-key or set OPENROUTER_API_KEY environment variable."
        return 1
    fi

    # Basic validation - check if it looks like an API key
    if [[ ${#api_key} -lt 20 ]]; then
        log_warn "api_validation" "API key seems too short. Please verify it's correct."
    fi

    log_info "api_validation" "API key validation passed"
    return 0
}

# Function to create necessary directories
setup_directories() {
    log_info "directory_setup" "Setting up directories..."

    # Create .opencode directory if it doesn't exist
    if mkdir -p "$PROJECT_ROOT/.opencode/agent"; then
        log_debug "directory_setup" "Created .opencode/agent directory"
    else
        log_error "directory_setup" "Failed to create .opencode/agent directory"
        return 1
    fi

    # Create .ai directory structure if it doesn't exist
    if mkdir -p "$PROJECT_ROOT/.ai/templates" && mkdir -p "$PROJECT_ROOT/.ai/standards"; then
        log_debug "directory_setup" "Created .ai directory structure"
    else
        log_error "directory_setup" "Failed to create .ai directory structure"
        return 1
    fi

    log_info "directory_setup" "Directory setup completed"
}

# Function to build Docker image
build_image() {
    local tag="$1"
    local no_cache="$2"

    log_info "docker_build" "Building OpenCode Docker image with tag: $tag"

    local build_args=""
    if [[ "$no_cache" == "true" ]]; then
        build_args="--no-cache"
        log_debug "docker_build" "Using --no-cache flag"
    fi

    # Build the image
    log_debug "docker_build" "Running docker build command in context: $DOCKER_CONTEXT"
    if docker build $build_args -t "horizon-sdlc/opencode:$tag" "$DOCKER_CONTEXT"; then
        log_info "docker_build" "Docker image built successfully: horizon-sdlc/opencode:$tag"
        return 0
    else
        log_error "docker_build" "Docker image build failed"
        return 1
    fi
}

# Function to push image to registry
push_image() {
    local tag="$1"
    local registry="$2"

    if [[ -n "$registry" ]]; then
        local full_tag="$registry/horizon-sdlc/opencode:$tag"

        log_info "docker_push" "Tagging image for registry: $full_tag"
        if docker tag "horizon-sdlc/opencode:$tag" "$full_tag"; then
            log_debug "docker_push" "Image tagged successfully"
        else
            log_error "docker_push" "Failed to tag image"
            return 1
        fi

        log_info "docker_push" "Pushing image to registry..."
        if docker push "$full_tag"; then
            log_info "docker_push" "Image pushed successfully: $full_tag"
            return 0
        else
            log_error "docker_push" "Failed to push image to registry"
            return 1
        fi
    else
        log_warn "docker_push" "No registry specified, skipping push"
        return 0
    fi
}

# Function to create environment file
create_env_file() {
    local api_key="$1"
    local github_token="$2"
    local magic_key="$3"

    log_info "env_setup" "Creating environment configuration..."

    local env_file="$PROJECT_ROOT/.env"

    if cat > "$env_file" << EOF
# OpenCode Container Environment Configuration
# Generated by build.sh on $(date)

# Required: AI Provider API Key
OPENROUTER_API_KEY=$api_key

# Optional: GitHub Integration
GITHUB_TOKEN=${github_token:-}

# Optional: Magic MCP Server (21st.dev)
TWENTY_FIRST_API_KEY=${magic_key:-}

# Container Configuration
NODE_ENV=production
LOG_LEVEL=info
SECURE_MODE=true

# MCP Server Configuration
MCP_SERVER_TIMEOUT=30000
MCP_SERVER_RETRIES=3
EOF
    then
        log_debug "env_setup" "Environment file content written successfully"
    else
        log_error "env_setup" "Failed to write environment file"
        return 1
    fi

    # Secure the environment file
    if chmod 600 "$env_file"; then
        log_debug "env_setup" "Environment file permissions set to 600"
    else
        log_warn "env_setup" "Failed to set secure permissions on environment file"
    fi

    log_info "env_setup" "Environment file created: $env_file"
}

# Function to prepare container (build-only mode)
prepare_container() {
    local api_key="$1"
    local github_token="$2"
    local magic_key="$3"

    log "Preparing OpenCode container environment..."

    # Export environment variables for docker-compose
    export OPENROUTER_API_KEY="$api_key"
    export GITHUB_TOKEN="$github_token"
    export TWENTY_FIRST_API_KEY="$magic_key"

    # Stop existing container if running
    if docker-compose ps | grep -q "horizon-opencode"; then
        log "Stopping existing container..."
        docker-compose down
    fi

    # Create the container without starting it (for networking setup)
    if docker-compose up --no-start; then
        success "OpenCode container prepared successfully"
        log "Container is ready for interactive startup"
        return 0
    else
        error "Failed to prepare OpenCode container"
        return 1
    fi
}

# Function to test container functionality
test_container() {
    log "Testing OpenCode container functionality..."

    # Start the service temporarily for testing
    local compose_cmd="docker-compose"
    if command -v docker &> /dev/null && docker compose version &> /dev/null; then
        compose_cmd="docker compose"
    fi

    # Test the container using Docker Compose
    local test_output
    if $compose_cmd up -d opencode >/dev/null 2>&1; then
        # Wait a moment for container to start
        sleep 3
        if test_output=$($compose_cmd exec -T opencode opencode --version 2>&1); then
            success "Container test passed"
            log "OpenCode version: $test_output"
            # Clean up test container
            $compose_cmd down >/dev/null 2>&1
            return 0
        else
            error "Container test failed"
            error "Test output: $test_output"
            # Clean up test container
            $compose_cmd down >/dev/null 2>&1
            return 1
        fi
    else
        error "Failed to start container for testing"
        return 1
    fi
}

# Main function
main() {
    local api_key=""
    local github_token=""
    local magic_key=""
    local tag="latest"
    local no_cache="false"
    local push="false"
    local registry="${DOCKER_REGISTRY:-}"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -o|--openrouter-api-key)
                api_key="$2"
                shift 2
                ;;
            -g|--github-token)
                github_token="$2"
                shift 2
                ;;
            -m|--magic-key)
                magic_key="$2"
                shift 2
                ;;
            -t|--tag)
                tag="$2"
                shift 2
                ;;
            -n|--no-cache)
                no_cache="true"
                shift
                ;;
            -p|--push)
                push="true"
                shift
                ;;
            -r|--registry)
                registry="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Use environment variables if not provided via command line
    api_key="${api_key:-$OPENROUTER_API_KEY}"
    github_token="${github_token:-$GITHUB_TOKEN}"
    magic_key="${magic_key:-$TWENTY_FIRST_API_KEY}"
    
    log "Starting OpenCode container build and deployment..."
    
    # Validate prerequisites
    if ! validate_prerequisites; then
        exit 1
    fi
    
    # Validate API key
    if ! validate_api_key "$api_key"; then
        exit 1
    fi
    
    # Setup directories
    setup_directories
    
    # Build Docker image
    if ! build_image "$tag" "$no_cache"; then
        exit 1
    fi
    
    # Push image if requested
    if [[ "$push" == "true" ]]; then
        if ! push_image "$tag" "$registry"; then
            exit 1
        fi
    fi
    
    # Create environment file
    create_env_file "$api_key" "$github_token" "$magic_key"

    # Test container functionality
    if ! test_container; then
        exit 1
    fi

    # Prepare container environment
    if ! prepare_container "$api_key" "$github_token" "$magic_key"; then
        exit 1
    fi

    log_info "build_complete" "OpenCode container build and preparation completed successfully!"

    # Display next steps
    log_info "next_steps" "Next steps:"
    log_info "next_steps" "  1. Start OpenCode interactively: ./scripts/start-opencode.sh"
    log_info "next_steps" "  2. Or start services manually: docker-compose up -d"
    log_info "next_steps" "  3. Check container status: docker-compose ps"
    log_info "next_steps" "  4. View logs: docker-compose logs opencode"
    log_info "next_steps" "  5. Access OpenCode directly: docker-compose exec opencode opencode"

    # Cleanup logging
    cleanup_logging "build.sh"
}

# Set up signal handlers for cleanup
trap 'cleanup_logging "build.sh"; exit 1' INT TERM

# Run main function with all arguments
main "$@"


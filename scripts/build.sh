#!/bin/bash

# Horizon SDLC OpenCode Container Build Script
# Builds and deploys the OpenCode container with MCP servers

set -e

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOCKER_CONTEXT="$PROJECT_ROOT/docker/opencode"

# Set GitHub Container Registry as default
DOCKER_REGISTRY="${DOCKER_REGISTRY:-ghcr.io/$(echo $GITHUB_REPOSITORY | tr '[:upper:]' '[:lower:]')}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to display usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Build and prepare the OpenCode container with MCP servers for interactive use.

OPTIONS:
    -k, --api-key KEY       Set OPENROUTER_API_KEY (required)
    -g, --github-token TOKEN Set GITHUB_TOKEN (optional)
    -t, --tag TAG           Docker image tag (default: latest)
    -n, --no-cache          Build without Docker cache
    -p, --push              Push image to registry after build
    -r, --registry URL      Docker registry URL for push
    -h, --help              Show this help message

EXAMPLES:
    # Basic build with API key
    $0 --api-key "your-openrouter-api-key"

    # Build with GitHub integration
    $0 --api-key "your-api-key" --github-token "your-github-token"

    # Build and push to registry
    $0 --api-key "your-api-key" --push --registry "your-registry.com"

    # After building, start OpenCode interactively:
    ./scripts/start-opencode.sh

ENVIRONMENT VARIABLES:
    OPENROUTER_API_KEY      AI provider API key (can be set instead of --api-key)
    GITHUB_TOKEN           GitHub token for MCP integration (can be set instead of --github-token)
    DOCKER_REGISTRY        Default registry for push operations

EOF
}

# Function to validate prerequisites
validate_prerequisites() {
    log "Validating prerequisites..."
    
    # Check Docker
    if ! command -v docker >/dev/null 2>&1; then
        error "Docker is not installed or not in PATH"
        return 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        error "Docker Compose is not installed or not in PATH"
        return 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        error "Docker daemon is not running"
        return 1
    fi
    
    # Check if we're in the correct directory
    if [[ ! -f "$PROJECT_ROOT/docker-compose.yml" ]]; then
        error "docker-compose.yml not found. Please run this script from the project root."
        return 1
    fi
    
    success "Prerequisites validation passed"
    return 0
}

# Function to validate API key
validate_api_key() {
    local api_key="$1"
    
    if [[ -z "$api_key" ]]; then
        error "API key is required. Use --api-key or set OPENROUTER_API_KEY environment variable."
        return 1
    fi
    
    # Basic validation - check if it looks like an API key
    if [[ ${#api_key} -lt 20 ]]; then
        warning "API key seems too short. Please verify it's correct."
    fi
    
    success "API key validation passed"
    return 0
}

# Function to create necessary directories
setup_directories() {
    log "Setting up directories..."
    
    # Create .opencode directory if it doesn't exist
    mkdir -p "$PROJECT_ROOT/.opencode/agent"
    
    # Create .ai directory structure if it doesn't exist
    mkdir -p "$PROJECT_ROOT/.ai/templates"
    mkdir -p "$PROJECT_ROOT/.ai/standards"
    
    success "Directory setup completed"
}

# Function to build Docker image
build_image() {
    local tag="$1"
    local no_cache="$2"
    
    log "Building OpenCode Docker image..."
    
    local build_args=""
    if [[ "$no_cache" == "true" ]]; then
        build_args="--no-cache"
    fi
    
    # Build the image
    if docker build $build_args -t "horizon-sdlc/opencode:$tag" "$DOCKER_CONTEXT"; then
        success "Docker image built successfully: horizon-sdlc/opencode:$tag"
        return 0
    else
        error "Docker image build failed"
        return 1
    fi
}

# Function to push image to registry
push_image() {
    local tag="$1"
    local registry="$2"
    
    if [[ -n "$registry" ]]; then
        local full_tag="$registry/horizon-sdlc/opencode:$tag"
        
        log "Tagging image for registry: $full_tag"
        docker tag "horizon-sdlc/opencode:$tag" "$full_tag"
        
        log "Pushing image to registry..."
        if docker push "$full_tag"; then
            success "Image pushed successfully: $full_tag"
            return 0
        else
            error "Failed to push image to registry"
            return 1
        fi
    else
        warning "No registry specified, skipping push"
        return 0
    fi
}

# Function to create environment file
create_env_file() {
    local api_key="$1"
    local github_token="$2"
    
    log "Creating environment configuration..."
    
    local env_file="$PROJECT_ROOT/.env"
    
    cat > "$env_file" << EOF
# OpenCode Container Environment Configuration
# Generated by build.sh on $(date)

# Required: AI Provider API Key
OPENROUTER_API_KEY=$api_key

# Optional: GitHub Integration
GITHUB_TOKEN=${github_token:-}

# Container Configuration
NODE_ENV=production
LOG_LEVEL=info
SECURE_MODE=true

# MCP Server Configuration
MCP_SERVER_TIMEOUT=30000
MCP_SERVER_RETRIES=3
EOF
    
    # Secure the environment file
    chmod 600 "$env_file"
    
    success "Environment file created: $env_file"
}

# Function to prepare container (build-only mode)
prepare_container() {
    local api_key="$1"
    local github_token="$2"

    log "Preparing OpenCode container environment..."

    # Export environment variables for docker-compose
    export OPENROUTER_API_KEY="$api_key"
    export GITHUB_TOKEN="$github_token"

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
    local tag="latest"
    local no_cache="false"
    local push="false"
    local registry="${DOCKER_REGISTRY:-}"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -k|--api-key)
                api_key="$2"
                shift 2
                ;;
            -g|--github-token)
                github_token="$2"
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
    create_env_file "$api_key" "$github_token"

    # Test container functionality
    if ! test_container; then
        exit 1
    fi

    # Prepare container environment
    if ! prepare_container "$api_key" "$github_token"; then
        exit 1
    fi

    success "OpenCode container build and preparation completed successfully!"

    # Display next steps
    log "Next steps:"
    log "  1. Start OpenCode interactively: ./scripts/start-opencode.sh"
    log "  2. Or start services manually: docker-compose up -d"
    log "  3. Check container status: docker-compose ps"
    log "  4. View logs: docker-compose logs opencode"
    log "  5. Access OpenCode directly: docker-compose exec opencode opencode"
}

# Run main function with all arguments
main "$@"


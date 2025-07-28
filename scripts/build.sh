#!/bin/bash

# Horizon SDLC OpenCode Container Build Script
# Builds and deploys the OpenCode container with MCP servers

set -e

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOCKER_CONTEXT="$PROJECT_ROOT/docker/opencode"

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

Build and deploy the OpenCode container with MCP servers.

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
    mkdir -p "$PROJECT_ROOT/.opencode"
    
    # Create .ai directory structure if it doesn't exist
    mkdir -p "$PROJECT_ROOT/.ai/config"
    mkdir -p "$PROJECT_ROOT/.ai/templates"
    mkdir -p "$PROJECT_ROOT/.ai/prompts"
    mkdir -p "$PROJECT_ROOT/.ai/standards"
    
    # Create .gitignore for sensitive files if it doesn't exist
    if [[ ! -f "$PROJECT_ROOT/.ai/config/.gitignore" ]]; then
        cat > "$PROJECT_ROOT/.ai/config/.gitignore" << EOF
# Ignore sensitive authentication files
auth.json
*.secret
*.key
*.env
EOF
    fi
    
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

# Function to deploy container
deploy_container() {
    local api_key="$1"
    local github_token="$2"
    
    log "Deploying OpenCode container..."
    
    # Export environment variables for docker-compose
    export OPENROUTER_API_KEY="$api_key"
    export GITHUB_TOKEN="$github_token"
    
    # Stop existing container if running
    if docker-compose ps | grep -q "horizon-opencode"; then
        log "Stopping existing container..."
        docker-compose down
    fi
    
    # Start the container
    if docker-compose up -d; then
        success "OpenCode container deployed successfully"
        
        # Wait for container to be healthy
        log "Waiting for container to be healthy..."
        local max_attempts=30
        local attempt=1
        
        while [[ $attempt -le $max_attempts ]]; do
            if docker-compose ps | grep -q "healthy"; then
                success "Container is healthy and ready"
                return 0
            fi
            
            log "Health check attempt $attempt/$max_attempts..."
            sleep 2
            ((attempt++))
        done
        
        warning "Container started but health check timed out"
        return 0
    else
        error "Failed to deploy OpenCode container"
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
    
    # Deploy container
    if ! deploy_container "$api_key" "$github_token"; then
        exit 1
    fi
    
    success "OpenCode container build and deployment completed successfully!"
    
    # Display next steps
    log "Next steps:"
    log "  1. Verify container status: docker-compose ps"
    log "  2. View container logs: docker-compose logs -f opencode"
    log "  3. Access OpenCode: docker-compose exec opencode opencode"
    log "  4. Run health check: docker-compose exec opencode /usr/local/bin/healthcheck.sh"
}

# Run main function with all arguments
main "$@"

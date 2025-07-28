#!/bin/bash

# OpenCode Container Entrypoint Script
# Handles container initialization, environment setup, and OpenCode startup

set -e

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

# Function to validate workspace mounting
validate_workspace() {
    log "Validating workspace configuration..."
    
    # Check if workspace directory exists and is writable
    if [[ ! -d "/workspace" ]]; then
        error "Workspace directory /workspace not found"
        return 1
    fi
    
    if [[ ! -w "/workspace" ]]; then
        error "Workspace directory /workspace is not writable"
        return 1
    fi
    
    # Check if .opencode directory exists
    if [[ ! -d "/.opencode" ]]; then
        warning ".opencode directory not found, creating..."
        mkdir -p /.opencode
    fi
    
    # Check if .ai directory exists
    if [[ ! -d "/.ai" ]]; then
        warning ".ai directory not found, creating..."
        mkdir -p /.ai
    fi
    
    success "Workspace validation completed"
    return 0
}

# Function to perform health checks
health_check() {
    log "Performing initial health check..."
    
    # Check OpenCode installation
    if ! command -v opencode >/dev/null 2>&1; then
        error "OpenCode is not installed or not in PATH"
        return 1
    fi
    
    # Check OpenCode configuration
    local config_file="$HOME/.config/opencode/opencode.json"
    if [[ ! -f "$config_file" ]]; then
        error "OpenCode configuration file not found at $config_file"
        return 1
    fi

    # Validate JSON configuration
    if ! python3 -m json.tool "$config_file" >/dev/null 2>&1; then
        error "OpenCode configuration file is not valid JSON"
        return 1
    fi
    
    # Check Node.js and npm
    if ! command -v node >/dev/null 2>&1; then
        error "Node.js is not installed"
        return 1
    fi
    
    if ! command -v npm >/dev/null 2>&1; then
        error "npm is not installed"
        return 1
    fi
    
    success "Health check passed"
    return 0
}

# Function to display startup information
display_startup_info() {
    log "OpenCode Container Startup Information:"
    log "  - OpenCode Version: $(opencode --version 2>/dev/null || echo 'Unknown')"
    log "  - Node.js Version: $(node --version)"
    log "  - Workspace: /workspace"
    log "  - OpenCode Config: ~/.config/opencode/"
    log "  - AI Assets: /.ai/"
    log "  - GitHub Token: $([ -n "${GITHUB_TOKEN:-}" ] && echo "Configured" || echo "Not configured")"
    
}

# Function to handle graceful shutdown
cleanup() {
    log "Received shutdown signal, cleaning up..."

    # Additional cleanup if needed

    log "Cleanup completed"
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Main execution
main() {
    log "Starting OpenCode container initialization..."
        
    # Validate workspace
    if ! validate_workspace; then
        error "Workspace validation failed"
        exit 1
    fi
    
    # Perform health check
    if ! health_check; then
        error "Health check failed"
        exit 1
    fi
    
    # Display startup information
    display_startup_info
    
    success "OpenCode container initialization completed!"
    
    # Change to workspace directory
    cd /workspace
    
    # Execute the provided command or start OpenCode
    if [[ $# -eq 0 ]]; then
        log "Starting OpenCode..."
        exec opencode
    else
        log "Executing command: $*"
        exec "$@"
    fi
}

# Run main function with all arguments
main "$@"

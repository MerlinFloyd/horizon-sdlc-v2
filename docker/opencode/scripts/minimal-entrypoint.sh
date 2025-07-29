#!/bin/bash

# Minimal OpenCode Container Entrypoint Script
# Focuses on essential setup only to avoid interfering with OpenCode

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Simple logging
log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Essential workspace validation
validate_workspace() {
    if [[ ! -d "/workspace" ]]; then
        error "Workspace directory /workspace not found"
        return 1
    fi
    
    if [[ ! -w "/workspace" ]]; then
        error "Workspace directory /workspace is not writable"
        return 1
    fi
    
    # Create .opencode directory if it doesn't exist
    if [[ ! -d "/workspace/.opencode" ]]; then
        mkdir -p /workspace/.opencode/agent 2>/dev/null || true
    fi
    
    return 0
}

# Set up environment for MCP servers
setup_environment() {
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        export GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_TOKEN"
    fi
}

# Main execution
main() {
    log "OpenCode container starting..."
    
    # Essential validation only
    if ! validate_workspace; then
        error "Workspace validation failed"
        exit 1
    fi
    
    # Set up environment
    setup_environment
    
    # Change to workspace directory
    cd /workspace
    
    # Show minimal startup info
    log "OpenCode v$(opencode --version 2>/dev/null || echo 'Unknown')"
    log "Workspace: $(pwd)"
    log "API Key: $([ -n "${OPENROUTER_API_KEY:-}" ] && echo "configured" || echo "not configured")"
    
    success "Starting OpenCode..."
    
    # Execute the provided command or start OpenCode
    if [[ $# -eq 0 ]]; then
        exec opencode
    else
        exec "$@"
    fi
}

# Run main function with all arguments
main "$@"

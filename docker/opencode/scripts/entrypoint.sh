#!/bin/bash

# OpenCode Container Entrypoint Script
# Handles container initialization, environment setup, and OpenCode startup

set -e

# Load container-local logging module
if [[ -f "/usr/local/lib/logging.sh" ]]; then
    # Use container-local logging module (primary)
    source "/usr/local/lib/logging.sh"
    setup_logging "entrypoint.sh"
elif [[ -f "/workspace/scripts/lib/logging.sh" ]]; then
    # Fallback to workspace logging module if available
    source "/workspace/scripts/lib/logging.sh"
    setup_logging "entrypoint.sh"
else
    # Basic fallback logging (should rarely be needed)
    log_info() {
        local operation="$1"
        local message="$2"
        echo "[$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")] [INFO] [entrypoint.sh] [$operation] $message"
    }

    log_error() {
        local operation="$1"
        local message="$2"
        echo "[$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")] [ERROR] [entrypoint.sh] [$operation] $message" >&2
    }

    log_warn() {
        local operation="$1"
        local message="$2"
        echo "[$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")] [WARN] [entrypoint.sh] [$operation] $message"
    }

    log_debug() {
        local operation="$1"
        local message="$2"
        echo "[$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")] [DEBUG] [entrypoint.sh] [$operation] $message"
    }

    cleanup_logging() {
        true
    }
fi

# Backward compatibility functions
log() {
    log_info "general" "$1"
}

error() {
    log_error "general" "$1"
}

warning() {
    log_warn "general" "$1"
}

success() {
    log_info "general" "$1"
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
    if [[ ! -d "/workspace/.opencode" ]]; then
        warning ".opencode/agent directory not found, creating..."
        mkdir -p /workspace/.opencode/agent
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
    
    # Set environment variables for MCP servers
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        export GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_TOKEN"
        log "GitHub Personal Access Token configured for MCP server"
    fi

    # Change to workspace directory
    cd /workspace

    # Execute the provided command or start OpenCode
    if [[ $# -eq 0 ]]; then
        log "Starting OpenCode..."

        # Check if we have a proper TTY for interactive mode
        if [[ -t 0 && -t 1 ]]; then
            log "Interactive terminal detected - starting OpenCode directly"
            exec opencode
        else
            log "Non-interactive mode detected - OpenCode may not work properly"
            log "For best results, run with: docker run -it"
            exec opencode
        fi
    else
        log "Executing command: $*"
        exec "$@"
    fi
}

# Set up signal handlers for cleanup
trap 'cleanup_logging "entrypoint.sh"; exit 1' INT TERM

# Run main function with all arguments
main "$@"

# Cleanup logging
cleanup_logging "entrypoint.sh"

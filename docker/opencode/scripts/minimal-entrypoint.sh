#!/bin/bash

# Minimal OpenCode Container Entrypoint Script
# Focuses on essential setup only to avoid interfering with OpenCode

set -e

# Load container-local logging module
if [[ -f "/usr/local/lib/logging.sh" ]]; then
    # Use container-local logging module (primary)
    source "/usr/local/lib/logging.sh"
    setup_logging "minimal-entrypoint.sh"
elif [[ -f "/workspace/scripts/lib/logging.sh" ]]; then
    # Fallback to workspace logging module if available
    source "/workspace/scripts/lib/logging.sh"
    setup_logging "minimal-entrypoint.sh"
else
    # Basic fallback logging (should rarely be needed)
    log_info() {
        local operation="$1"
        local message="$2"
        echo "[$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")] [INFO] [minimal-entrypoint.sh] [$operation] $message"
    }

    log_error() {
        local operation="$1"
        local message="$2"
        echo "[$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")] [ERROR] [minimal-entrypoint.sh] [$operation] $message" >&2
    }

    log_warn() {
        local operation="$1"
        local message="$2"
        echo "[$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")] [WARN] [minimal-entrypoint.sh] [$operation] $message"
    }

    log_debug() {
        local operation="$1"
        local message="$2"
        echo "[$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")] [DEBUG] [minimal-entrypoint.sh] [$operation] $message"
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

success() {
    log_info "general" "$1"
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

    # Check for debug mode
    if [[ $# -gt 0 ]] && [[ "$1" == "--debug" || "$1" == "bash" ]]; then
        log "Debug mode requested - starting interactive bash shell"
        log "Environment variables are configured and ready"
        log "Use 'opencode' command to start OpenCode manually"
        log "Use 'exit' to leave the container"
        success "Entering debug shell..."
        exec bash
    fi

    # Execute the provided command or start OpenCode
    if [[ $# -eq 0 ]]; then
        success "Starting OpenCode..."
        exec opencode
    else
        log "Executing command: $*"
        exec "$@"
    fi
}

# Set up signal handlers for cleanup
trap 'cleanup_logging "minimal-entrypoint.sh"; exit 1' INT TERM

# Run main function with all arguments
main "$@"

# Cleanup logging
cleanup_logging "minimal-entrypoint.sh"

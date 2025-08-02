#!/bin/bash
# OpenCode Container Entrypoint Script - Streamlined with conditional console logging

set -e

# === LOGGING INFRASTRUCTURE ===
# Consolidated logging with fallback support
load_logging() {
    # Try container-local logging first, then workspace, then fallback
    for logging_path in "/usr/local/lib/logging.sh" "/workspace/scripts/lib/logging.sh"; do
        if [[ -f "$logging_path" ]]; then
            source "$logging_path" && setup_logging "entrypoint.sh" && return 0
        fi
    done

    # Fallback logging implementation
    _log() {
        local level="$1" operation="$2" message="$3"
        local timestamp="$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")"
        local output="[$timestamp] [$level] [entrypoint.sh] [$operation] $message"
        [[ "$level" == "ERROR" ]] && echo "$output" >&2 || echo "$output"
    }

    log_info() { _log "INFO" "$1" "$2"; }
    log_error() { _log "ERROR" "$1" "$2"; }
    log_warn() { _log "WARN" "$1" "$2"; }
    log_debug() { _log "DEBUG" "$1" "$2"; }
    cleanup_logging() { true; }
}

# Initialize logging
load_logging

# === CORE FUNCTIONS ===

# Workspace validation
validate_workspace() {
    [[ -d "/workspace" && -w "/workspace" ]] || { log_error "validation" "Invalid workspace directory"; return 1; }
    mkdir -p /workspace/.opencode 2>/dev/null || true
}

# Environment setup for MCP servers
setup_environment() {
    [[ -n "${GITHUB_TOKEN:-}" ]] && export GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_TOKEN"
}

# OpenCode startup with conditional console logging
start_opencode() {
    local print_logs="$1"
    if [[ "$print_logs" == "true" ]]; then
        log_info "opencode_start" "Starting OpenCode with console logging..."
        exec opencode --print-logs
    else
        log_info "opencode_start" "Starting OpenCode..."
        exec opencode
    fi
}

# === MAIN EXECUTION ===
main() {
    log_info "startup" "OpenCode container starting..."

    # Parse command line arguments
    local print_logs="false"
    local remaining_args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --print-logs)
                print_logs="true"
                shift
                ;;
            --debug|bash)
                log_info "debug_mode" "Debug mode - starting interactive shell (use 'opencode' or 'opencode --print-logs' to start manually)"
                exec bash
                ;;
            *)
                remaining_args+=("$1")
                shift
                ;;
        esac
    done

    # Validate workspace and setup environment
    validate_workspace || { log_error "validation" "Workspace validation failed"; exit 1; }
    setup_environment && cd /workspace

    # Display startup information
    local version="$(opencode --version 2>/dev/null || echo 'Unknown')"
    local api_status="$([[ -n "${OPENROUTER_API_KEY:-}" ]] && echo "configured" || echo "not configured")"
    local logging_status="$([[ "$print_logs" == "true" ]] && echo "console logging enabled" || echo "standard logging")"
    log_info "startup" "OpenCode v$version | Workspace: $(pwd) | API Key: $api_status | $logging_status"

    # Execute command or start OpenCode
    if [[ ${#remaining_args[@]} -eq 0 ]]; then
        start_opencode "$print_logs"
    else
        log_info "command_exec" "Executing command: ${remaining_args[*]}"
        exec "${remaining_args[@]}"
    fi
}

# === CLEANUP AND SIGNAL HANDLING ===
cleanup_entrypoint() {
    log_info "cleanup" "Performing cleanup..."
    cleanup_logging "entrypoint.sh"
}

# Setup signal handlers and execute
trap 'cleanup_entrypoint; exit 1' INT TERM
main "$@"
cleanup_entrypoint

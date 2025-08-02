#!/bin/bash

# OpenCode Container Health Check Script
# Verifies that OpenCode and all MCP servers are functioning correctly

set -e

# Exit codes
EXIT_SUCCESS=0
EXIT_FAILURE=1

# Load container-local logging module
if [[ -f "/usr/local/lib/logging.sh" ]]; then
    # Use container-local logging module (primary)
    source "/usr/local/lib/logging.sh"
    setup_logging "healthcheck.sh"
elif [[ -f "/workspace/scripts/lib/logging.sh" ]]; then
    # Fallback to workspace logging module if available
    source "/workspace/scripts/lib/logging.sh"
    setup_logging "healthcheck.sh"
else
    # Basic fallback logging (should rarely be needed)
    log_info() {
        local operation="$1"
        local message="$2"
        echo "[$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")] [INFO] [healthcheck.sh] [$operation] $message"
    }

    log_error() {
        local operation="$1"
        local message="$2"
        echo "[$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")] [ERROR] [healthcheck.sh] [$operation] $message" >&2
    }

    log_warn() {
        local operation="$1"
        local message="$2"
        echo "[$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")] [WARN] [healthcheck.sh] [$operation] $message"
    }

    log_debug() {
        local operation="$1"
        local message="$2"
        echo "[$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")] [DEBUG] [healthcheck.sh] [$operation] $message"
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

# Function to check if a command exists and is executable
check_command() {
    local cmd="$1"
    local description="$2"
    
    if command -v "$cmd" >/dev/null 2>&1; then
        success "$description is available"
        return 0
    else
        error "$description is not available"
        return 1
    fi
}

# Function to check if a service is responding
check_service() {
    local cmd="$1"
    local description="$2"
    local timeout="${3:-5}"
    
    if timeout "$timeout" "$cmd" --version >/dev/null 2>&1; then
        success "$description is responding"
        return 0
    else
        warning "$description is not responding"
        return 1
    fi
}

# Function to check file existence and permissions
check_file() {
    local file="$1"
    local description="$2"
    local required="${3:-true}"
    
    if [[ -f "$file" ]]; then
        if [[ -r "$file" ]]; then
            success "$description exists and is readable"
            return 0
        else
            error "$description exists but is not readable"
            return 1
        fi
    else
        if [[ "$required" == "true" ]]; then
            error "$description does not exist"
            return 1
        else
            warning "$description does not exist (optional)"
            return 0
        fi
    fi
}

# Function to check directory existence and permissions
check_directory() {
    local dir="$1"
    local description="$2"
    local writable="${3:-false}"
    
    if [[ -d "$dir" ]]; then
        if [[ "$writable" == "true" && ! -w "$dir" ]]; then
            error "$description exists but is not writable"
            return 1
        else
            success "$description exists and has correct permissions"
            return 0
        fi
    else
        error "$description does not exist"
        return 1
    fi
}

# Function to validate JSON file
check_json() {
    local file="$1"
    local description="$2"
    
    if [[ -f "$file" ]]; then
        if python3 -m json.tool "$file" >/dev/null 2>&1; then
            success "$description is valid JSON"
            return 0
        else
            error "$description is not valid JSON"
            return 1
        fi
    else
        error "$description does not exist"
        return 1
    fi
}

# Function to check environment variables
check_environment() {
    log_info "env_check" "Checking environment variables..."

    local env_ok=true

    # Check for API key
    if [[ -n "${OPENROUTER_API_KEY:-}" ]]; then
        log_info "env_check" "API key is configured"
    else
        log_error "env_check" "No API key configured (OPENROUTER_API_KEY)"
        env_ok=false
    fi

    # Check GITHUB_TOKEN (optional)
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        log_info "env_check" "GITHUB_TOKEN is configured"
    else
        log_warn "env_check" "GITHUB_TOKEN is not configured (GitHub MCP and GitHub CLI will be limited)"
    fi

    if [[ "$env_ok" == "true" ]]; then
        log_debug "env_check" "Environment check passed"
        return 0
    else
        log_debug "env_check" "Environment check failed"
        return 1
    fi
}

# Function to check core system components
check_system() {
    log "Checking system components..."
    
    local system_ok=true
    
    # Check Node.js
    if ! check_command "node" "Node.js"; then
        system_ok=false
    fi
    
    # Check npm
    if ! check_command "npm" "npm"; then
        system_ok=false
    fi
    
    # Check Python (for JSON validation)
    if ! check_command "python3" "Python 3"; then
        system_ok=false
    fi
    
    # Check git
    if ! check_command "git" "Git"; then
        system_ok=false
    fi

    # Check GitHub CLI
    if ! check_command "gh" "GitHub CLI"; then
        log_warn "system_check" "GitHub CLI not available (gh command not found)"
        # Don't fail system check for missing GitHub CLI as it's not critical
    else
        log_info "system_check" "GitHub CLI is available"
    fi

    if [[ "$system_ok" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check OpenCode installation and configuration
check_opencode() {
    log "Checking OpenCode..."
    
    local opencode_ok=true
    
    # Check OpenCode command
    if ! check_command "opencode" "OpenCode"; then
        opencode_ok=false
    fi
    
    # Check OpenCode configuration file
    local config_file="$HOME/.config/opencode/opencode.json"
    if ! check_json "$config_file" "OpenCode configuration"; then
        opencode_ok=false
    fi
    
    # Check OpenCode data directory
    if ! check_directory "/workspace/.opencode" "OpenCode data directory" "true"; then
        opencode_ok=false
    fi
    
    if [[ "$opencode_ok" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check MCP servers
check_mcp_servers() {
    log "Checking MCP servers..."

    local mcp_ok=true

    # Check if MCP server packages are installed
    local mcp_packages=(
        "@playwright/mcp"
        "@modelcontextprotocol/server-sequential-thinking"
        "@jpisnice/shadcn-ui-mcp-server"
    )

    for package in "${mcp_packages[@]}"; do
        if npm list -g "$package" >/dev/null 2>&1; then
            success "MCP server $package is installed"
        else
            warning "MCP server $package is not installed"
            # Don't fail the health check for missing MCP servers
        fi
    done

    # MCP servers are optional, so always return success
    return 0
}

# Function to check workspace and AI assets
check_workspace() {
    log "Checking workspace and AI assets..."
    
    local workspace_ok=true
    
    # Check workspace directory
    if ! check_directory "/workspace" "Workspace directory" "true"; then
        workspace_ok=false
    fi
    
    # Check AGENTS.md file
    if ! check_file "/root/.config/opencode/AGENTS.md" "Global agents configuration" "false"; then
        # This is not critical, just a warning
        true
    fi
    
    if [[ "$workspace_ok" == "true" ]]; then
        return 0
    else
        return 1
    fi
}



# Main health check function
main() {
    log "Starting OpenCode container health check..."
    
    local overall_health=true
    
    # Check environment variables
    if ! check_environment; then
        overall_health=false
    fi
    
    # Check system components
    if ! check_system; then
        overall_health=false
    fi
    
    # Check OpenCode
    if ! check_opencode; then
        overall_health=false
    fi
    
    # Check MCP servers
    if ! check_mcp_servers; then
        overall_health=false
    fi
    
    # Check workspace
    if ! check_workspace; then
        overall_health=false
    fi
    

    
    # Final health status
    if [[ "$overall_health" == "true" ]]; then
        log_info "health_check" "OpenCode container health check PASSED"
        cleanup_logging "healthcheck.sh"
        return $EXIT_SUCCESS
    else
        log_error "health_check" "OpenCode container health check FAILED"
        cleanup_logging "healthcheck.sh"
        return $EXIT_FAILURE
    fi
}

# Set up signal handlers for cleanup
trap 'cleanup_logging "healthcheck.sh"; exit 1' INT TERM

# Run main function
main "$@"

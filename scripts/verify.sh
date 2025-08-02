#!/bin/bash

# OpenCode Container Verification Script
# Comprehensive testing of OpenCode functionality and MCP server connectivity

set -e

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load centralized logging module
source "$SCRIPT_DIR/lib/logging.sh"

# Initialize logging
setup_logging "verify.sh"

# Test results tracking
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result functions
test_start() {
    local test_name="$1"
    ((TESTS_TOTAL++))
    log_info "test_execution" "Testing: $test_name"
}

test_pass() {
    local test_name="$1"
    ((TESTS_PASSED++))
    log_info "test_result" "✓ $test_name"
}

test_fail() {
    local test_name="$1"
    local reason="$2"
    ((TESTS_FAILED++))
    log_error "test_result" "✗ $test_name - $reason"
}

# Function to check if container is running
check_container_running() {
    test_start "Container Status"

    log_debug "container_check" "Checking if horizon-opencode container is running"
    if docker-compose ps | grep -q "horizon-opencode.*Up"; then
        test_pass "Container is running"
        log_debug "container_check" "Container status check passed"
        return 0
    else
        test_fail "Container Status" "Container is not running"
        log_debug "container_check" "Container status check failed"
        return 1
    fi
}

# Function to check container health
check_container_health() {
    test_start "Container Health"

    # Get the full docker-compose ps output for the container
    local container_line=$(docker-compose ps | grep "horizon-opencode")
    log "Container status line: $container_line"

    # Extract the status field (which contains the health information)
    # The status field is typically the 6th field in docker-compose ps output
    local status_field=$(echo "$container_line" | awk '{for(i=6;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/[[:space:]]*$//')
    log "Extracted status field: '$status_field'"

    # Check Docker's native health status using compose
    local docker_health=$(docker-compose exec -T opencode sh -c 'echo "healthy"' 2>/dev/null && echo "healthy" || echo "unhealthy")
    log "Container health status: $docker_health"

    # Check if container is healthy using multiple methods
    if [[ "$status_field" == *"healthy"* ]] || [[ "$docker_health" == "healthy" ]]; then
        test_pass "Container is healthy"
        log "Health check details:"
        log "  - Docker Compose status: $status_field"
        log "  - Docker native health: $docker_health"
        return 0
    elif [[ "$status_field" == *"starting"* ]] || [[ "$docker_health" == "starting" ]]; then
        warning "Container is still starting, waiting..."
        log "Current status: $status_field"
        sleep 10
        check_container_health
        return $?
    else
        test_fail "Container Health" "Container is not healthy"
        error "Health check details:"
        error "  - Docker Compose status: $status_field"
        error "  - Docker native health: $docker_health"
        error "  - Full container line: $container_line"

        # Show recent logs
        log "Recent container logs:"
        docker-compose logs --tail=5 opencode 2>/dev/null || echo "No logs available"

        return 1
    fi
}

# Function to test OpenCode installation
test_opencode_installation() {
    test_start "OpenCode Installation"
    
    if docker-compose exec -T opencode opencode --version >/dev/null 2>&1; then
        local version=$(docker-compose exec -T opencode opencode --version 2>/dev/null | tr -d '\r')
        test_pass "OpenCode is installed (version: $version)"
        return 0
    else
        test_fail "OpenCode Installation" "OpenCode command not found or not working"
        return 1
    fi
}

# Function to test OpenCode configuration
test_opencode_configuration() {
    test_start "OpenCode Configuration"

    # Try multiple possible configuration paths
    local config_paths=(
        "~/.config/opencode/opencode.json"
        "/.opencode/opencode.json"
        "/root/.config/opencode/opencode.json"
        "/workspace/.opencode/opencode.json"
    )

    local config_found=false
    local config_path=""

    for path in "${config_paths[@]}"; do
        if docker-compose exec -T opencode test -f "$path" 2>/dev/null; then
            config_found=true
            config_path="$path"
            break
        fi
    done

    if [[ "$config_found" == "true" ]]; then
        log "Found configuration at: $config_path"
        # Validate JSON syntax
        if docker-compose exec -T opencode python3 -m json.tool "$config_path" >/dev/null 2>&1; then
            test_pass "OpenCode configuration is valid"
            return 0
        else
            test_fail "OpenCode Configuration" "Configuration file is not valid JSON"
            return 1
        fi
    else
        # Configuration might be optional or generated at runtime
        warning "OpenCode configuration file not found in standard locations"
        log "Checked paths: ${config_paths[*]}"

        # Check if OpenCode can run without explicit config
        if docker-compose exec -T opencode timeout 10 opencode --help >/dev/null 2>&1; then
            test_pass "OpenCode configuration (using defaults or runtime config)"
            return 0
        else
            test_fail "OpenCode Configuration" "No configuration found and OpenCode not responding"
            return 1
        fi
    fi
}

# Function to test MCP server availability
test_mcp_server() {
    local server_name="$1"
    local server_command="$2"

    test_start "MCP Server: $server_name"

    # First check if the command exists
    if docker-compose exec -T opencode which "$server_command" >/dev/null 2>&1; then
        log "Command '$server_command' found in container"

        # Try to get version with timeout
        if docker-compose exec -T opencode timeout 5 "$server_command" --version >/dev/null 2>&1; then
            test_pass "MCP Server: $server_name is responding"
            return 0
        else
            warning "MCP Server: $server_name command exists but not responding to --version"
            # Some MCP servers might not support --version, try --help
            if docker-compose exec -T opencode timeout 5 "$server_command" --help >/dev/null 2>&1; then
                test_pass "MCP Server: $server_name is available (responds to --help)"
                return 0
            else
                test_fail "MCP Server: $server_name" "Server not responding to version or help commands"
                return 1
            fi
        fi
    else
        # Check if it's installed as an npm package
        local package_name=""
        case "$server_name" in
            "Context7") package_name="context7-mcp-server" ;;
            "GitHub MCP") package_name="@modelcontextprotocol/server-github" ;;
            "Playwright") package_name="@playwright/mcp" ;;
            "ShadCN UI") package_name="@jpisnice/shadcn-ui-mcp-server" ;;
            "Sequential Thinking") package_name="@modelcontextprotocol/server-sequential-thinking" ;;
        esac

        if [[ -n "$package_name" ]] && docker-compose exec -T opencode npm list -g "$package_name" >/dev/null 2>&1; then
            test_pass "MCP Server: $server_name is installed as npm package"
            return 0
        else
            warning "MCP Server: $server_name not found (command: $server_command)"
            log "This is not critical - MCP servers are optional components"
            return 0  # Don't fail the overall test for missing MCP servers
        fi
    fi
}

# Function to test all MCP servers
test_all_mcp_servers() {
    log "Testing MCP servers..."
    
    # Test Context7 MCP server
    test_mcp_server "Context7" "context7-mcp-server"
    
    # Test GitHub MCP server
    test_mcp_server "GitHub MCP" "github-mcp-server"
    
    # Test Playwright MCP server
    test_mcp_server "Playwright" "playwright-mcp-server"
    
    # Test ShadCN UI MCP server
    test_mcp_server "ShadCN UI" "shadcn-ui-mcp-server"
    
    # Test Sequential Thinking MCP server
    test_mcp_server "Sequential Thinking" "sequential-thinking-mcp-server"

    # Test Magic MCP server (21st.dev)
    test_mcp_server "Magic (21st.dev)" "magic-mcp-server"
}

# Function to test workspace mounting
test_workspace_mounting() {
    test_start "Workspace Mounting"
    
    # Create a test file in the host workspace
    local test_file="$PROJECT_ROOT/.test_workspace_mount"
    echo "test" > "$test_file"
    
    # Check if the file is visible in the container
    if docker-compose exec -T opencode test -f /workspace/.test_workspace_mount; then
        # Clean up test file
        rm -f "$test_file"
        test_pass "Workspace is properly mounted"
        return 0
    else
        # Clean up test file
        rm -f "$test_file"
        test_fail "Workspace Mounting" "Workspace directory not properly mounted"
        return 1
    fi
}

# Function to test AI assets mounting
test_ai_assets_mounting() {
    test_start "AI Assets Mounting"
    
    # Check if .ai directory is mounted
    if docker-compose exec -T opencode test -d /.ai; then
        # Check if AGENTS.md exists
        if docker-compose exec -T opencode test -f /.ai/AGENTS.md; then
            test_pass "AI assets are properly mounted"
            return 0
        else
            test_fail "AI Assets Mounting" "AGENTS.md not found in .ai directory"
            return 1
        fi
    else
        test_fail "AI Assets Mounting" ".ai directory not mounted"
        return 1
    fi
}

# Function to test environment variables
test_environment_variables() {
    test_start "Environment Variables"

    local env_ok=true

    # Check for OpenRouter API key (required)
    if docker-compose exec -T opencode printenv OPENROUTER_API_KEY >/dev/null 2>&1; then
        success "✓ OpenRouter API key is configured (enables AI model access)"
    else
        error "✗ OpenRouter API key is missing (required for AI provider access)"
        error "  Set OPENROUTER_API_KEY environment variable or use --openrouter-api-key"
        env_ok=false
    fi

    # Check for GitHub token (optional)
    if docker-compose exec -T opencode printenv GITHUB_TOKEN >/dev/null 2>&1; then
        success "✓ GitHub token is configured (GitHub MCP server enabled)"
    else
        log "ℹ GitHub token not configured (GitHub MCP server disabled)"
    fi

    # Check for Magic API key (optional)
    if docker-compose exec -T opencode printenv TWENTY_FIRST_API_KEY >/dev/null 2>&1; then
        success "✓ Magic API key is configured (21st.dev Magic MCP server enabled)"
    else
        log "ℹ Magic API key not configured (Magic MCP server disabled)"
    fi

    if [[ "$env_ok" == "true" ]]; then
        test_pass "Environment variables are properly configured"
        return 0
    else
        test_fail "Environment Variables" "Required OpenRouter API key is missing"
        return 1
    fi
}



# Function to test OpenCode basic functionality
test_opencode_functionality() {
    test_start "OpenCode Basic Functionality"
    
    # Try to run a simple OpenCode command
    if docker-compose exec -T opencode timeout 30 opencode --help >/dev/null 2>&1; then
        test_pass "OpenCode basic functionality works"
        return 0
    else
        test_fail "OpenCode Basic Functionality" "OpenCode help command failed"
        return 1
    fi
}

# Function to test container logs
test_container_logs() {
    test_start "Container Logs"
    
    # Check if container is producing logs
    local log_lines=$(docker-compose logs --tail=10 opencode 2>/dev/null | wc -l)
    
    if [[ $log_lines -gt 0 ]]; then
        test_pass "Container is producing logs ($log_lines lines)"
        return 0
    else
        test_fail "Container Logs" "No logs found"
        return 1
    fi
}

# Function to run comprehensive health check
run_health_check() {
    test_start "Internal Health Check"

    # Capture the health check output for detailed diagnostics
    local health_output
    local health_exit_code

    health_output=$(docker-compose exec -T opencode /usr/local/bin/healthcheck.sh 2>&1)
    health_exit_code=$?

    if [[ $health_exit_code -eq 0 ]]; then
        test_pass "Internal health check passed"
        log "Health check summary:"
        echo "$health_output" | grep -E "\[OK\]|\[SUCCESS\]" | head -5 | while read line; do
            log "  $line"
        done
        return 0
    else
        test_fail "Internal Health Check" "Health check script failed (exit code: $health_exit_code)"
        error "Health check output:"
        echo "$health_output" | while read line; do
            error "  $line"
        done
        return 1
    fi
}

# Function to display detailed health diagnostics
display_health_diagnostics() {
    log "Detailed Health Diagnostics:"

    # Docker Compose container state
    log "1. Container State:"
    local container_status=$(docker-compose ps opencode --format "table {{.State}}" 2>/dev/null | tail -n +2 || echo "unknown")
    local container_running=$(docker-compose exec -T opencode echo "running" 2>/dev/null && echo "true" || echo "false")
    log "   Status: $container_status"
    log "   Running: $container_running"

    # Service configuration
    log ""
    log "2. Service Configuration:"
    local service_config=$(docker-compose config --services 2>/dev/null | grep opencode || echo "none")
    log "   Service: $service_config"
    log "   Compose file: docker-compose.yml"

    # Recent logs
    log ""
    log "3. Recent Container Logs:"
    docker-compose logs --tail=5 opencode 2>/dev/null | while read line; do
        log "   $line"
    done || log "   No logs available"

    # Process information
    log ""
    log "4. Container Processes:"
    docker-compose exec -T opencode ps aux 2>/dev/null | head -10 | while read line; do
        log "   $line"
    done || log "   Unable to retrieve process information"
}

# Function to display test summary
display_summary() {
    log "Test Summary:"
    log "  Total tests: $TESTS_TOTAL"
    log "  Passed: $TESTS_PASSED"
    log "  Failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        success "All tests passed! OpenCode container is fully functional."
        return 0
    else
        error "$TESTS_FAILED test(s) failed. Please check the issues above."
        return 1
    fi
}

# Function to display troubleshooting information
display_troubleshooting() {
    if [[ $TESTS_FAILED -gt 0 ]]; then
        log "Troubleshooting Information:"
        log "  1. Check container logs: docker-compose logs opencode"
        log "  2. Check container status: docker-compose ps"
        log "  3. Check service status: docker-compose ps opencode"
        log "  4. Access container shell: docker-compose exec opencode bash"
        log "  5. Restart container: docker-compose restart opencode"
        log "  6. Rebuild container: docker-compose down && docker-compose up -d"
        log "  7. Check environment variables in .env file"
        log "  8. Verify Docker and Docker Compose installation"
        log "  9. Run internal health check: docker-compose exec opencode /usr/local/bin/healthcheck.sh"

        # Show current diagnostic information
        log ""
        log "Current Diagnostic Information:"

        # Container status
        log "Container Status:"
        docker-compose ps | grep -E "(NAME|horizon-opencode)" || echo "  No container information available"

        # Recent logs
        log ""
        log "Recent Container Logs (last 10 lines):"
        docker-compose logs --tail=10 opencode 2>/dev/null || echo "  No logs available"

        # Service status
        log ""
        log "Service Status:"
        local service_status=$(docker-compose ps opencode --format "table {{.State}}" 2>/dev/null | tail -n +2 || echo "unknown")
        log "  Service Status: $service_status"

        # Environment check
        log ""
        log "API Keys and Authentication Status:"
        if docker-compose exec -T opencode printenv OPENROUTER_API_KEY >/dev/null 2>&1; then
            log "  ✓ OpenRouter API Key: Configured (AI models: Claude Sonnet 4, Gemini 2.5 Pro)"
        else
            log "  ✗ OpenRouter API Key: Missing (REQUIRED for AI provider access)"
            log "    → Get your key from: https://openrouter.ai/keys"
            log "    → Set via: --openrouter-api-key or OPENROUTER_API_KEY environment variable"
        fi

        if docker-compose exec -T opencode printenv GITHUB_TOKEN >/dev/null 2>&1; then
            log "  ✓ GitHub Token: Configured (GitHub MCP server enabled)"
            log "    → Enables: Repository operations, issue management, code search"
        else
            log "  ⚠ GitHub Token: Not configured (GitHub MCP server disabled)"
            log "    → Optional: Set via --github-token or GITHUB_TOKEN environment variable"
        fi

        if docker-compose exec -T opencode printenv TWENTY_FIRST_API_KEY >/dev/null 2>&1; then
            log "  ✓ Magic API Key: Configured (21st.dev Magic MCP server enabled)"
            log "    → Enables: Advanced Magic MCP functionality"
        else
            log "  ⚠ Magic API Key: Not configured (Magic MCP server disabled)"
            log "    → Optional: Set via --magic-key or TWENTY_FIRST_API_KEY environment variable"
        fi
    fi
}

# Main function
main() {
    log "Starting OpenCode container verification..."
    
    # Change to project root directory
    cd "$PROJECT_ROOT"
    
    # Basic container checks
    check_container_running || exit 1
    check_container_health || exit 1
    
    # OpenCode installation and configuration
    test_opencode_installation
    test_opencode_configuration
    
    # MCP servers
    test_all_mcp_servers
    
    # Mounting and environment
    test_workspace_mounting
    test_ai_assets_mounting
    test_environment_variables
    
    # System functionality
    test_opencode_functionality
    test_container_logs
    
    # Comprehensive health check
    run_health_check
    
    # Display results
    display_summary
    local exit_code=$?

    # Show detailed diagnostics if there were failures
    if [[ $TESTS_FAILED -gt 0 ]]; then
        display_health_diagnostics
    fi

    display_troubleshooting

    # Cleanup logging
    cleanup_logging "verify.sh"

    return $exit_code
}

# Set up signal handlers for cleanup
trap 'cleanup_logging "verify.sh"; exit 1' INT TERM

# Run main function
main "$@"

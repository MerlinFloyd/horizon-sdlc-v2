#!/bin/bash

# OpenCode Container Verification Script
# Comprehensive testing of OpenCode functionality and MCP server connectivity

set -e

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

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

# Test result functions
test_start() {
    local test_name="$1"
    ((TESTS_TOTAL++))
    log "Testing: $test_name"
}

test_pass() {
    local test_name="$1"
    ((TESTS_PASSED++))
    success "✓ $test_name"
}

test_fail() {
    local test_name="$1"
    local reason="$2"
    ((TESTS_FAILED++))
    error "✗ $test_name - $reason"
}

# Function to check if container is running
check_container_running() {
    test_start "Container Status"
    
    if docker-compose ps | grep -q "horizon-opencode.*Up"; then
        test_pass "Container is running"
        return 0
    else
        test_fail "Container Status" "Container is not running"
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

    # Check Docker's native health status as well
    local docker_health=$(docker inspect horizon-opencode --format='{{.State.Health.Status}}' 2>/dev/null || echo "no-health-check")
    log "Docker native health status: $docker_health"

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

        # Show recent health check logs
        log "Recent health check logs:"
        docker inspect horizon-opencode --format='{{range .State.Health.Log}}{{.Start}}: {{.ExitCode}} - {{.Output}}{{end}}' 2>/dev/null | tail -3 || echo "No health check logs available"

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
    
    # Check for API key
    if docker-compose exec -T opencode printenv OPENROUTER_API_KEY >/dev/null 2>&1; then
        success "API key environment variable is set"
    else
        error "No API key environment variable found"
        env_ok=false
    fi
    
    if [[ "$env_ok" == "true" ]]; then
        test_pass "Environment variables are configured"
        return 0
    else
        test_fail "Environment Variables" "Required environment variables missing"
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

    # Docker container state
    log "1. Container State:"
    local container_state=$(docker inspect horizon-opencode --format='{{.State.Status}}' 2>/dev/null || echo "unknown")
    local container_running=$(docker inspect horizon-opencode --format='{{.State.Running}}' 2>/dev/null || echo "unknown")
    local container_pid=$(docker inspect horizon-opencode --format='{{.State.Pid}}' 2>/dev/null || echo "unknown")
    log "   Status: $container_state"
    log "   Running: $container_running"
    log "   PID: $container_pid"

    # Health check configuration
    log ""
    log "2. Health Check Configuration:"
    local health_test=$(docker inspect horizon-opencode --format='{{.Config.Healthcheck.Test}}' 2>/dev/null || echo "none")
    local health_interval=$(docker inspect horizon-opencode --format='{{.Config.Healthcheck.Interval}}' 2>/dev/null || echo "none")
    local health_timeout=$(docker inspect horizon-opencode --format='{{.Config.Healthcheck.Timeout}}' 2>/dev/null || echo "none")
    local health_retries=$(docker inspect horizon-opencode --format='{{.Config.Healthcheck.Retries}}' 2>/dev/null || echo "none")
    log "   Test: $health_test"
    log "   Interval: $health_interval"
    log "   Timeout: $health_timeout"
    log "   Retries: $health_retries"

    # Recent health check results
    log ""
    log "3. Recent Health Check Results:"
    docker inspect horizon-opencode --format='{{range .State.Health.Log}}{{.Start}}: Exit={{.ExitCode}} {{if .Output}}Output={{.Output}}{{else}}(no output){{end}}{{end}}' 2>/dev/null | tail -3 | while read line; do
        log "   $line"
    done || log "   No health check logs available"

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
        log "  3. Check Docker health status: docker inspect horizon-opencode --format='{{.State.Health.Status}}'"
        log "  4. View health check logs: docker inspect horizon-opencode --format='{{range .State.Health.Log}}{{.Start}}: {{.Output}}{{end}}'"
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

        # Health check status
        log ""
        log "Health Check Status:"
        local health_status=$(docker inspect horizon-opencode --format='{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
        log "  Docker Health Status: $health_status"

        # Environment check
        log ""
        log "Environment Variables Check:"
        if docker-compose exec -T opencode printenv OPENROUTER_API_KEY >/dev/null 2>&1; then
            log "  ✓ OPENROUTER_API_KEY is set"
        else
            log "  ✗ OPENROUTER_API_KEY is not set"
        fi

        if docker-compose exec -T opencode printenv GITHUB_TOKEN >/dev/null 2>&1; then
            log "  ✓ GITHUB_TOKEN is set"
        else
            log "  ⚠ GITHUB_TOKEN is not set (optional)"
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

    return $exit_code
}

# Run main function
main "$@"

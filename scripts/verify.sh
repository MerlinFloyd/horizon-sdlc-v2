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
    
    local health_status=$(docker-compose ps | grep "horizon-opencode" | awk '{print $4}')
    
    if [[ "$health_status" == *"healthy"* ]]; then
        test_pass "Container is healthy"
        return 0
    elif [[ "$health_status" == *"starting"* ]]; then
        warning "Container is still starting, waiting..."
        sleep 10
        check_container_health
        return $?
    else
        test_fail "Container Health" "Container is not healthy: $health_status"
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
    
    # Check if configuration file exists
    if docker-compose exec -T opencode test -f /.opencode/opencode.json; then
        # Validate JSON syntax
        if docker-compose exec -T opencode python3 -m json.tool /.opencode/opencode.json >/dev/null 2>&1; then
            test_pass "OpenCode configuration is valid"
            return 0
        else
            test_fail "OpenCode Configuration" "Configuration file is not valid JSON"
            return 1
        fi
    else
        test_fail "OpenCode Configuration" "Configuration file not found"
        return 1
    fi
}

# Function to test MCP server availability
test_mcp_server() {
    local server_name="$1"
    local server_command="$2"
    
    test_start "MCP Server: $server_name"
    
    if docker-compose exec -T opencode timeout 10 $server_command --version >/dev/null 2>&1; then
        test_pass "MCP Server: $server_name is responding"
        return 0
    else
        test_fail "MCP Server: $server_name" "Server not responding or not installed"
        return 1
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
    
    if docker-compose exec -T opencode /usr/local/bin/healthcheck.sh >/dev/null 2>&1; then
        test_pass "Internal health check passed"
        return 0
    else
        test_fail "Internal Health Check" "Health check script failed"
        return 1
    fi
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
        log "  3. Restart container: docker-compose restart opencode"
        log "  4. Rebuild container: docker-compose down && docker-compose up -d"
        log "  5. Check environment variables in .env file"
        log "  6. Verify Docker and Docker Compose installation"
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
    
    display_troubleshooting
    
    return $exit_code
}

# Run main function
main "$@"

#!/bin/bash

# test-logging.sh
# Script to test the comprehensive logging implementation
# Usage: ./scripts/test-logging.sh

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load centralized logging module
source "$SCRIPT_DIR/lib/logging.sh"

# Initialize logging
setup_logging "test-logging.sh"

# Test function to demonstrate all logging levels
test_logging_levels() {
    log_info "test_execution" "Testing all logging levels..."
    
    log_debug "debug_test" "This is a debug message with detailed information"
    log_info "info_test" "This is an informational message about normal operations"
    log_warn "warning_test" "This is a warning message about potential issues"
    log_error "error_test" "This is an error message about something that went wrong"
    log_fatal "fatal_test" "This is a fatal error message about critical failures"
}

# Test function to demonstrate operation-specific logging
test_operation_logging() {
    log_info "operation_test" "Testing operation-specific logging..."
    
    log_info "file_copy" "Copying configuration files to target directory"
    log_debug "file_copy" "Source: /src/config.json, Target: /dest/config.json"
    log_info "file_copy" "File copy completed successfully"
    
    log_info "docker_build" "Starting Docker image build process"
    log_debug "docker_build" "Using build context: /workspace/docker/opencode"
    log_warn "docker_build" "Build cache is disabled, this may take longer"
    log_info "docker_build" "Docker build completed successfully"
    
    log_info "env_setup" "Configuring environment variables"
    log_debug "env_setup" "Setting OPENROUTER_API_KEY from user input"
    log_debug "env_setup" "Setting NODE_ENV to production"
    log_info "env_setup" "Environment configuration completed"
}

# Test function to demonstrate line number tracking
test_line_numbers() {
    log_info "line_test" "Testing line number tracking..."
    
    # These should show different line numbers
    log_debug "line_test" "This is line $(echo $LINENO)"
    log_info "line_test" "This is line $(echo $LINENO)"
    log_warn "line_test" "This is line $(echo $LINENO)"
    log_error "line_test" "This is line $(echo $LINENO)"
}

# Test function to demonstrate JSON escaping
test_json_escaping() {
    log_info "json_test" "Testing JSON escaping..."
    
    log_info "json_test" "Message with \"quotes\" and special characters"
    log_warn "json_test" "Message with newlines
and multiple lines"
    log_error "json_test" "Message with backslashes \\ and forward slashes /"
    log_debug "json_test" "Message with unicode: 🚀 and symbols: @#$%^&*()"
}

# Test function to demonstrate backward compatibility
test_backward_compatibility() {
    log_info "compatibility_test" "Testing backward compatibility functions..."
    
    log "This uses the old log() function"
    error "This uses the old error() function"
    warning "This uses the old warning() function"
    success "This uses the old success() function"
}

# Test function to demonstrate log level filtering
test_log_level_filtering() {
    log_info "filter_test" "Testing log level filtering..."
    
    # Save current log level
    local original_level="$LOG_LEVEL"
    
    # Test with different log levels
    for level in "DEBUG" "INFO" "WARN" "ERROR" "FATAL"; do
        log_info "filter_test" "Setting log level to $level"
        LOG_LEVEL="$level"
        
        log_debug "filter_test" "Debug message (should only show if level is DEBUG)"
        log_info "filter_test" "Info message (should show if level is DEBUG or INFO)"
        log_warn "filter_test" "Warning message (should show if level is DEBUG, INFO, or WARN)"
        log_error "filter_test" "Error message (should show unless level is FATAL)"
        log_fatal "filter_test" "Fatal message (should always show)"
        
        echo "---"
    done
    
    # Restore original log level
    LOG_LEVEL="$original_level"
    log_info "filter_test" "Restored log level to $LOG_LEVEL"
}

# Test function to check log file creation and content
test_log_file() {
    log_info "file_test" "Testing log file creation and content..."
    
    local log_file="$LOG_DIR/$LOG_FILE"
    
    if [[ -f "$log_file" ]]; then
        log_info "file_test" "Log file exists: $log_file"
        
        local line_count=$(wc -l < "$log_file")
        log_info "file_test" "Log file contains $line_count lines"
        
        # Check if JSON is valid
        if tail -1 "$log_file" | python3 -m json.tool >/dev/null 2>&1; then
            log_info "file_test" "Last log entry is valid JSON"
        else
            log_warn "file_test" "Last log entry may not be valid JSON"
        fi
        
        # Show last few entries
        log_info "file_test" "Last 3 log entries:"
        tail -3 "$log_file" | while read -r line; do
            echo "  $line"
        done
    else
        log_error "file_test" "Log file does not exist: $log_file"
    fi
}

# Main test function
main() {
    log_info "test_start" "Starting comprehensive logging tests..."
    echo
    
    # Run all tests
    test_logging_levels
    echo
    
    test_operation_logging
    echo
    
    test_line_numbers
    echo
    
    test_json_escaping
    echo
    
    test_backward_compatibility
    echo
    
    test_log_level_filtering
    echo
    
    test_log_file
    echo
    
    log_info "test_complete" "All logging tests completed successfully!"
    
    # Show summary
    echo
    echo "=== LOGGING TEST SUMMARY ==="
    echo "Log directory: $LOG_DIR"
    echo "Log file: $LOG_DIR/$LOG_FILE"
    echo "Current log level: $LOG_LEVEL"
    echo "JSON logging enabled: $ENABLE_JSON_LOGGING"
    echo "Console logging enabled: $ENABLE_CONSOLE_LOGGING"
    echo
    
    if [[ -f "$LOG_DIR/$LOG_FILE" ]]; then
        echo "To view the JSON log file:"
        echo "  cat $LOG_DIR/$LOG_FILE | jq ."
        echo
        echo "To search for specific operations:"
        echo "  grep '\"operation\":\"docker_build\"' $LOG_DIR/$LOG_FILE | jq ."
        echo
        echo "To filter by log level:"
        echo "  grep '\"level\":\"ERROR\"' $LOG_DIR/$LOG_FILE | jq ."
    fi
    
    # Cleanup logging
    cleanup_logging "test-logging.sh"
}

# Set up signal handlers for cleanup
trap 'cleanup_logging "test-logging.sh"; exit 1' INT TERM

# Run main function
main "$@"

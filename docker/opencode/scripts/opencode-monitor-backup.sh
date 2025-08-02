#!/bin/bash

# OpenCode Monitoring and Error Handling Module
# Provides comprehensive startup monitoring, log capture, and error handling for OpenCode
# This module is sourced by the main entrypoint script

# Ensure this script is not executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This script should be sourced, not executed directly" >&2
    exit 1
fi

# OpenCode monitoring configuration (with defaults)
OPENCODE_STARTUP_TIMEOUT="${OPENCODE_STARTUP_TIMEOUT:-60}"
OPENCODE_LOG_DIR="${OPENCODE_LOG_DIR:-/var/log/opencode}"
OPENCODE_EARLY_EXIT_THRESHOLD="${OPENCODE_EARLY_EXIT_THRESHOLD:-10}"
OPENCODE_NATIVE_LOG_DIR="$HOME/.local/share/opencode/log"

# Global variable to track OpenCode process
OPENCODE_PID=""

# Set up log capture infrastructure
setup_log_capture() {
    log_info "log_setup" "Setting up OpenCode log capture..."
    
    # Create log directory if it doesn't exist
    if [[ ! -d "$OPENCODE_LOG_DIR" ]]; then
        if ! mkdir -p "$OPENCODE_LOG_DIR" 2>/dev/null; then
            log_warn "log_setup" "Failed to create log directory: $OPENCODE_LOG_DIR"
            log_warn "log_setup" "Log capture will be limited to stdout/stderr"
            return 1
        fi
    fi
    
    # Ensure log directory is writable
    if [[ ! -w "$OPENCODE_LOG_DIR" ]]; then
        log_warn "log_setup" "Log directory is not writable: $OPENCODE_LOG_DIR"
        log_warn "log_setup" "Log capture will be limited to stdout/stderr"
        return 1
    fi
    
    # Clean up any existing log files from previous runs
    rm -f "$OPENCODE_LOG_DIR"/*.log 2>/dev/null || true
    
    log_info "log_setup" "Log capture ready - logs will be written to: $OPENCODE_LOG_DIR"
    return 0
}

# Monitor OpenCode startup process
monitor_opencode_startup() {
    local pid="$1"
    local start_time=$(date +%s)
    local startup_success=false
    
    log_info "startup_monitor" "Monitoring OpenCode startup (PID: $pid, timeout: ${OPENCODE_STARTUP_TIMEOUT}s)"
    
    # Monitor the process for the specified timeout period
    while [[ $(($(date +%s) - start_time)) -lt $OPENCODE_STARTUP_TIMEOUT ]]; do
        # Check if process is still running
        if ! kill -0 "$pid" 2>/dev/null; then
            local elapsed=$(($(date +%s) - start_time))
            if [[ $elapsed -lt $OPENCODE_EARLY_EXIT_THRESHOLD ]]; then
                log_error "startup_monitor" "OpenCode exited early after ${elapsed}s (PID: $pid)"
                return 1
            else
                log_warn "startup_monitor" "OpenCode process ended after ${elapsed}s"
                return 2
            fi
        fi
        
        # Check for successful startup indicators (basic process health)
        # For now, we consider the process healthy if it's been running for a reasonable time
        local elapsed=$(($(date +%s) - start_time))
        if [[ $elapsed -ge $OPENCODE_EARLY_EXIT_THRESHOLD ]]; then
            startup_success=true
            break
        fi
        
        sleep 2
    done
    
    if [[ "$startup_success" == "true" ]]; then
        log_info "startup_monitor" "OpenCode startup monitoring completed successfully"
        return 0
    else
        log_warn "startup_monitor" "OpenCode startup monitoring timed out after ${OPENCODE_STARTUP_TIMEOUT}s"
        return 3
    fi
}

# Capture OpenCode's native log files
capture_opencode_native_logs() {
    log_info "log_capture" "Checking for OpenCode native log files..."
    
    # Check if OpenCode's native log directory exists
    if [[ -d "$OPENCODE_NATIVE_LOG_DIR" ]]; then
        # Find the most recent log file
        local latest_log=$(find "$OPENCODE_NATIVE_LOG_DIR" -name "*.log" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
        
        if [[ -n "$latest_log" && -f "$latest_log" ]]; then
            log_info "log_capture" "Found OpenCode log file: $latest_log"
            
            # Output the log file contents
            log_error "startup_failure" "=== OpenCode Native Log File: $(basename "$latest_log") ==="
            cat "$latest_log" >&2
            log_error "startup_failure" "=== End OpenCode Native Log ==="
            
            return 0
        else
            log_warn "log_capture" "No log files found in OpenCode native log directory"
            return 1
        fi
    else
        log_warn "log_capture" "OpenCode native log directory not found: $OPENCODE_NATIVE_LOG_DIR"
        return 1
    fi
}

# Handle OpenCode startup failure
handle_startup_failure() {
    local failure_type="$1"
    local pid="$2"
    
    log_error "startup_failure" "OpenCode startup failed: $failure_type"
    
    # Give a moment for any final log output
    sleep 2
    
    # First, try to capture OpenCode's native log files
    local native_logs_captured=false
    if capture_opencode_native_logs; then
        native_logs_captured=true
    fi
    
    # Also capture our own stdout/stderr logs if available
    if [[ -d "$OPENCODE_LOG_DIR" ]]; then
        log_error "startup_failure" "Capturing container-level OpenCode logs..."
        
        # Output stdout logs
        if [[ -f "$OPENCODE_LOG_DIR/stdout.log" && -s "$OPENCODE_LOG_DIR/stdout.log" ]]; then
            log_error "startup_failure" "=== Container STDOUT Logs ==="
            cat "$OPENCODE_LOG_DIR/stdout.log" >&2
            log_error "startup_failure" "=== End Container STDOUT Logs ==="
        else
            log_warn "startup_failure" "No container stdout logs captured"
        fi
        
        # Output stderr logs
        if [[ -f "$OPENCODE_LOG_DIR/stderr.log" && -s "$OPENCODE_LOG_DIR/stderr.log" ]]; then
            log_error "startup_failure" "=== Container STDERR Logs ==="
            cat "$OPENCODE_LOG_DIR/stderr.log" >&2
            log_error "startup_failure" "=== End Container STDERR Logs ==="
        else
            log_warn "startup_failure" "No container stderr logs captured"
        fi
    else
        log_warn "startup_failure" "Container log directory not available for error capture"
    fi
    
    # If no logs were captured, provide guidance
    if [[ "$native_logs_captured" == "false" ]]; then
        log_error "startup_failure" "No OpenCode native logs could be captured automatically"
        log_error "startup_failure" "Try running with debug mode: docker run -it container-name --debug"
        log_error "startup_failure" "Then manually run: opencode --print-logs"
        log_error "startup_failure" "Or check OpenCode logs at: ~/.local/share/opencode/log/"
    fi
    
    # Clean up process if still running
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        log_info "startup_failure" "Terminating OpenCode process (PID: $pid)"
        kill -TERM "$pid" 2>/dev/null || true
        sleep 5
        if kill -0 "$pid" 2>/dev/null; then
            log_warn "startup_failure" "Force killing OpenCode process (PID: $pid)"
            kill -KILL "$pid" 2>/dev/null || true
        fi
    fi
}

# Start OpenCode with comprehensive monitoring
start_opencode_monitored() {
    log_info "opencode_start" "Starting OpenCode with monitoring enabled..."
    
    # Set up log capture
    local log_capture_available=false
    if setup_log_capture; then
        log_capture_available=true
    fi
    
    # Start OpenCode with output capture
    if [[ "$log_capture_available" == "true" ]]; then
        # Create named pipes for real-time log capture
        local stdout_pipe="/tmp/opencode_stdout_$$"
        local stderr_pipe="/tmp/opencode_stderr_$$"
        
        mkfifo "$stdout_pipe" "$stderr_pipe" 2>/dev/null || {
            log_warn "opencode_start" "Failed to create named pipes, using direct output"
            log_capture_available=false
        }
    fi
    
    if [[ "$log_capture_available" == "true" ]]; then
        # Start background processes to handle log capture
        tee "$OPENCODE_LOG_DIR/stdout.log" < "$stdout_pipe" &
        local stdout_tee_pid=$!
        
        tee "$OPENCODE_LOG_DIR/stderr.log" < "$stderr_pipe" >&2 &
        local stderr_tee_pid=$!
        
        # Start OpenCode with output redirected to pipes and --print-logs for better error visibility
        log_info "opencode_start" "Starting OpenCode with log capture and print-logs enabled..."
        opencode --print-logs > "$stdout_pipe" 2> "$stderr_pipe" &
        OPENCODE_PID=$!
        
        # Clean up pipes after OpenCode starts
        rm -f "$stdout_pipe" "$stderr_pipe" 2>/dev/null || true
        
        log_info "opencode_start" "OpenCode started with PID: $OPENCODE_PID (logs: $OPENCODE_LOG_DIR)"
    else
        # Fallback: start OpenCode without log capture but with --print-logs for stderr visibility
        log_info "opencode_start" "Starting OpenCode with print-logs enabled (no file capture)..."
        opencode --print-logs &
        OPENCODE_PID=$!
        
        log_info "opencode_start" "OpenCode started with PID: $OPENCODE_PID (stderr logging enabled)"
    fi
    
    # Monitor startup
    local monitor_result=0
    monitor_opencode_startup "$OPENCODE_PID" || monitor_result=$?
    
    case $monitor_result in
        0)
            log_info "opencode_start" "OpenCode startup completed successfully"
            ;;
        1)
            handle_startup_failure "early_exit" "$OPENCODE_PID"
            return 1
            ;;
        2)
            log_warn "opencode_start" "OpenCode process ended during startup monitoring"
            handle_startup_failure "process_ended" "$OPENCODE_PID"
            return 2
            ;;
        3)
            log_warn "opencode_start" "OpenCode startup monitoring timed out (process may still be starting)"
            # Don't treat timeout as failure - OpenCode might just be slow to start
            ;;
        *)
            log_error "opencode_start" "Unknown monitoring result: $monitor_result"
            handle_startup_failure "unknown_error" "$OPENCODE_PID"
            return 1
            ;;
    esac
    
    # Wait for OpenCode process to complete
    log_info "opencode_start" "Waiting for OpenCode process to complete..."
    wait "$OPENCODE_PID"
    local exit_code=$?
    
    log_info "opencode_start" "OpenCode process completed with exit code: $exit_code"
    return $exit_code
}

# Cleanup function for graceful shutdown
cleanup_opencode_monitor() {
    log_info "cleanup" "Performing OpenCode monitoring cleanup..."
    
    # Terminate OpenCode if still running
    if [[ -n "$OPENCODE_PID" ]] && kill -0 "$OPENCODE_PID" 2>/dev/null; then
        log_info "cleanup" "Terminating OpenCode process (PID: $OPENCODE_PID)"
        kill -TERM "$OPENCODE_PID" 2>/dev/null || true
        
        # Give it time to shut down gracefully
        local timeout=10
        while [[ $timeout -gt 0 ]] && kill -0 "$OPENCODE_PID" 2>/dev/null; do
            sleep 1
            ((timeout--))
        done
        
        # Force kill if still running
        if kill -0 "$OPENCODE_PID" 2>/dev/null; then
            log_warn "cleanup" "Force killing OpenCode process (PID: $OPENCODE_PID)"
            kill -KILL "$OPENCODE_PID" 2>/dev/null || true
        fi
    fi
    
    # Clean up temporary files
    rm -f /tmp/opencode_*_$$ 2>/dev/null || true
    
    log_info "cleanup" "OpenCode monitoring cleanup completed"
}

# Export functions for use by the entrypoint script
export -f setup_log_capture monitor_opencode_startup capture_opencode_native_logs
export -f handle_startup_failure start_opencode_monitored cleanup_opencode_monitor

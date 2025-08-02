#!/bin/bash

# Horizon SDLC Centralized Logging Module
# Provides comprehensive logging with structured JSON output and human-readable console format
# 
# Required Log Fields:
# - timestamp: ISO 8601 formatted timestamp
# - level: Log level (DEBUG, INFO, WARN, ERROR, FATAL)
# - operation: Specific operation being performed
# - filename: Name of the file being processed or affected
# - line_number: Line number within the target file (if applicable)
# - script_line: Line number within the executing script where the log entry originates
# - message: Human-readable description of the event or error

# Global logging configuration
LOG_DIR="${LOG_DIR:-logs}"
LOG_FILE="${LOG_FILE:-horizon-sdlc.log}"
LOG_LEVEL="${LOG_LEVEL:-INFO}"
ENABLE_JSON_LOGGING="${ENABLE_JSON_LOGGING:-true}"
ENABLE_CONSOLE_LOGGING="${ENABLE_CONSOLE_LOGGING:-true}"

# Colors for console output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log level priorities (for filtering)
declare -A LOG_PRIORITIES=(
    ["DEBUG"]=0
    ["INFO"]=1
    ["WARN"]=2
    ["ERROR"]=3
    ["FATAL"]=4
)

# Initialize logging system
setup_logging() {
    local script_name="${1:-$(basename "${BASH_SOURCE[1]}")}"
    
    # Create log directory if it doesn't exist
    if [[ ! -d "$LOG_DIR" ]]; then
        if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
            echo "[WARNING] Failed to create log directory: $LOG_DIR" >&2
            echo "[WARNING] JSON logging will be disabled" >&2
            ENABLE_JSON_LOGGING="false"
            return 1
        fi
    fi
    
    # Initialize log file with session header
    if [[ "$ENABLE_JSON_LOGGING" == "true" ]]; then
        local log_path="$LOG_DIR/$LOG_FILE"
        local session_start=$(get_timestamp)
        
        # Create session marker in JSON log
        {
            cat << EOF
{"timestamp":"$session_start","level":"INFO","operation":"session_start","filename":"$script_name","line_number":0,"script_line":0,"message":"Logging session started for $script_name"}
EOF
        } >> "$log_path" 2>/dev/null || {
            echo "[WARNING] Failed to write to log file: $log_path" >&2
            echo "[WARNING] JSON logging will be disabled" >&2
            ENABLE_JSON_LOGGING="false"
            return 1
        }
    fi
    
    return 0
}

# Get ISO 8601 timestamp
get_timestamp() {
    # Try to get milliseconds if available, fallback to seconds
    if date -u +"%Y-%m-%dT%H:%M:%S.%3NZ" 2>/dev/null; then
        return 0
    else
        date -u +"%Y-%m-%dT%H:%M:%S.000Z"
    fi
}

# Extract caller information from bash call stack
get_caller_info() {
    local caller_level="${1:-2}"  # Default to 2 levels up (caller of log function)
    local filename=""
    local script_line=""
    
    # Extract filename from BASH_SOURCE
    if [[ ${#BASH_SOURCE[@]} -gt $caller_level ]]; then
        filename=$(basename "${BASH_SOURCE[$caller_level]}")
    else
        filename="unknown"
    fi
    
    # Extract line number from BASH_LINENO
    if [[ ${#BASH_LINENO[@]} -gt $((caller_level - 1)) ]]; then
        script_line="${BASH_LINENO[$((caller_level - 1))]}"
    else
        script_line="0"
    fi
    
    echo "$filename:$script_line"
}

# Escape JSON string
escape_json() {
    local input="$1"
    # Escape backslashes, quotes, and newlines for JSON
    echo "$input" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/g' | tr -d '\n' | sed 's/\\n$//'
}

# Check if log level should be output
should_log() {
    local level="$1"
    local current_priority="${LOG_PRIORITIES[$LOG_LEVEL]:-1}"
    local message_priority="${LOG_PRIORITIES[$level]:-1}"
    
    [[ $message_priority -ge $current_priority ]]
}

# Format console log message
format_console_log() {
    local timestamp="$1"
    local level="$2"
    local filename="$3"
    local script_line="$4"
    local operation="$5"
    local message="$6"
    
    # Choose color based on level
    local color=""
    case "$level" in
        "DEBUG") color="$CYAN" ;;
        "INFO") color="$BLUE" ;;
        "WARN") color="$YELLOW" ;;
        "ERROR") color="$RED" ;;
        "FATAL") color="$PURPLE" ;;
        *) color="$NC" ;;
    esac
    
    # Format: [TIMESTAMP] [LEVEL] [FILENAME] [LINE NUMBER] [OPERATION] message
    local short_timestamp=$(echo "$timestamp" | cut -d'.' -f1)Z
    echo -e "${color}[${short_timestamp}] [${level}] [${filename}] [${script_line}] [${operation}]${NC} ${message}"
}

# Format JSON log entry
format_json_log() {
    local timestamp="$1"
    local level="$2"
    local filename="$3"
    local script_line="$4"
    local operation="$5"
    local message="$6"
    local line_number="${7:-0}"  # Optional target file line number
    
    local escaped_message=$(escape_json "$message")
    local escaped_operation=$(escape_json "$operation")
    
    cat << EOF
{"timestamp":"$timestamp","level":"$level","operation":"$escaped_operation","filename":"$filename","line_number":$line_number,"script_line":$script_line,"message":"$escaped_message"}
EOF
}

# Core logging function
write_log() {
    local level="$1"
    local operation="$2"
    local message="$3"
    local line_number="${4:-0}"  # Optional target file line number
    
    # Check if we should log this level
    if ! should_log "$level"; then
        return 0
    fi
    
    local timestamp=$(get_timestamp)
    local caller_info=$(get_caller_info 3)  # 3 levels up to get actual caller
    local filename=$(echo "$caller_info" | cut -d':' -f1)
    local script_line=$(echo "$caller_info" | cut -d':' -f2)
    
    # Console output
    if [[ "$ENABLE_CONSOLE_LOGGING" == "true" ]]; then
        format_console_log "$timestamp" "$level" "$filename" "$script_line" "$operation" "$message"
    fi
    
    # JSON file output
    if [[ "$ENABLE_JSON_LOGGING" == "true" ]]; then
        local log_path="$LOG_DIR/$LOG_FILE"
        format_json_log "$timestamp" "$level" "$filename" "$script_line" "$operation" "$message" "$line_number" >> "$log_path" 2>/dev/null || {
            # Fallback: disable JSON logging if write fails
            ENABLE_JSON_LOGGING="false"
            echo "[WARNING] Failed to write to log file, disabling JSON logging" >&2
        }
    fi
}

# Level-specific logging functions
log_debug() {
    local operation="$1"
    local message="$2"
    local line_number="${3:-0}"
    write_log "DEBUG" "$operation" "$message" "$line_number"
}

log_info() {
    local operation="$1"
    local message="$2"
    local line_number="${3:-0}"
    write_log "INFO" "$operation" "$message" "$line_number"
}

log_warn() {
    local operation="$1"
    local message="$2"
    local line_number="${3:-0}"
    write_log "WARN" "$operation" "$message" "$line_number"
}

log_error() {
    local operation="$1"
    local message="$2"
    local line_number="${3:-0}"
    write_log "ERROR" "$operation" "$message" "$line_number"
}

log_fatal() {
    local operation="$1"
    local message="$2"
    local line_number="${3:-0}"
    write_log "FATAL" "$operation" "$message" "$line_number"
}



# Cleanup function for session end
cleanup_logging() {
    if [[ "$ENABLE_JSON_LOGGING" == "true" ]]; then
        local script_name="${1:-$(basename "${BASH_SOURCE[1]}")}"
        log_info "session_end" "Logging session ended for $script_name"
    fi
}

# Export functions for use in other scripts
export -f setup_logging get_timestamp get_caller_info escape_json should_log
export -f format_console_log format_json_log write_log
export -f log_debug log_info log_warn log_error log_fatal cleanup_logging

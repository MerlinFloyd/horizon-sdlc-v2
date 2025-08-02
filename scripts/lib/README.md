# Horizon SDLC Centralized Logging System

This directory contains the centralized logging module used across all build scripts, verification scripts, and automation scripts in the horizon-sdlc-v2 project.

## Overview

The logging system provides comprehensive, structured logging with the following features:

- **Structured JSON logging** to files for searchability and analysis
- **Human-readable console output** with color coding and timestamps
- **Automatic caller information** extraction (filename and line numbers)
- **Operation-specific logging** for better categorization and filtering
- **Multiple log levels** with configurable filtering
- **Error handling and fallbacks** to ensure scripts continue running even if logging fails
- **Backward compatibility** with existing script logging functions

## Required Log Fields

Each log entry includes the following fields:

- `timestamp`: ISO 8601 formatted timestamp (e.g., "2025-08-02T10:30:45.123Z")
- `level`: Log level (DEBUG, INFO, WARN, ERROR, FATAL)
- `operation`: Specific operation being performed (e.g., "docker_build", "dependency_install", "file_copy")
- `filename`: Name of the file being processed or affected
- `line_number`: Line number within the target file (if applicable)
- `script_line`: Line number within the executing script where the log entry originates
- `message`: Human-readable description of the event or error

## Output Formats

### Console Output (Human-Readable)
```
[2025-08-02T10:30:45Z] [ERROR] [build.sh] [15] [docker_build] Failed to copy requirements.txt
```

### Log File Output (JSON)
```json
{
  "timestamp": "2025-08-02T10:30:45.123Z",
  "level": "ERROR",
  "operation": "docker_build",
  "filename": "build.sh",
  "line_number": 15,
  "script_line": 15,
  "message": "Failed to copy requirements.txt"
}
```

## Usage

### Basic Setup

1. **Source the logging module** at the top of your script:
```bash
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logging.sh"
```

2. **Initialize logging** with your script name:
```bash
setup_logging "your-script.sh"
```

3. **Add cleanup** at the end of your script:
```bash
# Set up signal handlers for cleanup
trap 'cleanup_logging "your-script.sh"; exit 1' INT TERM

# At the end of your main function
cleanup_logging "your-script.sh"
```

### Logging Functions

#### Level-Specific Functions
```bash
log_debug "operation_name" "Debug message"
log_info "operation_name" "Informational message"
log_warn "operation_name" "Warning message"
log_error "operation_name" "Error message"
log_fatal "operation_name" "Fatal error message"
```

#### Backward Compatibility Functions
```bash
log "General message"           # Maps to log_info "general"
error "Error message"           # Maps to log_error "general"
warning "Warning message"       # Maps to log_warn "general"
success "Success message"       # Maps to log_info "general"
```

### Operation Names

Use descriptive, consistent operation names across scripts:

- **Build Operations**: `docker_build`, `image_tag`, `image_push`
- **Environment Setup**: `env_setup`, `env_validation`, `api_key_check`
- **File Operations**: `file_copy`, `file_create`, `directory_setup`
- **Container Operations**: `container_start`, `container_stop`, `health_check`
- **Verification**: `prerequisite_check`, `mcp_test`, `container_verify`
- **General**: `test_execution`, `test_result`, `session_start`, `session_end`

## Configuration

### Environment Variables

- `LOG_DIR`: Directory for log files (default: "logs")
- `LOG_FILE`: Log file name (default: "horizon-sdlc.log")
- `LOG_LEVEL`: Minimum log level to output (default: "INFO")
- `ENABLE_JSON_LOGGING`: Enable JSON file logging (default: "true")
- `ENABLE_CONSOLE_LOGGING`: Enable console output (default: "true")

### Log Levels

Log levels in order of priority:
1. `DEBUG` (0) - Detailed debugging information
2. `INFO` (1) - General informational messages
3. `WARN` (2) - Warning messages about potential issues
4. `ERROR` (3) - Error messages about failures
5. `FATAL` (4) - Critical errors that may cause script termination

## Container Environment

The logging system is designed to work in both host and container environments:

1. **Mounted Workspace**: Uses `/workspace/scripts/lib/logging.sh` when available
2. **Container-Local**: Uses `/usr/local/lib/logging.sh` copied during build
3. **Fallback**: Basic logging functions if neither is available

## Testing

Run the comprehensive logging test suite:

```bash
./scripts/test-logging.sh
```

This will test:
- All logging levels
- Operation-specific logging
- Line number tracking
- JSON escaping
- Backward compatibility
- Log level filtering
- Log file creation and validation

## Log Analysis

### View JSON Logs
```bash
cat logs/horizon-sdlc.log | jq .
```

### Search by Operation
```bash
grep '"operation":"docker_build"' logs/horizon-sdlc.log | jq .
```

### Filter by Log Level
```bash
grep '"level":"ERROR"' logs/horizon-sdlc.log | jq .
```

### Search by Timestamp Range
```bash
grep '"timestamp":"2025-08-02T10:3[0-9]"' logs/horizon-sdlc.log | jq .
```

## Error Handling

The logging system includes comprehensive error handling:

- **Log directory creation failure**: Disables JSON logging, continues with console only
- **Log file write failure**: Disables JSON logging, continues with console only
- **Missing logging module**: Falls back to basic logging functions
- **JSON formatting errors**: Escapes special characters automatically

## Best Practices

1. **Use descriptive operation names** that are consistent across scripts
2. **Include relevant context** in log messages (file paths, configuration values, etc.)
3. **Use appropriate log levels** based on message importance
4. **Always initialize and cleanup logging** in your scripts
5. **Test your logging** by running scripts and checking both console and file output
6. **Use structured data** in messages when possible for better searchability

## Files Updated

The following scripts have been updated to use the centralized logging system:

### Host Scripts
- `scripts/build.sh` - Main build script
- `scripts/verify.sh` - Verification script
- `scripts/start-opencode.sh` - Container startup script
- `scripts/test-debug-mode.sh` - Debug testing script

### Container Scripts
- `docker/opencode/scripts/entrypoint.sh` - Container entrypoint
- `docker/opencode/scripts/healthcheck.sh` - Health check script
- `docker/opencode/scripts/minimal-entrypoint.sh` - Minimal entrypoint

All scripts maintain backward compatibility while providing enhanced logging capabilities.

# OpenCode Agents Development Guide

## Build & Test Commands
- **Build container**: `./scripts/build.sh --api-key "your-key"`
- **Deploy container**: `docker-compose up -d`
- **Health check**: `docker-compose exec opencode /usr/local/bin/healthcheck.sh`
- **Container logs**: `docker-compose logs -f opencode`
- **Verify setup**: `./scripts/verify.sh`

## Code Style Guidelines
- **Shell scripts**: Use bash, include error handling with `set -e`, use functions, add logging with colors
- **Dockerfiles**: Multi-stage builds, Ubuntu 22.04 base, Node.js 20+, proper cleanup with `rm -rf /var/lib/apt/lists/*`
- **YAML/Docker Compose**: Use proper indentation (2 spaces), include health checks, resource limits, security options
- **Environment variables**: Use `.env` file, validate required vars, secure with `chmod 600`
- **Naming**: kebab-case for containers (`horizon-opencode`), snake_case for scripts, descriptive function names

## Error Handling
- Use `set -e` in all shell scripts for immediate exit on errors
- Include proper error messages with color coding (`error()`, `warning()`, `success()` functions)
- Validate prerequisites before execution (Docker, API keys, file paths)
- Implement graceful shutdown handlers with `trap` for SIGTERM/SIGINT

## Security
- Never log or expose API keys, tokens, or sensitive configuration
- Use environment variable substitution for secrets
- Set proper file permissions (600 for .env files)
- Run containers with security options: `no-new-privileges:true`
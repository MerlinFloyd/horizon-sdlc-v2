# OpenCode Container Setup Guide

This guide provides comprehensive instructions for building, running, and verifying the OpenCode container environment with all required MCP servers.

## Overview

The OpenCode container includes:
- OpenCode AI development assistant
- 5 pre-installed MCP servers (Context7, GitHub MCP, Playwright, ShadCN UI, Sequential Thinking)
- Proper workspace and AI assets mounting
- Environment variable configuration for authentication
- Health monitoring and verification tools

## Prerequisites

### System Requirements
- Docker 20.10+ with Docker Compose
- 4GB+ available RAM
- 10GB+ available disk space
- Internet connection for image building and MCP server installation

### Required Authentication
- **OPENROUTER_API_KEY** (required)
- **GITHUB_TOKEN** (optional, for GitHub MCP functionality)

## Quick Start

### 1. Build and Deploy

```bash
# Basic setup with API key
./scripts/build.sh --api-key "your-openrouter-api-key"

# With GitHub integration
./scripts/build.sh --api-key "your-api-key" --github-token "your-github-token"
```

### 2. Verify Installation

```bash
# Run comprehensive verification
./scripts/verify.sh

# Check container status
docker-compose ps

# View logs
docker-compose logs -f opencode
```

## Detailed Setup Instructions

### Step 1: Environment Preparation

1. **Clone the repository** (if not already done):
   ```bash
   git clone <repository-url>
   cd horizon-sdlc-v2
   ```

2. **Set up environment variables** (optional):
   ```bash
   export ANTHROPIC_API_KEY="your-api-key"
   export GITHUB_TOKEN="your-github-token"
   ```

3. **Create required directories**:
   ```bash
   mkdir -p .opencode .ai/config .ai/templates .ai/prompts .ai/standards
   ```

### Step 2: Build Configuration

The build script accepts the following options:

| Option | Description | Required |
|--------|-------------|----------|
| `-k, --api-key` | ANTHROPIC_API_KEY for AI provider | Yes |
| `-g, --github-token` | GitHub token for MCP integration | No |
| `-t, --tag` | Docker image tag (default: latest) | No |
| `-n, --no-cache` | Build without Docker cache | No |
| `-p, --push` | Push image to registry after build | No |
| `-r, --registry` | Docker registry URL for push | No |

### Step 3: Container Deployment

The build script automatically:
1. Validates prerequisites (Docker, Docker Compose)
2. Creates necessary directory structure
3. Builds the OpenCode Docker image
4. Creates environment configuration file
5. Deploys the container with proper volume mounts
6. Waits for container health check to pass

### Step 4: Verification

Run the verification script to ensure everything is working:

```bash
./scripts/verify.sh
```

The verification script tests:
- Container status and health
- OpenCode installation and configuration
- All 5 MCP servers functionality
- Workspace and AI assets mounting
- Environment variables configuration
- Virtual display for headless operations
- Basic OpenCode functionality

## Container Architecture

### Volume Mounts

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| `.` | `/workspace` | Project workspace |
| `./.opencode` | `/.opencode` | OpenCode data and configuration |
| `./.ai` | `/.ai` | AI assets (templates, prompts, standards) |

### Environment Variables

| Variable | Purpose | Required |
|----------|---------|----------|
| `OPENROUTER_API_KEY` | AI provider authentication | Yes |
| `GITHUB_TOKEN` | GitHub MCP server access | No |
| `NODE_ENV` | Node.js environment | Auto-set |

### MCP Servers Configuration

| Server | Command | Purpose |
|--------|---------|---------|
| Context7 | `context7-mcp-server` | Documentation retrieval |
| GitHub MCP | `github-mcp-server` | Repository management |
| Playwright | `playwright-mcp-server` | Browser automation |
| ShadCN UI | `shadcn-ui-mcp-server` | UI component generation |
| Sequential Thinking | `sequential-thinking-mcp-server` | Problem-solving workflows |

## Usage Examples

### Basic OpenCode Usage

```bash
# Access OpenCode shell
docker-compose exec opencode bash

# Run OpenCode directly
docker-compose exec opencode opencode

# Run OpenCode with specific command
docker-compose exec opencode opencode "Analyze the current project structure"
```

### Container Management

```bash
# Start container
docker-compose up -d

# Stop container
docker-compose down

# Restart container
docker-compose restart opencode

# View logs
docker-compose logs -f opencode

# Check container status
docker-compose ps
```

### Health Monitoring

```bash
# Run health check
docker-compose exec opencode /usr/local/bin/healthcheck.sh

# Check individual MCP servers
docker-compose exec opencode context7-mcp-server --version
docker-compose exec opencode github-mcp-server --version
```

## Troubleshooting

### Common Issues

1. **Container fails to start**
   ```bash
   # Check logs
   docker-compose logs opencode
   
   # Verify environment variables
   cat .env
   
   # Rebuild container
   docker-compose down
   docker-compose up -d --build
   ```

2. **MCP servers not responding**
   ```bash
   # Check MCP server status
   docker-compose exec opencode ps aux | grep mcp
   
   # Test individual servers
   docker-compose exec opencode timeout 10 context7-mcp-server --version
   ```

3. **Workspace mounting issues**
   ```bash
   # Verify mount points
   docker-compose exec opencode ls -la /workspace
   docker-compose exec opencode ls -la /.ai
   
   # Check permissions
   docker-compose exec opencode id
   ```

4. **API key issues**
   ```bash
   # Verify environment variables in container
   docker-compose exec opencode printenv | grep API_KEY
   
   # Check configuration file
   docker-compose exec opencode cat /.opencode/opencode.json
   ```

### Performance Optimization

1. **Resource allocation**: Adjust memory and CPU limits in `docker-compose.yml`
2. **MCP server timeout**: Modify timeout values in OpenCode configuration
3. **Container restart policy**: Configure restart behavior for production use

### Security Considerations

1. **API key protection**: Never commit API keys to version control
2. **Container isolation**: Run container with appropriate security options
3. **Network access**: Limit container network access if needed
4. **File permissions**: Ensure proper file permissions for mounted volumes

## Advanced Configuration

### Custom OpenCode Configuration

Modify `docker/opencode/config/opencode.json.template` to customize:
- AI model selection
- MCP server configurations
- Agent mode definitions
- Security settings

### Custom MCP Server Installation

Add new MCP servers by:
1. Modifying the Dockerfile to install the server
2. Adding configuration to `opencode.json.template`
3. Updating the health check script

### Production Deployment

For production use:
1. Use specific image tags instead of `latest`
2. Configure proper logging and monitoring
3. Set up container orchestration (Kubernetes, Docker Swarm)
4. Implement backup strategies for persistent data

## Support and Maintenance

### Regular Maintenance

1. **Update base images**: Rebuild container with latest base images
2. **Update MCP servers**: Check for MCP server updates
3. **Monitor logs**: Regular log review for issues
4. **Health checks**: Automated health monitoring

### Getting Help

1. Check container logs: `docker-compose logs opencode`
2. Run verification script: `./scripts/verify.sh`
3. Review this documentation
4. Check OpenCode and MCP server documentation

This setup provides a complete OpenCode development environment ready for use with the Horizon SDLC project.

# OpenCode Container Setup - Quick Start Guide

This guide helps you quickly set up the OpenCode development environment with all required MCP servers for the Horizon SDLC project.

## 🚀 Quick Start

### Prerequisites
- Docker 20.10+ with Docker Compose
- 4GB+ RAM available
- OPENROUTER_API_KEY (required)
- GITHUB_TOKEN (optional, for GitHub integration)

### 1. Build and Deploy (One Command)

```bash
./scripts/build.sh --api-key "your-openrouter-api-key"
```

**With GitHub Integration:**
```bash
./scripts/build.sh --api-key "your-api-key" --github-token "your-github-token"
```

**Advanced Build Options:**
```bash
# Build without cache
./scripts/build.sh --api-key "your-key" --no-cache

# Build and push to registry
./scripts/build.sh --api-key "your-key" --push --registry "your-registry.com"

# Custom image tag
./scripts/build.sh --api-key "your-key" --tag "v1.0.0"
```

### 2. Verify Installation
```bash
./scripts/verify.sh
```

### 3. Start Using OpenCode
```bash
# Access OpenCode
docker-compose exec opencode opencode

# Or run specific commands
docker-compose exec opencode opencode "Analyze the current project structure"
```

## 📋 What Gets Installed

### OpenCode Container Includes:
- ✅ OpenCode AI development assistant
- ✅ Context7 MCP server (remote documentation retrieval)
- ✅ GitHub MCP server (remote repository management)
- ✅ Playwright MCP server (local browser automation)
- ✅ ShadCN UI MCP server (local UI component generation)
- ✅ Sequential Thinking MCP server (local problem-solving workflows)
- ✅ Proper workspace mounting
- ✅ Environment variable configuration
- ✅ Security hardening and resource limits

### Directory Structure Created:
```
.opencode/                 # OpenCode data and configuration
├── opencode.json         # Main configuration file
├── commands/             # Custom commands
└── themes/               # Custom themes

.ai/                      # AI assets (user-modifiable)
├── config/
│   ├── auth.json        # Authentication (gitignored)
│   └── mcp-servers.json # MCP server configs
├── templates/           # Project templates
├── prompts/             # Workflow prompts
└── standards/           # Coding standards

.env                     # Environment variables (gitignored)
```

## 🔧 Container Management

### Basic Commands
```bash
# Start container
docker-compose up -d

# Stop container
docker-compose down

# View container status
docker-compose ps

# View container logs
docker-compose logs -f opencode

# Restart container
docker-compose restart opencode

# Restart container
docker-compose restart opencode

# View logs
docker-compose logs -f opencode

# Check status
docker-compose ps

# Run health check
docker-compose exec opencode /usr/local/bin/healthcheck.sh
```

### OpenCode Usage
```bash
# Interactive shell
docker-compose exec opencode bash

# Direct OpenCode access
docker-compose exec opencode opencode

# Run specific OpenCode commands
docker-compose exec opencode opencode "Create a TypeScript project structure"
```

## 🔍 Verification and Testing

The verification script tests:
- ✅ Container health and status
- ✅ OpenCode installation and configuration
- ✅ All 5 MCP servers functionality
- ✅ Workspace and AI assets mounting
- ✅ Environment variables

```bash
# Run comprehensive verification
./scripts/verify.sh

# Expected output:
# ✓ Container is running
# ✓ Container is healthy
# ✓ OpenCode is installed
# ✓ OpenCode configuration is valid
# ✓ MCP Server: Context7 is installed as npm package (remote)
# ✓ MCP Server: GitHub MCP is installed as npm package (remote)
# ✓ MCP Server: Playwright is responding (local)
# ✓ MCP Server: ShadCN UI is responding (local)
# ✓ MCP Server: Sequential Thinking is responding (local)
# ✓ Workspace is properly mounted
# ✓ Environment variables are configured
# ✓ Internal health check passed

# ✓ OpenCode basic functionality works
# ✓ All tests passed! OpenCode container is fully functional.
```

## 🛠️ Troubleshooting

### Common Issues

**Container won't start:**
```bash
# Check logs
docker-compose logs opencode

# Verify environment
cat .env

# Rebuild
docker-compose down && docker-compose up -d --build
```

**MCP servers not responding:**
```bash
# Test local MCP servers
docker-compose exec opencode npx @playwright/mcp --version
docker-compose exec opencode npx @modelcontextprotocol/server-sequential-thinking --version
docker-compose exec opencode npx @jpisnice/shadcn-ui-mcp-server --version

# Check remote MCP server configuration
docker-compose exec opencode cat /root/.config/opencode/opencode.json | grep -A 10 "mcp"
```

**API key issues:**
```bash
# Check environment in container
docker-compose exec opencode printenv | grep OPENROUTER_API_KEY

# Verify configuration
docker-compose exec opencode cat /root/.config/opencode/opencode.json
```

## 📚 Next Steps

1. **Explore OpenCode capabilities**: Try different commands and workflows
2. **Customize AI assets**: Modify templates and prompts in `.ai/` directory
3. **Integrate with your workflow**: Use OpenCode for development tasks
4. **Review documentation**: Check `docs/opencode-container-setup.md` for detailed information

## 🔐 Security Notes

- API keys are stored in environment variables and `.env` file (gitignored)
- Container runs with appropriate security restrictions
- Sensitive files are automatically excluded from version control
- MCP servers operate with minimal required permissions

## 🔄 GitHub Actions Integration

The project includes GitHub Actions workflow for OpenCode integration:

### Setup GitHub Actions
1. **Add Repository Secrets**:
   - `OPENROUTER_API_KEY`: Your OpenRouter API key for OpenCode

2. **Trigger OpenCode**:
   - Comment `/oc` or `/opencode` on any issue
   - GitHub Actions will run OpenCode with Claude Sonnet 4

### Workflow Configuration
- **File**: `.github/workflows/opencode.yml`
- **Trigger**: Issue comments containing `/oc` or `/opencode`
- **Model**: `anthropic/claude-sonnet-4`
- **Provider**: OpenRouter (via `OPENROUTER_API_KEY`)
- **Permissions**: `id-token: write` for secure authentication

## 📖 Additional Resources

- **Detailed Setup Guide**: `docs/opencode-container-setup.md`
- **Container Architecture**: See Docker Compose configuration
- **OpenCode Configuration**: `docker/opencode/config/opencode.json.template`
- **Build Scripts**: `scripts/build.sh`
- **Verification Script**: `scripts/verify.sh`
- **GitHub Actions**: `.github/workflows/opencode.yml`

## 🆘 Getting Help

If you encounter issues:
1. Run the verification script: `./scripts/verify.sh`
2. Check container logs: `docker-compose logs opencode`
3. Review the troubleshooting section in the detailed documentation
4. Ensure all prerequisites are met

---

**Ready to start developing with OpenCode!** 🎉

The container provides a complete AI-assisted development environment with all the tools you need for the Horizon SDLC project.

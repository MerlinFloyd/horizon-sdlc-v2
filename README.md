# Horizon SDLC v2

A TypeScript-based project bootstrapping tool that automates one-time project setup and deploys OpenCode AI development assistance in a containerized environment for ongoing development support.

## 🎯 Project Overview

### Vision Statement
Build a TypeScript-based project bootstrapping tool that automates one-time project setup and deploys OpenCode AI development assistance in a containerized environment for ongoing development support, distributed as a Docker container for universal deployment across repositories.

### Core Objectives
- **Automation**: Eliminate manual project setup overhead through one-time bootstrapping
- **AI Integration**: Deploy OpenCode AI assistance infrastructure for ongoing development support
- **Portability**: Docker-based distribution for universal deployment
- **Clean Handoff**: Seamless transition from bootstrap setup to OpenCode-managed development

## 🚀 Quick Start

### Prerequisites
- Docker 20.10+ with Docker Compose
- 4GB+ RAM available
- OPENROUTER_API_KEY (required)
- GITHUB_TOKEN (optional, for GitHub integration)

### One-Command Setup
```bash
./scripts/build.sh --api-key "your-openrouter-api-key"
```

### Verify Installation
```bash
./scripts/verify.sh
```

### Start Using OpenCode
```bash
# Access OpenCode
docker-compose exec opencode opencode

# Or run specific commands
docker-compose exec opencode opencode "Analyze the current project structure"
```

## 📋 What's Included

### OpenCode Container Features
- ✅ OpenCode AI development assistant with Claude Sonnet 4
- ✅ Context7 MCP server (remote documentation retrieval)
- ✅ GitHub MCP server (remote repository management)
- ✅ Playwright MCP server (local browser automation)
- ✅ ShadCN UI MCP server (local UI component generation)
- ✅ Sequential Thinking MCP server (local problem-solving workflows)
- ✅ Proper workspace mounting and environment configuration
- ✅ Security hardening and resource limits

### Workflow Modes
- **PRD Mode**: Technical documentation and requirements gathering
- **Architect Mode**: Technical Architect for system design and architecture decisions
- **Feature Breakdown Mode**: Feature analysis and component breakdown
- **USP Mode**: Implementation and development for user stories and features

## 🏗️ Architecture

### Container Structure
```
horizon-opencode/                 # Main OpenCode container
├── OpenCode AI Assistant         # Core AI development assistant
├── MCP Servers/                  # Model Context Protocol servers
│   ├── Context7 (remote)         # Documentation retrieval
│   ├── GitHub (remote)           # Repository management
│   ├── Playwright (local)        # Browser automation
│   ├── ShadCN UI (local)         # UI component generation
│   └── Sequential Thinking (local) # Problem-solving workflows
└── Configuration/
    ├── opencode.json             # Main OpenCode configuration
    ├── AGENTS.md                 # Global agent standards
    └── Workflow prompts         # Mode-specific prompts
```

### Directory Structure
```
.opencode/                        # OpenCode data and configuration
├── opencode.json                # Main configuration file
├── commands/                    # Custom commands
└── themes/                      # Custom themes

.ai/                             # AI assets (user-modifiable)
├── config/
│   ├── auth.json               # Authentication (gitignored)
│   └── mcp-servers.json        # MCP server configs
├── templates/                  # Project templates
├── prompts/                    # Workflow prompts
└── standards/                  # Coding standards

.env                            # Environment variables (gitignored)
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

# Run health check
docker-compose exec opencode /usr/local/bin/healthcheck.sh
```

### Advanced Build Options
```bash
# Build without cache
./scripts/build.sh --api-key "your-key" --no-cache

# Build and push to registry
./scripts/build.sh --api-key "your-key" --push --registry "your-registry.com"

# Custom image tag
./scripts/build.sh --api-key "your-key" --tag "v1.0.0"
```

## 🔄 GitHub Actions Integration

### Setup
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

## 🛠️ Development

### Project Structure
- **Source Code**: `src/` - Bootstrapper implementation logic
- **Assets**: `assets/` - Deployable templates and standards
- **Tests**: `tests/` - Comprehensive testing at all levels
- **Scripts**: `scripts/` - Build, deployment, and utility automation
- **Docker**: `docker/` - Container configuration and deployment
- **Documentation**: `docs/` - Detailed project documentation

### Key Technologies
- **TypeScript**: Primary development language
- **Docker**: Containerization and deployment
- **OpenCode**: AI development assistant
- **MCP (Model Context Protocol)**: AI server integration
- **GitHub Actions**: CI/CD and automation

## 📖 Documentation

- **[Quick Setup Guide](README-OPENCODE-SETUP.md)**: Fast setup instructions
- **[Detailed Setup Guide](docs/opencode-container-setup.md)**: Comprehensive setup documentation
- **[Requirements](docs/requirements.md)**: Project requirements and specifications
- **[Repository Structure](docs/repository-structure.md)**: Detailed project structure
- **[Standards Integration](docs/standards-templates-integration.md)**: Standards and templates documentation

## 🔐 Security

- API keys stored in environment variables and `.env` file (gitignored)
- Container runs with security restrictions (`no-new-privileges:true`)
- Sensitive files automatically excluded from version control
- MCP servers operate with minimal required permissions
- Resource limits and logging configuration for production use

## 🆘 Getting Help

If you encounter issues:
1. Run the verification script: `./scripts/verify.sh`
2. Check container logs: `docker-compose logs opencode`
3. Review the troubleshooting section in the detailed documentation
4. Ensure all prerequisites are met

## 📄 License

This project is part of the Horizon SDLC ecosystem for automated development workflows.

---

**Ready to start developing with AI assistance!** 🎉

The container provides a complete AI-assisted development environment with all the tools you need for modern software development.

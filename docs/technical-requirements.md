# Technical Requirements Document
## Horizon SDLC v2 Bootstrapping Application

### 1. Executive Summary

This document defines the technical specifications for the Horizon SDLC v2 bootstrapping application - a TypeScript-based CLI tool that automates project setup and deploys OpenCode AI development assistance in containerized environments.

**Key Components:**
- **Bootstrapper**: Temporary CLI tool for one-time project setup
- **OpenCode Container**: Persistent AI development assistance with MCP servers
- **Asset Management**: User-modifiable templates, standards, and configurations
- **GitHub Integration**: CI/CD workflows and container registry deployment

### 2. System Architecture

#### 2.1 High-Level Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                    Host System                             │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐       ┌─────────────────────────────────┐ │
│  │   Bootstrapper  │─────▶│         OpenCode Container      │ │
│  │   (Temporary)   │       │                                 │ │
│  └─────────────────┘       │  ┌─────────────────────────────┐ │ │
│                            │  │      MCP Servers            │ │ │
│  ┌─────────────────┐       │  │  • Context7                 │ │ │
│  │    Project      │◀─────┼──│  • GitHub MCP               │ │ │
│  │   Workspace     │       │  │  • Playwright               │ │ │
│  │   ├── .ai       │◀─────┼──│  • ShadCN UI                │ │ │
│  │   ├── .opencode │       │  │  • Sequential Thinking      │ │ │
│  │   └── src/      │       │  └─────────────────────────────┘ │ │
│  └─────────────────┘       └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

#### 2.2 Component Relationships
- **Bootstrapper** → **Project Workspace**: Generates project structure and configuration files
- **Bootstrapper** → **OpenCode Container**: Deploys and configures AI assistance
- **Project Workspace** → **OpenCode Container**: Volume mounts for real-time access
- **GitHub Actions** → **OpenCode Container**: CI/CD integration for automated workflows

### 3. Technical Specifications

#### 3.1 Core Technology Stack
- **Runtime**: Node.js 20+
- **Language**: TypeScript 5.x
- **CLI Framework**: Commander.js for command parsing, Inquirer.js for interactive wizard
- **Template Engine**: Mustache/Handlebars for file generation
- **File Operations**: fs-extra for enhanced file system operations
- **Container Management**: Docker SDK for container orchestration
- **Testing**: Jest for unit and integration testing
- **Build System**: TypeScript compiler with custom build scripts

#### 3.2 Data Models and Interfaces

```typescript
// Core configuration interfaces
interface ProjectConfig {
  name: string;
  languages: SupportedLanguage[];
  frameworks: string[];
  features: ProjectFeature[];
  opencode: OpenCodeConfig;
}

interface OpenCodeConfig {
  provider: 'openrouter';
  model: 'anthropic/claude-sonnet-4-20250514';
  apiKey: string; // Environment variable reference
  mcpServers: MCPServerConfig[];
  agentModes: AgentModeConfig;
  dataDirectory: string;
}

interface MCPServerConfig {
  name: string;
  type: 'local';
  command: string[];
  enabled: boolean;
  environment?: Record<string, string>;
}

enum SupportedLanguage {
  TYPESCRIPT = 'typescript',
  GO = 'go',
  PYTHON = 'python',
  JAVA = 'java'
}

enum ProjectFeature {
  TESTING = 'testing',
  LINTING = 'linting',
  CI_CD = 'ci-cd',
  DOCKER = 'docker',
  DOCUMENTATION = 'documentation'
}
```

### 4. Implementation Details

#### 4.1 CLI Interface Specification

**Command Structure:**
```bash
# Interactive setup wizard
horizon-bootstrap init

# Batch mode with configuration file
horizon-bootstrap init --config bootstrap.json

# Add language to existing project
horizon-bootstrap add --language typescript

# Update templates and standards
horizon-bootstrap update

# Deploy OpenCode container
horizon-bootstrap deploy-opencode --api-key <key>
```

**Interactive Wizard Flow:**
1. Project name and description input
2. Multi-select language/framework selection
3. Feature selection (testing, CI/CD, etc.)
4. OpenCode configuration options
5. GitHub integration setup
6. Confirmation and execution

#### 4.2 File Generation System

**Template Processing Pipeline:**
1. **Template Selection**: Based on language and feature selections
2. **Variable Substitution**: Project-specific values and configurations
3. **File Generation**: Create project structure with populated templates
4. **Asset Deployment**: Copy standards, prompts, and configurations to .ai directory
5. **Validation**: Verify generated files and configurations

**Generated File Examples:**

**TypeScript Project Structure:**
```
project-name/
├── src/
│   ├── index.ts
│   ├── types/
│   └── utils/
├── tests/
├── .ai/
│   ├── templates/typescript/
│   ├── standards/typescript/
│   └── prompts/workflow/
├── .opencode/
│   └── opencode.json
├── .github/workflows/
│   └── opencode.yml
├── package.json
├── tsconfig.json
├── .eslintrc.json
└── .gitignore
```

#### 4.3 OpenCode Configuration Generation

**opencode.json Template:**
```json
{
  "provider": "openrouter",
  "model": "anthropic/claude-sonnet-4-20250514",
  "apiKey": "{env:OPENROUTER_API_KEY}",
  "dataDirectory": ".opencode",
  "mcpServers": {
    "context7": {
      "type": "local",
      "command": ["context7-mcp-server"],
      "enabled": true
    },
    "github": {
      "type": "local",
      "command": ["github-mcp-server"],
      "enabled": true,
      "env": {
        "GITHUB_TOKEN": "{env:GITHUB_TOKEN}"
      }
    },
    "playwright": {
      "type": "local",
      "command": ["playwright-mcp-server"],
      "enabled": true
    },
    "shadcn-ui": {
      "type": "local",
      "command": ["shadcn-ui-mcp-server"],
      "enabled": true
    },
    "sequential-thinking": {
      "type": "local",
      "command": ["sequential-thinking-mcp-server"],
      "enabled": true
    }
  },
  "agentModes": {
    "prd": {
      "name": "Technical Product Owner",
      "description": "Requirements gathering and PRD creation",
      "tools": ["read", "analyze", "document"]
    },
    "architecture": {
      "name": "System Architect", 
      "description": "Technical specifications and system design",
      "tools": ["design", "analyze", "document"]
    },
    "breakdown": {
      "name": "Feature Developer",
      "description": "Feature decomposition and implementation planning",
      "tools": ["read", "write", "analyze", "test"]
    },
    "usp": {
      "name": "Implementation Agent",
      "description": "User story implementation and code generation",
      "tools": ["read", "write", "test", "debug"]
    }
  }
}
```

### 5. Container Integration

#### 5.1 Docker Deployment Strategy

**Volume Mounting Configuration:**
```bash
docker run -d \
  --name opencode-${PROJECT_NAME} \
  -v ${PROJECT_ROOT}:/workspace \
  -v ${PROJECT_ROOT}/.opencode:/.opencode \
  -v ${PROJECT_ROOT}/.ai:/.ai \
  -e OPENROUTER_API_KEY=${OPENROUTER_API_KEY} \
  -e GITHUB_TOKEN=${GITHUB_TOKEN} \
  opencode:latest
```

**Container Health Checks:**
- OpenCode service responsiveness
- MCP server connectivity
- Volume mount accessibility
- Environment variable availability

#### 5.2 Asset Management System

**.ai Directory Structure:**
```
.ai/
├── config/
│   ├── auth.json              # API keys (gitignored)
│   └── mcp-servers.json       # MCP server configurations
├── templates/
│   ├── typescript/
│   │   ├── project.json       # Project template metadata
│   │   ├── files/             # Template files
│   │   └── scripts/           # Setup scripts
│   ├── go/
│   ├── python/
│   └── java/
├── prompts/
│   ├── workflow/
│   │   ├── prd.json          # PRD generation prompts
│   │   ├── architecture.json  # Architecture design prompts
│   │   └── implementation.json # Implementation prompts
│   ├── coding-standards/
│   └── agent-modes/
└── standards/
    ├── architectural/
    │   ├── clean-architecture.json
    │   ├── ddd-patterns.json
    │   └── api-design.json
    ├── testing/
    │   ├── unit-testing.json
    │   ├── integration-testing.json
    │   └── e2e-testing.json
    └── documentation/
        ├── api-docs.json
        ├── readme-template.json
        └── code-comments.json
```

### 6. GitHub Integration

#### 6.1 GitHub Actions Workflow

**Required .github/workflows/opencode.yml:**
```yaml
name: opencode

on:
  issue_comment:
    types: [created]

jobs:
  opencode:
    if: |
      contains(github.event.comment.body, '/oc') ||
      contains(github.event.comment.body, '/opencode')
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
      pull-requests: write
      issues: write
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 1

      - name: Run opencode
        uses: sst/opencode/github@latest
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        with:
          model: anthropic/claude-sonnet-4-20250514
```

#### 6.2 Container Registry Integration

**Build and Push Workflow:**
```yaml
name: Build and Push Container

on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build and push
        run: |
          docker build -t ghcr.io/${{ github.repository }}:${{ github.ref_name }} .
          docker push ghcr.io/${{ github.repository }}:${{ github.ref_name }}
```

### 7. Security and Secrets Management

#### 7.1 Environment Variable Strategy

**Secret Handling:**
- **Build Time**: API keys passed as command-line arguments to build scripts
- **Runtime**: Environment variable substitution using {env:VARIABLE_NAME} pattern
- **GitHub Actions**: Secrets stored in repository settings
- **Local Development**: .env files (gitignored) or direct environment variables

**Required Secrets:**
- `OPENROUTER_API_KEY`: AI provider authentication
- `ANTHROPIC_API_KEY`: Alternative AI provider (for GitHub Actions)
- `GITHUB_TOKEN`: Automatically provided by GitHub Actions

#### 7.2 Security Best Practices

**Container Security:**
- Non-root user execution
- Read-only file systems where possible
- Resource limits and constraints
- Regular security scanning

**Secret Protection:**
- No secrets in container images
- Environment variable substitution
- Secure secret injection
- Audit logging for secret access

### 8. Validation and Testing Strategy

#### 8.1 Validation Checkpoints

**Phase 1 - Foundation Validation:**
- CLI framework functional
- Basic file operations working
- Template engine operational

**Phase 2 - Asset Validation:**
- Templates generate valid projects
- JSON schemas validate correctly
- Standards and prompts well-formed

**Phase 3 - Integration Validation:**
- OpenCode container deploys successfully
- MCP servers respond correctly
- Volume mounts accessible
- Environment variables substituted

**Phase 4 - End-to-End Validation:**
- Complete bootstrap process functional
- GitHub Actions workflows trigger
- Container registry deployment successful
- Cross-platform compatibility verified

#### 8.2 Testing Framework

**Unit Tests:**
- Template processing logic
- Configuration generation
- File system operations
- CLI command parsing

**Integration Tests:**
- Complete project generation
- OpenCode container deployment
- Asset deployment and mounting
- GitHub workflow execution

**End-to-End Tests:**
- Full bootstrap process
- Multi-language project setup
- Iterative setup scenarios
- Error handling and recovery

### 9. Performance Requirements

#### 9.1 Performance Targets

- **Bootstrap Time**: Complete project setup in under 5 minutes
- **Container Startup**: OpenCode container operational within 2 minutes
- **Asset Deployment**: Template and standard deployment under 30 seconds
- **Memory Usage**: Bootstrapper under 512MB, OpenCode container under 2GB
- **Disk Usage**: Generated projects under 100MB (excluding dependencies)

#### 9.2 Optimization Strategies

- **Parallel Processing**: Concurrent template generation and asset deployment
- **Caching**: Template and dependency caching for repeated operations
- **Incremental Updates**: Only update changed assets during iterative setup
- **Resource Management**: Efficient memory usage and cleanup

### 10. Error Handling and Recovery

#### 10.1 Error Categories

**Setup Errors:**
- Invalid project configuration
- Missing dependencies or prerequisites
- File system permission issues
- Network connectivity problems

**Deployment Errors:**
- Container deployment failures
- Volume mounting issues
- Environment variable problems
- MCP server connectivity failures

**Integration Errors:**
- GitHub Actions configuration issues
- Secret management problems
- Container registry access failures
- Asset deployment conflicts

#### 10.2 Recovery Mechanisms

**Rollback Capabilities:**
- Restore previous project state
- Clean up partial deployments
- Remove failed container instances
- Reset configuration to known good state

**Retry Logic:**
- Automatic retry for transient failures
- Exponential backoff for network operations
- User-prompted retry for manual intervention
- Graceful degradation for non-critical failures

**Diagnostic Tools:**
- Detailed logging with configurable levels
- Health check utilities for all components
- Configuration validation tools
- Troubleshooting guides and error resolution

This technical requirements document provides the foundation for implementing the Horizon SDLC v2 bootstrapping application with clear specifications, concrete examples, and comprehensive validation criteria.

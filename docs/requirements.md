# AI Project Bootstrap Tool - Requirements Document

## 1. Project Overview

### 1.1 Vision Statement
Build a TypeScript-based project bootstrapping tool that automates one-time project setup and deploys OpenCode AI development assistance in a containerized environment for ongoing development support, distributed as a Docker container for universal deployment across repositories.

### 1.2 Core Objectives
- **Automation**: Eliminate manual project setup overhead through one-time bootstrapping
- **AI Integration**: Deploy OpenCode AI assistance infrastructure for ongoing development support
- **Portability**: Docker-based distribution for universal deployment
- **Clean Handoff**: Seamless transition from bootstrap setup to OpenCode-managed development

### 1.3 Architectural Inspiration
Based on https://github.com/SuperClaude-Org/SuperClaude_Framework architecture and functional patterns.
Inspiration also from:
- https://github.com/Jedward23/Tmux-Orchestrator
- https://github.com/All-Hands-AI/OpenHands
- https://github.com/buildermethods/agent-os

### 1.4 Repository Purpose
This repository serves as the foundation for our AI Project Bootstrap Tool and contains standardized configurations, templates, and agent definitions that will be used to bootstrap new projects across multiple languages and use cases. The bootstrapper performs one-time project setup and deploys these assets to OpenCode for ongoing development assistance.

### 1.5 Scope Boundaries
- **Bootstrapper Scope**: Initial and iterative project setup, configuration generation, OpenCode container deployment, workspace asset management
- **OpenCode Scope**: Ongoing development assistance, code generation, workflow management, continuous project support
- **Shared Assets**: Templates, standards, configurations, and prompts deployed in `.ai` workspace directory and mounted into OpenCode container for ongoing use and modification

## 2. Repository Structure Requirements

### 2.1 Core Components
This repository must contain:
- [ ] **Language-specific baseline setups** - Complete project templates and configurations for TypeScript, Go, Python, and Java
- [ ] **Architectural standards documentation** - Detailed guidelines and templates that enforce our opinionated development workflow (JSON format for AI agent consumption)
- [ ] **OpenCode AI agent mode definitions** - Specialized agent personas with distinct responsibilities throughout the SDLC (JSON configuration files)
- [ ] **Coding standards libraries** - Language-specific rules and examples that agents will reference (JSON format with structured examples)
- [ ] **Structured workflow prompts** - Pre-configured prompt templates that guide users through our standardized development process (JSON templates)

### 2.2 Supported Languages
- [ ] **TypeScript** - Complete project templates and coding standards (JSON format)
- [ ] **Go** - Idiomatic Go project structure and standards (JSON format)
- [ ] **Python** - Python best practices and project organization (JSON format)
- [ ] **Java** - Enterprise Java patterns and configurations (JSON format)

## 3. Architectural Standards (Applied to All Languages)

### 3.1 Core Principles
- [ ] **Clean Architecture** - Layered architecture with clear boundaries
- [ ] **Don't Repeat Yourself (DRY)** - Code reusability and maintainability
- [ ] **Separation of Concerns** - Single responsibility and modular design
- [ ] **OpenAPI Standards** - API-first design and documentation
- [ ] **Structured Logging** - OpenTelemetry-compliant logging libraries
- [ ] **Repository Pattern** - Standardized data store interactions
- [ ] **Domain Driven Design (DDD)** - Business domain modeling
- [ ] **Nx Monorepo Management** - Scalable project organization

### 3.2 Implementation Requirements
- [ ] Document architectural patterns with examples for each language (JSON schema format)
- [ ] Create template implementations demonstrating each principle (JSON configuration with code examples)
- [ ] Establish validation rules for architectural compliance (JSON schema validation)
- [ ] Provide refactoring guidelines for legacy code alignment (JSON-structured guidelines)

## 4. OpenCode AI Agent Modes

### 4.1 Agent Mode Definitions
Each mode has specific responsibilities and operates at different SDLC phases:

- [ ] **Technical Product Owner** - Requirements gathering and PRD creation
- [ ] **Architect** - Technical specifications and system design
- [ ] **Frontend Developer** - UI/UX implementation
- [ ] **Backend Developer** - API and business logic implementation
- [ ] **Analyzer/Debugger** - Code analysis and issue resolution
- [ ] **Security Expert** - Security review and vulnerability assessment
- [ ] **Technical Writer** - Technical documentation creation
- [ ] **Product Document Writer** - User-facing documentation
- [ ] **QA Engineer** - Testing strategy and implementation
- [ ] **DevOps Engineer** - CI/CD and infrastructure
- [ ] **Refactorer** - Code improvement and optimization

### 4.2 Agent Configuration Requirements
Establish uniform global rules for all OpenCode agents:
- [ ] **MCP Server Integration** - Pre-installed in OpenCode container:
  - Context7 - Documentation retrieval and context management for libraries and frameworks
  - Playwright - Browser automation and testing
  - ShadCN UI MCP (https://github.com/Jpisnice/shadcn-ui-mcp-server) - UI component generation
  - Sequential Thinking - Structured problem-solving workflows
  - GitHub MCP - Repository management and GitHub API integration
- [ ] **Context7 Configuration** - Context7 MCP server configured for:
  - Library documentation retrieval from various sources
  - Real-time code documentation for project-specific libraries
  - Support for both public and private library documentation
- [ ] **GitHub MCP Configuration** - GitHub MCP server configured for:
  - Repository access and file operations
  - Issue and pull request management
  - GitHub API integration for project-specific repository operations
  - Support for both public and private repository access
- [ ] **Context Awareness** - Agents must read and incorporate architecture documents, tech-stack documentation and best practices specifications
- [ ] **Consistent Behavior** - All agents follow the same base configuration and operational patterns

## 5. Language-Specific Coding Standards Libraries

### 5.1 Standards Coverage
For each supported language (TypeScript, Go, Python, Java), create comprehensive standards covering:

- [ ] **Inversion of Control** - Dependency injection patterns and examples where applicable
- [ ] **Self-Documenting Code** - Best practices for inline documentation, don't write code comments unnecessarily
- [ ] **Single Responsibility Principle** - Class and function design guidelines
- [ ] **Test Design** - Testing patterns, file organization, and co-location rules
- [ ] **Folder Structure** - Standardized project organization
- [ ] **Linting Guidelines** - Language-specific rules and configurations
- [ ] **Git Rules** - Including pre-commit checks and workflow standards

### 5.2 Implementation Requirements
- [ ] Create practical examples for each standard
- [ ] Provide before/after code samples (JSON structure with comparison examples)
- [ ] Include automated validation tools (JSON schema-based validation)
- [ ] Document exceptions and edge cases (JSON-structured documentation)

## 6. Workflow Template Installation

### 6.1 Development Workflow Templates
Install structured development process templates and configurations for OpenCode usage:

#### Phase 1: Product Requirements Document (PRD) Template
- [ ] **Template Installation**: Install PRD template for OpenCode Product Owner mode
- [ ] **Configuration**: Target languages, frameworks, product requirements, business use cases, user personas
- [ ] **Prompt Templates**: Pre-configured prompts for comprehensive PRD creation

#### Phase 2: Technical Architecture Template
- [ ] **Template Installation**: Install architecture template for OpenCode Architect mode
- [ ] **Configuration**: Enterprise requirements, architectural standards, integration patterns
- [ ] **Prompt Templates**: Pre-configured prompts for technical specification development

#### Phase 3: Feature Breakdown Template
- [ ] **Template Installation**: Install feature decomposition templates for OpenCode
- [ ] **Configuration Templates**:
  - Functional requirements structure
  - Testing requirements framework
  - Logging specifications template
  - CI/CD considerations checklist
  - Observability requirements template
  - Documentation requirements framework
- [ ] **Agent Assignment Templates**: Backend and frontend development role templates

#### Phase 4: User Story Prompt (USP) Template
- [ ] **Template Installation**: Install USP templates for OpenCode implementation agents
- [ ] **Template Components**:
  - Agent role definition templates
  - Implementation goal structures
  - Step-by-step instruction frameworks
  - Language-specific example libraries
  - Compliance rule templates
  - Documentation deliverable templates
- [ ] **Best Practice Templates**: Prompt engineering and test-driven development frameworks

### 6.2 Template Installation Requirements
- [ ] Package standardized prompt templates for OpenCode consumption (JSON format for token efficiency)
- [ ] Include validation checkpoint templates (JSON schema validation)
- [ ] Install handoff procedure templates for agent mode transitions (JSON workflow definitions)
- [ ] Provide escalation path templates for complex decisions (JSON decision trees)

## 7. OpenCode Integration Requirements

### 7.1 OpenCode Configuration Specifications

#### 7.1.1 Environment Variable Configuration
- [ ] **Provider Authentication**: Use environment variable substitution for sensitive data:
  - `{env:OPENROUTER_API_KEY}` for OpenRouter provider authentication
  - `{env:GITHUB_TOKEN}` for GitHub MCP server access
  - Environment variables passed to Docker container during build and runtime
  - Bootstrapper build scripts accept authentication keys as command-line parameters

#### 7.1.2 Provider and Model Configuration
- [ ] **OpenRouter Provider Setup**:
  - Configure provider as "openrouter" in opencode.json
  - Set default model to "anthropic/claude-sonnet-4-20250514" (Claude Sonnet 4)
  - Use environment variable substitution for API key security
  - Configure provider-specific options and fallback settings

#### 7.1.3 MCP Server Configuration
- [ ] **MCP Server Integration** using latest OpenCode MCP configuration format:
  - **Context7 MCP Server**: Documentation retrieval and context management
    - Type: "local", Command: ["context7-mcp-server"], Enabled: true
  - **GitHub MCP Server**: Repository management and GitHub API integration
    - Type: "local", Command: ["github-mcp-server"], Enabled: true
    - Environment: GITHUB_TOKEN from environment variables
  - **Playwright MCP Server**: Browser automation and testing capabilities
    - Type: "local", Command: ["playwright-mcp-server"], Enabled: true
  - **ShadCN UI MCP Server**: UI component generation and management
    - Type: "local", Command: ["shadcn-ui-mcp-server"], Enabled: true
  - **Sequential Thinking MCP Server**: Structured problem-solving workflows
    - Type: "local", Command: ["sequential-thinking-mcp-server"], Enabled: true

#### 7.1.4 Agent Mode Configuration for Workflow Phases
- [ ] **Workflow Phase Agents**: Configure specialized agent modes for SDLC phases:
  - **PRD Mode**: Technical Product Owner agent for requirements gathering
    - Model: Claude Sonnet 4, Tools: read-only analysis, documentation generation
  - **Technical Architecture Mode**: Architect agent for system design
    - Model: Claude Sonnet 4, Tools: design tools, documentation, analysis
  - **Feature Breakdown Mode**: Developer agents for feature decomposition
    - Model: Claude Sonnet 4, Tools: full development capabilities
  - **USP Generation Mode**: Implementation agents for user story creation
    - Model: Claude Sonnet 4, Tools: implementation and testing capabilities

#### 7.1.5 Global AGENTS.md Configuration
- [ ] **Global Agent Rules**: Deploy AGENTS.md file in OpenCode container with:
  - **Context Awareness Rules**: Instructions to read standards and templates from .ai directory
  - **MCP Server Usage Guidelines**: When and how to invoke specific MCP servers
  - **Standards Reference Rules**: Lazy loading of external file references from .ai directory
  - **Workflow Phase Instructions**: Guidelines for different development phases
  - **Template and Prompt Integration**: Instructions for using .ai directory assets

### 7.2 GitHub Agent Mode for CI/CD Integration

#### 7.2.1 GitHub Actions Runner Compatibility
- [ ] **GitHub Agent Mode Configuration**: Specialized OpenCode configuration for GitHub Actions execution:
  - Non-interactive mode operation with `opencode run` command for automation
  - Headless container execution without TUI requirements
  - Optimized resource allocation for GitHub Actions runner constraints
  - Support for GitHub Actions environment variables and secrets
  - Integration with GitHub CLI (`gh`) for repository operations

#### 7.2.2 Authentication and Permissions
- [ ] **GitHub Actions Authentication**: Configure secure authentication for CI/CD workflows:
  - **GITHUB_TOKEN**: Use GitHub Actions built-in token for repository access
    - Automatic token provision by GitHub Actions
    - Scoped permissions based on workflow requirements
    - Token expiration and rotation handling
  - **Provider API Keys**: Secure handling of AI provider authentication
    - OPENROUTER_API_KEY stored as GitHub repository secret
    - Environment variable substitution in container: `{env:OPENROUTER_API_KEY}`
    - Secure secret injection into OpenCode container
  - **MCP Server Authentication**: GitHub MCP server configuration for Actions
    - Use GITHUB_TOKEN for GitHub API access within MCP server
    - Repository-scoped permissions for file operations
    - Pull request and issue management capabilities

#### 7.2.3 Container Configuration for GitHub Actions
- [ ] **GitHub Actions Container Modifications**: Adapt OpenCode container for CI/CD constraints:
  - **Headless Operation**: Remove interactive components and TUI dependencies
    - Disable permission dialogs and interactive prompts
    - Use `--allowedTools` and `--excludedTools` flags for tool restriction
    - Configure automatic permission grants for CI/CD operations
  - **Resource Optimization**: Optimize for GitHub Actions runner limitations
    - Reduced memory footprint for standard GitHub runners (7GB limit)
    - Efficient CPU usage within 2-core runner constraints
    - Fast startup time to minimize workflow execution duration
  - **Environment Setup**: Configure container for GitHub Actions environment
    - Install required clipboard utilities for headless operation (xvfb, xclip)
    - Set DISPLAY environment variable for virtual framebuffer
    - Configure workspace mounting for GitHub Actions workspace

#### 7.2.4 MCP Server Configuration for CI/CD
- [ ] **CI/CD-Optimized MCP Servers**: Configure MCP servers for automated workflows:
  - **GitHub MCP Server**: Enhanced configuration for CI/CD operations
    - Repository file operations with GITHUB_TOKEN authentication
    - Pull request creation and management automation
    - Issue tracking and project management integration
    - Commit and branch operations within workflow context
  - **Context7 MCP Server**: Documentation retrieval for automated analysis
    - Library and framework documentation access
    - Code context analysis for automated reviews
    - Integration with external documentation sources
  - **Sequential Thinking MCP Server**: Structured problem-solving for CI/CD
    - Automated code analysis workflows
    - Multi-step validation and testing procedures
    - Decision tree execution for complex CI/CD logic
  - **Playwright MCP Server**: Automated testing capabilities
    - End-to-end testing in CI/CD pipelines
    - Browser automation for web application testing
    - Screenshot and visual regression testing
  - **Restricted MCP Configuration**: Disable or limit MCP servers for security
    - Remove write-heavy MCP servers in read-only CI/CD contexts
    - Configure MCP servers with minimal required permissions
    - Implement MCP server timeout and resource limits

#### 7.2.5 Workflow Integration Patterns
- [ ] **GitHub Actions Workflow Examples**: Provide workflow templates for common CI/CD scenarios:
  - **Code Review Automation**: Automated code analysis and review generation
    ```yaml
    - name: OpenCode Code Review
      run: |
        opencode run "Analyze the changes in this PR and provide a comprehensive code review focusing on security, performance, and best practices" \
          --allowedTools=view,read,glob,bash \
          --excludedTools=write,edit
    ```
  - **Documentation Generation**: Automated documentation updates
    ```yaml
    - name: Generate Documentation
      run: |
        opencode run "Update the README.md and API documentation based on recent code changes" \
          --allowedTools=view,read,write,edit,glob
    ```
  - **Test Generation**: Automated test case creation
    ```yaml
    - name: Generate Tests
      run: |
        opencode run "Generate comprehensive unit tests for the modified files in this PR" \
          --allowedTools=view,read,write,glob,bash
    ```
  - **Security Analysis**: Automated security vulnerability assessment
    ```yaml
    - name: Security Analysis
      run: |
        opencode run "Perform a security analysis of the codebase focusing on authentication, authorization, and data validation" \
          --allowedTools=view,read,glob,bash \
          --excludedTools=write,edit
    ```

#### 7.2.6 Security Considerations and Best Practices
- [ ] **GitHub Actions Security**: Implement security best practices for CI/CD integration:
  - **Secret Management**: Secure handling of sensitive information
    - Store AI provider API keys as GitHub repository secrets
    - Use GitHub Actions built-in GITHUB_TOKEN for repository operations
    - Implement secret rotation and expiration policies
    - Avoid logging sensitive information in workflow outputs
  - **Permission Scoping**: Minimal required permissions for GitHub Actions
    - Repository read/write permissions based on workflow requirements
    - Pull request and issue management permissions for automation
    - Package registry access for dependency management
    - Actions and workflow permissions for CI/CD operations
  - **Container Security**: Secure container execution in GitHub Actions
    - Use official OpenCode container images with security updates
    - Implement container scanning for vulnerabilities
    - Configure resource limits and timeout constraints
    - Use read-only file systems where possible
  - **Audit and Monitoring**: Track and monitor GitHub Agent operations
    - Log all OpenCode operations and decisions in workflow outputs
    - Implement audit trails for automated code changes
    - Monitor resource usage and performance metrics
    - Set up alerts for failed or suspicious operations

#### 7.2.7 Workflow File Templates and Integration
- [ ] **Required OpenCode Workflow**: Deploy mandatory `.github/workflows/opencode.yml` file:
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
            # share: true
  ```
- [ ] **Additional Workflow Templates**: Provide optional GitHub Actions workflows:
  - **Pull Request Analysis Workflow**: Comprehensive PR review and analysis
  - **Continuous Documentation Workflow**: Automated documentation maintenance
  - **Security Scanning Workflow**: Regular security analysis and reporting
  - **Test Generation Workflow**: Automated test case creation and validation
  - **Code Quality Workflow**: Automated code quality assessment and improvement
- [ ] **Integration Patterns**: Common patterns for OpenCode integration
  - **Conditional Execution**: Run OpenCode based on file changes or PR labels
  - **Multi-Stage Workflows**: Combine OpenCode with other CI/CD tools
  - **Parallel Execution**: Run multiple OpenCode tasks concurrently
  - **Result Aggregation**: Combine outputs from multiple OpenCode operations
  - **Failure Handling**: Graceful error handling and recovery mechanisms

### 7.3 Container Architecture
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
│  │    Project      │◀─────┼──│  • Playwright               │ │ │
│  │   Workspace     │       │  │  • ShadCN UI                │ │ │
│  │   ├── .ai       │◀─────┼──│  • Sequential Thinking      │ │ │
│  │   │   ├── config│       │  │  • GitHub MCP               │ │ │
│  │   │   ├── templates     │  └─────────────────────────────┘ │ │
│  │   │   ├── prompts│      │                                 │ │
│  │   │   └── standards     │  Volume Mounts:                 │ │
│  │   ├── .opencode │       │  /workspace -> Project Root     │ │
│  │   │   └── opencode.json │  /.opencode -> OpenCode Data │ │
│  │   └── src/      │       │  /.ai -> AI Assets              │ │
│  └─────────────────┘       └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

GitHub Actions Integration:
┌─────────────────────────────────────────────────────────────┐
│                GitHub Actions Runner                       │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────┐ │
│  │         OpenCode GitHub Agent Container             │ │
│  │                                                         │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │      Headless MCP Servers                       │ │ │
│  │  │  • GitHub MCP (GITHUB_TOKEN auth)               │ │ │
│  │  │  • Context7 (Documentation)                     │ │ │
│  │  │  • Sequential Thinking (Automation)             │ │ │
│  │  │  • Playwright (Testing)                         │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  │                                                         │ │
│  │  Environment Variables:                                 │ │
│  │  • GITHUB_TOKEN (auto-provided)                        │ │
│  │  • OPENROUTER_API_KEY (from secrets)                   │ │
│  │  • DISPLAY=:99.0 (virtual framebuffer)                 │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘

### 7.4 OpenCode Container Deployment
- [ ] **Container Orchestration**: Deploy OpenCode in isolated container with:
  - Project workspace mounted as volume (/workspace -> project directory)
  - OpenCode data directory mounted (/workspace/.opencode -> container /.opencode)
  - AI assets directory mounted (/workspace/.ai -> container /.ai)
  - MCP servers pre-installed and configured
  - Project-specific environment variables
  - Network access for development tools
  - Resource allocation and limits
- [ ] **Environment Variable Configuration**: Use environment variables for sensitive information:
  - OPENROUTER_API_KEY for provider authentication
  - GITHUB_TOKEN for GitHub MCP server access
  - Environment variable substitution in opencode.json using {env:VARIABLE_NAME} syntax
  - Bootstrapper accepts auth key as parameter for Docker build process
- [ ] **Volume Mounting Strategy**:
  - Workspace root mounted for project access
  - `.opencode` directory mounted for OpenCode's data and configuration
  - `.ai` directory mounted for user-modifiable templates, prompts, and standards
  - OpenCode configuration file (`opencode.json`) accessible from workspace
  - User-modifiable assets available for real-time updates
- [ ] **Container Lifecycle Management**:
  - Container start, stop, restart capabilities
  - Health checks for OpenCode and MCP servers
  - Automatic restart on failure
  - Graceful shutdown procedures

### 7.3 Workspace Asset Management
- [ ] **Asset Deployment to Workspace**: Deploy project assets to separate directories:
  - OpenCode configuration and data in `.opencode` directory
  - User-modifiable AI assets in `.ai` directory
  - Language-specific coding standards and templates
  - Workflow prompt templates and configurations
  - Architectural guidelines and validation rules
  - Project-specific context and metadata
- [ ] **Asset Structure in Workspace**:
  ```
  .opencode/                    # OpenCode's data directory
  ├── opencode.json            # Main OpenCode configuration with:
  │                            #   - Environment variable substitution
  │                            #   - OpenRouter provider (claude sonnet 4)
  │                            #   - MCP server configurations
  │                            #   - Agent modes for workflow phases
  │                            #   - GitHub integration as default
  ├── commands/                # Custom commands
  └── themes/                  # Custom themes

  .ai/                         # User-modifiable AI assets
  ├── config/
  │   ├── auth.json           # AI provider API keys (gitignored)
  │   └── mcp-servers.json    # MCP server configurations
  ├── templates/
  │   ├── typescript/
  │   ├── go/
  │   ├── python/
  │   └── java/
  ├── prompts/
  │   ├── workflow/
  │   ├── coding-standards/
  │   └── agent-modes/
  └── standards/
      ├── architectural/
      ├── testing/
      └── documentation/

  .github/                     # GitHub Actions integration
  └── workflows/
      └── opencode.yml        # Required OpenCode workflow for issue comment triggers

  AGENTS.md                    # Global agent configuration file in container:
                               #   - Standards and templates from .ai directory
                               #   - MCP server invocation rules
                               #   - Context awareness instructions
                               #   - Workflow phase guidelines
  ```
- [ ] **User Modification Support**:
  - All AI assets in `.ai` directory editable by user
  - Changes reflected in OpenCode container via volume mounts
  - Version control integration for asset tracking
  - Validation tools for asset integrity

### 7.4 Handoff and Validation Process
- [ ] **Deployment Validation**: Ensure successful OpenCode deployment:
  - Verify OpenCode container operational status
  - Validate all MCP servers functional and responsive
  - Confirm workspace assets properly mounted and accessible (`.opencode` and `.ai` directories)
  - Test basic OpenCode functionality with project
  - Validate Context7 MCP server functionality and documentation retrieval
  - Validate GitHub MCP server functionality and repository access
  - Verify OpenCode can read configuration from `opencode.json`
- [ ] **Handoff Completion**:
  - Generate handoff report with deployment status
  - Clean up bootstrapper temporary resources
  - Provide OpenCode access instructions to user
  - Document asset modification procedures for user (`.ai` directory)
  - Log successful completion or failure details

### 7.5 Project Lifecycle Support
- [ ] **Iterative Setup Support**: Support multiple bootstrap runs:
  - Add new languages and frameworks to existing projects
  - Remove unused language configurations
  - Update templates and standards without losing customizations
  - Merge new assets with existing user modifications in `.ai` directory
- [ ] **Asset Management**:
  - Version control integration for `.ai` directory (excluding sensitive config)
  - Asset validation and integrity checking
  - Conflict resolution for asset updates
  - User modification preservation during updates
- [ ] **Container Management**:
  - OpenCode container restart after configuration changes
  - Volume remounting for asset updates
  - Configuration validation before container restart
  - Proper handling of both `.opencode` and `.ai` directory mounts

## 8. Bootstrap Tool Functional Requirements

### 8.1 DevContainer Setup Generation
- [ ] **DevContainer Configuration**: Generate `.devcontainer/devcontainer.json` with:
  - Base image selection based on project type
  - Required development tools and runtimes
  - Port forwarding configuration
  - Volume mounts for development workflow
  - OpenCode container integration setup
- [ ] **VSCode Integration**: Create `.vscode/settings.json` with:
  - Project-specific editor settings
  - Formatter and linter configurations
  - Debug configurations
  - OpenCode integration settings
- [ ] **Extension Management**: Generate `.vscode/extensions.json` with:
  - Required extensions list for project type
  - Recommended extensions for enhanced development
  - OpenCode-compatible extensions

### 8.2 Project Structure Generation
- [ ] **Folder Structure**: Create default directory layout based on:
  - Project type and language selection
  - Architectural standards compliance
  - Industry standard conventions
  - OpenCode integration requirements
- [ ] **Configuration Files**: Generate appropriate config files:
  - Build configurations (tsconfig.json, go.mod, requirements.txt, pom.xml)
  - Package management and dependency files
  - Quality tools (eslint, prettier, jest, golangci-lint configs)
- [ ] **GitHub Actions Setup**: Deploy GitHub Actions workflow files:
  - Create `.github/workflows/` directory structure
  - Deploy mandatory `opencode.yml` workflow for issue comment triggers
  - Configure workflow with proper permissions and environment variables
  - Set up integration with official `sst/opencode/github@latest` action
- [ ] **OpenCode Configuration**: Deploy OpenCode configuration:
  - Generate `opencode.json` in project root with proper data directory configuration
  - Configure provider as OpenRouter with Claude Sonnet 4 model
  - Use environment variable substitution for sensitive data: {env:OPENROUTER_API_KEY}
  - Configure MCP servers (Context7, GitHub MCP, Playwright, ShadCN UI, Sequential Thinking)
  - Set up agent modes for workflow phases (PRD, Technical Architecture, Feature Breakdown, USP)
  - Configure GitHub as default integration
  - Set up project-specific OpenCode settings
- [ ] **AI Workspace Assets**: Deploy assets to `.ai` directory:
  - Language-specific templates and coding standards
  - Project-context-aware prompts and configurations
  - Workflow templates and validation rules
  - AI provider authentication configuration
- [ ] **Git Integration**:
  - Initialize git repository if needed
  - Generate .gitignore with AI secrets exclusion
  - Exclude `.ai/config/auth.json` and other sensitive files
  - Include `.ai/templates/`, `.ai/prompts/`, and `.ai/standards/` for version control
  - Include `opencode.json` and `.opencode/` directory for version control
- [ ] **GitHub Actions Integration**:
  - Deploy `.github/workflows/opencode.yml` workflow file for GitHub Actions integration
  - Configure workflow to trigger on issue comments containing `/oc` or `/opencode`
  - Set up proper permissions (id-token: write) for GitHub Actions
  - Configure environment variables for AI provider authentication
  - Use official `sst/opencode/github@latest` action for execution

### 8.3 Development Standards Integration
- [ ] **AI Asset Deployment**: Deploy project-specific assets to `.ai` directory:
  - Language-specific coding standards libraries
  - Architectural pattern templates
  - Workflow prompt templates
  - Development rules and guidelines
- [ ] **OpenCode Configuration**: Generate OpenCode-specific configurations:
  - Main `opencode.json` configuration file in project root
  - Project-context-aware prompts in `.ai/prompts/`
  - Language-specific coding standards in `.ai/standards/`
  - Development workflow templates in `.ai/templates/`
  - Validation rules and compliance checks
  - MCP server configurations for project context
- [ ] **Documentation Template Installation**: Generate templates in `.ai` directory:
  - System architecture document templates
  - API documentation structure templates
  - Code review checklist templates
  - User guide templates

### 8.4 OpenCode Deployment and Integration
- [ ] **OpenCode Container Deployment**: Deploy and configure OpenCode with:
  - Project workspace volume mounting (/workspace)
  - OpenCode data directory mounting (/workspace/.opencode -> /.opencode)
  - AI assets directory mounting (/workspace/.ai -> /.ai)
  - MCP servers pre-installed and configured (Context7, GitHub MCP, Playwright, etc.)
  - Development workflow integration
  - Code generation capabilities
- [ ] **Volume Mount Configuration**: Configure container mounts for:
  - Real-time access to user-modifiable AI assets in `.ai` directory
  - OpenCode configuration and data access via `.opencode` directory
  - Template and prompt updates without container restart
  - Project context and metadata access
- [ ] **Deployment Validation**: Verify successful OpenCode integration:
  - Container health checks
  - Individual MCP server functionality validation:
    - Context7 documentation retrieval testing
    - GitHub MCP repository access testing
    - Playwright browser automation testing
    - Sequential Thinking workflow testing
  - Workspace asset mounting verification (both `.opencode` and `.ai`)
  - OpenCode configuration file accessibility
  - Basic functionality testing

### 8.5 CLI Interface
- [ ] **Interactive Setup Wizard**: Guided project configuration through:
  - Language and framework selection (multi-select supported)
  - Project type selection
  - Feature selection (testing, CI/CD, etc.)
  - OpenCode capabilities configuration
  - Container deployment options
- [ ] **Iterative Setup Support**: Allow multiple bootstrap runs:
  - Detect existing `.ai` directory and project configuration
  - Add new languages/frameworks to existing setup
  - Remove unused language configurations
  - Preserve user modifications during updates
  - Merge new templates with existing customizations in `.ai` directory
- [ ] **Batch Mode**: Configuration file-driven automation
- [ ] **Template Management**: Manage project templates and configurations

### 8.6 Error Handling and Recovery
- [ ] **Comprehensive Error Handling**: Handle all setup phases gracefully:
  - Project structure generation failures
  - OpenCode container deployment failures
  - Workspace asset deployment errors
  - MCP server integration failures
  - Volume mounting and permission issues
- [ ] **Recovery Mechanisms**: Provide recovery options for partial failures:
  - Rollback capabilities for failed deployments
  - Retry mechanisms for transient failures
  - Manual intervention options for complex issues
  - Asset conflict resolution during iterative setup
- [ ] **Diagnostic Tools**: Support troubleshooting and debugging:
  - Detailed logging for all operations
  - Health check utilities for deployed components
  - Configuration validation tools
  - User-friendly error messages and resolution guidance
  - Volume mount verification utilities
- [ ] **Offline Operation**: Support limited functionality without internet:
  - Local template and configuration caching
  - Offline project structure generation
  - Graceful degradation when external services unavailable

## 9. Technical Requirements

### 9.1 Bootstrap Tool Architecture

#### 9.1.1 Core Components
```
┌─────────────────────────────────────────────────────────────┐
│                    CLI Interface                            │
├─────────────────┬───────────────┬───────────────────────────┤
│ Setup Wizard    │ Batch Mode    │ Template Manager          │
└─────────────────┴───────────────┴───────────────────────────┘
         │                       │                       │
┌─────────────────────────────────┼─────────────────────────────────┐
│                    Core Engine                                    │
├─────────────────┬───────────────┬───────────────┬─────────────────┤
│ Project Manager │ Template Eng. │ AI Integrator │ Config Manager  │
├─────────────────┼───────────────┼───────────────┼─────────────────┤
│ File Generator  │ DevContainer  │ OpenCode      │ Validation      │
│ Git Integration │ VSCode Config │ MCP Setup     │ Schema Mgmt     │
└─────────────────┴───────────────┴───────────────┴─────────────────┘
```

#### 9.1.2 Technology Stack
- **Core**: TypeScript 5.x, Node.js 20+
- **CLI**: Commander.js, Inquirer.js for interactive wizard
- **File Operations**: fs-extra, yaml, mustache/handlebars for templating
- **Docker**: Multi-stage builds, Alpine base images, container orchestration
- **Testing**: Jest, integration tests for generated projects
- **Container Management**: Docker SDK for container deployment and management

### 9.2 Data Models
```typescript
enum SupportedLanguage {
  TYPESCRIPT = 'typescript',
  GO = 'go',
  PYTHON = 'python',
  JAVA = 'java'
}

enum AgentMode {
  TECHNICAL_PRODUCT_OWNER = 'technical-product-owner',
  ARCHITECT = 'architect',
  FRONTEND_DEVELOPER = 'frontend-developer',
  BACKEND_DEVELOPER = 'backend-developer',
  ANALYZER_DEBUGGER = 'analyzer-debugger',
  SECURITY_EXPERT = 'security-expert',
  TECHNICAL_WRITER = 'technical-writer',
  PRODUCT_DOCUMENT_WRITER = 'product-document-writer',
  QA_ENGINEER = 'qa-engineer',
  DEVOPS_ENGINEER = 'devops-engineer',
  REFACTORER = 'refactorer'
}
```

## 10. Distribution and Usage

### 10.1 Docker Distribution
- [ ] **Container Image**: Single Docker image containing:
  - Bootstrap tool executable
  - Language-specific project templates (JSON format)
  - Configuration schemas (JSON schemas)
  - Documentation templates
  - Agent mode definitions (JSON configuration files)
  - Coding standards libraries (JSON format)
- [ ] **Registry Publishing**: Distribute via:
  - Docker Hub public registry
  - GitHub Container Registry
  - Semantic versioning for releases

### 10.2 Installation and Usage
- [ ] **Setup Script**: Provide installation scripts:
  - `setup.sh` for Unix/Linux/macOS
  - `setup.cmd` for Windows
  - Scripts handle Docker image pulling and initial setup
- [ ] **Build Scripts**: Provide build scripts for bootstrapper:
  - `build.sh` for Unix/Linux/macOS
  - `build.cmd` for Windows
  - Scripts accept OPENROUTER_API_KEY as parameter
  - Build Docker container with environment variables
  - Deploy OpenCode container with MCP servers pre-installed
- [ ] **CLI Invocation**: Simple command structure:
  ```bash
  # Pull and run bootstrap tool
  ./setup.sh
  
  # Or direct Docker usage
  docker run -it -v $(pwd):/workspace ai-bootstrap
  ```

### 10.3 Workflow Integration
- [ ] **Target Repository Setup**: Tool operates on target directories:
  - Mounts target repository as volume
  - Generates all configuration files in target location
  - Initializes git repository if needed
  - Commits initial setup with descriptive message
  - Deploys and configures OpenCode container
  - Transfers all project assets to OpenCode
  - Validates successful handoff to OpenCode

## 11. Implementation Phases

### Phase 1: Foundation Setup (Weeks 1-2)
- [ ] Repository structure and organization
- [ ] Language-specific project templates
- [ ] Architectural standards documentation
- [ ] Agent mode definitions and responsibilities for OpenCode

### Phase 2: Standards and Workflows (Weeks 3-4)
- [ ] Coding standards libraries for each language
- [ ] Workflow prompt templates for OpenCode installation
- [ ] MCP server integration specifications for OpenCode container
- [ ] Validation rules and compliance checks

### Phase 3: Bootstrap Tool Development (Weeks 5-7)
- [ ] TypeScript project structure and CLI framework
- [ ] Interactive setup wizard implementation
- [ ] DevContainer and VSCode configuration generation
- [ ] Project structure generation engine
- [ ] Template system implementation
- [ ] Asset packaging and transfer mechanisms

### Phase 4: OpenCode Integration (Weeks 8-9)
- [ ] OpenCode container deployment automation
- [ ] Asset transfer and configuration system
- [ ] MCP server integration within OpenCode container
- [ ] Handoff and validation process implementation
- [ ] Error handling and recovery mechanisms

### Phase 5: Distribution and Testing (Weeks 10-11)
- [ ] Docker image optimization and multi-arch builds
- [ ] Setup scripts for all platforms
- [ ] Integration testing with OpenCode deployment
- [ ] End-to-end testing of bootstrap-to-OpenCode workflow
- [ ] Documentation and examples

## 12. Deliverables Required

### 12.1 Repository Content
- [ ] Complete project templates for TypeScript, Go, Python, and Java
- [ ] Documented architectural standards with practical examples
- [ ] Agent mode definitions for OpenCode with clear responsibilities and workflows
- [ ] Coding standards libraries with language-specific examples
- [ ] Workflow prompt templates for OpenCode installation
- [ ] OpenCode configuration files and operational rules
- [ ] MCP server integration specifications for OpenCode container
- [ ] GitHub Agent mode configuration for CI/CD integration
- [ ] Required `.github/workflows/opencode.yml` workflow file for issue comment triggers
- [ ] GitHub Actions workflow templates for automated code analysis, review, and generation
- [ ] Security configurations and best practices for GitHub Actions integration

### 12.2 Bootstrap Tool
- [ ] TypeScript-based CLI tool with interactive wizard
- [ ] Docker container with all templates and configurations
- [ ] OpenCode container deployment and management capabilities
- [ ] Asset transfer and configuration system
- [ ] Setup scripts for cross-platform installation
- [ ] Comprehensive documentation and usage examples

## 13. Success Criteria

### 13.1 Functional Success
- [ ] **Complete Setup**: Single command creates fully configured development environment with OpenCode deployed
- [ ] **OpenCode Integration**: OpenCode container operational with workspace assets mounted and all MCP servers functional
- [ ] **DevContainer Ready**: Immediate development capability in any Docker-compatible environment
- [ ] **Standards Compliance**: Generated projects follow established architectural principles
- [ ] **Seamless Handoff**: Successful transition from bootstrapper to OpenCode with all assets accessible via volume mounts
- [ ] **Asset Accessibility**: All templates, standards, and configurations available in workspace and modifiable by user
- [ ] **Iterative Setup**: Support for multiple bootstrap runs to add/remove languages and frameworks
- [ ] **MCP Server Integration**: Both Context7 and GitHub MCP servers properly configured and functional
- [ ] **GitHub Agent Mode**: OpenCode successfully operates in GitHub Actions workflows with full automation capabilities
- [ ] **CI/CD Integration**: Automated code analysis, review, and generation workflows function reliably in GitHub Actions
- [ ] **Security Compliance**: GitHub Actions integration follows security best practices with proper secret management

### 13.2 Technical Success
- [ ] **Cross-Platform**: Works on Windows, macOS, and Linux
- [ ] **Multi-Language Templates**: Provides templates and standards for TypeScript, Go, Python, and Java projects
- [ ] **Performance**: Complete project setup and OpenCode deployment in under 5 minutes
- [ ] **Reliability**: 95% success rate across different project configurations and OpenCode deployments
- [ ] **Maintainability**: Clear separation of concerns between bootstrapper and OpenCode
- [ ] **Container Management**: Reliable OpenCode container deployment and lifecycle management
- [ ] **Volume Mount Reliability**: Consistent workspace asset mounting and real-time updates
- [ ] **Iterative Capability**: Successful addition/removal of languages without data loss
- [ ] **Git Integration**: Proper .gitignore configuration excluding AI secrets
- [ ] **GitHub Actions Compatibility**: Reliable execution within GitHub Actions runner constraints (7GB memory, 2-core CPU)
- [ ] **Headless Operation**: Successful non-interactive operation in CI/CD environments
- [ ] **Authentication Security**: Secure handling of GitHub tokens and AI provider API keys in automated workflows

## 14. Dependencies and Prerequisites

### 14.1 External Dependencies
- Docker runtime on target system with container orchestration capabilities
- Git for repository initialization
- Internet connectivity for image pulling and package installation
- Sufficient system resources for running OpenCode container alongside development environment

### 14.2 Internal Prerequisites
- OpenCode AI agent Docker image with MCP servers pre-installed (must be built first)
- MCP server configurations and integrations (Context7, GitHub MCP, Playwright, ShadCN UI, Sequential Thinking)
- Global AGENTS.md file with comprehensive agent rules and MCP server usage guidelines
- Environment variable configuration for OpenRouter provider (Claude Sonnet 4)
- Agent mode definitions for workflow phases (PRD, Technical Architecture, Feature Breakdown, USP)
- GitHub Agent mode configuration for CI/CD integration with headless operation capabilities
- GitHub Actions workflow templates for automated code analysis, review, testing, and documentation
- Security configurations for GitHub Actions integration including secret management and permission scoping
- Documented development standards and templates
- Tested project templates for each supported language
- Validated workflow prompt templates for OpenCode consumption
- Container orchestration and deployment scripts
- Volume mounting and permission management utilities
- Build scripts (build.sh, build.cmd) that accept authentication keys as parameters

## 15. Risk Mitigation

### 15.1 Technical Risks
- **Docker Compatibility**: Test across Docker Desktop, Podman, and cloud environments
- **Template Complexity**: Start with simple templates, gradually add complexity
- **OpenCode Container Reliability**: Implement health checks, restart policies, and fallback modes
- **Multi-Language Templates**: Ensure consistent template quality across all supported languages
- **Container Orchestration**: Test container deployment across different Docker environments
- **Asset Transfer Reliability**: Implement validation and retry mechanisms for asset transfer

### 15.2 Operational Risks
- **Setup Script Reliability**: Extensive testing across platforms and environments
- **Version Management**: Clear versioning strategy for bootstrapper, OpenCode, templates, and MCP servers
- **User Experience**: Comprehensive error handling and helpful error messages
- **OpenCode Integration**: Clear documentation for OpenCode usage and troubleshooting
- **Container Resource Management**: Monitor and manage resource usage for OpenCode container
- **Handoff Process**: Ensure reliable transition from bootstrapper to OpenCode with proper validation





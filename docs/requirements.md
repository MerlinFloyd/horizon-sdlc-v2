# AI Project Bootstrap Tool - Requirements Document

## 1. Project Overview

### 1.1 Vision Statement
Build a TypeScript-based project bootstrapping tool that automates complete project setup with AI-powered development assistance, distributed as a Docker container for universal deployment across repositories.

### 1.2 Core Objectives
- **Automation**: Eliminate manual project setup overhead
- **AI Integration**: Embed intelligent development assistance throughout SDLC
- **Portability**: Docker-based distribution for universal deployment

### 1.3 Architectural Inspiration
Based on https://github.com/SuperClaude-Org/SuperClaude_Framework architecture and functional patterns.
Inspiration also from:
- https://github.com/Jedward23/Tmux-Orchestrator
- https://github.com/All-Hands-AI/OpenHands
- https://github.com/buildermethods/agent-os

### 1.4 Repository Purpose
This repository serves as the foundation for our AI Project Bootstrap Tool and contains standardized configurations, templates, and agent definitions that will be used to bootstrap new projects across multiple languages and use cases.

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
- [ ] **MCP Server Integration** - Mandatory use of available MCP servers:
  - Context7 - Context management and retrieval
  - Playwright - Browser automation and testing
  - ShadCN UI MCP (https://github.com/Jpisnice/shadcn-ui-mcp-server) - UI component generation
  - Sequential Thinking - Structured problem-solving workflows
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

## 6. Structured Workflow Implementation

### 6.1 Four-Phase Development Workflow
Create a structured development process with pre-configured prompts:

#### Phase 1: Product Requirements Document (PRD) Phase
- [ ] **Product Owner Mode Agent** creates comprehensive PRD
- [ ] **Incorporates**: Target languages, frameworks, product requirements, business use cases, user personas
- [ ] **Output**: Complete PRD document with clear specifications

#### Phase 2: Technical Architecture Phase
- [ ] **Architect Mode Agent** develops technical specifications
- [ ] **Integrates**: Enterprise requirements, architectural standards, PRD requirements
- [ ] **Output**: Technical specifications document with system design

#### Phase 3: Feature Breakdown Phase
- [ ] **Technical specifications** decomposed into independent, implementable features
- [ ] **Each feature includes**: 
  - Functional requirements
  - Testing requirements
  - Logging specifications
  - CI/CD considerations
  - Observability requirements
  - **Documentation requirements**:
    - Technical documentation (API docs, architecture decisions)
    - Business documentation (user guides, feature specifications, acceptance criteria)
    - Integration documentation (setup guides, configuration examples)
- [ ] **Features assigned** to appropriate backend or frontend dev agents
- [ ] **Documentation assignments** distributed to:
  - Technical Writer agents for technical documentation
  - Product Document Writer agents for business-facing documentation
  - Implementation agents responsible for inline code documentation

#### Phase 4: User Story Prompt (USP) Implementation Phase
- [ ] **Features broken down** into actionable User Story Prompts
- [ ] **Each USP contains**:
  - Agent role definition
  - Clear implementation goal
  - Step-by-step instructions
  - Language-specific examples from coding standards
  - Compliance rules
  - **Documentation deliverables**:
    - Only write code comments if absolutely necessary, we prefer that the code be simple enough to be self-documenting
    - API documentation updates (OpenAPI/Swagger specs)
    - README updates for new features
    - User-facing documentation for new functionality
- [ ] **USPs follow** prompt engineering best practices for maximum agent effectiveness
- [ ] **USPs follow** test-driven development approaches so that tests are written first and then the implementation is added
- [ ] **Documentation USPs** created alongside implementation USPs:
  - Technical documentation USPs for complex features
  - Business documentation USPs for user-facing features
  - Integration documentation USPs for setup and configuration changes

### 6.2 Workflow Prompt Templates
- [ ] Create standardized prompt templates for each phase (JSON format for token efficiency)
- [ ] Include validation checkpoints between phases (JSON schema validation)
- [ ] Establish handoff procedures between agent modes (JSON workflow definitions)
- [ ] Document escalation paths for complex decisions (JSON decision trees)

## 7. Bootstrap Tool Functional Requirements

### 7.1 DevContainer Setup Generation
- [ ] **DevContainer Configuration**: Generate `.devcontainer/devcontainer.json` with:
  - Base image selection based on project type
  - Required development tools and runtimes
  - Port forwarding configuration
  - Volume mounts for development workflow
- [ ] **VSCode Integration**: Create `.vscode/settings.json` with:
  - Project-specific editor settings
  - Formatter and linter configurations
  - Debug configurations
- [ ] **Extension Management**: Generate `.vscode/extensions.json` with:
  - Required extensions list for project type
  - Recommended extensions for enhanced development

### 7.2 Project Structure Generation
- [ ] **Folder Structure**: Create default directory layout based on:
  - Project type and language selection
  - Architectural standards compliance
  - Industry standard conventions
- [ ] **Configuration Files**: Generate appropriate config files:
  - Build configurations (tsconfig.json, go.mod, requirements.txt, pom.xml)
  - Package management and dependency files
  - Quality tools (eslint, prettier, jest, golangci-lint configs)
- [ ] **DevContainer Configuration**: Generate `.devcontainer/devcontainer.json` for selected language
- [ ] **AI Agent Templates**: Install language-specific templates and coding standards (JSON format)
- [ ] **OpenCode Agent Setup**: Configure AI agent with project-context-aware prompts

### 7.3 Development Standards Integration
- [ ] **AI Agent Templates**: Install project-specific:
  - Language-specific coding standards libraries (JSON format)
  - Architectural pattern templates (JSON format)
  - Workflow prompt templates (JSON format)
- [ ] **OpenCode Configuration**: Deploy AI agent with:
  - Project-context-aware prompts
  - Language-specific coding standards
  - Development workflow integration
- [ ] **Development Rules**: Install project-specific:
  - Coding standards and style guides
  - Git workflow guidelines
  - Code review checklists
- [ ] **Architecture Documentation**: Generate templates for:
  - System architecture documents
  - API documentation structure
  - Technical decision records (ADRs)

### 7.4 AI Agent Integration
- [ ] **OpenCode AI Agent**: Configure and deploy AI agent with:
  - Project-context-aware prompts
  - Development workflow integration
  - Code generation capabilities
- [ ] **Custom Prompts**: Install project-specific prompt libraries for:
  - Code generation patterns
  - Documentation assistance
  - Testing strategies
  - Architecture guidance

### 7.5 CLI Interface
- [ ] **Interactive Setup Wizard**: Guided project configuration through:
  - Language and framework selection
  - Project type selection
  - Feature selection (testing, CI/CD, etc.)
  - AI capabilities configuration
- [ ] **Batch Mode**: Configuration file-driven automation
- [ ] **Template Management**: Manage project templates and configurations

## 8. Technical Requirements

### 8.1 Bootstrap Tool Architecture

#### 8.1.1 Core Components
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

#### 8.1.2 Technology Stack
- **Core**: TypeScript 5.x, Node.js 20+
- **CLI**: Commander.js, Inquirer.js for interactive wizard
- **File Operations**: fs-extra, yaml, mustache/handlebars for templating
- **Docker**: Multi-stage builds, Alpine base images
- **Testing**: Jest, integration tests for generated projects

### 8.2 Data Models
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

## 9. Distribution and Usage

### 9.1 Docker Distribution
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

### 9.2 Installation and Usage
- [ ] **Setup Script**: Provide installation scripts:
  - `setup.sh` for Unix/Linux/macOS
  - `setup.cmd` for Windows
  - Scripts handle Docker image pulling and initial setup
- [ ] **CLI Invocation**: Simple command structure:
  ```bash
  # Pull and run bootstrap tool
  ./setup.sh
  
  # Or direct Docker usage
  docker run -it -v $(pwd):/workspace ai-bootstrap
  ```

### 9.3 Workflow Integration
- [ ] **Target Repository Setup**: Tool operates on target directories:
  - Mounts target repository as volume
  - Generates all configuration files in target location
  - Initializes git repository if needed
  - Commits initial setup with descriptive message

## 10. Implementation Phases

### Phase 1: Foundation Setup (Weeks 1-2)
- [ ] Repository structure and organization
- [ ] Language-specific project templates
- [ ] Architectural standards documentation
- [ ] Agent mode definitions and responsibilities

### Phase 2: Standards and Workflows (Weeks 3-4)
- [ ] Coding standards libraries for each language
- [ ] Structured workflow prompt templates
- [ ] MCP server integration specifications
- [ ] Validation rules and compliance checks

### Phase 3: Bootstrap Tool Development (Weeks 5-7)
- [ ] TypeScript project structure and CLI framework
- [ ] Interactive setup wizard implementation
- [ ] DevContainer and VSCode configuration generation
- [ ] Project structure generation engine
- [ ] Template system implementation

### Phase 4: AI Integration (Weeks 8-9)
- [ ] OpenCode agent integration
- [ ] Custom prompt installation
- [ ] AI capability configuration
- [ ] MCP server setup automation

### Phase 5: Distribution and Testing (Weeks 10-11)
- [ ] Docker image optimization and multi-arch builds
- [ ] Setup scripts for all platforms
- [ ] Integration testing with various project types
- [ ] Documentation and examples

## 11. Deliverables Required

### 11.1 Repository Content
- [ ] Complete project templates for TypeScript, Go, Python, and Java (JSON format)
- [ ] Documented architectural standards with practical examples (JSON schemas and examples)
- [ ] Agent mode definitions with clear responsibilities and workflows (JSON configuration)
- [ ] Coding standards libraries with language-specific examples (JSON format)
- [ ] Workflow prompt templates for each development phase (JSON templates)
- [ ] OpenCode configuration files and operational rules (JSON format)
- [ ] Integration specifications for MCP servers (JSON configuration)

### 11.2 Bootstrap Tool
- [ ] TypeScript-based CLI tool with interactive wizard
- [ ] Docker container with all templates and configurations
- [ ] Setup scripts for cross-platform installation
- [ ] Comprehensive documentation and usage examples

## 12. Success Criteria

### 12.1 Functional Success
- [ ] **Complete Setup**: Single command creates fully configured development environment
- [ ] **AI Integration**: OpenCode agent operational with project-specific context
- [ ] **DevContainer Ready**: Immediate development capability in any Docker-compatible environment
- [ ] **Standards Compliance**: Generated projects follow established architectural principles
- [ ] **Workflow Integration**: Structured development process with AI-guided phases

### 12.2 Technical Success
- [ ] **Cross-Platform**: Works on Windows, macOS, and Linux
- [ ] **Multi-Language Templates**: Provides templates and standards for TypeScript, Go, Python, and Java projects
- [ ] **Performance**: Complete project setup in under 2 minutes
- [ ] **Reliability**: 95% success rate across different project configurations
- [ ] **Maintainability**: Clear separation of concerns and extensible architecture

## 13. Dependencies and Prerequisites

### 13.1 External Dependencies
- Docker runtime on target system
- Git for repository initialization
- Internet connectivity for image pulling and package installation

### 13.2 Internal Prerequisites
- OpenCode AI agent Docker image (must be built first)
- MCP server configurations and integrations
- Documented development standards and templates
- Tested project templates for each supported language
- Validated workflow prompt templates

## 14. Risk Mitigation

### 14.1 Technical Risks
- **Docker Compatibility**: Test across Docker Desktop, Podman, and cloud environments
- **Template Complexity**: Start with simple templates, gradually add complexity
- **AI Agent Reliability**: Implement fallback modes for offline operation
- **Multi-Language Templates**: Ensure consistent template quality across all supported languages

### 14.2 Operational Risks
- **Setup Script Reliability**: Extensive testing across platforms and environments
- **Version Management**: Clear versioning strategy for tool, templates, and AI agent
- **User Experience**: Comprehensive error handling and helpful error messages
- **Workflow Adoption**: Clear documentation and examples for structured development process





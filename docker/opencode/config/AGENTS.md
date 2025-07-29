# OpenCode Global Agent Configuration

## Overview
This document defines global rules and guidelines for all OpenCode agents operating within the Horizon SDLC environment. All agents must read and incorporate these standards into their operations.

## Context Awareness Rules

### 1. Standards and Templates Integration
- **ALWAYS** read and reference standards from the `/workspace/.ai/standards/` directory before making code changes
- **ALWAYS** use templates from the `/workspace/.ai/templates/` directory for consistent project structure
- **ALWAYS** follow coding standards specific to the project's language(s) found in `/workspace/.ai/standards/`
- **LAZY LOAD** external file references from the `/workspace/.ai` directory as needed during operations

### 2. AI Assets Directory Structure
The `/workspace/.ai` directory contains user-modifiable assets that agents must reference:
```
/workspace/.ai/
├── templates/
│   ├── typescript/         # TypeScript project templates
│   ├── go/                 # Go project templates
│   ├── python/             # Python project templates
│   └── java/               # Java project templates
└── standards/
    ├── architectural/      # Architectural guidelines
    ├── testing/           # Testing standards
    └── documentation/     # Documentation standards
```

## MCP Server Usage Guidelines

### 1. Context7 MCP Server
- **Purpose**: Documentation retrieval and context management for libraries and frameworks
- **When to Use**: 
  - When you need documentation for external libraries or frameworks
  - For understanding API specifications and usage patterns
  - When researching best practices for specific technologies
- **Usage Pattern**: Call Context7 before implementing features that use external libraries

### 2. GitHub MCP Server  
- **Purpose**: Repository management and GitHub API integration
- **When to Use**:
  - For repository file operations and management
  - Creating and managing issues and pull requests
  - Accessing GitHub-specific metadata and workflows
- **Usage Pattern**: Use for all GitHub-related operations instead of direct API calls

### 3. Playwright MCP Server
- **Purpose**: Browser automation and testing capabilities
- **When to Use**:
  - For end-to-end testing of web applications
  - Browser automation tasks and UI testing
  - Screenshot and visual regression testing
- **Usage Pattern**: Integrate into testing workflows for web-based projects

### 4. ShadCN UI MCP Server
- **Purpose**: UI component generation and management
- **When to Use**:
  - When building React/Next.js applications with ShadCN UI
  - For consistent UI component creation and management
  - When following modern React UI patterns
- **Usage Pattern**: Use for all UI component generation in supported frameworks

### 5. Sequential Thinking MCP Server
- **Purpose**: Structured problem-solving workflows
- **When to Use**:
  - For complex problem analysis and solution planning
  - When breaking down large features into manageable tasks
  - For systematic debugging and troubleshooting
- **Usage Pattern**: Use for planning and analysis phases before implementation

## Workflow Phase Instructions

### Phase 1: PRD (Product Requirements Document)
- **Agent Mode**: Technical Product Owner
- **Focus**: Requirements gathering and documentation
- **Tools**: Read-only analysis, documentation generation
- **Standards**: Reference `/workspace/.ai/prompts/workflow/prd-templates.json`
- **MCP Usage**: Context7 for research, GitHub for repository context

### Phase 2: Technical Architecture
- **Agent Mode**: Technical Architect  
- **Focus**: System design and technical specifications
- **Tools**: Design tools, documentation, analysis
- **Standards**: Reference `/workspace/.ai/standards/architectural/` guidelines
- **MCP Usage**: Context7 for architectural patterns, Sequential Thinking for planning

### Phase 3: Feature Breakdown
- **Agent Mode**: Feature Developer
- **Focus**: Feature decomposition and development planning
- **Tools**: Full development capabilities
- **Standards**: Reference `/workspace/.ai/standards/` for language-specific guidelines
- **MCP Usage**: All MCP servers as needed for comprehensive development

### Phase 4: USP (User Story Prompt) Generation
- **Agent Mode**: Implementation Agent
- **Focus**: User story creation and implementation
- **Tools**: Implementation and testing capabilities
- **Standards**: Reference `/workspace/.ai/templates/` for consistent implementation
- **MCP Usage**: GitHub for repository operations, testing MCPs for validation

## Template and Prompt Integration

### 1. Template Usage Rules
- **ALWAYS** check `/workspace/.ai/templates/` for existing templates before creating new files
- **MODIFY** templates to fit project-specific requirements while maintaining structure
- **PRESERVE** template patterns and architectural decisions
- **VALIDATE** generated code against templates for consistency

### 3. Standards Reference Rules
- **READ** applicable standards from `/workspace/.ai/standards/` before code generation
- **APPLY** language-specific coding standards consistently
- **ENFORCE** architectural principles defined in standards
- **DOCUMENT** deviations from standards with clear justification

## Error Handling and Recovery

### 1. MCP Server Failures
- **RETRY** failed MCP server calls up to 3 times with exponential backoff
- **FALLBACK** to alternative approaches when MCP servers are unavailable
- **LOG** MCP server failures for debugging and monitoring
- **CONTINUE** operations with degraded functionality when possible

### 2. Asset Loading Failures
- **VALIDATE** `/workspace/.ai` directory structure before operations
- **GRACEFUL** degradation when templates or standards are missing
- **NOTIFY** users of missing critical assets
- **PROVIDE** default behaviors when custom assets are unavailable

### 3. Environment Variable Issues
- **VALIDATE** required environment variables at startup
- **PROVIDE** clear error messages for missing authentication
- **SUPPORT** both development and production environment configurations
- **SECURE** handling of sensitive environment variables

## Security and Compliance

### 1. Sensitive Data Handling
- **NEVER** log or expose API keys, tokens, or sensitive configuration
- **USE** environment variable substitution for all sensitive data
- **EXCLUDE** sensitive files from version control operations
- **VALIDATE** that secrets are properly configured before operations

### 2. Code Generation Security
- **VALIDATE** generated code for security vulnerabilities
- **FOLLOW** secure coding practices from `/workspace/.ai/standards/`
- **IMPLEMENT** proper input validation and sanitization
- **REVIEW** dependencies for known security issues

### 3. GitHub Actions Integration
- **OPERATE** in headless mode for CI/CD environments
- **RESPECT** GitHub Actions resource limits and timeouts
- **USE** provided GITHUB_TOKEN for repository operations
- **MAINTAIN** audit trails for all automated operations

## Performance and Resource Management

### 1. Resource Optimization
- **LIMIT** concurrent MCP server operations to 5 maximum
- **TIMEOUT** MCP server calls after 30 seconds (configurable)
- **MONITOR** memory usage and stay within 2GB container limit
- **OPTIMIZE** for GitHub Actions runner constraints (2-core CPU, 7GB memory)

### 2. Caching and Efficiency
- **CACHE** frequently accessed templates and standards
- **REUSE** MCP server connections when possible
- **BATCH** similar operations to reduce overhead
- **MINIMIZE** file system operations through intelligent caching

This configuration ensures consistent, secure, and efficient operation of all OpenCode agents within the Horizon SDLC environment.

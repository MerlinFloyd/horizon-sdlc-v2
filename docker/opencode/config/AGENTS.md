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
    ├── architectural.md      # Architectural guidelines
    ├── testing.md           # Testing standards
    └── documentation.md     # Documentation standards
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

This section documents the four-phase product development workflow that guides users through the complete process of building a product using OpenCode. Each phase has specific OpenCode modes and the requirements and specific tools is specified in the markdown files related to that mode.

### Phase 1: Product Requirements Definition

**Purpose**: Define comprehensive product requirements based on user needs and transform them into a structured Product Requirements Document.

**OpenCode Mode**: product-requirements-definition mode

**Standards**: Reference `/workspace/.ai/standards/` guidelines

### Phase 2: Technical Architecture Specification

**Purpose**: Merge product requirements with organizational technical constraints to create a comprehensive technical specification that ensures the product can be built within the organization's technical ecosystem.

**OpenCode Mode**: architect Mode

**Standards**: Reference `/workspace/.ai/standards/` guidelines

### Phase 3: Feature Breakdown and Prioritization

**Purpose**: Decompose requirements and technical specifications into independently implementable features, ordered by dependencies, priority levels, and risk mitigation strategies.

**OpenCode Mode**: feature-breakdown Mode

**Standards**: Reference `/workspace/.ai/standards/` guidelines

### Phase 4: User Story Generation and Implementation (USP Mode)

**Purpose**: Convert individual features into detailed, actionable user stories that provide comprehensive implementation guidance for AI agent execution.

**OpenCode Mode**: user-story-prompt Mode

## Workflow Integration Notes

### Cross-Phase Dependencies
- Each phase builds upon the outputs of the previous phase
- Changes in later phases may require revisiting earlier phases
- Maintain traceability from user stories back to original requirements

### Quality Gates
- Each phase must be completed and validated before proceeding to the next
- Regular reviews ensure alignment with original product vision
- Continuous validation against organizational constraints and standards

### Iterative Refinement
- Phases may be revisited based on implementation feedback
- User stories can be refined based on development insights
- Architecture may be adjusted based on implementation realities

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

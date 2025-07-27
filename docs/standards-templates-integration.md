# Standards and Templates Integration Planning
## Horizon SDLC v2 Bootstrapping Application

### 1. Overview

This document defines how the standards from requirements.md will be integrated into the technical implementation, establishes templates for generated artifacts, and defines OpenCode agent configuration patterns.

### 2. Standards Integration Framework

#### 2.1 Architectural Standards Implementation

**Clean Architecture Integration:**
```json
{
  "standard": "clean-architecture",
  "version": "1.0.0",
  "description": "Layered architecture with clear boundaries",
  "languages": ["typescript", "go", "python", "java"],
  "patterns": {
    "layers": {
      "presentation": {
        "description": "Controllers, views, and user interface",
        "dependencies": ["application"],
        "examples": {
          "typescript": "src/controllers/",
          "go": "internal/handlers/",
          "python": "src/presentation/",
          "java": "src/main/java/com/example/controllers/"
        }
      },
      "application": {
        "description": "Use cases and application services",
        "dependencies": ["domain"],
        "examples": {
          "typescript": "src/services/",
          "go": "internal/services/",
          "python": "src/application/",
          "java": "src/main/java/com/example/services/"
        }
      },
      "domain": {
        "description": "Business logic and entities",
        "dependencies": [],
        "examples": {
          "typescript": "src/domain/",
          "go": "internal/domain/",
          "python": "src/domain/",
          "java": "src/main/java/com/example/domain/"
        }
      },
      "infrastructure": {
        "description": "External concerns and implementations",
        "dependencies": ["application", "domain"],
        "examples": {
          "typescript": "src/infrastructure/",
          "go": "internal/infrastructure/",
          "python": "src/infrastructure/",
          "java": "src/main/java/com/example/infrastructure/"
        }
      }
    }
  },
  "validation": {
    "rules": [
      "Domain layer has no external dependencies",
      "Application layer only depends on domain",
      "Infrastructure implements interfaces from application/domain"
    ]
  }
}
```

**DRY Principle Implementation:**
```json
{
  "standard": "dry-principle",
  "version": "1.0.0",
  "description": "Don't Repeat Yourself - Code reusability and maintainability",
  "implementation": {
    "shared-utilities": {
      "location": "src/utils/",
      "purpose": "Common functionality across modules",
      "examples": ["validation", "formatting", "constants"]
    },
    "base-classes": {
      "location": "src/base/",
      "purpose": "Common behavior inheritance",
      "examples": ["BaseEntity", "BaseService", "BaseController"]
    },
    "configuration": {
      "location": "src/config/",
      "purpose": "Centralized configuration management",
      "examples": ["database", "api", "environment"]
    }
  }
}
```

#### 2.2 Language-Specific Standards

**TypeScript Standards:**
```json
{
  "language": "typescript",
  "standards": {
    "style-guide": {
      "naming": {
        "classes": "PascalCase",
        "functions": "camelCase",
        "variables": "camelCase",
        "constants": "UPPER_SNAKE_CASE",
        "interfaces": "PascalCase with I prefix",
        "types": "PascalCase"
      },
      "file-naming": {
        "components": "kebab-case.ts",
        "tests": "kebab-case.test.ts",
        "types": "kebab-case.types.ts"
      }
    },
    "best-practices": {
      "strict-mode": true,
      "explicit-types": "required for public APIs",
      "null-checks": "strict null checks enabled",
      "unused-variables": "error level",
      "prefer-const": true,
      "no-any": "avoid any type usage"
    },
    "patterns": {
      "dependency-injection": {
        "framework": "tsyringe or inversify",
        "pattern": "constructor injection",
        "example": "src/examples/di-example.ts"
      },
      "error-handling": {
        "pattern": "Result<T, E> or Either<L, R>",
        "no-exceptions": "prefer explicit error types",
        "example": "src/examples/error-handling.ts"
      }
    }
  }
}
```

### 3. Template Generation Patterns

#### 3.1 Project Template Structure

**Template Metadata Schema:**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "name": {"type": "string"},
    "version": {"type": "string"},
    "description": {"type": "string"},
    "language": {"type": "string"},
    "frameworks": {"type": "array", "items": {"type": "string"}},
    "features": {"type": "array", "items": {"type": "string"}},
    "dependencies": {
      "type": "object",
      "properties": {
        "runtime": {"type": "array"},
        "development": {"type": "array"},
        "testing": {"type": "array"}
      }
    },
    "structure": {
      "type": "object",
      "properties": {
        "directories": {"type": "array"},
        "files": {"type": "array"}
      }
    },
    "scripts": {
      "type": "object",
      "properties": {
        "setup": {"type": "string"},
        "build": {"type": "string"},
        "test": {"type": "string"},
        "lint": {"type": "string"}
      }
    }
  }
}
```

**TypeScript Project Template Example:**
```json
{
  "name": "typescript-clean-architecture",
  "version": "1.0.0",
  "description": "TypeScript project with Clean Architecture",
  "language": "typescript",
  "frameworks": ["express", "jest"],
  "features": ["testing", "linting", "docker"],
  "dependencies": {
    "runtime": [
      "express@^4.18.0",
      "tsyringe@^4.7.0",
      "dotenv@^16.0.0"
    ],
    "development": [
      "@types/node@^18.0.0",
      "@types/express@^4.17.0",
      "typescript@^5.0.0",
      "ts-node@^10.9.0"
    ],
    "testing": [
      "jest@^29.0.0",
      "@types/jest@^29.0.0",
      "ts-jest@^29.0.0"
    ]
  },
  "structure": {
    "directories": [
      "src/domain/entities",
      "src/domain/repositories",
      "src/application/services",
      "src/application/interfaces",
      "src/infrastructure/database",
      "src/infrastructure/web",
      "src/presentation/controllers",
      "tests/unit",
      "tests/integration"
    ],
    "files": [
      "src/index.ts",
      "src/container.ts",
      "package.json",
      "tsconfig.json",
      ".eslintrc.json",
      "jest.config.js",
      "Dockerfile",
      ".dockerignore"
    ]
  },
  "scripts": {
    "setup": "npm install && npm run build",
    "build": "tsc",
    "test": "jest",
    "lint": "eslint src/**/*.ts"
  }
}
```

#### 3.2 Configuration File Templates

**OpenCode Configuration Template:**
```mustache
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
    {{#features.testing}}
    "playwright": {
      "type": "local",
      "command": ["playwright-mcp-server"],
      "enabled": true
    },
    {{/features.testing}}
    {{#features.ui}}
    "shadcn-ui": {
      "type": "local",
      "command": ["shadcn-ui-mcp-server"],
      "enabled": true
    },
    {{/features.ui}}
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
      "systemPrompt": "You are a technical product owner focused on {{project.domain}}. Use the standards from .ai/standards/ and follow the workflow prompts in .ai/prompts/workflow/.",
      "tools": ["read", "analyze", "document"]
    },
    "architecture": {
      "name": "System Architect",
      "description": "Technical specifications and system design",
      "systemPrompt": "You are a system architect specializing in {{project.language}} and {{project.frameworks}}. Follow clean architecture principles from .ai/standards/architectural/.",
      "tools": ["design", "analyze", "document"]
    },
    "breakdown": {
      "name": "Feature Developer",
      "description": "Feature decomposition and implementation planning",
      "systemPrompt": "You are a {{project.language}} developer. Use coding standards from .ai/standards/coding/{{project.language}}/ and testing patterns from .ai/standards/testing/.",
      "tools": ["read", "write", "analyze", "test"]
    },
    "usp": {
      "name": "Implementation Agent",
      "description": "User story implementation and code generation",
      "systemPrompt": "You are an expert {{project.language}} developer. Generate code following the patterns in .ai/templates/{{project.language}}/ and standards in .ai/standards/.",
      "tools": ["read", "write", "test", "debug"]
    }
  }
}
```

### 4. OpenCode Agent Configuration Patterns

#### 4.1 Global AGENTS.md Template

```markdown
# OpenCode Agent Configuration
## Project: {{project.name}}

### Context Awareness Rules

1. **Standards Reference**: Always read and incorporate standards from `.ai/standards/` directory
2. **Template Usage**: Use templates from `.ai/templates/{{project.language}}/` for code generation
3. **Prompt Integration**: Follow workflow prompts from `.ai/prompts/workflow/` for structured development

### MCP Server Usage Guidelines

#### Context7 MCP Server
- **Purpose**: Documentation retrieval and context management
- **Usage**: Query for library documentation, framework guides, and best practices
- **Command**: Use when you need external documentation or examples

#### GitHub MCP Server  
- **Purpose**: Repository management and GitHub API integration
- **Usage**: File operations, issue management, pull request creation
- **Command**: Use for all GitHub-related operations

#### Sequential Thinking MCP Server
- **Purpose**: Structured problem-solving workflows
- **Usage**: Complex analysis, multi-step planning, decision trees
- **Command**: Use for breaking down complex problems

#### Playwright MCP Server
- **Purpose**: Browser automation and testing
- **Usage**: E2E testing, UI automation, screenshot generation
- **Command**: Use for web application testing

{{#features.ui}}
#### ShadCN UI MCP Server
- **Purpose**: UI component generation and management
- **Usage**: React component creation, UI library integration
- **Command**: Use for frontend component development
{{/features.ui}}

### Workflow Phase Instructions

#### PRD Mode (Technical Product Owner)
1. Read project requirements and business context
2. Use `.ai/prompts/workflow/prd-generation.json` for structured PRD creation
3. Reference `.ai/standards/documentation/` for documentation standards
4. Generate comprehensive product requirements document

#### Technical Architecture Mode (System Architect)
1. Analyze PRD and technical requirements
2. Use `.ai/prompts/workflow/technical-architecture.json` for design guidance
3. Follow architectural patterns from `.ai/standards/architectural/`
4. Create detailed technical specifications

#### Feature Breakdown Mode (Feature Developer)
1. Decompose features into implementable tasks
2. Use `.ai/prompts/workflow/feature-breakdown.json` for structured breakdown
3. Reference `.ai/standards/coding/{{project.language}}/` for implementation patterns
4. Create detailed implementation plans

#### USP Generation Mode (Implementation Agent)
1. Implement user stories and features
2. Use `.ai/templates/{{project.language}}/` for code generation
3. Follow `.ai/standards/testing/` for test creation
4. Generate production-ready code

### Standards Reference Rules

#### Lazy Loading Pattern
- Load standards files only when needed for specific tasks
- Cache frequently used standards for performance
- Reference specific sections rather than entire files

#### File Reference Format
```
.ai/standards/architectural/clean-architecture.json
.ai/standards/coding/{{project.language}}/best-practices.json
.ai/templates/{{project.language}}/files/
.ai/prompts/workflow/prd-generation.json
```

### Template and Prompt Integration

#### Code Generation
1. Always use templates from `.ai/templates/{{project.language}}/`
2. Follow naming conventions from language-specific standards
3. Include appropriate tests using testing templates
4. Generate documentation using documentation standards

#### Validation Rules
1. Validate generated code against `.ai/standards/coding/{{project.language}}/`
2. Ensure architectural compliance with `.ai/standards/architectural/`
3. Verify test coverage meets `.ai/standards/testing/` requirements
4. Check documentation completeness against `.ai/standards/documentation/`

### Error Handling and Escalation

#### Standard Violations
- If code violates standards, reference specific standard and provide correction
- Suggest refactoring approaches from `.ai/standards/architectural/`
- Use `.ai/prompts/coding-standards/` for guidance on fixes

#### Complex Decisions
- Use Sequential Thinking MCP for multi-step analysis
- Reference architectural decision records in `.ai/standards/`
- Escalate to human review when standards conflict or are unclear

### Performance and Resource Management

#### MCP Server Optimization
- Use Context7 for external documentation queries
- Use GitHub MCP for repository operations
- Minimize redundant MCP calls through caching
- Batch operations when possible

#### Asset Loading
- Load `.ai` directory assets incrementally
- Cache frequently accessed standards and templates
- Update asset cache when files change in `.ai` directory
```

### 5. Workflow Prompt Templates

#### 5.1 PRD Generation Prompt Template

```json
{
  "name": "prd-generation",
  "version": "1.0.0",
  "description": "Product Requirements Document generation workflow",
  "phase": "requirements",
  "agent": "technical-product-owner",
  "systemPrompt": "You are a technical product owner creating a comprehensive PRD. Use the project context and business requirements to generate detailed product specifications.",
  "workflow": {
    "steps": [
      {
        "step": 1,
        "title": "Business Context Analysis",
        "prompt": "Analyze the business context and objectives for {{project.name}}. Consider the target audience, market needs, and business goals.",
        "inputs": ["business_requirements", "market_analysis"],
        "outputs": ["business_context"]
      },
      {
        "step": 2,
        "title": "Feature Requirements",
        "prompt": "Define the core features and functionality required for {{project.name}}. Prioritize features based on business value and technical feasibility.",
        "inputs": ["business_context", "user_personas"],
        "outputs": ["feature_list", "feature_priorities"]
      },
      {
        "step": 3,
        "title": "Technical Constraints",
        "prompt": "Identify technical constraints, performance requirements, and integration needs for {{project.name}} using {{project.language}} and {{project.frameworks}}.",
        "inputs": ["feature_list", "technical_standards"],
        "outputs": ["technical_constraints", "performance_requirements"]
      },
      {
        "step": 4,
        "title": "Success Metrics",
        "prompt": "Define measurable success criteria and KPIs for {{project.name}}. Include both business and technical metrics.",
        "inputs": ["business_context", "feature_list"],
        "outputs": ["success_metrics", "kpis"]
      }
    ]
  },
  "templates": {
    "output_format": {
      "sections": [
        "Executive Summary",
        "Business Context",
        "User Personas",
        "Feature Requirements",
        "Technical Requirements",
        "Success Metrics",
        "Timeline and Milestones"
      ]
    }
  },
  "validation": {
    "required_sections": ["business_context", "feature_requirements", "technical_requirements"],
    "quality_checks": ["completeness", "clarity", "feasibility"]
  }
}
```

### 6. Integration Validation Framework

#### 6.1 Standards Compliance Validation

```json
{
  "validation": {
    "architectural": {
      "clean_architecture": {
        "check": "layer_dependencies",
        "rule": "domain_has_no_external_deps",
        "severity": "error"
      },
      "dry_principle": {
        "check": "code_duplication",
        "rule": "max_duplication_threshold",
        "threshold": 0.1,
        "severity": "warning"
      }
    },
    "coding_standards": {
      "typescript": {
        "naming_conventions": "error",
        "type_safety": "error",
        "unused_variables": "warning"
      }
    },
    "testing": {
      "coverage": {
        "minimum": 80,
        "severity": "error"
      },
      "test_structure": {
        "pattern": "arrange_act_assert",
        "severity": "warning"
      }
    }
  }
}
```

This standards and templates integration plan provides a comprehensive framework for implementing the requirements.md standards into the technical implementation, ensuring consistency and quality across all generated projects and OpenCode agent interactions.

# Prompt Chain Specifications - SuperClaude Framework Architecture

## 1. Prompt Chain Stage Specifications

### 1.1 Complete Prompt Chain Flow

| Stage | Input | Processing | Output | Context Operations |
|-------|-------|------------|--------|------------------|
| **Idea Definition** | User concept | Critique & enrich | Enriched requirements | Analyze existing implementations |
| **PRD Generation** | Enriched idea | Business analysis | Product requirements | Analyze related features |
| **TRD Creation** | PRD + constraints | Technical planning | Technical requirements | Analyze architecture patterns |
| **Feature Breakdown** | TRD + context | Decomposition | Feature list | Analyze/update dependencies |
| **User Story Creation** | Features + context | Implementation planning | Executable prompts | Analyze/update implementations |

### 1.2 Stage Transition Triggers

| From Stage | To Stage | Trigger Conditions | Context Requirements |
|------------|----------|-------------------|-------------------|
| Idea Definition | PRD | Enriched idea validated | Similar implementations analyzed |
| PRD | TRD | Business requirements complete | Architecture context analyzed |
| TRD | Feature Breakdown | Technical approach approved | Existing features analyzed |
| Feature Breakdown | User Stories | Features decomposed | Dependencies mapped |
| User Stories | Implementation | Stories validated | Implementation context ready |

## 2. Detailed Prompt Chain Stage Specifications

### 2.1 Idea Definition Prompt Specification

**Purpose**: Critique and enrich initial user concepts to elicit comprehensive functional requirements

**Prompt Template**:
```
# Idea Definition and Enrichment

## Current Project Context
{projectContext}

## User's Initial Idea
{userIdea}

## Analysis Framework
1. **Concept Breakdown**: Decompose the idea into core components
2. **Requirement Elicitation**: Ask clarifying questions to expand understanding
3. **Feasibility Assessment**: Evaluate technical and business viability
4. **Context Integration**: Identify related existing implementations
5. **Enhancement Suggestions**: Propose improvements and additional features

## Context-Aware Analysis
Based on existing implementations in project:
- Related Features: {relatedFeatures}
- Reusable Components: {reusableComponents}
- Integration Opportunities: {integrationOpportunities}

## Output Requirements
Generate an enriched idea document that includes:
- Expanded functional requirements
- Clarifying questions for the user
- Feasibility assessment with rationale
- Context integration opportunities
- Enhancement suggestions with business value

## Quality Gates
- Completeness: All aspects of the idea explored
- Feasibility: Technical approach validated
- Context Consistency: Alignment with existing implementations verified
```

**Configuration**:
```json
{
  "stageId": "idea-definition",
  "contextAnalysis": ["project-domain", "technical-constraints"],
  "qualityGates": ["completeness", "feasibility", "context-consistency"],
  "outputFormat": "enriched-idea",
  "nextStage": "prd-generation",
  "agentRequirements": {
    "optional": ["analyzer", "architect"],
    "spawningThreshold": 0.6
  }
}
```

### 2.2 Build Mode

**SuperClaude Configuration**:
```yaml
---
allowed-tools: [Read, Grep, Glob, Bash, TodoWrite, Edit, MultiEdit]
description: "Build projects with intelligent framework detection and optimization"
personas: [frontend, backend, architect]
mcp-servers: [magic, context7, sequential]
wave-enabled: true
complexity-threshold: 0.6
---
```

**OpenCode CLI Implementation**:
```json
{
  "mode": {
    "build": {
      "prompt": "{file:./prompts/build.txt}",
      "tools": {
        "read": true,
        "bash": true,
        "glob": true,
        "write": true,
        "edit": true
      },
      "mcpServers": ["magic", "context7", "sequential"],
      "metadata": {
        "personas": ["frontend", "backend", "architect"],
        "complexityThreshold": 0.6,
        "waveEnabled": true,
        "autoActivation": {
          "fileExtensions": [".json", ".js", ".ts", ".py", ".go"],
          "files": ["package.json", "Makefile", "Dockerfile", "pyproject.toml"],
          "keywords": ["build", "compile", "bundle", "deploy"]
        }
      }
    }
  }
}
```

### 2.3 Implement Mode

**SuperClaude Configuration**:
```yaml
---
allowed-tools: [Read, Write, Edit, Glob, Grep, TodoWrite, Task]
description: "Feature implementation with intelligent persona activation"
personas: [frontend, backend, architect, security, scribe]
mcp-servers: [sequential, context7, magic]
wave-enabled: true
complexity-threshold: 0.7
---
```

**OpenCode CLI Implementation**:
```json
{
  "mode": {
    "implement": {
      "prompt": "{file:./prompts/implement.txt}",
      "tools": {
        "read": true,
        "write": true,
        "edit": true,
        "bash": true,
        "glob": true,
        "grep": true
      },
      "mcpServers": ["sequential", "context7", "magic"],
      "metadata": {
        "personas": ["frontend", "backend", "architect", "security"],
        "complexityThreshold": 0.7,
        "waveEnabled": true,
        "autoActivation": {
          "keywords": ["implement", "feature", "add", "create", "develop"],
          "contextPatterns": ["new feature", "enhancement", "functionality"]
        }
      }
    }
  }
}
```

## 3. Persona Mapping and Auto-Activation

### 3.1 Persona Equivalents

| SuperClaude Persona | OpenCode CLI Mode Preference | Activation Triggers |
|-------------------|----------------------------|-------------------|
| **Frontend** | `build`, `implement`, `design` | `.js`, `.jsx`, `.ts`, `.tsx`, `/components/`, "react", "vue" |
| **Backend** | `implement`, `analyze`, `build` | `.py`, `.go`, `.rs`, `/api/`, "server", "database" |
| **Security** | `analyze`, `implement`, `review` | `/auth/`, "security", "vulnerability", "jwt" |
| **Performance** | `analyze`, `improve`, `build` | "optimize", "performance", "benchmark", "cache" |
| **Architect** | `design`, `analyze`, `workflow` | "architecture", "design", "system", "pattern" |
| **Analyzer** | `analyze`, `debug`, `review` | "analyze", "investigate", "examine", "study" |
| **Scribe** | `docs`, `explain`, `review` | `.md`, `/docs/`, "document", "readme", "explain" |

### 3.2 Auto-Activation Scoring Implementation

```json
{
  "personaActivation": {
    "scoringAlgorithm": {
      "keywordMatching": {
        "weight": 0.3,
        "patterns": {
          "frontend": ["component", "react", "vue", "angular", "ui", "responsive"],
          "backend": ["api", "server", "database", "service", "endpoint"],
          "security": ["auth", "security", "vulnerability", "encryption", "jwt"],
          "performance": ["optimize", "performance", "speed", "cache", "benchmark"]
        }
      },
      "contextAnalysis": {
        "weight": 0.4,
        "fileExtensions": {
          "frontend": [".js", ".jsx", ".ts", ".tsx", ".vue", ".svelte"],
          "backend": [".py", ".go", ".rs", ".java", ".php"],
          "config": [".json", ".yaml", ".toml", ".env"]
        },
        "directoryPatterns": {
          "frontend": ["/components/", "/pages/", "/ui/", "/views/"],
          "backend": ["/api/", "/server/", "/services/", "/models/"],
          "security": ["/auth/", "/security/", "/middleware/"],
          "docs": ["/docs/", "/documentation/"]
        }
      },
      "userHistory": {
        "weight": 0.2,
        "trackPreferences": true,
        "adaptToPatterns": true,
        "successRateInfluence": 0.15
      },
      "performanceMetrics": {
        "weight": 0.1,
        "systemLoad": true,
        "responseTime": true,
        "resourceUsage": true
      }
    },
    "activationThresholds": {
      "autoActivate": 0.85,
      "suggest": 0.70,
      "neutral": 0.50
    }
  }
}
```

## 4. MCP Server Coordination Mapping

### 4.1 Server-to-Mode Affinity Matrix

| MCP Server | Primary Modes | Secondary Modes | Capabilities |
|-----------|---------------|-----------------|--------------|
| **Context7** | `build`, `docs`, `explain` | `analyze`, `implement` | Documentation, research, patterns |
| **Sequential** | `analyze`, `debug`, `workflow` | `implement`, `design` | Multi-step reasoning, complex analysis |
| **Magic** | `implement`, `design`, `build` | `improve` | UI components, design systems |
| **Playwright** | `test`, `analyze` | `build`, `implement` | E2E testing, automation, performance |

### 4.2 Server Selection Logic

```json
{
  "mcpServerSelection": {
    "selectionCriteria": {
      "taskAffinity": {
        "weight": 0.4,
        "mappings": {
          "analyze": ["sequential", "context7"],
          "build": ["magic", "context7", "sequential"],
          "implement": ["sequential", "context7", "magic"],
          "design": ["magic", "sequential", "context7"],
          "test": ["playwright", "sequential"],
          "docs": ["context7", "sequential"]
        }
      },
      "performance": {
        "weight": 0.3,
        "metrics": {
          "responseTime": {"threshold": 2000, "weight": 0.4},
          "successRate": {"threshold": 0.95, "weight": 0.4},
          "availability": {"threshold": 0.99, "weight": 0.2}
        }
      },
      "context": {
        "weight": 0.2,
        "factors": {
          "currentMode": 0.4,
          "activePersona": 0.3,
          "sessionState": 0.2,
          "userPreferences": 0.1
        }
      },
      "loadDistribution": {
        "weight": 0.1,
        "maxConcurrent": 3,
        "balancingEnabled": true,
        "queueingStrategy": "priority"
      }
    }
  }
}
```

## 5. Quality Gates Mapping

### 5.1 SuperClaude Quality Gates

```yaml
quality_gates:
  step_1_syntax: "language parsers, Context7 validation"
  step_2_type: "Sequential analysis, type compatibility"
  step_3_lint: "Context7 rules, quality analysis"
  step_4_security: "Sequential analysis, vulnerability assessment"
  step_5_test: "Playwright E2E, coverage analysis"
  step_6_performance: "Sequential analysis, benchmarking"
  step_7_documentation: "Context7 patterns, completeness validation"
  step_8_integration: "Playwright testing, deployment validation"
```

### 5.2 OpenCode CLI Quality Gates Implementation

```json
{
  "qualityGates": {
    "gateDefinitions": {
      "syntax": {
        "tools": ["read", "bash"],
        "mcpServers": ["context7"],
        "threshold": 0.95,
        "modes": ["analyze", "build", "implement"]
      },
      "type": {
        "tools": ["read", "bash"],
        "mcpServers": ["sequential"],
        "threshold": 0.90,
        "modes": ["implement", "build"]
      },
      "lint": {
        "tools": ["bash", "read"],
        "mcpServers": ["context7"],
        "threshold": 0.85,
        "modes": ["analyze", "implement", "build"]
      },
      "security": {
        "tools": ["grep", "bash"],
        "mcpServers": ["sequential"],
        "threshold": 0.95,
        "modes": ["analyze", "implement"]
      },
      "test": {
        "tools": ["bash", "read"],
        "mcpServers": ["playwright"],
        "threshold": 0.80,
        "modes": ["test", "implement", "build"]
      },
      "performance": {
        "tools": ["bash", "read"],
        "mcpServers": ["sequential"],
        "threshold": 0.75,
        "modes": ["analyze", "build"]
      },
      "documentation": {
        "tools": ["read", "write"],
        "mcpServers": ["context7"],
        "threshold": 0.70,
        "modes": ["docs", "implement"]
      },
      "integration": {
        "tools": ["bash", "read"],
        "mcpServers": ["playwright"],
        "threshold": 0.85,
        "modes": ["build", "test"]
      }
    },
    "modeSpecificGates": {
      "analyze": ["syntax", "lint", "security", "performance"],
      "build": ["syntax", "type", "lint", "test", "integration"],
      "implement": ["syntax", "type", "lint", "security", "test", "documentation"],
      "design": ["documentation", "lint"],
      "test": ["syntax", "test", "integration"],
      "docs": ["syntax", "documentation"],
      "debug": ["syntax", "lint"],
      "workflow": ["syntax", "documentation", "integration"]
    }
  }
}
```

## 6. Flag and Modifier Mappings

### 6.1 SuperClaude Flags to OpenCode CLI Options

| SuperClaude Flag | OpenCode CLI Equivalent | Purpose |
|-----------------|------------------------|---------|
| `--focus <domain>` | `--persona <domain>` | Force specific persona activation |
| `--wave-mode` | `--multi-stage` | Enable multi-stage execution |
| `--single-wave` | `--single-pass` | Disable multi-stage execution |
| `--c7` | `--context7` | Prefer Context7 MCP server |
| `--sequential` | `--sequential` | Prefer Sequential MCP server |
| `--magic` | `--magic` | Prefer Magic MCP server |
| `--playwright` | `--playwright` | Prefer Playwright MCP server |
| `--quality-gates` | `--validate` | Enable quality gate validation |
| `--no-validation` | `--skip-validation` | Disable quality gates |

### 6.2 Implementation Example

```json
{
  "flagMappings": {
    "--persona": {
      "type": "string",
      "values": ["frontend", "backend", "security", "performance", "architect"],
      "effect": "forcePersonaActivation"
    },
    "--multi-stage": {
      "type": "boolean",
      "effect": "enableWaveMode"
    },
    "--context7": {
      "type": "boolean", 
      "effect": "preferMcpServer",
      "server": "context7"
    },
    "--validate": {
      "type": "boolean",
      "effect": "enableQualityGates"
    }
  }
}
```

---

*This mapping document provides the complete translation matrix for converting SuperClaude's command system to OpenCode CLI's mode-based architecture while preserving all functionality and intelligent behavior.*

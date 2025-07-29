# Technical Requirements - SuperClaude Framework Prompt Chain Architecture

## 1. Core Prompt Chain Architecture Requirements

### 1.1 5-Stage Prompt Chain System

**Prompt Chain Flow**:
```
User Idea → Idea Definition → PRD → TRD → Feature Breakdown → User Stories → Implementation
```

**OpenCode CLI Requirement**: Create progressive prompt chain system with context analysis and agent spawning capabilities.

### 1.2 5-Step Processing Pipeline Integration

The original 5-step pipeline applies within each prompt chain stage:

#### Step 1: Input Parsing
- **Requirements**:
  - Parse prompt chain stage inputs and context
  - Extract project context and requirements
  - Process agent spawning requirements and coordination flags
  - Handle cross-stage dependencies and references

#### Step 2: Context Resolution
- **Requirements**:
  - Automatic agent selection based on prompt chain stage and context
  - Analyze project context and technical requirements
  - Activate appropriate agent behaviors and specializations
  - Select optimal MCP servers for current stage requirements

#### Step 3: Wave Eligibility Assessment
- **Requirements**:
  - Complexity scoring algorithm for prompt chain stages
  - Multi-factor assessment (stage complexity, project scope, agent coordination)
  - Configurable thresholds per prompt chain stage
  - Context-aware wave mode determination

#### Step 4: Execution Strategy
- **Requirements**:
  - Dynamic agent spawning based on prompt chain stage and context
  - MCP server coordination through spawned agents
  - Context-driven execution planning
  - Cross-agent communication and result aggregation

#### Step 5: Quality Gates
- **Requirements**:
  - 8-step validation framework applied at appropriate chain stages
  - Context validation and consistency checking
  - Agent coordination validation and result verification
  - Progressive quality enhancement across prompt chain stages

### 1.3 Prompt Chain Stage Metadata Structure

**Prompt Chain Stage Configuration**:
```json
{
  "stageId": "feature-breakdown",
  "description": "Decompose TRD into implementable features with context analysis",
  "requiredInputs": ["trd", "project-context"],
  "outputFormat": "feature-list",
  "agentRequirements": {
    "primary": ["architect", "analyzer"],
    "optional": ["frontend", "backend", "security"],
    "spawningCriteria": "complexity-based"
  },
  "mcpServers": ["sequential", "context7"],
  "contextAnalysis": ["project-scope", "technical-requirements", "dependencies"],
  "qualityGates": ["syntax", "completeness", "dependency-validation"],
  "waveEnabled": true,
  "complexityThreshold": 0.6
}
```

**OpenCode CLI Requirement**: Implement prompt chain stage system with:
- Context-aware input/output specifications
- Agent spawning requirements and criteria
- MCP server coordination per stage
- Quality gate integration points
- Cross-stage dependency management

## 2. Agent-Based Persona System

### 2.1 Agent Spawning Multi-Factor Scoring Algorithm

**Technical Requirements**:
- **Prompt Chain Stage Analysis (40% weight)**: Stage-specific agent requirements
- **Content Analysis (35% weight)**: Technical domain and complexity assessment
- **Project Context Analysis (15% weight)**: Current project scope and requirements
- **User Preferences (10% weight)**: User-specified agent preferences and overrides

### 2.2 Agent Spawning Engine Implementation

```
Agent_Score = (Stage_Score * 0.40) + (Content_Score * 0.35) + (Context_Score * 0.15) + (Preference_Score * 0.10)

If Agent_Score >= 0.85: Auto-spawn agent
If Agent_Score >= 0.70: Suggest agent spawning
If Agent_Score < 0.70: Use orchestrator only
```

### 2.3 Agent Spawning Triggers and Capabilities

**Frontend Agent**:
- **Spawning Triggers**: UI components, responsive design, accessibility requirements
- **Capabilities**: React/Vue/Angular patterns, design systems, component architecture
- **Context Analysis**: Frontend frameworks, UI requirements, design specifications
- **MCP Servers**: Magic (primary), Context7 (patterns)

**Backend Agent**:
- **Spawning Triggers**: API development, database design, service architecture
- **Capabilities**: REST/GraphQL APIs, database optimization, microservices patterns
- **Context Analysis**: Backend frameworks, API requirements, data architecture
- **MCP Servers**: Sequential (primary), Context7 (patterns)

**Security Agent**:
- **Spawning Triggers**: Authentication, authorization, vulnerability assessment
- **Capabilities**: Security patterns, compliance checking, threat modeling
- **Context Analysis**: Security requirements, compliance standards, threat landscape
- **MCP Servers**: Sequential (primary), Context7 (security patterns)

**Performance Agent**:
- **Spawning Triggers**: Optimization requirements, performance bottlenecks, scalability
- **Capabilities**: Performance profiling, optimization strategies, caching patterns
- **Context Analysis**: Performance requirements, scalability needs, optimization targets
- **MCP Servers**: Sequential (primary), Playwright (performance testing)

## 3. MCP Server Selection and Agent Coordination

### 3.1 Agent-MCP Server Coordination Algorithm

**Priority Matrix for Agent-Server Pairing**:
1. **Agent-Server Affinity**: Match spawned agents to optimal servers based on specialization
2. **Project Context**: Current project requirements and technical constraints
3. **Performance Metrics**: Server response time, success rate, agent coordination efficiency
4. **Load Distribution**: Balance server load across multiple spawned agents
5. **Fallback Readiness**: Maintain backup servers for critical agent operations

**Selection Process**: Agent Analysis → Context Analysis → Server Capability Match → Performance Check → Load Assessment → Final Pairing

### 3.2 Agent-Server Capability Matrix

**Context7 Integration**:
- **Primary Agents**: Frontend, Backend, Architect
- **Purpose**: Documentation research, library patterns, implementation examples
- **Context Integration**: Analyze project requirements and technology stack
- **Workflow**: Context Analysis → Library Detection → ID Resolution → Documentation Retrieval → Pattern Extraction → Implementation

**Sequential Integration**:
- **Primary Agents**: Analyzer, Security, Performance, Architect
- **Purpose**: Multi-step problem solving, systematic analysis, complex reasoning
- **Context Integration**: Track analysis patterns and solution strategies
- **Workflow**: Context Analysis → Problem Decomposition → Systematic Analysis → Step-by-step Reasoning → Solution Synthesis

**Magic Integration**:
- **Primary Agents**: Frontend, Designer
- **Purpose**: UI component generation, design systems, modern frontend patterns
- **Context Integration**: Analyze design requirements and component specifications
- **Workflow**: Context Analysis → Requirement Parsing → Pattern Search → Framework Detection → Code Generation → Design Integration

**Playwright Integration**:
- **Primary Agents**: Tester, Performance, Quality Assurance
- **Purpose**: E2E testing, performance monitoring, browser automation, quality validation
- **Context Integration**: Analyze testing requirements and performance targets
- **Workflow**: Context Analysis → Test Planning → E2E Automation → Performance Monitoring → Visual Testing

### 3.3 Agent Coordination and Load Balancing

**Requirements**:
- Multi-agent coordination with context sharing
- Server health monitoring across all spawned agents
- Intelligent queuing system for agent-server interactions
- Graceful degradation when servers are unavailable to specific agents
- Cross-agent communication and result aggregation
- Context consistency across concurrent agent operations

## 4. Prompt Chain Wave System and Complexity Assessment

### 4.1 Context-Aware Wave Detection Algorithm

**Scoring Factors**:
- **Prompt Chain Complexity (0.35 weight)**: Stage complexity and cross-stage dependencies
- **Agent Coordination (0.25 weight)**: Number of agents required and coordination complexity
- **Implementation Scale (0.2 weight)**: Number of features, components, and files involved
- **Project Context (0.15 weight)**: Project scope, technical constraints, and requirements
- **Quality Requirements (0.05 weight)**: Number of quality gates and validation requirements

**Decision Logic**:
```
Wave_Score = Chain_Complexity * 0.35 + Agent_Coordination * 0.25 + Implementation_Scale * 0.2 + Project_Context * 0.15 + Quality_Requirements * 0.05

If Wave_Score >= 0.7: Enable Wave Mode (multi-stage execution with validation checkpoints)
If Wave_Score < 0.7: Standard Execution (single-pass execution)
```

### 4.2 Context-Integrated Wave Execution Strategies

**Progressive Waves**: Incremental enhancement with validation checkpoints
**Context-Driven Waves**: Build upon project context and requirements analysis
**Agent-Coordinated Waves**: Multi-agent execution with coordinated context sharing
**Validation Waves**: Quality-focused with comprehensive validation checking

## 5. Prompt Chain Stage Specifications

### 5.1 Stage 1: Idea Definition Prompt

**Purpose**: Critique and enrich initial user concepts to elicit comprehensive functional requirements

**Input Requirements**:
- User's initial idea or concept
- Basic context about the project or domain

**Processing Logic**:
1. **Context Analysis**: Analyze project domain and technical context
2. **Concept Analysis**: Break down the idea into core components
3. **Requirement Elicitation**: Ask clarifying questions to expand the concept
4. **Feasibility Assessment**: Evaluate technical and business feasibility
5. **Enhancement Suggestions**: Propose improvements and additional features

**Output Format**:
```json
{
  "enrichedIdea": {
    "originalConcept": "User's initial idea",
    "expandedRequirements": ["requirement1", "requirement2"],
    "clarifyingQuestions": ["question1", "question2"],
    "feasibilityAssessment": "high|medium|low",
    "enhancementSuggestions": ["suggestion1", "suggestion2"],
    "projectContext": {
      "domain": "web-application",
      "technicalConstraints": ["constraint1", "constraint2"],
      "scope": "medium"
    }
  }
}
```

### 5.2 Stage 2: Product Requirements Document (PRD) Prompt

**Purpose**: Transform enriched ideas into structured business requirements and user needs

**Input Requirements**:
- Enriched idea from Stage 1
- Project context and domain analysis
- Business context and constraints

**Processing Logic**:
1. **Context Integration**: Incorporate project context and constraints
2. **User Story Generation**: Create user-focused requirement statements
3. **Business Value Assessment**: Define success metrics and KPIs
4. **Constraint Identification**: Technical, business, and resource constraints
5. **Priority Ranking**: Prioritize requirements by business value and complexity

**Output Format**:
```json
{
  "prd": {
    "projectOverview": "High-level project description",
    "userStories": ["As a user, I want...", "As an admin, I need..."],
    "businessRequirements": ["requirement1", "requirement2"],
    "successMetrics": ["metric1", "metric2"],
    "constraints": ["constraint1", "constraint2"],
    "priorities": {"high": ["req1"], "medium": ["req2"], "low": ["req3"]},
    "contextDependencies": ["existing-system-1", "integration-point-2"]
  }
}
```

### 5.3 Stage 3: Technical Requirements Document (TRD) Prompt

**Purpose**: Combine PRD with technical constraints, architecture patterns, and implementation details

**Input Requirements**:
- PRD from Stage 2
- Project context and existing technical implementations
- Technology stack and architectural constraints

**Processing Logic**:
1. **Architecture Analysis**: Review project architecture and technical context
2. **Technology Stack Integration**: Align with project technology choices and constraints
3. **Architecture Pattern Selection**: Choose appropriate patterns based on context and requirements
4. **Technical Constraint Mapping**: Map business requirements to technical specifications
5. **Agent Requirement Analysis**: Determine which agents will be needed for implementation

**Output Format**:
```json
{
  "trd": {
    "technicalOverview": "System architecture and technology approach",
    "technologyStack": ["React", "Node.js", "PostgreSQL"],
    "architecturePatterns": ["MVC", "Repository Pattern", "Observer"],
    "technicalRequirements": ["requirement1", "requirement2"],
    "performanceRequirements": ["<200ms response time", ">99% uptime"],
    "securityRequirements": ["JWT authentication", "HTTPS encryption"],
    "integrationPoints": ["existing-api-1", "existing-service-2"],
    "requiredAgents": ["frontend", "backend", "security"],
    "contextIntegrations": ["existing-auth-system", "existing-database-schema"]
  }
}
```

### 5.4 Stage 4: Feature Breakdown Prompt

**Purpose**: Decompose TRD into independent, isolated, implementable features with context awareness

**Input Requirements**:
- TRD from Stage 3
- Project context and existing implementations
- Dependency analysis from project context

**Processing Logic**:
1. **Context Dependency Analysis**: Identify existing features and integration points
2. **Feature Decomposition**: Break TRD into atomic, implementable features
3. **Dependency Mapping**: Map dependencies between new and existing features
4. **Implementation Priority**: Order features based on dependencies and business value
5. **Agent Assignment**: Assign appropriate agents to each feature based on complexity

**Output Format**:
```json
{
  "featureBreakdown": {
    "features": [
      {
        "id": "feature-uuid",
        "name": "User Authentication",
        "description": "Implement user login and registration",
        "dependencies": ["existing-database-schema"],
        "newDependencies": ["password-hashing"],
        "estimatedComplexity": "medium",
        "requiredAgents": ["security", "backend"],
        "contextReuse": ["existing-user-model", "existing-validation"]
      }
    ],
    "implementationOrder": ["feature-1", "feature-2", "feature-3"],
    "riskAssessment": {"high": [], "medium": ["feature-1"], "low": ["feature-2"]}
  }
}
```

### 5.5 Stage 5: User Story Prompts

**Purpose**: Generate final executable prompts that implement individual features with complete context

**Input Requirements**:
- Feature breakdown from Stage 4
- Project context and existing implementations
- Agent assignments and MCP server requirements

**User Story Prompt Structure**:
```
# User Story: {Feature Name}

## Role Definition
You are a {AgentType} agent specializing in {Domain} with access to {MCPServers}.

## Goal Statement
Implement {FeatureName} that {SpecificObjective} while integrating with existing {ExistingComponents}.

## Project Context
Current Implementation:
- {ExistingFeature1}: {Status} - {FilePaths}
- {ExistingFeature2}: {Status} - {Components}

Available Components:
- {Component1}: {Location} - {Interface}
- {Component2}: {Location} - {Capabilities}

## Step-by-Step Execution Plan
1. **Context Analysis**: Analyze existing implementations and integration points
2. **Integration Planning**: Plan integration with existing features
3. **Implementation**: {SpecificImplementationSteps}
4. **Testing**: {TestingRequirements}
5. **Documentation**: Update documentation with new implementation

## Concrete Examples
Input Example: {SampleInput}
Expected Output: {SampleOutput}
Edge Cases: {EdgeCase1}, {EdgeCase2}
Integration Patterns: {ExistingPatterns}

## Acceptance Criteria
- [ ] Feature implements {SpecificRequirement}
- [ ] Integrates successfully with {ExistingFeature}
- [ ] Passes {QualityGates}
- [ ] Context analysis validates implementation approach
- [ ] Documentation updated with new feature

## Quality Gates
Required: {RequiredGates}
Optional: {OptionalGates}
Context Validation: {ContextConsistencyChecks}
```

## 6. Prompt Chain Quality Gates Integration

### 6.1 Stage-Specific Quality Gate Application

**Idea Definition Stage**:
- **Completeness Gate**: Verify all aspects of the idea are explored
- **Feasibility Gate**: Validate technical and business feasibility
- **Context Consistency Gate**: Check alignment with project context

**PRD Stage**:
- **Requirements Completeness Gate**: Ensure all user needs are captured
- **Business Value Gate**: Validate success metrics and KPIs
- **Context Integration Gate**: Verify compatibility with project constraints

**TRD Stage**:
- **Technical Feasibility Gate**: Validate technical approach and constraints
- **Architecture Consistency Gate**: Ensure alignment with project architecture
- **Agent Requirement Gate**: Verify appropriate agent assignments

**Feature Breakdown Stage**:
- **Decomposition Completeness Gate**: Ensure features are properly isolated
- **Dependency Validation Gate**: Verify dependency mappings are correct
- **Implementation Readiness Gate**: Confirm features are ready for implementation

**User Story Stage**:
- **All 8 Traditional Gates**: Syntax, Type, Lint, Security, Test, Performance, Documentation, Integration
- **Context Validation Gate**: Ensure context analysis is consistent and accurate
- **Agent Coordination Gate**: Verify successful agent spawning and coordination

### 6.2 Context-Integrated Quality Gate Implementation

**Requirements**:
- Context consistency validation at each quality gate
- Project context validation throughout implementation
- Agent coordination validation with project context
- Progressive quality enhancement with context awareness
- Comprehensive reporting with context impact analysis

## 8. Performance Requirements

### 7.1 Prompt Chain Performance Targets

- **Context Analysis Operations**: < 100ms for project context analysis
- **Agent Spawning**: < 500ms for agent initialization
- **Prompt Chain Stage Transition**: < 200ms between stages
- **Quality Gate Execution**: < 300ms per validation gate
- **Cross-Agent Communication**: < 300ms for coordination

### 7.2 Agent Coordination Performance

- **Agent Selection**: < 100ms for multi-factor scoring
- **MCP Server Coordination**: < 200ms for server selection and pairing
- **Context Sharing**: < 150ms for context distribution across agents
- **Result Aggregation**: < 250ms for collecting and synthesizing agent results
- **Quality Validation**: < 200ms for context consistency checks

## 8. Prompt Chain Configuration Requirements

### 8.1 Prompt Chain Stage Configuration

```json
{
  "promptChain": {
    "stages": {
      "ideaDefinition": {
        "prompt": "{file:./prompts/idea-definition.txt}",
        "contextAnalysis": ["project-domain", "technical-constraints"],
        "qualityGates": ["completeness", "feasibility", "context-consistency"],
        "outputFormat": "enriched-idea",
        "nextStage": "prdGeneration"
      },
      "prd": {
        "prompt": "{file:./prompts/prd-generation.txt}",
        "contextAnalysis": ["business-requirements", "project-scope"],
        "qualityGates": ["requirements-completeness", "business-value", "context-integration"],
        "outputFormat": "product-requirements",
        "nextStage": "trdCreation"
      },
      "userStory": {
        "prompt": "{file:./prompts/user-story-template.txt}",
        "contextAnalysis": ["implementation-context", "integration-points"],
        "agentSpawning": true,
        "qualityGates": ["syntax", "security", "test", "context-validation"],
        "outputFormat": "implementation-complete"
      }
    }
  }
}
```

### 8.2 Agent Coordination Configuration

```json
{
  "agentCoordination": {
    "maxConcurrentAgents": 4,
    "communicationProtocol": "context-based",
    "conflictResolution": "orchestrator-mediated",
    "resultAggregation": "sequential",
    "contextSharing": true,
    "performanceMonitoring": true
  }
}
```

---

*This document provides the detailed technical specifications required for implementing SuperClaude's prompt chain architecture with agent-based execution in OpenCode CLI.*

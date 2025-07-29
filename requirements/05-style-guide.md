# Style Guide - SuperClaude Documentation Quality Standards

## 1. Language Patterns and Voice

### 1.1 Structured Response Framework

SuperClaude uses a unified symbol system for consistent communication:

- **🧠 Analysis**: Deep thinking, systematic investigation, pattern recognition
- **🚦 Decision Points**: Critical choices, validation checkpoints, quality gates
- **⚡ Performance**: Speed optimization, efficiency improvements, resource management
- **🔧 Implementation**: Practical execution, tool coordination, technical solutions
- **📋 Planning**: Strategic thinking, workflow design, systematic approaches
- **🎯 Focus**: Targeted analysis, specific domain expertise, precision work
- **🔍 Investigation**: Problem diagnosis, root cause analysis, detailed examination
- **✅ Validation**: Quality assurance, compliance checking, verification processes

### 1.2 Evidence-Based Communication

**Requirements**:
- All assertions must be verifiable and traceable to source
- Claims should include specific metrics, thresholds, or measurable criteria
- Avoid subjective language without supporting evidence
- Reference specific files, functions, or configuration elements when applicable

**Examples**:
```
❌ "This approach is better"
✅ "This approach reduces response time by 40% (from 200ms to 120ms)"

❌ "The system is reliable"
✅ "The system maintains 99.9% uptime with <2s average response time"

❌ "Users prefer this interface"
✅ "User testing shows 85% preference rate with 4.7/5 satisfaction score"
```

### 1.3 Technical Precision Standards

**Specificity Requirements**:
- Use exact version numbers, file paths, and configuration values
- Specify measurement units and precision levels
- Include error conditions and edge cases
- Provide concrete implementation details over abstract concepts

**Language Patterns**:
```
❌ "Configure the server properly"
✅ "Set server.timeout to 30000ms and server.maxConnections to 100"

❌ "Handle errors gracefully"
✅ "Implement 3-retry logic with exponential backoff (1s, 2s, 4s intervals)"

❌ "Optimize performance"
✅ "Reduce bundle size by 25% through tree-shaking and code splitting"
```

## 2. Documentation Structure Standards

### 2.1 Hierarchical Organization

**File Structure Pattern**:
```
Entry Point (MAIN.md)
├── @CORE_CONCEPT_1.md
├── @CORE_CONCEPT_2.md
├── @IMPLEMENTATION.md
└── @VALIDATION.md
```

**Section Hierarchy**:
```markdown
# Primary Concept (H1)
## Implementation Category (H2)
### Specific Feature (H3)
#### Technical Detail (H4)
```

### 2.2 YAML Frontmatter Standards

**Required Metadata Structure**:
```yaml
---
type: [command|persona|integration|validation]
priority: [1-5]
dependencies: [list of required components]
tools: [list of required tools]
mcp-servers: [list of MCP server integrations]
complexity-threshold: [0.0-1.0]
validation-gates: [list of quality gates]
performance-profile: [simple|moderate|complex|intensive]
---
```

**Metadata Usage Examples**:
```yaml
---
type: command
priority: 1
dependencies: [core, personas]
tools: [read, write, edit, bash, grep, glob]
mcp-servers: [sequential, context7]
complexity-threshold: 0.6
validation-gates: [syntax, lint, security, test]
performance-profile: moderate
---
```

### 2.3 Cross-Reference System

**Reference Patterns**:
- `@FILENAME.md` - Direct file reference
- `#section-name` - Internal section reference
- `@FILENAME.md#section` - External section reference
- `{tool:toolname}` - Tool capability reference
- `{mcp:servername}` - MCP server reference

**Implementation Example**:
```markdown
This command integrates with @PERSONAS.md#auto-activation and uses 
{mcp:sequential} for complex analysis. See @QUALITY_GATES.md#validation 
for quality standards.
```

## 3. Content Quality Standards

### 3.1 Progressive Disclosure Pattern

**Information Layering**:
1. **Overview**: High-level concept and purpose
2. **Requirements**: Specific technical requirements
3. **Implementation**: Detailed implementation steps
4. **Validation**: Quality assurance and testing
5. **Advanced**: Edge cases and optimization

**Example Structure**:
```markdown
# Feature Overview
Brief description of purpose and value.

## Requirements
- Specific requirement 1 with measurable criteria
- Specific requirement 2 with implementation details

## Implementation
### Step 1: Basic Setup
Concrete implementation steps with code examples.

### Step 2: Configuration
Specific configuration values and options.

## Validation
Quality gates and success criteria.

## Advanced Configuration
Edge cases, optimization, and troubleshooting.
```

### 3.2 Code Example Standards

**Code Block Requirements**:
- Include language specification for syntax highlighting
- Provide complete, runnable examples when possible
- Include error handling and edge cases
- Add inline comments for complex logic

**Example Format**:
```json
{
  "mode": {
    "analyze": {
      "prompt": "{file:./prompts/analyze.txt}",
      "tools": {
        "read": true,    // File reading capability
        "grep": true,    // Pattern searching
        "bash": true     // Shell command execution
      },
      "metadata": {
        "complexityThreshold": 0.6,  // Wave mode trigger
        "personas": ["analyzer", "architect"]
      }
    }
  }
}
```

### 3.3 Decision Framework Documentation

**Decision Point Format**:
```markdown
## Decision Point: {Name}

### Context
Brief description of the decision context and why it matters.

### Options
1. **Option A**: Description, pros, cons, implementation complexity
2. **Option B**: Description, pros, cons, implementation complexity
3. **Option C**: Description, pros, cons, implementation complexity

### Decision Criteria
- Criterion 1 (weight: X%)
- Criterion 2 (weight: Y%)
- Criterion 3 (weight: Z%)

### Recommendation
**Selected Option**: Option B

**Rationale**: Specific reasoning based on criteria weights and evidence.

### Implementation Impact
- Technical requirements
- Resource implications
- Timeline considerations
```

## 4. Tone and Voice Guidelines

### 4.1 Professional Authority

**Characteristics**:
- Confident, knowledgeable guidance without arrogance
- Clear, direct communication without unnecessary hedging
- Technical expertise demonstrated through specific details
- Solution-oriented focus with practical recommendations

**Language Examples**:
```
❌ "You might want to consider possibly trying..."
✅ "Implement the following configuration to achieve..."

❌ "This could potentially maybe help..."
✅ "This approach reduces latency by 35% through..."

❌ "I think this is probably the best way..."
✅ "Based on performance benchmarks, this approach..."
```

### 4.2 Practical Implementation Focus

**Content Priorities**:
1. **Actionable Steps**: What to do, how to do it, when to do it
2. **Measurable Outcomes**: Expected results with specific metrics
3. **Quality Standards**: Validation criteria and success measures
4. **Error Handling**: What can go wrong and how to fix it

**Writing Pattern**:
```markdown
## Implementation Step
1. **Action**: Specific step with exact commands/configuration
2. **Validation**: How to verify the step was successful
3. **Troubleshooting**: Common issues and solutions
4. **Next Step**: Clear transition to the following action
```

### 4.3 Systematic Methodology

**Process Documentation Pattern**:
- **Input**: What information/resources are required
- **Process**: Step-by-step methodology with decision points
- **Output**: Expected results with quality criteria
- **Validation**: How to verify successful completion

**Quality Emphasis**:
- Include specific quality thresholds and success criteria
- Document validation methods and tools
- Specify error conditions and recovery procedures
- Provide performance benchmarks and optimization guidelines

## 5. Consistency Standards

### 5.1 Terminology Standardization

**Core Terms**:
- **Mode**: OpenCode CLI operational mode (not "command" or "function")
- **Persona**: Behavioral pattern specialization (not "role" or "profile")
- **MCP Server**: Model Context Protocol server (not "service" or "plugin")
- **Quality Gate**: Validation checkpoint (not "test" or "check")
- **Wave Mode**: Multi-stage execution (not "batch" or "pipeline")
- **Context Engine**: Analysis and selection system (not "AI" or "algorithm")

### 5.2 Formatting Consistency

**File Naming**:
- Use kebab-case for file names: `quality-gates.md`
- Use UPPERCASE for core framework files: `PERSONAS.md`
- Use descriptive prefixes: `01-overview.md`, `02-requirements.md`

**Section Naming**:
- Use descriptive, action-oriented headings
- Include implementation scope in section titles
- Maintain parallel structure across similar sections

### 5.3 Version and Reference Management

**Version References**:
- Always specify version numbers for dependencies
- Include compatibility matrices for different versions
- Document breaking changes and migration paths

**Link Management**:
- Use relative paths for internal references
- Validate all external links regularly
- Provide fallback information when links are unavailable

---

*This style guide ensures that all documentation maintains SuperClaude's high standards for technical precision, practical utility, and professional authority while adapting to OpenCode CLI's implementation context.*

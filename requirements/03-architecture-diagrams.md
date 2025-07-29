# Architecture Diagrams - SuperClaude Framework Prompt Chain Architecture

## 1. Prompt Chain Architecture Overview

```mermaid
graph TD
    A[User Idea] --> B[Idea Definition Prompt]
    B --> C[Context Analysis]
    C --> D[PRD Generation Prompt]
    D --> E[TRD Creation Prompt]
    E --> F[Feature Breakdown Prompt]
    F --> G[User Story Prompts]
    G --> H[Agent Spawning]
    H --> I[Implementation]
    I --> J[Quality Validation]

    K[Project Context] --> C
    K --> D
    K --> E
    K --> F
    K --> G

    L[Quality Gates] --> B
    L --> D
    L --> E
    L --> F
    L --> G
    L --> J

    M[Agent Pool] --> H
    N[Frontend Agent] --> M
    O[Backend Agent] --> M
    P[Security Agent] --> M
    Q[Performance Agent] --> M

    R[MCP Servers] --> H
    S[Context7] --> R
    T[Sequential] --> R
    U[Magic] --> R
    V[Playwright] --> R

    style A fill:#0d47a1
    style K fill:#4a148c
    style L fill:#1b5e20
    style M fill:#e65100
    style R fill:#b71c1c
```

## 2. Prompt Chain Processing Flow with Context Integration

```mermaid
flowchart TD
    A[User Idea Input] --> B[Step 1: Input Parsing]
    B --> C{Parse Idea Components}
    C --> D[Extract Core Concept]
    C --> E[Extract Context]
    C --> F[Extract Requirements]

    D --> G[Step 2: Context Analysis]
    E --> G
    F --> G
    G --> H[Analyze Project Context]
    H --> I[Load Related Context]

    I --> J[Step 3: Prompt Chain Stage Selection]
    J --> K{Current Stage?}
    K -->|Idea| L[Idea Definition Prompt]
    K -->|PRD| M[PRD Generation Prompt]
    K -->|TRD| N[TRD Creation Prompt]
    K -->|Features| O[Feature Breakdown Prompt]
    K -->|Stories| P[User Story Prompts]

    L --> Q[Step 4: Agent Spawning Decision]
    M --> Q
    N --> Q
    O --> Q
    P --> Q

    Q --> R{Spawn Agents?}
    R -->|Yes| S[Spawn Required Agents]
    R -->|No| T[Orchestrator Only]

    S --> U[Agent Coordination]
    T --> U
    U --> V[MCP Server Selection]
    V --> W[Execute Prompt Chain Stage]

    W --> X[Step 5: Quality Gates]
    X --> Y[Stage-Specific Validation]
    Y --> Z[Context Consistency Check]
    Z --> AA[Update Project Context]

    AA --> BB{More Stages?}
    BB -->|Yes| J
    BB -->|No| CC[Final Output]

    style A fill:#0d47a1
    style G fill:#4a148c
    style J fill:#1b5e20
    style Q fill:#e65100
    style X fill:#b71c1c
    style AA fill:#2e7d32
```

## 3. Agent Spawning and Context-Aware Scoring System

```mermaid
flowchart TD
    A[Prompt Chain Stage] --> B[Multi-Factor Agent Analysis]

    B --> C[Stage Requirements<br/>Weight: 40%]
    B --> D[Content Analysis<br/>Weight: 35%]
    B --> E[Project Context<br/>Weight: 15%]
    B --> F[User Preferences<br/>Weight: 10%]

    C --> G[Stage-Specific Needs]
    G --> H[PRD: Business Analysis]
    G --> I[TRD: Technical Architecture]
    G --> J[Features: Implementation Planning]
    G --> K[Stories: Specialized Implementation]

    D --> L[Technical Domain Analysis]
    L --> M[Frontend: UI/UX Requirements]
    L --> N[Backend: API/Database Needs]
    L --> O[Security: Auth/Compliance]
    L --> P[Performance: Optimization Needs]

    E --> Q[Project Context Analysis]
    Q --> R[Current Implementation]
    Q --> S[Technical Constraints]
    Q --> T[Integration Requirements]
    Q --> U[Architecture Patterns]

    F --> V[Agent Preferences]
    F --> W[User Overrides]
    F --> X[Collaboration Patterns]

    H --> Y[Calculate Agent Scores]
    I --> Y
    J --> Y
    K --> Y
    M --> Y
    N --> Y
    O --> Y
    P --> Y
    R --> Y
    S --> Y
    T --> Y
    U --> Y
    V --> Y
    W --> Y
    X --> Y

    Y --> Z{Score >= 85%?}
    Z -->|Yes| AA[Auto-Spawn Agent]
    Z -->|No| BB[Orchestrator Only]

    AA --> CC[Agent Initialization]
    CC --> DD[Context Loading]
    CC --> EE[MCP Server Assignment]
    CC --> FF[Task Coordination]

    BB --> GG[Standard Processing]

    style A fill:#0d47a1
    style B fill:#4a148c
    style Y fill:#e65100
    style Z fill:#b71c1c
    style AA fill:#1b5e20
```

## 4. Agent-MCP Server Coordination with Context Integration

```mermaid
flowchart TD
    A[Agent Spawn Request] --> B[Context-Aware Server Selection]

    B --> C[Agent-Server Affinity<br/>Priority 1]
    B --> D[Project Context<br/>Priority 2]
    B --> E[Performance Metrics<br/>Priority 3]
    B --> F[Load Distribution<br/>Priority 4]

    C --> G[Frontend Agent + Magic]
    C --> H[Backend Agent + Sequential]
    C --> I[Security Agent + Sequential]
    C --> J[Performance Agent + Playwright]

    D --> K[Context Analysis]
    K --> L[Current Implementation]
    K --> M[Technical Patterns]
    K --> N[Integration Requirements]

    G --> O[UI Component Generation]
    O --> P[Context Check: Existing Components]
    P --> Q[Pattern Analysis]
    Q --> R[New Implementation]
    R --> S[Context Update]

    H --> T[API Development]
    T --> U[Context Check: Existing APIs]
    U --> V[Integration Analysis]
    V --> W[Implementation]
    W --> X[Context Update]

    I --> Y[Security Implementation]
    Y --> Z[Context Check: Security Patterns]
    Z --> AA[Compliance Verification]
    AA --> BB[Implementation]
    BB --> CC[Context Update]

    J --> DD[Performance Optimization]
    DD --> EE[Context Check: Previous Optimizations]
    EE --> FF[Benchmark Analysis]
    FF --> GG[Implementation]
    GG --> HH[Context Update]

    E --> II[Response Time Tracking]
    E --> JJ[Success Rate Monitoring]
    E --> KK[Context Operation Performance]

    F --> LL[Agent Load Balancing]
    F --> MM[Server Health Monitoring]
    F --> NN[Context Consistency Checks]

    style A fill:#0d47a1
    style B fill:#4a148c
    style K fill:#1b5e20
    style S fill:#e65100
    style X fill:#b71c1c
    style CC fill:#2e7d32
    style HH fill:#1565c0
```

## 5. Prompt Chain Wave System with Context Integration

```mermaid
flowchart TD
    A[Prompt Chain Stage] --> B[Wave Eligibility Assessment]

    B --> C[Chain Complexity<br/>Weight: 35%]
    B --> D[Agent Coordination<br/>Weight: 25%]
    B --> E[Implementation Scale<br/>Weight: 20%]
    B --> F[Project Context<br/>Weight: 15%]
    B --> G[Quality Requirements<br/>Weight: 5%]

    C --> H[Multi-Stage Dependencies]
    C --> I[Cross-Stage Complexity]
    C --> J[Integration Requirements]

    D --> K[Required Agent Count]
    D --> L[Agent Coordination Complexity]
    D --> M[Cross-Agent Dependencies]

    E --> N[Feature Count]
    E --> O[Component Count]
    E --> P[File Modification Count]

    F --> Q[Project Scope]
    F --> R[Technical Constraints]
    F --> S[Integration Complexity]

    G --> T[Quality Gate Count]
    G --> U[Validation Complexity]
    G --> V[Context Validation Requirements]

    H --> W[Calculate Wave Score]
    I --> W
    J --> W
    K --> W
    L --> W
    M --> W
    N --> W
    O --> W
    P --> W
    Q --> W
    R --> W
    S --> W
    T --> W
    U --> W
    V --> W

    W --> X{Score >= 0.7?}
    X -->|Yes| Y[Enable Wave Mode]
    X -->|No| Z[Standard Execution]

    Y --> AA[Wave 1: Foundation]
    AA --> BB[Context Checkpoint]
    BB --> CC[Wave 2: Enhancement]
    CC --> DD[Context Checkpoint]
    DD --> EE[Wave 3: Optimization]
    EE --> FF[Final Context Update]

    Z --> GG[Single-Pass Execution]
    GG --> HH[Context Update]

    style A fill:#0d47a1
    style B fill:#4a148c
    style X fill:#1b5e20
    style Y fill:#e65100
    style Z fill:#b71c1c
```

## 7. OpenCode CLI Prompt Chain Implementation Architecture

```mermaid
graph TD
    A[OpenCode CLI] --> B[Prompt Chain System]
    B --> C[Stage Orchestrator]
    B --> E[Agent Pool]
    B --> F[MCP Coordinator]

    C --> G[Idea Definition Stage]
    C --> H[PRD Generation Stage]
    C --> I[TRD Creation Stage]
    C --> J[Feature Breakdown Stage]
    C --> K[User Story Stage]

    E --> R[Frontend Agent]
    E --> S[Backend Agent]
    E --> T[Security Agent]
    E --> U[Performance Agent]
    E --> V[Architect Agent]

    F --> W[Context7 Server]
    F --> X[Sequential Server]
    F --> Y[Magic Server]
    F --> Z[Playwright Server]

    G --> AA[Quality Gates]
    H --> AA
    I --> AA
    J --> AA
    K --> AA

    AA --> BB[Stage Validation]
    AA --> CC[Context Validation]
    AA --> DD[Agent Coordination Validation]

    style A fill:#0d47a1
    style B fill:#4a148c
    style C fill:#1b5e20
    style D fill:#e65100
    style E fill:#b71c1c
    style F fill:#2e7d32
```

## 8. Quality Gates Integration with Prompt Chain

```mermaid
flowchart LR
    A[Prompt Chain Stage] --> B[Stage-Specific Gates]
    B --> C{Pass?}
    C -->|Yes| D[Context Validation]
    C -->|No| E[Stage Errors]

    D --> F{Context Consistent?}
    F -->|Yes| G[Agent Coordination Check]
    F -->|No| H[Context Errors]

    G --> I{Agents Coordinated?}
    I -->|Yes| J[Implementation Gates]
    I -->|No| K[Coordination Errors]

    J --> L[Syntax/Type/Lint/Security]
    L --> M{Implementation Valid?}
    M -->|Yes| N[Context Update]
    M -->|No| O[Implementation Errors]

    N --> P{Context Updated?}
    P -->|Yes| Q[✅ Stage Complete]
    P -->|No| R[Context Update Errors]

    Q --> S[Next Stage or Complete]

    style A fill:#0d47a1
    style Q fill:#1b5e20
    style E fill:#c62828
    style H fill:#c62828
    style K fill:#c62828
    style O fill:#c62828
    style R fill:#c62828
```

---

*These diagrams provide visual representations of the SuperClaude Framework prompt chain architecture with context-aware processing and agent coordination. Each diagram illustrates key relationships and processes for the OpenCode CLI implementation.*

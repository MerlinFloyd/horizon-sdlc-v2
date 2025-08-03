# Phase 1: NX Monorepo Management Patterns (Revised)

## **1. NX Workspace Organization with Docker Integration**

### **Mandatory Folder Structure**
```
workspace-root/
├── apps/                          # Deployable applications
│   ├── web-dashboard/            # Next.js frontend apps
│   │   ├── src/
│   │   ├── Dockerfile            # Co-located with application
│   │   ├── k8s/                  # Kubernetes manifests
│   │   └── helm/                 # Helm charts (if used)
│   ├── web-marketplace/          
│   │   ├── src/
│   │   ├── Dockerfile
│   │   └── k8s/
│   ├── api-core/                 # Node.js backend services
│   │   ├── src/
│   │   ├── Dockerfile
│   │   └── k8s/
│   ├── api-payments/             
│   │   ├── src/
│   │   ├── Dockerfile
│   │   └── k8s/
│   └── blockchain-deployer/      # Smart contract deployment apps
│       ├── src/
│       ├── Dockerfile
│       └── k8s/
├── libs/                         # Shared libraries
│   ├── shared/                   # Cross-domain shared code
│   │   ├── ui/                   # ShadCN components & design system
│   │   │   ├── src/
│   │   │   └── Dockerfile        # For Storybook deployment
│   │   ├── utils/                # Common utilities
│   │   ├── types/                # TypeScript type definitions
│   │   └── config/               # Shared configurations
│   ├── web/                      # Frontend-specific libraries
│   │   ├── components/           # Web-specific components
│   │   ├── hooks/                # React hooks
│   │   └── stores/               # State management
│   ├── api/                      # Backend-specific libraries
│   │   ├── database/             # Database utilities & models
│   │   ├── auth/                 # Authentication logic
│   │   └── services/             # Business logic services
│   └── blockchain/               # Blockchain-specific libraries
│       ├── contracts/            # Smart contract interfaces
│       ├── sdk/                  # Blockchain interaction SDK
│       └── utils/                # Blockchain utilities
├── contracts/                    # Smart contract source code
│   ├── ethereum/                 # Ethereum/Polygon contracts
│   │   ├── src/
│   │   ├── Dockerfile            # For contract compilation/deployment
│   │   └── k8s/                  # For deployment jobs
│   ├── solana/                   # Solana programs (if supported)
│   │   ├── src/
│   │   └── Dockerfile
│   └── shared/                   # Cross-chain utilities
├── tools/                        # Development tools
│   ├── generators/               # NX generators
│   ├── scripts/                  # Build/deployment scripts
│   └── linters/                  # Custom linting rules
├── docs/                         # Documentation
│   ├── architecture/             # System architecture docs
│   ├── apis/                     # API documentation
│   └── guides/                   # Developer guides
├── docker-compose.yml            # Local development orchestration
└── docker-compose.override.yml   # Local development overrides
```

### **Docker Integration Principles**
```json
{
  "dockerIntegration": {
    "coLocation": {
      "principle": "Dockerfiles live with their applications",
      "examples": [
        "apps/web-dashboard/Dockerfile",
        "apps/api-core/Dockerfile",
        "contracts/ethereum/Dockerfile"
      ]
    },
    "orchestration": {
      "localDevelopment": {
        "file": "docker-compose.yml (workspace root)"
      },
      "kubernetesManifests": {
        "location": "Co-located with applications (apps/*/k8s/)"
      }
    }
  }
}
```

### **Project Naming Conventions (Approved)**
```json
{
  "applications": {
    "pattern": "{domain}-{purpose}",
    "examples": [
      "web-dashboard",
      "web-marketplace", 
      "api-core",
      "api-payments",
      "blockchain-deployer"
    ]
  },
  "libraries": {
    "pattern": "{scope}/{domain}",
    "examples": [
      "shared/ui",
      "shared/utils",
      "web/components",
      "api/database",
      "blockchain/sdk"
    ]
  },
  "contracts": {
    "pattern": "{chain}/{purpose}",
    "examples": [
      "ethereum/token-contract",
      "ethereum/marketplace-contract",
      "solana/nft-program"
    ]
  }
}
```

## **2. Project Types (Simplified)**

### **Supported Project Types**
```json
{
  "applications": {
    "web-apps": {
      "technology": "Next.js 14+ with TypeScript",
      "purpose": "User-facing frontend applications",
      "dockerSupport": "Multi-stage builds with nginx serving",
      "examples": ["web-dashboard", "web-marketplace"]
    },
    "api-services": {
      "technology": "Node.js with Express/Fastify",
      "purpose": "Backend services and APIs",
      "dockerSupport": "Node.js runtime with health checks", 
      "examples": ["api-core", "api-payments"]
    },
    "blockchain-apps": {
      "technology": "Hardhat/Foundry deployment scripts",
      "purpose": "Smart contract deployment and management",
      "dockerSupport": "Contract compilation and deployment containers",
      "examples": ["blockchain-deployer"]
    }
  },
  "libraries": {
    "ui-libraries": {
      "technology": "React + ShadCN + Tailwind",
      "purpose": "Reusable UI components and design system",
      "dockerSupport": "Storybook deployment containers (optional)"
    },
    "utility-libraries": {
      "technology": "TypeScript",
      "purpose": "Pure functions and utilities",
      "dockerSupport": "Not applicable (library code)"
    },
    "service-libraries": {
      "technology": "Node.js + TypeScript",
      "purpose": "Business logic and data access",
      "dockerSupport": "Not applicable (library code)"
    },
    "blockchain-libraries": {
      "technology": "ethers.js/web3.js + TypeScript",
      "purpose": "Blockchain interaction and utilities",
      "dockerSupport": "Not applicable (library code)"
    }
  }
}
```

## **3. Build Orchestration Standards (Updated)**

### **Task Dependencies and Execution Order**
```json
{
  "taskOrchestration": {
    "buildOrder": {
      "phase1": "shared/* libraries (parallel)",
      "phase2": "domain libraries (web/*, api/*, blockchain/*) (parallel within domain)",
      "phase3": "applications (parallel)",
      "rationale": "Dependency-aware execution ensures libraries are built before consumers"
    },
    "taskTypes": {
      "build": {
        "dependencies": ["lint", "type-check"],
        "parallelizable": true,
        "cacheable": true
      },
      "test": {
        "dependencies": ["build"],
        "parallelizable": true,
        "cacheable": true
      },
      "docker-build": {
        "dependencies": ["build", "test"],
        "parallelizable": true,
        "cacheable": false
      },
      "e2e": {
        "dependencies": ["docker-build"],
        "parallelizable": false,
        "cacheable": false
      },
      "deploy": {
        "dependencies": ["docker-build", "e2e"],
        "parallelizable": false,
        "cacheable": false
      }
    }
  }
}
```

### **CI/CD Platform Standards**
```json
{
  "cicdPlatform": {
    "mandatory": "GitHub Actions",
    "rationale": "Integrated with GitHub, excellent NX support, cost-effective",
    "configuration": {
      "workflowLocation": ".github/workflows/",
      "nxIntegration": "Use @nrwl/nx-set-shas for affected project detection",
      "matrixBuilds": "Parallel execution for independent projects",
      "dockerIntegration": "Build and push containers for each application"
    },
    "requiredWorkflows": [
      "ci.yml (build, test, lint for PRs)",
      "cd.yml (deploy to staging/production)",
      "docker.yml (container builds and registry pushes)"
    ]
  }
}
```

### **Caching Technology Standards**
```json
{
  "cachingTechnology": {
    "approved": "Redis",
    "rationale": "High performance, widely supported, excellent for distributed caching",
    "useCases": [
      "NX distributed build cache",
      "Application-level caching",
      "Session storage",
      "Rate limiting"
    ],
    "implementation": "Implementation details to be defined in Phase 2"
  }
}
```

## **4. Feature Flagging Support**

### **Feature Flag Management**
```json
{
  "featureFlagging": {
    "approvedStyle": "LaunchDarkly-style tools",
    "rationale": "Enable safe deployments, A/B testing, gradual rollouts",
    "toolSelection": "Specific tool selection pending evaluation",
    "requirements": {
      "realTimeUpdates": "Flags should update without deployment",
      "targeting": "Support user/group targeting",
      "rollback": "Instant rollback capability",
      "analytics": "Flag usage analytics and impact measurement"
    },
    "integrationPoints": {
      "frontend": "React hooks for feature flag evaluation",
      "backend": "Middleware for API feature gating",
      "infrastructure": "Infrastructure-level feature toggles"
    }
  }
}
```

## **5. Local Development Environment**

### **Docker Compose Configuration**
```json
{
  "localDevelopment": {
    "dockerCompose": {
      "location": "workspace-root/docker-compose.yml",
      "purpose": "Unified local development environment",
      "services": {
        "databases": ["PostgreSQL", "MongoDB", "Redis"],
        "messageQueues": ["Redis Pub/Sub", "RabbitMQ (if needed)"],
        "externalServices": ["Mock APIs", "Blockchain test networks"],
        "monitoring": ["Local observability stack (optional)"]
      },
      "overrides": {
        "file": "docker-compose.override.yml",
        "purpose": "Developer-specific customizations",
        "gitIgnore": true
      }
    },
    "developmentWorkflow": {
      "startup": "docker-compose up -d (start dependencies)",
      "development": "nx serve <app> (start individual applications)",
      "testing": "nx test <project> (run tests with dependencies available)",
      "cleanup": "docker-compose down (stop all services)"
    }
  }
}
```

## **Next Steps for Phase 1 Implementation**

1. **Create monorepo-management.json** with these revised patterns
2. **Update architectural-patterns.json** to reflect Docker co-location
3. **Update development-workflow.json** for GitHub Actions integration
4. **Prepare for Phase 2** containerization standards that build on this foundation

These revised patterns provide a solid foundation that integrates Docker from the start while maintaining the flexibility to define detailed implementation patterns in subsequent phases.

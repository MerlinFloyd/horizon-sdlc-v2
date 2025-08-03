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

## **5. NX Configuration Standards**

### **Project Structure Templates**
```json
{
  "projectStructureTemplates": {
    "nextjsApp": {
      "folders": [
        "src/app/",
        "src/components/",
        "src/lib/",
        "src/hooks/",
        "public/",
        "k8s/"
      ],
      "configFiles": [
        "next.config.js",
        "tailwind.config.js",
        "tsconfig.json",
        "Dockerfile",
        "project.json"
      ]
    },
    "nodejsApi": {
      "folders": [
        "src/routes/",
        "src/middleware/",
        "src/services/",
        "src/models/",
        "k8s/"
      ],
      "configFiles": [
        "tsconfig.json",
        "Dockerfile",
        "project.json"
      ]
    },
    "smartContractProject": {
      "folders": [
        "contracts/",
        "scripts/",
        "test/",
        "deploy/",
        "k8s/"
      ],
      "configFiles": [
        "hardhat.config.ts",
        "foundry.toml",
        "Dockerfile",
        "project.json"
      ]
    },
    "sharedLibrary": {
      "folders": [
        "src/",
        "test/"
      ],
      "configFiles": [
        "tsconfig.json",
        "project.json",
        "README.md"
      ]
    }
  }
}
```

### **Code Templates (Boilerplate)**
```json
{
  "codeTemplates": {
    "nextjsApp": {
      "boilerplate": [
        "Basic layout.tsx with ShadCN/ui integration",
        "page.tsx with TypeScript and Tailwind setup",
        "API route examples with proper error handling",
        "Component examples using shared/ui library"
      ]
    },
    "nodejsApi": {
      "boilerplate": [
        "Express server setup with TypeScript",
        "Basic route structure and middleware",
        "Database connection setup (MongoDB/PostgreSQL)",
        "Health check and error handling endpoints"
      ]
    },
    "smartContractProject": {
      "boilerplate": [
        "Basic contract template with security patterns",
        "Deployment script templates",
        "Test file templates with coverage examples",
        "Integration examples with frontend libraries"
      ]
    },
    "sharedLibrary": {
      "boilerplate": [
        "index.ts with proper exports",
        "TypeScript configuration inheritance",
        "Jest test setup and example tests",
        "README with usage examples"
      ]
    }
  }
}
```

### **Development Workflow Scaffolding**
```json
{
  "workflowScaffolding": {
    "cicdSetup": {
      "includes": [
        "GitHub Actions workflow templates",
        "Docker build and test configurations",
        "Deployment pipeline setup"
      ],
      "autoGenerated": true,
      "templates": [
        ".github/workflows/ci.yml",
        ".github/workflows/cd.yml",
        ".github/workflows/docker.yml"
      ]
    },
    "testingSetup": {
      "includes": [
        "Jest configuration with NX integration",
        "Playwright E2E test setup",
        "Test file templates and examples"
      ],
      "autoGenerated": true,
      "configFiles": [
        "jest.config.js",
        "playwright.config.ts"
      ]
    },
    "dockerSetup": {
      "includes": [
        "Multi-stage Dockerfile optimized for project type",
        "Kubernetes manifest templates"
      ],
      "autoGenerated": true,
      "templates": [
        "Dockerfile",
        "k8s/deployment.yaml",
        "k8s/service.yaml"
      ]
    }
  }
}
```

### **External Platform Integrations**
```json
{
  "externalPlatformIntegrations": {
    "githubActions": {
      "integration": "NX Cloud for distributed caching",
      "workflows": "Auto-generated CI/CD workflows",
      "affected": "Automated affected project detection",
      "required": true
    },
    "containerRegistries": {
      "integration": "GitHub Container Registry (primary)",
      "automation": "Automated image builds and pushes",
      "tagging": "Semantic versioning and branch-based tags",
      "required": true
    },
    "deploymentPlatforms": {
      "integration": "Kubernetes clusters via GitOps",
      "automation": "Automated deployment workflows",
      "manifests": "Co-located Kubernetes manifests",
      "required": true
    }
  }
}
```

### **Mandatory NX Plugins**
```json
{
  "mandatoryNxPlugins": {
    "@nx/react": {
      "purpose": "Next.js application support",
      "required": true,
      "version": "Latest stable"
    },
    "@nx/node": {
      "purpose": "Node.js API service support",
      "required": true,
      "version": "Latest stable"
    },
    "@nx/jest": {
      "purpose": "Testing framework integration",
      "required": true,
      "version": "Latest stable"
    },
    "@nx/eslint": {
      "purpose": "Code quality and linting",
      "required": true,
      "version": "Latest stable"
    }
  }
}
```

## **6. Local Development Environment**

### **Docker Compose Configuration**
```json
{
  "localDevelopment": {
    "dockerCompose": {
      "location": "workspace-root/docker-compose.yml",
      "services": {
        "databases": ["PostgreSQL", "MongoDB", "Redis"],
        "messageQueues": ["Redis Pub/Sub"],
        "externalServices": ["Mock APIs", "Blockchain test networks"]
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

## **Phase 1 Completion Status**

### **✅ Completed NX Monorepo Management Topics:**
1. **NX Workspace Organization** - Mandatory folder structure with Docker integration
2. **Project Types** - Defined supported application and library types
3. **Build Orchestration** - GitHub Actions integration and Redis caching
4. **Feature Flagging** - LaunchDarkly-style tool support
5. **UI Component Library Standards** - ShadCN/ui, Tailwind CSS, Framer Motion integration
6. **NX Configuration Standards** - Project templates, code scaffolding, platform integrations

### **📋 Ready for Implementation:**
- **monorepo-management.json** - Complete standards document
- **ui-design-system.json** - UI and design system standards
- Updates to existing standards documents for NX integration

### **🚀 Ready to Proceed to Phase 2: Containerization Standards**

Phase 1 Foundation is complete. All NX monorepo management discussions have been addressed, providing a solid foundation for containerization standards that will build upon:
- Co-located Docker files established in workspace organization
- GitHub Actions CI/CD platform selection
- Project structure templates that include Kubernetes manifests
- External platform integrations for container registries and deployment

**Phase 2 Focus:** Docker best practices, container orchestration, security standards, and integration with our established NX monorepo structure.

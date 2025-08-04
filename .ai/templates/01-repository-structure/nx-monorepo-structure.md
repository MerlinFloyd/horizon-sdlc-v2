# NX Monorepo Structure Template

## Overview
This template provides the complete NX monorepo structure following our organizational standards with domain-driven organization, clear boundaries, and scalable architecture.

## Directory Structure

```
horizon-monorepo/
├── apps/                           # Deployable applications
│   ├── web-dashboard/              # Next.js frontend application
│   │   ├── src/
│   │   │   ├── app/               # Next.js App Router
│   │   │   ├── components/        # App-specific components
│   │   │   ├── lib/               # App-specific utilities
│   │   │   └── hooks/             # App-specific React hooks
│   │   ├── public/                # Static assets
│   │   ├── k8s/                   # Kubernetes manifests
│   │   ├── helm/                  # Helm charts
│   │   ├── Dockerfile             # Container definition
│   │   ├── project.json           # NX project configuration
│   │   ├── next.config.js         # Next.js configuration
│   │   ├── tailwind.config.js     # Tailwind CSS configuration
│   │   └── tsconfig.json          # TypeScript configuration
│   ├── web-marketplace/            # Next.js marketplace application
│   │   └── [similar structure]
│   ├── api-core/                   # Node.js backend services
│   │   ├── src/
│   │   │   ├── routes/            # API route handlers
│   │   │   ├── middleware/        # Express middleware
│   │   │   ├── services/          # Business logic services
│   │   │   ├── models/            # Data models
│   │   │   └── utils/             # API-specific utilities
│   │   ├── k8s/                   # Kubernetes manifests
│   │   ├── Dockerfile             # Container definition
│   │   ├── project.json           # NX project configuration
│   │   └── tsconfig.json          # TypeScript configuration
│   ├── api-payments/               # Node.js payment services
│   │   └── [similar structure]
│   └── blockchain-deployer/        # Smart contract deployment app
│       ├── contracts/             # Smart contract source
│       ├── scripts/               # Deployment scripts
│       ├── test/                  # Contract tests
│       ├── deploy/                # Deployment configurations
│       ├── k8s/                   # Kubernetes manifests
│       ├── Dockerfile             # Container definition
│       ├── hardhat.config.ts      # Hardhat configuration
│       ├── foundry.toml           # Foundry configuration
│       └── project.json           # NX project configuration
├── libs/                           # Shared libraries organized by category
│   ├── shared/                     # Cross-domain shared libraries
│   │   ├── ui/                    # ShadCN components & design system
│   │   │   ├── src/
│   │   │   │   ├── components/    # UI components
│   │   │   │   ├── hooks/         # UI-related hooks
│   │   │   │   ├── utils/         # UI utilities
│   │   │   │   └── index.ts       # Public API
│   │   │   ├── Dockerfile         # Storybook container
│   │   │   ├── .storybook/        # Storybook configuration
│   │   │   ├── project.json       # NX project configuration
│   │   │   └── tsconfig.json      # TypeScript configuration
│   │   ├── utils/                 # Common utilities
│   │   │   ├── src/
│   │   │   │   ├── date/          # Date utilities
│   │   │   │   ├── validation/    # Validation utilities
│   │   │   │   ├── crypto/        # Cryptographic utilities
│   │   │   │   └── index.ts       # Public API
│   │   │   └── project.json       # NX project configuration
│   │   ├── types/                 # TypeScript type definitions
│   │   │   ├── src/
│   │   │   │   ├── api/           # API types
│   │   │   │   ├── domain/        # Domain types
│   │   │   │   ├── ui/            # UI types
│   │   │   │   └── index.ts       # Public API
│   │   │   └── project.json       # NX project configuration
│   │   └── config/                # Shared configurations
│   │       ├── src/
│   │       │   ├── env/           # Environment configurations
│   │       │   ├── constants/     # Application constants
│   │       │   └── index.ts       # Public API
│   │       └── project.json       # NX project configuration
│   ├── web/                        # Web-specific libraries
│   │   ├── components/            # Web-specific components
│   │   │   ├── src/
│   │   │   │   ├── forms/         # Form components
│   │   │   │   ├── layouts/       # Layout components
│   │   │   │   ├── navigation/    # Navigation components
│   │   │   │   └── index.ts       # Public API
│   │   │   └── project.json       # NX project configuration
│   │   ├── hooks/                 # React hooks
│   │   │   ├── src/
│   │   │   │   ├── auth/          # Authentication hooks
│   │   │   │   ├── data/          # Data fetching hooks
│   │   │   │   ├── ui/            # UI interaction hooks
│   │   │   │   └── index.ts       # Public API
│   │   │   └── project.json       # NX project configuration
│   │   └── stores/                # State management
│   │       ├── src/
│   │       │   ├── auth/          # Authentication store
│   │       │   ├── user/          # User data store
│   │       │   ├── ui/            # UI state store
│   │       │   └── index.ts       # Public API
│   │       └── project.json       # NX project configuration
│   ├── api/                        # API-specific libraries
│   │   ├── database/              # Database utilities & models
│   │   │   ├── src/
│   │   │   │   ├── prisma/        # Prisma client & schemas
│   │   │   │   ├── mongoose/      # Mongoose models
│   │   │   │   ├── redis/         # Redis utilities
│   │   │   │   ├── migrations/    # Database migrations
│   │   │   │   └── index.ts       # Public API
│   │   │   └── project.json       # NX project configuration
│   │   ├── auth/                  # Authentication logic
│   │   │   ├── src/
│   │   │   │   ├── jwt/           # JWT utilities
│   │   │   │   ├── oauth/         # OAuth providers
│   │   │   │   ├── middleware/    # Auth middleware
│   │   │   │   └── index.ts       # Public API
│   │   │   └── project.json       # NX project configuration
│   │   └── services/              # Business logic services
│   │       ├── src/
│   │       │   ├── user/          # User service
│   │       │   ├── payment/       # Payment service
│   │       │   ├── notification/  # Notification service
│   │       │   └── index.ts       # Public API
│   │       └── project.json       # NX project configuration
│   └── blockchain/                 # Blockchain-specific libraries
│       ├── contracts/             # Smart contract interfaces
│       │   ├── src/
│       │   │   ├── ethereum/      # Ethereum contract interfaces
│       │   │   ├── solana/        # Solana program interfaces
│       │   │   ├── polygon/       # Polygon contract interfaces
│       │   │   └── index.ts       # Public API
│       │   └── project.json       # NX project configuration
│       ├── sdk/                   # Blockchain interaction SDK
│       │   ├── src/
│       │   │   ├── ethereum/      # Ethereum SDK
│       │   │   ├── solana/        # Solana SDK
│       │   │   ├── polygon/       # Polygon SDK
│       │   │   └── index.ts       # Public API
│       │   └── project.json       # NX project configuration
│       └── utils/                 # Blockchain utilities
│           ├── src/
│           │   ├── wallet/        # Wallet utilities
│           │   ├── gas/           # Gas optimization
│           │   ├── events/        # Event processing
│           │   └── index.ts       # Public API
│           └── project.json       # NX project configuration
├── contracts/                      # Smart contract source code
│   ├── ethereum/                   # Ethereum/Polygon contracts
│   │   ├── src/                   # Solidity source files
│   │   ├── test/                  # Contract tests
│   │   ├── scripts/               # Deployment scripts
│   │   ├── k8s/                   # Kubernetes manifests
│   │   ├── Dockerfile             # Container definition
│   │   ├── hardhat.config.ts      # Hardhat configuration
│   │   └── project.json           # NX project configuration
│   ├── solana/                     # Solana programs
│   │   ├── src/                   # Rust source files
│   │   ├── tests/                 # Program tests
│   │   ├── Dockerfile             # Container definition
│   │   ├── Anchor.toml            # Anchor configuration
│   │   └── project.json           # NX project configuration
│   └── shared/                     # Cross-chain utilities
│       ├── src/
│       │   ├── interfaces/        # Common interfaces
│       │   ├── utils/             # Shared utilities
│       │   └── index.ts           # Public API
│       └── project.json           # NX project configuration
├── tools/                          # Development tools
│   ├── generators/                # NX generators
│   │   ├── app/                   # Application generator
│   │   ├── lib/                   # Library generator
│   │   ├── component/             # Component generator
│   │   └── contract/              # Smart contract generator
│   ├── scripts/                   # Build/deployment scripts
│   │   ├── build.sh               # Build script
│   │   ├── deploy.sh              # Deployment script
│   │   ├── test.sh                # Test script
│   │   └── setup.sh               # Environment setup
│   └── linters/                   # Custom linting rules
│       ├── eslint/                # ESLint configurations
│       ├── prettier/              # Prettier configurations
│       └── solhint/               # Solidity linting
├── docs/                           # Documentation
│   ├── architecture/              # System architecture docs
│   │   ├── overview.md            # Architecture overview
│   │   ├── data-flow.md           # Data flow diagrams
│   │   └── security.md            # Security architecture
│   ├── apis/                      # API documentation
│   │   ├── core-api.md            # Core API documentation
│   │   ├── payment-api.md         # Payment API documentation
│   │   └── blockchain-api.md      # Blockchain API documentation
│   └── guides/                    # Developer guides
│       ├── getting-started.md     # Getting started guide
│       ├── deployment.md          # Deployment guide
│       └── testing.md             # Testing guide
├── .github/                        # GitHub configuration
│   └── workflows/                 # GitHub Actions workflows
│       ├── ci.yml                 # Continuous integration
│       ├── cd.yml                 # Continuous deployment
│       ├── security.yml           # Security scanning
│       └── release.yml            # Release automation
├── terraform/                      # Infrastructure as Code
│   ├── environments/              # Environment-specific configs
│   │   ├── test/                  # Test environment
│   │   └── prod/                  # Production environment
│   ├── modules/                   # Reusable Terraform modules
│   │   ├── gke/                   # GKE cluster module
│   │   ├── vpc/                   # VPC network module
│   │   └── monitoring/            # Monitoring module
│   └── global/                    # Global resources
├── docker-compose.yml              # Local development orchestration
├── docker-compose.override.yml     # Local development overrides (git ignored)
├── nx.json                         # NX workspace configuration
├── package.json                    # Dependencies and scripts
├── tsconfig.base.json              # Base TypeScript configuration
├── tailwind.config.js              # Global Tailwind configuration
├── .eslintrc.json                  # ESLint configuration
├── .prettierrc                     # Prettier configuration
├── .gitignore                      # Git ignore rules
└── README.md                       # Project documentation
```

## NX Configuration

### Workspace Configuration (nx.json)
```json
{
  "extends": "nx/presets/npm.json",
  "tasksRunnerOptions": {
    "default": {
      "runner": "nx/tasks-runners/default",
      "options": {
        "cacheableOperations": ["build", "lint", "test", "e2e"]
      }
    }
  },
  "targetDefaults": {
    "build": {
      "dependsOn": ["^build"],
      "inputs": ["production", "^production"]
    },
    "test": {
      "inputs": ["default", "^production", "{workspaceRoot}/jest.preset.js"]
    },
    "lint": {
      "inputs": ["default", "{workspaceRoot}/.eslintrc.json"]
    }
  },
  "namedInputs": {
    "default": ["{projectRoot}/**/*", "sharedGlobals"],
    "production": [
      "default",
      "!{projectRoot}/**/?(*.)+(spec|test).[jt]s?(x)?(.snap)",
      "!{projectRoot}/tsconfig.spec.json",
      "!{projectRoot}/jest.config.[jt]s",
      "!{projectRoot}/.eslintrc.json"
    ],
    "sharedGlobals": []
  }
}
```

### Project Configuration (project.json)
```json
{
  "name": "web-dashboard",
  "sourceRoot": "apps/web-dashboard/src",
  "projectType": "application",
  "targets": {
    "build": {
      "executor": "@nx/next:build",
      "outputs": ["{options.outputPath}"],
      "defaultConfiguration": "production",
      "options": {
        "outputPath": "dist/apps/web-dashboard"
      }
    },
    "serve": {
      "executor": "@nx/next:dev",
      "defaultConfiguration": "development",
      "options": {
        "buildTarget": "web-dashboard:build",
        "dev": true
      }
    },
    "test": {
      "executor": "@nx/jest:jest",
      "outputs": ["{workspaceRoot}/coverage/{projectRoot}"],
      "options": {
        "jestConfig": "apps/web-dashboard/jest.config.ts"
      }
    },
    "lint": {
      "executor": "@nx/linter:eslint",
      "outputs": ["{options.outputFile}"],
      "options": {
        "lintFilePatterns": ["apps/web-dashboard/**/*.{ts,tsx,js,jsx}"]
      }
    }
  },
  "tags": ["scope:web", "type:app"]
}
```

## Usage Examples

### Creating New Projects
```bash
# Generate new Next.js application
nx g @nx/next:app web-admin --directory=apps/web-admin

# Generate new Node.js API
nx g @nx/node:app api-notifications --directory=apps/api-notifications

# Generate new shared library
nx g @nx/js:lib utils --directory=libs/shared/utils

# Generate new React component library
nx g @nx/react:lib components --directory=libs/web/components
```

### Building and Testing
```bash
# Build all affected projects
nx affected:build

# Test all affected projects
nx affected:test

# Lint all affected projects
nx affected:lint

# Run specific project
nx serve web-dashboard
nx test api-core
nx build blockchain-deployer
```

### Dependency Management
```bash
# Show project dependencies
nx graph

# Show what's affected by changes
nx affected:graph

# Run tasks in parallel
nx run-many --target=build --projects=web-dashboard,api-core
```

This structure provides a scalable, maintainable foundation for our NX monorepo following all organizational standards and best practices.

# Repository Structure Design
## Horizon SDLC

### 1. Overview

This document defines the **source code organization and build structure** for Horizon SDLC. It complements [requirements.md](./requirements.md) by focusing on the development repository structure, build scripts, and testing organization.

**Reference**: See [requirements.md Section 2](./requirements.md#2-repository-structure-requirements) for asset requirements and [Section 7.3](./requirements.md#73-workspace-asset-management) for deployed asset structure.

**Focus Areas**:
- Source code organization (`src/` directory)
- Testing structure and utilities
- Build and deployment scripts
- Development tooling and configuration

### 2. Repository Root Structure

**Reference**: See [requirements.md Section 2.1](./requirements.md#21-core-components) for complete asset requirements.

```
horizon-sdlc-v2/
├── src/                          # Horizon SDLC source code (detailed below)
├── assets/                       # Assets deployed to target projects (see requirements.md)
├── docker/                       # Docker build configurations
├── scripts/                      # Build and setup scripts
├── tests/                        # Test suites (detailed below)
├── docs/                         # Documentation
├── examples/                     # Example configurations and usage
├── .github/                      # GitHub Actions workflows
├── package.json                  # Node.js project configuration
├── tsconfig.json                 # TypeScript configuration
├── jest.config.js                # Testing configuration
├── eslint.config.js              # ESLint configuration
├── prettier.config.js            # Prettier configuration
├── .gitignore                    # Git ignore rules
├── .dockerignore                 # Docker ignore rules
├── README.md                     # Project documentation
├── LICENSE                       # License file
└── CHANGELOG.md                  # Version history
```

**Note**: The `assets/` directory structure is fully defined in [requirements.md Section 7.3](./requirements.md#73-workspace-asset-management). This document focuses on the development repository structure.

### 3. Source Code Structure (`src/`)

**Detailed organization of the bootstrapper application source code:**

```
src/
├── cli/                          # CLI interface and commands
│   ├── commands/                 # Individual CLI commands
│   │   ├── init.ts              # Project initialization command
│   │   ├── add.ts               # Add language/framework command
│   │   ├── update.ts            # Update assets command
│   │   ├── deploy.ts            # Deploy OpenCode command
│   │   ├── validate.ts          # Validation command
│   │   └── index.ts             # Command exports
│   ├── wizard/                   # Interactive setup wizard
│   │   ├── project-wizard.ts    # Main wizard orchestrator
│   │   ├── language-selector.ts # Language selection interface
│   │   ├── feature-selector.ts  # Feature selection interface
│   │   ├── config-builder.ts    # Configuration builder
│   │   └── prompts.ts           # Inquirer prompt definitions
│   ├── parsers/                  # Command line parsing
│   │   ├── option-parser.ts     # Command option parsing
│   │   ├── config-parser.ts     # Configuration file parsing
│   │   └── validation.ts        # Input validation
│   └── index.ts                 # CLI entry point
├── core/                        # Core engine components
│   ├── project-manager.ts       # Project lifecycle management
│   ├── file-processor.ts        # Static file processing and copying
│   ├── config-manager.ts        # Configuration management
│   ├── asset-manager.ts         # Asset deployment and management
│   ├── validation-engine.ts     # Validation and schema checking
│   ├── error-handler.ts         # Error handling and recovery
│   └── bootstrap-orchestrator.ts # Main bootstrap workflow
├── docker/                      # Docker integration
│   ├── container-manager.ts     # Container lifecycle management
│   ├── volume-manager.ts        # Volume mounting and management
│   ├── opencode-deployer.ts     # OpenCode deployment logic
│   ├── health-checker.ts        # Container health monitoring
│   ├── image-builder.ts         # Docker image building
│   └── registry-client.ts       # Container registry operations
├── generators/                  # File and structure generators
│   ├── project-generator.ts     # Project structure generation
│   ├── config-generator.ts      # Configuration file generation
│   ├── workflow-generator.ts    # GitHub Actions workflow generation
│   ├── devcontainer-generator.ts # DevContainer configuration
│   ├── package-generator.ts     # Package.json generation
│   └── gitignore-generator.ts   # .gitignore file generation
├── processing/                  # File processing utilities
│   ├── file-copier.ts           # Static file copying operations
│   ├── string-replacer.ts       # Simple string replacement
│   ├── file-validator.ts        # Basic file content validation
│   └── asset-deployer.ts        # Asset deployment utilities
├── utils/                       # Utility functions and helpers
│   ├── file-utils.ts           # File system operations
│   ├── git-utils.ts            # Git integration utilities
│   ├── crypto-utils.ts         # Encryption and security utilities
│   ├── logger.ts               # Logging utilities
│   ├── constants.ts            # Application constants
│   ├── path-utils.ts           # Path resolution utilities
│   ├── process-utils.ts        # Process execution utilities
│   └── validation-utils.ts     # Common validation functions
├── types/                       # TypeScript type definitions
│   ├── project.ts              # Project configuration types
│   ├── file-processing.ts      # File processing types
│   ├── opencode.ts             # OpenCode configuration types
│   ├── docker.ts               # Docker integration types
│   ├── cli.ts                  # CLI interface types
│   ├── errors.ts               # Error type definitions
│   └── common.ts               # Common shared types
├── config/                      # Application configuration
│   ├── default.ts              # Default configuration values
│   ├── schema.ts               # Configuration schema definitions
│   └── environment.ts          # Environment-specific configs
└── index.ts                    # Main application entry point
```

### 4. Docker Configuration Structure (`docker/`)

**Reference**: See [requirements.md Section 7.4](./requirements.md#74-opencode-container-deployment) for container deployment requirements.

```
docker/
├── horizon-sdlc/               # Horizon SDLC container configuration
│   ├── Dockerfile             # Multi-stage build for Horizon SDLC
│   ├── Dockerfile.dev         # Development container
│   ├── entrypoint.sh          # Container entry point script
│   ├── healthcheck.sh         # Health check script
│   └── .dockerignore          # Docker ignore rules
├── opencode/                  # OpenCode container customization
│   ├── Dockerfile.opencode    # OpenCode container modifications
│   ├── agents.md.template     # Global agent configuration template
│   ├── mcp-servers/           # MCP server installation scripts
│   │   ├── install-context7.sh
│   │   ├── install-github-mcp.sh
│   │   ├── install-playwright.sh
│   │   ├── install-shadcn-ui.sh
│   │   └── install-sequential-thinking.sh
│   └── config/
│       ├── base-opencode.json.template
│       └── mcp-defaults.json
└── scripts/                   # Docker utility scripts
    ├── build-all.sh          # Build all images
    ├── push-images.sh        # Push to registry
    ├── cleanup.sh            # Clean up containers and images
    └── health-check.sh       # Container health verification
```

### 5. Build and Deployment Scripts (`scripts/`)

**Reference**: See [requirements.md Section 10.2](./requirements.md#102-installation-and-usage) for build script requirements.

```
scripts/
├── build.sh                  # Build script for Docker image and deployment
├── verify.sh                 # Installation verification script
└── setup/                     # Setup and installation scripts (future)
    ├── install-deps.sh       # Dependency installation
    ├── setup-dev-env.sh      # Development environment setup
    └── check-prerequisites.sh # Prerequisites verification
```

### 6. Testing Structure (`tests/`)

**Comprehensive testing organization for the bootstrapper application:**

```
tests/
├── unit/                      # Unit tests
│   ├── cli/
│   │   ├── commands/
│   │   │   ├── init.test.ts
│   │   │   ├── add.test.ts
│   │   │   ├── update.test.ts
│   │   │   ├── deploy.test.ts
│   │   │   └── validate.test.ts
│   │   ├── wizard/
│   │   │   ├── project-wizard.test.ts
│   │   │   ├── language-selector.test.ts
│   │   │   ├── feature-selector.test.ts
│   │   │   └── config-builder.test.ts
│   │   └── parsers/
│   │       ├── option-parser.test.ts
│   │       ├── config-parser.test.ts
│   │       └── validation.test.ts
│   ├── core/
│   │   ├── project-manager.test.ts
│   │   ├── template-engine.test.ts
│   │   ├── config-manager.test.ts
│   │   ├── asset-manager.test.ts
│   │   ├── validation-engine.test.ts
│   │   ├── error-handler.test.ts
│   │   └── bootstrap-orchestrator.test.ts
│   ├── docker/
│   │   ├── container-manager.test.ts
│   │   ├── volume-manager.test.ts
│   │   ├── opencode-deployer.test.ts
│   │   ├── health-checker.test.ts
│   │   ├── image-builder.test.ts
│   │   └── registry-client.test.ts
│   ├── generators/
│   │   ├── project-generator.test.ts
│   │   ├── config-generator.test.ts
│   │   ├── workflow-generator.test.ts
│   │   ├── devcontainer-generator.test.ts
│   │   ├── package-generator.test.ts
│   │   └── gitignore-generator.test.ts
│   ├── processing/
│   │   ├── file-copier.test.ts
│   │   ├── string-replacer.test.ts
│   │   ├── file-validator.test.ts
│   │   └── asset-deployer.test.ts
│   └── utils/
│       ├── file-utils.test.ts
│       ├── git-utils.test.ts
│       ├── crypto-utils.test.ts
│       ├── logger.test.ts
│       ├── path-utils.test.ts
│       ├── process-utils.test.ts
│       └── validation-utils.test.ts
├── fixtures/                  # Test fixtures and mock data
│   ├── projects/
│   │   ├── typescript-sample/
│   │   ├── go-sample/
│   │   ├── python-sample/
│   │   └── java-sample/
│   ├── static-files/
│   │   ├── valid-files/
│   │   ├── invalid-files/
│   │   └── edge-cases/
│   ├── configs/
│   │   ├── valid-configs/
│   │   ├── invalid-configs/
│   │   └── edge-cases/
│   ├── responses/
│   │   ├── docker-responses/
│   │   ├── git-responses/
│   │   └── api-responses/
│   └── assets/
│       ├── sample-standards/
│       ├── sample-prompts/
│       └── sample-workflows/
├── helpers/                   # Test utilities and helpers
│   ├── test-utils.ts         # Common test utilities
│   ├── mock-docker.ts        # Docker mocking utilities
│   ├── mock-git.ts           # Git mocking utilities
│   ├── mock-fs.ts            # File system mocking
│   ├── temp-project.ts       # Temporary project management
│   ├── assertion-helpers.ts  # Custom assertion helpers
│   ├── performance-helpers.ts # Performance testing utilities
│   └── cleanup-helpers.ts    # Test cleanup utilities
└── setup/                     # Test environment setup
    ├── jest.setup.ts         # Jest global setup
    ├── docker-setup.ts       # Docker test environment
    ├── git-setup.ts          # Git test environment
    ├── temp-dirs.ts          # Temporary directory management
    ├── mock-setup.ts         # Mock configuration
    └── cleanup.ts            # Global cleanup
```

### 7. Development Configuration Files

**Project configuration files for development workflow:**

```
# Package configuration
package.json                   # Node.js dependencies and scripts
package-lock.json             # Dependency lock file

# TypeScript configuration
tsconfig.json                 # Main TypeScript configuration
tsconfig.build.json           # Build-specific TypeScript config
tsconfig.test.json            # Test-specific TypeScript config

# Testing configuration
jest.config.js                # Jest testing framework configuration
jest.setup.js                 # Jest setup and global configuration

# Code quality configuration
eslint.config.js              # ESLint linting configuration
prettier.config.js            # Prettier formatting configuration
.editorconfig                 # Editor configuration

# Git configuration
.gitignore                    # Git ignore rules
.gitattributes                # Git attributes configuration

# Docker configuration
.dockerignore                 # Docker ignore rules

# CI/CD configuration
.github/
├── workflows/
│   ├── ci.yml               # Continuous integration workflow
│   ├── release.yml          # Release workflow
│   ├── security.yml         # Security scanning workflow
│   └── docs.yml             # Documentation workflow
├── ISSUE_TEMPLATE/
│   ├── bug_report.md        # Bug report template
│   ├── feature_request.md   # Feature request template
│   └── question.md          # Question template
├── PULL_REQUEST_TEMPLATE.md # Pull request template
└── dependabot.yml           # Dependabot configuration

# Development environment
.env.example                  # Environment variables example
.nvmrc                       # Node.js version specification
.vscode/
├── settings.json            # VSCode workspace settings
├── extensions.json          # Recommended VSCode extensions
├── launch.json              # Debug configurations
└── tasks.json               # VSCode tasks
```

### 8. Build and Deployment Flow

**Reference**: See [requirements.md Section 11](./requirements.md#11-implementation-phases) for implementation phases and [Section 10](./requirements.md#10-distribution-and-usage) for distribution requirements.

#### 8.1 Development Workflow
```bash
# Development setup
npm install                    # Install dependencies
npm run build:dev             # Development build
npm run test:watch            # Watch mode testing
npm run lint:watch            # Watch mode linting

# Testing workflow
npm run test                  # Run all tests
npm run test:unit            # Unit tests only
npm run test:coverage        # Coverage reporting

# Build workflow
npm run build                # Production build
npm run docker:build         # Build Docker image
npm run docker:test          # Test Docker image
npm run validate             # Full validation
```

### 9. Key Design Principles

#### 9.1 Separation of Concerns
- **Source Code (`src/`)**: Bootstrapper implementation logic
- **Assets (`assets/`)**: Deployable templates and standards (see requirements.md)
- **Tests (`tests/`)**: Comprehensive testing at all levels
- **Scripts (`scripts/`)**: Build, deployment, and utility automation
- **Docker (`docker/`)**: Container configuration and deployment

#### 9.2 Modularity and Extensibility
- **Plugin Architecture**: Easy addition of new languages and frameworks
- **Template System**: Extensible template processing with custom helpers
- **Configuration Driven**: Behavior controlled through configuration files
- **Asset Management**: User-modifiable assets with version control integration

#### 9.3 Development Experience
- **Fast Feedback**: Watch mode for development and testing
- **Cross-Platform**: Consistent behavior across Windows, macOS, and Linux
- **Comprehensive Testing**: Unit, integration, e2e, and performance tests
- **Quality Gates**: Automated linting, formatting, and security scanning

### 10. Summary

This repository structure design provides:

✅ **Clear Organization**: Logical separation of source code, tests, scripts, and configuration
✅ **Comprehensive Testing**: Multi-level testing strategy with fixtures and utilities
✅ **Build Automation**: Complete build and deployment pipeline
✅ **Development Workflow**: Efficient development experience with quality gates
✅ **Extensibility**: Modular design for easy addition of new features
✅ **Cross-Platform Support**: Consistent behavior across all target platforms

**Complementary to requirements.md**: This document focuses on the development repository structure while requirements.md defines the deployed asset structure and system requirements. Together they provide complete coverage of the project organization needs.

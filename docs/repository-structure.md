# Repository Structure Design
## Horizon SDLC v2 Bootstrapping Application

### 1. Overview

This document defines the complete folder structure for the Horizon SDLC v2 bootstrapping application, establishing clear separation of concerns between the bootstrapper tool and the OpenCode container deployment.

### 2. Repository Root Structure

```
horizon-sdlc-v2/
├── src/                          # Bootstrapper source code
├── assets/                       # Assets deployed to target projects
├── docker/                       # Docker build configurations
├── scripts/                      # Build and setup scripts
├── tests/                        # Test suites
├── docs/                         # Documentation
├── examples/                     # Example configurations and usage
├── .github/                      # GitHub Actions workflows
├── package.json                  # Node.js project configuration
├── tsconfig.json                 # TypeScript configuration
├── jest.config.js                # Testing configuration
├── .gitignore                    # Git ignore rules
├── .dockerignore                 # Docker ignore rules
├── README.md                     # Project documentation
├── LICENSE                       # License file
└── CHANGELOG.md                  # Version history
```

### 3. Source Code Structure (`src/`)

```
src/
├── cli/                          # CLI interface and commands
│   ├── commands/                 # Individual CLI commands
│   │   ├── init.ts              # Project initialization command
│   │   ├── add.ts               # Add language/framework command
│   │   ├── update.ts            # Update templates command
│   │   ├── deploy.ts            # Deploy OpenCode command
│   │   └── validate.ts          # Validation command
│   ├── wizard/                   # Interactive setup wizard
│   │   ├── project-wizard.ts    # Main wizard orchestrator
│   │   ├── language-selector.ts # Language selection interface
│   │   ├── feature-selector.ts  # Feature selection interface
│   │   └── config-builder.ts    # Configuration builder
│   └── index.ts                 # CLI entry point
├── core/                        # Core engine components
│   ├── project-manager.ts       # Project lifecycle management
│   ├── template-engine.ts       # Template processing engine
│   ├── config-manager.ts        # Configuration management
│   ├── asset-manager.ts         # Asset deployment and management
│   ├── validation-engine.ts     # Validation and schema checking
│   └── error-handler.ts         # Error handling and recovery
├── docker/                      # Docker integration
│   ├── container-manager.ts     # Container lifecycle management
│   ├── volume-manager.ts        # Volume mounting and management
│   ├── opencode-deployer.ts     # OpenCode deployment logic
│   └── health-checker.ts        # Container health monitoring
├── generators/                  # File and structure generators
│   ├── project-generator.ts     # Project structure generation
│   ├── config-generator.ts      # Configuration file generation
│   ├── workflow-generator.ts    # GitHub Actions workflow generation
│   └── devcontainer-generator.ts # DevContainer configuration
├── templates/                   # Template processing utilities
│   ├── template-loader.ts       # Template loading and caching
│   ├── variable-resolver.ts     # Variable substitution
│   ├── file-processor.ts        # File processing and generation
│   └── schema-validator.ts      # Template schema validation
├── utils/                       # Utility functions and helpers
│   ├── file-utils.ts           # File system operations
│   ├── git-utils.ts            # Git integration utilities
│   ├── crypto-utils.ts         # Encryption and security utilities
│   ├── logger.ts               # Logging utilities
│   └── constants.ts            # Application constants
├── types/                       # TypeScript type definitions
│   ├── project.ts              # Project configuration types
│   ├── template.ts             # Template system types
│   ├── opencode.ts             # OpenCode configuration types
│   ├── docker.ts               # Docker integration types
│   └── cli.ts                  # CLI interface types
└── index.ts                    # Main application entry point
```

### 4. Assets Structure (`assets/`)

```
assets/                          # Assets deployed to target projects
├── templates/                   # Language-specific project templates
│   ├── typescript/
│   │   ├── metadata.json       # Template metadata and configuration
│   │   ├── files/              # Template files and directories
│   │   │   ├── src/
│   │   │   │   ├── index.ts.mustache
│   │   │   │   ├── types/
│   │   │   │   └── utils/
│   │   │   ├── tests/
│   │   │   │   └── index.test.ts.mustache
│   │   │   ├── package.json.mustache
│   │   │   ├── tsconfig.json.mustache
│   │   │   ├── .eslintrc.json.mustache
│   │   │   └── jest.config.js.mustache
│   │   ├── scripts/            # Post-generation scripts
│   │   │   ├── setup.sh
│   │   │   └── install-deps.sh
│   │   └── validation/         # Template validation rules
│   │       └── schema.json
│   ├── go/
│   │   ├── metadata.json
│   │   ├── files/
│   │   │   ├── cmd/
│   │   │   ├── internal/
│   │   │   ├── pkg/
│   │   │   ├── go.mod.mustache
│   │   │   ├── main.go.mustache
│   │   │   └── Makefile.mustache
│   │   ├── scripts/
│   │   └── validation/
│   ├── python/
│   │   ├── metadata.json
│   │   ├── files/
│   │   │   ├── src/
│   │   │   ├── tests/
│   │   │   ├── requirements.txt.mustache
│   │   │   ├── pyproject.toml.mustache
│   │   │   └── setup.py.mustache
│   │   ├── scripts/
│   │   └── validation/
│   └── java/
│       ├── metadata.json
│       ├── files/
│       │   ├── src/main/java/
│       │   ├── src/test/java/
│       │   ├── pom.xml.mustache
│       │   └── build.gradle.mustache
│       ├── scripts/
│       └── validation/
├── standards/                   # Coding standards and architectural guidelines
│   ├── architectural/
│   │   ├── clean-architecture.json
│   │   ├── ddd-patterns.json
│   │   ├── microservices.json
│   │   ├── api-design.json
│   │   └── security-patterns.json
│   ├── coding/
│   │   ├── typescript/
│   │   │   ├── style-guide.json
│   │   │   ├── best-practices.json
│   │   │   ├── patterns.json
│   │   │   └── anti-patterns.json
│   │   ├── go/
│   │   ├── python/
│   │   └── java/
│   ├── testing/
│   │   ├── unit-testing.json
│   │   ├── integration-testing.json
│   │   ├── e2e-testing.json
│   │   └── test-patterns.json
│   └── documentation/
│       ├── api-documentation.json
│       ├── readme-standards.json
│       ├── code-comments.json
│       └── architecture-docs.json
├── prompts/                     # Workflow prompt templates
│   ├── workflow/
│   │   ├── prd-generation.json
│   │   ├── technical-architecture.json
│   │   ├── feature-breakdown.json
│   │   └── user-story-prompts.json
│   ├── agent-modes/
│   │   ├── technical-product-owner.json
│   │   ├── system-architect.json
│   │   ├── frontend-developer.json
│   │   ├── backend-developer.json
│   │   ├── qa-engineer.json
│   │   └── devops-engineer.json
│   ├── coding-standards/
│   │   ├── code-review.json
│   │   ├── refactoring.json
│   │   └── optimization.json
│   └── validation/
│       ├── schema.json
│       └── examples/
├── configs/                     # Configuration templates
│   ├── opencode/
│   │   ├── base-config.json.mustache
│   │   ├── agent-modes.json.mustache
│   │   └── mcp-servers.json.mustache
│   ├── github/
│   │   ├── workflows/
│   │   │   ├── opencode.yml.mustache
│   │   │   ├── ci-cd.yml.mustache
│   │   │   ├── security-scan.yml.mustache
│   │   │   └── documentation.yml.mustache
│   │   └── templates/
│   │       ├── pull-request.md.mustache
│   │       └── issue.md.mustache
│   ├── devcontainer/
│   │   ├── devcontainer.json.mustache
│   │   └── docker-compose.yml.mustache
│   ├── vscode/
│   │   ├── settings.json.mustache
│   │   ├── extensions.json.mustache
│   │   └── launch.json.mustache
│   └── git/
│       ├── gitignore.mustache
│       └── gitattributes.mustache
└── schemas/                     # JSON schemas for validation
    ├── project-config.schema.json
    ├── opencode-config.schema.json
    ├── template-metadata.schema.json
    ├── standards.schema.json
    └── prompts.schema.json
```

### 5. Docker Configuration (`docker/`)

```
docker/
├── bootstrapper/               # Bootstrapper container configuration
│   ├── Dockerfile             # Multi-stage build for bootstrapper
│   ├── entrypoint.sh          # Container entry point script
│   └── .dockerignore          # Docker ignore rules
├── opencode/                  # OpenCode container customization
│   ├── Dockerfile.opencode    # OpenCode container modifications
│   ├── mcp-servers/           # MCP server installation scripts
│   │   ├── install-context7.sh
│   │   ├── install-github-mcp.sh
│   │   ├── install-playwright.sh
│   │   ├── install-shadcn-ui.sh
│   │   └── install-sequential-thinking.sh
│   ├── agents.md              # Global agent configuration
│   └── config/
│       ├── base-opencode.json
│       └── mcp-defaults.json
└── compose/                   # Docker Compose configurations
    ├── development.yml        # Development environment
    ├── production.yml         # Production environment
    └── testing.yml            # Testing environment
```

### 6. Scripts Directory (`scripts/`)

```
scripts/
├── build/                     # Build scripts
│   ├── build.sh              # Unix/Linux/macOS build script
│   ├── build.cmd             # Windows build script
│   ├── docker-build.sh       # Docker image build script
│   └── release.sh            # Release preparation script
├── setup/                     # Setup and installation scripts
│   ├── setup.sh              # Unix/Linux/macOS setup script
│   ├── setup.cmd             # Windows setup script
│   ├── install-deps.sh       # Dependency installation
│   └── verify-install.sh     # Installation verification
├── development/               # Development utilities
│   ├── dev-setup.sh          # Development environment setup
│   ├── test-runner.sh        # Test execution script
│   ├── lint-check.sh         # Linting and formatting
│   └── watch-build.sh        # Watch mode for development
└── deployment/                # Deployment scripts
    ├── deploy-registry.sh     # Container registry deployment
    ├── tag-release.sh         # Release tagging
    └── publish-npm.sh         # NPM package publishing
```

### 7. Testing Structure (`tests/`)

```
tests/
├── unit/                      # Unit tests
│   ├── cli/
│   │   ├── commands.test.ts
│   │   └── wizard.test.ts
│   ├── core/
│   │   ├── project-manager.test.ts
│   │   ├── template-engine.test.ts
│   │   └── config-manager.test.ts
│   ├── generators/
│   │   ├── project-generator.test.ts
│   │   └── config-generator.test.ts
│   └── utils/
│       ├── file-utils.test.ts
│       └── git-utils.test.ts
├── integration/               # Integration tests
│   ├── template-generation.test.ts
│   ├── opencode-deployment.test.ts
│   ├── asset-deployment.test.ts
│   └── github-integration.test.ts
├── e2e/                       # End-to-end tests
│   ├── complete-bootstrap.test.ts
│   ├── multi-language.test.ts
│   ├── iterative-setup.test.ts
│   └── error-recovery.test.ts
├── fixtures/                  # Test fixtures and mock data
│   ├── projects/
│   ├── templates/
│   ├── configs/
│   └── responses/
├── helpers/                   # Test utilities and helpers
│   ├── test-utils.ts
│   ├── mock-docker.ts
│   ├── mock-git.ts
│   └── temp-project.ts
└── setup/                     # Test environment setup
    ├── jest.setup.ts
    ├── docker-setup.ts
    └── cleanup.ts
```

### 8. Documentation Structure (`docs/`)

```
docs/
├── requirements.md            # Original requirements document
├── technical-requirements.md  # Technical specifications
├── repository-structure.md    # This document
├── implementation-plan.md     # Implementation roadmap
├── api/                       # API documentation
│   ├── cli-commands.md
│   ├── configuration.md
│   └── templates.md
├── guides/                    # User and developer guides
│   ├── getting-started.md
│   ├── template-development.md
│   ├── opencode-integration.md
│   └── troubleshooting.md
├── examples/                  # Usage examples
│   ├── typescript-project.md
│   ├── go-microservice.md
│   ├── python-api.md
│   └── java-enterprise.md
└── architecture/              # Architecture documentation
    ├── system-design.md
    ├── security-model.md
    ├── deployment-strategy.md
    └── integration-patterns.md
```

### 9. Component Relationships

#### 9.1 Bootstrapper → Project Workspace
- **Generates**: Project structure, configuration files, build scripts
- **Deploys**: Templates, standards, prompts to .ai directory
- **Configures**: Git repository, GitHub Actions, DevContainer setup

#### 9.2 Bootstrapper → OpenCode Container
- **Deploys**: OpenCode container with MCP servers
- **Configures**: Environment variables, volume mounts, agent modes
- **Validates**: Container health, MCP server connectivity

#### 9.3 Project Workspace → OpenCode Container
- **Volume Mounts**: Real-time access to project files and .ai assets
- **Configuration**: OpenCode reads from .opencode/opencode.json
- **Asset Access**: Templates, standards, and prompts available in container

#### 9.4 GitHub Actions → OpenCode Container
- **Triggers**: Issue comment workflows (/oc, /opencode)
- **Authentication**: GitHub secrets for API keys
- **Execution**: Headless OpenCode operation in CI/CD environment

### 10. Separation of Concerns

#### 10.1 Bootstrapper Responsibilities
- **One-time Setup**: Project initialization and configuration
- **Asset Deployment**: Templates, standards, and prompts
- **Container Deployment**: OpenCode container setup and configuration
- **Validation**: Verify successful handoff to OpenCode

#### 10.2 OpenCode Container Responsibilities
- **Ongoing Development**: AI-assisted development workflows
- **Code Generation**: Template-based code creation
- **Workflow Management**: SDLC phase management (PRD, Architecture, etc.)
- **Continuous Support**: Long-term project assistance

#### 10.3 Shared Assets (.ai directory)
- **User-Modifiable**: Templates, standards, prompts editable by user
- **Version Controlled**: Tracked in git (excluding sensitive config)
- **Real-time Updates**: Changes reflected in OpenCode container
- **Extensible**: Users can add custom templates and standards

### 11. Build and Deployment Flow

#### 11.1 Development Build
1. **Source Compilation**: TypeScript → JavaScript
2. **Asset Packaging**: Bundle templates, standards, prompts
3. **Docker Image**: Create bootstrapper container image
4. **Testing**: Unit, integration, and e2e tests
5. **Validation**: Cross-platform compatibility testing

#### 11.2 Release Process
1. **Version Tagging**: Semantic versioning
2. **Container Build**: Multi-arch Docker images
3. **Registry Push**: GitHub Container Registry
4. **Documentation**: Update guides and examples
5. **Release Notes**: Changelog and migration guides

This repository structure provides clear organization, separation of concerns, and scalability for the Horizon SDLC v2 bootstrapping application while maintaining clean boundaries between the bootstrapper tool and OpenCode container deployment.

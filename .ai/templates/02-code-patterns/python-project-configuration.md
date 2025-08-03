# Python Project Configuration Templates

## Overview
This template provides standardized configuration files for Python AI services in our NX monorepo, including pyproject.toml, requirements.txt, and testing configurations.

## pyproject.toml Configuration

### Standard AI Service Configuration
```toml
[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "ai-agents"
version = "1.0.0"
description = "LangChain-based AI agent orchestration service"
readme = "README.md"
license = {file = "LICENSE"}
authors = [
    {name = "Development Team", email = "dev@company.com"}
]
classifiers = [
    "Development Status :: 4 - Beta",
    "Intended Audience :: Developers",
    "License :: OSI Approved :: MIT License",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.11",
    "Programming Language :: Python :: 3.12",
]
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.100.0",
    "uvicorn[standard]>=0.23.0",
    "pydantic>=2.0.0",
    "pydantic-settings>=2.0.0",
    "langchain>=0.1.0",
    "langchain-google-vertexai>=1.0.0",
    "langgraph>=0.1.0",
    "google-genai>=0.1.0",
    "google-cloud-aiplatform>=1.40.0",
    "opentelemetry-api>=1.20.0",
    "opentelemetry-sdk>=1.20.0",
    "opentelemetry-instrumentation-fastapi>=0.41b0",
    "opentelemetry-exporter-otlp>=1.20.0",
    "redis>=5.0.0",
    "asyncpg>=0.29.0",
    "sqlalchemy[asyncio]>=2.0.0",
    "alembic>=1.12.0",
    "structlog>=23.0.0",
    "httpx>=0.25.0",
    "tenacity>=8.2.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.4.0",
    "pytest-asyncio>=0.21.0",
    "pytest-cov>=4.1.0",
    "pytest-mock>=3.11.0",
    "black>=23.0.0",
    "isort>=5.12.0",
    "mypy>=1.5.0",
    "ruff>=0.0.290",
    "pre-commit>=3.4.0",
]
test = [
    "pytest>=7.4.0",
    "pytest-asyncio>=0.21.0",
    "pytest-cov>=4.1.0",
    "pytest-mock>=3.11.0",
    "factory-boy>=3.3.0",
    "faker>=19.0.0",
]

[project.urls]
Homepage = "https://github.com/company/horizon-sdlc-v2"
Repository = "https://github.com/company/horizon-sdlc-v2"
Documentation = "https://docs.company.com/ai-agents"

[tool.setuptools.packages.find]
where = ["src"]

[tool.setuptools.package-data]
"*" = ["*.yaml", "*.yml", "*.json"]

# Black configuration
[tool.black]
line-length = 88
target-version = ['py311']
include = '\.pyi?$'
extend-exclude = '''
/(
  # directories
  \.eggs
  | \.git
  | \.hg
  | \.mypy_cache
  | \.tox
  | \.venv
  | build
  | dist
)/
'''

# isort configuration
[tool.isort]
profile = "black"
multi_line_output = 3
line_length = 88
known_first_party = ["src"]
known_third_party = ["fastapi", "langchain", "google", "opentelemetry"]

# MyPy configuration
[tool.mypy]
python_version = "3.11"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
disallow_incomplete_defs = true
check_untyped_defs = true
disallow_untyped_decorators = true
no_implicit_optional = true
warn_redundant_casts = true
warn_unused_ignores = true
warn_no_return = true
warn_unreachable = true
strict_equality = true

[[tool.mypy.overrides]]
module = [
    "langchain.*",
    "langgraph.*",
    "google.genai.*",
    "opentelemetry.*",
]
ignore_missing_imports = true

# Pytest configuration
[tool.pytest.ini_options]
minversion = "7.0"
addopts = [
    "--strict-markers",
    "--strict-config",
    "--cov=src",
    "--cov-report=term-missing",
    "--cov-report=html",
    "--cov-report=xml",
    "--cov-fail-under=80",
]
testpaths = ["tests"]
python_files = ["test_*.py", "*_test.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
markers = [
    "unit: Unit tests",
    "integration: Integration tests",
    "e2e: End-to-end tests",
    "slow: Slow running tests",
]
asyncio_mode = "auto"

# Coverage configuration
[tool.coverage.run]
source = ["src"]
omit = [
    "*/tests/*",
    "*/test_*",
    "*/__pycache__/*",
    "*/migrations/*",
]

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "if self.debug:",
    "if settings.DEBUG",
    "raise AssertionError",
    "raise NotImplementedError",
    "if 0:",
    "if __name__ == .__main__.:",
    "class .*\\bProtocol\\):",
    "@(abc\\.)?abstractmethod",
]

# Ruff configuration
[tool.ruff]
target-version = "py311"
line-length = 88
select = [
    "E",  # pycodestyle errors
    "W",  # pycodestyle warnings
    "F",  # pyflakes
    "I",  # isort
    "B",  # flake8-bugbear
    "C4", # flake8-comprehensions
    "UP", # pyupgrade
]
ignore = [
    "E501",  # line too long, handled by black
    "B008",  # do not perform function calls in argument defaults
    "C901",  # too complex
]

[tool.ruff.per-file-ignores]
"__init__.py" = ["F401"]
"tests/*" = ["B011"]

[tool.ruff.isort]
known-first-party = ["src"]
```

## requirements.txt

### Production Dependencies
```txt
# Web Framework
fastapi==0.104.1
uvicorn[standard]==0.24.0

# Data Validation
pydantic==2.5.0
pydantic-settings==2.1.0

# AI/ML Libraries
langchain==0.1.0
langchain-google-vertexai==1.0.1
langgraph==0.1.0
google-genai==0.3.0
google-cloud-aiplatform==1.40.0

# Observability
opentelemetry-api==1.21.0
opentelemetry-sdk==1.21.0
opentelemetry-instrumentation-fastapi==0.42b0
opentelemetry-exporter-otlp==1.21.0
structlog==23.2.0

# Database
redis==5.0.1
asyncpg==0.29.0
sqlalchemy[asyncio]==2.0.23
alembic==1.13.1

# HTTP Client
httpx==0.25.2

# Utilities
tenacity==8.2.3
python-multipart==0.0.6
python-jose[cryptography]==3.3.0
```

## Development Configuration Files

### .env.example
```bash
# Google Cloud Configuration
GOOGLE_CLOUD_PROJECT=your-project-id
GOOGLE_CLOUD_LOCATION=us-central1
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json

# Model Configuration
DEFAULT_MODEL=gemini-2.0-flash-001
MAX_TOKENS=8192
TEMPERATURE=0.7

# OpenTelemetry Configuration
OTEL_SERVICE_NAME=ai-agents
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317

# Database Configuration
DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/ai_agents
REDIS_URL=redis://localhost:6379/0

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
DEBUG=true
LOG_LEVEL=INFO

# Security
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

### .gitignore
```gitignore
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# Virtual environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Testing
.coverage
.pytest_cache/
htmlcov/
.tox/
.cache
nosetests.xml
coverage.xml
*.cover
.hypothesis/

# MyPy
.mypy_cache/
.dmypy.json
dmypy.json

# Jupyter
.ipynb_checkpoints

# OS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Logs
*.log
logs/

# Database
*.db
*.sqlite3

# Secrets
.env.local
.env.production
*.pem
*.key
service-account.json
```

### pre-commit-config.yaml
```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-merge-conflict
      - id: debug-statements

  - repo: https://github.com/psf/black
    rev: 23.9.1
    hooks:
      - id: black
        language_version: python3.11

  - repo: https://github.com/pycqa/isort
    rev: 5.12.0
    hooks:
      - id: isort

  - repo: https://github.com/charliermarsh/ruff-pre-commit
    rev: v0.0.290
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.5.1
    hooks:
      - id: mypy
        additional_dependencies: [types-all]
```

## NX Project Configuration

### project.json
```json
{
  "name": "ai-agents",
  "projectType": "application",
  "sourceRoot": "apps/ai-agents/src",
  "targets": {
    "serve": {
      "executor": "@nrwl/workspace:run-commands",
      "options": {
        "command": "python -m uvicorn src.api.main:app --reload --host 0.0.0.0 --port 8000",
        "cwd": "apps/ai-agents"
      }
    },
    "test": {
      "executor": "@nrwl/workspace:run-commands",
      "options": {
        "command": "python -m pytest",
        "cwd": "apps/ai-agents"
      }
    },
    "test:cov": {
      "executor": "@nrwl/workspace:run-commands",
      "options": {
        "command": "python -m pytest --cov=src --cov-report=html",
        "cwd": "apps/ai-agents"
      }
    },
    "lint": {
      "executor": "@nrwl/workspace:run-commands",
      "options": {
        "command": "ruff check src tests",
        "cwd": "apps/ai-agents"
      }
    },
    "format": {
      "executor": "@nrwl/workspace:run-commands",
      "options": {
        "command": "black src tests && isort src tests",
        "cwd": "apps/ai-agents"
      }
    },
    "type-check": {
      "executor": "@nrwl/workspace:run-commands",
      "options": {
        "command": "mypy src",
        "cwd": "apps/ai-agents"
      }
    },
    "build": {
      "executor": "@nrwl/workspace:run-commands",
      "options": {
        "command": "docker build -t ai-agents .",
        "cwd": "apps/ai-agents"
      }
    }
  },
  "tags": ["type:app", "scope:ai", "platform:python"]
}
```

# Generic Development Container for Code Review

This directory contains a lightweight development container configuration for GitHub Codespaces and VS Code Dev Containers, optimized for code review and inspection across different projects and programming languages.

## 🚀 Quick Start

### GitHub Codespaces
1. Click the "Code" button on the GitHub repository
2. Select "Codespaces" tab
3. Click "Create codespace on main"
4. Wait for the container to build and setup to complete
5. Start reviewing code!

### VS Code Dev Containers
1. Install the "Dev Containers" extension in VS Code
2. Open the repository in VS Code
3. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
4. Select "Dev Containers: Reopen in Container"
5. Wait for the container to build and setup to complete
6. Start reviewing code!

## 📦 What's Included

### Base Environment
- **OS**: Ubuntu 22.04 (via Microsoft's dev container base)
- **Node.js**: Version 20 LTS
- **TypeScript**: Latest version with essential toolchain
- **Python**: 3.11 with development tools
- **Go**: Latest version
- **Docker**: Docker-in-Docker support for container inspection

### Development Tools
- **GitHub CLI**: For repository management and PR reviews
- **Terraform**: For infrastructure as code inspection
- **Git**: Pre-configured with sensible defaults
- **Essential npm packages**: TypeScript, ESLint, Prettier
- **Python tools**: Black, Ruff, MyPy, isort, pytest

### VS Code Extensions
- **Code Review**: GitHub Copilot, GitHub PR management
- **TypeScript**: Enhanced TypeScript support
- **Docker**: Container inspection tools
- **Git**: GitHub integration and pull request management
- **Terraform**: Infrastructure as code support
- **Python & Go**: Language support
- **Markdown**: Enhanced markdown with Mermaid diagrams
- **JSON/YAML**: Configuration file support

## 🔧 Configuration

### Environment Variables
Copy `.env.template` to `.env` and configure as needed:

```bash
# Development environment
NODE_ENV=development

# Optional: GitHub integration for PR reviews
GITHUB_TOKEN=your_github_token_here

# Add project-specific variables as needed
```

### Helpful Aliases
The setup script creates essential aliases:

```bash
# Docker Compose shortcuts
dcu         # docker-compose up -d
dcd         # docker-compose down
dcl         # docker-compose logs -f
dcr         # docker-compose restart

# Git shortcuts
gs          # git status
ga          # git add
gc          # git commit
gp          # git push
gl          # git pull
gb          # git branch
gco         # git checkout
```

## 🏗️ Code Review Workflow

### 1. Initial Setup
```bash
# Load aliases (if needed)
source ~/.bashrc

# Configure project-specific environment variables (optional)
cp .env.template .env  # if template exists
code .env
```

### 2. Basic Development Commands
```bash
# TypeScript projects
npm install
npm run build
npm run test
npm run lint

# Python projects
pip install -r requirements.txt
python -m pytest
black .
ruff check .

# Git workflow for code review
gs              # Check status
ga .            # Stage changes
gc "message"    # Commit changes
gp              # Push changes
```

### 3. Container Management (if using Docker Compose)
```bash
# Start services
dcu

# View logs
dcl

# Restart services
dcr

# Stop services
dcd
```

## 📁 Container Structure

```
.devcontainer/
├── devcontainer.json       # Main container configuration
├── Dockerfile              # Custom container image
├── setup.sh               # Post-create setup script
├── README.md              # This documentation
└── .gitignore             # Ignore local dev files
```

This configuration can be copied to any repository to provide a consistent development environment.

## 🔒 Security Features

- **Non-root user**: Container runs as `vscode` user
- **Privileged mode**: Only for Docker-in-Docker functionality
- **Environment protection**: Local .env files are gitignored
- **Container isolation**: Proper volume mounts and network isolation

## 🐛 Troubleshooting

### Container Build Issues
```bash
# Rebuild without cache
Dev Containers: Rebuild Container (No Cache)
```

### Docker Socket Issues
```bash
# Check Docker socket permissions
ls -la /var/run/docker.sock

# Restart Docker service if needed
sudo service docker restart
```

### Port Conflicts
The container forwards these ports:
- `3000`: Development Server
- `8080`: Additional Services

If you encounter port conflicts, modify the `forwardPorts` in `devcontainer.json`.

## 📚 Additional Resources

- [GitHub Codespaces Documentation](https://docs.github.com/en/codespaces)
- [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)
- [Docker-in-Docker](https://github.com/devcontainers/features/tree/main/src/docker-in-docker)

## 🆘 Getting Help

1. **Rebuild the container:**
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
   - Type "Dev Containers: Rebuild Container"

2. **Verify tools:**
   ```bash
   node --version
   python3 --version
   git --version
   ```

3. **Check GitHub Codespaces status:**
   - Visit [GitHub Codespaces](https://github.com/codespaces) for service status

## 🤝 Contributing

When modifying the dev container configuration:

1. Test changes locally with VS Code Dev Containers
2. Verify the setup script works correctly
3. Update this README with any new features or requirements
4. Test in GitHub Codespaces before merging

---

**Happy code reviewing!** 🚀

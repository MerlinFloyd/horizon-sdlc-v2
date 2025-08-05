# Generic Development Container for Code Review and Inspection
# Based on Microsoft's Ubuntu dev container image

FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_VERSION=20

# Install essential system dependencies
RUN apt-get update && apt-get install -y \
    # Build tools and utilities
    build-essential \
    curl \
    wget \
    git \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    jq \
    unzip \
    zip \
    tree \
    htop \
    # Text editors and utilities
    vim \
    nano \
    less \
    # Python dependencies
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    # Additional utilities
    procps \
    file \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Install GitHub CLI (latest version)
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && wget -nv -O /tmp/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && cat /tmp/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/* /tmp/githubcli-archive-keyring.gpg

# Install Terraform CLI
RUN wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null \
    && gpg --no-default-keyring \
    --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    --fingerprint \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=VERSION_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update \
    && apt-get install -y terraform \
    && rm -rf /var/lib/apt/lists/*

# Switch to vscode user for the rest of the setup
USER vscode

# Install essential npm packages for development and code review
RUN npm install -g \
    # Core development tools
    typescript@latest \
    ts-node@latest \
    prettier@latest \
    eslint@latest \
    @typescript-eslint/parser@latest \
    @typescript-eslint/eslint-plugin@latest \
    # Additional utilities
    nodemon@latest

# Install essential Python development tools
RUN pip3 install --user \
    black \
    ruff \
    mypy \
    isort \
    pytest

# Create necessary directories
RUN mkdir -p /home/vscode/.local/bin

# Set up Git configuration defaults
RUN git config --global init.defaultBranch main \
    && git config --global pull.rebase false \
    && git config --global core.autocrlf input \
    && git config --global core.editor "code --wait"

# Add essential aliases for development and code review
RUN echo '' >> /home/vscode/.bashrc \
    && echo '# Development Container Aliases' >> /home/vscode/.bashrc \
    && echo 'alias dcu="docker-compose up -d"' >> /home/vscode/.bashrc \
    && echo 'alias dcd="docker-compose down"' >> /home/vscode/.bashrc \
    && echo 'alias dcl="docker-compose logs -f"' >> /home/vscode/.bashrc \
    && echo 'alias dcr="docker-compose restart"' >> /home/vscode/.bashrc \
    && echo 'alias gs="git status"' >> /home/vscode/.bashrc \
    && echo 'alias ga="git add"' >> /home/vscode/.bashrc \
    && echo 'alias gc="git commit"' >> /home/vscode/.bashrc \
    && echo 'alias gp="git push"' >> /home/vscode/.bashrc \
    && echo 'alias gl="git pull"' >> /home/vscode/.bashrc \
    && echo 'alias gb="git branch"' >> /home/vscode/.bashrc \
    && echo 'alias gco="git checkout"' >> /home/vscode/.bashrc

# Set working directory
WORKDIR /workspaces

# Switch back to root for any final system-level setup
USER root

# Ensure proper permissions for Docker socket (will be handled by features)
RUN echo '#!/bin/bash\nsudo chmod 666 /var/run/docker.sock 2>/dev/null || true' > /usr/local/bin/fix-docker-socket \
    && chmod +x /usr/local/bin/fix-docker-socket

# Switch back to vscode user
USER vscode

# Set default shell
SHELL ["/bin/bash", "-c"]

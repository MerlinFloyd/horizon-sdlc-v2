# OpenCode Container with MCP Servers
# Based on Ubuntu 22.04 with Node.js 20+ for OpenCode and MCP server compatibility

FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_VERSION=20
ENV OPENCODE_VERSION=latest
ENV WORKSPACE_DIR=/workspace
ENV OPENCODE_CONFIG_DIR=/root/.config/opencode
ENV AI_ASSETS_DIR=/.ai

# Headless clipboard environment variables
ENV DISPLAY=:99
ENV XVFB_DISPLAY=:99
ENV XVFB_SCREEN=0
ENV XVFB_RESOLUTION=1024x768x24

# MCP Server Environment Variables (to be set at runtime)
# GitHub MCP Server and GitHub CLI authentication
ENV GITHUB_TOKEN=""

# Magic MCP Server (21st.dev)
ENV TWENTY_FIRST_API_KEY=""

# Terraform Cloud Token (MUST be READ-ONLY)
ENV TF_CLOUD_TOKEN=""

# GCP Credentials (for Terraform with GCP provider) (MUST be READ-ONLY)
ENV GOOGLE_APPLICATION_CREDENTIALS=""

# Install system dependencies including clipboard utilities
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    xclip \
    xsel \
    wl-clipboard \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && wget -nv -O /tmp/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && cat /tmp/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/* /tmp/githubcli-archive-keyring.gpg

# Install Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Install Docker CLI (for potential container management)
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# Install Terraform CLI
RUN wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null \
    && gpg --no-default-keyring \
    --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    --fingerprint \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update \
    && apt-get install -y terraform \
    && rm -rf /var/lib/apt/lists/*

# Create workspace, OpenCode, and logging directories
RUN mkdir -p $WORKSPACE_DIR /var/log/opencode

# Install OpenCode
RUN npm install -g opencode-ai@latest

# Install MCP Servers

# 1. Install Context7 MCP Server
RUN npm install -g @upstash/context7-mcp@latest

# 2. Install GitHub MCP Server
RUN npm install -g @modelcontextprotocol/server-github@latest

# 3. Install Playwright MCP Server
RUN npm install -g @playwright/mcp@latest

# 4. Install Sequential Thinking MCP Server
RUN npm install -g @modelcontextprotocol/server-sequential-thinking@latest

# 5. Install ShadCN UI MCP Server
# RUN npm install -g @jpisnice/shadcn-ui-mcp-server@latest

# 6. Install Magic MCP Server
RUN npx @21st-dev/magic@latest

# Create OpenCode configuration directory and copy files
RUN mkdir -p $OPENCODE_CONFIG_DIR $OPENCODE_CONFIG_DIR/agent $AI_ASSETS_DIR/prompts
COPY config/opencode.json.template $OPENCODE_CONFIG_DIR/opencode.json
COPY config/AGENTS.md $OPENCODE_CONFIG_DIR/AGENTS.md

# Copy agent Markdown files to global agent directory
COPY config/agent/ $OPENCODE_CONFIG_DIR/agent/

# Copy prompt files to AI assets directory
COPY config/prompts/ $AI_ASSETS_DIR/prompts/

# Set proper permissions for OpenCode to read configuration files and write logs
RUN chmod -R 644 $OPENCODE_CONFIG_DIR/ && \
    chmod -R 644 $AI_ASSETS_DIR/ && \
    chmod 755 $OPENCODE_CONFIG_DIR && \
    chmod 755 $OPENCODE_CONFIG_DIR/agent && \
    chmod 755 $AI_ASSETS_DIR && \
    chmod 755 $AI_ASSETS_DIR/prompts && \
    chmod 755 /var/log/opencode

# Copy scripts and logging module
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY scripts/libs/logging.sh /usr/local/lib/logging.sh

# Set working directory
WORKDIR $WORKSPACE_DIR

# Health check script
COPY scripts/healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/healthcheck.sh

# Health check configuration
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh

# Expose OpenCode default port (if applicable)
EXPOSE 3000

# Set entrypoint - using consolidated entrypoint for better OpenCode compatibility
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

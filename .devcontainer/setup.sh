#!/bin/bash
# Generic Development Container Setup Script
# This script sets up a lightweight development environment for code review and inspection

set -e

echo "🚀 Setting up development environment for code review..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Update system packages
log_info "Updating system packages..."
sudo apt-get update -qq

# Install additional system dependencies
log_info "Installing additional system dependencies..."
sudo apt-get install -y -qq \
    curl \
    wget \
    git \
    build-essential \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    xclip \
    xsel \
    wl-clipboard \
    xvfb \
    jq \
    unzip \
    zip

# Verify Node.js and npm installation
log_info "Verifying Node.js installation..."
node --version
npm --version

# Verify global npm packages are already installed (from Dockerfile)
log_info "Verifying development tools..."
npm list -g --depth=0 || log_warning "Some global packages may not be installed"

# Verify Python development tools
log_info "Verifying Python tools..."
python3 --version
pip3 --version

# Set up Git configuration (if not already configured)
if [ -z "$(git config --global user.name)" ]; then
    log_info "Setting up Git configuration..."
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global core.autocrlf input
fi

# Create necessary directories
log_info "Creating development directories..."
mkdir -p ~/.local/bin

# Set up Docker socket permissions
log_info "Setting up Docker permissions..."
sudo chmod 666 /var/run/docker-host.sock || true

# Create symlink for Docker socket
sudo ln -sf /var/run/docker-host.sock /var/run/docker.sock || true

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    log_info "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Set up basic environment template if needed
log_info "Setting up environment template..."
if [ ! -f .env ] && [ ! -f .env.template ]; then
    cat > .env.template << 'EOF'
# Development Environment Configuration
NODE_ENV=development

# Optional: GitHub Integration
GITHUB_TOKEN=your_github_token_here

# Optional: Additional API keys as needed
# Add your project-specific environment variables here
EOF
    log_info "Created basic .env.template"
fi

# Make scripts executable if they exist
log_info "Making scripts executable..."
find . -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true

# Install project dependencies if package.json exists
if [ -f package.json ]; then
    log_info "Installing project dependencies..."
    npm install
fi

# Skip project-specific configuration setup

# Create essential aliases
log_info "Setting up essential aliases..."
cat >> ~/.bashrc << 'EOF'

# Development Container Aliases
alias dcu='docker-compose up -d'
alias dcd='docker-compose down'
alias dcl='docker-compose logs -f'
alias dcr='docker-compose restart'

# Git Aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gb='git branch'
alias gco='git checkout'

EOF

log_success "Development environment setup completed! 🎉"
log_info "Next steps:"
echo "  1. Run 'source ~/.bashrc' to load new aliases"
echo "  2. Configure any project-specific environment variables in .env"
echo "  3. Start exploring and reviewing code!"
echo ""
log_info "Available aliases:"
echo "  dcu/dcd     - Docker Compose up/down"
echo "  dcl/dcr     - Docker Compose logs/restart"
echo "  gs/ga/gc    - Git status/add/commit"
echo "  gp/gl       - Git push/pull"
echo "  gb/gco      - Git branch/checkout"
echo ""
log_success "Happy code reviewing! 🚀"

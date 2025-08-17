#!/bin/bash

# Minimal post-create script for Horizon SDLC Development Container
# This script runs once after the container is created

set -e

echo "🚀 Setting up minimal development environment..."

# Install essential utilities
echo "📦 Installing essential utilities..."
sudo apt-get update && sudo apt-get install -y \
    jq \
    tree \
    vim \
    nano \
    && sudo rm -rf /var/lib/apt/lists/*

# Set up Git configuration with automatic detection and fallbacks
echo "🔧 Configuring Git..."

# Function to safely get git config value
get_git_config() {
    git config --global "$1" 2>/dev/null || echo ""
}

# Check if Git is already configured (from mounted .gitconfig)
USER_NAME=$(get_git_config "user.name")
USER_EMAIL=$(get_git_config "user.email")

if [ -n "$USER_NAME" ] && [ -n "$USER_EMAIL" ]; then
    echo "✅ Git already configured:"
    echo "   Name: $USER_NAME"
    echo "   Email: $USER_EMAIL"
else
    echo "⚠️  Git configuration incomplete."

    # check and user guidance
    if [ -z "$USER_NAME" ] || [ -z "$USER_EMAIL" ]; then
        echo ""
        echo "❌ Git configuration still incomplete. Please configure manually:"
        [ -z "$USER_NAME" ] && echo "   git config --global user.name 'Your Name'"
        [ -z "$USER_EMAIL" ] && echo "   git config --global user.email 'your.email@example.com'"
        echo ""
        echo "💡 Tip: You can also set these in your host ~/.gitconfig and restart the container"
    else
        echo "✅ Git configuration completed automatically"
    fi
fi

# Create basic aliases
echo "🔗 Setting up basic aliases..."
cat >> ~/.bashrc << 'EOF'

# Basic aliases
alias ll='ls -alF'
alias la='ls -A'
alias ..='cd ..'
alias dc='docker-compose'
alias gs='git status'

EOF

# Set proper permissions
echo "🔐 Setting permissions..."
sudo chown -R dev:dev /workspace
chmod -R 755 /workspace

echo "✅ Minimal setup completed!"
echo ""
echo "🎯 Basic development environment ready"
echo "Next steps:"
echo "1. Configure Git if needed"
echo "2. Start developing!"

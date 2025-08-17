#!/bin/bash

# Minimal post-start script for Horizon SDLC Development Container
# This script runs every time the container starts

set -e

echo "🔄 Starting minimal development environment..."

# Check basic tools
echo "🔧 Checking basic tools..."

if command -v docker &> /dev/null; then
    echo "✅ Docker CLI available"

    # Check Docker socket permissions and fix if needed
    if [ -S /var/run/docker.sock ]; then
        echo "🔧 Checking Docker socket permissions..."

        # Get the group ID of the Docker socket
        DOCKER_SOCK_GID=$(stat -c '%g' /var/run/docker.sock)

        # Check if docker group exists and has the right GID
        if ! getent group docker > /dev/null 2>&1; then
            echo "🔧 Creating docker group..."
            sudo groupadd -g $DOCKER_SOCK_GID docker
        else
            # Update docker group GID to match socket
            CURRENT_DOCKER_GID=$(getent group docker | cut -d: -f3)
            if [ "$CURRENT_DOCKER_GID" != "$DOCKER_SOCK_GID" ]; then
                echo "🔧 Updating docker group GID to match socket..."
                sudo groupmod -g $DOCKER_SOCK_GID docker
            fi
        fi

        # Add dev user to docker group if not already a member
        if ! groups dev | grep -q docker; then
            echo "🔧 Adding dev user to docker group..."
            sudo usermod -aG docker dev
        fi

        # Test Docker access
        if docker info > /dev/null 2>&1; then
            echo "✅ Docker daemon accessible"
        else
            echo "⚠️  Docker daemon not accessible - you may need to restart the container"
        fi
    else
        echo "⚠️  Docker socket not found at /var/run/docker.sock"
    fi
else
    echo "❌ Docker CLI not available"
fi

if command -v gh &> /dev/null; then
    echo "✅ GitHub CLI available"
else
    echo "❌ GitHub CLI not available"
fi

if command -v node &> /dev/null; then
    echo "✅ Node.js available: $(node --version)"
else
    echo "❌ Node.js not available"
fi

if command -v npm &> /dev/null; then
    echo "✅ npm available: $(npm --version)"
else
    echo "❌ npm not available"
fi

# Check Git configuration
echo "🔧 Checking Git configuration..."
USER_NAME=$(git config --global user.name 2>/dev/null || echo "")
USER_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [ -n "$USER_NAME" ] && [ -n "$USER_EMAIL" ]; then
    echo "✅ Git configured: $USER_NAME <$USER_EMAIL>"
else
    echo "⚠️  Git configuration incomplete"
    [ -z "$USER_NAME" ] && echo "   Missing: user.name"
    [ -z "$USER_EMAIL" ] && echo "   Missing: user.email"
fi

# Set up workspace permissions
echo "🔐 Ensuring proper workspace permissions..."
sudo chown -R dev:dev /workspace 2>/dev/null || true

# Ensure execute permissions on scripts
echo "🔐 Ensuring execute permissions on scripts..."
if [ -d "/workspace/scripts" ]; then
    chmod +x /workspace/scripts/*.sh 2>/dev/null || true
    find /workspace/scripts -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true
    echo "✅ Execute permissions ensured for scripts"
fi

# Final Docker connectivity test
if command -v docker &> /dev/null && [ -S /var/run/docker.sock ]; then
    echo "🐳 Testing Docker connectivity..."
    if docker version > /dev/null 2>&1; then
        echo "✅ Docker is fully functional!"
    else
        echo "⚠️  Docker CLI available but daemon not accessible"
    fi
fi

echo "✅ Environment ready!"

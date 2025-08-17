#!/bin/bash

# Minimal post-start script for Horizon SDLC Development Container
# This script runs every time the container starts

set -e

echo "🔄 Starting minimal development environment..."

# Check basic tools
echo "🔧 Checking basic tools..."

if command -v docker &> /dev/null; then
    echo "✅ Docker CLI available"
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

echo "✅ Environment ready!"

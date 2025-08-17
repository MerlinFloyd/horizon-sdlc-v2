#!/bin/bash

# Fix Docker Permissions Script
# This script fixes common Docker socket permission issues in the devcontainer

set -e

echo "🔧 Docker Permission Fix Script"
echo "================================"

# Check if Docker socket exists
if [ ! -S /var/run/docker.sock ]; then
    echo "❌ Docker socket not found at /var/run/docker.sock"
    echo "   Make sure Docker is running and the socket is mounted in the container"
    exit 1
fi

echo "✅ Docker socket found"

# Get current socket information
DOCKER_SOCK_GID=$(stat -c '%g' /var/run/docker.sock)
DOCKER_SOCK_GROUP=$(stat -c '%G' /var/run/docker.sock)
SOCKET_PERMS=$(stat -c '%a' /var/run/docker.sock)

echo "📊 Current Docker socket info:"
echo "   Group: $DOCKER_SOCK_GROUP (GID: $DOCKER_SOCK_GID)"
echo "   Permissions: $SOCKET_PERMS"

# Check if docker group exists
if ! getent group docker > /dev/null 2>&1; then
    echo "🔧 Creating docker group with GID $DOCKER_SOCK_GID..."
    sudo groupadd -g $DOCKER_SOCK_GID docker
else
    # Update docker group GID to match socket
    CURRENT_DOCKER_GID=$(getent group docker | cut -d: -f3)
    if [ "$CURRENT_DOCKER_GID" != "$DOCKER_SOCK_GID" ]; then
        echo "🔧 Updating docker group GID from $CURRENT_DOCKER_GID to $DOCKER_SOCK_GID..."
        sudo groupmod -g $DOCKER_SOCK_GID docker
    fi
fi

# Fix socket group ownership
if [ "$DOCKER_SOCK_GROUP" != "docker" ]; then
    echo "🔧 Fixing Docker socket group ownership..."
    sudo chgrp docker /var/run/docker.sock
    echo "✅ Socket group ownership fixed"
fi

# Fix socket permissions
if [ "$SOCKET_PERMS" != "660" ]; then
    echo "🔧 Setting Docker socket permissions to 660..."
    sudo chmod 660 /var/run/docker.sock
    echo "✅ Socket permissions fixed"
fi

# Add current user to docker group if not already a member
CURRENT_USER=$(whoami)
if ! groups $CURRENT_USER | grep -q docker; then
    echo "🔧 Adding $CURRENT_USER to docker group..."
    sudo usermod -aG docker $CURRENT_USER
    echo "✅ User added to docker group"
    echo "⚠️  You may need to restart your shell or run 'newgrp docker' for changes to take effect"
fi

# Test Docker access
echo "🧪 Testing Docker access..."
if docker info > /dev/null 2>&1; then
    echo "✅ Docker is accessible!"
    echo "🐳 Docker version: $(docker --version)"
else
    echo "⚠️  Docker still not accessible. Trying group refresh..."
    if newgrp docker -c 'docker info > /dev/null 2>&1'; then
        echo "✅ Docker accessible after group refresh!"
        echo "💡 Run 'newgrp docker' or restart your shell to use Docker"
    else
        echo "❌ Docker still not accessible. You may need to:"
        echo "   1. Restart the devcontainer"
        echo "   2. Check if Docker daemon is running on the host"
        echo "   3. Verify the Docker socket is properly mounted"
    fi
fi

echo ""
echo "🎉 Docker permission fix complete!"
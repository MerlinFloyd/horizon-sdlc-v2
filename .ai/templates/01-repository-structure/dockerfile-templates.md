# Dockerfile Templates

## Overview
This template provides Dockerfile examples for different application types following our containerization standards with Alpine-based images, multi-stage builds, and security best practices.

## Next.js Application Dockerfile

### Production-Optimized Multi-Stage Build
```dockerfile
# Build stage
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Install dependencies first (for better caching)
COPY package*.json ./
COPY nx.json ./
COPY tsconfig.base.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy source code
COPY . .

# Build the application
RUN npx nx build web-dashboard --prod

# Production stage
FROM node:18-alpine AS runner

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Set working directory
WORKDIR /app

# Copy built application
COPY --from=builder --chown=nextjs:nodejs /app/dist/apps/web-dashboard/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/dist/apps/web-dashboard/.next/static ./apps/web-dashboard/.next/static
COPY --from=builder --chown=nextjs:nodejs /app/dist/apps/web-dashboard/public ./apps/web-dashboard/public

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/api/health || exit 1

# Start the application
CMD ["node", "apps/web-dashboard/server.js"]
```

## Node.js API Dockerfile

### Express/Fastify API Container
```dockerfile
# Build stage
FROM node:18-alpine AS builder

# Install build dependencies
RUN apk add --no-cache python3 make g++

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./
COPY nx.json ./
COPY tsconfig.base.json ./

# Install all dependencies (including dev dependencies for build)
RUN npm ci

# Copy source code
COPY . .

# Build the application
RUN npx nx build api-core --prod

# Production stage
FROM node:18-alpine AS runner

# Install curl for health checks
RUN apk add --no-cache curl

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 apiuser

# Set working directory
WORKDIR /app

# Copy built application and production dependencies
COPY --from=builder --chown=apiuser:nodejs /app/dist/apps/api-core ./
COPY --from=builder --chown=apiuser:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=apiuser:nodejs /app/package*.json ./

# Switch to non-root user
USER apiuser

# Expose port
EXPOSE 3001

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3001/health || exit 1

# Start the application
CMD ["node", "main.js"]
```

## Smart Contract Deployment Dockerfile

### Foundry-based Blockchain Deployer
```dockerfile
# Build stage
FROM node:18-alpine AS node-builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./
COPY nx.json ./
COPY tsconfig.base.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build TypeScript components
RUN npx nx build blockchain-deployer --prod

# Foundry stage
FROM ghcr.io/foundry-rs/foundry:latest AS foundry-builder

# Set working directory
WORKDIR /app

# Copy contract source
COPY contracts/ ./contracts/
COPY foundry.toml ./

# Compile contracts
RUN forge build

# Production stage
FROM node:18-alpine AS runner

# Install curl for health checks
RUN apk add --no-cache curl

# Create non-root user
RUN addgroup --system --gid 1001 blockchain
RUN adduser --system --uid 1001 deployer

# Set working directory
WORKDIR /app

# Copy built application
COPY --from=node-builder --chown=deployer:blockchain /app/dist/apps/blockchain-deployer ./
COPY --from=node-builder --chown=deployer:blockchain /app/node_modules ./node_modules

# Copy compiled contracts
COPY --from=foundry-builder --chown=deployer:blockchain /app/out ./contracts/out

# Switch to non-root user
USER deployer

# Expose port
EXPOSE 3002

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3002

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3002/health || exit 1

# Start the application
CMD ["node", "main.js"]
```

## Storybook Documentation Dockerfile

### Shared UI Library Documentation
```dockerfile
# Build stage
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./
COPY nx.json ./
COPY tsconfig.base.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build Storybook
RUN npx nx build-storybook shared-ui

# Production stage
FROM nginx:alpine AS runner

# Copy built Storybook
COPY --from=builder /app/dist/storybook/shared-ui /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Create non-root user
RUN adduser -D -s /bin/sh nginx-user

# Change ownership of nginx directories
RUN chown -R nginx-user:nginx-user /usr/share/nginx/html
RUN chown -R nginx-user:nginx-user /var/cache/nginx
RUN chown -R nginx-user:nginx-user /var/log/nginx
RUN chown -R nginx-user:nginx-user /etc/nginx/conf.d

# Switch to non-root user
USER nginx-user

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080 || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
```

## Python AI Service Dockerfile

### Production-Optimized Multi-Stage Build
```dockerfile
# Build stage
FROM python:3.11-alpine AS builder

# Set working directory
WORKDIR /app

# Install system dependencies for building
RUN apk add --no-cache \
    gcc \
    musl-dev \
    libffi-dev \
    openssl-dev \
    cargo \
    rust

# Copy dependency files
COPY pyproject.toml requirements.txt ./

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Production stage
FROM python:3.11-alpine AS runner

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

# Set working directory
WORKDIR /app

# Install runtime dependencies
RUN apk add --no-cache \
    libffi \
    openssl

# Copy Python dependencies from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code
COPY --chown=appuser:appgroup src/ ./src/
COPY --chown=appuser:appgroup pyproject.toml requirements.txt ./

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health')" || exit 1

# Start application
CMD ["python", "-m", "uvicorn", "src.api.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Docker Compose Integration

### Local Development Stack
```yaml
version: '3.8'

services:
  web-dashboard:
    build:
      context: .
      dockerfile: apps/web-dashboard/Dockerfile
      target: runner
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgresql://user:password@postgres:5432/horizon
      - REDIS_URL=redis://redis:6379
    depends_on:
      - postgres
      - redis
    volumes:
      - ./apps/web-dashboard:/app/apps/web-dashboard
      - /app/node_modules

  api-core:
    build:
      context: .
      dockerfile: apps/api-core/Dockerfile
      target: runner
    ports:
      - "3001:3001"
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgresql://user:password@postgres:5432/horizon
      - REDIS_URL=redis://redis:6379
    depends_on:
      - postgres
      - redis
    volumes:
      - ./apps/api-core:/app/apps/api-core
      - /app/node_modules

  storybook:
    build:
      context: .
      dockerfile: libs/shared/ui/Dockerfile
      target: runner
    ports:
      - "6006:8080"
    volumes:
      - ./libs/shared/ui:/app/libs/shared/ui
      - /app/node_modules

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=horizon
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

## Build Scripts

### Push to Registry
```bash
#!/bin/bash
# push-images.sh

REGISTRY="ghcr.io/horizon"
TAG=${1:-latest}

# Tag and push all images
for service in web-dashboard web-marketplace api-core api-payments blockchain-deployer storybook; do
  docker tag horizon/$service:latest $REGISTRY/$service:$TAG
  docker push $REGISTRY/$service:$TAG
done

echo "All images pushed to registry!"
```

This template provides production-ready Dockerfile configurations following our security and optimization standards.

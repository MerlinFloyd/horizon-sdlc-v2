# Container Security Patterns Template

## Overview
This template provides comprehensive patterns for container security including security scanning, runtime security, non-root users, read-only filesystems, and seccomp profiles within our NX monorepo structure.

## Security Scanning Patterns

### Multi-Stage Dockerfile with Security Best Practices
```dockerfile
# apps/api-core/Dockerfile
# Build stage
FROM node:18-alpine AS builder

# Create app directory with proper ownership
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001 -G nodejs

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY nx.json ./
COPY tsconfig.base.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy source code
COPY --chown=nextjs:nodejs . .

# Build the application
RUN npx nx build api-core

# Production stage
FROM node:18-alpine AS runner

# Install security updates
RUN apk update && apk upgrade && \
    apk add --no-cache dumb-init && \
    rm -rf /var/cache/apk/*

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001 -G nodejs

# Set working directory
WORKDIR /app

# Create necessary directories with proper permissions
RUN mkdir -p /app/logs /app/tmp && \
    chown -R nextjs:nodejs /app

# Copy built application from builder stage
COPY --from=builder --chown=nextjs:nodejs /app/dist/apps/api-core ./
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "main.js"]
```

### Security Scanning with Trivy
```yaml
# .github/workflows/security-scan.yml
name: Container Security Scan

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Build Docker image
      run: |
        docker build -t horizon/api-core:${{ github.sha }} -f apps/api-core/Dockerfile .

    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: 'horizon/api-core:${{ github.sha }}'
        format: 'sarif'
        output: 'trivy-results.sarif'
        severity: 'CRITICAL,HIGH,MEDIUM'
        exit-code: '1'

    - name: Upload Trivy scan results to GitHub Security tab
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: 'trivy-results.sarif'

    - name: Run Trivy config scanner
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'config'
        scan-ref: '.'
        format: 'sarif'
        output: 'trivy-config-results.sarif'
        severity: 'CRITICAL,HIGH,MEDIUM'

    - name: Upload Trivy config scan results
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: 'trivy-config-results.sarif'
```

### Container Image Signing with Cosign
```yaml
# .github/workflows/build-and-sign.yml
name: Build and Sign Container Images

on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  build-and-sign:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      id-token: write

    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Install Cosign
      uses: sigstore/cosign-installer@v3

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3

    - name: Log in to Container Registry
      uses: docker/login-action@v3
      with:
        registry: gcr.io
        username: _json_key
        password: ${{ secrets.GCP_SA_KEY }}

    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: gcr.io/${{ secrets.GCP_PROJECT_ID }}/api-core
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=semver,pattern={{version}}
          type=semver,pattern={{major}}.{{minor}}

    - name: Build and push
      id: build
      uses: docker/build-push-action@v5
      with:
        context: .
        file: apps/api-core/Dockerfile
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        platforms: linux/amd64,linux/arm64

    - name: Sign container image
      env:
        COSIGN_EXPERIMENTAL: 1
      run: |
        cosign sign --yes gcr.io/${{ secrets.GCP_PROJECT_ID }}/api-core@${{ steps.build.outputs.digest }}

    - name: Generate SBOM
      uses: anchore/sbom-action@v0
      with:
        image: gcr.io/${{ secrets.GCP_PROJECT_ID }}/api-core@${{ steps.build.outputs.digest }}
        format: spdx-json
        output-file: sbom.spdx.json

    - name: Attach SBOM to image
      env:
        COSIGN_EXPERIMENTAL: 1
      run: |
        cosign attach sbom --sbom sbom.spdx.json gcr.io/${{ secrets.GCP_PROJECT_ID }}/api-core@${{ steps.build.outputs.digest }}
```

## Runtime Security Patterns

### Kubernetes Security Context
```yaml
# infrastructure/k8s/security/pod-security-standards.yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-api-core
  labels:
    app: api-core
spec:
  securityContext:
    # Run as non-root user
    runAsNonRoot: true
    runAsUser: 1001
    runAsGroup: 1001
    
    # Set filesystem group
    fsGroup: 1001
    fsGroupChangePolicy: "OnRootMismatch"
    
    # Security enhancements
    seccompProfile:
      type: RuntimeDefault
    supplementalGroups: [1001]

  containers:
  - name: api-core
    image: gcr.io/horizon-project/api-core:latest
    
    securityContext:
      # Prevent privilege escalation
      allowPrivilegeEscalation: false
      
      # Drop all capabilities
      capabilities:
        drop:
        - ALL
        # Add only required capabilities
        add:
        - NET_BIND_SERVICE
      
      # Read-only root filesystem
      readOnlyRootFilesystem: true
      
      # Run as non-root
      runAsNonRoot: true
      runAsUser: 1001
      runAsGroup: 1001
      
      # Seccomp profile
      seccompProfile:
        type: RuntimeDefault

    # Volume mounts for writable directories
    volumeMounts:
    - name: tmp-volume
      mountPath: /tmp
    - name: logs-volume
      mountPath: /app/logs
    - name: cache-volume
      mountPath: /app/.cache

    resources:
      limits:
        memory: "512Mi"
        cpu: "500m"
        ephemeral-storage: "1Gi"
      requests:
        memory: "256Mi"
        cpu: "250m"
        ephemeral-storage: "500Mi"

  volumes:
  - name: tmp-volume
    emptyDir:
      sizeLimit: "100Mi"
  - name: logs-volume
    emptyDir:
      sizeLimit: "200Mi"
  - name: cache-volume
    emptyDir:
      sizeLimit: "100Mi"

  # DNS policy
  dnsPolicy: ClusterFirst
  
  # Restart policy
  restartPolicy: Always
  
  # Termination grace period
  terminationGracePeriodSeconds: 30
```

### Network Policies
```yaml
# infrastructure/k8s/security/network-policies.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-core-network-policy
  namespace: horizon-production
spec:
  podSelector:
    matchLabels:
      app: api-core
  
  policyTypes:
  - Ingress
  - Egress
  
  ingress:
  # Allow traffic from ingress controller
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 3000
  
  # Allow traffic from other services in the same namespace
  - from:
    - namespaceSelector:
        matchLabels:
          name: horizon-production
      podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 3000

  egress:
  # Allow DNS resolution
  - to: []
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
  
  # Allow HTTPS traffic (for external APIs)
  - to: []
    ports:
    - protocol: TCP
      port: 443
  
  # Allow database connections
  - to:
    - namespaceSelector:
        matchLabels:
          name: database
    ports:
    - protocol: TCP
      port: 5432
  
  # Allow Redis connections
  - to:
    - namespaceSelector:
        matchLabels:
          name: cache
    ports:
    - protocol: TCP
      port: 6379
```

## Seccomp Profiles

### Custom Seccomp Profile
```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": [
    "SCMP_ARCH_X86_64",
    "SCMP_ARCH_X86",
    "SCMP_ARCH_X32"
  ],
  "syscalls": [
    {
      "names": [
        "accept",
        "accept4",
        "access",
        "arch_prctl",
        "bind",
        "brk",
        "clone",
        "close",
        "connect",
        "dup",
        "dup2",
        "epoll_create",
        "epoll_create1",
        "epoll_ctl",
        "epoll_wait",
        "execve",
        "exit",
        "exit_group",
        "fcntl",
        "fstat",
        "futex",
        "getcwd",
        "getdents",
        "getdents64",
        "getegid",
        "geteuid",
        "getgid",
        "getpid",
        "getppid",
        "getrandom",
        "getsockname",
        "getsockopt",
        "getuid",
        "listen",
        "lseek",
        "mmap",
        "mprotect",
        "munmap",
        "nanosleep",
        "open",
        "openat",
        "pipe",
        "pipe2",
        "poll",
        "read",
        "readlink",
        "recvfrom",
        "rt_sigaction",
        "rt_sigprocmask",
        "rt_sigreturn",
        "sendto",
        "set_robust_list",
        "setsockopt",
        "socket",
        "stat",
        "write"
      ],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

### Applying Seccomp Profiles in Kubernetes
```yaml
# infrastructure/k8s/security/seccomp-profile.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-core-seccomp-profile
  namespace: horizon-production
data:
  api-core-profile.json: |
    {
      "defaultAction": "SCMP_ACT_ERRNO",
      "architectures": ["SCMP_ARCH_X86_64"],
      "syscalls": [
        {
          "names": [
            "accept", "accept4", "access", "arch_prctl", "bind", "brk",
            "clone", "close", "connect", "dup", "dup2", "epoll_create",
            "epoll_create1", "epoll_ctl", "epoll_wait", "execve", "exit",
            "exit_group", "fcntl", "fstat", "futex", "getcwd", "getdents",
            "getdents64", "getegid", "geteuid", "getgid", "getpid",
            "getppid", "getrandom", "getsockname", "getsockopt", "getuid",
            "listen", "lseek", "mmap", "mprotect", "munmap", "nanosleep",
            "open", "openat", "pipe", "pipe2", "poll", "read", "readlink",
            "recvfrom", "rt_sigaction", "rt_sigprocmask", "rt_sigreturn",
            "sendto", "set_robust_list", "setsockopt", "socket", "stat", "write"
          ],
          "action": "SCMP_ACT_ALLOW"
        }
      ]
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-core-secure
  namespace: horizon-production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api-core
  template:
    metadata:
      labels:
        app: api-core
      annotations:
        container.seccomp.security.alpha.kubernetes.io/api-core: localhost/api-core-profile.json
    spec:
      securityContext:
        seccompProfile:
          type: Localhost
          localhostProfile: api-core-profile.json
      
      containers:
      - name: api-core
        image: gcr.io/horizon-project/api-core:latest
        securityContext:
          seccompProfile:
            type: Localhost
            localhostProfile: api-core-profile.json

## Runtime Monitoring and Detection

### Falco Security Monitoring
```yaml
# infrastructure/k8s/security/falco-rules.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: falco-custom-rules
  namespace: falco-system
data:
  custom_rules.yaml: |
    - rule: Unexpected Network Connection
      desc: Detect unexpected network connections from containers
      condition: >
        (inbound_outbound) and
        container and
        not proc.name in (node, npm, curl, wget) and
        not fd.sport in (80, 443, 3000, 5432, 6379)
      output: >
        Unexpected network connection
        (user=%user.name command=%proc.cmdline connection=%fd.name)
      priority: WARNING
      tags: [network, container]

    - rule: Suspicious File Access
      desc: Detect access to sensitive files
      condition: >
        open_read and
        container and
        (fd.name startswith /etc/passwd or
         fd.name startswith /etc/shadow or
         fd.name startswith /etc/ssh/ or
         fd.name startswith /root/.ssh/)
      output: >
        Sensitive file accessed
        (user=%user.name command=%proc.cmdline file=%fd.name)
      priority: HIGH
      tags: [filesystem, container]

    - rule: Container Privilege Escalation
      desc: Detect privilege escalation attempts
      condition: >
        spawned_process and
        container and
        proc.name in (sudo, su, setuid) and
        not user.name in (root)
      output: >
        Privilege escalation attempt
        (user=%user.name command=%proc.cmdline container=%container.name)
      priority: CRITICAL
      tags: [privilege_escalation, container]

    - rule: Unexpected Process in Container
      desc: Detect unexpected processes in application containers
      condition: >
        spawned_process and
        container and
        container.image.repository contains "horizon" and
        not proc.name in (node, npm, sh, bash, dumb-init)
      output: >
        Unexpected process in container
        (user=%user.name command=%proc.cmdline container=%container.name image=%container.image.repository)
      priority: WARNING
      tags: [process, container]
```

### Container Runtime Security with gVisor
```yaml
# infrastructure/k8s/security/gvisor-runtime-class.yaml
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-core-gvisor
  namespace: horizon-production
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-core-gvisor
  template:
    metadata:
      labels:
        app: api-core-gvisor
    spec:
      runtimeClassName: gvisor
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 1001

      containers:
      - name: api-core
        image: gcr.io/horizon-project/api-core:latest
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1001

        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
          requests:
            memory: "256Mi"
            cpu: "250m"
```

## Security Compliance and Auditing

### Pod Security Standards
```yaml
# infrastructure/k8s/security/pod-security-policy.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: horizon-production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
---
apiVersion: v1
kind: Namespace
metadata:
  name: horizon-test
  labels:
    pod-security.kubernetes.io/enforce: baseline
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### OPA Gatekeeper Policies
```yaml
# infrastructure/k8s/security/gatekeeper-constraints.yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8srequiredsecuritycontext
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredSecurityContext
      validation:
        type: object
        properties:
          runAsNonRoot:
            type: boolean
          readOnlyRootFilesystem:
            type: boolean
          allowPrivilegeEscalation:
            type: boolean
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredsecuritycontext

        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not container.securityContext.runAsNonRoot == true
          msg := "Container must run as non-root user"
        }

        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not container.securityContext.readOnlyRootFilesystem == true
          msg := "Container must have read-only root filesystem"
        }

        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not container.securityContext.allowPrivilegeEscalation == false
          msg := "Container must not allow privilege escalation"
        }
---
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredSecurityContext
metadata:
  name: must-have-security-context
spec:
  match:
    kinds:
      - apiGroups: ["apps"]
        kinds: ["Deployment", "StatefulSet", "DaemonSet"]
    namespaces: ["horizon-production", "horizon-test"]
  parameters:
    runAsNonRoot: true
    readOnlyRootFilesystem: true
    allowPrivilegeEscalation: false
```

## Best Practices

### Container Image Security
- **Minimal Base Images**: Use distroless or Alpine-based images
- **Regular Updates**: Keep base images and dependencies updated
- **Vulnerability Scanning**: Scan images for vulnerabilities before deployment
- **Image Signing**: Sign container images to ensure integrity

### Runtime Security
- **Non-Root Users**: Always run containers as non-root users
- **Read-Only Filesystems**: Use read-only root filesystems where possible
- **Capability Dropping**: Drop all unnecessary Linux capabilities
- **Seccomp Profiles**: Apply restrictive seccomp profiles

### Network Security
- **Network Policies**: Implement Kubernetes network policies
- **Service Mesh**: Use Istio for encrypted service-to-service communication
- **Ingress Security**: Secure ingress with TLS and authentication
- **Egress Control**: Control and monitor outbound network traffic

### Monitoring and Compliance
- **Runtime Monitoring**: Use Falco for runtime security monitoring
- **Policy Enforcement**: Use OPA Gatekeeper for policy enforcement
- **Audit Logging**: Enable and monitor Kubernetes audit logs
- **Compliance Scanning**: Regular compliance scans with tools like kube-bench

### Secret Management
- **External Secrets**: Use external secret management systems
- **Secret Rotation**: Implement automated secret rotation
- **Least Privilege**: Grant minimal necessary access to secrets
- **Encryption**: Encrypt secrets at rest and in transit

This container security patterns template provides comprehensive guidance for implementing robust container security within our NX monorepo structure.
```

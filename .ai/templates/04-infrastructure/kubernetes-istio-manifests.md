# Kubernetes with Istio Service Mesh Manifests Template

## Overview
This template provides Kubernetes manifests with Istio service mesh integration following our infrastructure standards with security policies, traffic management, and observability.

## Istio Installation and Configuration

### 1. Istio Installation
```yaml
# k8s/istio/istio-operator.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: horizon-istio
  namespace: istio-system
spec:
  values:
    global:
      meshID: horizon-mesh
      network: horizon-network
      proxy:
        tracer: "jaeger"
    pilot:
      env:
        EXTERNAL_ISTIOD: false
  components:
    pilot:
      k8s:
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        service:
          type: LoadBalancer
          annotations:
            cloud.google.com/load-balancer-type: "External"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
    egressGateways:
    - name: istio-egressgateway
      enabled: true
      k8s:
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
  meshConfig:
    defaultConfig:
      proxyStatsMatcher:
        inclusionRegexps:
        - ".*outlier_detection.*"
        - ".*circuit_breakers.*"
        - ".*upstream_rq_retry.*"
        - ".*_cx_.*"
    extensionProviders:
    - name: elastic-apm
      envoyOtelAls:
        service: elastic-apm-server.observability.svc.cluster.local
        port: 8200
    - name: elastic-otel
      envoyOtelAls:
        service: opentelemetry-collector.observability.svc.cluster.local
        port: 4317
```

### 2. Gateway Configuration
```yaml
# k8s/istio/gateway.yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: horizon-gateway
  namespace: istio-system
  labels:
    app: horizon
    environment: test
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*.horizon-test.example.com"
    tls:
      httpsRedirect: true
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - "*.horizon-test.example.com"
    tls:
      mode: SIMPLE
      credentialName: horizon-tls-cert
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: horizon-vs
  namespace: istio-system
  labels:
    app: horizon
    environment: test
spec:
  hosts:
  - "*.horizon-test.example.com"
  gateways:
  - horizon-gateway
  http:
  - match:
    - uri:
        prefix: /api/
    route:
    - destination:
        host: api-core.horizon.svc.cluster.local
        port:
          number: 3001
    timeout: 30s
    retries:
      attempts: 3
      perTryTimeout: 10s
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: web-dashboard.horizon.svc.cluster.local
        port:
          number: 3000
    timeout: 30s
```

## Application Deployments

### 1. Web Dashboard Deployment
```yaml
# k8s/apps/web-dashboard/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-dashboard
  namespace: horizon
  labels:
    app: web-dashboard
    version: v1
    environment: test
    application: horizon
    managed-by: terraform
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-dashboard
      version: v1
  template:
    metadata:
      labels:
        app: web-dashboard
        version: v1
        environment: test
      annotations:
        sidecar.istio.io/inject: "true"
        prometheus.io/scrape: "true"
        prometheus.io/port: "3000"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: web-dashboard
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 1001
      containers:
      - name: web-dashboard
        image: ghcr.io/horizon/web-dashboard:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 3000
          name: http
          protocol: TCP
        env:
        - name: NODE_ENV
          value: "production"
        - name: PORT
          value: "3000"
        - name: API_BASE_URL
          value: "http://api-core.horizon.svc.cluster.local:3001"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-credentials
              key: url
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: redis-credentials
              key: url
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
        livenessProbe:
          httpGet:
            path: /api/health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /api/ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: cache
          mountPath: /app/.next/cache
      volumes:
      - name: tmp
        emptyDir: {}
      - name: cache
        emptyDir: {}
      imagePullSecrets:
      - name: ghcr-secret
---
apiVersion: v1
kind: Service
metadata:
  name: web-dashboard
  namespace: horizon
  labels:
    app: web-dashboard
    environment: test
spec:
  selector:
    app: web-dashboard
  ports:
  - port: 3000
    targetPort: 3000
    name: http
  type: ClusterIP
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: web-dashboard
  namespace: horizon
  labels:
    app: web-dashboard
    environment: test
  annotations:
    iam.gke.io/gcp-service-account: web-dashboard@horizon-test.iam.gserviceaccount.com
```

### 2. API Core Deployment
```yaml
# k8s/apps/api-core/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-core
  namespace: horizon
  labels:
    app: api-core
    version: v1
    environment: test
    application: horizon
    managed-by: terraform
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api-core
      version: v1
  template:
    metadata:
      labels:
        app: api-core
        version: v1
        environment: test
      annotations:
        sidecar.istio.io/inject: "true"
        prometheus.io/scrape: "true"
        prometheus.io/port: "3001"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: api-core
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 1001
      containers:
      - name: api-core
        image: ghcr.io/horizon/api-core:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 3001
          name: http
          protocol: TCP
        env:
        - name: NODE_ENV
          value: "production"
        - name: PORT
          value: "3001"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-credentials
              key: url
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: redis-credentials
              key: url
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: api-secrets
              key: jwt-secret
        - name: STRIPE_SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: payment-secrets
              key: stripe-secret
        resources:
          requests:
            cpu: 200m
            memory: 512Mi
          limits:
            cpu: 1000m
            memory: 1Gi
        livenessProbe:
          httpGet:
            path: /health
            port: 3001
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: 3001
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        volumeMounts:
        - name: tmp
          mountPath: /tmp
      volumes:
      - name: tmp
        emptyDir: {}
      imagePullSecrets:
      - name: ghcr-secret
---
apiVersion: v1
kind: Service
metadata:
  name: api-core
  namespace: horizon
  labels:
    app: api-core
    environment: test
spec:
  selector:
    app: api-core
  ports:
  - port: 3001
    targetPort: 3001
    name: http
  type: ClusterIP
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: api-core
  namespace: horizon
  labels:
    app: api-core
    environment: test
  annotations:
    iam.gke.io/gcp-service-account: api-core@horizon-test.iam.gserviceaccount.com
```

## Istio Security Policies

### 1. Peer Authentication
```yaml
# k8s/istio/security/peer-authentication.yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: horizon
spec:
  mtls:
    mode: STRICT
---
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: api-core-permissive
  namespace: horizon
spec:
  selector:
    matchLabels:
      app: api-core
  mtls:
    mode: PERMISSIVE
  portLevelMtls:
    3001:
      mode: STRICT
```

### 2. Authorization Policies
```yaml
# k8s/istio/security/authorization-policy.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: api-core-authz
  namespace: horizon
spec:
  selector:
    matchLabels:
      app: api-core
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/horizon/sa/web-dashboard"]
    - source:
        principals: ["cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
    to:
    - operation:
        methods: ["GET", "POST", "PUT", "DELETE"]
        paths: ["/api/*"]
  - from:
    - source:
        principals: ["cluster.local/ns/horizon/sa/api-core"]
    to:
    - operation:
        methods: ["GET"]
        paths: ["/health", "/ready", "/metrics"]
---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: web-dashboard-authz
  namespace: horizon
spec:
  selector:
    matchLabels:
      app: web-dashboard
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
    to:
    - operation:
        methods: ["GET"]
        paths: ["/*"]
  - from:
    - source:
        principals: ["cluster.local/ns/horizon/sa/web-dashboard"]
    to:
    - operation:
        methods: ["GET"]
        paths: ["/api/health", "/api/ready", "/metrics"]
```

## Traffic Management

### 1. Destination Rules
```yaml
# k8s/istio/traffic/destination-rules.yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: api-core-dr
  namespace: horizon
spec:
  host: api-core.horizon.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
        http2MaxRequests: 100
        maxRequestsPerConnection: 10
        maxRetries: 3
        consecutiveGatewayErrors: 5
        interval: 30s
        baseEjectionTime: 30s
        maxEjectionPercent: 50
    loadBalancer:
      simple: LEAST_CONN
    outlierDetection:
      consecutiveGatewayErrors: 5
      consecutive5xxErrors: 5
      interval: 30s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
      minHealthPercent: 50
  subsets:
  - name: v1
    labels:
      version: v1
    trafficPolicy:
      circuitBreaker:
        connectionPool:
          tcp:
            maxConnections: 50
          http:
            http1MaxPendingRequests: 25
            maxRequestsPerConnection: 5
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: web-dashboard-dr
  namespace: horizon
spec:
  host: web-dashboard.horizon.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
    connectionPool:
      tcp:
        maxConnections: 50
      http:
        http1MaxPendingRequests: 25
        http2MaxRequests: 50
        maxRequestsPerConnection: 5
    loadBalancer:
      simple: ROUND_ROBIN
  subsets:
  - name: v1
    labels:
      version: v1
```

### 2. Virtual Services for Canary Deployments
```yaml
# k8s/istio/traffic/virtual-service-canary.yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: api-core-canary
  namespace: horizon
spec:
  hosts:
  - api-core.horizon.svc.cluster.local
  http:
  - match:
    - headers:
        canary:
          exact: "true"
    route:
    - destination:
        host: api-core.horizon.svc.cluster.local
        subset: v2
      weight: 100
    fault:
      delay:
        percentage:
          value: 0.1
        fixedDelay: 5s
  - route:
    - destination:
        host: api-core.horizon.svc.cluster.local
        subset: v1
      weight: 90
    - destination:
        host: api-core.horizon.svc.cluster.local
        subset: v2
      weight: 10
    timeout: 30s
    retries:
      attempts: 3
      perTryTimeout: 10s
      retryOn: gateway-error,connect-failure,refused-stream
```

## Observability Configuration

### 1. Elastic Cloud Integration

#### OpenTelemetry Collector for Elastic Cloud
```yaml
# k8s/observability/otel-collector.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-collector-config
  namespace: observability
data:
  config.yaml: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
      prometheus:
        config:
          scrape_configs:
          - job_name: 'kubernetes-pods'
            kubernetes_sd_configs:
            - role: pod

    processors:
      batch:
        timeout: 1s
        send_batch_size: 1024
      resource:
        attributes:
        - key: service.namespace
          value: horizon
          action: upsert
        - key: deployment.environment
          from_attribute: k8s.namespace.name
          action: insert

    exporters:
      elasticsearch:
        endpoints:
        - ${ELASTIC_CLOUD_ENDPOINT}
        api_key: ${ELASTIC_CLOUD_API_KEY}
        logs_index: logs-horizon
        traces_index: traces-horizon
        metrics_index: metrics-horizon

      otlphttp:
        endpoint: ${ELASTIC_APM_ENDPOINT}
        headers:
          Authorization: "Bearer ${ELASTIC_APM_SECRET_TOKEN}"

    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [batch, resource]
          exporters: [elasticsearch, otlphttp]
        metrics:
          receivers: [otlp, prometheus]
          processors: [batch, resource]
          exporters: [elasticsearch]
        logs:
          receivers: [otlp]
          processors: [batch, resource]
          exporters: [elasticsearch]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: otel-collector
  namespace: observability
spec:
  replicas: 2
  selector:
    matchLabels:
      app: otel-collector
  template:
    metadata:
      labels:
        app: otel-collector
    spec:
      containers:
      - name: otel-collector
        image: otel/opentelemetry-collector-contrib:latest
        args: ["--config=/etc/config/config.yaml"]
        env:
        - name: ELASTIC_CLOUD_ENDPOINT
          valueFrom:
            secretKeyRef:
              name: elastic-cloud-credentials
              key: endpoint
        - name: ELASTIC_CLOUD_API_KEY
          valueFrom:
            secretKeyRef:
              name: elastic-cloud-credentials
              key: api-key
        - name: ELASTIC_APM_ENDPOINT
          valueFrom:
            secretKeyRef:
              name: elastic-apm-credentials
              key: endpoint
        - name: ELASTIC_APM_SECRET_TOKEN
          valueFrom:
            secretKeyRef:
              name: elastic-apm-credentials
              key: secret-token
        ports:
        - containerPort: 4317
          name: otlp-grpc
        - containerPort: 4318
          name: otlp-http
        volumeMounts:
        - name: config
          mountPath: /etc/config
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
      volumes:
      - name: config
        configMap:
          name: otel-collector-config
---
apiVersion: v1
kind: Service
metadata:
  name: opentelemetry-collector
  namespace: observability
spec:
  selector:
    app: otel-collector
  ports:
  - name: otlp-grpc
    port: 4317
    targetPort: 4317
  - name: otlp-http
    port: 4318
    targetPort: 4318
```

### 2. Telemetry Configuration
```yaml
# k8s/istio/observability/telemetry.yaml
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: default
  namespace: horizon
spec:
  metrics:
  - providers:
    - name: prometheus
  - overrides:
    - match:
        metric: ALL_METRICS
      tagOverrides:
        request_protocol:
          value: "http"
    - match:
        metric: REQUEST_COUNT
      disabled: false
    - match:
        metric: REQUEST_DURATION
      disabled: false
    - match:
        metric: REQUEST_SIZE
      disabled: false
    - match:
        metric: RESPONSE_SIZE
      disabled: false
  tracing:
  - providers:
    - name: elastic-apm
  accessLogging:
  - providers:
    - name: elastic-otel
  - disabled: false
    providers:
    - name: elastic-otel
```

### 2. Service Monitor for Prometheus
```yaml
# k8s/monitoring/service-monitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: horizon-apps
  namespace: horizon
  labels:
    app: horizon
    environment: test
spec:
  selector:
    matchLabels:
      app: api-core
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
    scrapeTimeout: 10s
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: istio-proxy
  namespace: horizon
  labels:
    app: istio-proxy
    environment: test
spec:
  selector:
    matchLabels:
      app: api-core
  endpoints:
  - port: http-monitoring
    path: /stats/prometheus
    interval: 15s
    scrapeTimeout: 10s
```

## Network Policies

### 1. Kubernetes Network Policies
```yaml
# k8s/security/network-policies.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-core-netpol
  namespace: horizon
spec:
  podSelector:
    matchLabels:
      app: api-core
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: web-dashboard
    - namespaceSelector:
        matchLabels:
          name: istio-system
      podSelector:
        matchLabels:
          app: istio-ingressgateway
    ports:
    - protocol: TCP
      port: 3001
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
  - to: []
    ports:
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 5432  # PostgreSQL
    - protocol: TCP
      port: 6379  # Redis
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-dashboard-netpol
  namespace: horizon
spec:
  podSelector:
    matchLabels:
      app: web-dashboard
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: istio-system
      podSelector:
        matchLabels:
          app: istio-ingressgateway
    ports:
    - protocol: TCP
      port: 3000
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: api-core
    ports:
    - protocol: TCP
      port: 3001
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
```

This template provides comprehensive Kubernetes manifests with Istio service mesh integration following our infrastructure standards with security, traffic management, and observability.

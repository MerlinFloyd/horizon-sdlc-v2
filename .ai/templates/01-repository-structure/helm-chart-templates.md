# Helm Chart Templates

## Overview
This template provides Helm chart standards following our organizational requirements for Kubernetes deployments with environment-specific configurations, security best practices, and observability integration.

## Chart Structure

```
helm/
├── charts/                     # Chart dependencies
├── templates/                  # Kubernetes manifest templates
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── serviceaccount.yaml
│   ├── rbac.yaml
│   ├── hpa.yaml
│   ├── pdb.yaml
│   ├── networkpolicy.yaml
│   ├── servicemonitor.yaml
│   └── _helpers.tpl
├── values/                     # Environment-specific values
│   ├── values-test.yaml
│   └── values-prod.yaml
├── Chart.yaml                  # Chart metadata
├── values.yaml                 # Default values
└── README.md                   # Chart documentation
```

## Chart.yaml Configuration

### 1. Chart Metadata
```yaml
# Chart.yaml
apiVersion: v2
name: horizon-app
description: Horizon application Helm chart following organizational standards
type: application
version: 1.0.0
appVersion: "1.0.0"
home: https://github.com/horizon/horizon-monorepo
sources:
  - https://github.com/horizon/horizon-monorepo
maintainers:
  - name: Platform Team
    email: platform@horizon.com
keywords:
  - horizon
  - microservice
  - kubernetes
annotations:
  category: Application
  licenses: MIT
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
  - name: redis
    version: "17.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled
```

## Default Values Configuration

### 1. Application Configuration
```yaml
# values.yaml
# Global configuration
global:
  imageRegistry: "ghcr.io"
  imagePullSecrets:
    - name: ghcr-secret
  storageClass: "standard"

# Application configuration
app:
  name: horizon-app
  version: "1.0.0"
  environment: "test"
  
# Image configuration
image:
  registry: ghcr.io
  repository: horizon/app
  tag: "latest"
  pullPolicy: IfNotPresent
  pullSecrets:
    - name: ghcr-secret

# Deployment configuration
deployment:
  replicaCount: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  
  # Resource requirements
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi
  
  # Security context
  securityContext:
    runAsNonRoot: true
    runAsUser: 1001
    fsGroup: 1001
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    capabilities:
      drop:
        - ALL

  # Health checks
  livenessProbe:
    httpGet:
      path: /health
      port: http
    initialDelaySeconds: 30
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 3
  
  readinessProbe:
    httpGet:
      path: /ready
      port: http
    initialDelaySeconds: 5
    periodSeconds: 5
    timeoutSeconds: 3
    failureThreshold: 3

# Service configuration
service:
  type: ClusterIP
  port: 80
  targetPort: 3000
  annotations: {}

# Ingress configuration
ingress:
  enabled: true
  className: "istio"
  annotations:
    kubernetes.io/ingress.class: istio
  hosts:
    - host: app.horizon-test.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: horizon-tls-cert
      hosts:
        - app.horizon-test.example.com

# Horizontal Pod Autoscaler
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

# Pod Disruption Budget
podDisruptionBudget:
  enabled: true
  minAvailable: 1

# Network Policy
networkPolicy:
  enabled: true
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: istio-system
      ports:
        - protocol: TCP
          port: 3000
  egress:
    - to: []
      ports:
        - protocol: TCP
          port: 443
        - protocol: TCP
          port: 5432  # PostgreSQL
        - protocol: TCP
          port: 6379  # Redis

# Service Account
serviceAccount:
  create: true
  annotations:
    iam.gke.io/gcp-service-account: "app@horizon-test.iam.gserviceaccount.com"
  name: ""

# RBAC
rbac:
  create: true
  rules:
    - apiGroups: [""]
      resources: ["configmaps", "secrets"]
      verbs: ["get", "list"]

# ConfigMap
configMap:
  enabled: true
  data:
    NODE_ENV: "production"
    LOG_LEVEL: "info"
    API_BASE_URL: "http://api-core.horizon.svc.cluster.local:3001"

# Secrets (references to external secrets)
secrets:
  enabled: true
  data:
    DATABASE_URL: ""
    REDIS_URL: ""
    JWT_SECRET: ""

# Monitoring
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    interval: 30s
    path: /metrics
    port: http

# Istio configuration
istio:
  enabled: true
  sidecar:
    inject: true
  virtualService:
    enabled: true
    gateways:
      - istio-system/horizon-gateway
    hosts:
      - app.horizon-test.example.com
  destinationRule:
    enabled: true
    trafficPolicy:
      tls:
        mode: ISTIO_MUTUAL

# Database dependencies
postgresql:
  enabled: false
  auth:
    postgresPassword: ""
    database: horizon
  primary:
    persistence:
      enabled: true
      size: 10Gi

redis:
  enabled: false
  auth:
    enabled: true
    password: ""
  master:
    persistence:
      enabled: true
      size: 5Gi

# Labels applied to all resources
commonLabels:
  app.kubernetes.io/name: horizon-app
  app.kubernetes.io/instance: horizon
  app.kubernetes.io/version: "1.0.0"
  app.kubernetes.io/component: application
  app.kubernetes.io/part-of: horizon
  app.kubernetes.io/managed-by: helm
  environment: test
  application: horizon
  managed-by: terraform
```

## Template Files

### 1. Deployment Template
```yaml
# templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "horizon-app.fullname" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "horizon-app.labels" . | nindent 4 }}
  annotations:
    deployment.kubernetes.io/revision: "{{ .Release.Revision }}"
spec:
  replicas: {{ .Values.deployment.replicaCount }}
  strategy:
    {{- toYaml .Values.deployment.strategy | nindent 4 }}
  selector:
    matchLabels:
      {{- include "horizon-app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "horizon-app.selectorLabels" . | nindent 8 }}
        version: {{ .Values.app.version | quote }}
      annotations:
        sidecar.istio.io/inject: "{{ .Values.istio.sidecar.inject }}"
        prometheus.io/scrape: "{{ .Values.monitoring.enabled }}"
        prometheus.io/port: "{{ .Values.service.targetPort }}"
        prometheus.io/path: "/metrics"
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
        checksum/secret: {{ include (print $.Template.BasePath "/secret.yaml") . | sha256sum }}
    spec:
      serviceAccountName: {{ include "horizon-app.serviceAccountName" . }}
      securityContext:
        {{- toYaml .Values.deployment.securityContext | nindent 8 }}
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.registry }}/{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: {{ .Values.service.targetPort }}
          protocol: TCP
        env:
        {{- if .Values.configMap.enabled }}
        - name: NODE_ENV
          valueFrom:
            configMapKeyRef:
              name: {{ include "horizon-app.fullname" . }}-config
              key: NODE_ENV
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: {{ include "horizon-app.fullname" . }}-config
              key: LOG_LEVEL
        {{- end }}
        {{- if .Values.secrets.enabled }}
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: {{ include "horizon-app.fullname" . }}-secret
              key: DATABASE_URL
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: {{ include "horizon-app.fullname" . }}-secret
              key: REDIS_URL
        {{- end }}
        livenessProbe:
          {{- toYaml .Values.deployment.livenessProbe | nindent 10 }}
        readinessProbe:
          {{- toYaml .Values.deployment.readinessProbe | nindent 10 }}
        resources:
          {{- toYaml .Values.deployment.resources | nindent 10 }}
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
      {{- with .Values.image.pullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
```

### 2. Helper Templates
```yaml
# templates/_helpers.tpl
{{/*
Expand the name of the chart.
*/}}
{{- define "horizon-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "horizon-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "horizon-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "horizon-app.labels" -}}
helm.sh/chart: {{ include "horizon-app.chart" . }}
{{ include "horizon-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
environment: {{ .Values.app.environment }}
application: horizon
managed-by: terraform
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "horizon-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "horizon-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "horizon-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "horizon-app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
```

## Environment-Specific Values

### 1. Test Environment Values
```yaml
# values/values-test.yaml
app:
  environment: "test"

image:
  tag: "test-latest"

deployment:
  replicaCount: 2
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi

ingress:
  hosts:
    - host: app.horizon-test.example.com
      paths:
        - path: /
          pathType: Prefix

autoscaling:
  minReplicas: 2
  maxReplicas: 5

postgresql:
  enabled: true
  auth:
    database: horizon_test

redis:
  enabled: true
```

### 2. Production Environment Values
```yaml
# values/values-prod.yaml
app:
  environment: "production"

image:
  tag: "v1.0.0"

deployment:
  replicaCount: 5
  resources:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 2000m
      memory: 2Gi

ingress:
  hosts:
    - host: app.horizon.com
      paths:
        - path: /
          pathType: Prefix

autoscaling:
  minReplicas: 5
  maxReplicas: 20
  targetCPUUtilizationPercentage: 60

postgresql:
  enabled: false  # Use external managed database

redis:
  enabled: false  # Use external managed Redis
```

This template provides comprehensive Helm chart standards following our organizational requirements with proper security, observability, and environment management.

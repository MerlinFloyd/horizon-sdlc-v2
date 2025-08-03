# Environment Management Patterns Template

## Overview
This template provides comprehensive patterns for environment management including configuration management, secrets handling, environment-specific deployments, and resource tagging strategies within our NX monorepo structure.

## Configuration Management Patterns

### Environment Configuration Structure
```typescript
// libs/shared/config/src/environment.config.ts
export interface EnvironmentConfig {
  environment: 'test' | 'production';
  region: string;
  database: DatabaseConfig;
  redis: RedisConfig;
  auth: AuthConfig;
  blockchain: BlockchainConfig;
  monitoring: MonitoringConfig;
  features: FeatureFlags;
}

export interface DatabaseConfig {
  url: string;
  poolSize: number;
  ssl: boolean;
  migrations: {
    autoRun: boolean;
    directory: string;
  };
}

export interface RedisConfig {
  url: string;
  password?: string;
  db: number;
  maxRetries: number;
  retryDelay: number;
}

export interface AuthConfig {
  jwtSecret: string;
  jwtExpiry: string;
  refreshTokenExpiry: string;
  oauth: {
    google: OAuthProviderConfig;
    github: OAuthProviderConfig;
  };
}

export interface OAuthProviderConfig {
  clientId: string;
  clientSecret: string;
  redirectUri: string;
}

export interface BlockchainConfig {
  networks: {
    ethereum: NetworkConfig;
    polygon: NetworkConfig;
    solana: NetworkConfig;
  };
  defaultNetwork: string;
}

export interface NetworkConfig {
  rpcUrl: string;
  chainId: number;
  contracts: Record<string, string>;
}

export interface MonitoringConfig {
  elasticCloud: {
    endpoint: string;
    apiKey: string;
  };
  openTelemetry: {
    endpoint: string;
    serviceName: string;
  };
}

export interface FeatureFlags {
  blockchainIntegration: boolean;
  advancedAnalytics: boolean;
  experimentalFeatures: boolean;
}
```

### Configuration Loader
```typescript
// libs/shared/config/src/config.loader.ts
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EnvironmentConfig } from './environment.config';

@Injectable()
export class ConfigLoader {
  private config: EnvironmentConfig;

  constructor(private configService: ConfigService) {
    this.config = this.loadConfiguration();
    this.validateConfiguration();
  }

  getConfig(): EnvironmentConfig {
    return this.config;
  }

  private loadConfiguration(): EnvironmentConfig {
    const environment = this.configService.get('NODE_ENV', 'test') as 'test' | 'production';
    
    return {
      environment,
      region: this.configService.get('GCP_REGION', 'us-central1'),
      
      database: {
        url: this.getRequiredConfig('DATABASE_URL'),
        poolSize: parseInt(this.configService.get('DB_POOL_SIZE', '10')),
        ssl: this.configService.get('DB_SSL', 'true') === 'true',
        migrations: {
          autoRun: environment === 'test',
          directory: './migrations'
        }
      },

      redis: {
        url: this.getRequiredConfig('REDIS_URL'),
        password: this.configService.get('REDIS_PASSWORD'),
        db: parseInt(this.configService.get('REDIS_DB', '0')),
        maxRetries: parseInt(this.configService.get('REDIS_MAX_RETRIES', '3')),
        retryDelay: parseInt(this.configService.get('REDIS_RETRY_DELAY', '1000'))
      },

      auth: {
        jwtSecret: this.getRequiredConfig('JWT_SECRET'),
        jwtExpiry: this.configService.get('JWT_EXPIRY', '15m'),
        refreshTokenExpiry: this.configService.get('REFRESH_TOKEN_EXPIRY', '7d'),
        oauth: {
          google: {
            clientId: this.getRequiredConfig('GOOGLE_CLIENT_ID'),
            clientSecret: this.getRequiredConfig('GOOGLE_CLIENT_SECRET'),
            redirectUri: this.getRequiredConfig('GOOGLE_REDIRECT_URI')
          },
          github: {
            clientId: this.getRequiredConfig('GITHUB_CLIENT_ID'),
            clientSecret: this.getRequiredConfig('GITHUB_CLIENT_SECRET'),
            redirectUri: this.getRequiredConfig('GITHUB_REDIRECT_URI')
          }
        }
      },

      blockchain: {
        networks: {
          ethereum: {
            rpcUrl: this.getRequiredConfig('ETHEREUM_RPC_URL'),
            chainId: parseInt(this.configService.get('ETHEREUM_CHAIN_ID', '1')),
            contracts: {
              taskManager: this.getRequiredConfig('ETHEREUM_TASK_MANAGER_CONTRACT')
            }
          },
          polygon: {
            rpcUrl: this.getRequiredConfig('POLYGON_RPC_URL'),
            chainId: parseInt(this.configService.get('POLYGON_CHAIN_ID', '137')),
            contracts: {
              taskManager: this.getRequiredConfig('POLYGON_TASK_MANAGER_CONTRACT')
            }
          },
          solana: {
            rpcUrl: this.getRequiredConfig('SOLANA_RPC_URL'),
            chainId: parseInt(this.configService.get('SOLANA_CHAIN_ID', '101')),
            contracts: {
              taskManager: this.getRequiredConfig('SOLANA_TASK_MANAGER_PROGRAM')
            }
          }
        },
        defaultNetwork: this.configService.get('DEFAULT_BLOCKCHAIN_NETWORK', 'ethereum')
      },

      monitoring: {
        elasticCloud: {
          endpoint: this.getRequiredConfig('ELASTIC_CLOUD_ENDPOINT'),
          apiKey: this.getRequiredConfig('ELASTIC_CLOUD_API_KEY')
        },
        openTelemetry: {
          endpoint: this.getRequiredConfig('OTEL_EXPORTER_OTLP_ENDPOINT'),
          serviceName: this.configService.get('OTEL_SERVICE_NAME', 'horizon-api')
        }
      },

      features: {
        blockchainIntegration: this.configService.get('FEATURE_BLOCKCHAIN', 'true') === 'true',
        advancedAnalytics: this.configService.get('FEATURE_ANALYTICS', 'false') === 'true',
        experimentalFeatures: environment === 'test'
      }
    };
  }

  private getRequiredConfig(key: string): string {
    const value = this.configService.get(key);
    if (!value) {
      throw new Error(`Required configuration missing: ${key}`);
    }
    return value;
  }

  private validateConfiguration(): void {
    const errors: string[] = [];

    // Validate database configuration
    if (!this.config.database.url.startsWith('postgresql://')) {
      errors.push('DATABASE_URL must be a valid PostgreSQL connection string');
    }

    // Validate Redis configuration
    if (!this.config.redis.url.startsWith('redis://')) {
      errors.push('REDIS_URL must be a valid Redis connection string');
    }

    // Validate JWT secret length
    if (this.config.auth.jwtSecret.length < 32) {
      errors.push('JWT_SECRET must be at least 32 characters long');
    }

    // Validate blockchain configuration
    Object.entries(this.config.blockchain.networks).forEach(([network, config]) => {
      if (!config.rpcUrl.startsWith('http')) {
        errors.push(`${network.toUpperCase()}_RPC_URL must be a valid HTTP URL`);
      }
    });

    if (errors.length > 0) {
      throw new Error(`Configuration validation failed:\n${errors.join('\n')}`);
    }
  }
}
```

## Secrets Management Patterns

### Google Secret Manager Integration
```typescript
// libs/shared/config/src/secrets/secret-manager.service.ts
import { Injectable } from '@nestjs/common';
import { SecretManagerServiceClient } from '@google-cloud/secret-manager';

@Injectable()
export class SecretManagerService {
  private client: SecretManagerServiceClient;
  private projectId: string;

  constructor() {
    this.client = new SecretManagerServiceClient();
    this.projectId = process.env.GOOGLE_CLOUD_PROJECT || '';
  }

  async getSecret(secretName: string, version: string = 'latest'): Promise<string> {
    try {
      const name = `projects/${this.projectId}/secrets/${secretName}/versions/${version}`;
      const [response] = await this.client.accessSecretVersion({ name });
      
      if (!response.payload?.data) {
        throw new Error(`Secret ${secretName} not found or empty`);
      }

      return response.payload.data.toString();
    } catch (error) {
      console.error(`Failed to retrieve secret ${secretName}:`, error);
      throw error;
    }
  }

  async createSecret(secretName: string, secretValue: string): Promise<void> {
    try {
      // Create the secret
      const parent = `projects/${this.projectId}`;
      await this.client.createSecret({
        parent,
        secretId: secretName,
        secret: {
          replication: {
            automatic: {}
          }
        }
      });

      // Add the secret version
      await this.addSecretVersion(secretName, secretValue);
    } catch (error) {
      console.error(`Failed to create secret ${secretName}:`, error);
      throw error;
    }
  }

  async addSecretVersion(secretName: string, secretValue: string): Promise<void> {
    try {
      const parent = `projects/${this.projectId}/secrets/${secretName}`;
      await this.client.addSecretVersion({
        parent,
        payload: {
          data: Buffer.from(secretValue, 'utf8')
        }
      });
    } catch (error) {
      console.error(`Failed to add version to secret ${secretName}:`, error);
      throw error;
    }
  }

  async deleteSecret(secretName: string): Promise<void> {
    try {
      const name = `projects/${this.projectId}/secrets/${secretName}`;
      await this.client.deleteSecret({ name });
    } catch (error) {
      console.error(`Failed to delete secret ${secretName}:`, error);
      throw error;
    }
  }

  async listSecrets(): Promise<string[]> {
    try {
      const parent = `projects/${this.projectId}`;
      const [secrets] = await this.client.listSecrets({ parent });
      
      return secrets.map(secret => {
        const name = secret.name || '';
        return name.split('/').pop() || '';
      }).filter(name => name !== '');
    } catch (error) {
      console.error('Failed to list secrets:', error);
      throw error;
    }
  }
}
```

### Environment-Specific Secret Loading
```typescript
// libs/shared/config/src/secrets/environment-secrets.loader.ts
import { Injectable } from '@nestjs/common';
import { SecretManagerService } from './secret-manager.service';

@Injectable()
export class EnvironmentSecretsLoader {
  constructor(private secretManager: SecretManagerService) {}

  async loadSecrets(environment: 'test' | 'production'): Promise<Record<string, string>> {
    const secretNames = this.getSecretNamesForEnvironment(environment);
    const secrets: Record<string, string> = {};

    for (const secretName of secretNames) {
      try {
        const secretValue = await this.secretManager.getSecret(secretName);
        const envVarName = this.secretNameToEnvVar(secretName);
        secrets[envVarName] = secretValue;
        
        // Set environment variable for immediate use
        process.env[envVarName] = secretValue;
      } catch (error) {
        console.error(`Failed to load secret ${secretName}:`, error);
        // Don't fail the entire application for missing secrets in test environment
        if (environment === 'production') {
          throw error;
        }
      }
    }

    return secrets;
  }

  private getSecretNamesForEnvironment(environment: string): string[] {
    const commonSecrets = [
      `${environment}-jwt-secret`,
      `${environment}-database-url`,
      `${environment}-redis-url`,
      `${environment}-elastic-cloud-api-key`
    ];

    const oauthSecrets = [
      `${environment}-google-client-secret`,
      `${environment}-github-client-secret`
    ];

    const blockchainSecrets = [
      `${environment}-ethereum-rpc-url`,
      `${environment}-polygon-rpc-url`,
      `${environment}-solana-rpc-url`
    ];

    return [...commonSecrets, ...oauthSecrets, ...blockchainSecrets];
  }

  private secretNameToEnvVar(secretName: string): string {
    // Convert "test-jwt-secret" to "JWT_SECRET"
    const parts = secretName.split('-');
    const envParts = parts.slice(1); // Remove environment prefix
    return envParts.map(part => part.toUpperCase()).join('_');
  }
}

## Environment-Specific Deployment Patterns

### Terraform Environment Configuration
```hcl
# infrastructure/environments/test/main.tf
terraform {
  required_version = ">= 1.0"

  backend "gcs" {
    bucket = "horizon-terraform-state-test"
    prefix = "environments/test"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  environment = "test"

  common_tags = {
    Environment     = local.environment
    Project         = "horizon-sdlc"
    ManagedBy      = "terraform"
    CostCenter     = "engineering"
    Owner          = "platform-team"
  }

  # Environment-specific configuration
  config = {
    gke_node_count     = 2
    gke_machine_type   = "e2-standard-2"
    db_tier           = "db-f1-micro"
    redis_memory_size = 1
    enable_monitoring = true
    enable_logging    = true
  }
}

# GKE Cluster
resource "google_container_cluster" "main" {
  name     = "horizon-${local.environment}"
  location = var.region

  initial_node_count = local.config.gke_node_count

  node_config {
    machine_type = local.config.gke_machine_type

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = merge(local.common_tags, {
      NodePool = "default"
    })

    tags = ["horizon", local.environment, "gke-node"]
  }

  # Enable network policy
  network_policy {
    enabled = true
  }

  # Enable workload identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  resource_labels = local.common_tags
}

# Cloud SQL Database
resource "google_sql_database_instance" "main" {
  name             = "horizon-db-${local.environment}"
  database_version = "POSTGRES_14"
  region          = var.region

  settings {
    tier = local.config.db_tier

    backup_configuration {
      enabled                        = true
      start_time                    = "03:00"
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = 7
      }
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.main.id
    }

    database_flags {
      name  = "log_statement"
      value = "all"
    }

    user_labels = local.common_tags
  }

  deletion_protection = local.environment == "production"
}

# Redis Instance
resource "google_redis_instance" "main" {
  name           = "horizon-redis-${local.environment}"
  memory_size_gb = local.config.redis_memory_size
  region         = var.region

  redis_version = "REDIS_6_X"
  display_name  = "Horizon Redis ${title(local.environment)}"

  labels = local.common_tags
}
```

### Kubernetes Deployment Manifests
```yaml
# infrastructure/k8s/environments/test/api-core-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-core
  namespace: horizon-test
  labels:
    app: api-core
    environment: test
    version: "1.0.0"
    component: backend
    managed-by: argocd
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-core
      environment: test
  template:
    metadata:
      labels:
        app: api-core
        environment: test
        version: "1.0.0"
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "3000"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: api-core-sa
      containers:
      - name: api-core
        image: gcr.io/horizon-project/api-core:test-latest
        ports:
        - containerPort: 3000
          name: http
        env:
        - name: NODE_ENV
          value: "test"
        - name: ENVIRONMENT
          value: "test"
        - name: GCP_PROJECT_ID
          valueFrom:
            fieldRef:
              fieldPath: metadata.annotations['iam.gke.io/gcp-service-account']
        envFrom:
        - configMapRef:
            name: api-core-config
        - secretRef:
            name: api-core-secrets
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
        securityContext:
          runAsNonRoot: true
          runAsUser: 1000
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-core-config
  namespace: horizon-test
  labels:
    app: api-core
    environment: test
data:
  REDIS_DB: "0"
  REDIS_MAX_RETRIES: "3"
  JWT_EXPIRY: "15m"
  REFRESH_TOKEN_EXPIRY: "7d"
  FEATURE_BLOCKCHAIN: "true"
  FEATURE_ANALYTICS: "false"
  DEFAULT_BLOCKCHAIN_NETWORK: "sepolia"
  OTEL_SERVICE_NAME: "api-core-test"
---
apiVersion: v1
kind: Service
metadata:
  name: api-core-service
  namespace: horizon-test
  labels:
    app: api-core
    environment: test
spec:
  selector:
    app: api-core
    environment: test
  ports:
  - port: 80
    targetPort: 3000
    name: http
  type: ClusterIP
```

## Resource Tagging Strategies

### GCP Resource Tagging Standards
```typescript
// libs/shared/infrastructure/src/tagging/gcp-tags.ts
export interface ResourceTags {
  // Mandatory tags for cost attribution
  Environment: 'test' | 'production';
  Project: string;
  Application: string;

  // Operational tags
  ManagedBy: 'terraform' | 'manual' | 'argocd';
  Owner: string;
  CostCenter: string;

  // Optional tags
  Version?: string;
  Component?: string;
  Backup?: 'enabled' | 'disabled';
  Monitoring?: 'enabled' | 'disabled';
}

export class GCPResourceTagger {
  static createStandardTags(
    environment: 'test' | 'production',
    application: string,
    component?: string
  ): ResourceTags {
    return {
      Environment: environment,
      Project: 'horizon-sdlc',
      Application: application,
      ManagedBy: 'terraform',
      Owner: 'platform-team',
      CostCenter: 'engineering',
      ...(component && { Component: component })
    };
  }

  static validateTags(tags: Partial<ResourceTags>): string[] {
    const errors: string[] = [];
    const required: (keyof ResourceTags)[] = ['Environment', 'Project', 'Application', 'ManagedBy', 'Owner', 'CostCenter'];

    required.forEach(key => {
      if (!tags[key]) {
        errors.push(`Missing required tag: ${key}`);
      }
    });

    // Validate tag values
    if (tags.Environment && !['test', 'production'].includes(tags.Environment)) {
      errors.push('Environment must be either "test" or "production"');
    }

    if (tags.ManagedBy && !['terraform', 'manual', 'argocd'].includes(tags.ManagedBy)) {
      errors.push('ManagedBy must be one of: terraform, manual, argocd');
    }

    return errors;
  }

  static formatForTerraform(tags: ResourceTags): Record<string, string> {
    return Object.entries(tags).reduce((acc, [key, value]) => {
      if (value !== undefined) {
        acc[key.toLowerCase().replace(/([A-Z])/g, '_$1').substring(1)] = value;
      }
      return acc;
    }, {} as Record<string, string>);
  }

  static formatForKubernetes(tags: ResourceTags): Record<string, string> {
    return Object.entries(tags).reduce((acc, [key, value]) => {
      if (value !== undefined) {
        acc[key.toLowerCase().replace(/([A-Z])/g, '-$1').substring(1)] = value;
      }
      return acc;
    }, {} as Record<string, string>);
  }
}
```

### Automated Tagging with Terraform
```hcl
# infrastructure/modules/common/variables.tf
variable "environment" {
  description = "Environment name (test or production)"
  type        = string
  validation {
    condition     = contains(["test", "production"], var.environment)
    error_message = "Environment must be either 'test' or 'production'."
  }
}

variable "application" {
  description = "Application name"
  type        = string
}

variable "component" {
  description = "Component name (optional)"
  type        = string
  default     = ""
}

# infrastructure/modules/common/locals.tf
locals {
  standard_tags = {
    environment  = var.environment
    project      = "horizon-sdlc"
    application  = var.application
    managed_by   = "terraform"
    owner        = "platform-team"
    cost_center  = "engineering"
    component    = var.component != "" ? var.component : null
  }

  # Remove null values
  resource_labels = { for k, v in local.standard_tags : k => v if v != null }
}

# infrastructure/modules/common/outputs.tf
output "resource_labels" {
  description = "Standard resource labels for GCP resources"
  value       = local.resource_labels
}

output "kubernetes_labels" {
  description = "Standard labels for Kubernetes resources"
  value = {
    for k, v in local.resource_labels :
    replace(k, "_", "-") => v
  }
}
```

## Best Practices

### Configuration Management
- **Environment Separation**: Maintain strict separation between test and production configurations
- **Secret Rotation**: Implement automated secret rotation policies
- **Configuration Validation**: Validate all configuration at startup
- **Default Values**: Provide sensible defaults for non-critical configuration

### Security Considerations
- **Least Privilege**: Grant minimum necessary permissions for each environment
- **Secret Encryption**: Encrypt all secrets at rest and in transit
- **Access Auditing**: Log all access to secrets and configuration
- **Network Isolation**: Isolate environments using VPCs and network policies

### Deployment Strategies
- **Blue-Green Deployments**: Use blue-green deployments for zero-downtime updates
- **Canary Releases**: Implement canary releases for gradual rollouts
- **Rollback Procedures**: Maintain clear rollback procedures for each environment
- **Health Checks**: Implement comprehensive health checks for all services

### Resource Management
- **Cost Optimization**: Right-size resources based on environment needs
- **Resource Cleanup**: Implement automated cleanup of unused resources
- **Monitoring**: Monitor resource usage and costs across environments
- **Tagging Compliance**: Enforce mandatory tagging policies

This environment management patterns template provides comprehensive guidance for managing configurations, secrets, deployments, and resources across different environments within our NX monorepo structure.


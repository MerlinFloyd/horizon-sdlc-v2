# OpenTelemetry Instrumentation Template

## Overview
This template provides comprehensive OpenTelemetry instrumentation patterns following our observability standards with structured logging, distributed tracing, and metrics collection for Node.js, Python AI services, Go applications, GitHub Actions CI/CD, PostgreSQL databases, and Kubernetes clusters. All telemetry data is sent to Elastic Cloud as our centralized observability platform.

## Core OpenTelemetry Setup

### 1. Base Instrumentation Configuration
```typescript
// libs/shared/utils/src/telemetry/instrumentation.ts
import { NodeSDK } from '@opentelemetry/sdk-node';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { PeriodicExportingMetricReader } from '@opentelemetry/sdk-metrics';
import { OTLPTraceExporter } from '@opentelemetry/exporter-otlp-http';
import { OTLPMetricExporter } from '@opentelemetry/exporter-otlp-http';
import { ElasticsearchInstrumentation } from '@opentelemetry/instrumentation-elasticsearch';
import { RedisInstrumentation } from '@opentelemetry/instrumentation-redis-4';
import { PrismaInstrumentation } from '@prisma/instrumentation';

const serviceName = process.env.SERVICE_NAME || 'horizon-service';
const serviceVersion = process.env.SERVICE_VERSION || '1.0.0';
const environment = process.env.NODE_ENV || 'development';

// Resource configuration
const resource = new Resource({
  [SemanticResourceAttributes.SERVICE_NAME]: serviceName,
  [SemanticResourceAttributes.SERVICE_VERSION]: serviceVersion,
  [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: environment,
  [SemanticResourceAttributes.SERVICE_NAMESPACE]: 'horizon',
  [SemanticResourceAttributes.SERVICE_INSTANCE_ID]: process.env.HOSTNAME || 'unknown',
});

// Elastic Cloud exporter configuration
const traceExporter = new OTLPTraceExporter({
  url: process.env.ELASTIC_APM_SERVER_URL || 'https://your-deployment.apm.us-central1.gcp.cloud.es.io',
  headers: {
    'Authorization': `Bearer ${process.env.ELASTIC_APM_SECRET_TOKEN}`,
  },
});

// Metric exporter configuration for Elastic Cloud
const metricExporter = new OTLPMetricExporter({
  url: process.env.ELASTIC_APM_SERVER_URL || 'https://your-deployment.apm.us-central1.gcp.cloud.es.io',
  headers: {
    'Authorization': `Bearer ${process.env.ELASTIC_APM_SECRET_TOKEN}`,
  },
});

// Metric reader configuration
const metricReader = new PeriodicExportingMetricReader({
  exporter: metricExporter,
  exportIntervalMillis: 30000, // Export every 30 seconds
});

// SDK configuration
const sdk = new NodeSDK({
  resource,
  traceExporter,
  metricReader,
  instrumentations: [
    getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-fs': {
        enabled: false, // Disable file system instrumentation for performance
      },
      '@opentelemetry/instrumentation-http': {
        enabled: true,
        requestHook: (span, request) => {
          // Add custom attributes to HTTP spans
          span.setAttributes({
            'http.request.header.user-agent': request.headers['user-agent'],
            'http.request.header.x-forwarded-for': request.headers['x-forwarded-for'],
          });
        },
        responseHook: (span, response) => {
          // Add response attributes
          span.setAttributes({
            'http.response.header.content-type': response.headers['content-type'],
          });
        },
      },
      '@opentelemetry/instrumentation-express': {
        enabled: true,
        requestHook: (span, info) => {
          // Add Express-specific attributes
          span.setAttributes({
            'express.route': info.route?.path,
            'express.method': info.request.method,
          });
        },
      },
    }),
    new ElasticsearchInstrumentation(),
    new RedisInstrumentation(),
    new PrismaInstrumentation(),
  ],
});

// Initialize the SDK
export function initializeTelemetry(): void {
  sdk.start();
  console.log('OpenTelemetry initialized successfully');
}

// Graceful shutdown
process.on('SIGTERM', () => {
  sdk.shutdown()
    .then(() => console.log('OpenTelemetry terminated'))
    .catch((error) => console.log('Error terminating OpenTelemetry', error))
    .finally(() => process.exit(0));
});
```

### 2. Custom Instrumentation Utilities
```typescript
// libs/shared/utils/src/telemetry/tracer.ts
import { trace, context, SpanStatusCode, SpanKind } from '@opentelemetry/api';
import { SemanticAttributes } from '@opentelemetry/semantic-conventions';

const tracer = trace.getTracer('horizon-tracer', '1.0.0');

export interface SpanOptions {
  name: string;
  kind?: SpanKind;
  attributes?: Record<string, string | number | boolean>;
  parent?: any;
}

export class TracingService {
  static async withSpan<T>(
    options: SpanOptions,
    fn: (span: any) => Promise<T>
  ): Promise<T> {
    const span = tracer.startSpan(options.name, {
      kind: options.kind || SpanKind.INTERNAL,
      attributes: options.attributes,
    }, options.parent);

    try {
      const result = await context.with(trace.setSpan(context.active(), span), () => fn(span));
      span.setStatus({ code: SpanStatusCode.OK });
      return result;
    } catch (error) {
      span.setStatus({
        code: SpanStatusCode.ERROR,
        message: error instanceof Error ? error.message : 'Unknown error',
      });
      span.recordException(error as Error);
      throw error;
    } finally {
      span.end();
    }
  }

  static createDatabaseSpan(operation: string, table: string, query?: string) {
    return tracer.startSpan(`db.${operation}`, {
      kind: SpanKind.CLIENT,
      attributes: {
        [SemanticAttributes.DB_SYSTEM]: 'postgresql',
        [SemanticAttributes.DB_OPERATION]: operation,
        [SemanticAttributes.DB_SQL_TABLE]: table,
        [SemanticAttributes.DB_STATEMENT]: query,
      },
    });
  }

  static createHttpClientSpan(method: string, url: string) {
    return tracer.startSpan(`HTTP ${method}`, {
      kind: SpanKind.CLIENT,
      attributes: {
        [SemanticAttributes.HTTP_METHOD]: method,
        [SemanticAttributes.HTTP_URL]: url,
      },
    });
  }

  static createBusinessLogicSpan(operation: string, attributes?: Record<string, any>) {
    return tracer.startSpan(operation, {
      kind: SpanKind.INTERNAL,
      attributes: {
        'business.operation': operation,
        ...attributes,
      },
    });
  }

  static addUserContext(userId: string, email?: string) {
    const span = trace.getActiveSpan();
    if (span) {
      span.setAttributes({
        'user.id': userId,
        'user.email': email || '',
      });
    }
  }

  static addErrorContext(error: Error, context?: Record<string, any>) {
    const span = trace.getActiveSpan();
    if (span) {
      span.recordException(error);
      span.setStatus({
        code: SpanStatusCode.ERROR,
        message: error.message,
      });
      if (context) {
        span.setAttributes(context);
      }
    }
  }
}
```

## Metrics Collection

### 1. Custom Metrics Service
```typescript
// libs/shared/utils/src/telemetry/metrics.ts
import { metrics } from '@opentelemetry/api';
import { MeterProvider } from '@opentelemetry/sdk-metrics';

const meter = metrics.getMeter('horizon-metrics', '1.0.0');

// Business metrics
const userRegistrationCounter = meter.createCounter('user_registrations_total', {
  description: 'Total number of user registrations',
});

const paymentProcessedCounter = meter.createCounter('payments_processed_total', {
  description: 'Total number of payments processed',
});

const paymentAmountHistogram = meter.createHistogram('payment_amount', {
  description: 'Payment amounts in USD',
  unit: 'USD',
});

const apiRequestDuration = meter.createHistogram('api_request_duration', {
  description: 'API request duration in milliseconds',
  unit: 'ms',
});

const activeUsersGauge = meter.createUpDownCounter('active_users', {
  description: 'Number of currently active users',
});

const databaseConnectionsGauge = meter.createUpDownCounter('database_connections', {
  description: 'Number of active database connections',
});

export class MetricsService {
  // Business metrics
  static recordUserRegistration(source: string = 'web') {
    userRegistrationCounter.add(1, { source });
  }

  static recordPaymentProcessed(
    amount: number,
    currency: string,
    status: 'success' | 'failed',
    paymentMethod: string
  ) {
    paymentProcessedCounter.add(1, {
      currency,
      status,
      payment_method: paymentMethod,
    });

    if (status === 'success') {
      paymentAmountHistogram.record(amount, {
        currency,
        payment_method: paymentMethod,
      });
    }
  }

  // Performance metrics
  static recordApiRequestDuration(
    duration: number,
    method: string,
    route: string,
    statusCode: number
  ) {
    apiRequestDuration.record(duration, {
      method,
      route,
      status_code: statusCode.toString(),
    });
  }

  // System metrics
  static updateActiveUsers(count: number) {
    activeUsersGauge.add(count);
  }

  static updateDatabaseConnections(count: number) {
    databaseConnectionsGauge.add(count);
  }

  // Error metrics
  static recordError(
    errorType: string,
    service: string,
    operation: string
  ) {
    const errorCounter = meter.createCounter('errors_total', {
      description: 'Total number of errors',
    });

    errorCounter.add(1, {
      error_type: errorType,
      service,
      operation,
    });
  }

  // Cache metrics
  static recordCacheOperation(
    operation: 'hit' | 'miss' | 'set' | 'delete',
    cacheType: string = 'redis'
  ) {
    const cacheCounter = meter.createCounter('cache_operations_total', {
      description: 'Total number of cache operations',
    });

    cacheCounter.add(1, {
      operation,
      cache_type: cacheType,
    });
  }
}
```

## Express.js Integration

### 1. Express Middleware
```typescript
// libs/api/middleware/src/telemetry/telemetry.middleware.ts
import { Request, Response, NextFunction } from 'express';
import { trace, context } from '@opentelemetry/api';
import { TracingService, MetricsService } from '@shared/utils';

export interface TelemetryRequest extends Request {
  startTime?: number;
  traceId?: string;
  spanId?: string;
}

export function telemetryMiddleware() {
  return (req: TelemetryRequest, res: Response, next: NextFunction) => {
    req.startTime = Date.now();
    
    const span = trace.getActiveSpan();
    if (span) {
      const spanContext = span.spanContext();
      req.traceId = spanContext.traceId;
      req.spanId = spanContext.spanId;
      
      // Add request attributes to span
      span.setAttributes({
        'http.request.method': req.method,
        'http.request.url': req.url,
        'http.request.route': req.route?.path || req.path,
        'http.request.user_agent': req.get('User-Agent') || '',
        'http.request.ip': req.ip,
      });

      // Add user context if available
      if (req.user) {
        TracingService.addUserContext(req.user.id, req.user.email);
      }
    }

    // Override res.end to capture response metrics
    const originalEnd = res.end;
    res.end = function(chunk?: any, encoding?: any) {
      const duration = Date.now() - (req.startTime || Date.now());
      
      // Record metrics
      MetricsService.recordApiRequestDuration(
        duration,
        req.method,
        req.route?.path || req.path,
        res.statusCode
      );

      // Add response attributes to span
      if (span) {
        span.setAttributes({
          'http.response.status_code': res.statusCode,
          'http.response.duration_ms': duration,
        });
      }

      // Call original end method
      originalEnd.call(this, chunk, encoding);
    };

    next();
  };
}

export function errorTelemetryMiddleware() {
  return (error: Error, req: TelemetryRequest, res: Response, next: NextFunction) => {
    // Record error metrics
    MetricsService.recordError(
      error.constructor.name,
      'api-core',
      `${req.method} ${req.route?.path || req.path}`
    );

    // Add error context to span
    TracingService.addErrorContext(error, {
      'error.request.method': req.method,
      'error.request.url': req.url,
      'error.request.user_id': req.user?.id,
    });

    next(error);
  };
}
```

## Database Instrumentation

### 1. Prisma Instrumentation
```typescript
// libs/api/database/src/telemetry/prisma-telemetry.ts
import { PrismaClient } from '@prisma/client';
import { TracingService, MetricsService } from '@shared/utils';

export function createInstrumentedPrismaClient(): PrismaClient {
  const prisma = new PrismaClient({
    log: [
      { emit: 'event', level: 'query' },
      { emit: 'event', level: 'error' },
      { emit: 'event', level: 'info' },
      { emit: 'event', level: 'warn' },
    ],
  });

  // Query instrumentation
  prisma.$on('query', (e) => {
    const span = TracingService.createDatabaseSpan(
      'query',
      extractTableFromQuery(e.query),
      e.query
    );

    span.setAttributes({
      'db.query.duration_ms': e.duration,
      'db.query.params': JSON.stringify(e.params),
    });

    span.end();

    // Record metrics
    MetricsService.recordApiRequestDuration(
      e.duration,
      'DATABASE',
      'query',
      200
    );
  });

  // Error instrumentation
  prisma.$on('error', (e) => {
    MetricsService.recordError(
      'DatabaseError',
      'prisma',
      'query'
    );

    TracingService.addErrorContext(new Error(e.message), {
      'db.error.target': e.target,
    });
  });

  return prisma;
}

function extractTableFromQuery(query: string): string {
  // Simple regex to extract table name from SQL query
  const match = query.match(/(?:FROM|INTO|UPDATE|DELETE FROM)\s+`?(\w+)`?/i);
  return match ? match[1] : 'unknown';
}
```

### 2. Redis Instrumentation
```typescript
// libs/api/services/src/cache/instrumented-redis.service.ts
import { Redis } from 'ioredis';
import { TracingService, MetricsService } from '@shared/utils';
import { CacheService } from '@shared/types';

export class InstrumentedRedisCacheService implements CacheService {
  private redis: Redis;

  constructor() {
    this.redis = new Redis({
      host: process.env.REDIS_HOST || 'localhost',
      port: parseInt(process.env.REDIS_PORT || '6379'),
      password: process.env.REDIS_PASSWORD,
    });
  }

  async get<T>(key: string): Promise<T | null> {
    return TracingService.withSpan(
      {
        name: 'redis.get',
        attributes: {
          'cache.key': key,
          'cache.operation': 'get',
        },
      },
      async (span) => {
        try {
          const value = await this.redis.get(key);
          const hit = value !== null;
          
          span.setAttributes({
            'cache.hit': hit,
          });

          MetricsService.recordCacheOperation(hit ? 'hit' : 'miss');
          
          return value ? JSON.parse(value) : null;
        } catch (error) {
          MetricsService.recordError('CacheError', 'redis', 'get');
          throw error;
        }
      }
    );
  }

  async set<T>(key: string, value: T, ttl?: number): Promise<void> {
    return TracingService.withSpan(
      {
        name: 'redis.set',
        attributes: {
          'cache.key': key,
          'cache.operation': 'set',
          'cache.ttl': ttl || 0,
        },
      },
      async () => {
        try {
          const serialized = JSON.stringify(value);
          if (ttl) {
            await this.redis.setex(key, ttl, serialized);
          } else {
            await this.redis.set(key, serialized);
          }

          MetricsService.recordCacheOperation('set');
        } catch (error) {
          MetricsService.recordError('CacheError', 'redis', 'set');
          throw error;
        }
      }
    );
  }

  async delete(key: string): Promise<void> {
    return TracingService.withSpan(
      {
        name: 'redis.delete',
        attributes: {
          'cache.key': key,
          'cache.operation': 'delete',
        },
      },
      async () => {
        try {
          await this.redis.del(key);
          MetricsService.recordCacheOperation('delete');
        } catch (error) {
          MetricsService.recordError('CacheError', 'redis', 'delete');
          throw error;
        }
      }
    );
  }

  async clear(): Promise<void> {
    return TracingService.withSpan(
      {
        name: 'redis.clear',
        attributes: {
          'cache.operation': 'clear',
        },
      },
      async () => {
        try {
          await this.redis.flushall();
        } catch (error) {
          MetricsService.recordError('CacheError', 'redis', 'clear');
          throw error;
        }
      }
    );
  }

  async exists(key: string): Promise<boolean> {
    return TracingService.withSpan(
      {
        name: 'redis.exists',
        attributes: {
          'cache.key': key,
          'cache.operation': 'exists',
        },
      },
      async () => {
        try {
          const result = await this.redis.exists(key);
          return result === 1;
        } catch (error) {
          MetricsService.recordError('CacheError', 'redis', 'exists');
          throw error;
        }
      }
    );
  }
}
```

## Service Instrumentation

### 1. Business Logic Instrumentation
```typescript
// libs/api/services/src/user/instrumented-user.service.ts
import { Injectable } from '@nestjs/common';
import { UserRepository } from './user.repository';
import { User, CreateUserDto, UpdateUserDto } from '@shared/types';
import { TracingService, MetricsService } from '@shared/utils';

@Injectable()
export class InstrumentedUserService {
  constructor(private readonly userRepository: UserRepository) {}

  async createUser(userData: CreateUserDto): Promise<User> {
    return TracingService.withSpan(
      {
        name: 'user.create',
        attributes: {
          'user.email': userData.email,
          'user.operation': 'create',
        },
      },
      async (span) => {
        try {
          const user = await this.userRepository.create(userData);
          
          // Record business metrics
          MetricsService.recordUserRegistration('api');
          
          span.setAttributes({
            'user.id': user.id,
            'user.created': true,
          });

          return user;
        } catch (error) {
          MetricsService.recordError('UserCreationError', 'user-service', 'create');
          throw error;
        }
      }
    );
  }

  async getUserById(id: string): Promise<User | null> {
    return TracingService.withSpan(
      {
        name: 'user.get',
        attributes: {
          'user.id': id,
          'user.operation': 'get',
        },
      },
      async (span) => {
        const user = await this.userRepository.findById(id);
        
        span.setAttributes({
          'user.found': user !== null,
        });

        return user;
      }
    );
  }

  async updateUser(id: string, userData: UpdateUserDto): Promise<User> {
    return TracingService.withSpan(
      {
        name: 'user.update',
        attributes: {
          'user.id': id,
          'user.operation': 'update',
        },
      },
      async () => {
        return this.userRepository.update(id, userData);
      }
    );
  }

  async deleteUser(id: string): Promise<void> {
    return TracingService.withSpan(
      {
        name: 'user.delete',
        attributes: {
          'user.id': id,
          'user.operation': 'delete',
        },
      },
      async () => {
        await this.userRepository.delete(id);
      }
    );
  }
}
```

## Application Initialization

### 1. Application Bootstrap
```typescript
// apps/api-core/src/main.ts
import { initializeTelemetry } from '@shared/utils';

// Initialize telemetry BEFORE importing other modules
initializeTelemetry();

import { NestFactory } from '@nestjs/core';
import { AppModule } from './app/app.module';
import { telemetryMiddleware, errorTelemetryMiddleware } from '@api/middleware';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Add telemetry middleware
  app.use(telemetryMiddleware());
  app.use(errorTelemetryMiddleware());
  
  const port = process.env.PORT || 3001;
  await app.listen(port);
  
  console.log(`Application is running on: http://localhost:${port}`);
}

bootstrap();
```

## PostgreSQL Database Instrumentation

### 1. PostgreSQL Connection Pool Instrumentation
```typescript
// libs/api/database/src/telemetry/instrumented-postgres.ts
import { Pool, PoolClient, QueryResult } from 'pg';
import { TracingService, MetricsService } from '@shared/utils';
import { trace, context } from '@opentelemetry/api';

export class InstrumentedPostgresPool {
  private pool: Pool;
  private poolMetrics: {
    totalConnections: number;
    idleConnections: number;
    waitingClients: number;
  };

  constructor(config: any) {
    this.pool = new Pool(config);
    this.poolMetrics = {
      totalConnections: 0,
      idleConnections: 0,
      waitingClients: 0,
    };

    // Set up pool event listeners for metrics
    this.setupPoolMetrics();
  }

  private setupPoolMetrics() {
    this.pool.on('connect', (client) => {
      this.poolMetrics.totalConnections++;
      MetricsService.updateDatabaseConnections(this.poolMetrics.totalConnections);
    });

    this.pool.on('remove', (client) => {
      this.poolMetrics.totalConnections--;
      MetricsService.updateDatabaseConnections(this.poolMetrics.totalConnections);
    });

    this.pool.on('acquire', (client) => {
      this.poolMetrics.idleConnections--;
    });

    this.pool.on('release', (client) => {
      this.poolMetrics.idleConnections++;
    });

    // Periodic metrics reporting
    setInterval(() => {
      MetricsService.recordDatabasePoolMetrics({
        totalConnections: this.pool.totalCount,
        idleConnections: this.pool.idleCount,
        waitingClients: this.pool.waitingCount,
      });
    }, 30000); // Every 30 seconds
  }

  async query<T = any>(text: string, params?: any[]): Promise<QueryResult<T>> {
    return TracingService.withSpan(
      {
        name: 'postgresql.query',
        attributes: {
          'db.system': 'postgresql',
          'db.statement': text,
          'db.operation': this.extractOperation(text),
          'db.sql.table': this.extractTable(text),
        },
      },
      async (span) => {
        const startTime = Date.now();

        try {
          const result = await this.pool.query(text, params);
          const duration = Date.now() - startTime;

          span.setAttributes({
            'db.rows_affected': result.rowCount || 0,
            'db.query.duration_ms': duration,
          });

          // Record metrics
          MetricsService.recordDatabaseQuery(
            this.extractOperation(text),
            this.extractTable(text),
            duration,
            'success'
          );

          return result;
        } catch (error) {
          const duration = Date.now() - startTime;

          MetricsService.recordDatabaseQuery(
            this.extractOperation(text),
            this.extractTable(text),
            duration,
            'error'
          );

          MetricsService.recordError(
            'DatabaseError',
            'postgresql',
            this.extractOperation(text)
          );

          throw error;
        }
      }
    );
  }

  async getClient(): Promise<InstrumentedPoolClient> {
    return TracingService.withSpan(
      {
        name: 'postgresql.getClient',
        attributes: {
          'db.system': 'postgresql',
          'db.operation': 'getClient',
        },
      },
      async () => {
        const client = await this.pool.connect();
        return new InstrumentedPoolClient(client);
      }
    );
  }

  private extractOperation(query: string): string {
    const match = query.trim().match(/^(SELECT|INSERT|UPDATE|DELETE|CREATE|DROP|ALTER)/i);
    return match ? match[1].toUpperCase() : 'UNKNOWN';
  }

  private extractTable(query: string): string {
    const patterns = [
      /FROM\s+([`"]?)(\w+)\1/i,
      /INTO\s+([`"]?)(\w+)\1/i,
      /UPDATE\s+([`"]?)(\w+)\1/i,
      /TABLE\s+([`"]?)(\w+)\1/i,
    ];

    for (const pattern of patterns) {
      const match = query.match(pattern);
      if (match) return match[2];
    }

    return 'unknown';
  }

  async end(): Promise<void> {
    await this.pool.end();
  }
}

export class InstrumentedPoolClient {
  constructor(private client: PoolClient) {}

  async query<T = any>(text: string, params?: any[]): Promise<QueryResult<T>> {
    return TracingService.withSpan(
      {
        name: 'postgresql.client.query',
        attributes: {
          'db.system': 'postgresql',
          'db.statement': text,
          'db.operation': this.extractOperation(text),
        },
      },
      async (span) => {
        const startTime = Date.now();

        try {
          const result = await this.client.query(text, params);
          const duration = Date.now() - startTime;

          span.setAttributes({
            'db.rows_affected': result.rowCount || 0,
            'db.query.duration_ms': duration,
          });

          return result;
        } catch (error) {
          TracingService.addErrorContext(error as Error, {
            'db.query': text,
            'db.params': JSON.stringify(params),
          });
          throw error;
        }
      }
    );
  }

  async begin(): Promise<void> {
    return TracingService.withSpan(
      {
        name: 'postgresql.transaction.begin',
        attributes: {
          'db.system': 'postgresql',
          'db.operation': 'BEGIN',
        },
      },
      async () => {
        await this.client.query('BEGIN');
      }
    );
  }

  async commit(): Promise<void> {
    return TracingService.withSpan(
      {
        name: 'postgresql.transaction.commit',
        attributes: {
          'db.system': 'postgresql',
          'db.operation': 'COMMIT',
        },
      },
      async () => {
        await this.client.query('COMMIT');
      }
    );
  }

  async rollback(): Promise<void> {
    return TracingService.withSpan(
      {
        name: 'postgresql.transaction.rollback',
        attributes: {
          'db.system': 'postgresql',
          'db.operation': 'ROLLBACK',
        },
      },
      async () => {
        await this.client.query('ROLLBACK');
      }
    );
  }

  release(): void {
    this.client.release();
  }

  private extractOperation(query: string): string {
    const match = query.trim().match(/^(SELECT|INSERT|UPDATE|DELETE|CREATE|DROP|ALTER|BEGIN|COMMIT|ROLLBACK)/i);
    return match ? match[1].toUpperCase() : 'UNKNOWN';
  }
}
```

### 2. Enhanced Metrics for Database Operations
```typescript
// libs/shared/utils/src/telemetry/database-metrics.ts
import { metrics } from '@opentelemetry/api';

const meter = metrics.getMeter('horizon-database-metrics', '1.0.0');

// Database connection metrics
const dbConnectionsGauge = meter.createUpDownCounter('db_connections_active', {
  description: 'Number of active database connections',
});

const dbConnectionPoolGauge = meter.createUpDownCounter('db_connection_pool_size', {
  description: 'Database connection pool size',
});

// Query performance metrics
const dbQueryDuration = meter.createHistogram('db_query_duration', {
  description: 'Database query duration in milliseconds',
  unit: 'ms',
});

const dbQueryCounter = meter.createCounter('db_queries_total', {
  description: 'Total number of database queries',
});

const dbTransactionDuration = meter.createHistogram('db_transaction_duration', {
  description: 'Database transaction duration in milliseconds',
  unit: 'ms',
});

export class DatabaseMetricsService {
  static recordDatabaseQuery(
    operation: string,
    table: string,
    duration: number,
    status: 'success' | 'error'
  ) {
    const labels = {
      operation: operation.toLowerCase(),
      table,
      status,
    };

    dbQueryCounter.add(1, labels);
    dbQueryDuration.record(duration, labels);
  }

  static recordDatabasePoolMetrics(metrics: {
    totalConnections: number;
    idleConnections: number;
    waitingClients: number;
  }) {
    dbConnectionsGauge.add(metrics.totalConnections, { state: 'total' });
    dbConnectionsGauge.add(metrics.idleConnections, { state: 'idle' });
    dbConnectionsGauge.add(metrics.waitingClients, { state: 'waiting' });
  }

  static recordTransaction(duration: number, status: 'commit' | 'rollback') {
    dbTransactionDuration.record(duration, { status });
  }
}
```

## Kubernetes Cluster Instrumentation

### 1. Kubernetes Metrics Collection
```yaml
# k8s/observability/otel-k8s-collector.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-k8s-collector-config
  namespace: observability
data:
  config.yaml: |
    receivers:
      # Kubernetes cluster metrics
      k8s_cluster:
        auth_type: serviceAccount
        node_conditions_to_report: [Ready, MemoryPressure, DiskPressure, PIDPressure]
        allocatable_types_to_report: [cpu, memory, storage]

      # Kubernetes events
      k8s_events:
        auth_type: serviceAccount

      # Kubelet metrics
      kubeletstats:
        collection_interval: 20s
        auth_type: serviceAccount
        endpoint: ${K8S_NODE_NAME}:10250
        insecure_skip_verify: true
        metric_groups:
          - node
          - pod
          - container
          - volume

      # Host metrics
      hostmetrics:
        collection_interval: 30s
        scrapers:
          cpu:
            metrics:
              system.cpu.utilization:
                enabled: true
          memory:
            metrics:
              system.memory.utilization:
                enabled: true
          disk:
            metrics:
              system.disk.io:
                enabled: true
          network:
            metrics:
              system.network.io:
                enabled: true
          filesystem:
            metrics:
              system.filesystem.utilization:
                enabled: true

    processors:
      # Add Kubernetes metadata
      k8sattributes:
        auth_type: serviceAccount
        passthrough: false
        filter:
          node_from_env_var: K8S_NODE_NAME
        extract:
          metadata:
            - k8s.pod.name
            - k8s.pod.uid
            - k8s.deployment.name
            - k8s.namespace.name
            - k8s.node.name
            - k8s.pod.start_time
        pod_association:
          - sources:
            - from: resource_attribute
              name: k8s.pod.ip
          - sources:
            - from: resource_attribute
              name: k8s.pod.uid
          - sources:
            - from: connection

      # Resource processor to add cluster info
      resource:
        attributes:
        - key: k8s.cluster.name
          value: horizon-test-gke
          action: upsert
        - key: cloud.provider
          value: gcp
          action: upsert
        - key: cloud.platform
          value: gcp_kubernetes_engine
          action: upsert

      # Batch processor
      batch:
        timeout: 1s
        send_batch_size: 1024

    exporters:
      # Elastic Cloud exporter
      elasticsearch:
        endpoints:
        - ${ELASTIC_CLOUD_ENDPOINT}
        api_key: ${ELASTIC_CLOUD_API_KEY}
        logs_index: logs-k8s-horizon
        metrics_index: metrics-k8s-horizon

      # Elastic APM exporter
      otlphttp:
        endpoint: ${ELASTIC_APM_ENDPOINT}
        headers:
          Authorization: "Bearer ${ELASTIC_APM_SECRET_TOKEN}"

    service:
      pipelines:
        metrics:
          receivers: [k8s_cluster, kubeletstats, hostmetrics]
          processors: [k8sattributes, resource, batch]
          exporters: [elasticsearch, otlphttp]
        logs:
          receivers: [k8s_events]
          processors: [k8sattributes, resource, batch]
          exporters: [elasticsearch]

---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: otel-k8s-collector
  namespace: observability
  labels:
    app: otel-k8s-collector
spec:
  selector:
    matchLabels:
      app: otel-k8s-collector
  template:
    metadata:
      labels:
        app: otel-k8s-collector
    spec:
      serviceAccountName: otel-k8s-collector
      hostNetwork: true
      hostPID: true
      containers:
      - name: otel-collector
        image: otel/opentelemetry-collector-contrib:latest
        args: ["--config=/etc/config/config.yaml"]
        env:
        - name: K8S_NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        - name: K8S_POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
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
        - containerPort: 8888
          name: metrics
        - containerPort: 8889
          name: health
        volumeMounts:
        - name: config
          mountPath: /etc/config
        - name: proc
          mountPath: /host/proc
          readOnly: true
        - name: sys
          mountPath: /host/sys
          readOnly: true
        - name: varlog
          mountPath: /var/log
          readOnly: true
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
        securityContext:
          privileged: true
          runAsUser: 0
      volumes:
      - name: config
        configMap:
          name: otel-k8s-collector-config
      - name: proc
        hostPath:
          path: /proc
      - name: sys
        hostPath:
          path: /sys
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      tolerations:
      - operator: Exists
        effect: NoSchedule
      - operator: Exists
        effect: NoExecute

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: otel-k8s-collector
  namespace: observability

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: otel-k8s-collector
rules:
- apiGroups: [""]
  resources: ["nodes", "nodes/proxy", "nodes/metrics", "services", "endpoints", "pods", "events"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "daemonsets", "statefulsets"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["extensions"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["batch"]
  resources: ["jobs", "cronjobs"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["autoscaling"]
  resources: ["horizontalpodautoscalers"]
  verbs: ["get", "list", "watch"]
- nonResourceURLs: ["/metrics", "/metrics/cadvisor"]
  verbs: ["get"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: otel-k8s-collector
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: otel-k8s-collector
subjects:
- kind: ServiceAccount
  name: otel-k8s-collector
  namespace: observability
```

### 2. Pod-Level Instrumentation
```yaml
# k8s/observability/pod-telemetry.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: pod-telemetry-config
  namespace: horizon
data:
  telemetry.js: |
    const { NodeSDK } = require('@opentelemetry/sdk-node');
    const { Resource } = require('@opentelemetry/resources');
    const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');
    const { OTLPTraceExporter } = require('@opentelemetry/exporter-otlp-http');
    const { OTLPMetricExporter } = require('@opentelemetry/exporter-otlp-http');
    const { PeriodicExportingMetricReader } = require('@opentelemetry/sdk-metrics');

    // Get Kubernetes metadata from environment
    const podName = process.env.K8S_POD_NAME || 'unknown';
    const podNamespace = process.env.K8S_POD_NAMESPACE || 'default';
    const nodeName = process.env.K8S_NODE_NAME || 'unknown';
    const serviceName = process.env.SERVICE_NAME || 'horizon-service';

    const resource = new Resource({
      [SemanticResourceAttributes.SERVICE_NAME]: serviceName,
      [SemanticResourceAttributes.SERVICE_VERSION]: process.env.SERVICE_VERSION || '1.0.0',
      [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: process.env.NODE_ENV || 'development',
      [SemanticResourceAttributes.K8S_POD_NAME]: podName,
      [SemanticResourceAttributes.K8S_NAMESPACE_NAME]: podNamespace,
      [SemanticResourceAttributes.K8S_NODE_NAME]: nodeName,
      [SemanticResourceAttributes.K8S_CLUSTER_NAME]: 'horizon-test-gke',
      [SemanticResourceAttributes.CLOUD_PROVIDER]: 'gcp',
      [SemanticResourceAttributes.CLOUD_PLATFORM]: 'gcp_kubernetes_engine',
    });

    const traceExporter = new OTLPTraceExporter({
      url: process.env.ELASTIC_APM_SERVER_URL,
      headers: {
        'Authorization': `Bearer ${process.env.ELASTIC_APM_SECRET_TOKEN}`,
      },
    });

    const metricExporter = new OTLPMetricExporter({
      url: process.env.ELASTIC_APM_SERVER_URL,
      headers: {
        'Authorization': `Bearer ${process.env.ELASTIC_APM_SECRET_TOKEN}`,
      },
    });

    const sdk = new NodeSDK({
      resource,
      traceExporter,
      metricReader: new PeriodicExportingMetricReader({
        exporter: metricExporter,
        exportIntervalMillis: 30000,
      }),
    });

    sdk.start();

    // Kubernetes-specific metrics
    const { metrics } = require('@opentelemetry/api');
    const meter = metrics.getMeter('k8s-pod-metrics', '1.0.0');

    const podRestartCounter = meter.createCounter('k8s_pod_restarts_total', {
      description: 'Total number of pod restarts',
    });

    const podMemoryUsage = meter.createUpDownCounter('k8s_pod_memory_usage_bytes', {
      description: 'Pod memory usage in bytes',
    });

    const podCpuUsage = meter.createUpDownCounter('k8s_pod_cpu_usage_cores', {
      description: 'Pod CPU usage in cores',
    });

    // Collect pod metrics periodically
    setInterval(async () => {
      try {
        const memUsage = process.memoryUsage();
        const cpuUsage = process.cpuUsage();

        podMemoryUsage.add(memUsage.rss, {
          pod_name: podName,
          namespace: podNamespace,
          node_name: nodeName,
        });

        podCpuUsage.add(cpuUsage.user + cpuUsage.system, {
          pod_name: podName,
          namespace: podNamespace,
          node_name: nodeName,
        });
      } catch (error) {
        console.error('Error collecting pod metrics:', error);
      }
    }, 30000);

    module.exports = { sdk };
```

## Python AI Services Instrumentation

### 1. Python OpenTelemetry Setup
```python
# src/observability/instrumentation.py
from opentelemetry import trace, metrics
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.sdk.resources import Resource
from opentelemetry.semconv.resource import ResourceAttributes
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor
from opentelemetry.instrumentation.redis import RedisInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
import os
import logging

logger = logging.getLogger(__name__)

def setup_telemetry(service_name: str, service_version: str = "1.0.0"):
    """Initialize OpenTelemetry for Python AI services."""

    # Resource configuration
    resource = Resource.create({
        ResourceAttributes.SERVICE_NAME: service_name,
        ResourceAttributes.SERVICE_VERSION: service_version,
        ResourceAttributes.DEPLOYMENT_ENVIRONMENT: os.getenv("ENVIRONMENT", "development"),
        ResourceAttributes.SERVICE_NAMESPACE: "horizon-ai",
        ResourceAttributes.SERVICE_INSTANCE_ID: os.getenv("HOSTNAME", "unknown"),
    })

    # Trace provider setup
    trace_provider = TracerProvider(resource=resource)
    trace.set_tracer_provider(trace_provider)

    # OTLP trace exporter for Elastic Cloud
    otlp_trace_exporter = OTLPSpanExporter(
        endpoint=os.getenv("ELASTIC_APM_SERVER_URL", "http://localhost:4317"),
        headers={"Authorization": f"Bearer {os.getenv('ELASTIC_APM_SECRET_TOKEN')}"},
        insecure=os.getenv("ENVIRONMENT") == "development"
    )

    span_processor = BatchSpanProcessor(otlp_trace_exporter)
    trace_provider.add_span_processor(span_processor)

    # Metrics provider setup
    otlp_metric_exporter = OTLPMetricExporter(
        endpoint=os.getenv("ELASTIC_APM_SERVER_URL", "http://localhost:4317"),
        headers={"Authorization": f"Bearer {os.getenv('ELASTIC_APM_SECRET_TOKEN')}"},
        insecure=os.getenv("ENVIRONMENT") == "development"
    )

    metric_reader = PeriodicExportingMetricReader(
        exporter=otlp_metric_exporter,
        export_interval_millis=30000  # 30 seconds
    )

    metrics_provider = MeterProvider(
        resource=resource,
        metric_readers=[metric_reader]
    )
    metrics.set_meter_provider(metrics_provider)

    # Auto-instrumentation
    FastAPIInstrumentor.instrument()
    HTTPXClientInstrumentor.instrument()
    RedisInstrumentor.instrument()
    SQLAlchemyInstrumentor.instrument()

    logger.info(f"OpenTelemetry initialized for service: {service_name}")
```

### 2. AI-Specific Instrumentation
```python
# src/observability/ai_instrumentation.py
from opentelemetry import trace, metrics
from opentelemetry.trace import Status, StatusCode
from functools import wraps
from typing import Dict, Any, Optional, Callable
import time
import logging

logger = logging.getLogger(__name__)
tracer = trace.get_tracer(__name__)
meter = metrics.get_meter(__name__)

# AI-specific metrics
llm_request_counter = meter.create_counter(
    "ai_llm_requests_total",
    description="Total number of LLM requests",
    unit="1"
)

llm_request_duration = meter.create_histogram(
    "ai_llm_request_duration_seconds",
    description="Duration of LLM requests",
    unit="s"
)

llm_token_usage = meter.create_histogram(
    "ai_llm_tokens_used",
    description="Number of tokens used in LLM requests",
    unit="1"
)

agent_execution_counter = meter.create_counter(
    "ai_agent_executions_total",
    description="Total number of agent executions",
    unit="1"
)

agent_execution_duration = meter.create_histogram(
    "ai_agent_execution_duration_seconds",
    description="Duration of agent executions",
    unit="s"
)

def trace_llm_call(model_name: str, operation: str = "generate"):
    """Decorator for tracing LLM API calls."""
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def wrapper(*args, **kwargs):
            with tracer.start_as_current_span(f"llm.{operation}") as span:
                start_time = time.time()

                # Set span attributes
                span.set_attribute("ai.model.name", model_name)
                span.set_attribute("ai.operation", operation)
                span.set_attribute("ai.provider", "google_cloud")

                try:
                    result = await func(*args, **kwargs)

                    # Record success metrics
                    duration = time.time() - start_time
                    llm_request_counter.add(1, {
                        "model": model_name,
                        "operation": operation,
                        "status": "success"
                    })
                    llm_request_duration.record(duration, {
                        "model": model_name,
                        "operation": operation
                    })

                    # Extract token usage if available
                    if hasattr(result, 'usage_metadata'):
                        input_tokens = getattr(result.usage_metadata, 'prompt_token_count', 0)
                        output_tokens = getattr(result.usage_metadata, 'candidates_token_count', 0)

                        span.set_attribute("ai.tokens.input", input_tokens)
                        span.set_attribute("ai.tokens.output", output_tokens)
                        span.set_attribute("ai.tokens.total", input_tokens + output_tokens)

                        llm_token_usage.record(input_tokens + output_tokens, {
                            "model": model_name,
                            "token_type": "total"
                        })

                    span.set_status(Status(StatusCode.OK))
                    return result

                except Exception as e:
                    # Record error metrics
                    llm_request_counter.add(1, {
                        "model": model_name,
                        "operation": operation,
                        "status": "error"
                    })

                    span.record_exception(e)
                    span.set_status(Status(StatusCode.ERROR, str(e)))
                    logger.error(f"LLM call failed: {e}")
                    raise

        return wrapper
    return decorator

def trace_agent_execution(agent_name: str):
    """Decorator for tracing agent executions."""
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def wrapper(*args, **kwargs):
            with tracer.start_as_current_span(f"agent.{agent_name}") as span:
                start_time = time.time()

                # Set span attributes
                span.set_attribute("ai.agent.name", agent_name)
                span.set_attribute("ai.agent.type", "langchain")

                try:
                    result = await func(*args, **kwargs)

                    # Record success metrics
                    duration = time.time() - start_time
                    agent_execution_counter.add(1, {
                        "agent": agent_name,
                        "status": "success"
                    })
                    agent_execution_duration.record(duration, {
                        "agent": agent_name
                    })

                    # Add result metadata
                    if isinstance(result, dict) and 'output' in result:
                        span.set_attribute("ai.agent.output_length", len(str(result['output'])))

                    span.set_status(Status(StatusCode.OK))
                    return result

                except Exception as e:
                    # Record error metrics
                    agent_execution_counter.add(1, {
                        "agent": agent_name,
                        "status": "error"
                    })

                    span.record_exception(e)
                    span.set_status(Status(StatusCode.ERROR, str(e)))
                    logger.error(f"Agent execution failed: {e}")
                    raise

        return wrapper
    return decorator

class AIMetrics:
    """Centralized AI metrics collection."""

    @staticmethod
    def record_rag_query(
        query_type: str,
        documents_retrieved: int,
        relevance_score: float,
        duration: float
    ):
        """Record RAG query metrics."""
        rag_query_counter = meter.create_counter(
            "ai_rag_queries_total",
            description="Total RAG queries processed"
        )

        rag_documents_retrieved = meter.create_histogram(
            "ai_rag_documents_retrieved",
            description="Number of documents retrieved for RAG"
        )

        rag_relevance_score = meter.create_histogram(
            "ai_rag_relevance_score",
            description="RAG relevance scores"
        )

        rag_query_counter.add(1, {"query_type": query_type})
        rag_documents_retrieved.record(documents_retrieved, {"query_type": query_type})
        rag_relevance_score.record(relevance_score, {"query_type": query_type})

    @staticmethod
    def record_vector_search(
        collection_name: str,
        query_vector_size: int,
        results_count: int,
        search_duration: float
    ):
        """Record vector search metrics."""
        vector_search_counter = meter.create_counter(
            "ai_vector_searches_total",
            description="Total vector searches performed"
        )

        vector_search_duration = meter.create_histogram(
            "ai_vector_search_duration_seconds",
            description="Vector search duration"
        )

        vector_search_counter.add(1, {"collection": collection_name})
        vector_search_duration.record(search_duration, {"collection": collection_name})
```

### 3. FastAPI Integration with AI Tracing
```python
# src/api/middleware/telemetry.py
from fastapi import FastAPI, Request, Response
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.propagate import extract
import time
import logging

logger = logging.getLogger(__name__)
tracer = trace.get_tracer(__name__)

def setup_fastapi_telemetry(app: FastAPI):
    """Setup FastAPI-specific telemetry."""

    @app.middleware("http")
    async def telemetry_middleware(request: Request, call_next):
        """Custom telemetry middleware for AI-specific tracking."""

        # Extract trace context from headers
        context = extract(request.headers)

        with tracer.start_as_current_span(
            f"{request.method} {request.url.path}",
            context=context
        ) as span:
            start_time = time.time()

            # Set request attributes
            span.set_attribute("http.method", request.method)
            span.set_attribute("http.url", str(request.url))
            span.set_attribute("http.user_agent", request.headers.get("user-agent", ""))

            # Add AI-specific attributes
            if "ai" in request.url.path or "agent" in request.url.path:
                span.set_attribute("service.type", "ai")
                span.set_attribute("ai.request.type", "api")

            try:
                response = await call_next(request)

                # Set response attributes
                span.set_attribute("http.status_code", response.status_code)
                span.set_attribute("http.response_time", time.time() - start_time)

                return response

            except Exception as e:
                span.record_exception(e)
                span.set_status(trace.Status(trace.StatusCode.ERROR, str(e)))
                logger.error(f"Request failed: {e}")
                raise

    # Instrument FastAPI
    FastAPIInstrumentor.instrument_app(app)
```

## Go Language Instrumentation

### 1. Go Service Instrumentation Setup
```go
// libs/go-services/pkg/telemetry/instrumentation.go
package telemetry

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetrichttp"
	"go.opentelemetry.io/otel/metric"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/resource"
	"go.opentelemetry.io/otel/sdk/metric"
	"go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.17.0"
	"go.opentelemetry.io/otel/trace"
)

type TelemetryConfig struct {
	ServiceName    string
	ServiceVersion string
	Environment    string
	ElasticAPMURL  string
	ElasticToken   string
}

type TelemetryService struct {
	tracer   trace.Tracer
	meter    metric.Meter
	config   TelemetryConfig
	shutdown func(context.Context) error
}

func NewTelemetryService(config TelemetryConfig) (*TelemetryService, error) {
	// Create resource
	res, err := resource.Merge(
		resource.Default(),
		resource.NewWithAttributes(
			semconv.SchemaURL,
			semconv.ServiceName(config.ServiceName),
			semconv.ServiceVersion(config.ServiceVersion),
			semconv.DeploymentEnvironment(config.Environment),
			attribute.String("service.namespace", "horizon"),
		),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create resource: %w", err)
	}

	// Set up trace exporter
	traceExporter, err := otlptracehttp.New(
		context.Background(),
		otlptracehttp.WithEndpoint(config.ElasticAPMURL),
		otlptracehttp.WithHeaders(map[string]string{
			"Authorization": fmt.Sprintf("Bearer %s", config.ElasticToken),
		}),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create trace exporter: %w", err)
	}

	// Set up trace provider
	traceProvider := trace.NewTracerProvider(
		trace.WithBatcher(traceExporter),
		trace.WithResource(res),
		trace.WithSampler(trace.AlwaysSample()),
	)
	otel.SetTracerProvider(traceProvider)

	// Set up metric exporter
	metricExporter, err := otlpmetrichttp.New(
		context.Background(),
		otlpmetrichttp.WithEndpoint(config.ElasticAPMURL),
		otlpmetrichttp.WithHeaders(map[string]string{
			"Authorization": fmt.Sprintf("Bearer %s", config.ElasticToken),
		}),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create metric exporter: %w", err)
	}

	// Set up metric provider
	metricProvider := metric.NewMeterProvider(
		metric.WithReader(metric.NewPeriodicReader(
			metricExporter,
			metric.WithInterval(30*time.Second),
		)),
		metric.WithResource(res),
	)
	otel.SetMeterProvider(metricProvider)

	// Set up propagator
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(
		propagation.TraceContext{},
		propagation.Baggage{},
	))

	tracer := otel.Tracer(config.ServiceName)
	meter := otel.Meter(config.ServiceName)

	shutdown := func(ctx context.Context) error {
		if err := traceProvider.Shutdown(ctx); err != nil {
			return err
		}
		return metricProvider.Shutdown(ctx)
	}

	return &TelemetryService{
		tracer:   tracer,
		meter:    meter,
		config:   config,
		shutdown: shutdown,
	}, nil
}

func (ts *TelemetryService) Tracer() trace.Tracer {
	return ts.tracer
}

func (ts *TelemetryService) Meter() metric.Meter {
	return ts.meter
}

func (ts *TelemetryService) Shutdown(ctx context.Context) error {
	return ts.shutdown(ctx)
}

// Initialize telemetry from environment variables
func InitFromEnv() (*TelemetryService, error) {
	config := TelemetryConfig{
		ServiceName:    getEnvOrDefault("SERVICE_NAME", "go-service"),
		ServiceVersion: getEnvOrDefault("SERVICE_VERSION", "1.0.0"),
		Environment:    getEnvOrDefault("NODE_ENV", "development"),
		ElasticAPMURL:  getEnvOrDefault("ELASTIC_APM_SERVER_URL", ""),
		ElasticToken:   getEnvOrDefault("ELASTIC_APM_SECRET_TOKEN", ""),
	}

	if config.ElasticAPMURL == "" || config.ElasticToken == "" {
		return nil, fmt.Errorf("ELASTIC_APM_SERVER_URL and ELASTIC_APM_SECRET_TOKEN must be set")
	}

	return NewTelemetryService(config)
}

func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
```

### 2. Go HTTP Server Instrumentation
```go
// libs/go-services/pkg/telemetry/http.go
package telemetry

import (
	"context"
	"net/http"
	"strconv"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/metric"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.17.0"
)

type HTTPMetrics struct {
	requestDuration metric.Float64Histogram
	requestCounter  metric.Int64Counter
	activeRequests  metric.Int64UpDownCounter
}

func NewHTTPMetrics(meter metric.Meter) (*HTTPMetrics, error) {
	requestDuration, err := meter.Float64Histogram(
		"http_request_duration_seconds",
		metric.WithDescription("HTTP request duration in seconds"),
		metric.WithUnit("s"),
	)
	if err != nil {
		return nil, err
	}

	requestCounter, err := meter.Int64Counter(
		"http_requests_total",
		metric.WithDescription("Total number of HTTP requests"),
	)
	if err != nil {
		return nil, err
	}

	activeRequests, err := meter.Int64UpDownCounter(
		"http_requests_active",
		metric.WithDescription("Number of active HTTP requests"),
	)
	if err != nil {
		return nil, err
	}

	return &HTTPMetrics{
		requestDuration: requestDuration,
		requestCounter:  requestCounter,
		activeRequests:  activeRequests,
	}, nil
}

// HTTPMiddleware provides OpenTelemetry instrumentation for HTTP handlers
func HTTPMiddleware(serviceName string, metrics *HTTPMetrics) func(http.Handler) http.Handler {
	tracer := otel.Tracer(serviceName)

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Extract context from headers
			ctx := otel.GetTextMapPropagator().Extract(r.Context(), propagation.HeaderCarrier(r.Header))

			// Start span
			ctx, span := tracer.Start(ctx, r.Method+" "+r.URL.Path,
				trace.WithAttributes(
					semconv.HTTPMethod(r.Method),
					semconv.HTTPTarget(r.URL.Path),
					semconv.HTTPScheme(r.URL.Scheme),
					semconv.HTTPHost(r.Host),
					semconv.HTTPUserAgent(r.UserAgent()),
					semconv.HTTPClientIP(getClientIP(r)),
				),
				trace.WithSpanKind(trace.SpanKindServer),
			)
			defer span.End()

			// Update active requests
			if metrics != nil {
				metrics.activeRequests.Add(ctx, 1, metric.WithAttributes(
					attribute.String("method", r.Method),
					attribute.String("route", r.URL.Path),
				))
				defer metrics.activeRequests.Add(ctx, -1, metric.WithAttributes(
					attribute.String("method", r.Method),
					attribute.String("route", r.URL.Path),
				))
			}

			// Wrap response writer to capture status code
			wrapped := &responseWriter{ResponseWriter: w, statusCode: 200}

			start := time.Now()

			// Call next handler
			next.ServeHTTP(wrapped, r.WithContext(ctx))

			duration := time.Since(start)

			// Set span attributes
			span.SetAttributes(
				semconv.HTTPStatusCode(wrapped.statusCode),
				attribute.Float64("http.request.duration", duration.Seconds()),
			)

			// Record metrics
			if metrics != nil {
				attrs := metric.WithAttributes(
					attribute.String("method", r.Method),
					attribute.String("route", r.URL.Path),
					attribute.String("status_code", strconv.Itoa(wrapped.statusCode)),
				)

				metrics.requestCounter.Add(ctx, 1, attrs)
				metrics.requestDuration.Record(ctx, duration.Seconds(), attrs)
			}

			// Set span status based on HTTP status code
			if wrapped.statusCode >= 400 {
				span.SetAttributes(attribute.String("error", "true"))
				if wrapped.statusCode >= 500 {
					span.RecordError(fmt.Errorf("HTTP %d", wrapped.statusCode))
				}
			}
		})
	}
}

type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

func getClientIP(r *http.Request) string {
	// Check X-Forwarded-For header
	if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
		return xff
	}
	// Check X-Real-IP header
	if xri := r.Header.Get("X-Real-IP"); xri != "" {
		return xri
	}
	// Fall back to RemoteAddr
	return r.RemoteAddr
}
```

### 3. Go Database Instrumentation
```go
// libs/go-services/pkg/telemetry/database.go
package telemetry

import (
	"context"
	"database/sql"
	"database/sql/driver"
	"fmt"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/metric"
	"go.opentelemetry.io/otel/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.17.0"
)

type DatabaseMetrics struct {
	queryDuration   metric.Float64Histogram
	queryCounter    metric.Int64Counter
	connectionPool  metric.Int64UpDownCounter
	transactionDuration metric.Float64Histogram
}

func NewDatabaseMetrics(meter metric.Meter) (*DatabaseMetrics, error) {
	queryDuration, err := meter.Float64Histogram(
		"db_query_duration_seconds",
		metric.WithDescription("Database query duration in seconds"),
		metric.WithUnit("s"),
	)
	if err != nil {
		return nil, err
	}

	queryCounter, err := meter.Int64Counter(
		"db_queries_total",
		metric.WithDescription("Total number of database queries"),
	)
	if err != nil {
		return nil, err
	}

	connectionPool, err := meter.Int64UpDownCounter(
		"db_connections_active",
		metric.WithDescription("Number of active database connections"),
	)
	if err != nil {
		return nil, err
	}

	transactionDuration, err := meter.Float64Histogram(
		"db_transaction_duration_seconds",
		metric.WithDescription("Database transaction duration in seconds"),
		metric.WithUnit("s"),
	)
	if err != nil {
		return nil, err
	}

	return &DatabaseMetrics{
		queryDuration:       queryDuration,
		queryCounter:        queryCounter,
		connectionPool:      connectionPool,
		transactionDuration: transactionDuration,
	}, nil
}

// InstrumentedDB wraps sql.DB with OpenTelemetry instrumentation
type InstrumentedDB struct {
	*sql.DB
	tracer  trace.Tracer
	metrics *DatabaseMetrics
	dbName  string
}

func NewInstrumentedDB(db *sql.DB, dbName string, metrics *DatabaseMetrics) *InstrumentedDB {
	return &InstrumentedDB{
		DB:      db,
		tracer:  otel.Tracer("database"),
		metrics: metrics,
		dbName:  dbName,
	}
}

func (db *InstrumentedDB) QueryContext(ctx context.Context, query string, args ...interface{}) (*sql.Rows, error) {
	ctx, span := db.tracer.Start(ctx, "db.query",
		trace.WithAttributes(
			semconv.DBSystem("postgresql"),
			semconv.DBName(db.dbName),
			semconv.DBStatement(query),
			semconv.DBOperation(extractOperation(query)),
		),
	)
	defer span.End()

	start := time.Now()
	rows, err := db.DB.QueryContext(ctx, query, args...)
	duration := time.Since(start)

	// Record metrics
	if db.metrics != nil {
		attrs := metric.WithAttributes(
			attribute.String("db.system", "postgresql"),
			attribute.String("db.name", db.dbName),
			attribute.String("db.operation", extractOperation(query)),
			attribute.String("status", getStatus(err)),
		)
		db.metrics.queryCounter.Add(ctx, 1, attrs)
		db.metrics.queryDuration.Record(ctx, duration.Seconds(), attrs)
	}

	// Set span attributes and status
	span.SetAttributes(
		attribute.Float64("db.query.duration", duration.Seconds()),
	)

	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
	} else {
		span.SetStatus(codes.Ok, "")
	}

	return rows, err
}

func (db *InstrumentedDB) ExecContext(ctx context.Context, query string, args ...interface{}) (sql.Result, error) {
	ctx, span := db.tracer.Start(ctx, "db.exec",
		trace.WithAttributes(
			semconv.DBSystem("postgresql"),
			semconv.DBName(db.dbName),
			semconv.DBStatement(query),
			semconv.DBOperation(extractOperation(query)),
		),
	)
	defer span.End()

	start := time.Now()
	result, err := db.DB.ExecContext(ctx, query, args...)
	duration := time.Since(start)

	// Record metrics
	if db.metrics != nil {
		attrs := metric.WithAttributes(
			attribute.String("db.system", "postgresql"),
			attribute.String("db.name", db.dbName),
			attribute.String("db.operation", extractOperation(query)),
			attribute.String("status", getStatus(err)),
		)
		db.metrics.queryCounter.Add(ctx, 1, attrs)
		db.metrics.queryDuration.Record(ctx, duration.Seconds(), attrs)
	}

	// Set span attributes
	span.SetAttributes(
		attribute.Float64("db.query.duration", duration.Seconds()),
	)

	if result != nil {
		if rowsAffected, err := result.RowsAffected(); err == nil {
			span.SetAttributes(attribute.Int64("db.rows_affected", rowsAffected))
		}
	}

	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, err.Error())
	} else {
		span.SetStatus(codes.Ok, "")
	}

	return result, err
}

func extractOperation(query string) string {
	// Simple operation extraction - could be enhanced
	query = strings.TrimSpace(strings.ToUpper(query))
	if strings.HasPrefix(query, "SELECT") {
		return "SELECT"
	} else if strings.HasPrefix(query, "INSERT") {
		return "INSERT"
	} else if strings.HasPrefix(query, "UPDATE") {
		return "UPDATE"
	} else if strings.HasPrefix(query, "DELETE") {
		return "DELETE"
	}
	return "OTHER"
}

func getStatus(err error) string {
	if err != nil {
		return "error"
	}
	return "success"
}
```

### 4. Go Service Example with Full Instrumentation
```go
// apps/go-payment-service/main.go
package main

import (
	"context"
	"database/sql"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	_ "github.com/lib/pq"
	"horizon/libs/go-services/pkg/telemetry"
)

func main() {
	// Initialize telemetry
	ts, err := telemetry.InitFromEnv()
	if err != nil {
		log.Fatalf("Failed to initialize telemetry: %v", err)
	}
	defer ts.Shutdown(context.Background())

	// Initialize database
	db, err := sql.Open("postgres", os.Getenv("DATABASE_URL"))
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Create database metrics
	dbMetrics, err := telemetry.NewDatabaseMetrics(ts.Meter())
	if err != nil {
		log.Fatalf("Failed to create database metrics: %v", err)
	}

	// Wrap database with instrumentation
	instrumentedDB := telemetry.NewInstrumentedDB(db, "horizon_payments", dbMetrics)

	// Create HTTP metrics
	httpMetrics, err := telemetry.NewHTTPMetrics(ts.Meter())
	if err != nil {
		log.Fatalf("Failed to create HTTP metrics: %v", err)
	}

	// Set up HTTP server with instrumentation
	mux := http.NewServeMux()
	mux.HandleFunc("/health", healthHandler)
	mux.HandleFunc("/payments", paymentsHandler(instrumentedDB))

	// Apply telemetry middleware
	handler := telemetry.HTTPMiddleware("go-payment-service", httpMetrics)(mux)

	server := &http.Server{
		Addr:    ":8080",
		Handler: handler,
	}

	// Start server
	go func() {
		log.Println("Starting server on :8080")
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server failed: %v", err)
		}
	}()

	// Wait for interrupt signal
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
	<-c

	// Graceful shutdown
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Printf("Server shutdown error: %v", err)
	}

	log.Println("Server stopped")
}
```

## Elastic Cloud Integration Patterns

### 1. Centralized Configuration for Elastic Cloud
```typescript
// libs/shared/utils/src/telemetry/elastic-config.ts
export interface ElasticCloudConfig {
  apmServerUrl: string;
  apmSecretToken: string;
  elasticsearchEndpoint: string;
  elasticsearchApiKey: string;
  kibanaEndpoint: string;
  environment: string;
  serviceName: string;
  serviceVersion: string;
}

export function getElasticCloudConfig(): ElasticCloudConfig {
  const config: ElasticCloudConfig = {
    apmServerUrl: process.env.ELASTIC_APM_SERVER_URL || '',
    apmSecretToken: process.env.ELASTIC_APM_SECRET_TOKEN || '',
    elasticsearchEndpoint: process.env.ELASTIC_CLOUD_ENDPOINT || '',
    elasticsearchApiKey: process.env.ELASTIC_CLOUD_API_KEY || '',
    kibanaEndpoint: process.env.KIBANA_ENDPOINT || '',
    environment: process.env.NODE_ENV || 'development',
    serviceName: process.env.SERVICE_NAME || 'horizon-service',
    serviceVersion: process.env.SERVICE_VERSION || '1.0.0',
  };

  // Validate required configuration
  const requiredFields = ['apmServerUrl', 'apmSecretToken', 'elasticsearchEndpoint', 'elasticsearchApiKey'];
  const missingFields = requiredFields.filter(field => !config[field as keyof ElasticCloudConfig]);

  if (missingFields.length > 0) {
    throw new Error(`Missing required Elastic Cloud configuration: ${missingFields.join(', ')}`);
  }

  return config;
}

export function createElasticCloudExporters(config: ElasticCloudConfig) {
  return {
    traces: {
      url: `${config.apmServerUrl}/intake/v2/events`,
      headers: {
        'Authorization': `Bearer ${config.apmSecretToken}`,
        'Content-Type': 'application/x-ndjson',
      },
    },
    metrics: {
      url: `${config.elasticsearchEndpoint}/_bulk`,
      headers: {
        'Authorization': `ApiKey ${config.elasticsearchApiKey}`,
        'Content-Type': 'application/x-ndjson',
      },
    },
    logs: {
      url: `${config.elasticsearchEndpoint}/_bulk`,
      headers: {
        'Authorization': `ApiKey ${config.elasticsearchApiKey}`,
        'Content-Type': 'application/x-ndjson',
      },
    },
  };
}
```

### 2. Kubernetes Secret Management for Elastic Cloud
```yaml
# k8s/observability/elastic-cloud-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: elastic-cloud-credentials
  namespace: observability
type: Opaque
data:
  # Base64 encoded values
  endpoint: <base64-encoded-elasticsearch-endpoint>
  api-key: <base64-encoded-api-key>

---
apiVersion: v1
kind: Secret
metadata:
  name: elastic-apm-credentials
  namespace: observability
type: Opaque
data:
  # Base64 encoded values
  endpoint: <base64-encoded-apm-server-url>
  secret-token: <base64-encoded-secret-token>

---
apiVersion: v1
kind: Secret
metadata:
  name: kibana-credentials
  namespace: observability
type: Opaque
data:
  # Base64 encoded values
  endpoint: <base64-encoded-kibana-endpoint>
  username: <base64-encoded-username>
  password: <base64-encoded-password>
```

### 3. Terraform Configuration for Elastic Cloud Resources
```hcl
# terraform/modules/elastic-cloud/main.tf
terraform {
  required_providers {
    ec = {
      source  = "elastic/ec"
      version = "~> 0.9.0"
    }
  }
  cloud {
    organization = "horizon-org"
    workspaces {
      name = "horizon-elastic-cloud"
    }
  }
}

provider "ec" {
  apikey = var.elastic_cloud_api_key
}

# Elastic Cloud deployment
resource "ec_deployment" "horizon" {
  name                   = "horizon-${var.environment}"
  version                = var.elastic_stack_version
  region                 = var.elastic_cloud_region
  deployment_template_id = "gcp-general-purpose"

  elasticsearch {
    hot = {
      size       = var.elasticsearch_size
      zone_count = var.elasticsearch_zones
    }

    config = {
      user_settings_yaml = yamlencode({
        action = {
          destructive_requires_name = true
        }
        cluster = {
          routing = {
            allocation = {
              disk = {
                watermark = {
                  low  = "85%"
                  high = "90%"
                }
              }
            }
          }
        }
        indices = {
          lifecycle = {
            poll_interval = "1m"
          }
        }
      })
    }
  }

  kibana {
    size       = var.kibana_size
    zone_count = 1

    config = {
      user_settings_yaml = yamlencode({
        server = {
          maxPayloadBytes = 1048576
        }
        elasticsearch = {
          requestTimeout = 60000
        }
      })
    }
  }

  apm {
    size       = var.apm_size
    zone_count = 1

    config = {
      user_settings_yaml = yamlencode({
        apm-server = {
          rum = {
            enabled = true
          }
          capture_personal_data = false
        }
      })
    }
  }

  tags = merge(var.common_tags, {
    Environment = var.environment
    Service     = "observability"
  })
}

# Index lifecycle policies
resource "ec_deployment_extension" "ilm_policies" {
  deployment_id = ec_deployment.horizon.id
  name          = "horizon-ilm-policies"
  extension_type = "bundle"
  version       = "*"

  config = jsonencode({
    policies = {
      "horizon-logs-policy" = {
        policy = {
          phases = {
            hot = {
              actions = {
                rollover = {
                  max_size = "50gb"
                  max_age  = "7d"
                }
              }
            }
            warm = {
              min_age = "7d"
              actions = {
                allocate = {
                  number_of_replicas = 0
                }
              }
            }
            cold = {
              min_age = "30d"
              actions = {
                allocate = {
                  number_of_replicas = 0
                }
              }
            }
            delete = {
              min_age = "90d"
            }
          }
        }
      }
      "horizon-metrics-policy" = {
        policy = {
          phases = {
            hot = {
              actions = {
                rollover = {
                  max_size = "30gb"
                  max_age  = "3d"
                }
              }
            }
            warm = {
              min_age = "3d"
              actions = {
                allocate = {
                  number_of_replicas = 0
                }
              }
            }
            delete = {
              min_age = "30d"
            }
          }
        }
      }
      "horizon-traces-policy" = {
        policy = {
          phases = {
            hot = {
              actions = {
                rollover = {
                  max_size = "10gb"
                  max_age  = "1d"
                }
              }
            }
            delete = {
              min_age = "7d"
            }
          }
        }
      }
    }
  })
}

# Index templates
resource "ec_deployment_extension" "index_templates" {
  deployment_id = ec_deployment.horizon.id
  name          = "horizon-index-templates"
  extension_type = "bundle"
  version       = "*"

  config = jsonencode({
    index_templates = {
      "horizon-logs" = {
        index_patterns = ["logs-horizon-*"]
        template = {
          settings = {
            number_of_shards   = 1
            number_of_replicas = 1
            "index.lifecycle.name" = "horizon-logs-policy"
            "index.lifecycle.rollover_alias" = "logs-horizon"
          }
          mappings = {
            properties = {
              "@timestamp" = {
                type = "date"
              }
              "service.name" = {
                type = "keyword"
              }
              "service.version" = {
                type = "keyword"
              }
              "log.level" = {
                type = "keyword"
              }
              "message" = {
                type = "text"
                analyzer = "standard"
              }
              "trace.id" = {
                type = "keyword"
              }
              "span.id" = {
                type = "keyword"
              }
            }
          }
        }
      }
      "horizon-metrics" = {
        index_patterns = ["metrics-horizon-*"]
        template = {
          settings = {
            number_of_shards   = 1
            number_of_replicas = 1
            "index.lifecycle.name" = "horizon-metrics-policy"
            "index.lifecycle.rollover_alias" = "metrics-horizon"
          }
          mappings = {
            properties = {
              "@timestamp" = {
                type = "date"
              }
              "service.name" = {
                type = "keyword"
              }
              "metric.name" = {
                type = "keyword"
              }
              "metric.value" = {
                type = "double"
              }
              "metric.type" = {
                type = "keyword"
              }
            }
          }
        }
      }
      "horizon-traces" = {
        index_patterns = ["traces-horizon-*"]
        template = {
          settings = {
            number_of_shards   = 1
            number_of_replicas = 1
            "index.lifecycle.name" = "horizon-traces-policy"
            "index.lifecycle.rollover_alias" = "traces-horizon"
          }
          mappings = {
            properties = {
              "@timestamp" = {
                type = "date"
              }
              "trace.id" = {
                type = "keyword"
              }
              "span.id" = {
                type = "keyword"
              }
              "parent.id" = {
                type = "keyword"
              }
              "service.name" = {
                type = "keyword"
              }
              "operation.name" = {
                type = "keyword"
              }
              "duration" = {
                type = "long"
              }
            }
          }
        }
      }
    }
  })
}

# Outputs
output "elasticsearch_endpoint" {
  value = ec_deployment.horizon.elasticsearch[0].https_endpoint
  sensitive = true
}

output "kibana_endpoint" {
  value = ec_deployment.horizon.kibana[0].https_endpoint
  sensitive = true
}

output "apm_endpoint" {
  value = ec_deployment.horizon.apm[0].https_endpoint
  sensitive = true
}

output "apm_secret_token" {
  value = ec_deployment.horizon.apm_secret_token
  sensitive = true
}

output "elasticsearch_username" {
  value = ec_deployment.horizon.elasticsearch_username
  sensitive = true
}

output "elasticsearch_password" {
  value = ec_deployment.horizon.elasticsearch_password
  sensitive = true
}
```

This comprehensive template now includes all the requested expansions: GitHub Actions CI/CD instrumentation, PostgreSQL database instrumentation, Kubernetes cluster and pod-level instrumentation, Go language examples, and complete Elastic Cloud integration patterns for centralized observability.
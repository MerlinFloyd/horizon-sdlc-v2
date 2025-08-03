# Comprehensive Design Patterns Template

## Overview
This template provides comprehensive design patterns following SOLID principles and architectural best practices. These patterns are essential for building maintainable, scalable applications within our NX monorepo structure.

## Repository Pattern

### Definition and Use Cases
The Repository pattern encapsulates data access logic and provides a uniform interface for accessing domain objects. It centralizes common data access functionality and promotes testability by separating infrastructure concerns.

### TypeScript/Node.js Implementation
```typescript
// libs/api/database/src/repositories/user.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { User, CreateUserDto, UpdateUserDto } from '@shared/types';

export interface IUserRepository {
  findById(id: string): Promise<User | null>;
  findByEmail(email: string): Promise<User | null>;
  create(userData: CreateUserDto): Promise<User>;
  update(id: string, userData: UpdateUserDto): Promise<User>;
  delete(id: string): Promise<void>;
  findAll(limit?: number, offset?: number): Promise<User[]>;
}

@Injectable()
export class UserRepository implements IUserRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findById(id: string): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { id },
      include: { profile: true }
    });
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { email },
      include: { profile: true }
    });
  }

  async create(userData: CreateUserDto): Promise<User> {
    return this.prisma.user.create({
      data: userData,
      include: { profile: true }
    });
  }

  async update(id: string, userData: UpdateUserDto): Promise<User> {
    return this.prisma.user.update({
      where: { id },
      data: userData,
      include: { profile: true }
    });
  }

  async delete(id: string): Promise<void> {
    await this.prisma.user.delete({
      where: { id }
    });
  }

  async findAll(limit = 50, offset = 0): Promise<User[]> {
    return this.prisma.user.findMany({
      take: limit,
      skip: offset,
      include: { profile: true },
      orderBy: { createdAt: 'desc' }
    });
  }
}
```

### Go Implementation Example
```go
// libs/api/database/repositories/user_repository.go
package repositories

import (
    "context"
    "database/sql"
    "github.com/horizon/shared/types"
)

type UserRepository interface {
    FindByID(ctx context.Context, id string) (*types.User, error)
    FindByEmail(ctx context.Context, email string) (*types.User, error)
    Create(ctx context.Context, user *types.CreateUserRequest) (*types.User, error)
    Update(ctx context.Context, id string, user *types.UpdateUserRequest) (*types.User, error)
    Delete(ctx context.Context, id string) error
    FindAll(ctx context.Context, limit, offset int) ([]*types.User, error)
}

type userRepository struct {
    db *sql.DB
}

func NewUserRepository(db *sql.DB) UserRepository {
    return &userRepository{db: db}
}

func (r *userRepository) FindByID(ctx context.Context, id string) (*types.User, error) {
    query := `SELECT id, email, name, created_at, updated_at FROM users WHERE id = $1`
    
    var user types.User
    err := r.db.QueryRowContext(ctx, query, id).Scan(
        &user.ID, &user.Email, &user.Name, &user.CreatedAt, &user.UpdatedAt,
    )
    
    if err == sql.ErrNoRows {
        return nil, nil
    }
    
    return &user, err
}
```

## Factory Pattern

### Definition and Use Cases
The Factory pattern creates objects without specifying their exact classes. It's useful for creating different implementations based on configuration or runtime conditions.

### TypeScript Implementation
```typescript
// libs/shared/utils/src/factories/database.factory.ts
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface DatabaseConnection {
  connect(): Promise<void>;
  disconnect(): Promise<void>;
  query(sql: string, params?: any[]): Promise<any>;
}

export class PostgreSQLConnection implements DatabaseConnection {
  constructor(private connectionString: string) {}
  
  async connect(): Promise<void> {
    // PostgreSQL connection logic
  }
  
  async disconnect(): Promise<void> {
    // PostgreSQL disconnection logic
  }
  
  async query(sql: string, params?: any[]): Promise<any> {
    // PostgreSQL query logic
  }
}

export class MongoDBConnection implements DatabaseConnection {
  constructor(private connectionString: string) {}
  
  async connect(): Promise<void> {
    // MongoDB connection logic
  }
  
  async disconnect(): Promise<void> {
    // MongoDB disconnection logic
  }
  
  async query(sql: string, params?: any[]): Promise<any> {
    // MongoDB query logic (adapted for NoSQL)
  }
}

@Injectable()
export class DatabaseFactory {
  constructor(private configService: ConfigService) {}
  
  createConnection(type: 'postgresql' | 'mongodb'): DatabaseConnection {
    const connectionString = this.configService.get(`${type.toUpperCase()}_URL`);
    
    switch (type) {
      case 'postgresql':
        return new PostgreSQLConnection(connectionString);
      case 'mongodb':
        return new MongoDBConnection(connectionString);
      default:
        throw new Error(`Unsupported database type: ${type}`);
    }
  }
}
```

## Builder Pattern

### Definition and Use Cases
The Builder pattern constructs complex objects step by step. It's particularly useful for objects with many optional parameters or complex initialization logic.

### TypeScript Implementation
```typescript
// libs/shared/utils/src/builders/api-response.builder.ts
export interface ApiResponse<T = any> {
  data?: T;
  message?: string;
  errors?: string[];
  meta?: {
    pagination?: {
      page: number;
      limit: number;
      total: number;
      totalPages: number;
    };
    timestamp: string;
    requestId: string;
  };
  status: 'success' | 'error' | 'warning';
}

export class ApiResponseBuilder<T = any> {
  private response: Partial<ApiResponse<T>> = {
    meta: {
      timestamp: new Date().toISOString(),
      requestId: this.generateRequestId()
    }
  };

  static success<T>(data?: T): ApiResponseBuilder<T> {
    return new ApiResponseBuilder<T>().setStatus('success').setData(data);
  }

  static error(message: string, errors?: string[]): ApiResponseBuilder {
    return new ApiResponseBuilder()
      .setStatus('error')
      .setMessage(message)
      .setErrors(errors);
  }

  setData(data: T): this {
    this.response.data = data;
    return this;
  }

  setMessage(message: string): this {
    this.response.message = message;
    return this;
  }

  setErrors(errors: string[]): this {
    this.response.errors = errors;
    return this;
  }

  setStatus(status: 'success' | 'error' | 'warning'): this {
    this.response.status = status;
    return this;
  }

  setPagination(page: number, limit: number, total: number): this {
    if (!this.response.meta) {
      this.response.meta = { timestamp: new Date().toISOString(), requestId: this.generateRequestId() };
    }
    
    this.response.meta.pagination = {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit)
    };
    return this;
  }

  setRequestId(requestId: string): this {
    if (!this.response.meta) {
      this.response.meta = { timestamp: new Date().toISOString(), requestId };
    } else {
      this.response.meta.requestId = requestId;
    }
    return this;
  }

  build(): ApiResponse<T> {
    if (!this.response.status) {
      throw new Error('Status is required for API response');
    }
    
    return this.response as ApiResponse<T>;
  }

  private generateRequestId(): string {
    return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}

// Usage examples:
// const successResponse = ApiResponseBuilder.success(userData).setMessage('User created successfully').build();
// const errorResponse = ApiResponseBuilder.error('Validation failed', ['Email is required']).build();
```

## Engine Pattern for Modular Architectures

### Definition and Use Cases
The Engine pattern provides a plugin-based architecture where modules can be dynamically loaded, configured, and managed. It's essential for building extensible systems that can be enhanced without modifying core functionality.

### TypeScript Implementation
```typescript
// libs/shared/utils/src/engine/module-engine.ts
export interface ModuleMetadata {
  name: string;
  version: string;
  description: string;
  dependencies?: string[];
  author?: string;
  tags?: string[];
}

export interface ModuleContext {
  config: Record<string, any>;
  logger: Logger;
  eventBus: EventBus;
  services: Map<string, any>;
}

export interface Module {
  metadata: ModuleMetadata;
  initialize(context: ModuleContext): Promise<void>;
  start(): Promise<void>;
  stop(): Promise<void>;
  destroy(): Promise<void>;
  getExports?(): Record<string, any>;
}

export interface ModuleConfig {
  enabled: boolean;
  config: Record<string, any>;
  loadOrder?: number;
}

export class ModuleEngine {
  private modules = new Map<string, Module>();
  private moduleConfigs = new Map<string, ModuleConfig>();
  private moduleInstances = new Map<string, any>();
  private dependencyGraph = new Map<string, string[]>();
  private eventBus: EventBus;
  private logger: Logger;

  constructor(eventBus: EventBus, logger: Logger) {
    this.eventBus = eventBus;
    this.logger = logger;
  }

  async registerModule(module: Module, config: ModuleConfig): Promise<void> {
    const { name } = module.metadata;

    if (this.modules.has(name)) {
      throw new Error(`Module ${name} is already registered`);
    }

    // Validate dependencies
    if (module.metadata.dependencies) {
      for (const dep of module.metadata.dependencies) {
        if (!this.modules.has(dep)) {
          throw new Error(`Dependency ${dep} not found for module ${name}`);
        }
      }
      this.dependencyGraph.set(name, module.metadata.dependencies);
    }

    this.modules.set(name, module);
    this.moduleConfigs.set(name, config);

    this.logger.info(`Module ${name} registered successfully`);
  }

  async initializeModules(): Promise<void> {
    const loadOrder = this.calculateLoadOrder();

    for (const moduleName of loadOrder) {
      const module = this.modules.get(moduleName);
      const config = this.moduleConfigs.get(moduleName);

      if (!module || !config || !config.enabled) {
        continue;
      }

      try {
        const context: ModuleContext = {
          config: config.config,
          logger: this.logger.child({ module: moduleName }),
          eventBus: this.eventBus,
          services: new Map()
        };

        await module.initialize(context);
        await module.start();

        // Store module exports for other modules to use
        if (module.getExports) {
          this.moduleInstances.set(moduleName, module.getExports());
        }

        this.eventBus.emit('module:started', { name: moduleName, metadata: module.metadata });
        this.logger.info(`Module ${moduleName} initialized and started`);

      } catch (error) {
        this.logger.error(`Failed to initialize module ${moduleName}:`, error);
        throw error;
      }
    }
  }

  async shutdownModules(): Promise<void> {
    const loadOrder = this.calculateLoadOrder().reverse(); // Shutdown in reverse order

    for (const moduleName of loadOrder) {
      const module = this.modules.get(moduleName);

      if (!module) continue;

      try {
        await module.stop();
        await module.destroy();
        this.eventBus.emit('module:stopped', { name: moduleName });
        this.logger.info(`Module ${moduleName} stopped and destroyed`);
      } catch (error) {
        this.logger.error(`Error stopping module ${moduleName}:`, error);
      }
    }
  }

  getModuleExports<T = any>(moduleName: string): T | undefined {
    return this.moduleInstances.get(moduleName);
  }

  isModuleLoaded(moduleName: string): boolean {
    return this.moduleInstances.has(moduleName);
  }

  private calculateLoadOrder(): string[] {
    const visited = new Set<string>();
    const visiting = new Set<string>();
    const result: string[] = [];

    const visit = (moduleName: string) => {
      if (visiting.has(moduleName)) {
        throw new Error(`Circular dependency detected involving module ${moduleName}`);
      }

      if (visited.has(moduleName)) {
        return;
      }

      visiting.add(moduleName);

      const dependencies = this.dependencyGraph.get(moduleName) || [];
      for (const dep of dependencies) {
        visit(dep);
      }

      visiting.delete(moduleName);
      visited.add(moduleName);
      result.push(moduleName);
    };

    for (const moduleName of this.modules.keys()) {
      if (!visited.has(moduleName)) {
        visit(moduleName);
      }
    }

    return result;
  }
}

// Example module implementation
export class DatabaseModule implements Module {
  metadata: ModuleMetadata = {
    name: 'database',
    version: '1.0.0',
    description: 'Database connection and ORM module',
    dependencies: ['config', 'logger']
  };

  private connection: any;
  private context: ModuleContext;

  async initialize(context: ModuleContext): Promise<void> {
    this.context = context;
    const dbConfig = context.config.database;

    // Initialize database connection
    this.connection = await this.createConnection(dbConfig);
  }

  async start(): Promise<void> {
    await this.connection.connect();
    this.context.logger.info('Database connection established');
  }

  async stop(): Promise<void> {
    if (this.connection) {
      await this.connection.disconnect();
      this.context.logger.info('Database connection closed');
    }
  }

  async destroy(): Promise<void> {
    this.connection = null;
  }

  getExports() {
    return {
      connection: this.connection,
      query: (sql: string, params?: any[]) => this.connection.query(sql, params)
    };
  }

  private async createConnection(config: any) {
    // Database connection creation logic
    return {
      connect: async () => { /* connection logic */ },
      disconnect: async () => { /* disconnection logic */ },
      query: async (sql: string, params?: any[]) => { /* query logic */ }
    };
  }
}
```

## Observer Pattern

### Definition and Use Cases
The Observer pattern defines a one-to-many dependency between objects so that when one object changes state, all dependents are notified automatically. Essential for event-driven architectures and reactive programming.

### TypeScript Implementation
```typescript
// libs/shared/utils/src/patterns/event-bus.ts
export interface EventListener<T = any> {
  (data: T): void | Promise<void>;
}

export interface EventSubscription {
  unsubscribe(): void;
}

export class EventBus {
  private listeners = new Map<string, Set<EventListener>>();
  private onceListeners = new Map<string, Set<EventListener>>();

  subscribe<T = any>(event: string, listener: EventListener<T>): EventSubscription {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, new Set());
    }

    this.listeners.get(event)!.add(listener);

    return {
      unsubscribe: () => {
        const eventListeners = this.listeners.get(event);
        if (eventListeners) {
          eventListeners.delete(listener);
          if (eventListeners.size === 0) {
            this.listeners.delete(event);
          }
        }
      }
    };
  }

  once<T = any>(event: string, listener: EventListener<T>): EventSubscription {
    if (!this.onceListeners.has(event)) {
      this.onceListeners.set(event, new Set());
    }

    this.onceListeners.get(event)!.add(listener);

    return {
      unsubscribe: () => {
        const eventListeners = this.onceListeners.get(event);
        if (eventListeners) {
          eventListeners.delete(listener);
          if (eventListeners.size === 0) {
            this.onceListeners.delete(event);
          }
        }
      }
    };
  }

  async emit<T = any>(event: string, data?: T): Promise<void> {
    // Emit to regular listeners
    const regularListeners = this.listeners.get(event);
    if (regularListeners) {
      const promises = Array.from(regularListeners).map(listener =>
        Promise.resolve(listener(data))
      );
      await Promise.all(promises);
    }

    // Emit to once listeners and remove them
    const onceListeners = this.onceListeners.get(event);
    if (onceListeners) {
      const promises = Array.from(onceListeners).map(listener =>
        Promise.resolve(listener(data))
      );
      this.onceListeners.delete(event);
      await Promise.all(promises);
    }
  }

  removeAllListeners(event?: string): void {
    if (event) {
      this.listeners.delete(event);
      this.onceListeners.delete(event);
    } else {
      this.listeners.clear();
      this.onceListeners.clear();
    }
  }

  getListenerCount(event: string): number {
    const regular = this.listeners.get(event)?.size || 0;
    const once = this.onceListeners.get(event)?.size || 0;
    return regular + once;
  }
}

// Domain-specific observer example
export interface TaskEvent {
  taskId: string;
  userId: string;
  timestamp: Date;
  metadata?: Record<string, any>;
}

export class TaskEventBus extends EventBus {
  onTaskCreated(listener: EventListener<TaskEvent>): EventSubscription {
    return this.subscribe('task:created', listener);
  }

  onTaskUpdated(listener: EventListener<TaskEvent>): EventSubscription {
    return this.subscribe('task:updated', listener);
  }

  onTaskCompleted(listener: EventListener<TaskEvent>): EventSubscription {
    return this.subscribe('task:completed', listener);
  }

  onTaskDeleted(listener: EventListener<TaskEvent>): EventSubscription {
    return this.subscribe('task:deleted', listener);
  }

  emitTaskCreated(event: TaskEvent): Promise<void> {
    return this.emit('task:created', event);
  }

  emitTaskUpdated(event: TaskEvent): Promise<void> {
    return this.emit('task:updated', event);
  }

  emitTaskCompleted(event: TaskEvent): Promise<void> {
    return this.emit('task:completed', event);
  }

  emitTaskDeleted(event: TaskEvent): Promise<void> {
    return this.emit('task:deleted', event);
  }
}
```

## Dependency Injection Pattern

### Definition and Use Cases
Dependency Injection is a technique for achieving Inversion of Control between classes and their dependencies. It promotes loose coupling, testability, and maintainability by injecting dependencies rather than creating them internally.

### TypeScript Implementation
```typescript
// libs/shared/utils/src/di/container.ts
export type Constructor<T = {}> = new (...args: any[]) => T;
export type Factory<T = any> = () => T | Promise<T>;

export interface ServiceDefinition<T = any> {
  factory: Factory<T>;
  singleton?: boolean;
  dependencies?: string[];
}

export class DIContainer {
  private services = new Map<string, ServiceDefinition>();
  private instances = new Map<string, any>();
  private resolving = new Set<string>();

  register<T>(token: string, definition: ServiceDefinition<T>): void {
    this.services.set(token, definition);
  }

  registerClass<T>(token: string, constructor: Constructor<T>, dependencies: string[] = [], singleton = true): void {
    this.register(token, {
      factory: () => {
        const deps = dependencies.map(dep => this.resolve(dep));
        return new constructor(...deps);
      },
      singleton,
      dependencies
    });
  }

  registerValue<T>(token: string, value: T): void {
    this.instances.set(token, value);
  }

  registerFactory<T>(token: string, factory: Factory<T>, dependencies: string[] = [], singleton = true): void {
    this.register(token, {
      factory: () => {
        const deps = dependencies.map(dep => this.resolve(dep));
        return factory.call(null, ...deps);
      },
      singleton,
      dependencies
    });
  }

  resolve<T = any>(token: string): T {
    // Check if already instantiated
    if (this.instances.has(token)) {
      return this.instances.get(token);
    }

    // Check for circular dependencies
    if (this.resolving.has(token)) {
      throw new Error(`Circular dependency detected: ${Array.from(this.resolving).join(' -> ')} -> ${token}`);
    }

    const definition = this.services.get(token);
    if (!definition) {
      throw new Error(`Service ${token} not registered`);
    }

    this.resolving.add(token);

    try {
      const instance = definition.factory();

      if (definition.singleton) {
        this.instances.set(token, instance);
      }

      this.resolving.delete(token);
      return instance;
    } catch (error) {
      this.resolving.delete(token);
      throw error;
    }
  }

  has(token: string): boolean {
    return this.services.has(token) || this.instances.has(token);
  }

  clear(): void {
    this.services.clear();
    this.instances.clear();
    this.resolving.clear();
  }
}

// Example service implementations
export interface ILogger {
  info(message: string, meta?: any): void;
  error(message: string, error?: Error): void;
  warn(message: string, meta?: any): void;
  debug(message: string, meta?: any): void;
}

export class ConsoleLogger implements ILogger {
  info(message: string, meta?: any): void {
    console.log(`[INFO] ${message}`, meta || '');
  }

  error(message: string, error?: Error): void {
    console.error(`[ERROR] ${message}`, error || '');
  }

  warn(message: string, meta?: any): void {
    console.warn(`[WARN] ${message}`, meta || '');
  }

  debug(message: string, meta?: any): void {
    console.debug(`[DEBUG] ${message}`, meta || '');
  }
}

export interface IConfigService {
  get(key: string): any;
  set(key: string, value: any): void;
}

export class ConfigService implements IConfigService {
  private config = new Map<string, any>();

  constructor(private logger: ILogger) {
    this.logger.info('ConfigService initialized');
  }

  get(key: string): any {
    return this.config.get(key);
  }

  set(key: string, value: any): void {
    this.config.set(key, value);
    this.logger.debug(`Config set: ${key}`);
  }
}

// Container setup example
export function setupContainer(): DIContainer {
  const container = new DIContainer();

  // Register logger
  container.registerClass('logger', ConsoleLogger, [], true);

  // Register config service with logger dependency
  container.registerClass('config', ConfigService, ['logger'], true);

  // Register database factory
  container.registerFactory('database', (config: IConfigService) => {
    const dbUrl = config.get('DATABASE_URL');
    return new DatabaseConnection(dbUrl);
  }, ['config'], true);

  return container;
}
```

## Best Practices and Common Pitfalls

### Repository Pattern Best Practices
- **Interface Segregation**: Create specific repository interfaces for different use cases
- **Error Handling**: Always handle database errors gracefully and provide meaningful error messages
- **Testing**: Use repository interfaces for easy mocking in unit tests
- **Caching**: Implement caching at the repository level for frequently accessed data

### Factory Pattern Best Practices
- **Configuration-Driven**: Use configuration to determine which implementation to create
- **Validation**: Validate inputs before creating objects
- **Error Handling**: Provide clear error messages for unsupported types
- **Registration**: Consider using a registry pattern for dynamic factory registration

### Builder Pattern Best Practices
- **Immutability**: Consider making builders immutable by returning new instances
- **Validation**: Validate required fields in the build() method
- **Fluent Interface**: Chain methods for better readability
- **Default Values**: Provide sensible defaults for optional parameters

### Engine Pattern Best Practices
- **Dependency Management**: Implement proper dependency resolution and circular dependency detection
- **Error Isolation**: Ensure module failures don't crash the entire system
- **Hot Reloading**: Consider implementing hot module reloading for development
- **Configuration**: Provide comprehensive configuration options for each module

### Observer Pattern Best Practices
- **Memory Leaks**: Always provide unsubscribe mechanisms and clean up listeners
- **Error Handling**: Handle errors in event listeners to prevent cascading failures
- **Async Events**: Support both synchronous and asynchronous event handlers
- **Type Safety**: Use TypeScript generics for type-safe event data

### Dependency Injection Best Practices
- **Interface-Based**: Always inject interfaces, not concrete implementations
- **Circular Dependencies**: Design your dependency graph to avoid circular dependencies
- **Lifecycle Management**: Properly manage singleton vs transient lifetimes
- **Testing**: Use DI containers for easy test setup and mocking

## NX Monorepo Integration

### Library Organization
```typescript
// libs/shared/patterns/src/index.ts
export * from './repository/base.repository';
export * from './factory/database.factory';
export * from './builder/api-response.builder';
export * from './engine/module-engine';
export * from './observer/event-bus';
export * from './di/container';
```

### Project Configuration
```json
// libs/shared/patterns/project.json
{
  "name": "shared-patterns",
  "sourceRoot": "libs/shared/patterns/src",
  "projectType": "library",
  "targets": {
    "build": {
      "executor": "@nx/js:tsc",
      "outputs": ["{options.outputPath}"],
      "options": {
        "outputPath": "dist/libs/shared/patterns",
        "main": "libs/shared/patterns/src/index.ts",
        "tsConfig": "libs/shared/patterns/tsconfig.lib.json"
      }
    },
    "test": {
      "executor": "@nx/jest:jest",
      "outputs": ["{workspaceRoot}/coverage/{projectRoot}"],
      "options": {
        "jestConfig": "libs/shared/patterns/jest.config.ts"
      }
    }
  },
  "tags": ["scope:shared", "type:util"]
}
```

### Usage in Applications
```typescript
// apps/api-core/src/main.ts
import { setupContainer } from '@shared/patterns';
import { ModuleEngine } from '@shared/patterns';

async function bootstrap() {
  const container = setupContainer();
  const engine = container.resolve<ModuleEngine>('moduleEngine');

  await engine.initializeModules();

  // Start your application
}
```

This comprehensive design patterns template provides the foundation for building maintainable, scalable applications within our NX monorepo structure, with special emphasis on the engine pattern for modular architectures.


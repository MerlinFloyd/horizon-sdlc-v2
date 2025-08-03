# TypeScript Patterns Template

## Overview
This template demonstrates TypeScript patterns following SOLID principles, dependency injection, and design patterns aligned with our organizational standards.

## SOLID Principles Implementation

### 1. Single Responsibility Principle (SRP)

#### User Service Example
```typescript
// libs/api/services/src/user/user.service.ts
import { Injectable } from '@nestjs/common';
import { UserRepository } from './user.repository';
import { User, CreateUserDto, UpdateUserDto } from '@shared/types';

@Injectable()
export class UserService {
  constructor(private readonly userRepository: UserRepository) {}

  async createUser(userData: CreateUserDto): Promise<User> {
    // Single responsibility: user creation logic
    const user = await this.userRepository.create(userData);
    return user;
  }

  async getUserById(id: string): Promise<User | null> {
    // Single responsibility: user retrieval logic
    return this.userRepository.findById(id);
  }

  async updateUser(id: string, userData: UpdateUserDto): Promise<User> {
    // Single responsibility: user update logic
    return this.userRepository.update(id, userData);
  }

  async deleteUser(id: string): Promise<void> {
    // Single responsibility: user deletion logic
    await this.userRepository.delete(id);
  }
}
```

#### User Repository Example
```typescript
// libs/api/services/src/user/user.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '@api/database';
import { User, CreateUserDto, UpdateUserDto } from '@shared/types';

@Injectable()
export class UserRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(userData: CreateUserDto): Promise<User> {
    // Single responsibility: data persistence
    return this.prisma.user.create({
      data: userData,
    });
  }

  async findById(id: string): Promise<User | null> {
    // Single responsibility: data retrieval
    return this.prisma.user.findUnique({
      where: { id },
    });
  }

  async update(id: string, userData: UpdateUserDto): Promise<User> {
    // Single responsibility: data update
    return this.prisma.user.update({
      where: { id },
      data: userData,
    });
  }

  async delete(id: string): Promise<void> {
    // Single responsibility: data deletion
    await this.prisma.user.delete({
      where: { id },
    });
  }
}
```

### 2. Open/Closed Principle (OCP)

#### Payment Processor Interface
```typescript
// libs/shared/types/src/payment/payment.types.ts
export interface PaymentProcessor {
  processPayment(amount: number, currency: string, metadata?: Record<string, any>): Promise<PaymentResult>;
  refundPayment(transactionId: string, amount?: number): Promise<RefundResult>;
  getPaymentStatus(transactionId: string): Promise<PaymentStatus>;
}

export interface PaymentResult {
  transactionId: string;
  status: 'success' | 'failed' | 'pending';
  amount: number;
  currency: string;
  timestamp: Date;
}

export interface RefundResult {
  refundId: string;
  status: 'success' | 'failed' | 'pending';
  amount: number;
  timestamp: Date;
}

export enum PaymentStatus {
  PENDING = 'pending',
  COMPLETED = 'completed',
  FAILED = 'failed',
  CANCELLED = 'cancelled',
}
```

#### Stripe Payment Processor Implementation
```typescript
// libs/api/services/src/payment/processors/stripe.processor.ts
import { Injectable } from '@nestjs/common';
import Stripe from 'stripe';
import { PaymentProcessor, PaymentResult, RefundResult, PaymentStatus } from '@shared/types';

@Injectable()
export class StripePaymentProcessor implements PaymentProcessor {
  private stripe: Stripe;

  constructor() {
    this.stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
      apiVersion: '2023-10-16',
    });
  }

  async processPayment(amount: number, currency: string, metadata?: Record<string, any>): Promise<PaymentResult> {
    try {
      const paymentIntent = await this.stripe.paymentIntents.create({
        amount: amount * 100, // Convert to cents
        currency,
        metadata,
      });

      return {
        transactionId: paymentIntent.id,
        status: this.mapStripeStatus(paymentIntent.status),
        amount,
        currency,
        timestamp: new Date(),
      };
    } catch (error) {
      throw new Error(`Stripe payment failed: ${error.message}`);
    }
  }

  async refundPayment(transactionId: string, amount?: number): Promise<RefundResult> {
    try {
      const refund = await this.stripe.refunds.create({
        payment_intent: transactionId,
        amount: amount ? amount * 100 : undefined,
      });

      return {
        refundId: refund.id,
        status: refund.status === 'succeeded' ? 'success' : 'failed',
        amount: refund.amount / 100,
        timestamp: new Date(),
      };
    } catch (error) {
      throw new Error(`Stripe refund failed: ${error.message}`);
    }
  }

  async getPaymentStatus(transactionId: string): Promise<PaymentStatus> {
    try {
      const paymentIntent = await this.stripe.paymentIntents.retrieve(transactionId);
      return this.mapStripeStatus(paymentIntent.status);
    } catch (error) {
      throw new Error(`Failed to get payment status: ${error.message}`);
    }
  }

  private mapStripeStatus(stripeStatus: string): PaymentStatus {
    switch (stripeStatus) {
      case 'succeeded':
        return PaymentStatus.COMPLETED;
      case 'processing':
      case 'requires_payment_method':
      case 'requires_confirmation':
        return PaymentStatus.PENDING;
      case 'canceled':
        return PaymentStatus.CANCELLED;
      default:
        return PaymentStatus.FAILED;
    }
  }
}
```

### 3. Liskov Substitution Principle (LSP)

#### Base Cache Interface
```typescript
// libs/shared/types/src/cache/cache.types.ts
export interface CacheService {
  get<T>(key: string): Promise<T | null>;
  set<T>(key: string, value: T, ttl?: number): Promise<void>;
  delete(key: string): Promise<void>;
  clear(): Promise<void>;
  exists(key: string): Promise<boolean>;
}
```

#### Redis Cache Implementation
```typescript
// libs/api/services/src/cache/redis-cache.service.ts
import { Injectable } from '@nestjs/common';
import { Redis } from 'ioredis';
import { CacheService } from '@shared/types';

@Injectable()
export class RedisCacheService implements CacheService {
  private redis: Redis;

  constructor() {
    this.redis = new Redis({
      host: process.env.REDIS_HOST || 'localhost',
      port: parseInt(process.env.REDIS_PORT || '6379'),
      password: process.env.REDIS_PASSWORD,
    });
  }

  async get<T>(key: string): Promise<T | null> {
    const value = await this.redis.get(key);
    return value ? JSON.parse(value) : null;
  }

  async set<T>(key: string, value: T, ttl?: number): Promise<void> {
    const serialized = JSON.stringify(value);
    if (ttl) {
      await this.redis.setex(key, ttl, serialized);
    } else {
      await this.redis.set(key, serialized);
    }
  }

  async delete(key: string): Promise<void> {
    await this.redis.del(key);
  }

  async clear(): Promise<void> {
    await this.redis.flushall();
  }

  async exists(key: string): Promise<boolean> {
    const result = await this.redis.exists(key);
    return result === 1;
  }
}
```

#### Memory Cache Implementation (for testing)
```typescript
// libs/api/services/src/cache/memory-cache.service.ts
import { Injectable } from '@nestjs/common';
import { CacheService } from '@shared/types';

interface CacheItem<T> {
  value: T;
  expiry?: number;
}

@Injectable()
export class MemoryCacheService implements CacheService {
  private cache = new Map<string, CacheItem<any>>();

  async get<T>(key: string): Promise<T | null> {
    const item = this.cache.get(key);
    if (!item) return null;

    if (item.expiry && Date.now() > item.expiry) {
      this.cache.delete(key);
      return null;
    }

    return item.value;
  }

  async set<T>(key: string, value: T, ttl?: number): Promise<void> {
    const expiry = ttl ? Date.now() + ttl * 1000 : undefined;
    this.cache.set(key, { value, expiry });
  }

  async delete(key: string): Promise<void> {
    this.cache.delete(key);
  }

  async clear(): Promise<void> {
    this.cache.clear();
  }

  async exists(key: string): Promise<boolean> {
    return this.cache.has(key);
  }
}
```

### 4. Interface Segregation Principle (ISP)

#### Segregated Notification Interfaces
```typescript
// libs/shared/types/src/notification/notification.types.ts

// Specific interfaces for different notification types
export interface EmailNotificationService {
  sendEmail(to: string, subject: string, body: string): Promise<void>;
  sendTemplateEmail(to: string, templateId: string, data: Record<string, any>): Promise<void>;
}

export interface SMSNotificationService {
  sendSMS(to: string, message: string): Promise<void>;
}

export interface PushNotificationService {
  sendPushNotification(deviceToken: string, title: string, body: string): Promise<void>;
  sendPushToTopic(topic: string, title: string, body: string): Promise<void>;
}

export interface WebhookNotificationService {
  sendWebhook(url: string, payload: Record<string, any>): Promise<void>;
}

// Clients only implement what they need
export interface NotificationService extends 
  EmailNotificationService, 
  SMSNotificationService, 
  PushNotificationService {}
```

### 5. Dependency Inversion Principle (DIP)

#### High-level Module Depending on Abstractions
```typescript
// libs/api/services/src/user/user-notification.service.ts
import { Injectable } from '@nestjs/common';
import { EmailNotificationService, SMSNotificationService } from '@shared/types';

@Injectable()
export class UserNotificationService {
  constructor(
    private readonly emailService: EmailNotificationService,
    private readonly smsService: SMSNotificationService,
  ) {}

  async notifyUserRegistration(email: string, phone?: string): Promise<void> {
    // High-level module depends on abstractions, not concretions
    await this.emailService.sendTemplateEmail(
      email,
      'welcome-template',
      { timestamp: new Date().toISOString() }
    );

    if (phone) {
      await this.smsService.sendSMS(
        phone,
        'Welcome to Horizon! Your account has been created successfully.'
      );
    }
  }

  async notifyPasswordReset(email: string, resetToken: string): Promise<void> {
    await this.emailService.sendTemplateEmail(
      email,
      'password-reset-template',
      { resetToken, expiresIn: '1 hour' }
    );
  }
}
```

## Design Patterns

### 1. Factory Pattern

#### Logger Factory
```typescript
// libs/shared/utils/src/logger/logger.factory.ts
import { Logger } from '@shared/types';
import { ConsoleLogger } from './console-logger';
import { FileLogger } from './file-logger';
import { ElasticLogger } from './elastic-logger';

export class LoggerFactory {
  static createLogger(type: 'console' | 'file' | 'elastic', config?: any): Logger {
    switch (type) {
      case 'console':
        return new ConsoleLogger(config);
      case 'file':
        return new FileLogger(config);
      case 'elastic':
        return new ElasticLogger(config);
      default:
        throw new Error(`Unknown logger type: ${type}`);
    }
  }

  static createProductionLogger(): Logger {
    if (process.env.NODE_ENV === 'production') {
      return this.createLogger('elastic', {
        endpoint: process.env.ELASTIC_ENDPOINT,
        apiKey: process.env.ELASTIC_API_KEY,
      });
    }
    return this.createLogger('console');
  }
}
```

### 2. Repository Pattern

#### Generic Repository Interface
```typescript
// libs/shared/types/src/repository/repository.types.ts
export interface Repository<T, ID = string> {
  findById(id: ID): Promise<T | null>;
  findAll(options?: FindOptions): Promise<T[]>;
  create(entity: Omit<T, 'id'>): Promise<T>;
  update(id: ID, entity: Partial<T>): Promise<T>;
  delete(id: ID): Promise<void>;
  count(filter?: Record<string, any>): Promise<number>;
}

export interface FindOptions {
  limit?: number;
  offset?: number;
  orderBy?: string;
  orderDirection?: 'asc' | 'desc';
  filter?: Record<string, any>;
}
```

### 3. Builder Pattern

#### Query Builder
```typescript
// libs/api/database/src/query-builder/query-builder.ts
export class QueryBuilder {
  private query: string = '';
  private params: any[] = [];

  select(fields: string[]): this {
    this.query += `SELECT ${fields.join(', ')} `;
    return this;
  }

  from(table: string): this {
    this.query += `FROM ${table} `;
    return this;
  }

  where(condition: string, value?: any): this {
    const operator = this.query.includes('WHERE') ? 'AND' : 'WHERE';
    this.query += `${operator} ${condition} `;
    if (value !== undefined) {
      this.params.push(value);
    }
    return this;
  }

  orderBy(field: string, direction: 'ASC' | 'DESC' = 'ASC'): this {
    this.query += `ORDER BY ${field} ${direction} `;
    return this;
  }

  limit(count: number): this {
    this.query += `LIMIT ${count} `;
    return this;
  }

  build(): { query: string; params: any[] } {
    return {
      query: this.query.trim(),
      params: this.params,
    };
  }
}

// Usage example
const { query, params } = new QueryBuilder()
  .select(['id', 'name', 'email'])
  .from('users')
  .where('active = ?', true)
  .where('created_at > ?', new Date('2024-01-01'))
  .orderBy('created_at', 'DESC')
  .limit(10)
  .build();
```

### 4. Strategy Pattern

#### Validation Strategy
```typescript
// libs/shared/utils/src/validation/validation-strategy.ts
export interface ValidationStrategy<T> {
  validate(data: T): ValidationResult;
}

export interface ValidationResult {
  isValid: boolean;
  errors: string[];
}

export class EmailValidationStrategy implements ValidationStrategy<string> {
  validate(email: string): ValidationResult {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    const isValid = emailRegex.test(email);
    
    return {
      isValid,
      errors: isValid ? [] : ['Invalid email format'],
    };
  }
}

export class PasswordValidationStrategy implements ValidationStrategy<string> {
  validate(password: string): ValidationResult {
    const errors: string[] = [];
    
    if (password.length < 8) {
      errors.push('Password must be at least 8 characters long');
    }
    if (!/[A-Z]/.test(password)) {
      errors.push('Password must contain at least one uppercase letter');
    }
    if (!/[a-z]/.test(password)) {
      errors.push('Password must contain at least one lowercase letter');
    }
    if (!/\d/.test(password)) {
      errors.push('Password must contain at least one number');
    }
    
    return {
      isValid: errors.length === 0,
      errors,
    };
  }
}

export class ValidationContext<T> {
  constructor(private strategy: ValidationStrategy<T>) {}

  setStrategy(strategy: ValidationStrategy<T>): void {
    this.strategy = strategy;
  }

  validate(data: T): ValidationResult {
    return this.strategy.validate(data);
  }
}
```

## Dependency Injection Container

### IoC Container Implementation
```typescript
// libs/shared/utils/src/di/container.ts
type Constructor<T = {}> = new (...args: any[]) => T;
type ServiceIdentifier<T = any> = Constructor<T> | string | symbol;

export class Container {
  private services = new Map<ServiceIdentifier, any>();
  private singletons = new Map<ServiceIdentifier, any>();

  bind<T>(identifier: ServiceIdentifier<T>, implementation: Constructor<T>): void {
    this.services.set(identifier, implementation);
  }

  bindSingleton<T>(identifier: ServiceIdentifier<T>, implementation: Constructor<T>): void {
    this.services.set(identifier, implementation);
    this.singletons.set(identifier, null);
  }

  get<T>(identifier: ServiceIdentifier<T>): T {
    // Check if it's a singleton and already instantiated
    if (this.singletons.has(identifier)) {
      const singleton = this.singletons.get(identifier);
      if (singleton) return singleton;
    }

    const ServiceClass = this.services.get(identifier);
    if (!ServiceClass) {
      throw new Error(`Service ${String(identifier)} not found`);
    }

    // Resolve dependencies
    const dependencies = this.resolveDependencies(ServiceClass);
    const instance = new ServiceClass(...dependencies);

    // Store singleton instance
    if (this.singletons.has(identifier)) {
      this.singletons.set(identifier, instance);
    }

    return instance;
  }

  private resolveDependencies(ServiceClass: Constructor): any[] {
    // In a real implementation, you'd use reflection or decorators
    // to determine dependencies. This is a simplified version.
    const dependencies: any[] = [];
    
    // Example: resolve known dependencies
    if (ServiceClass.name === 'UserService') {
      dependencies.push(this.get('UserRepository'));
    }
    
    return dependencies;
  }
}

// Usage example
const container = new Container();

// Bind services
container.bindSingleton('UserRepository', UserRepository);
container.bind('UserService', UserService);
container.bindSingleton('CacheService', RedisCacheService);

// Resolve services
const userService = container.get<UserService>('UserService');
```

This template demonstrates comprehensive TypeScript patterns following SOLID principles and design patterns for scalable, maintainable code architecture.

# Database Integration Patterns Template

## Overview
This template provides comprehensive patterns for database integration using Prisma ORM, Mongoose ODM, Redis caching strategies, migration patterns, and connection pooling within our NX monorepo structure.

## Prisma ORM Patterns

### Schema Definition and Models
```prisma
// libs/api/database/prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
  output   = "../src/generated/client"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String?
  avatar    String?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  // Relations
  tasks     Task[]
  profile   UserProfile?
  sessions  UserSession[]

  @@map("users")
}

model UserProfile {
  id       String @id @default(cuid())
  userId   String @unique
  bio      String?
  timezone String @default("UTC")
  settings Json   @default("{}")

  // Relations
  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@map("user_profiles")
}

model Task {
  id          String     @id @default(cuid())
  title       String
  description String?
  status      TaskStatus @default(TODO)
  priority    Priority   @default(MEDIUM)
  dueDate     DateTime?
  createdAt   DateTime   @default(now())
  updatedAt   DateTime   @updatedAt

  // Relations
  assigneeId String?
  assignee   User?   @relation(fields: [assigneeId], references: [id])
  tags       TaskTag[]

  @@map("tasks")
  @@index([status, priority])
  @@index([assigneeId])
  @@index([createdAt])
}

model Tag {
  id    String @id @default(cuid())
  name  String @unique
  color String @default("#gray")

  // Relations
  tasks TaskTag[]

  @@map("tags")
}

model TaskTag {
  taskId String
  tagId  String

  // Relations
  task Task @relation(fields: [taskId], references: [id], onDelete: Cascade)
  tag  Tag  @relation(fields: [tagId], references: [id], onDelete: Cascade)

  @@id([taskId, tagId])
  @@map("task_tags")
}

enum TaskStatus {
  TODO
  IN_PROGRESS
  COMPLETED
  CANCELLED
}

enum Priority {
  LOW
  MEDIUM
  HIGH
}
```

### Repository Pattern with Prisma
```typescript
// libs/api/database/src/repositories/task.repository.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { Task, Prisma } from '../generated/client';

export interface TaskFilters {
  status?: TaskStatus;
  priority?: Priority;
  assigneeId?: string;
  search?: string;
  tags?: string[];
}

export interface PaginationOptions {
  page: number;
  limit: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

@Injectable()
export class TaskRepository {
  constructor(private prisma: PrismaService) {}

  async findMany(
    filters: TaskFilters = {},
    pagination: PaginationOptions
  ): Promise<{ tasks: Task[]; total: number }> {
    const where: Prisma.TaskWhereInput = this.buildWhereClause(filters);
    const orderBy = this.buildOrderBy(pagination.sortBy, pagination.sortOrder);

    const [tasks, total] = await Promise.all([
      this.prisma.task.findMany({
        where,
        orderBy,
        skip: (pagination.page - 1) * pagination.limit,
        take: pagination.limit,
        include: {
          assignee: {
            select: { id: true, name: true, email: true }
          },
          tags: {
            include: { tag: true }
          }
        }
      }),
      this.prisma.task.count({ where })
    ]);

    return { tasks, total };
  }

  async findById(id: string): Promise<Task | null> {
    return this.prisma.task.findUnique({
      where: { id },
      include: {
        assignee: {
          select: { id: true, name: true, email: true }
        },
        tags: {
          include: { tag: true }
        }
      }
    });
  }

  async create(data: Prisma.TaskCreateInput): Promise<Task> {
    return this.prisma.task.create({
      data,
      include: {
        assignee: {
          select: { id: true, name: true, email: true }
        },
        tags: {
          include: { tag: true }
        }
      }
    });
  }

  async update(id: string, data: Prisma.TaskUpdateInput): Promise<Task> {
    return this.prisma.task.update({
      where: { id },
      data,
      include: {
        assignee: {
          select: { id: true, name: true, email: true }
        },
        tags: {
          include: { tag: true }
        }
      }
    });
  }

  async delete(id: string): Promise<Task> {
    return this.prisma.task.delete({
      where: { id }
    });
  }

  async addTags(taskId: string, tagIds: string[]): Promise<void> {
    await this.prisma.taskTag.createMany({
      data: tagIds.map(tagId => ({ taskId, tagId })),
      skipDuplicates: true
    });
  }

  async removeTags(taskId: string, tagIds: string[]): Promise<void> {
    await this.prisma.taskTag.deleteMany({
      where: {
        taskId,
        tagId: { in: tagIds }
      }
    });
  }

  private buildWhereClause(filters: TaskFilters): Prisma.TaskWhereInput {
    const where: Prisma.TaskWhereInput = {};

    if (filters.status) {
      where.status = filters.status;
    }

    if (filters.priority) {
      where.priority = filters.priority;
    }

    if (filters.assigneeId) {
      where.assigneeId = filters.assigneeId;
    }

    if (filters.search) {
      where.OR = [
        { title: { contains: filters.search, mode: 'insensitive' } },
        { description: { contains: filters.search, mode: 'insensitive' } }
      ];
    }

    if (filters.tags && filters.tags.length > 0) {
      where.tags = {
        some: {
          tag: {
            name: { in: filters.tags }
          }
        }
      };
    }

    return where;
  }

  private buildOrderBy(
    sortBy?: string, 
    sortOrder: 'asc' | 'desc' = 'desc'
  ): Prisma.TaskOrderByWithRelationInput {
    const validSortFields = ['createdAt', 'updatedAt', 'dueDate', 'priority', 'title'];
    const field = validSortFields.includes(sortBy || '') ? sortBy : 'createdAt';
    
    return { [field!]: sortOrder };
  }
}
```

### Database Service with Connection Pooling
```typescript
// libs/api/database/src/prisma.service.ts
import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from './generated/client';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  constructor(private configService: ConfigService) {
    super({
      datasources: {
        db: {
          url: configService.get('DATABASE_URL')
        }
      },
      log: configService.get('NODE_ENV') === 'development' 
        ? ['query', 'info', 'warn', 'error']
        : ['error'],
      errorFormat: 'pretty'
    });
  }

  async onModuleInit() {
    await this.$connect();
    
    // Enable query logging in development
    if (this.configService.get('NODE_ENV') === 'development') {
      this.$on('query', (e) => {
        console.log('Query: ' + e.query);
        console.log('Duration: ' + e.duration + 'ms');
      });
    }
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }

  // Transaction helper
  async executeTransaction<T>(
    fn: (prisma: PrismaClient) => Promise<T>
  ): Promise<T> {
    return this.$transaction(fn);
  }

  // Soft delete helper
  async softDelete(model: string, id: string): Promise<any> {
    return (this as any)[model].update({
      where: { id },
      data: { deletedAt: new Date() }
    });
  }

  // Bulk operations helper
  async bulkUpsert<T>(
    model: string,
    data: T[],
    uniqueField: string
  ): Promise<void> {
    await this.$transaction(
      data.map(item => 
        (this as any)[model].upsert({
          where: { [uniqueField]: (item as any)[uniqueField] },
          update: item,
          create: item
        })
      )
    );
  }
}
```

## Mongoose ODM Patterns

### Schema Definition and Models
```typescript
// libs/api/database/src/schemas/user.schema.ts
import { Schema, Document, model } from 'mongoose';

export interface IUser extends Document {
  email: string;
  name?: string;
  avatar?: string;
  profile?: {
    bio?: string;
    timezone: string;
    settings: Record<string, any>;
  };
  createdAt: Date;
  updatedAt: Date;
}

const UserSchema = new Schema<IUser>({
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true,
    validate: {
      validator: (email: string) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email),
      message: 'Invalid email format'
    }
  },
  name: {
    type: String,
    trim: true,
    maxlength: 100
  },
  avatar: {
    type: String,
    validate: {
      validator: (url: string) => !url || /^https?:\/\/.+/.test(url),
      message: 'Invalid avatar URL'
    }
  },
  profile: {
    bio: { type: String, maxlength: 500 },
    timezone: { type: String, default: 'UTC' },
    settings: { type: Schema.Types.Mixed, default: {} }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
UserSchema.index({ email: 1 });
UserSchema.index({ createdAt: -1 });

// Virtual for tasks
UserSchema.virtual('tasks', {
  ref: 'Task',
  localField: '_id',
  foreignField: 'assigneeId'
});

// Instance methods
UserSchema.methods.toSafeObject = function() {
  const obj = this.toObject();
  delete obj.__v;
  return obj;
};

// Static methods
UserSchema.statics.findByEmail = function(email: string) {
  return this.findOne({ email: email.toLowerCase() });
};

export const User = model<IUser>('User', UserSchema);
```

### Repository Pattern with Mongoose
```typescript
// libs/api/database/src/repositories/user.repository.mongoose.ts
import { Injectable } from '@nestjs/common';
import { User, IUser } from '../schemas/user.schema';
import { FilterQuery, UpdateQuery, QueryOptions } from 'mongoose';

export interface CreateUserDto {
  email: string;
  name?: string;
  avatar?: string;
  profile?: {
    bio?: string;
    timezone?: string;
    settings?: Record<string, any>;
  };
}

export interface UpdateUserDto {
  name?: string;
  avatar?: string;
  profile?: {
    bio?: string;
    timezone?: string;
    settings?: Record<string, any>;
  };
}

@Injectable()
export class UserRepositoryMongo {
  async findById(id: string): Promise<IUser | null> {
    return User.findById(id).populate('tasks').exec();
  }

  async findByEmail(email: string): Promise<IUser | null> {
    return User.findByEmail(email);
  }

  async findMany(
    filter: FilterQuery<IUser> = {},
    options: QueryOptions = {}
  ): Promise<IUser[]> {
    return User.find(filter, null, {
      sort: { createdAt: -1 },
      ...options
    }).exec();
  }

  async create(userData: CreateUserDto): Promise<IUser> {
    const user = new User(userData);
    return user.save();
  }

  async update(id: string, updateData: UpdateUserDto): Promise<IUser | null> {
    return User.findByIdAndUpdate(
      id,
      { $set: updateData },
      { new: true, runValidators: true }
    ).exec();
  }

  async delete(id: string): Promise<IUser | null> {
    return User.findByIdAndDelete(id).exec();
  }

  async updateSettings(
    id: string,
    settings: Record<string, any>
  ): Promise<IUser | null> {
    return User.findByIdAndUpdate(
      id,
      { $set: { 'profile.settings': settings } },
      { new: true, runValidators: true }
    ).exec();
  }

  async aggregateUserStats(): Promise<any[]> {
    return User.aggregate([
      {
        $lookup: {
          from: 'tasks',
          localField: '_id',
          foreignField: 'assigneeId',
          as: 'tasks'
        }
      },
      {
        $project: {
          email: 1,
          name: 1,
          taskCount: { $size: '$tasks' },
          completedTasks: {
            $size: {
              $filter: {
                input: '$tasks',
                cond: { $eq: ['$$this.status', 'COMPLETED'] }
              }
            }
          }
        }
      }
    ]).exec();
  }

  async findUsersWithTasksInDateRange(
    startDate: Date,
    endDate: Date
  ): Promise<IUser[]> {
    return User.find({
      'tasks.createdAt': {
        $gte: startDate,
        $lte: endDate
      }
    }).populate({
      path: 'tasks',
      match: {
        createdAt: { $gte: startDate, $lte: endDate }
      }
    }).exec();
  }
}
```

## Redis Caching Strategies

### Redis Service Setup
```typescript
// libs/api/database/src/redis/redis.service.ts
import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

export interface CacheOptions {
  ttl?: number; // Time to live in seconds
  prefix?: string;
  serialize?: boolean;
}

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private client: Redis;
  private subscriber: Redis;
  private publisher: Redis;

  constructor(private configService: ConfigService) {}

  async onModuleInit() {
    const redisConfig = {
      host: this.configService.get('REDIS_HOST', 'localhost'),
      port: this.configService.get('REDIS_PORT', 6379),
      password: this.configService.get('REDIS_PASSWORD'),
      db: this.configService.get('REDIS_DB', 0),
      retryDelayOnFailover: 100,
      maxRetriesPerRequest: 3,
      lazyConnect: true
    };

    this.client = new Redis(redisConfig);
    this.subscriber = new Redis(redisConfig);
    this.publisher = new Redis(redisConfig);

    await Promise.all([
      this.client.connect(),
      this.subscriber.connect(),
      this.publisher.connect()
    ]);
  }

  async onModuleDestroy() {
    await Promise.all([
      this.client.disconnect(),
      this.subscriber.disconnect(),
      this.publisher.disconnect()
    ]);
  }

  // Basic cache operations
  async get<T = any>(key: string, options: CacheOptions = {}): Promise<T | null> {
    const fullKey = this.buildKey(key, options.prefix);
    const value = await this.client.get(fullKey);

    if (!value) return null;

    return options.serialize !== false ? JSON.parse(value) : value;
  }

  async set<T = any>(
    key: string,
    value: T,
    options: CacheOptions = {}
  ): Promise<void> {
    const fullKey = this.buildKey(key, options.prefix);
    const serializedValue = options.serialize !== false
      ? JSON.stringify(value)
      : value as string;

    if (options.ttl) {
      await this.client.setex(fullKey, options.ttl, serializedValue);
    } else {
      await this.client.set(fullKey, serializedValue);
    }
  }

  async del(key: string, prefix?: string): Promise<number> {
    const fullKey = this.buildKey(key, prefix);
    return this.client.del(fullKey);
  }

  async exists(key: string, prefix?: string): Promise<boolean> {
    const fullKey = this.buildKey(key, prefix);
    return (await this.client.exists(fullKey)) === 1;
  }

  // Hash operations
  async hget(key: string, field: string, prefix?: string): Promise<string | null> {
    const fullKey = this.buildKey(key, prefix);
    return this.client.hget(fullKey, field);
  }

  async hset(
    key: string,
    field: string,
    value: string,
    prefix?: string
  ): Promise<number> {
    const fullKey = this.buildKey(key, prefix);
    return this.client.hset(fullKey, field, value);
  }

  async hgetall(key: string, prefix?: string): Promise<Record<string, string>> {
    const fullKey = this.buildKey(key, prefix);
    return this.client.hgetall(fullKey);
  }

  // List operations
  async lpush(key: string, ...values: string[]): Promise<number> {
    return this.client.lpush(key, ...values);
  }

  async rpop(key: string): Promise<string | null> {
    return this.client.rpop(key);
  }

  async lrange(key: string, start: number, stop: number): Promise<string[]> {
    return this.client.lrange(key, start, stop);
  }

  // Pub/Sub operations
  async publish(channel: string, message: string): Promise<number> {
    return this.publisher.publish(channel, message);
  }

  async subscribe(channel: string, callback: (message: string) => void): Promise<void> {
    await this.subscriber.subscribe(channel);
    this.subscriber.on('message', (receivedChannel, message) => {
      if (receivedChannel === channel) {
        callback(message);
      }
    });
  }

  // Cache patterns
  async getOrSet<T>(
    key: string,
    factory: () => Promise<T>,
    options: CacheOptions = {}
  ): Promise<T> {
    const cached = await this.get<T>(key, options);

    if (cached !== null) {
      return cached;
    }

    const value = await factory();
    await this.set(key, value, options);
    return value;
  }

  async invalidatePattern(pattern: string): Promise<number> {
    const keys = await this.client.keys(pattern);
    if (keys.length === 0) return 0;
    return this.client.del(...keys);
  }

  private buildKey(key: string, prefix?: string): string {
    return prefix ? `${prefix}:${key}` : key;
  }
}
```

## Migration Patterns

### Prisma Migrations
```typescript
// libs/api/database/src/migrations/migration.service.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Injectable()
export class MigrationService {
  constructor(private prisma: PrismaService) {}

  async runDataMigration(migrationName: string): Promise<void> {
    console.log(`Starting data migration: ${migrationName}`);

    try {
      switch (migrationName) {
        case 'add-default-tags':
          await this.addDefaultTags();
          break;
        case 'migrate-user-settings':
          await this.migrateUserSettings();
          break;
        default:
          throw new Error(`Unknown migration: ${migrationName}`);
      }

      console.log(`Completed data migration: ${migrationName}`);
    } catch (error) {
      console.error(`Failed data migration: ${migrationName}`, error);
      throw error;
    }
  }

  private async addDefaultTags(): Promise<void> {
    const defaultTags = [
      { name: 'urgent', color: '#red' },
      { name: 'feature', color: '#blue' },
      { name: 'bug', color: '#orange' },
      { name: 'enhancement', color: '#green' }
    ];

    await this.prisma.tag.createMany({
      data: defaultTags,
      skipDuplicates: true
    });
  }

  private async migrateUserSettings(): Promise<void> {
    const users = await this.prisma.user.findMany({
      where: {
        profile: null
      }
    });

    for (const user of users) {
      await this.prisma.userProfile.create({
        data: {
          userId: user.id,
          timezone: 'UTC',
          settings: {}
        }
      });
    }
  }
}
```

### Database Seeding
```typescript
// libs/api/database/src/seeds/seed.service.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { faker } from '@faker-js/faker';

@Injectable()
export class SeedService {
  constructor(private prisma: PrismaService) {}

  async seedDatabase(): Promise<void> {
    console.log('Starting database seeding...');

    await this.clearDatabase();
    await this.seedUsers();
    await this.seedTags();
    await this.seedTasks();

    console.log('Database seeding completed');
  }

  private async clearDatabase(): Promise<void> {
    await this.prisma.taskTag.deleteMany();
    await this.prisma.task.deleteMany();
    await this.prisma.tag.deleteMany();
    await this.prisma.userProfile.deleteMany();
    await this.prisma.user.deleteMany();
  }

  private async seedUsers(): Promise<void> {
    const users = Array.from({ length: 10 }, () => ({
      email: faker.internet.email(),
      name: faker.person.fullName(),
      avatar: faker.image.avatar(),
      profile: {
        create: {
          bio: faker.lorem.sentence(),
          timezone: faker.location.timeZone(),
          settings: {
            theme: faker.helpers.arrayElement(['light', 'dark']),
            notifications: faker.datatype.boolean()
          }
        }
      }
    }));

    for (const userData of users) {
      await this.prisma.user.create({
        data: userData
      });
    }
  }

  private async seedTags(): Promise<void> {
    const tags = [
      { name: 'urgent', color: '#ef4444' },
      { name: 'feature', color: '#3b82f6' },
      { name: 'bug', color: '#f97316' },
      { name: 'enhancement', color: '#10b981' },
      { name: 'documentation', color: '#8b5cf6' }
    ];

    await this.prisma.tag.createMany({
      data: tags
    });
  }

  private async seedTasks(): Promise<void> {
    const users = await this.prisma.user.findMany();
    const tags = await this.prisma.tag.findMany();

    for (let i = 0; i < 50; i++) {
      const task = await this.prisma.task.create({
        data: {
          title: faker.lorem.sentence(),
          description: faker.lorem.paragraph(),
          status: faker.helpers.arrayElement(['TODO', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED']),
          priority: faker.helpers.arrayElement(['LOW', 'MEDIUM', 'HIGH']),
          dueDate: faker.date.future(),
          assigneeId: faker.helpers.arrayElement(users).id
        }
      });

      // Add random tags
      const randomTags = faker.helpers.arrayElements(tags, { min: 0, max: 3 });
      for (const tag of randomTags) {
        await this.prisma.taskTag.create({
          data: {
            taskId: task.id,
            tagId: tag.id
          }
        });
      }
    }
  }
}
```

## Best Practices

### Connection Management
- **Connection Pooling**: Configure appropriate connection pool sizes
- **Connection Lifecycle**: Properly initialize and cleanup connections
- **Error Handling**: Implement robust error handling for connection failures
- **Health Checks**: Monitor database connection health

### Performance Optimization
- **Indexing**: Create appropriate database indexes for query performance
- **Query Optimization**: Use explain plans to optimize slow queries
- **Batch Operations**: Use batch operations for bulk data processing
- **Caching**: Implement multi-level caching strategies

### Data Integrity
- **Transactions**: Use transactions for operations that must be atomic
- **Validation**: Implement both application and database-level validation
- **Constraints**: Use database constraints to ensure data integrity
- **Soft Deletes**: Consider soft deletes for important data

### Security Considerations
- **SQL Injection**: Use parameterized queries and ORM protections
- **Access Control**: Implement proper database access controls
- **Encryption**: Encrypt sensitive data at rest and in transit
- **Audit Logging**: Log database operations for security auditing

This database integration patterns template provides comprehensive guidance for working with multiple database technologies within our NX monorepo structure.

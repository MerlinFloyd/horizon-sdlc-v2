# Event-Driven Architecture Patterns Template

## Overview
This template provides comprehensive patterns for implementing event-driven architecture using Google Cloud Pub/Sub messaging, message contracts, event versioning, and reliable event processing within our NX monorepo structure.

## Google Cloud Pub/Sub Integration

### Basic Pub/Sub Setup
```typescript
// libs/shared/messaging/src/pubsub/client.ts
import { PubSub, Topic, Subscription } from '@google-cloud/pubsub';
import { Injectable } from '@nestjs/common';

export interface PubSubConfig {
  projectId: string;
  keyFilename?: string;
  credentials?: any;
}

@Injectable()
export class PubSubClient {
  private client: PubSub;
  private topics = new Map<string, Topic>();
  private subscriptions = new Map<string, Subscription>();

  constructor(private config: PubSubConfig) {
    this.client = new PubSub({
      projectId: config.projectId,
      keyFilename: config.keyFilename,
      credentials: config.credentials
    });
  }

  async createTopic(topicName: string): Promise<Topic> {
    if (this.topics.has(topicName)) {
      return this.topics.get(topicName)!;
    }

    const [topic] = await this.client.topic(topicName).get({ autoCreate: true });
    this.topics.set(topicName, topic);
    return topic;
  }

  async createSubscription(topicName: string, subscriptionName: string): Promise<Subscription> {
    const subscriptionKey = `${topicName}:${subscriptionName}`;
    
    if (this.subscriptions.has(subscriptionKey)) {
      return this.subscriptions.get(subscriptionKey)!;
    }

    const topic = await this.createTopic(topicName);
    const [subscription] = await topic.subscription(subscriptionName).get({ autoCreate: true });
    
    this.subscriptions.set(subscriptionKey, subscription);
    return subscription;
  }

  async publishMessage<T>(topicName: string, data: T, attributes?: Record<string, string>): Promise<string> {
    const topic = await this.createTopic(topicName);
    const message = {
      data: Buffer.from(JSON.stringify(data)),
      attributes: {
        ...attributes,
        timestamp: new Date().toISOString(),
        messageId: this.generateMessageId()
      }
    };

    const messageId = await topic.publishMessage(message);
    return messageId;
  }

  async subscribe<T>(
    topicName: string, 
    subscriptionName: string, 
    handler: (message: T, ack: () => void, nack: () => void) => Promise<void>
  ): Promise<void> {
    const subscription = await this.createSubscription(topicName, subscriptionName);
    
    subscription.on('message', async (message) => {
      try {
        const data = JSON.parse(message.data.toString()) as T;
        await handler(data, () => message.ack(), () => message.nack());
      } catch (error) {
        console.error('Error processing message:', error);
        message.nack();
      }
    });

    subscription.on('error', (error) => {
      console.error('Subscription error:', error);
    });
  }

  private generateMessageId(): string {
    return `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}
```

## Message Contracts and Versioning

### Base Message Contract
```typescript
// libs/shared/messaging/src/contracts/base-message.ts
export interface BaseMessage {
  messageId: string;
  timestamp: string;
  version: string;
  source: string;
  type: string;
  correlationId?: string;
  causationId?: string;
  metadata?: Record<string, any>;
}

export interface DomainMessage<T = any> extends BaseMessage {
  data: T;
  domain: string;
  aggregate?: {
    id: string;
    type: string;
    version: number;
  };
}

// Context-specific extensions
export interface ClientContext {
  clientId: string;
  companyId?: string;
  userId?: string;
  sessionId?: string;
}

export interface BlockchainContext {
  network: 'ethereum' | 'polygon' | 'solana';
  contractAddress?: string;
  transactionHash?: string;
  blockNumber?: number;
}

export interface ApplicationContext {
  applicationId: string;
  environment: 'test' | 'production';
  region?: string;
  instanceId?: string;
}

export interface ExtendedMessage<T = any> extends DomainMessage<T> {
  context: {
    client?: ClientContext;
    blockchain?: BlockchainContext;
    application: ApplicationContext;
  };
}
```

### Message Contract Versioning
```typescript
// libs/shared/messaging/src/contracts/versioning.ts
export interface MessageSchema {
  version: string;
  schema: any; // JSON Schema
  migrations?: MessageMigration[];
}

export interface MessageMigration {
  fromVersion: string;
  toVersion: string;
  migrate: (oldMessage: any) => any;
}

export class MessageVersionManager {
  private schemas = new Map<string, Map<string, MessageSchema>>();

  registerSchema(messageType: string, schema: MessageSchema): void {
    if (!this.schemas.has(messageType)) {
      this.schemas.set(messageType, new Map());
    }
    
    this.schemas.get(messageType)!.set(schema.version, schema);
  }

  validateMessage(messageType: string, version: string, message: any): boolean {
    const typeSchemas = this.schemas.get(messageType);
    if (!typeSchemas) {
      throw new Error(`No schemas registered for message type: ${messageType}`);
    }

    const schema = typeSchemas.get(version);
    if (!schema) {
      throw new Error(`No schema found for ${messageType} version ${version}`);
    }

    // Implement JSON Schema validation here
    return true;
  }

  migrateMessage(messageType: string, message: any, targetVersion: string): any {
    const currentVersion = message.version;
    if (currentVersion === targetVersion) {
      return message;
    }

    const typeSchemas = this.schemas.get(messageType);
    if (!typeSchemas) {
      throw new Error(`No schemas registered for message type: ${messageType}`);
    }

    // Find migration path
    const migrationPath = this.findMigrationPath(messageType, currentVersion, targetVersion);
    
    let migratedMessage = message;
    for (const migration of migrationPath) {
      migratedMessage = migration.migrate(migratedMessage);
      migratedMessage.version = migration.toVersion;
    }

    return migratedMessage;
  }

  private findMigrationPath(messageType: string, fromVersion: string, toVersion: string): MessageMigration[] {
    // Implement migration path finding algorithm
    // This is a simplified version - in practice, you'd implement a graph traversal
    const typeSchemas = this.schemas.get(messageType);
    const migrations: MessageMigration[] = [];
    
    for (const schema of typeSchemas!.values()) {
      if (schema.migrations) {
        migrations.push(...schema.migrations);
      }
    }

    return migrations.filter(m => m.fromVersion === fromVersion && m.toVersion === toVersion);
  }
}
```

## Publisher/Subscriber Patterns

### Event Publisher
```typescript
// libs/shared/messaging/src/publishers/event-publisher.ts
import { Injectable } from '@nestjs/common';
import { PubSubClient } from '../pubsub/client';
import { ExtendedMessage, ApplicationContext } from '../contracts/base-message';

export interface PublishOptions {
  topic?: string;
  attributes?: Record<string, string>;
  delay?: number;
}

@Injectable()
export class EventPublisher {
  constructor(
    private pubSubClient: PubSubClient,
    private applicationContext: ApplicationContext
  ) {}

  async publishDomainEvent<T>(
    eventType: string,
    domain: string,
    data: T,
    options: PublishOptions = {}
  ): Promise<string> {
    const message: ExtendedMessage<T> = {
      messageId: this.generateMessageId(),
      timestamp: new Date().toISOString(),
      version: '1.0.0',
      source: this.applicationContext.applicationId,
      type: eventType,
      domain,
      data,
      context: {
        application: this.applicationContext
      }
    };

    const topicName = options.topic || this.getTopicName(domain, eventType);
    
    if (options.delay) {
      // Implement delayed publishing if needed
      await this.scheduleDelayedPublish(topicName, message, options.delay);
      return message.messageId;
    }

    return this.pubSubClient.publishMessage(topicName, message, options.attributes);
  }

  async publishIntegrationEvent<T>(
    eventType: string,
    data: T,
    correlationId?: string,
    options: PublishOptions = {}
  ): Promise<string> {
    const message: ExtendedMessage<T> = {
      messageId: this.generateMessageId(),
      timestamp: new Date().toISOString(),
      version: '1.0.0',
      source: this.applicationContext.applicationId,
      type: eventType,
      domain: 'integration',
      correlationId,
      data,
      context: {
        application: this.applicationContext
      }
    };

    const topicName = options.topic || this.getTopicName('integration', eventType);
    return this.pubSubClient.publishMessage(topicName, message, options.attributes);
  }

  private getTopicName(domain: string, eventType: string): string {
    const env = this.applicationContext.environment;
    return `${env}-${domain}-${eventType}`;
  }

  private generateMessageId(): string {
    return `evt_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private async scheduleDelayedPublish<T>(
    topicName: string,
    message: ExtendedMessage<T>,
    delayMs: number
  ): Promise<void> {
    // Implement delayed publishing using Cloud Scheduler or similar
    setTimeout(async () => {
      await this.pubSubClient.publishMessage(topicName, message);
    }, delayMs);
  }
}
```

### Event Subscriber
```typescript
// libs/shared/messaging/src/subscribers/event-subscriber.ts
import { Injectable } from '@nestjs/common';
import { PubSubClient } from '../pubsub/client';
import { ExtendedMessage } from '../contracts/base-message';

export interface SubscriptionConfig {
  topicName: string;
  subscriptionName: string;
  maxRetries?: number;
  retryDelay?: number;
  deadLetterTopic?: string;
  batchSize?: number;
  ackDeadline?: number;
}

export interface EventHandler<T = any> {
  handle(message: ExtendedMessage<T>): Promise<void>;
  canHandle(messageType: string): boolean;
  getHandlerName(): string;
}

@Injectable()
export class EventSubscriber {
  private handlers = new Map<string, EventHandler[]>();
  private activeSubscriptions = new Set<string>();

  constructor(private pubSubClient: PubSubClient) {}

  registerHandler<T>(messageType: string, handler: EventHandler<T>): void {
    if (!this.handlers.has(messageType)) {
      this.handlers.set(messageType, []);
    }

    this.handlers.get(messageType)!.push(handler);
  }

  async subscribe(config: SubscriptionConfig): Promise<void> {
    const subscriptionKey = `${config.topicName}:${config.subscriptionName}`;

    if (this.activeSubscriptions.has(subscriptionKey)) {
      console.warn(`Subscription ${subscriptionKey} is already active`);
      return;
    }

    await this.pubSubClient.subscribe<ExtendedMessage>(
      config.topicName,
      config.subscriptionName,
      async (message, ack, nack) => {
        await this.processMessage(message, ack, nack, config);
      }
    );

    this.activeSubscriptions.add(subscriptionKey);
    console.log(`Subscribed to ${subscriptionKey}`);
  }

  private async processMessage(
    message: ExtendedMessage,
    ack: () => void,
    nack: () => void,
    config: SubscriptionConfig
  ): Promise<void> {
    const handlers = this.handlers.get(message.type) || [];
    const applicableHandlers = handlers.filter(h => h.canHandle(message.type));

    if (applicableHandlers.length === 0) {
      console.warn(`No handlers found for message type: ${message.type}`);
      ack(); // Acknowledge to prevent redelivery
      return;
    }

    let retryCount = 0;
    const maxRetries = config.maxRetries || 3;

    while (retryCount <= maxRetries) {
      try {
        // Process message with all applicable handlers
        await Promise.all(
          applicableHandlers.map(handler =>
            this.executeHandler(handler, message)
          )
        );

        ack();
        return;
      } catch (error) {
        retryCount++;
        console.error(`Error processing message (attempt ${retryCount}/${maxRetries + 1}):`, error);

        if (retryCount > maxRetries) {
          // Send to dead letter queue if configured
          if (config.deadLetterTopic) {
            await this.sendToDeadLetterQueue(message, error, config.deadLetterTopic);
          }

          ack(); // Acknowledge to prevent infinite redelivery
          return;
        }

        // Wait before retry
        if (config.retryDelay) {
          await this.delay(config.retryDelay * retryCount);
        }
      }
    }

    nack(); // This shouldn't be reached, but just in case
  }

  private async executeHandler(handler: EventHandler, message: ExtendedMessage): Promise<void> {
    const startTime = Date.now();

    try {
      await handler.handle(message);
      const duration = Date.now() - startTime;
      console.log(`Handler ${handler.getHandlerName()} processed message in ${duration}ms`);
    } catch (error) {
      const duration = Date.now() - startTime;
      console.error(`Handler ${handler.getHandlerName()} failed after ${duration}ms:`, error);
      throw error;
    }
  }

  private async sendToDeadLetterQueue(
    message: ExtendedMessage,
    error: any,
    deadLetterTopic: string
  ): Promise<void> {
    const deadLetterMessage = {
      ...message,
      metadata: {
        ...message.metadata,
        deadLetterReason: error.message,
        deadLetterTimestamp: new Date().toISOString(),
        originalTopic: message.source
      }
    };

    try {
      await this.pubSubClient.publishMessage(deadLetterTopic, deadLetterMessage);
      console.log(`Message sent to dead letter queue: ${deadLetterTopic}`);
    } catch (dlqError) {
      console.error('Failed to send message to dead letter queue:', dlqError);
    }
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
```

## Dead Letter Queue Handling

### Dead Letter Queue Processor
```typescript
// libs/shared/messaging/src/dlq/dead-letter-processor.ts
import { Injectable } from '@nestjs/common';
import { PubSubClient } from '../pubsub/client';
import { ExtendedMessage } from '../contracts/base-message';

export interface DeadLetterRecord extends ExtendedMessage {
  metadata: {
    deadLetterReason: string;
    deadLetterTimestamp: string;
    originalTopic: string;
    retryCount?: number;
    lastRetryTimestamp?: string;
  };
}

export interface DeadLetterAction {
  action: 'retry' | 'discard' | 'manual_review' | 'requeue';
  targetTopic?: string;
  delay?: number;
  reason?: string;
}

@Injectable()
export class DeadLetterProcessor {
  constructor(private pubSubClient: PubSubClient) {}

  async processDeadLetterQueue(
    deadLetterTopic: string,
    processor: (record: DeadLetterRecord) => Promise<DeadLetterAction>
  ): Promise<void> {
    await this.pubSubClient.subscribe<DeadLetterRecord>(
      deadLetterTopic,
      `${deadLetterTopic}-processor`,
      async (record, ack, nack) => {
        try {
          const action = await processor(record);
          await this.executeAction(record, action);
          ack();
        } catch (error) {
          console.error('Error processing dead letter record:', error);
          nack();
        }
      }
    );
  }

  private async executeAction(record: DeadLetterRecord, action: DeadLetterAction): Promise<void> {
    switch (action.action) {
      case 'retry':
        await this.retryMessage(record, action);
        break;
      case 'requeue':
        await this.requeueMessage(record, action);
        break;
      case 'discard':
        console.log(`Discarding message ${record.messageId}: ${action.reason}`);
        break;
      case 'manual_review':
        await this.sendForManualReview(record, action);
        break;
      default:
        throw new Error(`Unknown action: ${action.action}`);
    }
  }

  private async retryMessage(record: DeadLetterRecord, action: DeadLetterAction): Promise<void> {
    const retryCount = (record.metadata.retryCount || 0) + 1;
    const originalTopic = record.metadata.originalTopic;

    // Remove dead letter metadata and add retry metadata
    const { deadLetterReason, deadLetterTimestamp, ...cleanMetadata } = record.metadata;

    const retryMessage: ExtendedMessage = {
      ...record,
      metadata: {
        ...cleanMetadata,
        retryCount,
        lastRetryTimestamp: new Date().toISOString(),
        retryReason: action.reason
      }
    };

    if (action.delay) {
      // Implement delayed retry
      setTimeout(async () => {
        await this.pubSubClient.publishMessage(originalTopic, retryMessage);
      }, action.delay);
    } else {
      await this.pubSubClient.publishMessage(originalTopic, retryMessage);
    }

    console.log(`Retrying message ${record.messageId} (attempt ${retryCount})`);
  }

  private async requeueMessage(record: DeadLetterRecord, action: DeadLetterAction): Promise<void> {
    const targetTopic = action.targetTopic || record.metadata.originalTopic;

    // Clean up dead letter metadata
    const { deadLetterReason, deadLetterTimestamp, ...cleanMetadata } = record.metadata;

    const requeuedMessage: ExtendedMessage = {
      ...record,
      metadata: {
        ...cleanMetadata,
        requeuedTimestamp: new Date().toISOString(),
        requeueReason: action.reason
      }
    };

    await this.pubSubClient.publishMessage(targetTopic, requeuedMessage);
    console.log(`Requeued message ${record.messageId} to ${targetTopic}`);
  }

  private async sendForManualReview(record: DeadLetterRecord, action: DeadLetterAction): Promise<void> {
    const reviewTopic = 'manual-review-queue';

    const reviewMessage = {
      ...record,
      metadata: {
        ...record.metadata,
        manualReviewTimestamp: new Date().toISOString(),
        reviewReason: action.reason
      }
    };

    await this.pubSubClient.publishMessage(reviewTopic, reviewMessage);
    console.log(`Sent message ${record.messageId} for manual review`);
  }
}
```

## NX Monorepo Integration

### Library Organization
```typescript
// libs/shared/messaging/src/index.ts
export * from './pubsub/client';
export * from './contracts/base-message';
export * from './contracts/versioning';
export * from './publishers/event-publisher';
export * from './subscribers/event-subscriber';
export * from './dlq/dead-letter-processor';
```

### Project Configuration
```json
// libs/shared/messaging/project.json
{
  "name": "shared-messaging",
  "sourceRoot": "libs/shared/messaging/src",
  "projectType": "library",
  "targets": {
    "build": {
      "executor": "@nx/js:tsc",
      "outputs": ["{options.outputPath}"],
      "options": {
        "outputPath": "dist/libs/shared/messaging",
        "main": "libs/shared/messaging/src/index.ts",
        "tsConfig": "libs/shared/messaging/tsconfig.lib.json"
      }
    },
    "test": {
      "executor": "@nx/jest:jest",
      "outputs": ["{workspaceRoot}/coverage/{projectRoot}"],
      "options": {
        "jestConfig": "libs/shared/messaging/jest.config.ts"
      }
    }
  },
  "tags": ["scope:shared", "type:util"]
}
```

### Application Integration Example
```typescript
// apps/api-core/src/events/task-events.ts
import { EventPublisher, EventSubscriber, EventHandler, ExtendedMessage } from '@shared/messaging';
import { Injectable } from '@nestjs/common';

export interface TaskCreatedEvent {
  taskId: string;
  userId: string;
  title: string;
  description: string;
  createdAt: string;
}

export interface TaskUpdatedEvent {
  taskId: string;
  userId: string;
  changes: Record<string, any>;
  updatedAt: string;
}

@Injectable()
export class TaskEventPublisher {
  constructor(private eventPublisher: EventPublisher) {}

  async publishTaskCreated(event: TaskCreatedEvent): Promise<void> {
    await this.eventPublisher.publishDomainEvent(
      'task-created',
      'tasks',
      event
    );
  }

  async publishTaskUpdated(event: TaskUpdatedEvent): Promise<void> {
    await this.eventPublisher.publishDomainEvent(
      'task-updated',
      'tasks',
      event
    );
  }
}

@Injectable()
export class TaskCreatedHandler implements EventHandler<TaskCreatedEvent> {
  canHandle(messageType: string): boolean {
    return messageType === 'task-created';
  }

  getHandlerName(): string {
    return 'TaskCreatedHandler';
  }

  async handle(message: ExtendedMessage<TaskCreatedEvent>): Promise<void> {
    const { data } = message;

    // Handle task creation event
    console.log(`Processing task created: ${data.taskId} by user ${data.userId}`);

    // Example: Send notification, update analytics, etc.
    await this.sendNotification(data);
    await this.updateAnalytics(data);
  }

  private async sendNotification(data: TaskCreatedEvent): Promise<void> {
    // Notification logic
  }

  private async updateAnalytics(data: TaskCreatedEvent): Promise<void> {
    // Analytics logic
  }
}
```

## Best Practices

### Message Design
- **Immutable Events**: Design events as immutable facts about what happened
- **Rich Events**: Include sufficient context to avoid requiring additional lookups
- **Backward Compatibility**: Use versioning to maintain backward compatibility
- **Idempotency**: Ensure event handlers are idempotent

### Error Handling
- **Retry Logic**: Implement exponential backoff for transient failures
- **Dead Letter Queues**: Use DLQs for messages that consistently fail
- **Circuit Breakers**: Implement circuit breakers for external service calls
- **Monitoring**: Monitor message processing metrics and error rates

### Performance Optimization
- **Batch Processing**: Process messages in batches when possible
- **Parallel Processing**: Use multiple subscribers for high-throughput scenarios
- **Message Filtering**: Use subscription filters to reduce unnecessary processing
- **Connection Pooling**: Reuse Pub/Sub connections and topics

### Security Considerations
- **Authentication**: Use service accounts with minimal required permissions
- **Encryption**: Encrypt sensitive data in message payloads
- **Access Control**: Implement proper IAM policies for topics and subscriptions
- **Audit Logging**: Log all message publishing and processing activities

This event-driven architecture template provides a robust foundation for building scalable, reliable messaging systems within our NX monorepo structure.


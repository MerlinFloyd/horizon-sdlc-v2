# API Design Patterns Template

## Overview
This template provides comprehensive patterns for designing RESTful APIs using Next.js API routes, OpenAPI 3.0 specification, error handling, validation, and response formatting within our NX monorepo structure.

## RESTful API Design Principles

### Resource-Based URL Structure
```typescript
// apps/web-dashboard/src/app/api/tasks/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';

// GET /api/tasks - List all tasks
export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const page = parseInt(searchParams.get('page') || '1');
  const limit = parseInt(searchParams.get('limit') || '10');
  const status = searchParams.get('status');

  try {
    const tasks = await taskService.findAll({
      page,
      limit,
      status: status as TaskStatus
    });

    return NextResponse.json(
      ApiResponseBuilder.success(tasks)
        .setPagination(page, limit, tasks.total)
        .setMessage('Tasks retrieved successfully')
        .build(),
      { status: 200 }
    );
  } catch (error) {
    return handleApiError(error);
  }
}

// POST /api/tasks - Create new task
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const validatedData = createTaskSchema.parse(body);
    
    const task = await taskService.create(validatedData);
    
    return NextResponse.json(
      ApiResponseBuilder.success(task)
        .setMessage('Task created successfully')
        .build(),
      { status: 201 }
    );
  } catch (error) {
    return handleApiError(error);
  }
}
```

### Dynamic Route Handlers
```typescript
// apps/web-dashboard/src/app/api/tasks/[id]/route.ts
import { NextRequest, NextResponse } from 'next/server';

interface RouteParams {
  params: { id: string };
}

// GET /api/tasks/[id] - Get specific task
export async function GET(request: NextRequest, { params }: RouteParams) {
  try {
    const task = await taskService.findById(params.id);
    
    if (!task) {
      return NextResponse.json(
        ApiResponseBuilder.error('Task not found')
          .build(),
        { status: 404 }
      );
    }

    return NextResponse.json(
      ApiResponseBuilder.success(task)
        .setMessage('Task retrieved successfully')
        .build(),
      { status: 200 }
    );
  } catch (error) {
    return handleApiError(error);
  }
}

// PUT /api/tasks/[id] - Update specific task
export async function PUT(request: NextRequest, { params }: RouteParams) {
  try {
    const body = await request.json();
    const validatedData = updateTaskSchema.parse(body);
    
    const task = await taskService.update(params.id, validatedData);
    
    return NextResponse.json(
      ApiResponseBuilder.success(task)
        .setMessage('Task updated successfully')
        .build(),
      { status: 200 }
    );
  } catch (error) {
    return handleApiError(error);
  }
}

// DELETE /api/tasks/[id] - Delete specific task
export async function DELETE(request: NextRequest, { params }: RouteParams) {
  try {
    await taskService.delete(params.id);
    
    return NextResponse.json(
      ApiResponseBuilder.success(null)
        .setMessage('Task deleted successfully')
        .build(),
      { status: 200 }
    );
  } catch (error) {
    return handleApiError(error);
  }
}
```

## Validation with Zod

### Request Validation Schemas
```typescript
// libs/shared/validation/src/schemas/task.schemas.ts
import { z } from 'zod';

export const createTaskSchema = z.object({
  title: z.string()
    .min(1, 'Title is required')
    .max(200, 'Title must be less than 200 characters'),
  description: z.string()
    .max(1000, 'Description must be less than 1000 characters')
    .optional(),
  priority: z.enum(['low', 'medium', 'high'])
    .default('medium'),
  dueDate: z.string()
    .datetime('Invalid date format')
    .optional(),
  assigneeId: z.string()
    .uuid('Invalid assignee ID')
    .optional(),
  tags: z.array(z.string())
    .max(10, 'Maximum 10 tags allowed')
    .default([]),
  metadata: z.record(z.any())
    .optional()
});

export const updateTaskSchema = createTaskSchema.partial().extend({
  status: z.enum(['todo', 'in_progress', 'completed', 'cancelled']).optional()
});

export const taskQuerySchema = z.object({
  page: z.coerce.number().min(1).default(1),
  limit: z.coerce.number().min(1).max(100).default(10),
  status: z.enum(['todo', 'in_progress', 'completed', 'cancelled']).optional(),
  priority: z.enum(['low', 'medium', 'high']).optional(),
  assigneeId: z.string().uuid().optional(),
  search: z.string().max(100).optional(),
  sortBy: z.enum(['createdAt', 'updatedAt', 'dueDate', 'priority']).default('createdAt'),
  sortOrder: z.enum(['asc', 'desc']).default('desc')
});

export type CreateTaskDto = z.infer<typeof createTaskSchema>;
export type UpdateTaskDto = z.infer<typeof updateTaskSchema>;
export type TaskQueryDto = z.infer<typeof taskQuerySchema>;
```

### Validation Middleware
```typescript
// libs/shared/validation/src/middleware/validation.middleware.ts
import { NextRequest, NextResponse } from 'next/server';
import { z, ZodError } from 'zod';
import { ApiResponseBuilder } from '@shared/patterns';

export function validateRequest<T>(schema: z.ZodSchema<T>) {
  return async (request: NextRequest): Promise<{ data: T; error?: never } | { data?: never; error: NextResponse }> => {
    try {
      let data: any;
      
      if (request.method === 'GET') {
        // Validate query parameters
        const { searchParams } = new URL(request.url);
        const queryObject = Object.fromEntries(searchParams.entries());
        data = schema.parse(queryObject);
      } else {
        // Validate request body
        const body = await request.json();
        data = schema.parse(body);
      }
      
      return { data };
    } catch (error) {
      if (error instanceof ZodError) {
        const validationErrors = error.errors.map(err => ({
          field: err.path.join('.'),
          message: err.message,
          code: err.code
        }));

        return {
          error: NextResponse.json(
            ApiResponseBuilder.error('Validation failed', validationErrors.map(e => e.message))
              .build(),
            { status: 400 }
          )
        };
      }
      
      return {
        error: NextResponse.json(
          ApiResponseBuilder.error('Invalid request data')
            .build(),
          { status: 400 }
        )
      };
    }
  };
}

// Usage example
export async function POST(request: NextRequest) {
  const validation = await validateRequest(createTaskSchema)(request);
  
  if (validation.error) {
    return validation.error;
  }
  
  const { data } = validation;
  // Proceed with validated data
}
```

## Error Handling Patterns

### Centralized Error Handler
```typescript
// libs/shared/api/src/error-handling/api-error-handler.ts
import { NextResponse } from 'next/server';
import { ApiResponseBuilder } from '@shared/patterns';
import { ZodError } from 'zod';

export class ApiError extends Error {
  constructor(
    public message: string,
    public statusCode: number = 500,
    public code?: string,
    public details?: any
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

export class ValidationError extends ApiError {
  constructor(message: string, details?: any) {
    super(message, 400, 'VALIDATION_ERROR', details);
  }
}

export class NotFoundError extends ApiError {
  constructor(resource: string) {
    super(`${resource} not found`, 404, 'NOT_FOUND');
  }
}

export class UnauthorizedError extends ApiError {
  constructor(message: string = 'Unauthorized') {
    super(message, 401, 'UNAUTHORIZED');
  }
}

export class ForbiddenError extends ApiError {
  constructor(message: string = 'Forbidden') {
    super(message, 403, 'FORBIDDEN');
  }
}

export class ConflictError extends ApiError {
  constructor(message: string) {
    super(message, 409, 'CONFLICT');
  }
}

export function handleApiError(error: unknown): NextResponse {
  console.error('API Error:', error);

  // Handle Zod validation errors
  if (error instanceof ZodError) {
    const validationErrors = error.errors.map(err => 
      `${err.path.join('.')}: ${err.message}`
    );
    
    return NextResponse.json(
      ApiResponseBuilder.error('Validation failed', validationErrors)
        .build(),
      { status: 400 }
    );
  }

  // Handle custom API errors
  if (error instanceof ApiError) {
    return NextResponse.json(
      ApiResponseBuilder.error(error.message)
        .build(),
      { status: error.statusCode }
    );
  }

  // Handle Prisma errors
  if (error && typeof error === 'object' && 'code' in error) {
    return handlePrismaError(error as any);
  }

  // Handle unknown errors
  return NextResponse.json(
    ApiResponseBuilder.error('Internal server error')
      .build(),
    { status: 500 }
  );
}

function handlePrismaError(error: any): NextResponse {
  switch (error.code) {
    case 'P2002':
      return NextResponse.json(
        ApiResponseBuilder.error('Resource already exists')
          .build(),
        { status: 409 }
      );
    case 'P2025':
      return NextResponse.json(
        ApiResponseBuilder.error('Resource not found')
          .build(),
        { status: 404 }
      );
    default:
      return NextResponse.json(
        ApiResponseBuilder.error('Database error')
          .build(),
        { status: 500 }
      );
  }
}
```

## OpenAPI 3.0 Specification

### API Documentation Generation
```typescript
// libs/shared/api/src/openapi/spec-generator.ts
import { OpenAPIV3 } from 'openapi-types';

export const apiSpec: OpenAPIV3.Document = {
  openapi: '3.0.0',
  info: {
    title: 'Horizon Task Management API',
    version: '1.0.0',
    description: 'RESTful API for task management within the Horizon platform',
    contact: {
      name: 'API Support',
      email: 'api-support@horizon.com'
    }
  },
  servers: [
    {
      url: 'https://api.horizon.com/v1',
      description: 'Production server'
    },
    {
      url: 'https://api-test.horizon.com/v1',
      description: 'Test server'
    }
  ],
  paths: {
    '/tasks': {
      get: {
        summary: 'List tasks',
        description: 'Retrieve a paginated list of tasks with optional filtering',
        parameters: [
          {
            name: 'page',
            in: 'query',
            schema: { type: 'integer', minimum: 1, default: 1 },
            description: 'Page number for pagination'
          },
          {
            name: 'limit',
            in: 'query',
            schema: { type: 'integer', minimum: 1, maximum: 100, default: 10 },
            description: 'Number of items per page'
          },
          {
            name: 'status',
            in: 'query',
            schema: {
              type: 'string',
              enum: ['todo', 'in_progress', 'completed', 'cancelled']
            },
            description: 'Filter by task status'
          }
        ],
        responses: {
          '200': {
            description: 'Tasks retrieved successfully',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/TaskListResponse' }
              }
            }
          },
          '400': {
            description: 'Invalid request parameters',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/ErrorResponse' }
              }
            }
          }
        },
        tags: ['Tasks']
      },
      post: {
        summary: 'Create task',
        description: 'Create a new task',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/CreateTaskRequest' }
            }
          }
        },
        responses: {
          '201': {
            description: 'Task created successfully',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/TaskResponse' }
              }
            }
          },
          '400': {
            description: 'Validation error',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/ErrorResponse' }
              }
            }
          }
        },
        tags: ['Tasks']
      }
    },
    '/tasks/{id}': {
      get: {
        summary: 'Get task by ID',
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'string', format: 'uuid' },
            description: 'Task ID'
          }
        ],
        responses: {
          '200': {
            description: 'Task retrieved successfully',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/TaskResponse' }
              }
            }
          },
          '404': {
            description: 'Task not found',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/ErrorResponse' }
              }
            }
          }
        },
        tags: ['Tasks']
      }
    }
  },
  components: {
    schemas: {
      Task: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          title: { type: 'string', maxLength: 200 },
          description: { type: 'string', maxLength: 1000 },
          status: {
            type: 'string',
            enum: ['todo', 'in_progress', 'completed', 'cancelled']
          },
          priority: { type: 'string', enum: ['low', 'medium', 'high'] },
          dueDate: { type: 'string', format: 'date-time', nullable: true },
          assigneeId: { type: 'string', format: 'uuid', nullable: true },
          tags: { type: 'array', items: { type: 'string' } },
          createdAt: { type: 'string', format: 'date-time' },
          updatedAt: { type: 'string', format: 'date-time' }
        },
        required: ['id', 'title', 'status', 'priority', 'createdAt', 'updatedAt']
      },
      CreateTaskRequest: {
        type: 'object',
        properties: {
          title: { type: 'string', minLength: 1, maxLength: 200 },
          description: { type: 'string', maxLength: 1000 },
          priority: { type: 'string', enum: ['low', 'medium', 'high'], default: 'medium' },
          dueDate: { type: 'string', format: 'date-time' },
          assigneeId: { type: 'string', format: 'uuid' },
          tags: { type: 'array', items: { type: 'string' }, maxItems: 10 }
        },
        required: ['title']
      },
      TaskResponse: {
        type: 'object',
        properties: {
          data: { $ref: '#/components/schemas/Task' },
          message: { type: 'string' },
          meta: {
            type: 'object',
            properties: {
              timestamp: { type: 'string', format: 'date-time' },
              requestId: { type: 'string' }
            }
          },
          status: { type: 'string', enum: ['success'] }
        },
        required: ['data', 'status']
      },
      TaskListResponse: {
        type: 'object',
        properties: {
          data: {
            type: 'array',
            items: { $ref: '#/components/schemas/Task' }
          },
          message: { type: 'string' },
          meta: {
            type: 'object',
            properties: {
              pagination: {
                type: 'object',
                properties: {
                  page: { type: 'integer' },
                  limit: { type: 'integer' },
                  total: { type: 'integer' },
                  totalPages: { type: 'integer' }
                }
              },
              timestamp: { type: 'string', format: 'date-time' },
              requestId: { type: 'string' }
            }
          },
          status: { type: 'string', enum: ['success'] }
        },
        required: ['data', 'status']
      },
      ErrorResponse: {
        type: 'object',
        properties: {
          error: { type: 'string' },
          errors: {
            type: 'array',
            items: { type: 'string' }
          },
          meta: {
            type: 'object',
            properties: {
              timestamp: { type: 'string', format: 'date-time' },
              requestId: { type: 'string' }
            }
          },
          status: { type: 'string', enum: ['error'] }
        },
        required: ['error', 'status']
      }
    },
    securitySchemes: {
      bearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT'
      }
    }
  },
  security: [
    {
      bearerAuth: []
    }
  ]
};
```

## Response Formatting Standards

### Consistent Response Structure
```typescript
// libs/shared/api/src/responses/api-response.types.ts
export interface ApiResponse<T = any> {
  data?: T;
  message?: string;
  errors?: string[];
  meta: {
    timestamp: string;
    requestId: string;
    pagination?: {
      page: number;
      limit: number;
      total: number;
      totalPages: number;
    };
  };
  status: 'success' | 'error' | 'warning';
}

export interface PaginatedResponse<T> extends ApiResponse<T[]> {
  meta: ApiResponse['meta'] & {
    pagination: {
      page: number;
      limit: number;
      total: number;
      totalPages: number;
    };
  };
}
```

### Response Helpers
```typescript
// libs/shared/api/src/responses/response-helpers.ts
import { NextResponse } from 'next/server';
import { ApiResponse, PaginatedResponse } from './api-response.types';

export class ResponseHelper {
  static success<T>(
    data: T,
    message?: string,
    status: number = 200
  ): NextResponse {
    const response: ApiResponse<T> = {
      data,
      message,
      status: 'success',
      meta: {
        timestamp: new Date().toISOString(),
        requestId: this.generateRequestId()
      }
    };

    return NextResponse.json(response, { status });
  }

  static paginated<T>(
    data: T[],
    page: number,
    limit: number,
    total: number,
    message?: string
  ): NextResponse {
    const response: PaginatedResponse<T> = {
      data,
      message,
      status: 'success',
      meta: {
        timestamp: new Date().toISOString(),
        requestId: this.generateRequestId(),
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit)
        }
      }
    };

    return NextResponse.json(response, { status: 200 });
  }

  static error(
    message: string,
    errors?: string[],
    status: number = 500
  ): NextResponse {
    const response: ApiResponse = {
      error: message,
      errors,
      status: 'error',
      meta: {
        timestamp: new Date().toISOString(),
        requestId: this.generateRequestId()
      }
    };

    return NextResponse.json(response, { status });
  }

  static created<T>(data: T, message?: string): NextResponse {
    return this.success(data, message, 201);
  }

  static noContent(message?: string): NextResponse {
    const response: ApiResponse = {
      message,
      status: 'success',
      meta: {
        timestamp: new Date().toISOString(),
        requestId: this.generateRequestId()
      }
    };

    return NextResponse.json(response, { status: 204 });
  }

  private static generateRequestId(): string {
    return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}
```

## NX Monorepo Integration

### Library Organization
```typescript
// libs/shared/api/src/index.ts
export * from './error-handling/api-error-handler';
export * from './responses/response-helpers';
export * from './responses/api-response.types';
export * from './openapi/spec-generator';
export * from './middleware/cors.middleware';
export * from './middleware/auth.middleware';
```

### Project Configuration
```json
// libs/shared/api/project.json
{
  "name": "shared-api",
  "sourceRoot": "libs/shared/api/src",
  "projectType": "library",
  "targets": {
    "build": {
      "executor": "@nx/js:tsc",
      "outputs": ["{options.outputPath}"],
      "options": {
        "outputPath": "dist/libs/shared/api",
        "main": "libs/shared/api/src/index.ts",
        "tsConfig": "libs/shared/api/tsconfig.lib.json"
      }
    },
    "test": {
      "executor": "@nx/jest:jest",
      "outputs": ["{workspaceRoot}/coverage/{projectRoot}"],
      "options": {
        "jestConfig": "libs/shared/api/jest.config.ts"
      }
    }
  },
  "tags": ["scope:shared", "type:util"]
}
```

### Application Integration
```typescript
// apps/web-dashboard/src/app/api/tasks/route.ts
import {
  handleApiError,
  ResponseHelper,
  validateRequest
} from '@shared/api';
import { createTaskSchema, taskQuerySchema } from '@shared/validation';
import { taskService } from '@api/services';

export async function GET(request: NextRequest) {
  const validation = await validateRequest(taskQuerySchema)(request);

  if (validation.error) {
    return validation.error;
  }

  try {
    const { data: query } = validation;
    const result = await taskService.findAll(query);

    return ResponseHelper.paginated(
      result.tasks,
      query.page,
      query.limit,
      result.total,
      'Tasks retrieved successfully'
    );
  } catch (error) {
    return handleApiError(error);
  }
}

export async function POST(request: NextRequest) {
  const validation = await validateRequest(createTaskSchema)(request);

  if (validation.error) {
    return validation.error;
  }

  try {
    const { data } = validation;
    const task = await taskService.create(data);

    return ResponseHelper.created(task, 'Task created successfully');
  } catch (error) {
    return handleApiError(error);
  }
}
```

## Best Practices

### API Design Principles
- **RESTful Resources**: Use nouns for resources, not verbs
- **HTTP Methods**: Use appropriate HTTP methods (GET, POST, PUT, DELETE, PATCH)
- **Status Codes**: Return meaningful HTTP status codes
- **Consistent Naming**: Use consistent naming conventions (camelCase for JSON)

### Error Handling Best Practices
- **Structured Errors**: Provide structured error responses with codes and details
- **Validation Errors**: Include field-level validation errors
- **Error Logging**: Log errors with sufficient context for debugging
- **User-Friendly Messages**: Provide clear, actionable error messages

### Performance Optimization
- **Pagination**: Implement cursor-based pagination for large datasets
- **Caching**: Use appropriate caching headers and strategies
- **Compression**: Enable gzip compression for responses
- **Rate Limiting**: Implement rate limiting to prevent abuse

### Security Considerations
- **Input Validation**: Validate all input data using schemas
- **Authentication**: Implement proper authentication mechanisms
- **Authorization**: Check permissions for each endpoint
- **CORS**: Configure CORS policies appropriately

### Documentation Standards
- **OpenAPI Spec**: Maintain up-to-date OpenAPI specifications
- **Examples**: Provide request/response examples
- **Error Codes**: Document all possible error codes and scenarios
- **Versioning**: Implement API versioning strategy

This API design patterns template provides a comprehensive foundation for building robust, well-documented APIs within our NX monorepo structure.


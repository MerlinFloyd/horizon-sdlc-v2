# Next.js Full-Stack Patterns Template

## Overview
This template provides comprehensive patterns for building full-stack applications with Next.js 14+, covering React Server Components, Client Components, state management with Zustand, App Router patterns, and middleware implementation within our NX monorepo structure.

## React Server Components Patterns

### Server Component Implementation
```typescript
// apps/web-dashboard/src/app/tasks/page.tsx
import { Suspense } from 'react';
import { TaskList } from './components/TaskList';
import { TaskFilters } from './components/TaskFilters';
import { TaskSkeleton } from './components/TaskSkeleton';

interface TasksPageProps {
  searchParams: {
    status?: string;
    priority?: string;
    page?: string;
  };
}

// Server Component - runs on the server
export default async function TasksPage({ searchParams }: TasksPageProps) {
  // Data fetching happens on the server
  const filters = {
    status: searchParams.status,
    priority: searchParams.priority,
    page: parseInt(searchParams.page || '1')
  };

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold">Tasks</h1>
        <TaskFilters />
      </div>
      
      <Suspense fallback={<TaskSkeleton />}>
        <TaskList filters={filters} />
      </Suspense>
    </div>
  );
}

// Generate metadata on the server
export async function generateMetadata({ searchParams }: TasksPageProps) {
  const status = searchParams.status;
  const title = status ? `${status} Tasks` : 'All Tasks';
  
  return {
    title: `${title} | Task Management`,
    description: 'Manage your tasks efficiently with our task management system'
  };
}
```

### Data Fetching in Server Components
```typescript
// apps/web-dashboard/src/app/tasks/components/TaskList.tsx
import { taskService } from '@api/services';
import { TaskCard } from './TaskCard';
import { Pagination } from '@shared/ui';

interface TaskListProps {
  filters: {
    status?: string;
    priority?: string;
    page: number;
  };
}

// Server Component for data fetching
export async function TaskList({ filters }: TaskListProps) {
  // This runs on the server
  const { tasks, total, totalPages } = await taskService.findAll({
    ...filters,
    limit: 10
  });

  if (tasks.length === 0) {
    return (
      <div className="text-center py-12">
        <p className="text-gray-500">No tasks found</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {tasks.map((task) => (
          <TaskCard key={task.id} task={task} />
        ))}
      </div>
      
      <Pagination
        currentPage={filters.page}
        totalPages={totalPages}
        total={total}
      />
    </div>
  );
}
```

## Client Components Patterns

### Interactive Client Component
```typescript
// apps/web-dashboard/src/app/tasks/components/TaskCard.tsx
'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { Task } from '@shared/types';
import { Button } from '@shared/ui';
import { useTaskActions } from '../hooks/useTaskActions';

interface TaskCardProps {
  task: Task;
}

export function TaskCard({ task }: TaskCardProps) {
  const [isExpanded, setIsExpanded] = useState(false);
  const { updateTask, deleteTask, isLoading } = useTaskActions();

  const handleStatusChange = async (newStatus: string) => {
    await updateTask(task.id, { status: newStatus });
  };

  const handleDelete = async () => {
    if (confirm('Are you sure you want to delete this task?')) {
      await deleteTask(task.id);
    }
  };

  return (
    <motion.div
      layout
      className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow"
      whileHover={{ y: -2 }}
      transition={{ type: 'spring', stiffness: 300 }}
    >
      <div className="flex justify-between items-start mb-4">
        <h3 className="text-lg font-semibold text-gray-900">{task.title}</h3>
        <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(task.status)}`}>
          {task.status}
        </span>
      </div>

      {isExpanded && (
        <motion.div
          initial={{ opacity: 0, height: 0 }}
          animate={{ opacity: 1, height: 'auto' }}
          exit={{ opacity: 0, height: 0 }}
          className="mb-4"
        >
          <p className="text-gray-600">{task.description}</p>
        </motion.div>
      )}

      <div className="flex justify-between items-center">
        <Button
          variant="ghost"
          size="sm"
          onClick={() => setIsExpanded(!isExpanded)}
        >
          {isExpanded ? 'Show Less' : 'Show More'}
        </Button>

        <div className="flex space-x-2">
          <Button
            variant="secondary"
            size="sm"
            onClick={() => handleStatusChange('completed')}
            disabled={isLoading || task.status === 'completed'}
          >
            Complete
          </Button>
          <Button
            variant="ghost"
            size="sm"
            onClick={handleDelete}
            disabled={isLoading}
            className="text-red-600 hover:text-red-700"
          >
            Delete
          </Button>
        </div>
      </div>
    </motion.div>
  );
}

function getStatusColor(status: string): string {
  switch (status) {
    case 'completed':
      return 'bg-green-100 text-green-800';
    case 'in_progress':
      return 'bg-blue-100 text-blue-800';
    case 'todo':
      return 'bg-gray-100 text-gray-800';
    default:
      return 'bg-gray-100 text-gray-800';
  }
}
```

## State Management with Zustand

### Global State Store
```typescript
// libs/shared/state/src/stores/task.store.ts
import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';
import { Task, CreateTaskDto, UpdateTaskDto } from '@shared/types';
import { taskService } from '@api/services';

interface TaskState {
  tasks: Task[];
  selectedTask: Task | null;
  filters: {
    status?: string;
    priority?: string;
    search?: string;
  };
  isLoading: boolean;
  error: string | null;
}

interface TaskActions {
  // Task operations
  fetchTasks: () => Promise<void>;
  createTask: (data: CreateTaskDto) => Promise<void>;
  updateTask: (id: string, data: UpdateTaskDto) => Promise<void>;
  deleteTask: (id: string) => Promise<void>;
  
  // Selection
  selectTask: (task: Task | null) => void;
  
  // Filters
  setFilters: (filters: Partial<TaskState['filters']>) => void;
  clearFilters: () => void;
  
  // UI state
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;
}

type TaskStore = TaskState & TaskActions;

export const useTaskStore = create<TaskStore>()(
  devtools(
    persist(
      (set, get) => ({
        // Initial state
        tasks: [],
        selectedTask: null,
        filters: {},
        isLoading: false,
        error: null,

        // Actions
        fetchTasks: async () => {
          set({ isLoading: true, error: null });
          try {
            const { filters } = get();
            const response = await taskService.findAll(filters);
            set({ tasks: response.tasks, isLoading: false });
          } catch (error) {
            set({ 
              error: error instanceof Error ? error.message : 'Failed to fetch tasks',
              isLoading: false 
            });
          }
        },

        createTask: async (data: CreateTaskDto) => {
          set({ isLoading: true, error: null });
          try {
            const newTask = await taskService.create(data);
            set(state => ({
              tasks: [newTask, ...state.tasks],
              isLoading: false
            }));
          } catch (error) {
            set({ 
              error: error instanceof Error ? error.message : 'Failed to create task',
              isLoading: false 
            });
          }
        },

        updateTask: async (id: string, data: UpdateTaskDto) => {
          set({ isLoading: true, error: null });
          try {
            const updatedTask = await taskService.update(id, data);
            set(state => ({
              tasks: state.tasks.map(task => 
                task.id === id ? updatedTask : task
              ),
              selectedTask: state.selectedTask?.id === id ? updatedTask : state.selectedTask,
              isLoading: false
            }));
          } catch (error) {
            set({ 
              error: error instanceof Error ? error.message : 'Failed to update task',
              isLoading: false 
            });
          }
        },

        deleteTask: async (id: string) => {
          set({ isLoading: true, error: null });
          try {
            await taskService.delete(id);
            set(state => ({
              tasks: state.tasks.filter(task => task.id !== id),
              selectedTask: state.selectedTask?.id === id ? null : state.selectedTask,
              isLoading: false
            }));
          } catch (error) {
            set({ 
              error: error instanceof Error ? error.message : 'Failed to delete task',
              isLoading: false 
            });
          }
        },

        selectTask: (task: Task | null) => {
          set({ selectedTask: task });
        },

        setFilters: (newFilters: Partial<TaskState['filters']>) => {
          set(state => ({
            filters: { ...state.filters, ...newFilters }
          }));
        },

        clearFilters: () => {
          set({ filters: {} });
        },

        setLoading: (loading: boolean) => {
          set({ isLoading: loading });
        },

        setError: (error: string | null) => {
          set({ error });
        }
      }),
      {
        name: 'task-store',
        partialize: (state) => ({ 
          filters: state.filters,
          selectedTask: state.selectedTask 
        })
      }
    ),
    { name: 'task-store' }
  )
);
```

### Custom Hook for Task Actions
```typescript
// apps/web-dashboard/src/app/tasks/hooks/useTaskActions.ts
import { useTaskStore } from '@shared/state';
import { useRouter } from 'next/navigation';
import { toast } from 'sonner';

export function useTaskActions() {
  const router = useRouter();
  const {
    createTask,
    updateTask,
    deleteTask,
    isLoading,
    error,
    setError
  } = useTaskStore();

  const handleCreateTask = async (data: CreateTaskDto) => {
    try {
      await createTask(data);
      toast.success('Task created successfully');
      router.refresh(); // Refresh server components
    } catch (error) {
      toast.error('Failed to create task');
    }
  };

  const handleUpdateTask = async (id: string, data: UpdateTaskDto) => {
    try {
      await updateTask(id, data);
      toast.success('Task updated successfully');
      router.refresh();
    } catch (error) {
      toast.error('Failed to update task');
    }
  };

  const handleDeleteTask = async (id: string) => {
    try {
      await deleteTask(id);
      toast.success('Task deleted successfully');
      router.refresh();
    } catch (error) {
      toast.error('Failed to delete task');
    }
  };

  return {
    createTask: handleCreateTask,
    updateTask: handleUpdateTask,
    deleteTask: handleDeleteTask,
    isLoading,
    error,
    clearError: () => setError(null)
  };
}

## App Router Patterns

### Dynamic Routes and Layouts
```typescript
// apps/web-dashboard/src/app/tasks/[id]/page.tsx
import { notFound } from 'next/navigation';
import { taskService } from '@api/services';
import { TaskDetail } from './components/TaskDetail';
import { TaskActions } from './components/TaskActions';

interface TaskPageProps {
  params: { id: string };
}

export default async function TaskPage({ params }: TaskPageProps) {
  const task = await taskService.findById(params.id);

  if (!task) {
    notFound();
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-4xl mx-auto">
        <TaskDetail task={task} />
        <TaskActions task={task} />
      </div>
    </div>
  );
}

export async function generateMetadata({ params }: TaskPageProps) {
  const task = await taskService.findById(params.id);

  if (!task) {
    return {
      title: 'Task Not Found'
    };
  }

  return {
    title: `${task.title} | Task Management`,
    description: task.description || 'Task details and management'
  };
}
```

### Nested Layouts
```typescript
// apps/web-dashboard/src/app/tasks/layout.tsx
import { Sidebar } from './components/Sidebar';
import { TaskProvider } from './providers/TaskProvider';

export default function TasksLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <TaskProvider>
      <div className="flex h-screen bg-gray-50">
        <Sidebar />
        <main className="flex-1 overflow-auto">
          {children}
        </main>
      </div>
    </TaskProvider>
  );
}
```

### Loading and Error Boundaries
```typescript
// apps/web-dashboard/src/app/tasks/loading.tsx
import { TaskSkeleton } from './components/TaskSkeleton';

export default function Loading() {
  return (
    <div className="container mx-auto px-4 py-8">
      <div className="animate-pulse">
        <div className="h-8 bg-gray-200 rounded w-1/4 mb-6"></div>
        <TaskSkeleton />
      </div>
    </div>
  );
}
```

```typescript
// apps/web-dashboard/src/app/tasks/error.tsx
'use client';

import { useEffect } from 'react';
import { Button } from '@shared/ui';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error('Tasks page error:', error);
  }, [error]);

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="text-center">
        <h2 className="text-2xl font-bold text-gray-900 mb-4">
          Something went wrong!
        </h2>
        <p className="text-gray-600 mb-6">
          We encountered an error while loading your tasks.
        </p>
        <Button onClick={reset}>
          Try again
        </Button>
      </div>
    </div>
  );
}
```

### Route Groups and Parallel Routes
```typescript
// apps/web-dashboard/src/app/(dashboard)/tasks/@modal/(..)tasks/[id]/edit/page.tsx
import { Modal } from '@shared/ui';
import { TaskEditForm } from '../../../components/TaskEditForm';

interface EditTaskModalProps {
  params: { id: string };
}

export default function EditTaskModal({ params }: EditTaskModalProps) {
  return (
    <Modal>
      <TaskEditForm taskId={params.id} />
    </Modal>
  );
}
```

## Middleware Implementation

### Authentication Middleware
```typescript
// apps/web-dashboard/src/middleware.ts
import { NextRequest, NextResponse } from 'next/server';
import { jwtVerify } from 'jose';

const JWT_SECRET = new TextEncoder().encode(process.env.JWT_SECRET);

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Skip middleware for public routes
  if (isPublicRoute(pathname)) {
    return NextResponse.next();
  }

  // Check for authentication token
  const token = request.cookies.get('auth-token')?.value;

  if (!token) {
    return redirectToLogin(request);
  }

  try {
    // Verify JWT token
    const { payload } = await jwtVerify(token, JWT_SECRET);

    // Add user info to request headers
    const requestHeaders = new Headers(request.headers);
    requestHeaders.set('x-user-id', payload.sub as string);
    requestHeaders.set('x-user-email', payload.email as string);
    requestHeaders.set('x-user-roles', JSON.stringify(payload.roles));

    // Check role-based access
    if (isAdminRoute(pathname) && !hasAdminRole(payload.roles as string[])) {
      return new NextResponse('Forbidden', { status: 403 });
    }

    return NextResponse.next({
      request: {
        headers: requestHeaders,
      },
    });
  } catch (error) {
    console.error('JWT verification failed:', error);
    return redirectToLogin(request);
  }
}

function isPublicRoute(pathname: string): boolean {
  const publicRoutes = ['/login', '/register', '/forgot-password', '/api/auth'];
  return publicRoutes.some(route => pathname.startsWith(route));
}

function isAdminRoute(pathname: string): boolean {
  return pathname.startsWith('/admin');
}

function hasAdminRole(roles: string[]): boolean {
  return roles.includes('admin');
}

function redirectToLogin(request: NextRequest): NextResponse {
  const loginUrl = new URL('/login', request.url);
  loginUrl.searchParams.set('from', request.nextUrl.pathname);
  return NextResponse.redirect(loginUrl);
}

export const config = {
  matcher: [
    '/((?!api|_next/static|_next/image|favicon.ico).*)',
  ],
};
```

### Rate Limiting Middleware
```typescript
// apps/web-dashboard/src/middleware/rate-limit.ts
import { NextRequest, NextResponse } from 'next/server';
import { Redis } from '@upstash/redis';

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL!,
  token: process.env.UPSTASH_REDIS_REST_TOKEN!,
});

interface RateLimitConfig {
  requests: number;
  window: number; // in seconds
}

const rateLimits: Record<string, RateLimitConfig> = {
  '/api/auth/login': { requests: 5, window: 900 }, // 5 requests per 15 minutes
  '/api/tasks': { requests: 100, window: 3600 }, // 100 requests per hour
  default: { requests: 1000, window: 3600 }, // 1000 requests per hour
};

export async function rateLimitMiddleware(request: NextRequest) {
  const ip = request.ip ?? '127.0.0.1';
  const { pathname } = request.nextUrl;

  const config = rateLimits[pathname] || rateLimits.default;
  const key = `rate_limit:${ip}:${pathname}`;

  try {
    const current = await redis.get<number>(key) || 0;

    if (current >= config.requests) {
      return new NextResponse('Too Many Requests', {
        status: 429,
        headers: {
          'Retry-After': config.window.toString(),
          'X-RateLimit-Limit': config.requests.toString(),
          'X-RateLimit-Remaining': '0',
          'X-RateLimit-Reset': (Date.now() + config.window * 1000).toString(),
        },
      });
    }

    // Increment counter
    await redis.incr(key);
    await redis.expire(key, config.window);

    return NextResponse.next();
  } catch (error) {
    console.error('Rate limiting error:', error);
    return NextResponse.next(); // Fail open
  }
}
```

## Best Practices

### Server vs Client Components
- **Server Components**: Use for data fetching, static content, and SEO-critical content
- **Client Components**: Use for interactivity, browser APIs, and state management
- **Composition**: Compose server and client components effectively
- **Data Flow**: Pass data from server to client components via props

### Performance Optimization
- **Streaming**: Use Suspense boundaries for progressive loading
- **Caching**: Leverage Next.js caching strategies (fetch cache, router cache)
- **Bundle Splitting**: Optimize client-side JavaScript bundles
- **Image Optimization**: Use Next.js Image component for optimized images

### State Management Guidelines
- **Local State**: Use useState for component-specific state
- **Global State**: Use Zustand for cross-component state
- **Server State**: Use React Query or SWR for server state management
- **URL State**: Use searchParams for shareable state

### Security Considerations
- **Authentication**: Implement proper authentication middleware
- **Authorization**: Check permissions at both middleware and component levels
- **CSRF Protection**: Use CSRF tokens for state-changing operations
- **Input Validation**: Validate all inputs on both client and server

This Next.js full-stack patterns template provides comprehensive guidance for building modern, performant applications within our NX monorepo structure.

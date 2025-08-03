# Jest Unit Testing Template

## Overview
This template provides Jest unit testing patterns following our quality standards with 80% coverage requirement, TypeScript support, and comprehensive test organization.

## Jest Configuration

### 1. Base Jest Configuration
```typescript
// jest.preset.js
const nxPreset = require('@nx/jest/preset').default;

module.exports = {
  ...nxPreset,
  collectCoverageFrom: [
    'src/**/*.{ts,tsx}',
    '!src/**/*.d.ts',
    '!src/**/*.stories.{ts,tsx}',
    '!src/**/*.spec.{ts,tsx}',
    '!src/**/*.test.{ts,tsx}',
    '!src/**/index.ts',
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },
  setupFilesAfterEnv: ['<rootDir>/src/test-setup.ts'],
  testEnvironment: 'jsdom',
  transform: {
    '^.+\\.(ts|tsx|js|jsx)$': ['ts-jest', {
      tsconfig: '<rootDir>/tsconfig.spec.json',
    }],
  },
  moduleNameMapping: {
    '^@shared/(.*)$': '<rootDir>/../../libs/shared/$1/src',
    '^@api/(.*)$': '<rootDir>/../../libs/api/$1/src',
    '^@web/(.*)$': '<rootDir>/../../libs/web/$1/src',
    '^@blockchain/(.*)$': '<rootDir>/../../libs/blockchain/$1/src',
  },
};
```

### 2. Test Setup Configuration
```typescript
// src/test-setup.ts
import '@testing-library/jest-dom';
import { configure } from '@testing-library/react';
import { server } from './mocks/server';

// Configure testing library
configure({ testIdAttribute: 'data-testid' });

// Mock environment variables
process.env.NODE_ENV = 'test';
process.env.DATABASE_URL = 'postgresql://test:test@localhost:5432/test';
process.env.REDIS_URL = 'redis://localhost:6379';

// Setup MSW
beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

// Mock console methods in tests
global.console = {
  ...console,
  warn: jest.fn(),
  error: jest.fn(),
};

// Mock fetch globally
global.fetch = jest.fn();

// Mock window.matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: jest.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: jest.fn(),
    removeListener: jest.fn(),
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    dispatchEvent: jest.fn(),
  })),
});
```

## Service Layer Testing

### 1. User Service Tests
```typescript
// libs/api/services/src/user/user.service.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { UserService } from './user.service';
import { UserRepository } from './user.repository';
import { CreateUserDto, UpdateUserDto, User } from '@shared/types';

describe('UserService', () => {
  let service: UserService;
  let repository: jest.Mocked<UserRepository>;

  const mockUser: User = {
    id: '1',
    email: 'test@example.com',
    name: 'Test User',
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  beforeEach(async () => {
    const mockRepository = {
      create: jest.fn(),
      findById: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
      findAll: jest.fn(),
      count: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UserService,
        {
          provide: UserRepository,
          useValue: mockRepository,
        },
      ],
    }).compile();

    service = module.get<UserService>(UserService);
    repository = module.get(UserRepository);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('createUser', () => {
    it('should create a user successfully', async () => {
      // Arrange
      const createUserDto: CreateUserDto = {
        email: 'test@example.com',
        name: 'Test User',
      };
      repository.create.mockResolvedValue(mockUser);

      // Act
      const result = await service.createUser(createUserDto);

      // Assert
      expect(repository.create).toHaveBeenCalledWith(createUserDto);
      expect(result).toEqual(mockUser);
    });

    it('should throw error when repository fails', async () => {
      // Arrange
      const createUserDto: CreateUserDto = {
        email: 'test@example.com',
        name: 'Test User',
      };
      repository.create.mockRejectedValue(new Error('Database error'));

      // Act & Assert
      await expect(service.createUser(createUserDto)).rejects.toThrow('Database error');
      expect(repository.create).toHaveBeenCalledWith(createUserDto);
    });
  });

  describe('getUserById', () => {
    it('should return user when found', async () => {
      // Arrange
      repository.findById.mockResolvedValue(mockUser);

      // Act
      const result = await service.getUserById('1');

      // Assert
      expect(repository.findById).toHaveBeenCalledWith('1');
      expect(result).toEqual(mockUser);
    });

    it('should return null when user not found', async () => {
      // Arrange
      repository.findById.mockResolvedValue(null);

      // Act
      const result = await service.getUserById('999');

      // Assert
      expect(repository.findById).toHaveBeenCalledWith('999');
      expect(result).toBeNull();
    });
  });

  describe('updateUser', () => {
    it('should update user successfully', async () => {
      // Arrange
      const updateUserDto: UpdateUserDto = {
        name: 'Updated Name',
      };
      const updatedUser = { ...mockUser, name: 'Updated Name' };
      repository.update.mockResolvedValue(updatedUser);

      // Act
      const result = await service.updateUser('1', updateUserDto);

      // Assert
      expect(repository.update).toHaveBeenCalledWith('1', updateUserDto);
      expect(result).toEqual(updatedUser);
    });
  });

  describe('deleteUser', () => {
    it('should delete user successfully', async () => {
      // Arrange
      repository.delete.mockResolvedValue();

      // Act
      await service.deleteUser('1');

      // Assert
      expect(repository.delete).toHaveBeenCalledWith('1');
    });
  });
});
```

### 2. Payment Service Tests with Mocking
```typescript
// libs/api/services/src/payment/payment.service.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { PaymentService } from './payment.service';
import { StripePaymentProcessor } from './processors/stripe.processor';
import { PaymentRepository } from './payment.repository';
import { PaymentStatus } from '@shared/types';

describe('PaymentService', () => {
  let service: PaymentService;
  let stripeProcessor: jest.Mocked<StripePaymentProcessor>;
  let repository: jest.Mocked<PaymentRepository>;

  beforeEach(async () => {
    const mockStripeProcessor = {
      processPayment: jest.fn(),
      refundPayment: jest.fn(),
      getPaymentStatus: jest.fn(),
    };

    const mockRepository = {
      create: jest.fn(),
      findById: jest.fn(),
      update: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PaymentService,
        {
          provide: StripePaymentProcessor,
          useValue: mockStripeProcessor,
        },
        {
          provide: PaymentRepository,
          useValue: mockRepository,
        },
      ],
    }).compile();

    service = module.get<PaymentService>(PaymentService);
    stripeProcessor = module.get(StripePaymentProcessor);
    repository = module.get(PaymentRepository);
  });

  describe('processPayment', () => {
    it('should process payment and save to database', async () => {
      // Arrange
      const paymentData = {
        amount: 100,
        currency: 'USD',
        userId: '1',
      };

      const stripeResult = {
        transactionId: 'pi_test123',
        status: 'success' as const,
        amount: 100,
        currency: 'USD',
        timestamp: new Date(),
      };

      const savedPayment = {
        id: '1',
        ...paymentData,
        transactionId: 'pi_test123',
        status: PaymentStatus.COMPLETED,
        createdAt: new Date(),
      };

      stripeProcessor.processPayment.mockResolvedValue(stripeResult);
      repository.create.mockResolvedValue(savedPayment);

      // Act
      const result = await service.processPayment(paymentData);

      // Assert
      expect(stripeProcessor.processPayment).toHaveBeenCalledWith(
        paymentData.amount,
        paymentData.currency,
        { userId: paymentData.userId }
      );
      expect(repository.create).toHaveBeenCalledWith({
        ...paymentData,
        transactionId: 'pi_test123',
        status: PaymentStatus.COMPLETED,
      });
      expect(result).toEqual(savedPayment);
    });

    it('should handle payment processor failure', async () => {
      // Arrange
      const paymentData = {
        amount: 100,
        currency: 'USD',
        userId: '1',
      };

      stripeProcessor.processPayment.mockRejectedValue(new Error('Stripe error'));

      // Act & Assert
      await expect(service.processPayment(paymentData)).rejects.toThrow('Stripe error');
      expect(repository.create).not.toHaveBeenCalled();
    });
  });
});
```

## React Component Testing

### 1. Button Component Tests
```typescript
// libs/shared/ui/src/components/button/button.spec.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { Button } from './button';

describe('Button', () => {
  it('should render with default variant and size', () => {
    render(<Button>Click me</Button>);
    
    const button = screen.getByRole('button', { name: /click me/i });
    expect(button).toBeInTheDocument();
    expect(button).toHaveClass('bg-primary', 'h-9', 'px-4', 'py-2');
  });

  it('should render with different variants', () => {
    const { rerender } = render(<Button variant="secondary">Secondary</Button>);
    expect(screen.getByRole('button')).toHaveClass('bg-secondary');

    rerender(<Button variant="destructive">Destructive</Button>);
    expect(screen.getByRole('button')).toHaveClass('bg-destructive');

    rerender(<Button variant="outline">Outline</Button>);
    expect(screen.getByRole('button')).toHaveClass('border', 'border-input');
  });

  it('should render with different sizes', () => {
    const { rerender } = render(<Button size="sm">Small</Button>);
    expect(screen.getByRole('button')).toHaveClass('h-8', 'px-3');

    rerender(<Button size="lg">Large</Button>);
    expect(screen.getByRole('button')).toHaveClass('h-10', 'px-8');

    rerender(<Button size="icon">🚀</Button>);
    expect(screen.getByRole('button')).toHaveClass('h-9', 'w-9');
  });

  it('should handle click events', () => {
    const handleClick = jest.fn();
    render(<Button onClick={handleClick}>Click me</Button>);
    
    fireEvent.click(screen.getByRole('button'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('should be disabled when disabled prop is true', () => {
    render(<Button disabled>Disabled</Button>);
    
    const button = screen.getByRole('button');
    expect(button).toBeDisabled();
    expect(button).toHaveClass('disabled:pointer-events-none', 'disabled:opacity-50');
  });

  it('should render as child component when asChild is true', () => {
    render(
      <Button asChild>
        <a href="/test">Link Button</a>
      </Button>
    );
    
    const link = screen.getByRole('link');
    expect(link).toBeInTheDocument();
    expect(link).toHaveAttribute('href', '/test');
    expect(link).toHaveClass('bg-primary');
  });

  it('should apply custom className', () => {
    render(<Button className="custom-class">Custom</Button>);
    
    const button = screen.getByRole('button');
    expect(button).toHaveClass('custom-class', 'bg-primary');
  });
});
```

### 2. Form Component Tests
```typescript
// libs/shared/ui/src/components/form/form.spec.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from './form';
import { Input } from '../input';
import { Button } from '../button';

const formSchema = z.object({
  email: z.string().email('Invalid email address'),
  name: z.string().min(2, 'Name must be at least 2 characters'),
});

type FormData = z.infer<typeof formSchema>;

const TestForm = ({ onSubmit }: { onSubmit: (data: FormData) => void }) => {
  const form = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      email: '',
      name: '',
    },
  });

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Email</FormLabel>
              <FormControl>
                <Input placeholder="Enter your email" {...field} />
              </FormControl>
              <FormDescription>
                We'll never share your email with anyone else.
              </FormDescription>
              <FormMessage />
            </FormItem>
          )}
        />
        <FormField
          control={form.control}
          name="name"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Name</FormLabel>
              <FormControl>
                <Input placeholder="Enter your name" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        <Button type="submit">Submit</Button>
      </form>
    </Form>
  );
};

describe('Form Components', () => {
  it('should render form fields correctly', () => {
    const mockSubmit = jest.fn();
    render(<TestForm onSubmit={mockSubmit} />);

    expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/name/i)).toBeInTheDocument();
    expect(screen.getByText(/we'll never share your email/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /submit/i })).toBeInTheDocument();
  });

  it('should show validation errors for invalid input', async () => {
    const mockSubmit = jest.fn();
    render(<TestForm onSubmit={mockSubmit} />);

    const submitButton = screen.getByRole('button', { name: /submit/i });
    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText(/invalid email address/i)).toBeInTheDocument();
      expect(screen.getByText(/name must be at least 2 characters/i)).toBeInTheDocument();
    });

    expect(mockSubmit).not.toHaveBeenCalled();
  });

  it('should submit form with valid data', async () => {
    const mockSubmit = jest.fn();
    render(<TestForm onSubmit={mockSubmit} />);

    const emailInput = screen.getByLabelText(/email/i);
    const nameInput = screen.getByLabelText(/name/i);
    const submitButton = screen.getByRole('button', { name: /submit/i });

    fireEvent.change(emailInput, { target: { value: 'test@example.com' } });
    fireEvent.change(nameInput, { target: { value: 'John Doe' } });
    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(mockSubmit).toHaveBeenCalledWith({
        email: 'test@example.com',
        name: 'John Doe',
      });
    });
  });

  it('should clear validation errors when input becomes valid', async () => {
    const mockSubmit = jest.fn();
    render(<TestForm onSubmit={mockSubmit} />);

    const emailInput = screen.getByLabelText(/email/i);
    const submitButton = screen.getByRole('button', { name: /submit/i });

    // Trigger validation error
    fireEvent.click(submitButton);
    await waitFor(() => {
      expect(screen.getByText(/invalid email address/i)).toBeInTheDocument();
    });

    // Fix the error
    fireEvent.change(emailInput, { target: { value: 'test@example.com' } });
    fireEvent.blur(emailInput);

    await waitFor(() => {
      expect(screen.queryByText(/invalid email address/i)).not.toBeInTheDocument();
    });
  });
});
```

## Utility Function Testing

### 1. Validation Utilities Tests
```typescript
// libs/shared/utils/src/validation/validation.spec.ts
import { validateEmail, validatePassword, validatePhoneNumber } from './validation';

describe('Validation Utilities', () => {
  describe('validateEmail', () => {
    it('should validate correct email addresses', () => {
      const validEmails = [
        'test@example.com',
        'user.name@domain.co.uk',
        'user+tag@example.org',
        'user123@test-domain.com',
      ];

      validEmails.forEach(email => {
        expect(validateEmail(email)).toBe(true);
      });
    });

    it('should reject invalid email addresses', () => {
      const invalidEmails = [
        'invalid-email',
        '@example.com',
        'user@',
        'user..name@example.com',
        'user@.com',
        '',
      ];

      invalidEmails.forEach(email => {
        expect(validateEmail(email)).toBe(false);
      });
    });
  });

  describe('validatePassword', () => {
    it('should validate strong passwords', () => {
      const strongPasswords = [
        'Password123!',
        'MyStr0ngP@ssw0rd',
        'C0mpl3x!P@ssw0rd',
      ];

      strongPasswords.forEach(password => {
        const result = validatePassword(password);
        expect(result.isValid).toBe(true);
        expect(result.errors).toHaveLength(0);
      });
    });

    it('should reject weak passwords', () => {
      const weakPasswords = [
        { password: 'weak', expectedErrors: ['too short', 'no uppercase', 'no number'] },
        { password: 'password', expectedErrors: ['no uppercase', 'no number'] },
        { password: 'PASSWORD123', expectedErrors: ['no lowercase'] },
        { password: 'Password', expectedErrors: ['no number'] },
      ];

      weakPasswords.forEach(({ password, expectedErrors }) => {
        const result = validatePassword(password);
        expect(result.isValid).toBe(false);
        expectedErrors.forEach(error => {
          expect(result.errors.some(e => e.includes(error))).toBe(true);
        });
      });
    });
  });
});
```

## Test Data Factories

### 1. User Test Data Factory
```typescript
// libs/shared/utils/src/test-factories/user.factory.ts
import { faker } from '@faker-js/faker';
import { User, CreateUserDto } from '@shared/types';

export class UserFactory {
  static create(overrides: Partial<User> = {}): User {
    return {
      id: faker.string.uuid(),
      email: faker.internet.email(),
      name: faker.person.fullName(),
      createdAt: faker.date.past(),
      updatedAt: faker.date.recent(),
      ...overrides,
    };
  }

  static createMany(count: number, overrides: Partial<User> = {}): User[] {
    return Array.from({ length: count }, () => this.create(overrides));
  }

  static createDto(overrides: Partial<CreateUserDto> = {}): CreateUserDto {
    return {
      email: faker.internet.email(),
      name: faker.person.fullName(),
      ...overrides,
    };
  }

  static createWithEmail(email: string): User {
    return this.create({ email });
  }

  static createAdmin(): User {
    return this.create({
      email: 'admin@example.com',
      name: 'Admin User',
    });
  }
}
```

## Test Utilities

### 1. Custom Render Function
```typescript
// libs/shared/utils/src/test-utils/render.tsx
import React, { ReactElement } from 'react';
import { render, RenderOptions } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ThemeProvider } from 'next-themes';

interface CustomRenderOptions extends Omit<RenderOptions, 'wrapper'> {
  queryClient?: QueryClient;
}

const createTestQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

const AllTheProviders = ({ 
  children, 
  queryClient = createTestQueryClient() 
}: { 
  children: React.ReactNode;
  queryClient?: QueryClient;
}) => {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider attribute="class" defaultTheme="light">
        {children}
      </ThemeProvider>
    </QueryClientProvider>
  );
};

const customRender = (
  ui: ReactElement,
  { queryClient, ...options }: CustomRenderOptions = {}
) => {
  return render(ui, {
    wrapper: ({ children }) => (
      <AllTheProviders queryClient={queryClient}>{children}</AllTheProviders>
    ),
    ...options,
  });
};

export * from '@testing-library/react';
export { customRender as render };
```

## Coverage and Quality Gates

### 1. Coverage Configuration
```json
// jest.config.js coverage settings
{
  "collectCoverageFrom": [
    "src/**/*.{ts,tsx}",
    "!src/**/*.d.ts",
    "!src/**/*.stories.{ts,tsx}",
    "!src/**/index.ts"
  ],
  "coverageThreshold": {
    "global": {
      "branches": 80,
      "functions": 80,
      "lines": 80,
      "statements": 80
    },
    "./src/components/": {
      "branches": 85,
      "functions": 85,
      "lines": 85,
      "statements": 85
    },
    "./src/services/": {
      "branches": 90,
      "functions": 90,
      "lines": 90,
      "statements": 90
    }
  }
}
```

This template provides comprehensive Jest unit testing patterns with proper mocking, test organization, and coverage requirements aligned with our quality standards.

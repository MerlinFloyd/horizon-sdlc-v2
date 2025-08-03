# Playwright E2E Testing Template

## Overview
This template provides Playwright end-to-end testing patterns following our testing standards with visual regression testing, ephemeral environments, and comprehensive test organization.

## Playwright Configuration

### 1. Base Playwright Configuration
```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html'],
    ['json', { outputFile: 'test-results/results.json' }],
    ['junit', { outputFile: 'test-results/results.xml' }],
  ],
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] },
    },
  ],
  webServer: {
    command: 'npm run start:e2e',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120 * 1000,
  },
  expect: {
    timeout: 10 * 1000,
    toHaveScreenshot: {
      mode: 'strict',
      threshold: 0.2,
    },
    toMatchSnapshot: {
      threshold: 0.2,
    },
  },
  outputDir: 'test-results/',
});
```

### 2. Test Environment Setup
```typescript
// e2e/setup/global-setup.ts
import { chromium, FullConfig } from '@playwright/test';

async function globalSetup(config: FullConfig) {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  
  // Setup test database
  await page.goto(`${process.env.BASE_URL}/api/test/setup`);
  await page.waitForResponse(response => 
    response.url().includes('/api/test/setup') && response.status() === 200
  );
  
  // Create test users
  await page.goto(`${process.env.BASE_URL}/api/test/seed-users`);
  await page.waitForResponse(response => 
    response.url().includes('/api/test/seed-users') && response.status() === 200
  );
  
  await browser.close();
}

export default globalSetup;
```

### 3. Test Teardown
```typescript
// e2e/setup/global-teardown.ts
import { chromium, FullConfig } from '@playwright/test';

async function globalTeardown(config: FullConfig) {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  
  // Cleanup test database
  await page.goto(`${process.env.BASE_URL}/api/test/cleanup`);
  await page.waitForResponse(response => 
    response.url().includes('/api/test/cleanup') && response.status() === 200
  );
  
  await browser.close();
}

export default globalTeardown;
```

## Page Object Model

### 1. Base Page Class
```typescript
// e2e/pages/base.page.ts
import { Page, Locator, expect } from '@playwright/test';

export abstract class BasePage {
  protected page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async goto(path: string = '') {
    await this.page.goto(path);
    await this.waitForPageLoad();
  }

  async waitForPageLoad() {
    await this.page.waitForLoadState('networkidle');
  }

  async takeScreenshot(name: string) {
    await expect(this.page).toHaveScreenshot(`${name}.png`);
  }

  async clickAndWait(locator: Locator, waitForSelector?: string) {
    await locator.click();
    if (waitForSelector) {
      await this.page.waitForSelector(waitForSelector);
    }
  }

  async fillAndBlur(locator: Locator, value: string) {
    await locator.fill(value);
    await locator.blur();
  }

  async waitForToast(message?: string) {
    const toast = this.page.locator('[data-testid="toast"]');
    await expect(toast).toBeVisible();
    if (message) {
      await expect(toast).toContainText(message);
    }
    return toast;
  }

  async waitForModal(title?: string) {
    const modal = this.page.locator('[role="dialog"]');
    await expect(modal).toBeVisible();
    if (title) {
      await expect(modal.locator('h2, h3')).toContainText(title);
    }
    return modal;
  }

  async closeModal() {
    const closeButton = this.page.locator('[role="dialog"] button[aria-label="Close"]');
    await closeButton.click();
    await expect(this.page.locator('[role="dialog"]')).not.toBeVisible();
  }
}
```

### 2. Login Page Object
```typescript
// e2e/pages/login.page.ts
import { Page, Locator, expect } from '@playwright/test';
import { BasePage } from './base.page';

export class LoginPage extends BasePage {
  private readonly emailInput: Locator;
  private readonly passwordInput: Locator;
  private readonly loginButton: Locator;
  private readonly errorMessage: Locator;
  private readonly forgotPasswordLink: Locator;

  constructor(page: Page) {
    super(page);
    this.emailInput = page.locator('[data-testid="email-input"]');
    this.passwordInput = page.locator('[data-testid="password-input"]');
    this.loginButton = page.locator('[data-testid="login-button"]');
    this.errorMessage = page.locator('[data-testid="error-message"]');
    this.forgotPasswordLink = page.locator('[data-testid="forgot-password-link"]');
  }

  async goto() {
    await super.goto('/login');
  }

  async login(email: string, password: string) {
    await this.fillAndBlur(this.emailInput, email);
    await this.fillAndBlur(this.passwordInput, password);
    await this.loginButton.click();
  }

  async loginWithValidCredentials() {
    await this.login('test@example.com', 'Password123!');
    await this.page.waitForURL('/dashboard');
  }

  async expectLoginError(message: string) {
    await expect(this.errorMessage).toBeVisible();
    await expect(this.errorMessage).toContainText(message);
  }

  async expectLoginForm() {
    await expect(this.emailInput).toBeVisible();
    await expect(this.passwordInput).toBeVisible();
    await expect(this.loginButton).toBeVisible();
    await expect(this.forgotPasswordLink).toBeVisible();
  }

  async clickForgotPassword() {
    await this.forgotPasswordLink.click();
    await this.page.waitForURL('/forgot-password');
  }
}
```

### 3. Dashboard Page Object
```typescript
// e2e/pages/dashboard.page.ts
import { Page, Locator, expect } from '@playwright/test';
import { BasePage } from './base.page';

export class DashboardPage extends BasePage {
  private readonly userMenu: Locator;
  private readonly logoutButton: Locator;
  private readonly welcomeMessage: Locator;
  private readonly navigationMenu: Locator;
  private readonly statsCards: Locator;

  constructor(page: Page) {
    super(page);
    this.userMenu = page.locator('[data-testid="user-menu"]');
    this.logoutButton = page.locator('[data-testid="logout-button"]');
    this.welcomeMessage = page.locator('[data-testid="welcome-message"]');
    this.navigationMenu = page.locator('[data-testid="navigation-menu"]');
    this.statsCards = page.locator('[data-testid="stats-card"]');
  }

  async goto() {
    await super.goto('/dashboard');
  }

  async expectDashboardLoaded() {
    await expect(this.welcomeMessage).toBeVisible();
    await expect(this.navigationMenu).toBeVisible();
    await expect(this.statsCards.first()).toBeVisible();
  }

  async logout() {
    await this.userMenu.click();
    await this.logoutButton.click();
    await this.page.waitForURL('/login');
  }

  async navigateToSection(section: string) {
    const navLink = this.navigationMenu.locator(`[data-testid="nav-${section}"]`);
    await navLink.click();
    await this.page.waitForURL(`/${section}`);
  }

  async getStatsCardValue(cardName: string): Promise<string> {
    const card = this.statsCards.filter({ hasText: cardName });
    const value = card.locator('[data-testid="stats-value"]');
    return await value.textContent() || '';
  }

  async expectStatsCard(cardName: string, expectedValue: string) {
    const actualValue = await this.getStatsCardValue(cardName);
    expect(actualValue).toBe(expectedValue);
  }
}
```

## Test Suites

### 1. Authentication Flow Tests
```typescript
// e2e/auth/login.spec.ts
import { test, expect } from '@playwright/test';
import { LoginPage } from '../pages/login.page';
import { DashboardPage } from '../pages/dashboard.page';

test.describe('Authentication', () => {
  let loginPage: LoginPage;
  let dashboardPage: DashboardPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    dashboardPage = new DashboardPage(page);
    await loginPage.goto();
  });

  test('should display login form correctly', async () => {
    await loginPage.expectLoginForm();
    await loginPage.takeScreenshot('login-form');
  });

  test('should login with valid credentials', async () => {
    await loginPage.loginWithValidCredentials();
    await dashboardPage.expectDashboardLoaded();
    await dashboardPage.takeScreenshot('dashboard-after-login');
  });

  test('should show error for invalid credentials', async () => {
    await loginPage.login('invalid@example.com', 'wrongpassword');
    await loginPage.expectLoginError('Invalid email or password');
    await loginPage.takeScreenshot('login-error');
  });

  test('should show validation errors for empty fields', async () => {
    await loginPage.login('', '');
    await expect(loginPage.page.locator('[data-testid="email-error"]')).toContainText('Email is required');
    await expect(loginPage.page.locator('[data-testid="password-error"]')).toContainText('Password is required');
  });

  test('should navigate to forgot password page', async () => {
    await loginPage.clickForgotPassword();
    await expect(loginPage.page).toHaveURL('/forgot-password');
  });

  test('should logout successfully', async () => {
    await loginPage.loginWithValidCredentials();
    await dashboardPage.logout();
    await expect(loginPage.page).toHaveURL('/login');
  });
});
```

### 2. User Management Tests
```typescript
// e2e/users/user-management.spec.ts
import { test, expect } from '@playwright/test';
import { LoginPage } from '../pages/login.page';
import { DashboardPage } from '../pages/dashboard.page';
import { UsersPage } from '../pages/users.page';

test.describe('User Management', () => {
  let loginPage: LoginPage;
  let dashboardPage: DashboardPage;
  let usersPage: UsersPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    dashboardPage = new DashboardPage(page);
    usersPage = new UsersPage(page);
    
    // Login as admin
    await loginPage.goto();
    await loginPage.loginWithValidCredentials();
    await dashboardPage.navigateToSection('users');
  });

  test('should display users list', async () => {
    await usersPage.expectUsersTableLoaded();
    await usersPage.takeScreenshot('users-list');
  });

  test('should create new user', async () => {
    const newUser = {
      name: 'John Doe',
      email: 'john.doe@example.com',
      role: 'User',
    };

    await usersPage.clickCreateUser();
    await usersPage.fillUserForm(newUser);
    await usersPage.submitUserForm();
    
    await usersPage.waitForToast('User created successfully');
    await usersPage.expectUserInTable(newUser.email);
    await usersPage.takeScreenshot('user-created');
  });

  test('should edit existing user', async () => {
    const updatedUser = {
      name: 'Jane Smith Updated',
      email: 'jane.smith@example.com',
      role: 'Admin',
    };

    await usersPage.editUser('jane.smith@example.com');
    await usersPage.fillUserForm(updatedUser);
    await usersPage.submitUserForm();
    
    await usersPage.waitForToast('User updated successfully');
    await usersPage.expectUserInTable(updatedUser.email, updatedUser.name);
  });

  test('should delete user with confirmation', async () => {
    const userEmail = 'delete.me@example.com';
    
    await usersPage.deleteUser(userEmail);
    await usersPage.confirmDeletion();
    
    await usersPage.waitForToast('User deleted successfully');
    await usersPage.expectUserNotInTable(userEmail);
  });

  test('should search and filter users', async () => {
    await usersPage.searchUsers('john');
    await usersPage.expectSearchResults(['john.doe@example.com']);
    
    await usersPage.clearSearch();
    await usersPage.filterByRole('Admin');
    await usersPage.expectFilteredResults('Admin');
  });

  test('should handle pagination', async () => {
    await usersPage.expectPaginationControls();
    await usersPage.goToNextPage();
    await usersPage.expectPageNumber(2);
    await usersPage.goToPreviousPage();
    await usersPage.expectPageNumber(1);
  });
});
```

### 3. Visual Regression Tests
```typescript
// e2e/visual/visual-regression.spec.ts
import { test, expect } from '@playwright/test';
import { LoginPage } from '../pages/login.page';
import { DashboardPage } from '../pages/dashboard.page';

test.describe('Visual Regression Tests', () => {
  test('should match login page design', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    
    // Wait for fonts and images to load
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(1000);
    
    await expect(page).toHaveScreenshot('login-page.png');
  });

  test('should match dashboard design', async ({ page }) => {
    const loginPage = new LoginPage(page);
    const dashboardPage = new DashboardPage(page);
    
    await loginPage.goto();
    await loginPage.loginWithValidCredentials();
    
    // Wait for dashboard to fully load
    await dashboardPage.expectDashboardLoaded();
    await page.waitForTimeout(1000);
    
    await expect(page).toHaveScreenshot('dashboard-page.png');
  });

  test('should match mobile responsive design', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(1000);
    
    await expect(page).toHaveScreenshot('login-page-mobile.png');
  });

  test('should match dark theme design', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    
    // Switch to dark theme
    await page.locator('[data-testid="theme-toggle"]').click();
    await page.waitForTimeout(500);
    
    await expect(page).toHaveScreenshot('login-page-dark.png');
  });
});
```

## Test Data Management

### 1. Test Data Factory
```typescript
// e2e/fixtures/test-data.ts
import { faker } from '@faker-js/faker';

export class TestDataFactory {
  static createUser(overrides: Partial<any> = {}) {
    return {
      name: faker.person.fullName(),
      email: faker.internet.email(),
      password: 'Password123!',
      role: 'User',
      ...overrides,
    };
  }

  static createAdmin() {
    return this.createUser({
      email: 'admin@example.com',
      role: 'Admin',
    });
  }

  static createProduct(overrides: Partial<any> = {}) {
    return {
      name: faker.commerce.productName(),
      description: faker.commerce.productDescription(),
      price: faker.commerce.price(),
      category: faker.commerce.department(),
      ...overrides,
    };
  }

  static createOrder(overrides: Partial<any> = {}) {
    return {
      customerEmail: faker.internet.email(),
      items: [this.createProduct()],
      total: faker.commerce.price(),
      status: 'pending',
      ...overrides,
    };
  }
}
```

### 2. Database Seeding
```typescript
// e2e/fixtures/database-seeder.ts
import { Page } from '@playwright/test';
import { TestDataFactory } from './test-data';

export class DatabaseSeeder {
  constructor(private page: Page) {}

  async seedUsers() {
    const users = [
      TestDataFactory.createAdmin(),
      TestDataFactory.createUser({ email: 'test@example.com' }),
      TestDataFactory.createUser({ email: 'jane.smith@example.com' }),
      TestDataFactory.createUser({ email: 'delete.me@example.com' }),
    ];

    for (const user of users) {
      await this.page.request.post('/api/test/users', {
        data: user,
      });
    }
  }

  async seedProducts() {
    const products = Array.from({ length: 10 }, () => TestDataFactory.createProduct());

    for (const product of products) {
      await this.page.request.post('/api/test/products', {
        data: product,
      });
    }
  }

  async cleanupDatabase() {
    await this.page.request.delete('/api/test/cleanup');
  }
}
```

## CI/CD Integration

### 1. GitHub Actions Workflow
```yaml
# .github/workflows/e2e-tests.yml
name: E2E Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  e2e-tests:
    timeout-minutes: 60
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: 18
          cache: 'npm'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Install Playwright Browsers
        run: npx playwright install --with-deps
        
      - name: Build application
        run: npm run build
        
      - name: Run E2E tests
        run: npm run test:e2e
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db
          BASE_URL: http://localhost:3000
          
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 30
```

This template provides comprehensive Playwright E2E testing patterns with visual regression testing, page object model, and proper test organization following our testing standards.

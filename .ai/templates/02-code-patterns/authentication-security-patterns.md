# Authentication & Security Patterns Template

## Overview
This template provides comprehensive patterns for implementing authentication and security using JWT, OAuth 2.0, RBAC, session management, and security middleware within our NX monorepo structure.

## JWT Implementation Patterns

### JWT Service
```typescript
// libs/shared/auth/src/jwt/jwt.service.ts
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as jwt from 'jsonwebtoken';
import * as bcrypt from 'bcrypt';

export interface JwtPayload {
  sub: string; // User ID
  email: string;
  roles: string[];
  permissions: string[];
  iat?: number;
  exp?: number;
  jti?: string; // JWT ID for revocation
}

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

@Injectable()
export class JwtService {
  private readonly accessTokenSecret: string;
  private readonly refreshTokenSecret: string;
  private readonly accessTokenExpiry: string;
  private readonly refreshTokenExpiry: string;

  constructor(private configService: ConfigService) {
    this.accessTokenSecret = this.configService.get('JWT_ACCESS_SECRET');
    this.refreshTokenSecret = this.configService.get('JWT_REFRESH_SECRET');
    this.accessTokenExpiry = this.configService.get('JWT_ACCESS_EXPIRY', '15m');
    this.refreshTokenExpiry = this.configService.get('JWT_REFRESH_EXPIRY', '7d');
  }

  async generateTokenPair(payload: Omit<JwtPayload, 'iat' | 'exp' | 'jti'>): Promise<TokenPair> {
    const jti = this.generateJti();
    
    const accessToken = jwt.sign(
      { ...payload, jti },
      this.accessTokenSecret,
      { 
        expiresIn: this.accessTokenExpiry,
        issuer: 'horizon-api',
        audience: 'horizon-client'
      }
    );

    const refreshToken = jwt.sign(
      { sub: payload.sub, jti },
      this.refreshTokenSecret,
      { 
        expiresIn: this.refreshTokenExpiry,
        issuer: 'horizon-api',
        audience: 'horizon-client'
      }
    );

    return {
      accessToken,
      refreshToken,
      expiresIn: this.parseExpiry(this.accessTokenExpiry)
    };
  }

  async verifyAccessToken(token: string): Promise<JwtPayload> {
    try {
      const payload = jwt.verify(token, this.accessTokenSecret, {
        issuer: 'horizon-api',
        audience: 'horizon-client'
      }) as JwtPayload;

      // Check if token is revoked
      await this.checkTokenRevocation(payload.jti!);
      
      return payload;
    } catch (error) {
      throw new Error('Invalid access token');
    }
  }

  async verifyRefreshToken(token: string): Promise<{ sub: string; jti: string }> {
    try {
      const payload = jwt.verify(token, this.refreshTokenSecret, {
        issuer: 'horizon-api',
        audience: 'horizon-client'
      }) as { sub: string; jti: string };

      // Check if token is revoked
      await this.checkTokenRevocation(payload.jti);
      
      return payload;
    } catch (error) {
      throw new Error('Invalid refresh token');
    }
  }

  async refreshTokens(refreshToken: string): Promise<TokenPair> {
    const { sub } = await this.verifyRefreshToken(refreshToken);
    
    // Get user data to regenerate payload
    const user = await this.getUserById(sub);
    if (!user) {
      throw new Error('User not found');
    }

    // Revoke old tokens
    await this.revokeToken(refreshToken);

    // Generate new token pair
    return this.generateTokenPair({
      sub: user.id,
      email: user.email,
      roles: user.roles,
      permissions: user.permissions
    });
  }

  async revokeToken(token: string): Promise<void> {
    try {
      const payload = jwt.decode(token) as { jti: string };
      if (payload?.jti) {
        // Store revoked token ID in Redis with expiration
        await this.storeRevokedToken(payload.jti);
      }
    } catch (error) {
      // Token might be malformed, but we still want to attempt revocation
      console.warn('Failed to decode token for revocation:', error);
    }
  }

  private generateJti(): string {
    return `jti_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private parseExpiry(expiry: string): number {
    const match = expiry.match(/^(\d+)([smhd])$/);
    if (!match) return 900; // Default 15 minutes

    const value = parseInt(match[1]);
    const unit = match[2];

    switch (unit) {
      case 's': return value;
      case 'm': return value * 60;
      case 'h': return value * 3600;
      case 'd': return value * 86400;
      default: return 900;
    }
  }

  private async checkTokenRevocation(jti: string): Promise<void> {
    // Check Redis for revoked token
    const isRevoked = await this.isTokenRevoked(jti);
    if (isRevoked) {
      throw new Error('Token has been revoked');
    }
  }

  private async storeRevokedToken(jti: string): Promise<void> {
    // Implementation depends on your Redis service
    // await this.redisService.set(`revoked:${jti}`, '1', { ttl: this.parseExpiry(this.refreshTokenExpiry) });
  }

  private async isTokenRevoked(jti: string): Promise<boolean> {
    // Implementation depends on your Redis service
    // return await this.redisService.exists(`revoked:${jti}`);
    return false;
  }

  private async getUserById(id: string): Promise<any> {
    // Implementation depends on your user service
    return null;
  }
}
```

### Password Hashing Service
```typescript
// libs/shared/auth/src/password/password.service.ts
import { Injectable } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';

@Injectable()
export class PasswordService {
  private readonly saltRounds = 12;

  async hashPassword(password: string): Promise<string> {
    this.validatePassword(password);
    return bcrypt.hash(password, this.saltRounds);
  }

  async verifyPassword(password: string, hash: string): Promise<boolean> {
    return bcrypt.compare(password, hash);
  }

  generateSecurePassword(length: number = 16): string {
    const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*';
    let password = '';
    
    for (let i = 0; i < length; i++) {
      const randomIndex = crypto.randomInt(0, charset.length);
      password += charset[randomIndex];
    }
    
    return password;
  }

  validatePassword(password: string): void {
    if (password.length < 8) {
      throw new Error('Password must be at least 8 characters long');
    }

    if (!/(?=.*[a-z])/.test(password)) {
      throw new Error('Password must contain at least one lowercase letter');
    }

    if (!/(?=.*[A-Z])/.test(password)) {
      throw new Error('Password must contain at least one uppercase letter');
    }

    if (!/(?=.*\d)/.test(password)) {
      throw new Error('Password must contain at least one number');
    }

    if (!/(?=.*[!@#$%^&*])/.test(password)) {
      throw new Error('Password must contain at least one special character');
    }
  }

  generateResetToken(): string {
    return crypto.randomBytes(32).toString('hex');
  }

  hashResetToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }
}
```

## OAuth 2.0 Integration

### OAuth Provider Service
```typescript
// libs/shared/auth/src/oauth/oauth.service.ts
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

export interface OAuthConfig {
  clientId: string;
  clientSecret: string;
  redirectUri: string;
  scope: string[];
}

export interface OAuthTokenResponse {
  access_token: string;
  token_type: string;
  expires_in: number;
  refresh_token?: string;
  scope: string;
}

export interface OAuthUserInfo {
  id: string;
  email: string;
  name: string;
  avatar?: string;
  verified: boolean;
}

@Injectable()
export class OAuthService {
  private readonly providers: Map<string, OAuthConfig> = new Map();

  constructor(private configService: ConfigService) {
    this.initializeProviders();
  }

  private initializeProviders(): void {
    // Google OAuth
    this.providers.set('google', {
      clientId: this.configService.get('GOOGLE_CLIENT_ID'),
      clientSecret: this.configService.get('GOOGLE_CLIENT_SECRET'),
      redirectUri: this.configService.get('GOOGLE_REDIRECT_URI'),
      scope: ['openid', 'email', 'profile']
    });

    // GitHub OAuth
    this.providers.set('github', {
      clientId: this.configService.get('GITHUB_CLIENT_ID'),
      clientSecret: this.configService.get('GITHUB_CLIENT_SECRET'),
      redirectUri: this.configService.get('GITHUB_REDIRECT_URI'),
      scope: ['user:email']
    });
  }

  getAuthorizationUrl(provider: string, state?: string): string {
    const config = this.providers.get(provider);
    if (!config) {
      throw new Error(`Unsupported OAuth provider: ${provider}`);
    }

    const params = new URLSearchParams({
      client_id: config.clientId,
      redirect_uri: config.redirectUri,
      scope: config.scope.join(' '),
      response_type: 'code',
      ...(state && { state })
    });

    switch (provider) {
      case 'google':
        return `https://accounts.google.com/o/oauth2/v2/auth?${params}`;
      case 'github':
        return `https://github.com/login/oauth/authorize?${params}`;
      default:
        throw new Error(`Authorization URL not configured for provider: ${provider}`);
    }
  }

  async exchangeCodeForToken(provider: string, code: string): Promise<OAuthTokenResponse> {
    const config = this.providers.get(provider);
    if (!config) {
      throw new Error(`Unsupported OAuth provider: ${provider}`);
    }

    const tokenData = {
      client_id: config.clientId,
      client_secret: config.clientSecret,
      code,
      redirect_uri: config.redirectUri,
      grant_type: 'authorization_code'
    };

    let tokenUrl: string;
    switch (provider) {
      case 'google':
        tokenUrl = 'https://oauth2.googleapis.com/token';
        break;
      case 'github':
        tokenUrl = 'https://github.com/login/oauth/access_token';
        break;
      default:
        throw new Error(`Token URL not configured for provider: ${provider}`);
    }

    try {
      const response = await axios.post(tokenUrl, tokenData, {
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      });

      return response.data;
    } catch (error) {
      throw new Error(`Failed to exchange code for token: ${error.message}`);
    }
  }

  async getUserInfo(provider: string, accessToken: string): Promise<OAuthUserInfo> {
    let userInfoUrl: string;
    switch (provider) {
      case 'google':
        userInfoUrl = 'https://www.googleapis.com/oauth2/v2/userinfo';
        break;
      case 'github':
        userInfoUrl = 'https://api.github.com/user';
        break;
      default:
        throw new Error(`User info URL not configured for provider: ${provider}`);
    }

    try {
      const response = await axios.get(userInfoUrl, {
        headers: {
          'Authorization': `Bearer ${accessToken}`
        }
      });

      return this.normalizeUserInfo(provider, response.data);
    } catch (error) {
      throw new Error(`Failed to fetch user info: ${error.message}`);
    }
  }

  private normalizeUserInfo(provider: string, rawUserInfo: any): OAuthUserInfo {
    switch (provider) {
      case 'google':
        return {
          id: rawUserInfo.id,
          email: rawUserInfo.email,
          name: rawUserInfo.name,
          avatar: rawUserInfo.picture,
          verified: rawUserInfo.verified_email
        };
      case 'github':
        return {
          id: rawUserInfo.id.toString(),
          email: rawUserInfo.email,
          name: rawUserInfo.name || rawUserInfo.login,
          avatar: rawUserInfo.avatar_url,
          verified: true // GitHub emails are considered verified
        };
      default:
        throw new Error(`User info normalization not implemented for provider: ${provider}`);
    }
  }
}
```

## RBAC (Role-Based Access Control) Patterns

### Permission System
```typescript
// libs/shared/auth/src/rbac/permission.service.ts
import { Injectable } from '@nestjs/common';

export interface Permission {
  id: string;
  name: string;
  resource: string;
  action: string;
  conditions?: Record<string, any>;
}

export interface Role {
  id: string;
  name: string;
  description: string;
  permissions: Permission[];
}

export interface User {
  id: string;
  email: string;
  roles: Role[];
}

@Injectable()
export class PermissionService {
  private permissions: Map<string, Permission> = new Map();
  private roles: Map<string, Role> = new Map();

  constructor() {
    this.initializePermissions();
    this.initializeRoles();
  }

  private initializePermissions(): void {
    const permissions: Permission[] = [
      // Task permissions
      { id: 'task:read', name: 'Read Tasks', resource: 'task', action: 'read' },
      { id: 'task:create', name: 'Create Tasks', resource: 'task', action: 'create' },
      { id: 'task:update', name: 'Update Tasks', resource: 'task', action: 'update' },
      { id: 'task:delete', name: 'Delete Tasks', resource: 'task', action: 'delete' },
      { id: 'task:assign', name: 'Assign Tasks', resource: 'task', action: 'assign' },

      // User permissions
      { id: 'user:read', name: 'Read Users', resource: 'user', action: 'read' },
      { id: 'user:create', name: 'Create Users', resource: 'user', action: 'create' },
      { id: 'user:update', name: 'Update Users', resource: 'user', action: 'update' },
      { id: 'user:delete', name: 'Delete Users', resource: 'user', action: 'delete' },

      // Admin permissions
      { id: 'admin:system', name: 'System Administration', resource: 'system', action: 'admin' },
      { id: 'admin:users', name: 'User Administration', resource: 'user', action: 'admin' }
    ];

    permissions.forEach(permission => {
      this.permissions.set(permission.id, permission);
    });
  }

  private initializeRoles(): void {
    const roles: Role[] = [
      {
        id: 'user',
        name: 'User',
        description: 'Basic user with task management capabilities',
        permissions: [
          this.permissions.get('task:read')!,
          this.permissions.get('task:create')!,
          this.permissions.get('task:update')!,
          this.permissions.get('user:read')!
        ]
      },
      {
        id: 'manager',
        name: 'Manager',
        description: 'Manager with team oversight capabilities',
        permissions: [
          this.permissions.get('task:read')!,
          this.permissions.get('task:create')!,
          this.permissions.get('task:update')!,
          this.permissions.get('task:delete')!,
          this.permissions.get('task:assign')!,
          this.permissions.get('user:read')!,
          this.permissions.get('user:update')!
        ]
      },
      {
        id: 'admin',
        name: 'Administrator',
        description: 'Full system administrator',
        permissions: Array.from(this.permissions.values())
      }
    ];

    roles.forEach(role => {
      this.roles.set(role.id, role);
    });
  }

  hasPermission(user: User, permissionId: string, context?: any): boolean {
    const permission = this.permissions.get(permissionId);
    if (!permission) {
      return false;
    }

    // Check if user has the permission through any of their roles
    for (const role of user.roles) {
      const hasPermission = role.permissions.some(p => p.id === permissionId);
      if (hasPermission) {
        // Check conditions if they exist
        if (permission.conditions) {
          return this.evaluateConditions(permission.conditions, user, context);
        }
        return true;
      }
    }

    return false;
  }

  hasRole(user: User, roleId: string): boolean {
    return user.roles.some(role => role.id === roleId);
  }

  hasAnyRole(user: User, roleIds: string[]): boolean {
    return user.roles.some(role => roleIds.includes(role.id));
  }

  hasAllRoles(user: User, roleIds: string[]): boolean {
    return roleIds.every(roleId => this.hasRole(user, roleId));
  }

  canAccessResource(user: User, resource: string, action: string, context?: any): boolean {
    const permissionId = `${resource}:${action}`;
    return this.hasPermission(user, permissionId, context);
  }

  private evaluateConditions(conditions: Record<string, any>, user: User, context?: any): boolean {
    // Implement condition evaluation logic
    // For example: ownership checks, time-based restrictions, etc.

    if (conditions.owner && context?.ownerId) {
      return user.id === context.ownerId;
    }

    if (conditions.department && context?.department) {
      // Check if user belongs to the required department
      return user.roles.some(role => role.name.includes(context.department));
    }

    return true;
  }

  getUserPermissions(user: User): Permission[] {
    const permissions = new Set<Permission>();

    user.roles.forEach(role => {
      role.permissions.forEach(permission => {
        permissions.add(permission);
      });
    });

    return Array.from(permissions);
  }

  getRole(roleId: string): Role | undefined {
    return this.roles.get(roleId);
  }

  getAllRoles(): Role[] {
    return Array.from(this.roles.values());
  }

  getAllPermissions(): Permission[] {
    return Array.from(this.permissions.values());
  }
}
```

## Security Middleware

### Authentication Middleware
```typescript
// libs/shared/auth/src/middleware/auth.middleware.ts
import { NextRequest, NextResponse } from 'next/server';
import { JwtService } from '../jwt/jwt.service';
import { PermissionService } from '../rbac/permission.service';

export interface AuthenticatedRequest extends NextRequest {
  user?: {
    id: string;
    email: string;
    roles: string[];
    permissions: string[];
  };
}

export class AuthMiddleware {
  constructor(
    private jwtService: JwtService,
    private permissionService: PermissionService
  ) {}

  authenticate() {
    return async (request: NextRequest): Promise<NextResponse | null> => {
      const authHeader = request.headers.get('authorization');

      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return NextResponse.json(
          { error: 'Missing or invalid authorization header' },
          { status: 401 }
        );
      }

      const token = authHeader.substring(7);

      try {
        const payload = await this.jwtService.verifyAccessToken(token);

        // Add user info to request
        (request as AuthenticatedRequest).user = {
          id: payload.sub,
          email: payload.email,
          roles: payload.roles,
          permissions: payload.permissions
        };

        return null; // Continue to next middleware/handler
      } catch (error) {
        return NextResponse.json(
          { error: 'Invalid or expired token' },
          { status: 401 }
        );
      }
    };
  }

  requirePermission(permissionId: string) {
    return async (request: AuthenticatedRequest): Promise<NextResponse | null> => {
      if (!request.user) {
        return NextResponse.json(
          { error: 'Authentication required' },
          { status: 401 }
        );
      }

      if (!request.user.permissions.includes(permissionId)) {
        return NextResponse.json(
          { error: 'Insufficient permissions' },
          { status: 403 }
        );
      }

      return null; // Continue to next middleware/handler
    };
  }

  requireRole(roleId: string) {
    return async (request: AuthenticatedRequest): Promise<NextResponse | null> => {
      if (!request.user) {
        return NextResponse.json(
          { error: 'Authentication required' },
          { status: 401 }
        );
      }

      if (!request.user.roles.includes(roleId)) {
        return NextResponse.json(
          { error: 'Insufficient role privileges' },
          { status: 403 }
        );
      }

      return null; // Continue to next middleware/handler
    };
  }

  requireAnyRole(roleIds: string[]) {
    return async (request: AuthenticatedRequest): Promise<NextResponse | null> => {
      if (!request.user) {
        return NextResponse.json(
          { error: 'Authentication required' },
          { status: 401 }
        );
      }

      const hasRole = request.user.roles.some(role => roleIds.includes(role));
      if (!hasRole) {
        return NextResponse.json(
          { error: 'Insufficient role privileges' },
          { status: 403 }
        );
      }

      return null; // Continue to next middleware/handler
    };
  }
}
```

## Session Management

### Session Service
```typescript
// libs/shared/auth/src/session/session.service.ts
import { Injectable } from '@nestjs/common';
import { RedisService } from '@api/database';

export interface SessionData {
  userId: string;
  email: string;
  roles: string[];
  permissions: string[];
  createdAt: Date;
  lastAccessedAt: Date;
  ipAddress?: string;
  userAgent?: string;
}

@Injectable()
export class SessionService {
  private readonly sessionPrefix = 'session:';
  private readonly userSessionsPrefix = 'user_sessions:';
  private readonly defaultTtl = 86400; // 24 hours

  constructor(private redisService: RedisService) {}

  async createSession(
    sessionId: string,
    sessionData: Omit<SessionData, 'createdAt' | 'lastAccessedAt'>
  ): Promise<void> {
    const session: SessionData = {
      ...sessionData,
      createdAt: new Date(),
      lastAccessedAt: new Date()
    };

    // Store session data
    await this.redisService.set(
      `${this.sessionPrefix}${sessionId}`,
      session,
      { ttl: this.defaultTtl }
    );

    // Track user sessions
    await this.redisService.lpush(
      `${this.userSessionsPrefix}${sessionData.userId}`,
      sessionId
    );

    // Set expiry for user sessions list
    await this.redisService.client.expire(
      `${this.userSessionsPrefix}${sessionData.userId}`,
      this.defaultTtl
    );
  }

  async getSession(sessionId: string): Promise<SessionData | null> {
    const session = await this.redisService.get<SessionData>(
      `${this.sessionPrefix}${sessionId}`
    );

    if (session) {
      // Update last accessed time
      session.lastAccessedAt = new Date();
      await this.redisService.set(
        `${this.sessionPrefix}${sessionId}`,
        session,
        { ttl: this.defaultTtl }
      );
    }

    return session;
  }

  async updateSession(sessionId: string, updates: Partial<SessionData>): Promise<void> {
    const session = await this.getSession(sessionId);
    if (!session) {
      throw new Error('Session not found');
    }

    const updatedSession = {
      ...session,
      ...updates,
      lastAccessedAt: new Date()
    };

    await this.redisService.set(
      `${this.sessionPrefix}${sessionId}`,
      updatedSession,
      { ttl: this.defaultTtl }
    );
  }

  async destroySession(sessionId: string): Promise<void> {
    const session = await this.redisService.get<SessionData>(
      `${this.sessionPrefix}${sessionId}`
    );

    if (session) {
      // Remove from user sessions list
      await this.redisService.client.lrem(
        `${this.userSessionsPrefix}${session.userId}`,
        0,
        sessionId
      );
    }

    // Remove session data
    await this.redisService.del(`${this.sessionPrefix}${sessionId}`);
  }

  async destroyAllUserSessions(userId: string): Promise<void> {
    const sessionIds = await this.redisService.lrange(
      `${this.userSessionsPrefix}${userId}`,
      0,
      -1
    );

    // Remove all session data
    const deletePromises = sessionIds.map(sessionId =>
      this.redisService.del(`${this.sessionPrefix}${sessionId}`)
    );

    await Promise.all(deletePromises);

    // Clear user sessions list
    await this.redisService.del(`${this.userSessionsPrefix}${userId}`);
  }

  async getUserSessions(userId: string): Promise<SessionData[]> {
    const sessionIds = await this.redisService.lrange(
      `${this.userSessionsPrefix}${userId}`,
      0,
      -1
    );

    const sessionPromises = sessionIds.map(sessionId =>
      this.redisService.get<SessionData>(`${this.sessionPrefix}${sessionId}`)
    );

    const sessions = await Promise.all(sessionPromises);
    return sessions.filter(session => session !== null) as SessionData[];
  }

  async cleanupExpiredSessions(): Promise<void> {
    // This would typically be run as a scheduled job
    // Implementation depends on your specific needs
    console.log('Cleaning up expired sessions...');
  }

  generateSessionId(): string {
    return `sess_${Date.now()}_${Math.random().toString(36).substr(2, 16)}`;
  }
}
```

## Best Practices

### Security Headers Middleware
```typescript
// libs/shared/auth/src/middleware/security-headers.middleware.ts
import { NextRequest, NextResponse } from 'next/server';

export function securityHeaders() {
  return (request: NextRequest): NextResponse => {
    const response = NextResponse.next();

    // Prevent XSS attacks
    response.headers.set('X-Content-Type-Options', 'nosniff');
    response.headers.set('X-Frame-Options', 'DENY');
    response.headers.set('X-XSS-Protection', '1; mode=block');

    // HTTPS enforcement
    response.headers.set('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');

    // Content Security Policy
    response.headers.set(
      'Content-Security-Policy',
      "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' https:; connect-src 'self' https:; frame-ancestors 'none';"
    );

    // Referrer Policy
    response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');

    // Permissions Policy
    response.headers.set(
      'Permissions-Policy',
      'camera=(), microphone=(), geolocation=(), payment=()'
    );

    return response;
  };
}
```

### Rate Limiting
```typescript
// libs/shared/auth/src/middleware/rate-limit.middleware.ts
import { NextRequest, NextResponse } from 'next/server';
import { RedisService } from '@api/database';

export interface RateLimitConfig {
  windowMs: number; // Time window in milliseconds
  maxRequests: number; // Maximum requests per window
  keyGenerator?: (request: NextRequest) => string;
  skipSuccessfulRequests?: boolean;
  skipFailedRequests?: boolean;
}

export class RateLimitMiddleware {
  constructor(private redisService: RedisService) {}

  create(config: RateLimitConfig) {
    return async (request: NextRequest): Promise<NextResponse | null> => {
      const key = config.keyGenerator
        ? config.keyGenerator(request)
        : this.defaultKeyGenerator(request);

      const windowKey = `rate_limit:${key}:${Math.floor(Date.now() / config.windowMs)}`;

      const current = await this.redisService.get<number>(windowKey) || 0;

      if (current >= config.maxRequests) {
        return NextResponse.json(
          {
            error: 'Too many requests',
            retryAfter: Math.ceil(config.windowMs / 1000)
          },
          {
            status: 429,
            headers: {
              'Retry-After': Math.ceil(config.windowMs / 1000).toString(),
              'X-RateLimit-Limit': config.maxRequests.toString(),
              'X-RateLimit-Remaining': '0',
              'X-RateLimit-Reset': (Date.now() + config.windowMs).toString()
            }
          }
        );
      }

      // Increment counter
      await this.redisService.set(
        windowKey,
        current + 1,
        { ttl: Math.ceil(config.windowMs / 1000) }
      );

      return null; // Continue to next middleware/handler
    };
  }

  private defaultKeyGenerator(request: NextRequest): string {
    const forwarded = request.headers.get('x-forwarded-for');
    const ip = forwarded ? forwarded.split(',')[0] : request.ip || 'unknown';
    return ip;
  }
}
```

This authentication and security patterns template provides a comprehensive foundation for implementing secure authentication and authorization within our NX monorepo structure.

# SLA/SLO Monitoring Patterns Template

## Overview
This template provides comprehensive patterns for implementing Service Level Objectives (SLOs), error budgets, alerting strategies, and performance monitoring using Elastic Cloud and OpenTelemetry within our NX monorepo structure.

## SLO Definition and Implementation

### SLO Configuration Structure
```typescript
// libs/shared/monitoring/src/slo/slo.config.ts
export interface SLOConfig {
  name: string;
  description: string;
  service: string;
  sli: ServiceLevelIndicator;
  objective: number; // Target percentage (e.g., 99.9)
  errorBudgetPolicy: ErrorBudgetPolicy;
  alerting: AlertingConfig;
}

export interface ServiceLevelIndicator {
  type: 'availability' | 'latency' | 'throughput' | 'error_rate';
  metric: string;
  threshold?: number;
  aggregation: 'avg' | 'p50' | 'p95' | 'p99' | 'count' | 'rate';
  timeWindow: string; // e.g., '5m', '1h', '1d'
}

export interface ErrorBudgetPolicy {
  period: string; // e.g., '30d', '7d'
  burnRateThresholds: BurnRateThreshold[];
}

export interface BurnRateThreshold {
  rate: number; // e.g., 2.0 for 2x burn rate
  window: string; // e.g., '1h', '5m'
  severity: 'warning' | 'critical';
}

export interface AlertingConfig {
  enabled: boolean;
  channels: string[];
  escalation: EscalationPolicy;
}

export interface EscalationPolicy {
  levels: EscalationLevel[];
}

export interface EscalationLevel {
  delay: string; // e.g., '5m', '15m'
  channels: string[];
}

// Predefined SLO configurations
export const SLO_CONFIGS: SLOConfig[] = [
  {
    name: 'API Availability',
    description: 'API endpoints should be available 99.9% of the time',
    service: 'api-core',
    sli: {
      type: 'availability',
      metric: 'http_requests_total',
      aggregation: 'rate',
      timeWindow: '5m'
    },
    objective: 99.9,
    errorBudgetPolicy: {
      period: '30d',
      burnRateThresholds: [
        { rate: 14.4, window: '1h', severity: 'critical' },
        { rate: 6.0, window: '6h', severity: 'warning' }
      ]
    },
    alerting: {
      enabled: true,
      channels: ['slack-alerts', 'pagerduty'],
      escalation: {
        levels: [
          { delay: '5m', channels: ['slack-alerts'] },
          { delay: '15m', channels: ['pagerduty'] }
        ]
      }
    }
  },
  {
    name: 'API Latency P95',
    description: '95% of API requests should complete within 500ms',
    service: 'api-core',
    sli: {
      type: 'latency',
      metric: 'http_request_duration_seconds',
      threshold: 0.5,
      aggregation: 'p95',
      timeWindow: '5m'
    },
    objective: 95.0,
    errorBudgetPolicy: {
      period: '7d',
      burnRateThresholds: [
        { rate: 14.4, window: '1h', severity: 'critical' },
        { rate: 6.0, window: '6h', severity: 'warning' }
      ]
    },
    alerting: {
      enabled: true,
      channels: ['slack-alerts'],
      escalation: {
        levels: [
          { delay: '10m', channels: ['slack-alerts'] },
          { delay: '30m', channels: ['pagerduty'] }
        ]
      }
    }
  },
  {
    name: 'Database Connection Pool',
    description: 'Database connection pool should maintain 95% availability',
    service: 'database',
    sli: {
      type: 'availability',
      metric: 'db_connections_active',
      aggregation: 'avg',
      timeWindow: '1m'
    },
    objective: 95.0,
    errorBudgetPolicy: {
      period: '7d',
      burnRateThresholds: [
        { rate: 10.0, window: '30m', severity: 'critical' },
        { rate: 5.0, window: '2h', severity: 'warning' }
      ]
    },
    alerting: {
      enabled: true,
      channels: ['slack-alerts', 'email-alerts'],
      escalation: {
        levels: [
          { delay: '2m', channels: ['slack-alerts'] },
          { delay: '10m', channels: ['email-alerts'] }
        ]
      }
    }
  }
];
```

### SLO Monitoring Service
```typescript
// libs/shared/monitoring/src/slo/slo-monitor.service.ts
import { Injectable } from '@nestjs/common';
import { ElasticsearchService } from '@nestjs/elasticsearch';
import { SLOConfig, ServiceLevelIndicator } from './slo.config';

export interface SLOStatus {
  name: string;
  service: string;
  currentValue: number;
  objective: number;
  errorBudget: {
    remaining: number;
    consumed: number;
    burnRate: number;
  };
  status: 'healthy' | 'warning' | 'critical';
  lastUpdated: Date;
}

@Injectable()
export class SLOMonitorService {
  constructor(private elasticsearch: ElasticsearchService) {}

  async calculateSLO(config: SLOConfig): Promise<SLOStatus> {
    const sliValue = await this.calculateSLI(config.sli, config.service);
    const errorBudget = await this.calculateErrorBudget(config, sliValue);
    
    return {
      name: config.name,
      service: config.service,
      currentValue: sliValue,
      objective: config.objective,
      errorBudget,
      status: this.determineStatus(sliValue, config.objective, errorBudget.burnRate),
      lastUpdated: new Date()
    };
  }

  private async calculateSLI(sli: ServiceLevelIndicator, service: string): Promise<number> {
    const query = this.buildElasticsearchQuery(sli, service);
    
    try {
      const response = await this.elasticsearch.search({
        index: `metrics-${service}-*`,
        body: query
      });

      return this.extractSLIValue(response.body, sli);
    } catch (error) {
      console.error('Error calculating SLI:', error);
      throw error;
    }
  }

  private buildElasticsearchQuery(sli: ServiceLevelIndicator, service: string): any {
    const baseQuery = {
      size: 0,
      query: {
        bool: {
          must: [
            { term: { 'service.name': service } },
            {
              range: {
                '@timestamp': {
                  gte: `now-${sli.timeWindow}`,
                  lte: 'now'
                }
              }
            }
          ]
        }
      }
    };

    switch (sli.type) {
      case 'availability':
        return {
          ...baseQuery,
          aggs: {
            total_requests: {
              filter: { term: { 'metrics.name': sli.metric } }
            },
            successful_requests: {
              filter: {
                bool: {
                  must: [
                    { term: { 'metrics.name': sli.metric } },
                    { range: { 'http.response.status_code': { gte: 200, lt: 400 } } }
                  ]
                }
              }
            }
          }
        };

      case 'latency':
        return {
          ...baseQuery,
          aggs: {
            latency_percentile: {
              percentiles: {
                field: 'metrics.value',
                percents: [this.getPercentileValue(sli.aggregation)]
              }
            }
          }
        };

      case 'error_rate':
        return {
          ...baseQuery,
          aggs: {
            total_requests: {
              filter: { term: { 'metrics.name': sli.metric } }
            },
            error_requests: {
              filter: {
                bool: {
                  must: [
                    { term: { 'metrics.name': sli.metric } },
                    { range: { 'http.response.status_code': { gte: 400 } } }
                  ]
                }
              }
            }
          }
        };

      default:
        throw new Error(`Unsupported SLI type: ${sli.type}`);
    }
  }

  private extractSLIValue(response: any, sli: ServiceLevelIndicator): number {
    const aggregations = response.aggregations;

    switch (sli.type) {
      case 'availability':
        const total = aggregations.total_requests.doc_count;
        const successful = aggregations.successful_requests.doc_count;
        return total > 0 ? (successful / total) * 100 : 100;

      case 'latency':
        const percentileKey = this.getPercentileValue(sli.aggregation).toString();
        const latencyValue = aggregations.latency_percentile.values[percentileKey];
        return sli.threshold ? (latencyValue <= sli.threshold ? 100 : 0) : latencyValue;

      case 'error_rate':
        const totalRequests = aggregations.total_requests.doc_count;
        const errorRequests = aggregations.error_requests.doc_count;
        return totalRequests > 0 ? ((totalRequests - errorRequests) / totalRequests) * 100 : 100;

      default:
        return 0;
    }
  }

  private async calculateErrorBudget(config: SLOConfig, currentSLI: number): Promise<{
    remaining: number;
    consumed: number;
    burnRate: number;
  }> {
    const allowedFailureRate = 100 - config.objective;
    const actualFailureRate = 100 - currentSLI;
    
    const consumed = Math.min(actualFailureRate / allowedFailureRate * 100, 100);
    const remaining = Math.max(100 - consumed, 0);
    const burnRate = actualFailureRate / allowedFailureRate;

    return {
      remaining,
      consumed,
      burnRate
    };
  }

  private determineStatus(sliValue: number, objective: number, burnRate: number): 'healthy' | 'warning' | 'critical' {
    if (sliValue < objective * 0.95) {
      return 'critical';
    } else if (sliValue < objective * 0.98 || burnRate > 2.0) {
      return 'warning';
    } else {
      return 'healthy';
    }
  }

  private getPercentileValue(aggregation: string): number {
    switch (aggregation) {
      case 'p50': return 50;
      case 'p95': return 95;
      case 'p99': return 99;
      default: return 95;
    }
  }

  async getAllSLOStatuses(): Promise<SLOStatus[]> {
    const { SLO_CONFIGS } = await import('./slo.config');
    const statuses = await Promise.all(
      SLO_CONFIGS.map(config => this.calculateSLO(config))
    );
    
    return statuses;
  }
}
```

## Error Budget Management

### Error Budget Tracking
```typescript
// libs/shared/monitoring/src/error-budget/error-budget.service.ts
import { Injectable } from '@nestjs/common';
import { SLOMonitorService, SLOStatus } from '../slo/slo-monitor.service';

export interface ErrorBudgetAlert {
  sloName: string;
  service: string;
  burnRate: number;
  remainingBudget: number;
  severity: 'warning' | 'critical';
  message: string;
  timestamp: Date;
}

@Injectable()
export class ErrorBudgetService {
  constructor(private sloMonitor: SLOMonitorService) {}

  async checkErrorBudgets(): Promise<ErrorBudgetAlert[]> {
    const sloStatuses = await this.sloMonitor.getAllSLOStatuses();
    const alerts: ErrorBudgetAlert[] = [];

    for (const status of sloStatuses) {
      const alert = this.evaluateErrorBudget(status);
      if (alert) {
        alerts.push(alert);
      }
    }

    return alerts;
  }

  private evaluateErrorBudget(status: SLOStatus): ErrorBudgetAlert | null {
    const { errorBudget } = status;
    
    // Critical: Less than 10% error budget remaining or high burn rate
    if (errorBudget.remaining < 10 || errorBudget.burnRate > 10) {
      return {
        sloName: status.name,
        service: status.service,
        burnRate: errorBudget.burnRate,
        remainingBudget: errorBudget.remaining,
        severity: 'critical',
        message: `Critical: ${status.name} has ${errorBudget.remaining.toFixed(1)}% error budget remaining with ${errorBudget.burnRate.toFixed(2)}x burn rate`,
        timestamp: new Date()
      };
    }
    
    // Warning: Less than 25% error budget remaining or elevated burn rate
    if (errorBudget.remaining < 25 || errorBudget.burnRate > 2) {
      return {
        sloName: status.name,
        service: status.service,
        burnRate: errorBudget.burnRate,
        remainingBudget: errorBudget.remaining,
        severity: 'warning',
        message: `Warning: ${status.name} has ${errorBudget.remaining.toFixed(1)}% error budget remaining with ${errorBudget.burnRate.toFixed(2)}x burn rate`,
        timestamp: new Date()
      };
    }

    return null;
  }

  async getErrorBudgetReport(service?: string): Promise<{
    summary: {
      totalSLOs: number;
      healthySLOs: number;
      warningSLOs: number;
      criticalSLOs: number;
    };
    details: SLOStatus[];
  }> {
    let statuses = await this.sloMonitor.getAllSLOStatuses();
    
    if (service) {
      statuses = statuses.filter(s => s.service === service);
    }

    const summary = {
      totalSLOs: statuses.length,
      healthySLOs: statuses.filter(s => s.status === 'healthy').length,
      warningSLOs: statuses.filter(s => s.status === 'warning').length,
      criticalSLOs: statuses.filter(s => s.status === 'critical').length
    };

    return {
      summary,
      details: statuses
    };
  }
}

## Alerting Strategies

### Alert Manager Service
```typescript
// libs/shared/monitoring/src/alerting/alert-manager.service.ts
import { Injectable } from '@nestjs/common';
import { ErrorBudgetAlert } from '../error-budget/error-budget.service';

export interface AlertChannel {
  name: string;
  type: 'slack' | 'email' | 'pagerduty' | 'webhook';
  config: any;
  enabled: boolean;
}

export interface Alert {
  id: string;
  title: string;
  message: string;
  severity: 'info' | 'warning' | 'critical';
  service: string;
  timestamp: Date;
  resolved: boolean;
  channels: string[];
}

@Injectable()
export class AlertManagerService {
  private channels: Map<string, AlertChannel> = new Map();
  private activeAlerts: Map<string, Alert> = new Map();

  constructor() {
    this.initializeChannels();
  }

  private initializeChannels(): void {
    const channels: AlertChannel[] = [
      {
        name: 'slack-alerts',
        type: 'slack',
        config: {
          webhookUrl: process.env.SLACK_WEBHOOK_URL,
          channel: '#alerts',
          username: 'SLO Monitor'
        },
        enabled: true
      },
      {
        name: 'pagerduty',
        type: 'pagerduty',
        config: {
          integrationKey: process.env.PAGERDUTY_INTEGRATION_KEY,
          severity: 'critical'
        },
        enabled: true
      },
      {
        name: 'email-alerts',
        type: 'email',
        config: {
          recipients: ['oncall@horizon.com', 'platform-team@horizon.com'],
          smtpConfig: {
            host: process.env.SMTP_HOST,
            port: parseInt(process.env.SMTP_PORT || '587'),
            auth: {
              user: process.env.SMTP_USER,
              pass: process.env.SMTP_PASS
            }
          }
        },
        enabled: true
      }
    ];

    channels.forEach(channel => {
      this.channels.set(channel.name, channel);
    });
  }

  async sendAlert(alert: Alert): Promise<void> {
    // Check if alert already exists and is not resolved
    const existingAlert = this.activeAlerts.get(alert.id);
    if (existingAlert && !existingAlert.resolved) {
      console.log(`Alert ${alert.id} already active, skipping duplicate`);
      return;
    }

    // Store alert
    this.activeAlerts.set(alert.id, alert);

    // Send to configured channels
    const sendPromises = alert.channels.map(channelName =>
      this.sendToChannel(channelName, alert)
    );

    try {
      await Promise.all(sendPromises);
      console.log(`Alert ${alert.id} sent successfully`);
    } catch (error) {
      console.error(`Failed to send alert ${alert.id}:`, error);
    }
  }

  private async sendToChannel(channelName: string, alert: Alert): Promise<void> {
    const channel = this.channels.get(channelName);
    if (!channel || !channel.enabled) {
      console.warn(`Channel ${channelName} not found or disabled`);
      return;
    }

    switch (channel.type) {
      case 'slack':
        await this.sendSlackAlert(channel, alert);
        break;
      case 'email':
        await this.sendEmailAlert(channel, alert);
        break;
      case 'pagerduty':
        await this.sendPagerDutyAlert(channel, alert);
        break;
      case 'webhook':
        await this.sendWebhookAlert(channel, alert);
        break;
      default:
        console.warn(`Unsupported channel type: ${channel.type}`);
    }
  }

  private async sendSlackAlert(channel: AlertChannel, alert: Alert): Promise<void> {
    const color = this.getSeverityColor(alert.severity);
    const payload = {
      channel: channel.config.channel,
      username: channel.config.username,
      attachments: [
        {
          color,
          title: alert.title,
          text: alert.message,
          fields: [
            { title: 'Service', value: alert.service, short: true },
            { title: 'Severity', value: alert.severity.toUpperCase(), short: true },
            { title: 'Time', value: alert.timestamp.toISOString(), short: true }
          ],
          footer: 'SLO Monitor',
          ts: Math.floor(alert.timestamp.getTime() / 1000)
        }
      ]
    };

    // Implementation would use actual HTTP client
    console.log('Sending Slack alert:', payload);
  }

  private async sendEmailAlert(channel: AlertChannel, alert: Alert): Promise<void> {
    const subject = `[${alert.severity.toUpperCase()}] ${alert.title}`;
    const body = `
      Service: ${alert.service}
      Severity: ${alert.severity.toUpperCase()}
      Time: ${alert.timestamp.toISOString()}

      ${alert.message}
    `;

    // Implementation would use actual email service
    console.log('Sending email alert:', { subject, body, recipients: channel.config.recipients });
  }

  private async sendPagerDutyAlert(channel: AlertChannel, alert: Alert): Promise<void> {
    const payload = {
      routing_key: channel.config.integrationKey,
      event_action: 'trigger',
      dedup_key: alert.id,
      payload: {
        summary: alert.title,
        source: alert.service,
        severity: alert.severity,
        timestamp: alert.timestamp.toISOString(),
        custom_details: {
          message: alert.message,
          service: alert.service
        }
      }
    };

    // Implementation would use actual PagerDuty API
    console.log('Sending PagerDuty alert:', payload);
  }

  private async sendWebhookAlert(channel: AlertChannel, alert: Alert): Promise<void> {
    const payload = {
      alert_id: alert.id,
      title: alert.title,
      message: alert.message,
      severity: alert.severity,
      service: alert.service,
      timestamp: alert.timestamp.toISOString()
    };

    // Implementation would use actual HTTP client
    console.log('Sending webhook alert:', payload);
  }

  private getSeverityColor(severity: string): string {
    switch (severity) {
      case 'critical': return 'danger';
      case 'warning': return 'warning';
      case 'info': return 'good';
      default: return 'good';
    }
  }

  async resolveAlert(alertId: string): Promise<void> {
    const alert = this.activeAlerts.get(alertId);
    if (alert) {
      alert.resolved = true;
      this.activeAlerts.set(alertId, alert);
      console.log(`Alert ${alertId} resolved`);
    }
  }

  getActiveAlerts(): Alert[] {
    return Array.from(this.activeAlerts.values()).filter(alert => !alert.resolved);
  }
}
```

## Performance Monitoring Integration

### OpenTelemetry Metrics Collection
```typescript
// libs/shared/monitoring/src/metrics/otel-metrics.service.ts
import { Injectable } from '@nestjs/common';
import { metrics } from '@opentelemetry/api';
import { MeterProvider } from '@opentelemetry/sdk-metrics';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';

@Injectable()
export class OpenTelemetryMetricsService {
  private meter: any;
  private httpRequestDuration: any;
  private httpRequestsTotal: any;
  private dbConnectionsActive: any;
  private errorBudgetRemaining: any;

  constructor() {
    this.initializeMetrics();
  }

  private initializeMetrics(): void {
    const meterProvider = new MeterProvider({
      resource: new Resource({
        [SemanticResourceAttributes.SERVICE_NAME]: process.env.OTEL_SERVICE_NAME || 'horizon-api',
        [SemanticResourceAttributes.SERVICE_VERSION]: process.env.SERVICE_VERSION || '1.0.0',
        [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: process.env.NODE_ENV || 'development'
      })
    });

    this.meter = meterProvider.getMeter('horizon-slo-metrics');

    // HTTP request duration histogram
    this.httpRequestDuration = this.meter.createHistogram('http_request_duration_seconds', {
      description: 'Duration of HTTP requests in seconds',
      unit: 's'
    });

    // HTTP requests total counter
    this.httpRequestsTotal = this.meter.createCounter('http_requests_total', {
      description: 'Total number of HTTP requests'
    });

    // Database connections gauge
    this.dbConnectionsActive = this.meter.createUpDownCounter('db_connections_active', {
      description: 'Number of active database connections'
    });

    // Error budget remaining gauge
    this.errorBudgetRemaining = this.meter.createObservableGauge('error_budget_remaining_percent', {
      description: 'Remaining error budget percentage'
    });
  }

  recordHttpRequest(duration: number, method: string, route: string, statusCode: number): void {
    const labels = {
      method,
      route,
      status_code: statusCode.toString()
    };

    this.httpRequestDuration.record(duration, labels);
    this.httpRequestsTotal.add(1, labels);
  }

  recordDatabaseConnection(delta: number): void {
    this.dbConnectionsActive.add(delta);
  }

  updateErrorBudget(sloName: string, remainingPercent: number): void {
    this.errorBudgetRemaining.addCallback((result) => {
      result.observe(remainingPercent, { slo_name: sloName });
    });
  }
}
```

## Best Practices

### SLO Design Principles
- **User-Centric**: Define SLOs based on user experience, not system metrics
- **Achievable**: Set realistic targets that balance reliability with development velocity
- **Measurable**: Use metrics that can be accurately measured and monitored
- **Actionable**: Ensure SLO violations lead to clear remediation actions

### Error Budget Management
- **Policy-Driven**: Establish clear policies for error budget consumption
- **Burn Rate Alerts**: Alert on high burn rates before budget exhaustion
- **Feature Freeze**: Consider feature freezes when error budget is exhausted
- **Postmortem Process**: Conduct postmortems for significant SLO violations

### Alerting Best Practices
- **Actionable Alerts**: Only alert on conditions that require immediate action
- **Escalation Policies**: Implement clear escalation paths for different severities
- **Alert Fatigue**: Avoid alert fatigue by tuning thresholds appropriately
- **Runbooks**: Provide clear runbooks for alert resolution

### Monitoring Strategy
- **Golden Signals**: Focus on latency, traffic, errors, and saturation
- **Multi-Layer Monitoring**: Monitor at application, infrastructure, and business levels
- **Synthetic Monitoring**: Use synthetic tests to proactively detect issues
- **Real User Monitoring**: Supplement with real user experience data

### Integration with Development
- **SLO in CI/CD**: Include SLO validation in deployment pipelines
- **Performance Testing**: Validate SLO compliance during performance testing
- **Capacity Planning**: Use SLO data for capacity planning decisions
- **Team Ownership**: Assign clear ownership of SLOs to development teams

This SLA/SLO monitoring patterns template provides comprehensive guidance for implementing robust service level monitoring within our NX monorepo structure.
```

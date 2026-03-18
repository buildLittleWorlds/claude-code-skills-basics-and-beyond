# Data Model Reference

This document describes the application data model -- tables, event types,
metrics, and their relationships. Claude should consult this before constructing
any queries to ensure correct table names, column names, and event types.

## Database: app_db (PostgreSQL)

### Table: users

Primary user accounts.

| Column | Type | Description |
|---|---|---|
| id | uuid | Primary key |
| email | varchar(255) | Unique email address |
| name | varchar(255) | Display name |
| plan | varchar(50) | Subscription plan: `free`, `pro`, `enterprise` |
| status | varchar(20) | Account status: `active`, `suspended`, `deleted` |
| created_at | timestamptz | Account creation time |
| last_login_at | timestamptz | Most recent login |
| org_id | uuid | FK to `organizations.id` |

**Common queries:**
- Active users: `WHERE status = 'active'`
- Users by plan: `WHERE plan = 'pro'`
- Recent signups: `WHERE created_at >= NOW() - INTERVAL '7 days'`

### Table: organizations

Customer organizations (multi-tenant).

| Column | Type | Description |
|---|---|---|
| id | uuid | Primary key |
| name | varchar(255) | Organization display name |
| plan | varchar(50) | Subscription plan: `free`, `pro`, `enterprise` |
| created_at | timestamptz | Org creation time |
| seat_count | integer | Licensed seat count |
| seat_usage | integer | Current seats in use |

### Table: events

Application event log -- the primary source for user activity analysis.

| Column | Type | Description |
|---|---|---|
| id | bigint | Auto-incrementing primary key |
| user_id | uuid | FK to `users.id` (nullable for system events) |
| event_type | varchar(100) | Event classification (see Event Types below) |
| properties | jsonb | Event-specific payload |
| created_at | timestamptz | When the event occurred |
| session_id | uuid | Groups events within a user session |

**Indexes:** `created_at`, `event_type`, `user_id`, `(event_type, created_at)`

**Note:** The `properties` column is JSONB. Access nested fields with the `->>`
operator: `properties->>'endpoint'`, `properties->>'status_code'`.

### Table: deployments

Deployment history for correlating releases with metric changes.

| Column | Type | Description |
|---|---|---|
| id | serial | Primary key |
| version | varchar(50) | Deployed version tag (e.g., `v2.3.1`) |
| environment | varchar(20) | `production`, `staging`, `development` |
| deployed_at | timestamptz | Deployment timestamp |
| deployed_by | varchar(100) | Who triggered the deploy (username or CI) |
| status | varchar(20) | `success`, `failed`, `rolled_back` |
| commit_sha | varchar(40) | Git commit SHA |
| changelog | text | Summary of changes in this deploy |

### Table: feature_flags

Feature flag state for correlating flag changes with behavior changes.

| Column | Type | Description |
|---|---|---|
| id | serial | Primary key |
| flag_name | varchar(100) | Unique flag identifier |
| enabled | boolean | Whether the flag is globally enabled |
| rollout_pct | integer | Percentage of users seeing the flag (0-100) |
| updated_at | timestamptz | Last modification time |
| updated_by | varchar(100) | Who changed the flag |

## Event Types

### User Events

| Event Type | Description | Key Properties |
|---|---|---|
| `user.signup` | New user registration | `{ plan, source, referrer }` |
| `user.login` | User login | `{ method, ip, user_agent }` |
| `user.logout` | User logout | `{ session_duration_s }` |
| `user.plan_changed` | Plan upgrade or downgrade | `{ old_plan, new_plan }` |
| `user.deleted` | Account deletion | `{ reason }` |

### Feature Events

| Event Type | Description | Key Properties |
|---|---|---|
| `feature.used` | Feature interaction | `{ feature_name, action }` |
| `feature.error` | Feature-level error | `{ feature_name, error_type, message }` |

### API Events

| Event Type | Description | Key Properties |
|---|---|---|
| `api.request` | API call completed | `{ endpoint, method, status_code, duration_ms }` |
| `api.error` | API error (4xx or 5xx) | `{ endpoint, method, status_code, error_message }` |
| `api.rate_limited` | Request rate-limited | `{ endpoint, method, limit, current_rate }` |

### Billing Events

| Event Type | Description | Key Properties |
|---|---|---|
| `billing.charge` | Payment processed | `{ amount_cents, currency, plan }` |
| `billing.failed` | Payment failed | `{ amount_cents, currency, error }` |
| `billing.refund` | Refund issued | `{ amount_cents, currency, reason }` |

### Infrastructure Events

| Event Type | Description | Key Properties |
|---|---|---|
| `deploy.started` | Deployment initiated | `{ version, environment, triggered_by }` |
| `deploy.completed` | Deployment finished | `{ version, environment, status, duration_s }` |
| `config.changed` | Configuration modified | `{ key, old_value, new_value, changed_by }` |
| `alert.fired` | Monitoring alert triggered | `{ alert_name, severity, details }` |
| `alert.resolved` | Monitoring alert cleared | `{ alert_name, duration_s }` |

## Metrics (Prometheus)

### HTTP Metrics

| Metric Name | Type | Labels | Description |
|---|---|---|---|
| `http_requests_total` | counter | `method`, `endpoint`, `status_code` | Total HTTP requests |
| `http_request_duration_seconds` | histogram | `method`, `endpoint` | Request latency distribution |
| `http_error_rate` | gauge | `endpoint` | Computed 5xx error rate (0.0 to 1.0) |
| `http_active_connections` | gauge | `service` | Current open HTTP connections |

### Application Metrics

| Metric Name | Type | Labels | Description |
|---|---|---|---|
| `active_sessions` | gauge | -- | Currently active user sessions |
| `signup_rate` | gauge | `plan` | New signups per minute |
| `feature_usage_total` | counter | `feature_name`, `action` | Feature interaction count |

### Database Metrics

| Metric Name | Type | Labels | Description |
|---|---|---|---|
| `db_query_duration_seconds` | histogram | `query_type`, `table` | Database query latency |
| `db_connections_active` | gauge | `pool` | Active database connections |
| `db_connections_idle` | gauge | `pool` | Idle database connections |

### Infrastructure Metrics

| Metric Name | Type | Labels | Description |
|---|---|---|---|
| `cpu_usage_percent` | gauge | `service`, `instance` | CPU utilization |
| `memory_usage_bytes` | gauge | `service`, `instance` | Memory consumption |
| `disk_usage_percent` | gauge | `mount`, `instance` | Disk utilization |

### Background Job Metrics

| Metric Name | Type | Labels | Description |
|---|---|---|---|
| `background_jobs_total` | counter | `job_type`, `status` | Background jobs processed |
| `background_job_duration_seconds` | histogram | `job_type` | Job processing time |
| `background_job_queue_depth` | gauge | `job_type` | Jobs waiting in queue |

## Relationships

```
organizations 1──* users          (users.org_id → organizations.id)
users         1──* events         (events.user_id → users.id)
events        *──1 sessions       (events.session_id groups events)
deployments   ──── events         (correlated by timestamp, not FK)
feature_flags ──── events         (config.changed events reference flag_name)
```

### Key Correlations

- **Deployment impact**: Join `deployments` with metrics by timestamp to see
  how a deploy affected error rates, latency, or throughput.
- **Feature flag impact**: Look for `config.changed` events where
  `properties->>'key'` matches a feature flag name, then compare metrics
  before and after.
- **User journey**: Chain events by `session_id` to reconstruct a user's
  path through the application within a single session.
- **Error attribution**: `api.error` events contain `endpoint` and
  `status_code` that correlate with `http_error_rate` and
  `http_requests_total` metrics for the same endpoint.
- **Billing anomalies**: Compare `billing.failed` event counts with
  `billing.charge` counts to compute payment failure rate.

# Course 13: Data Fetching & Analysis Skills
**Level**: Intermediate-Advanced | **Estimated time**: 50 min

## Prerequisites
- Completed **Courses 1-5** (skills fundamentals, descriptions, anatomy, testing, advanced features)
- Completed **Course 12** (dynamic context injection, config patterns)
- Claude Code installed and working (`claude` command available)
- Python 3.8+ installed (for the helper scripts)
- Familiarity with JSON output and CLI argument patterns

## Concepts

### 1. The Data Skill Pattern

Most data analysis tasks follow a predictable cycle: connect to a source, query for data, transform results, present findings. Without a skill, Claude writes every step from scratch each time -- connection boilerplate, query construction, output formatting. The code works, but it's inconsistent, hard to audit, and re-invented on every invocation.

The **data skill pattern** flips this: you provide a library of tested helper scripts that Claude composes at runtime. Instead of writing a Prometheus query from memory, Claude calls your `query_metrics.py` script with the right arguments. Instead of guessing your database schema, Claude reads `schema.md` to understand table relationships.

**Before (Claude writes everything from scratch):**

```python
# Claude generates this every time -- different each invocation
import psycopg2
import os
import json

conn = psycopg2.connect(
    host=os.environ.get("DB_HOST", "localhost"),
    port=os.environ.get("DB_PORT", 5432),
    dbname=os.environ.get("DB_NAME", "myapp"),
    user=os.environ.get("DB_USER", "readonly"),
    password=os.environ.get("DB_PASSWORD", "")
)
cursor = conn.cursor()
cursor.execute("""
    SELECT user_id, event_type, created_at
    FROM events
    WHERE created_at > NOW() - INTERVAL '24 hours'
    ORDER BY created_at DESC
""")
results = cursor.fetchall()
print(json.dumps([dict(zip([d[0] for d in cursor.description], row)) for row in results]))
conn.close()
```

**After (Claude composes from provided helpers):**

```bash
# Claude calls your tested, documented script
python3 scripts/fetch_events.py --source app_db --since 24h --type all --format json
```

The advantages are significant:

| Aspect | From-scratch | Composed from helpers |
|---|---|---|
| Connection handling | Re-written each time, may vary | Consistent, tested, handles errors |
| Schema knowledge | Claude guesses or asks | Reads from `schema.md` |
| Output format | Inconsistent | Standardized JSON contract |
| Error handling | Often minimal | Built into each script |
| Auditability | Hard to review generated code | Review the helper scripts once |
| Reproducibility | Different code each run | Same scripts, different arguments |

### 2. Credential & Connection Management

Data skills need to connect to databases, APIs, and monitoring systems. Hardcoding credentials is a non-starter. The pattern is:

1. **Store connection metadata in `config.json`** -- datasource names, types, which environment variables hold the credentials
2. **Reference secrets via environment variables** -- never put actual passwords or tokens in config
3. **Use `.env` files for local development** -- loaded by the helper scripts, never committed to version control

Here is the layered approach:

```
config.json          →  "connection_env": "APP_DB_URL"     (name of the env var)
.env (local only)    →  APP_DB_URL=postgres://user:pass@localhost:5432/myapp
Environment (CI/CD)  →  APP_DB_URL is set by the deployment system
```

Your `config.json` acts as a registry of datasources:

```json
{
  "datasources": [
    {
      "name": "app_db",
      "type": "postgres",
      "connection_env": "APP_DB_URL",
      "description": "Primary application database (read replica)"
    }
  ]
}
```

Claude reads this config to know which datasources exist and which environment variable to check. The helper scripts read the actual environment variable at runtime. This separation means:
- `config.json` is safe to commit (no secrets)
- `.env` is gitignored (has actual secrets)
- Scripts work in any environment where the env vars are set

### 3. Dynamic Script Generation

The real power of the data skill pattern emerges when Claude composes multiple helpers into a single analysis flow. Rather than running one script at a time, Claude generates a short analysis script that chains your helpers together.

For example, when asked "Show me the error rate trend and the events that correlate with spikes":

```bash
#!/usr/bin/env bash
set -euo pipefail

# Step 1: Get error rate metrics for the last 6 hours
python3 scripts/query_metrics.py \
  --metric http_error_rate \
  --since 6h \
  --step 5m \
  --format json > /tmp/error_rates.json

# Step 2: Find timestamps where error rate exceeded threshold
SPIKE_TIMES=$(python3 -c "
import json, sys
data = json.load(open('/tmp/error_rates.json'))
spikes = [p['timestamp'] for p in data['datapoints'] if p['value'] > 0.05]
print(','.join(spikes[:10]))
")

# Step 3: Fetch events around those spike times
for ts in $(echo "$SPIKE_TIMES" | tr ',' '\n'); do
  echo "=== Events near $ts ==="
  python3 scripts/fetch_events.py \
    --source app_db \
    --around "$ts" \
    --window 5m \
    --type error,deploy,config_change \
    --format json
done
```

Claude is not writing database queries from scratch -- it is composing your tested building blocks. This is the **"Store Scripts & Generate Code"** pattern: the skill stores reliable components, and Claude generates the glue code to wire them together for each specific question.

### 4. Dashboard & Monitoring Integration

Data analysis often starts from a dashboard alert or a Grafana panel. The data-explorer skill includes a dashboard lookup table -- a mapping from problem areas to the dashboards, datasource UIDs, and cluster names that are relevant.

In `config.json`:

```json
{
  "dashboards": {
    "api_latency": {
      "url": "https://grafana.internal/d/abc123/api-latency",
      "datasource_uid": "prometheus-prod",
      "description": "P50/P95/P99 latency by endpoint"
    },
    "error_budget": {
      "url": "https://grafana.internal/d/def456/error-budget",
      "datasource_uid": "prometheus-prod",
      "description": "SLO burn rate and remaining error budget"
    },
    "user_activity": {
      "url": "https://grafana.internal/d/ghi789/user-activity",
      "datasource_uid": "app-postgres",
      "description": "Signups, logins, active sessions over time"
    }
  }
}
```

When Claude investigates an issue, it consults this lookup table to:
- Point the user to the right dashboard for visual confirmation
- Know which datasource UID to query programmatically
- Understand what metrics are already being tracked for a given problem area

This eliminates the "which dashboard do I check?" back-and-forth and keeps investigation workflows fast.

### 5. Result Caching & History

Data analysis is often iterative. You check a metric, make a change, then check again. Without caching, each query is isolated -- Claude cannot tell you what changed.

The result caching pattern stores query results in a local cache directory with timestamps:

```
.cache/data-explorer/
├── 2025-01-15T10:30:00_http_error_rate_6h.json
├── 2025-01-15T11:45:00_http_error_rate_6h.json
└── 2025-01-15T11:45:00_user_events_24h.json
```

Each cached file contains the query parameters and results. When Claude runs the same query later, it can:

1. **Compare current vs previous**: "Error rate was 2.3% an hour ago, now it's 0.8% -- the fix is working"
2. **Detect trends**: "Over the last 3 runs, signup events have been declining"
3. **Avoid redundant queries**: "I already fetched this data 5 minutes ago, reusing cached results"

The diff-based reporting pattern is especially powerful for incident response:

```
## Changes Since Last Check (15 min ago)
- http_error_rate: 4.7% → 1.2% (↓ 74%)
- active_sessions: 12,340 → 14,200 (↑ 15%)
- deploy events: 1 new (deploy #4521 at 10:42)
```

## Key References

| File | Purpose |
|---|---|
| `SKILL.md` | Main skill instructions -- tells Claude how to use the helpers |
| `config.json` | Datasource registry, dashboard lookup, cache settings |
| `scripts/fetch_events.py` | Helper to query events from a database or API |
| `scripts/query_metrics.py` | Helper to query time-series metrics |
| `references/schema.md` | Data model reference -- tables, events, metrics, relationships |

## What You're Building

The `data-explorer` skill -- a self-contained data analysis toolkit that Claude composes at runtime. It includes:

- **Helper scripts** (`scripts/`) that handle the mechanics of connecting to datasources and querying data
- **A schema reference** (`references/schema.md`) so Claude understands your data model without guessing
- **A configuration file** (`config.json`) mapping datasources, dashboards, and cache settings
- **A SKILL.md** that teaches Claude how to compose these pieces into analysis workflows

When you ask Claude "What's driving the spike in error rates?", it will:
1. Read `config.json` to find the right datasource
2. Read `references/schema.md` to understand what tables and metrics are relevant
3. Call `scripts/query_metrics.py` to pull error rate data
4. Call `scripts/fetch_events.py` to find correlated events (deploys, config changes)
5. Compare with cached results if available
6. Present a structured analysis with dashboard links for visual confirmation

## Walkthrough

### Step 1: Create the skill directory structure

Create the following directory tree. You can place this in your project's `.claude/skills/` directory or in `~/.claude/skills/` for global availability:

```bash
mkdir -p data-explorer/scripts
mkdir -p data-explorer/references
```

Your target structure:

```
data-explorer/
├── SKILL.md
├── config.json
├── scripts/
│   ├── fetch_events.py
│   └── query_metrics.py
└── references/
    └── schema.md
```

### Step 2: Create the configuration file

Create `data-explorer/config.json`:

```json
{
  "datasources": [
    {
      "name": "app_db",
      "type": "postgres",
      "connection_env": "APP_DB_URL",
      "description": "Primary application database (read replica)",
      "default_schema": "public"
    },
    {
      "name": "metrics",
      "type": "prometheus",
      "connection_env": "PROMETHEUS_URL",
      "description": "Prometheus metrics server"
    },
    {
      "name": "logs",
      "type": "elasticsearch",
      "connection_env": "ELASTICSEARCH_URL",
      "description": "Centralized log storage"
    }
  ],
  "dashboards": {
    "api_latency": {
      "url": "https://grafana.internal/d/abc123/api-latency",
      "datasource_uid": "prometheus-prod",
      "description": "P50/P95/P99 latency by endpoint"
    },
    "error_budget": {
      "url": "https://grafana.internal/d/def456/error-budget",
      "datasource_uid": "prometheus-prod",
      "description": "SLO burn rate and remaining error budget"
    },
    "user_activity": {
      "url": "https://grafana.internal/d/ghi789/user-activity",
      "datasource_uid": "app-postgres",
      "description": "Signups, logins, active sessions over time"
    },
    "infrastructure": {
      "url": "https://grafana.internal/d/jkl012/infrastructure",
      "datasource_uid": "prometheus-prod",
      "description": "CPU, memory, disk, network by service"
    }
  },
  "cache_dir": ".cache/data-explorer",
  "default_time_range": "1h",
  "max_cache_age_minutes": 60
}
```

Key design decisions:
- **`connection_env`** references environment variable names, not actual connection strings
- **`dashboards`** map problem areas to URLs, making it easy for Claude to link to visual tools
- **`cache_dir`** is relative to the project root, keeping caches per-project
- **`max_cache_age_minutes`** tells Claude when cached data is too stale to reuse

### Step 3: Create the schema reference

Create `data-explorer/references/schema.md`. This is the document Claude reads to understand your data model. The full file is provided at `skill/data-explorer/references/schema.md`, but here's what it covers for a typical SaaS application:

- **Database tables**: `users`, `events`, `organizations`, `deployments` -- each with column types and descriptions
- **Event types**: 11 types across user, API, billing, deploy, and config categories -- each with its JSON property payload
- **Prometheus metrics**: 7 metrics covering HTTP requests, latency, error rates, sessions, and background jobs
- **Relationships**: how tables connect (users → orgs, events → users) and how events correlate with metrics

The schema reference is Claude's "cheat sheet" for your data model. Without it, Claude would have to guess table names, column names, and event types -- or ask you every time.

### Step 4: Create the fetch_events.py helper

Create `data-explorer/scripts/fetch_events.py`. The full script is provided in the `skill/data-explorer/scripts/` directory, but here are the key design decisions to understand:

The script follows these design principles:

- **Clear input/output contract**: CLI args in, JSON to stdout, errors to stderr
- **Config-driven connections**: reads `config.json` for datasource metadata, env vars for actual secrets
- **Built-in caching**: writes results to the cache directory automatically
- **Safety**: opens the database in read-only mode
- **Good error messages**: tells the user exactly what's wrong and how to fix it

The key CLI flags are:

```
--source   Datasource name from config.json (e.g., app_db)
--since    Lookback duration (e.g., 24h, 30m, 7d)
--around   Center timestamp for point-in-time queries (ISO 8601)
--window   Window around --around (default: 5m)
--type     Comma-separated event types, or 'all'
--user-id  Filter by user
--limit    Max results (default: 1000)
--no-cache Skip caching
```

Example invocations:

```bash
python3 scripts/fetch_events.py --source app_db --since 24h --type user.login,api.error
python3 scripts/fetch_events.py --source app_db --around 2025-01-15T10:30:00Z --window 5m
python3 scripts/fetch_events.py --source app_db --since 1h --user-id abc-123 --limit 100
```

Read the full script at `skill/data-explorer/scripts/fetch_events.py` to see the implementation details: parameterized SQL query building, read-only connection mode, result caching, and JSON serialization.

### Step 5: Create the query_metrics.py helper

Create `data-explorer/scripts/query_metrics.py`. This script queries Prometheus and shares the same design principles as `fetch_events.py` (CLI args in, JSON stdout, errors stderr, config-driven, auto-caching).

The key CLI flags are:

```
--metric   Metric name (e.g., http_error_rate, active_sessions)
--since    Lookback duration (e.g., 1h, 6h, 7d)
--step     Resolution (default: 1m)
--agg      Aggregation: avg, max, min, sum, rate, p50, p90, p95, p99
--labels   Filter labels (e.g., "endpoint=/api/users,method=GET")
--no-cache Skip caching
```

Example invocations:

```bash
python3 scripts/query_metrics.py --metric http_error_rate --since 1h --step 1m
python3 scripts/query_metrics.py --metric http_requests_total --since 6h --step 5m --agg rate
python3 scripts/query_metrics.py --metric http_request_duration_seconds --since 1h --agg p95 --step 1m
```

Read the full script at `skill/data-explorer/scripts/query_metrics.py` for the PromQL query builder, Prometheus HTTP API integration, and histogram quantile support.

### Step 6: Create the SKILL.md

Create `data-explorer/SKILL.md`. This is the file Claude reads when the skill is activated. The full file is provided in `skill/data-explorer/SKILL.md`, but here are the key sections to understand:

**Frontmatter** -- description includes trigger phrases like "check metrics", "look at events", "analyze data", "what's happening with [metric]", "compare to last time":

```yaml
---
name: data-explorer
description: >
  Explores application data by composing helper scripts for fetching events,
  querying metrics, and analyzing trends. Use when the user asks to "check
  metrics", "look at events", "analyze data", "what's happening with
  [metric/feature]", "investigate [issue]", or "compare to last time".
---
```

**Available Scripts** -- documents each helper with its flags and usage, so Claude knows what tools it has.

**Workflow** -- a 7-step process: understand the question, read config, read schema, compose scripts, check cache, run analysis, link dashboards. This gives Claude the right approach without railroading specific steps.

**Result Caching & Comparison** -- instructions for diff-based reporting when the user asks about changes or trends.

**Gotchas** -- 7 items covering credentials, read-only mode, rate limits, large result sets, time zones, missing dependencies, and cache staleness.

Read the full SKILL.md at `skill/data-explorer/SKILL.md`.

### Step 7: Verify the structure

Check that everything is in place:

```bash
find data-explorer/ -type f | sort
```

Expected output:

```
data-explorer/SKILL.md
data-explorer/config.json
data-explorer/references/schema.md
data-explorer/scripts/fetch_events.py
data-explorer/scripts/query_metrics.py
```

Make the scripts executable:

```bash
chmod +x data-explorer/scripts/fetch_events.py
chmod +x data-explorer/scripts/query_metrics.py
```

### Step 8: Test the skill structure

Before connecting real datasources, verify the skill loads correctly:

```bash
# Start a Claude session with the skill loaded
claude --skills-dir ./data-explorer

# Then ask:
# "What data sources are available?"
# Claude should read config.json and list app_db, metrics, and logs

# "What event types can I query?"
# Claude should read references/schema.md and list the event types

# "Show me the error rate for the last hour"
# Claude should compose a call to query_metrics.py with the right arguments
```

### Step 9: Connect a real datasource (optional)

To test with real data, set the environment variables:

```bash
# For PostgreSQL
export APP_DB_URL="postgres://readonly:password@localhost:5432/myapp"

# For Prometheus
export PROMETHEUS_URL="http://localhost:9090"

# Then run the scripts directly to verify
python3 data-explorer/scripts/fetch_events.py --source app_db --since 1h --type all
python3 data-explorer/scripts/query_metrics.py --metric http_requests_total --since 1h --step 5m --agg rate
```

If you do not have a local database or Prometheus instance, the scripts will exit with a clear error message pointing to the missing environment variable. This is by design -- the skill works in any environment where the right env vars are set.

## Exercises

1. **Add a new datasource**. Extend `config.json` with a fourth datasource (for example, a Redis cache or a ClickHouse analytics database). Update `references/schema.md` with tables or key patterns for the new source. Create a new helper script `scripts/query_analytics.py` that connects to the new source. Test that Claude discovers and uses the new script through the skill.

2. **Build a comparison report**. Run a metrics query twice with a gap in between. Manually verify that two cache files are created. Then ask Claude "Compare the current error rate to the last check." Verify that Claude reads both cache files and produces a diff-based report showing changes with direction arrows and percentages.

3. **Extend the schema reference**. Add a new entity (for example, `feature_flags` with columns for flag name, enabled state, rollout percentage, and targeting rules). Add corresponding event types (`feature_flag.toggled`, `feature_flag.evaluated`). Ask Claude a question about feature flag usage and verify it references the new schema entries.

4. **Create a dashboard lookup workflow**. Ask Claude "Which dashboard should I check for API latency issues?" Verify it reads the dashboards section of `config.json` and returns the correct URL and description. Then ask "What metrics feed that dashboard?" and verify it cross-references the datasource UID with the schema.

## Verification Checklist

- [ ] `data-explorer/SKILL.md` exists with valid YAML frontmatter and a description mentioning data, metrics, events, and analysis
- [ ] `data-explorer/config.json` is valid JSON with datasources, dashboards, cache_dir, and default_time_range
- [ ] `data-explorer/scripts/fetch_events.py` exists, is executable, and has a `#!/usr/bin/env python3` shebang
- [ ] `data-explorer/scripts/query_metrics.py` exists, is executable, and has a `#!/usr/bin/env python3` shebang
- [ ] `data-explorer/references/schema.md` documents tables, event types, metrics, and relationships
- [ ] Running `fetch_events.py --help` prints usage information with examples
- [ ] Running `query_metrics.py --help` prints usage information with examples
- [ ] Both scripts exit with a clear error if the required environment variable is not set
- [ ] Both scripts output JSON to stdout and errors to stderr
- [ ] The SKILL.md references all helper scripts with usage examples
- [ ] The SKILL.md includes a gotchas section covering credentials, read-only mode, rate limits, and cache staleness
- [ ] `config.json` uses environment variable references, not hardcoded secrets
- [ ] Cache files are written to the configured cache_dir after each query
- [ ] Claude can read config.json, schema.md, and compose script calls to answer data questions

## What's Next

In **Course 14: Runbook Skills -- Symptom-Driven Investigation**, you'll learn:
- How runbooks differ from simple scripts (they involve judgment and branching)
- Symptom routing with decision trees that map symptoms to investigation paths
- Multi-tool investigation composing MCP tools, CLI tools, and log sources
- Structured report output with severity classification and evidence linking
- Forked investigation using `context: fork` to avoid polluting the main context
- You'll build a `service-debugger` skill that takes an error signature and produces a structured findings report

---
name: data-explorer
description: >
  Explores application data by composing helper scripts for fetching events,
  querying metrics, and analyzing trends. Use when the user asks to "check
  metrics", "look at events", "analyze data", "what's happening with
  [metric/feature]", "investigate [issue]", or "compare to last time".
---

# Data Explorer

You have a library of tested helper scripts for data analysis. **Always prefer
calling these scripts over writing queries from scratch.**

## Available Scripts

### scripts/fetch_events.py

Fetches events from the application database.

**Usage:**

```bash
python3 scripts/fetch_events.py --source <datasource> --since <duration> [options]
```

**Key flags:**

| Flag | Required | Description |
|---|---|---|
| `--source` | Yes | Datasource name from config.json (e.g., `app_db`) |
| `--since` | Yes* | Lookback duration (e.g., `24h`, `7d`, `30m`) |
| `--around` | Yes* | Center timestamp for point-in-time queries (ISO 8601) |
| `--window` | No | Window around `--around` (default: `5m`) |
| `--type` | No | Comma-separated event types, or `all` (default: `all`) |
| `--user-id` | No | Filter by user ID |
| `--limit` | No | Max results (default: 1000, max: 10000) |
| `--format` | No | Output format: `json` or `jsonl` (default: `json`) |
| `--no-cache` | No | Skip writing results to cache |

*One of `--since` or `--around` is required.

**Examples:**

```bash
# All events in the last hour
python3 scripts/fetch_events.py --source app_db --since 1h

# Login failures in the last 24 hours
python3 scripts/fetch_events.py --source app_db --since 24h --type user.login --limit 500

# Events around a specific incident timestamp
python3 scripts/fetch_events.py --source app_db --around 2025-01-15T10:30:00Z --window 10m --type api.error,deploy.completed

# Events for a specific user
python3 scripts/fetch_events.py --source app_db --since 7d --user-id abc-123-def
```

### scripts/query_metrics.py

Queries time-series metrics from Prometheus.

**Usage:**

```bash
python3 scripts/query_metrics.py --metric <name> --since <duration> [options]
```

**Key flags:**

| Flag | Required | Description |
|---|---|---|
| `--metric` | Yes | Metric name (e.g., `http_error_rate`, `active_sessions`) |
| `--since` | Yes | Lookback duration (e.g., `1h`, `6h`, `7d`) |
| `--step` | No | Query resolution (default: `1m`) |
| `--agg` | No | Aggregation: `avg`, `max`, `min`, `sum`, `rate`, `p50`, `p90`, `p95`, `p99` |
| `--labels` | No | Label filters: `"endpoint=/api/users,method=GET"` |
| `--format` | No | Output format: `json` or `jsonl` (default: `json`) |
| `--no-cache` | No | Skip writing results to cache |

**Examples:**

```bash
# Error rate over the last hour at 1-minute resolution
python3 scripts/query_metrics.py --metric http_error_rate --since 1h --step 1m

# P95 request latency for a specific endpoint
python3 scripts/query_metrics.py --metric http_request_duration_seconds --since 6h --agg p95 --labels "endpoint=/api/users"

# Request rate over the last day at 15-minute resolution
python3 scripts/query_metrics.py --metric http_requests_total --since 24h --step 15m --agg rate

# Active sessions trend
python3 scripts/query_metrics.py --metric active_sessions --since 7d --step 1h
```

## Configuration

Read `config.json` before querying to understand:

- Which **datasources** are available and what type each is
- Which **dashboards** relate to which problem areas (include URLs in your response)
- The **cache directory** path and **default time range**
- The **max cache age** for deciding whether to reuse cached results

## Data Model

Read `references/schema.md` to understand:

- Database tables and their columns
- Event types and their property payloads
- Metric names and what they measure
- Relationships between entities

**Always consult the schema before constructing queries.** Do not guess table
names, column names, event types, or metric names.

## Workflow

1. **Understand the question** -- what is the user trying to learn?
2. **Read config.json** -- which datasources and dashboards are relevant?
3. **Read references/schema.md** -- which tables, events, or metrics answer the question?
4. **Check the cache** -- look in the cache directory for recent results from
   similar queries. If a cached result exists and is less than
   `max_cache_age_minutes` old, reuse it and note you are using cached data.
5. **Compose a script** using the helpers above. For multi-step analysis, write
   a short bash script that chains multiple helper calls together.
6. **Run the analysis** and present structured findings.
7. **Link to dashboards** -- if a relevant dashboard exists in config.json,
   include the URL so the user can see the visual view.

## Result Caching & Comparison

Both scripts automatically cache results in the `cache_dir` from config.json.

When the user asks about **changes**, **trends**, or **comparisons**:

1. List files in the cache directory to find previous results for the same query
2. Load the previous result and the current result
3. Compute differences and report them in a structured format:

```
## Changes Since Last Check (<time ago>)
- metric_name: old_value → new_value (↑/↓ percentage%)
- New events: count and types since last check
- Notable changes: anything that crossed a threshold
```

When composing multi-step analyses, save intermediate results to the cache
directory for reuse in subsequent steps.

## Gotchas

- **Never hardcode credentials.** Always read connection details from
  environment variables via config.json. If an env var is not set, tell the
  user which variable to set and how.
- **Always use read-only connections.** The helper scripts open database
  connections in read-only mode. Do not modify this behavior or run write
  queries.
- **Respect rate limits.** Do not run more than 5 metric queries in quick
  succession. If you need many metrics, increase the `--step` interval to
  reduce data volume.
- **Large result sets.** If a query returns more than 5,000 rows, summarize
  the results (counts, distributions, top-N) rather than printing everything.
  Use `--limit` to cap results.
- **Time zones.** All timestamps in the helpers use UTC. When presenting
  results to the user, note that times are in UTC unless the user specifies
  otherwise.
- **Missing dependencies.** `fetch_events.py` requires `psycopg2-binary`.
  If it is not installed, the error message will tell the user how to
  install it. Do not attempt to install it automatically.
- **Cache staleness.** Check `max_cache_age_minutes` in config.json before
  reusing cached data. If the cache is older than that threshold, re-run the
  query.
- **Script paths.** Always call scripts relative to this skill directory.
  Use `scripts/fetch_events.py`, not an absolute path.

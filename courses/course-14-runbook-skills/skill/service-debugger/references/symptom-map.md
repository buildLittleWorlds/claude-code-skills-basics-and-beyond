# Symptom Map — Investigation Routing Guide

This file maps common operational symptoms to investigation paths. When a symptom is reported, find the matching category (or categories) below and follow the prescribed investigation approach.

Symptoms often span multiple categories. Start with the **primary** match and check **secondary** categories if the primary investigation doesn't yield a root cause.

---

## High Latency / Slow Responses

Symptoms: API response times increased, requests timing out, users reporting slow page loads, p99 latency spikes, upstream services reporting slow downstream calls.

### Tools to Use
- `git log --since="3 days ago" --oneline` -- identify recent code changes
- `git log --since="7 days ago" --all -- "*.sql" "*/migrations/*"` -- check for schema/query changes
- `grep -rn "timeout" --include="*.yaml" --include="*.yml" --include="*.json" --include="*.toml"` -- find timeout configurations
- `grep -rn "sleep\|delay\|setTimeout\|time\.Sleep" --include="*.ts" --include="*.js" --include="*.py" --include="*.go"` -- find artificial delays
- `grep -rn "SELECT\|INSERT\|UPDATE\|DELETE" --include="*.ts" --include="*.js" --include="*.py" --include="*.go"` -- find database queries
- Check application logs for slow query warnings or timeout messages

### What to Look For
- Recent code changes to request handlers, middleware, or hot paths
- New database queries or changes to existing queries (especially missing WHERE clauses or JOINs)
- Added middleware or interceptors that add processing time
- Changed timeout values, connection pool sizes, or retry configurations
- New synchronous calls in previously async code paths
- N+1 query patterns (loop that makes a database call per iteration)
- Large payload serialization/deserialization

### Common Root Causes
- N+1 query introduced in recent commit
- Missing database index after schema migration
- Connection pool exhaustion (pool size too small for load)
- External service degradation causing cascading slowness
- Added logging or tracing with synchronous I/O
- Regex with catastrophic backtracking on certain inputs
- Large response payloads without pagination

### Escalation Criteria
- Latency exceeding SLA thresholds for more than 15 minutes
- Cascading failures to upstream services
- Database connection pool fully exhausted
- No code or config changes correlate with the timeline (may indicate infrastructure issue)

---

## 5xx Errors / Service Crashes

Symptoms: HTTP 500/502/503 errors, service restarts, process crashes, unhandled exceptions in logs, health check failures, container OOMKilled events.

### Tools to Use
- `git log --since="3 days ago" --oneline` -- identify recent changes
- `git diff HEAD~5 -- src/` -- compare recent code changes
- `grep -rn "catch\|except\|rescue\|recover" --include="*.ts" --include="*.js" --include="*.py" --include="*.go"` -- find error handling
- `grep -rn "throw\|raise\|panic" --include="*.ts" --include="*.js" --include="*.py" --include="*.go"` -- find error sources
- `grep -rn "process\.exit\|os\.Exit\|sys\.exit" --include="*.ts" --include="*.js" --include="*.py" --include="*.go"` -- find hard exits
- Check for crash logs, core dumps, or error reporting output

### What to Look For
- Unhandled exceptions or promise rejections
- Null/undefined dereferences on new code paths
- Missing error handling on async operations
- Panics or fatal errors in recently changed code
- Resource exhaustion (file descriptors, memory, connections)
- Incompatible dependency updates
- Configuration errors (missing env vars, wrong URLs, bad credentials)

### Common Root Causes
- Unhandled exception in new code path
- Null pointer on edge case not covered by tests
- Dependency update with breaking API change
- Missing or incorrect environment variable in deployment
- Database connection failure without retry logic
- Race condition triggered under load
- Stack overflow from unbounded recursion

### Escalation Criteria
- Service completely unavailable (all requests failing)
- Crash loop with no successful restarts
- Data corruption suspected
- Multiple services affected simultaneously

---

## Memory Leaks / OOM (Out of Memory)

Symptoms: Steadily increasing memory usage, OOMKilled events, service restarts at regular intervals, garbage collection pauses increasing, swap usage climbing.

### Tools to Use
- `git log --since="7 days ago" --oneline` -- check for recent changes (memory leaks often have delayed onset)
- `grep -rn "cache\|Cache\|memoize\|memo\|store\|Store" --include="*.ts" --include="*.js" --include="*.py" --include="*.go"` -- find caching code
- `grep -rn "addEventListener\|on(\|subscribe\|setInterval\|setImmediate" --include="*.ts" --include="*.js"` -- find event listeners and timers (JS/TS)
- `grep -rn "global\|singleton\|Singleton\|class_variable\|@@" --include="*.py" --include="*.rb"` -- find global/singleton state
- `grep -rn "append\|push\|add\|put" --include="*.ts" --include="*.js" --include="*.py" --include="*.go"` -- find growing collections (narrow by context)
- Check for memory limit configurations in deployment manifests

### What to Look For
- Unbounded caches or maps that grow without eviction
- Event listeners registered without cleanup (especially in request handlers)
- Closures capturing large objects and preventing garbage collection
- Global or singleton collections that accumulate entries
- Connection objects not properly closed or returned to pool
- Large buffers allocated in loops without release
- Circular references preventing garbage collection

### Common Root Causes
- In-memory cache without TTL or size limit
- Event listener leak: registering per-request handlers without removing them
- Connection leak: database or HTTP connections not closed on error paths
- Closure leak: callbacks holding references to large request/response objects
- Buffer accumulation: reading large files/streams into memory without streaming
- Singleton pattern accumulating state across requests

### Escalation Criteria
- OOM events occurring more than once per hour
- Memory usage growing faster than 100MB/hour
- Service unable to serve requests due to GC pauses
- Available system memory below 10%

---

## Connection Failures / Timeouts

Symptoms: Connection refused errors, connection timeout errors, DNS resolution failures, TLS handshake failures, "no route to host" errors, connection pool exhausted warnings.

### Tools to Use
- `grep -rn "host\|port\|url\|endpoint\|connection" --include="*.env" --include="*.env.*" --include="*.yaml" --include="*.yml" --include="*.json"` -- check connection configs
- `grep -rn "connect\|createConnection\|createPool\|DriverManager\|dial" --include="*.ts" --include="*.js" --include="*.py" --include="*.go" --include="*.java"` -- find connection creation code
- `grep -rn "retry\|backoff\|reconnect" --include="*.ts" --include="*.js" --include="*.py" --include="*.go"` -- find retry logic
- `git diff HEAD~5 -- "*.env" "*.yaml" "*.yml" "*.json" "*.toml"` -- check recent config changes
- `cat docker-compose.yml 2>/dev/null || cat docker-compose.yaml 2>/dev/null` -- check service dependencies

### What to Look For
- Changed connection strings, hostnames, or ports in configuration
- DNS names that may have changed or become unresolvable
- TLS certificates that may have expired or been rotated
- Connection pool settings (size, timeout, idle timeout)
- Missing retry logic or backoff strategy
- Firewall rules or network policy changes
- Service discovery configuration changes

### Common Root Causes
- Configuration change pointing to wrong host or port
- TLS certificate expired or rotated without updating trust store
- Connection pool size too small for concurrent request volume
- DNS resolution failure (stale cache, changed records)
- Network policy or firewall rule blocking traffic
- Downstream service crashed or was redeployed
- Connection idle timeout mismatch between client and server

### Escalation Criteria
- Complete inability to connect to a critical dependency
- Connection failures affecting multiple services (network-level issue)
- TLS/certificate issues requiring infrastructure team
- DNS resolution failures across the cluster

---

## Data Inconsistency / Stale Data

Symptoms: Users seeing outdated information, data not updating after writes, different results on repeated reads, cache showing old values, replication lag warnings, eventual consistency violations.

### Tools to Use
- `grep -rn "cache\|Cache\|redis\|Redis\|memcache\|CDN" --include="*.ts" --include="*.js" --include="*.py" --include="*.go" --include="*.yaml"` -- find caching layers
- `grep -rn "ttl\|TTL\|expire\|maxAge\|max-age\|stale" --include="*.ts" --include="*.js" --include="*.py" --include="*.go" --include="*.yaml"` -- find TTL/expiry configs
- `grep -rn "replica\|secondary\|slave\|read.*pool\|readonly" --include="*.ts" --include="*.js" --include="*.py" --include="*.go" --include="*.yaml"` -- find read replica usage
- `git log --since="5 days ago" --all -- "*cache*" "*redis*" "*config*"` -- recent cache-related changes
- Check database migration files for schema changes that might affect queries

### What to Look For
- Cache TTL set too high for the data's volatility
- Read-after-write going to a replica instead of primary
- Missing cache invalidation on write paths
- Stale CDN or reverse proxy cache (check Cache-Control headers)
- Database replication lag
- Race conditions in concurrent write paths
- Missing transaction boundaries around multi-step operations

### Common Root Causes
- Cache invalidation not triggered on the write path
- Cache TTL too long for frequently changing data
- Read-after-write routed to stale replica
- CDN or proxy serving cached response after data change
- Missing optimistic locking causing lost updates
- Race condition: two concurrent writes, last one wins without merge
- Schema migration changed column semantics without updating all read paths

### Escalation Criteria
- Data corruption (inconsistent state that can't self-heal)
- Financial or compliance data affected
- Replication lag exceeding acceptable thresholds
- Users making decisions based on stale data

---

## Authentication / Authorization Failures

Symptoms: 401 Unauthorized errors, 403 Forbidden errors, JWT validation failures, token expiration errors, "access denied" messages, SSO/OAuth flow failures, CORS errors on authenticated endpoints.

### Tools to Use
- `grep -rn "auth\|Auth\|jwt\|JWT\|token\|Token\|session\|Session\|cookie\|Cookie" --include="*.ts" --include="*.js" --include="*.py" --include="*.go"` -- find auth code
- `grep -rn "middleware\|interceptor\|guard\|policy\|permission" --include="*.ts" --include="*.js" --include="*.py" --include="*.go"` -- find auth middleware
- `grep -rn "secret\|SECRET\|key\|KEY\|issuer\|audience" --include="*.env" --include="*.env.*" --include="*.yaml" --include="*.yml"` -- check auth config (be careful with actual secrets)
- `git log --since="3 days ago" --all -- "*auth*" "*middleware*" "*guard*" "*policy*"` -- recent auth changes
- `grep -rn "cors\|CORS\|origin\|Origin\|Access-Control" --include="*.ts" --include="*.js" --include="*.py" --include="*.go" --include="*.yaml"` -- check CORS config

### What to Look For
- Changed JWT signing keys or secrets
- Token expiration settings that may have been modified
- Middleware ordering changes (auth middleware must run before route handlers)
- CORS configuration changes (allowed origins, credentials headers)
- OAuth/OIDC provider configuration changes
- Role or permission definition changes
- Session storage configuration changes (Redis, cookies, etc.)

### Common Root Causes
- JWT signing secret rotated without updating all services
- Auth middleware reordering caused it to run after the route handler
- Token expiration set too short or clock skew between services
- CORS allowed origins not updated after domain change
- OAuth redirect URI mismatch after deployment URL change
- Permission check added to endpoint without updating role definitions
- Session storage (Redis) connection failure falling through silently

### Escalation Criteria
- All users unable to authenticate (complete auth outage)
- Security breach suspected (unauthorized access detected)
- Token signing key compromised
- SSO provider outage affecting authentication

---

## Deployment-Related Issues

Symptoms: Problems starting immediately after a deployment, new version not behaving as expected, rollback needed, health checks failing after deploy, gradual degradation after deploy, feature flags not working as expected.

### Tools to Use
- `git log --oneline -20` -- see the most recent commits
- `git diff HEAD~1 -- .` -- compare with previous version
- `git diff HEAD~1 -- "*.env" "*.yaml" "*.yml" "*.json" "*.toml" "Dockerfile" "docker-compose*"` -- config changes in last deploy
- `git show HEAD --stat` -- files changed in the latest commit
- `grep -rn "feature.*flag\|toggle\|experiment\|variant" --include="*.ts" --include="*.js" --include="*.py" --include="*.go" --include="*.yaml"` -- feature flag usage
- Check migration files for schema changes that may not have run
- `cat Dockerfile 2>/dev/null` -- check build configuration

### What to Look For
- Environment variables added in code but missing from deployment config
- Database migrations that need to run but haven't
- New dependencies that failed to install
- Build/compile errors that were masked by caching
- Feature flags with incorrect default values
- Changed port bindings, health check paths, or startup commands
- Incompatible schema changes (column renames, type changes)

### Common Root Causes
- Missing environment variable in production deployment
- Database migration not applied before new code deployed
- Build cache serving stale artifacts
- Dependency version mismatch between dev and production
- Feature flag defaulting to wrong value in production environment
- Health check path changed in code but not in deployment config
- Schema migration requires downtime but was deployed without it

### Escalation Criteria
- Deployment causing data corruption or loss
- Unable to rollback (migration is irreversible)
- Deployment affecting multiple services
- Zero successful requests after deployment
- Health checks failing with no clear code cause (infrastructure issue)

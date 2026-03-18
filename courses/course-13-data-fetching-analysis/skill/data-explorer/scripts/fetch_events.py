#!/usr/bin/env python3
"""Fetch events from the application database.

Usage:
    python3 fetch_events.py --source app_db --since 24h --type user.login,api.error
    python3 fetch_events.py --source app_db --around 2025-01-15T10:30:00Z --window 5m
    python3 fetch_events.py --source app_db --since 1h --user-id abc-123 --format json

Output:
    JSON array of event objects to stdout. Errors and diagnostics go to stderr.

Environment:
    Reads the connection URL from the environment variable specified in
    config.json for the given --source. For example, if source is "app_db"
    and config.json maps that to connection_env "APP_DB_URL", this script
    reads the APP_DB_URL environment variable.
"""

import argparse
import json
import os
import sys
from datetime import datetime, timedelta, timezone
from urllib.parse import urlparse


# ---------------------------------------------------------------------------
# Time parsing
# ---------------------------------------------------------------------------

def parse_duration(duration_str: str) -> timedelta:
    """Parse a human-friendly duration like '24h', '30m', '7d' into a timedelta."""
    units = {"s": "seconds", "m": "minutes", "h": "hours", "d": "days", "w": "weeks"}
    suffix = duration_str[-1].lower()
    if suffix not in units:
        raise ValueError(
            f"Unknown duration unit '{suffix}' in '{duration_str}'. "
            f"Supported: {', '.join(f'{k} ({v})' for k, v in units.items())}"
        )
    try:
        value = int(duration_str[:-1])
    except ValueError:
        raise ValueError(f"Invalid numeric value in duration '{duration_str}'")
    return timedelta(**{units[suffix]: value})


def parse_timestamp(ts_str: str) -> datetime:
    """Parse an ISO 8601 timestamp string."""
    ts_str = ts_str.replace("Z", "+00:00")
    return datetime.fromisoformat(ts_str)


# ---------------------------------------------------------------------------
# Config loading
# ---------------------------------------------------------------------------

def load_config() -> dict:
    """Load config.json from the skill directory (one level up from scripts/)."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    config_path = os.path.join(script_dir, "..", "config.json")
    try:
        with open(config_path) as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: config.json not found at {os.path.abspath(config_path)}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: invalid JSON in config.json: {e}", file=sys.stderr)
        sys.exit(1)


def get_connection_url(config: dict, source_name: str) -> str:
    """Resolve the connection URL for a named datasource."""
    for ds in config.get("datasources", []):
        if ds["name"] == source_name:
            env_var = ds["connection_env"]
            url = os.environ.get(env_var)
            if not url:
                print(
                    f"Error: environment variable {env_var} is not set.\n"
                    f"Set it with: export {env_var}=<connection-url>\n"
                    f"Or add it to your .env file.",
                    file=sys.stderr,
                )
                sys.exit(1)
            return url
    available = [ds["name"] for ds in config.get("datasources", [])]
    print(
        f"Error: datasource '{source_name}' not found in config.json.\n"
        f"Available datasources: {', '.join(available)}",
        file=sys.stderr,
    )
    sys.exit(1)


# ---------------------------------------------------------------------------
# Query building & execution
# ---------------------------------------------------------------------------

def build_query(args) -> tuple:
    """Build a SQL query and params from CLI arguments.

    Returns (query_string, params_list).
    """
    conditions = []
    params = []

    # Time filter: --since or --around+--window
    if args.around:
        center = parse_timestamp(args.around)
        window = parse_duration(args.window or "5m")
        conditions.append("created_at BETWEEN %s AND %s")
        params.extend([center - window, center + window])
    elif args.since:
        since_delta = parse_duration(args.since)
        cutoff = datetime.now(timezone.utc) - since_delta
        conditions.append("created_at >= %s")
        params.append(cutoff)

    # Event type filter
    if args.type and args.type != "all":
        types = [t.strip() for t in args.type.split(",")]
        placeholders = ", ".join(["%s"] * len(types))
        conditions.append(f"event_type IN ({placeholders})")
        params.extend(types)

    # User filter
    if args.user_id:
        conditions.append("user_id = %s")
        params.append(args.user_id)

    where = " AND ".join(conditions) if conditions else "TRUE"
    limit = min(args.limit, 10000)

    query = f"""
        SELECT id, user_id, event_type, properties, created_at, session_id
        FROM events
        WHERE {where}
        ORDER BY created_at DESC
        LIMIT {limit}
    """
    return query, params


def execute_query(connection_url: str, query: str, params: list) -> list:
    """Execute a query against PostgreSQL and return results as dicts."""
    try:
        import psycopg2
        import psycopg2.extras
    except ImportError:
        print(
            "Error: psycopg2 is not installed.\n"
            "Install it with: pip install psycopg2-binary",
            file=sys.stderr,
        )
        sys.exit(1)

    try:
        conn = psycopg2.connect(connection_url)
        conn.set_session(readonly=True)
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(query, params)
            rows = cur.fetchall()
        conn.close()
    except psycopg2.OperationalError as e:
        print(f"Error: could not connect to database: {e}", file=sys.stderr)
        sys.exit(1)
    except psycopg2.Error as e:
        print(f"Error: query failed: {e}", file=sys.stderr)
        sys.exit(1)

    # Serialize datetime and other non-JSON-native types
    def serialize(obj):
        if isinstance(obj, datetime):
            return obj.isoformat()
        if isinstance(obj, bytes):
            return obj.decode("utf-8", errors="replace")
        return str(obj)

    return json.loads(json.dumps(rows, default=serialize))


# ---------------------------------------------------------------------------
# Caching
# ---------------------------------------------------------------------------

def cache_results(config: dict, results: list, args) -> str:
    """Write results to the cache directory. Returns the cache file path."""
    cache_dir = config.get("cache_dir", ".cache/data-explorer")
    os.makedirs(cache_dir, exist_ok=True)

    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S")
    label = f"{args.source}_{args.type or 'all'}_{args.since or 'point'}"
    label = label.replace(",", "-").replace("/", "-")
    filename = f"{timestamp}_{label}.json"
    filepath = os.path.join(cache_dir, filename)

    cache_entry = {
        "query_params": {
            "source": args.source,
            "since": args.since,
            "around": args.around,
            "window": args.window,
            "type": args.type,
            "user_id": args.user_id,
            "limit": args.limit,
        },
        "fetched_at": timestamp,
        "result_count": len(results),
        "results": results,
    }

    with open(filepath, "w") as f:
        json.dump(cache_entry, f, indent=2)

    print(f"Cached {len(results)} results to {filepath}", file=sys.stderr)
    return filepath


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Fetch events from the application database.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s --source app_db --since 24h --type user.login,api.error
  %(prog)s --source app_db --around 2025-01-15T10:30:00Z --window 5m
  %(prog)s --source app_db --since 1h --user-id abc-123 --limit 100
  %(prog)s --source app_db --since 6h --type deploy.completed --no-cache
        """,
    )
    parser.add_argument(
        "--source", required=True,
        help="Datasource name from config.json (e.g., app_db)",
    )
    parser.add_argument(
        "--since",
        help="Duration to look back (e.g., 24h, 30m, 7d)",
    )
    parser.add_argument(
        "--around",
        help="Center timestamp for a time window query (ISO 8601)",
    )
    parser.add_argument(
        "--window", default="5m",
        help="Window size around --around timestamp (default: 5m)",
    )
    parser.add_argument(
        "--type", default="all",
        help="Comma-separated event types, or 'all' (default: all)",
    )
    parser.add_argument(
        "--user-id",
        help="Filter events by user ID",
    )
    parser.add_argument(
        "--limit", type=int, default=1000,
        help="Maximum number of results to return (default: 1000, max: 10000)",
    )
    parser.add_argument(
        "--format", choices=["json", "jsonl"], default="json",
        help="Output format (default: json)",
    )
    parser.add_argument(
        "--no-cache", action="store_true",
        help="Skip writing results to the cache directory",
    )

    args = parser.parse_args()

    # Validate: need either --since or --around
    if not args.since and not args.around:
        parser.error("either --since or --around is required")

    # Load config and resolve connection
    config = load_config()
    connection_url = get_connection_url(config, args.source)

    # Build and execute query
    query, params = build_query(args)
    print(f"Querying {args.source} for events...", file=sys.stderr)
    results = execute_query(connection_url, query, params)
    print(f"Fetched {len(results)} events.", file=sys.stderr)

    # Cache results unless --no-cache
    if not args.no_cache:
        cache_results(config, results, args)

    # Output results to stdout
    if args.format == "jsonl":
        for row in results:
            print(json.dumps(row))
    else:
        print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()

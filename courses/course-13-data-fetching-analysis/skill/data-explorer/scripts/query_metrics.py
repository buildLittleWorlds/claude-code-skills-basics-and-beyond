#!/usr/bin/env python3
"""Query time-series metrics from Prometheus.

Usage:
    python3 query_metrics.py --metric http_error_rate --since 1h --step 1m
    python3 query_metrics.py --metric http_requests_total --since 6h --step 5m --agg rate
    python3 query_metrics.py --metric http_request_duration_seconds --since 1h --agg p95

Output:
    JSON object with metadata and datapoints to stdout. Errors and diagnostics
    go to stderr.

Environment:
    Reads the Prometheus URL from the environment variable specified in
    config.json for the datasource with type "prometheus" (typically
    PROMETHEUS_URL).
"""

import argparse
import json
import os
import sys
from datetime import datetime, timedelta, timezone
from urllib.parse import urlencode
from urllib.request import urlopen, Request
from urllib.error import URLError, HTTPError


# ---------------------------------------------------------------------------
# Time parsing
# ---------------------------------------------------------------------------

def parse_duration(duration_str: str) -> timedelta:
    """Parse a human-friendly duration like '1h', '30m', '7d' into a timedelta."""
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


def get_prometheus_url(config: dict) -> str:
    """Get the Prometheus base URL from config and environment."""
    for ds in config.get("datasources", []):
        if ds["type"] == "prometheus":
            env_var = ds["connection_env"]
            url = os.environ.get(env_var)
            if not url:
                print(
                    f"Error: environment variable {env_var} is not set.\n"
                    f"Set it with: export {env_var}=http://localhost:9090\n"
                    f"Or add it to your .env file.",
                    file=sys.stderr,
                )
                sys.exit(1)
            return url.rstrip("/")
    print(
        "Error: no datasource with type 'prometheus' found in config.json.\n"
        "Add a prometheus datasource to the datasources array.",
        file=sys.stderr,
    )
    sys.exit(1)


# ---------------------------------------------------------------------------
# PromQL construction
# ---------------------------------------------------------------------------

AGGREGATION_FUNCTIONS = {
    "avg": "avg_over_time",
    "max": "max_over_time",
    "min": "min_over_time",
    "sum": "sum_over_time",
    "count": "count_over_time",
    "rate": "rate",
}

HISTOGRAM_QUANTILES = {
    "p50": 0.5,
    "p90": 0.9,
    "p95": 0.95,
    "p99": 0.99,
}


def build_promql(metric: str, labels: str, agg: str, step: str) -> str:
    """Build a PromQL query from the provided components.

    Args:
        metric: The metric name (e.g., http_requests_total).
        labels: Comma-separated label filters (e.g., "endpoint=/api,method=GET").
        agg: Aggregation function name (e.g., rate, p95, avg) or empty string.
        step: Step interval for range vectors (e.g., 1m, 5m).

    Returns:
        A PromQL query string.
    """
    # Build label selector
    label_selector = ""
    if labels:
        label_pairs = []
        for pair in labels.split(","):
            if "=" not in pair:
                print(f"Warning: skipping malformed label filter '{pair}' (expected key=value)", file=sys.stderr)
                continue
            key, value = pair.split("=", 1)
            label_pairs.append(f'{key.strip()}="{value.strip()}"')
        if label_pairs:
            label_selector = "{" + ", ".join(label_pairs) + "}"

    metric_with_labels = f"{metric}{label_selector}"

    if not agg:
        return metric_with_labels

    # Histogram quantiles (p50, p90, p95, p99)
    if agg in HISTOGRAM_QUANTILES:
        quantile = HISTOGRAM_QUANTILES[agg]
        # Histogram quantile requires the _bucket suffix
        bucket_metric = metric
        if not bucket_metric.endswith("_bucket"):
            # Try common histogram naming conventions
            for suffix in ("_seconds", "_bytes", "_count"):
                if bucket_metric.endswith(suffix):
                    bucket_metric = bucket_metric[: -len(suffix)] + suffix + "_bucket"
                    break
            else:
                bucket_metric += "_bucket"
        bucket_with_labels = f"{bucket_metric}{label_selector}"
        return f"histogram_quantile({quantile}, rate({bucket_with_labels}[{step}]))"

    # Standard aggregation functions
    if agg in AGGREGATION_FUNCTIONS:
        func = AGGREGATION_FUNCTIONS[agg]
        return f"{func}({metric_with_labels}[{step}])"

    # Unknown aggregation -- use it as-is and let Prometheus validate
    print(f"Warning: unknown aggregation '{agg}', using as raw function name", file=sys.stderr)
    return f"{agg}({metric_with_labels}[{step}])"


# ---------------------------------------------------------------------------
# Query execution
# ---------------------------------------------------------------------------

def query_prometheus(base_url: str, promql: str, start: datetime, end: datetime, step: str) -> dict:
    """Execute a range query against the Prometheus HTTP API.

    Args:
        base_url: Prometheus base URL (e.g., http://localhost:9090).
        promql: The PromQL query string.
        start: Range start time.
        end: Range end time.
        step: Query resolution step (e.g., 1m, 5m).

    Returns:
        The parsed JSON response from Prometheus.
    """
    params = {
        "query": promql,
        "start": start.isoformat(),
        "end": end.isoformat(),
        "step": step,
    }
    url = f"{base_url}/api/v1/query_range?{urlencode(params)}"

    try:
        req = Request(url, headers={"Accept": "application/json"})
        with urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode())
    except HTTPError as e:
        body = ""
        try:
            body = e.read().decode()
        except Exception:
            pass
        print(f"Error: Prometheus returned HTTP {e.code}: {body}", file=sys.stderr)
        sys.exit(1)
    except URLError as e:
        print(
            f"Error: could not reach Prometheus at {base_url}: {e.reason}\n"
            f"Verify the URL is correct and the server is running.",
            file=sys.stderr,
        )
        sys.exit(1)
    except Exception as e:
        print(f"Error: unexpected failure querying Prometheus: {e}", file=sys.stderr)
        sys.exit(1)

    if data.get("status") != "success":
        error_msg = data.get("error", "unknown error")
        error_type = data.get("errorType", "unknown")
        print(f"Error: Prometheus query failed ({error_type}): {error_msg}", file=sys.stderr)
        sys.exit(1)

    return data


def format_results(prom_data: dict, metric: str, promql: str) -> dict:
    """Transform Prometheus response into a clean output format.

    Returns a dict with:
        - metric: the metric name
        - query: the PromQL query used
        - datapoint_count: total number of datapoints
        - datapoints: list of {timestamp, value, labels} dicts
    """
    results = prom_data.get("data", {}).get("result", [])

    datapoints = []
    for series in results:
        labels = series.get("metric", {})
        for timestamp, value in series.get("values", []):
            datapoints.append({
                "timestamp": datetime.fromtimestamp(timestamp, tz=timezone.utc).isoformat(),
                "value": float(value) if value != "NaN" else None,
                "labels": labels,
            })

    # Sort by timestamp
    datapoints.sort(key=lambda dp: dp["timestamp"])

    return {
        "metric": metric,
        "query": promql,
        "datapoint_count": len(datapoints),
        "datapoints": datapoints,
    }


# ---------------------------------------------------------------------------
# Caching
# ---------------------------------------------------------------------------

def cache_results(config: dict, output: dict, args) -> str:
    """Write query results to the cache directory.

    Returns the path of the cache file.
    """
    cache_dir = config.get("cache_dir", ".cache/data-explorer")
    os.makedirs(cache_dir, exist_ok=True)

    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S")
    label = f"{args.metric}_{args.since}".replace("/", "-")
    filename = f"{timestamp}_{label}.json"
    filepath = os.path.join(cache_dir, filename)

    cache_entry = {
        "query_params": {
            "metric": args.metric,
            "since": args.since,
            "step": args.step,
            "agg": args.agg,
            "labels": args.labels,
        },
        "fetched_at": timestamp,
        **output,
    }

    with open(filepath, "w") as f:
        json.dump(cache_entry, f, indent=2)

    print(f"Cached {output['datapoint_count']} datapoints to {filepath}", file=sys.stderr)
    return filepath


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Query time-series metrics from Prometheus.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s --metric http_error_rate --since 1h --step 1m
  %(prog)s --metric http_requests_total --since 6h --step 5m --agg rate
  %(prog)s --metric http_request_duration_seconds --since 1h --agg p95 --step 1m
  %(prog)s --metric active_sessions --since 24h --step 15m --no-cache
  %(prog)s --metric http_requests_total --since 1h --labels "endpoint=/api/users,method=POST"
        """,
    )
    parser.add_argument(
        "--metric", required=True,
        help="Metric name to query (e.g., http_error_rate, active_sessions)",
    )
    parser.add_argument(
        "--since", required=True,
        help="How far back to query (e.g., 1h, 6h, 7d)",
    )
    parser.add_argument(
        "--step", default="1m",
        help="Query resolution / step interval (default: 1m)",
    )
    parser.add_argument(
        "--agg", default=None,
        help="Aggregation: avg, max, min, sum, rate, p50, p90, p95, p99",
    )
    parser.add_argument(
        "--labels", default="",
        help='Label filters as key=value pairs (e.g., "endpoint=/api/users,method=GET")',
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

    # Load config and resolve Prometheus URL
    config = load_config()
    base_url = get_prometheus_url(config)

    # Compute time range
    end = datetime.now(timezone.utc)
    start = end - parse_duration(args.since)

    # Build PromQL query
    promql = build_promql(args.metric, args.labels, args.agg or "", args.step)

    print(f"PromQL: {promql}", file=sys.stderr)
    print(f"Range: {start.isoformat()} to {end.isoformat()} (step: {args.step})", file=sys.stderr)

    # Execute query
    prom_data = query_prometheus(base_url, promql, start, end, args.step)
    output = format_results(prom_data, args.metric, promql)

    print(f"Received {output['datapoint_count']} datapoints.", file=sys.stderr)

    # Cache results unless --no-cache
    if not args.no_cache:
        cache_results(config, output, args)

    # Output results to stdout
    if args.format == "jsonl":
        for dp in output["datapoints"]:
            print(json.dumps(dp))
    else:
        print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()

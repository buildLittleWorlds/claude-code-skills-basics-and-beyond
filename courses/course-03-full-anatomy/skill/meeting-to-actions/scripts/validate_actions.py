#!/usr/bin/env python3
"""Validate action items extracted from meeting notes.

Reads a JSON array of action items from stdin. Each item should have:
  - action (str): Description of the task
  - owner (str): Person responsible
  - deadline (str): Due date in YYYY-MM-DD format

Outputs a JSON validation report to stdout.
Exit code 0 = all items valid, exit code 1 = issues found.

Usage:
  echo '[{"action":"Do thing","owner":"Alice","deadline":"2025-02-21"}]' | python validate_actions.py
"""

import json
import sys
import re
from datetime import datetime

REQUIRED_FIELDS = ["action", "owner", "deadline"]
DATE_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def validate_item(item, index):
    """Validate a single action item. Returns a list of issues (empty if valid)."""
    issues = []

    if not isinstance(item, dict):
        return [{"field": "item", "problem": f"Item {index} is not an object (got {type(item).__name__})"}]

    # Check required fields exist and are non-empty
    for field in REQUIRED_FIELDS:
        value = item.get(field)
        if value is None:
            issues.append({
                "field": field,
                "problem": f"Missing required field '{field}'"
            })
        elif not isinstance(value, str):
            issues.append({
                "field": field,
                "problem": f"Field '{field}' must be a string (got {type(value).__name__})"
            })
        elif value.strip() == "":
            issues.append({
                "field": field,
                "problem": f"Field '{field}' is empty"
            })

    # Check owner is not unassigned
    owner = item.get("owner", "")
    if isinstance(owner, str) and owner.strip().upper() == "UNASSIGNED":
        issues.append({
            "field": "owner",
            "problem": "Owner is UNASSIGNED - needs a responsible person"
        })

    # Check deadline format and validity
    deadline = item.get("deadline", "")
    if isinstance(deadline, str) and deadline.strip().upper() == "TBD":
        issues.append({
            "field": "deadline",
            "problem": "Deadline is TBD - needs a specific date"
        })
    elif isinstance(deadline, str) and deadline.strip() != "":
        if not DATE_PATTERN.match(deadline.strip()):
            issues.append({
                "field": "deadline",
                "problem": f"Deadline '{deadline}' is not in YYYY-MM-DD format"
            })
        else:
            try:
                datetime.strptime(deadline.strip(), "%Y-%m-%d")
            except ValueError:
                issues.append({
                    "field": "deadline",
                    "problem": f"Deadline '{deadline}' is not a valid date"
                })

    # Check action is specific enough (at least 5 characters)
    action = item.get("action", "")
    if isinstance(action, str) and 0 < len(action.strip()) < 5:
        issues.append({
            "field": "action",
            "problem": f"Action '{action}' is too vague (less than 5 characters)"
        })

    return issues


def main():
    # Read JSON from stdin
    try:
        raw_input = sys.stdin.read().strip()
    except KeyboardInterrupt:
        print(json.dumps({"error": "Interrupted"}), file=sys.stdout)
        sys.exit(1)

    if not raw_input:
        print(json.dumps({"error": "No input received. Pipe a JSON array to stdin."}), file=sys.stdout)
        sys.exit(1)

    # Parse JSON
    try:
        items = json.loads(raw_input)
    except json.JSONDecodeError as e:
        print(json.dumps({"error": f"Invalid JSON: {e}"}), file=sys.stdout)
        sys.exit(1)

    if not isinstance(items, list):
        print(json.dumps({"error": f"Expected a JSON array, got {type(items).__name__}"}), file=sys.stdout)
        sys.exit(1)

    if len(items) == 0:
        print(json.dumps({
            "status": "warning",
            "message": "No action items to validate (empty array)",
            "total_items": 0,
            "valid_items": 0,
            "items_with_issues": 0,
            "results": []
        }), file=sys.stdout)
        sys.exit(0)

    # Validate each item
    results = []
    total_issues = 0

    for i, item in enumerate(items):
        issues = validate_item(item, i)
        action_desc = item.get("action", f"item-{i}") if isinstance(item, dict) else f"item-{i}"
        result = {
            "index": i,
            "action": action_desc,
            "valid": len(issues) == 0,
            "issues": issues
        }
        results.append(result)
        total_issues += len(issues)

    valid_count = sum(1 for r in results if r["valid"])
    issue_count = len(results) - valid_count

    report = {
        "status": "pass" if total_issues == 0 else "fail",
        "total_items": len(items),
        "valid_items": valid_count,
        "items_with_issues": issue_count,
        "total_issues": total_issues,
        "results": results
    }

    print(json.dumps(report, indent=2), file=sys.stdout)
    sys.exit(0 if total_issues == 0 else 1)


if __name__ == "__main__":
    main()

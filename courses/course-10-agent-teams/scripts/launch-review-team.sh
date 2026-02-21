#!/bin/bash
# launch-review-team.sh
#
# Launches a 3-reviewer parallel code review using tmux + Claude Code.
# Creates three detached sessions (security, performance, test coverage),
# starts Claude in each, sends review prompts, then opens the dashboard.
#
# Usage:
#   ./launch-review-team.sh [project-directory]
#
# If no directory is given, uses the current directory.

set -euo pipefail

PROJECT_DIR="${1:-$(pwd)}"
PROJECT_DIR=$(cd "$PROJECT_DIR" && pwd)  # Resolve to absolute path
TEAM_NAME="review"

# Session names
SEC_SESSION="${TEAM_NAME}-security-reviewer"
PERF_SESSION="${TEAM_NAME}-perf-reviewer"
TEST_SESSION="${TEAM_NAME}-test-reviewer"
DASHBOARD_SESSION="${TEAM_NAME}-dashboard"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Parallel Code Review ==="
echo "Project: $PROJECT_DIR"
echo ""

# --- Cleanup existing sessions ---
for session in "$SEC_SESSION" "$PERF_SESSION" "$TEST_SESSION" "$DASHBOARD_SESSION"; do
  tmux has-session -t "$session" 2>/dev/null && tmux kill-session -t "$session"
done

# --- Create detached sessions ---
echo "Creating review sessions..."
tmux new-session -d -s "$SEC_SESSION" -c "$PROJECT_DIR"
tmux new-session -d -s "$PERF_SESSION" -c "$PROJECT_DIR"
tmux new-session -d -s "$TEST_SESSION" -c "$PROJECT_DIR"

# --- Start Claude in each session ---
echo "Starting Claude instances..."
tmux send-keys -t "$SEC_SESSION" 'claude --dangerously-skip-permissions' Enter
tmux send-keys -t "$PERF_SESSION" 'claude --dangerously-skip-permissions' Enter
tmux send-keys -t "$TEST_SESSION" 'claude --dangerously-skip-permissions' Enter

# Give Claude a moment to start up
echo "Waiting for Claude to initialize..."
sleep 5

# --- Send review prompts ---
echo "Sending review prompts..."

tmux send-keys -t "$SEC_SESSION" "You are a security reviewer. Review this project for security vulnerabilities. Focus on:
- Injection flaws (SQL injection, command injection, XSS)
- Authentication and session management issues
- Sensitive data exposure (hardcoded secrets, API keys, logging PII)
- Access control problems (missing auth checks, privilege escalation)
- Security misconfiguration (debug mode, default credentials, permissive CORS)
- Input validation gaps (path traversal, unrestricted uploads)

For each finding, report: severity (Critical/High/Medium/Low), OWASP category, file and line, what's wrong, and how to fix it. Summarize with a count by severity and top priorities." Enter

tmux send-keys -t "$PERF_SESSION" "You are a performance reviewer. Review this project for performance issues. Focus on:
- N+1 query patterns and unnecessary database calls
- Missing or ineffective caching
- Unnecessary memory allocations and large object copies
- Algorithmic complexity issues (O(n^2) loops, unindexed searches)
- Blocking I/O in async contexts
- Bundle size and unnecessary dependencies
- Missing pagination or unbounded data fetching

For each finding, report: impact (Critical/High/Medium/Low), category, file and line, what's wrong, and how to fix it. Summarize with overall performance assessment." Enter

tmux send-keys -t "$TEST_SESSION" "You are a test coverage reviewer. Review this project's test suite. Focus on:
- Untested code paths and functions
- Missing edge case tests (null inputs, empty arrays, boundary values)
- Brittle tests (time-dependent, order-dependent, external service calls)
- Test isolation issues (shared state, missing cleanup)
- Missing error path testing
- Integration test gaps

For each finding, report: priority (Critical/High/Medium/Low), category, file and line, what's missing, and a suggested test. Summarize with overall coverage assessment." Enter

echo ""
echo "=== Review team launched ==="
echo ""
echo "Sessions:"
echo "  Security:    $SEC_SESSION"
echo "  Performance: $PERF_SESSION"
echo "  Test:        $TEST_SESSION"
echo ""
echo "Quick commands:"
echo "  Peek:    tmux capture-pane -t $SEC_SESSION -p | tail -20"
echo "  Attach:  tmux attach -t $SEC_SESSION"
echo "  Switch:  Ctrl+J s (session switcher)"
echo ""
echo "To open the monitoring dashboard:"
echo "  $SCRIPT_DIR/team-dashboard.sh review 3"
echo "  (expects sessions: review-agent-1, review-agent-2, review-agent-3)"
echo ""
echo "  Or manually attach to each session to watch progress."
echo ""
echo "To capture all results when done:"
echo "  for s in $SEC_SESSION $PERF_SESSION $TEST_SESSION; do"
echo "    echo \"=== \$s ===\" >> review-results.txt"
echo "    tmux capture-pane -t \$s -p -S -1000 >> review-results.txt"
echo "  done"
echo ""
echo "To clean up:"
echo "  for s in $SEC_SESSION $PERF_SESSION $TEST_SESSION $DASHBOARD_SESSION; do"
echo "    tmux kill-session -t \$s 2>/dev/null"
echo "  done"

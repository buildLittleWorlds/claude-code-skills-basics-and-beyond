#!/bin/bash
# verify-task-completion.sh
#
# A TaskCompleted hook that runs the project's test suite.
# Blocks task completion (exit 2) if tests fail.
# Allows completion (exit 0) if tests pass or no test runner is found.
#
# Hook input (JSON on stdin):
#   task_id, task_subject, task_description, teammate_name, team_name
#
# Exit codes:
#   0 = allow task completion
#   2 = block task completion (stderr fed back to the agent)

set -euo pipefail

INPUT=$(cat)
TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject // "unknown task"')
TASK_ID=$(echo "$INPUT" | jq -r '.task_id // "unknown"')

# Detect test framework and build the test command
TEST_CMD=""

if [ -f "package.json" ]; then
  # Node.js: check for a test script
  HAS_TEST=$(jq -r '.scripts.test // empty' package.json 2>/dev/null)
  if [ -n "$HAS_TEST" ] && [ "$HAS_TEST" != "echo \"Error: no test specified\" && exit 1" ]; then
    TEST_CMD="npm test"
  fi
elif [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] || [ -d "tests" ]; then
  # Python: try pytest
  if command -v pytest &>/dev/null; then
    TEST_CMD="pytest --tb=short -q"
  elif command -v python3 &>/dev/null; then
    TEST_CMD="python3 -m pytest --tb=short -q"
  fi
elif [ -f "Cargo.toml" ]; then
  TEST_CMD="cargo test"
elif [ -f "go.mod" ]; then
  TEST_CMD="go test ./..."
elif [ -f "Makefile" ]; then
  # Check if Makefile has a test target
  if grep -q '^test:' Makefile 2>/dev/null; then
    TEST_CMD="make test"
  fi
fi

# If no test runner found, allow completion
if [ -z "$TEST_CMD" ]; then
  exit 0
fi

# Run the test suite
TEST_OUTPUT=$($TEST_CMD 2>&1) || {
  EXIT_CODE=$?
  # Tests failed -- block task completion
  # Truncate output to avoid overwhelming the agent
  TRUNCATED=$(echo "$TEST_OUTPUT" | tail -30)
  echo "Task '$TASK_SUBJECT' (ID: $TASK_ID) cannot be completed: test suite is failing." >&2
  echo "" >&2
  echo "Test command: $TEST_CMD" >&2
  echo "Exit code: $EXIT_CODE" >&2
  echo "" >&2
  echo "Last 30 lines of output:" >&2
  echo "$TRUNCATED" >&2
  echo "" >&2
  echo "Fix the failing tests, then try completing the task again." >&2
  exit 2
}

# Tests passed -- allow completion
exit 0

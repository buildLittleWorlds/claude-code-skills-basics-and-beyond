#!/bin/bash
# verify-completion.sh
#
# TaskCompleted hook that runs quality checks before allowing a task to close.
# Checks: test suite, lint (if configured), and artifact existence.
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

ERRORS=""

# --- Check 1: Test suite ---
TEST_CMD=""
if [ -f "package.json" ]; then
  HAS_TEST=$(jq -r '.scripts.test // empty' package.json 2>/dev/null)
  if [ -n "$HAS_TEST" ] && [ "$HAS_TEST" != "echo \"Error: no test specified\" && exit 1" ]; then
    TEST_CMD="npm test"
  fi
elif [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] || [ -d "tests" ]; then
  if command -v pytest &>/dev/null; then
    TEST_CMD="pytest --tb=short -q"
  fi
elif [ -f "Cargo.toml" ]; then
  TEST_CMD="cargo test"
elif [ -f "go.mod" ]; then
  TEST_CMD="go test ./..."
fi

if [ -n "$TEST_CMD" ]; then
  if ! $TEST_CMD >/dev/null 2>&1; then
    ERRORS="${ERRORS}Test suite failing ($TEST_CMD). "
  fi
fi

# --- Check 2: Lint (best-effort) ---
if [ -f "package.json" ]; then
  HAS_LINT=$(jq -r '.scripts.lint // empty' package.json 2>/dev/null)
  if [ -n "$HAS_LINT" ]; then
    if ! npm run lint >/dev/null 2>&1; then
      ERRORS="${ERRORS}Lint check failing (npm run lint). "
    fi
  fi
fi

# --- Check 3: No conflict markers in tracked files ---
if command -v git &>/dev/null && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  CONFLICT_FILES=$(git diff --name-only --diff-filter=U 2>/dev/null || true)
  if [ -n "$CONFLICT_FILES" ]; then
    ERRORS="${ERRORS}Unresolved merge conflicts in: $CONFLICT_FILES. "
  fi

  # Check for conflict markers in staged/modified files
  MODIFIED=$(git diff --name-only HEAD 2>/dev/null || true)
  if [ -n "$MODIFIED" ]; then
    for f in $MODIFIED; do
      if [ -f "$f" ] && grep -qE '^(<<<<<<<|=======|>>>>>>>)' "$f" 2>/dev/null; then
        ERRORS="${ERRORS}Conflict markers found in $f. "
        break
      fi
    done
  fi
fi

# --- Report ---
if [ -n "$ERRORS" ]; then
  echo "Task '$TASK_SUBJECT' (ID: $TASK_ID) cannot be completed:" >&2
  echo "$ERRORS" >&2
  echo "" >&2
  echo "Fix these issues and try completing the task again." >&2
  exit 2
fi

# All checks passed
exit 0

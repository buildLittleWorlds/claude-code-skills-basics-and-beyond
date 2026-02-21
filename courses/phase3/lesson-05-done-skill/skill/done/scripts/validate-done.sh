#!/usr/bin/env bash
# validate-done.sh — Verify that /done completed correctly
#
# Checks that a task was properly completed by validating:
# 1. The file was moved from pending/ to archive/
# 2. The archive file has status: done
# 3. A log entry was created for today
#
# Usage:
#   bash validate-done.sh <task-filename>
#
# Example:
#   bash validate-done.sh fix-api-timeout.md

set -e

TASKS_DIR="$HOME/work/_tasks"
TODAY=$(date +%Y-%m-%d)

if [ -z "$1" ]; then
    echo "Usage: bash validate-done.sh <task-filename>"
    echo "Example: bash validate-done.sh fix-api-timeout.md"
    exit 1
fi

TASK="$1"
PASS=0
FAIL=0

check() {
    local description="$1"
    local result="$2"
    if [ "$result" = "true" ]; then
        echo "  ✅ $description"
        PASS=$((PASS + 1))
    else
        echo "  ❌ $description"
        FAIL=$((FAIL + 1))
    fi
}

echo "Validating completion of: $TASK"
echo "─────────────────────────────────────"

# Check 1: File is NOT in pending/
if [ -f "$TASKS_DIR/pending/$TASK" ]; then
    check "File removed from pending/" "false"
else
    check "File removed from pending/" "true"
fi

# Check 2: File IS in archive/
if [ -f "$TASKS_DIR/archive/$TASK" ]; then
    check "File exists in archive/" "true"
else
    check "File exists in archive/" "false"
fi

# Check 3: Archive file has status: done
if [ -f "$TASKS_DIR/archive/$TASK" ]; then
    if grep -q "^status: done" "$TASKS_DIR/archive/$TASK"; then
        check "Archive file has status: done" "true"
    else
        check "Archive file has status: done" "false"
    fi
else
    check "Archive file has status: done (file missing)" "false"
fi

# Check 4: Today's log file exists
if [ -f "$TASKS_DIR/log/$TODAY.md" ]; then
    check "Log file exists for today ($TODAY)" "true"
else
    check "Log file exists for today ($TODAY)" "false"
fi

# Check 5: Log file contains the task title
if [ -f "$TASKS_DIR/archive/$TASK" ]; then
    TITLE=$(grep "^title:" "$TASKS_DIR/archive/$TASK" | sed 's/^title: *//')
    if [ -f "$TASKS_DIR/log/$TODAY.md" ] && grep -q "$TITLE" "$TASKS_DIR/log/$TODAY.md"; then
        check "Log file mentions task title" "true"
    else
        check "Log file mentions task title" "false"
    fi
else
    check "Log file mentions task title (archive missing)" "false"
fi

# Check 6: Log entry has required fields
if [ -f "$TASKS_DIR/log/$TODAY.md" ]; then
    HAS_STATUS=$(grep -c "^\*\*Status\*\*:" "$TASKS_DIR/log/$TODAY.md" 2>/dev/null || echo 0)
    HAS_SUMMARY=$(grep -c "^\*\*Summary\*\*:" "$TASKS_DIR/log/$TODAY.md" 2>/dev/null || echo 0)
    if [ "$HAS_STATUS" -gt 0 ] && [ "$HAS_SUMMARY" -gt 0 ]; then
        check "Log entry has Status and Summary fields" "true"
    else
        check "Log entry has Status and Summary fields" "false"
    fi
else
    check "Log entry has Status and Summary fields (no log file)" "false"
fi

echo "─────────────────────────────────────"
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi

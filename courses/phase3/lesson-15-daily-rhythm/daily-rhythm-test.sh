#!/usr/bin/env bash
# daily-rhythm-test.sh — Integration test for the full task workflow
#
# Walks through the complete daily rhythm and checks state at each step.
# Run this OUTSIDE tmux (it creates its own session for testing).
#
# Usage:
#   bash skills/courses/phase3/lesson-15-daily-rhythm/daily-rhythm-test.sh
#
# This is a guided walkthrough, not an automated test. It sets up state
# and tells you what to do at each step, then verifies the results.

set -e

TASKS_DIR="$HOME/work/_tasks"
TODAY=$(date +%Y-%m-%d)

PASS=0
FAIL=0

check() {
    local desc="$1"
    local condition="$2"
    if eval "$condition"; then
        echo "  ✅ $desc"
        PASS=$((PASS + 1))
    else
        echo "  ❌ $desc"
        FAIL=$((FAIL + 1))
    fi
}

echo "═══════════════════════════════════════════════════"
echo "  Daily Rhythm Integration Test"
echo "  Date: $TODAY"
echo "═══════════════════════════════════════════════════"
echo ""

# ── Phase 1: Pre-flight checks ──────────────────────────────
echo "📋 Phase 1: Pre-flight checks"
echo "─────────────────────────────"

check "Task directory exists" "[ -d '$TASKS_DIR' ]"
check "Inbox directory exists" "[ -d '$TASKS_DIR/inbox' ]"
check "Pending directory exists" "[ -d '$TASKS_DIR/pending' ]"
check "Archive directory exists" "[ -d '$TASKS_DIR/archive' ]"
check "Log directory exists" "[ -d '$TASKS_DIR/log' ]"

check "Skills installed: next" "[ -f '$HOME/.claude/skills/next/SKILL.md' ]"
check "Skills installed: done" "[ -f '$HOME/.claude/skills/done/SKILL.md' ]"
check "Skills installed: triage" "[ -f '$HOME/.claude/skills/triage/SKILL.md' ]"
check "Skills installed: today" "[ -f '$HOME/.claude/skills/today/SKILL.md' ]"
check "Skills installed: overdue" "[ -f '$HOME/.claude/skills/overdue/SKILL.md' ]"
check "Skills installed: session-summary" "[ -f '$HOME/.claude/skills/session-summary/SKILL.md' ]"

check "Hook installed: compound-reminder" "[ -f '$HOME/.claude/hooks/compound-reminder.sh' ]"
check "Hook installed: protect-task-files" "[ -f '$HOME/.claude/hooks/protect-task-files.sh' ]"

check "Startup script installed" "[ -f '$HOME/bin/tasks' ]"

INBOX_COUNT=$(ls "$TASKS_DIR/inbox/"*.md 2>/dev/null | wc -l | tr -d ' ')
PENDING_COUNT=$(ls "$TASKS_DIR/pending/"*.md 2>/dev/null | wc -l | tr -d ' ')
ARCHIVE_COUNT=$(ls "$TASKS_DIR/archive/"*.md 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "  Current state:"
echo "    Inbox:   $INBOX_COUNT files"
echo "    Pending: $PENDING_COUNT files"
echo "    Archive: $ARCHIVE_COUNT files"
echo ""

# ── Phase 2: Add test data ──────────────────────────────────
echo "📋 Phase 2: Adding integration test data"
echo "─────────────────────────────"

# Add a test inbox item
cat > "$TASKS_DIR/inbox/integration-test-task.md" << EOF
---
title: Integration test task for daily rhythm
status: inbox
created: ${TODAY}T10:00
---
This task was created by the daily-rhythm-test.sh script.
It should be triaged, worked on, and completed during this test.
EOF

check "Test inbox item created" "[ -f '$TASKS_DIR/inbox/integration-test-task.md' ]"

echo ""
echo "═══════════════════════════════════════════════════"
echo "  Manual Steps — Do these in the cockpit"
echo "═══════════════════════════════════════════════════"
echo ""
echo "  1. Launch the cockpit:  tasks"
echo "  2. Wait for /today briefing (auto-sent)"
echo "  3. Run: /triage"
echo "     → 'integration-test-task' should move to pending"
echo "  4. Run: /next"
echo "     → The test task should appear in the list"
echo "  5. Run: /overdue"
echo "     → Check for any escalated tasks"
echo "  6. Run: /done integration-test Completed the daily rhythm test"
echo "     → Task should move to archive"
echo "  7. Update ~/MEMORY.md with session notes"
echo "  8. Run: /session-summary"
echo "     → Should show the test task in completions"
echo ""
echo "  Press Enter when you've completed all steps..."
read -r

# ── Phase 3: Verify results ─────────────────────────────────
echo ""
echo "📋 Phase 3: Verifying results"
echo "─────────────────────────────"

check "Test task removed from inbox" "[ ! -f '$TASKS_DIR/inbox/integration-test-task.md' ]"
check "Test task NOT in pending (completed)" "[ ! -f '$TASKS_DIR/pending/integration-test-task.md' ]"
check "Test task in archive" "[ -f '$TASKS_DIR/archive/integration-test-task.md' ]"

if [ -f "$TASKS_DIR/archive/integration-test-task.md" ]; then
    check "Archive file has status: done" "grep -q 'status: done' '$TASKS_DIR/archive/integration-test-task.md'"
    check "Archive file has domain assigned" "grep -q 'domain:' '$TASKS_DIR/archive/integration-test-task.md'"
fi

check "Log entry exists for today" "[ -f '$TASKS_DIR/log/$TODAY.md' ]"

if [ -f "$TASKS_DIR/log/$TODAY.md" ]; then
    check "Log mentions test task" "grep -qi 'integration test' '$TASKS_DIR/log/$TODAY.md'"
fi

check "MEMORY.md was updated today" "[ -f '$HOME/MEMORY.md' ] && find '$HOME/MEMORY.md' -mtime 0 | grep -q '.'"

echo ""
echo "═══════════════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed"
echo "═══════════════════════════════════════════════════"

if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo "  Some checks failed. Review the failing items above"
    echo "  and re-run the relevant skill to fix them."
    exit 1
else
    echo ""
    echo "  🎉 All checks passed! The daily rhythm works end-to-end."
    echo ""
    echo "  Your complete workflow:"
    echo "    tasks → /today → /triage → /next → work → /done"
    echo "    → update MEMORY.md → /session-summary"
fi

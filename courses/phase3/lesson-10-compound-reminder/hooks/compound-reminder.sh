#!/usr/bin/env bash
# compound-reminder.sh — Stop hook that reminds to update MEMORY.md
#
# Event: Stop
# Purpose: If a task was completed during this session (archive changed)
#          but MEMORY.md was not updated, remind the user.
#
# Exit codes:
#   0 = allow (no reminder needed)
#   2 = block with feedback (reminder shown via stderr)
#
# CRITICAL: Check stop_hook_active to prevent infinite loops.
# When this hook exits 2, Claude gets the feedback and responds,
# which triggers another Stop event. Without the guard, it loops forever.

# ── Guard against infinite loops ────────────────────────────
if [ "${stop_hook_active}" = "1" ]; then
    exit 0
fi
export stop_hook_active=1

# ── Configuration ───────────────────────────────────────────
TASKS_DIR="$HOME/work/_tasks"
MEMORY_FILE="$HOME/MEMORY.md"
ARCHIVE_DIR="$TASKS_DIR/archive"

# ── Check: Were any tasks completed recently? ───────────────
# Look for archive files modified in the last 10 minutes
recent_archives=$(find "$ARCHIVE_DIR" -name "*.md" -mmin -10 2>/dev/null | wc -l | tr -d ' ')

if [ "$recent_archives" = "0" ]; then
    # No recent completions — nothing to remind about
    exit 0
fi

# ── Check: Was MEMORY.md updated recently? ──────────────────
if [ -f "$MEMORY_FILE" ]; then
    memory_age=$(find "$MEMORY_FILE" -mmin -10 2>/dev/null | wc -l | tr -d ' ')
    if [ "$memory_age" != "0" ]; then
        # MEMORY.md was updated recently — reminder not needed
        exit 0
    fi
fi

# ── Reminder needed ─────────────────────────────────────────
# Exit code 2 sends stderr back to Claude as feedback
echo "⚠️ You completed $recent_archives task(s) but haven't updated MEMORY.md yet." >&2
echo "" >&2
echo "Please update ~/MEMORY.md with:" >&2
echo "  - What was completed and key decisions made" >&2
echo "  - Any context needed for the next session" >&2
echo "  - Updated task priorities or blockers" >&2
echo "" >&2
echo "This keeps your session history useful for /session-summary." >&2

exit 2

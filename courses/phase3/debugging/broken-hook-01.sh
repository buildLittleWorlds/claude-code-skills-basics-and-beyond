#!/usr/bin/env bash
# BROKEN: Stop hook for MEMORY.md reminders
# BUG: This hook causes an infinite loop. Find and fix the issue.

TASKS_DIR="$HOME/work/_tasks"
MEMORY_FILE="$HOME/MEMORY.md"
ARCHIVE_DIR="$TASKS_DIR/archive"

# Check for recent completions
recent_archives=$(find "$ARCHIVE_DIR" -name "*.md" -mmin -10 2>/dev/null | wc -l | tr -d ' ')

if [ "$recent_archives" = "0" ]; then
    exit 0
fi

# Check MEMORY.md
if [ -f "$MEMORY_FILE" ]; then
    memory_age=$(find "$MEMORY_FILE" -mmin -10 2>/dev/null | wc -l | tr -d ' ')
    if [ "$memory_age" != "0" ]; then
        exit 0
    fi
fi

# Remind
echo "Please update MEMORY.md with your session notes." >&2
exit 2

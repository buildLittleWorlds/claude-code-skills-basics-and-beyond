#!/usr/bin/env bash
# BROKEN: PreToolUse hook to block log file edits
# BUG: The hook runs but edits still go through. Find and fix the issue.

input=$(cat)

file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

if [ -z "$file_path" ]; then
    exit 0
fi

TASKS_DIR="$HOME/work/_tasks"
LOG_DIR="$TASKS_DIR/log"

case "$file_path" in
    "$LOG_DIR"/*)
        echo "Cannot edit log files directly. Use /done to create entries."
        exit 2
        ;;
esac

exit 0

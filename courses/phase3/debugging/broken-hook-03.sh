#!/usr/bin/env bash
# BROKEN: PreToolUse hook to block archive file edits
# BUG: The file path is never extracted correctly. Find and fix the issue.

input=$(cat)

file_path=$(echo "$input" | jq -r '.tool_input.path // empty')

if [ -z "$file_path" ]; then
    exit 0
fi

TASKS_DIR="$HOME/work/_tasks"
ARCHIVE_DIR="$TASKS_DIR/archive"

case "$file_path" in
    "$ARCHIVE_DIR"/*)
        echo "Cannot edit archived tasks." >&2
        exit 2
        ;;
esac

exit 0

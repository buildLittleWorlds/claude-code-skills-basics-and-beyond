#!/usr/bin/env bash
# protect-task-files.sh — PreToolUse hook to block edits to log/archive
#
# Event: PreToolUse
# Matcher: Edit|Write
#
# Blocks file edits/writes to:
#   ~/work/_tasks/log/*     (append-only via /done)
#   ~/work/_tasks/archive/* (completed tasks are read-only)
#
# Exit codes:
#   0 = allow the edit
#   2 = block with feedback (tells Claude why and what to do instead)

# ── Read the tool input from stdin ──────────────────────────
# PreToolUse hooks receive JSON on stdin with tool details
input=$(cat)

# ── Extract the file path ───────────────────────────────────
# For Edit tool: .tool_input.file_path
# For Write tool: .tool_input.file_path
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

if [ -z "$file_path" ]; then
    # No file path found — allow (might be a different tool parameter format)
    exit 0
fi

# ── Resolve paths ───────────────────────────────────────────
TASKS_DIR="$HOME/work/_tasks"
LOG_DIR="$TASKS_DIR/log"
ARCHIVE_DIR="$TASKS_DIR/archive"

# Resolve to absolute path for comparison
resolved_path="$file_path"

# ── Check: Is this a log file? ──────────────────────────────
case "$resolved_path" in
    "$LOG_DIR"/*|"$LOG_DIR")
        echo "🚫 Blocked: Cannot edit log files directly." >&2
        echo "" >&2
        echo "Log files in ~/work/_tasks/log/ are append-only." >&2
        echo "New log entries are created by the /done skill when completing tasks." >&2
        echo "" >&2
        echo "To add a log entry: use /done <task-keyword> <summary>" >&2
        exit 2
        ;;
esac

# ── Check: Is this an archive file? ─────────────────────────
case "$resolved_path" in
    "$ARCHIVE_DIR"/*|"$ARCHIVE_DIR")
        echo "🚫 Blocked: Cannot edit archived tasks." >&2
        echo "" >&2
        echo "Files in ~/work/_tasks/archive/ are completed tasks and should not be modified." >&2
        echo "They serve as a historical record." >&2
        echo "" >&2
        echo "If you need to reopen a task, move it back to pending/:" >&2
        echo "  mv ~/work/_tasks/archive/<file>.md ~/work/_tasks/pending/" >&2
        exit 2
        ;;
esac

# ── Not a protected path — allow the edit ───────────────────
exit 0

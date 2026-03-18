#!/bin/bash
# skill-usage-logger.sh -- PreToolUse hook for measuring skill invocations
#
# Purpose: Logs every tool invocation with timestamp, tool name, and session ID
#          to a JSONL file for later analysis.
#
# Install:
#   1. chmod +x skill-usage-logger.sh
#   2. Copy to ~/.claude/hooks/skill-usage-logger.sh
#   3. Add to .claude/hooks.json:
#      {
#        "hooks": {
#          "PreToolUse": [{
#            "command": "~/.claude/hooks/skill-usage-logger.sh",
#            "description": "Logs all tool invocations for usage analytics"
#          }]
#        }
#      }
#
# Log format (JSONL, one entry per line):
#   {"timestamp":"2025-01-15T09:30:00Z","date":"2025-01-15","tool":"daily-standup-v2","session":"abc123"}
#
# Output: None (silent). Exit code 0 (always allow the tool call to proceed).

set -euo pipefail

# Read the hook JSON payload from stdin
INPUT=$(cat)

# Extract fields from the JSON payload
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# Only log if we got a tool name
if [[ -n "$TOOL_NAME" ]]; then
  LOG_DIR="${HOME}/.claude/logs"
  mkdir -p "$LOG_DIR"
  LOG_FILE="${LOG_DIR}/skill-usage.jsonl"

  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  DATE=$(date -u +"%Y-%m-%d")

  # Append the log entry as a single JSON line
  # Using printf to avoid issues with echo interpreting escape sequences
  printf '{"timestamp":"%s","date":"%s","tool":"%s","session":"%s"}\n' \
    "$TIMESTAMP" "$DATE" "$TOOL_NAME" "$SESSION_ID" >> "$LOG_FILE"
fi

# Exit 0 with no stdout -- this tells the hook system to allow the tool call
exit 0

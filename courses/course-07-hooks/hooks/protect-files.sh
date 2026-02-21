#!/bin/bash
# protect-files.sh -- PreToolUse hook for Edit|Write
# Blocks edits to sensitive files like .env, lock files, and .git/.
#
# Configuration: Add to .claude/settings.json under hooks.PreToolUse
# with matcher "Edit|Write".
#
# Exit codes:
#   0 = allow the edit
#   2 = block the edit (stderr is fed back to Claude as feedback)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file path
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Protected file patterns -- add to this list as needed
PROTECTED_PATTERNS=(
  ".env"
  "package-lock.json"
  "yarn.lock"
  "pnpm-lock.yaml"
  ".git/"
)

for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "Blocked: '$FILE_PATH' matches protected pattern '$pattern'. This file should not be modified by Claude." >&2
    exit 2
  fi
done

exit 0

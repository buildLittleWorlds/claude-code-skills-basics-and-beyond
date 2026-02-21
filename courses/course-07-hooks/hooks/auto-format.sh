#!/bin/bash
# auto-format.sh -- PostToolUse hook for Edit|Write
# Runs prettier on files after Claude edits or creates them.
#
# Configuration: Add to .claude/settings.json under hooks.PostToolUse
# with matcher "Edit|Write".

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file path (shouldn't happen for Edit/Write, but be safe)
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Skip if file doesn't exist (e.g., failed write)
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Only format file types prettier understands
case "$FILE_PATH" in
  *.js|*.jsx|*.ts|*.tsx|*.json|*.css|*.scss|*.md|*.html|*.yaml|*.yml)
    npx prettier --write "$FILE_PATH" 2>/dev/null
    ;;
esac

# Always exit 0 -- formatting failure shouldn't block Claude's work
exit 0

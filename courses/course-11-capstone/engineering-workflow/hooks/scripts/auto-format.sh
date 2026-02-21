#!/bin/bash
# auto-format.sh
#
# PostToolUse hook for Edit|Write events.
# Detects the project's formatter and runs it on the modified file.
#
# Hook input (JSON on stdin):
#   tool_name, tool_input.file_path, tool_input.content (for Write)
#
# Exit codes:
#   0 = success (formatted or no formatter found)
#   1 = non-blocking error (shown in verbose mode only)

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# If no file path, nothing to format
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Get file extension
EXT="${FILE_PATH##*.}"

# Detect formatter and run it
case "$EXT" in
  js|jsx|ts|tsx|json|css|scss|md|html|yaml|yml)
    # Try prettier first (most common JS/TS formatter)
    if command -v npx &>/dev/null && [ -f "node_modules/.bin/prettier" ]; then
      npx prettier --write "$FILE_PATH" 2>/dev/null || true
    elif command -v prettier &>/dev/null; then
      prettier --write "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  py)
    # Try black, then ruff format
    if command -v black &>/dev/null; then
      black --quiet "$FILE_PATH" 2>/dev/null || true
    elif command -v ruff &>/dev/null; then
      ruff format "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  rs)
    # Rust: rustfmt
    if command -v rustfmt &>/dev/null; then
      rustfmt "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  go)
    # Go: gofmt
    if command -v gofmt &>/dev/null; then
      gofmt -w "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
esac

# Always succeed -- formatting is best-effort
exit 0

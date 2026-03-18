#!/bin/bash
# block-destructive.sh -- PreToolUse hook for Bash
#
# Blocks destructive commands unless a CONFIRMED_DESTRUCTIVE marker is present.
# Used by the resource-cleanup and careful skills to prevent accidental
# data loss during operations work.
#
# Blocked patterns:
#   - rm -rf           (recursive forced deletion)
#   - git push --force (force push, including -f shorthand)
#   - DROP TABLE       (SQL table destruction)
#   - DROP DATABASE    (SQL database destruction)
#   - DELETE FROM      (SQL mass row deletion)
#   - git reset --hard (discard all uncommitted changes)
#   - git clean -f     (delete untracked files)
#
# Exit codes:
#   0 -- Command is safe or has been confirmed. Proceed.
#   2 -- Command is destructive and unconfirmed. Block it.
#
# To bypass the block for a legitimate destructive command, append
# "# CONFIRMED_DESTRUCTIVE" as a comment in the command string.
# Example:
#   rm -rf old-dir/ # CONFIRMED_DESTRUCTIVE

# Read the hook JSON payload from stdin
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# If there's no command, nothing to check
if [ -z "$COMMAND" ]; then
  exit 0
fi

# If the command contains the confirmation marker, allow it through
if echo "$COMMAND" | grep -q 'CONFIRMED_DESTRUCTIVE'; then
  exit 0
fi

# --- Destructive pattern checks ---

# 1. rm -rf (recursive forced deletion)
#    Matches: rm -rf, rm -fr, rm -rfi, rm -r -f, etc.
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)\b'; then
  echo "BLOCKED: 'rm -rf' detected. Recursive forced deletion is not allowed without confirmation. To proceed, re-run the command with a '# CONFIRMED_DESTRUCTIVE' comment appended." >&2
  exit 2
fi

# 2. git push --force / git push -f
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*(-f|--force)\b'; then
  echo "BLOCKED: 'git push --force' detected. Force pushing is not allowed without confirmation. To proceed, re-run the command with a '# CONFIRMED_DESTRUCTIVE' comment appended." >&2
  exit 2
fi

# 3. DROP TABLE / DROP DATABASE (case-insensitive)
if echo "$COMMAND" | grep -qiE '\bDROP\s+(TABLE|DATABASE)\b'; then
  echo "BLOCKED: 'DROP TABLE/DATABASE' detected. SQL destruction is not allowed without confirmation. To proceed, re-run the command with a '# CONFIRMED_DESTRUCTIVE' comment appended." >&2
  exit 2
fi

# 4. DELETE FROM (case-insensitive)
if echo "$COMMAND" | grep -qiE '\bDELETE\s+FROM\b'; then
  echo "BLOCKED: 'DELETE FROM' detected. SQL mass deletion is not allowed without confirmation. To proceed, re-run the command with a '# CONFIRMED_DESTRUCTIVE' comment appended." >&2
  exit 2
fi

# 5. git reset --hard
if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
  echo "BLOCKED: 'git reset --hard' detected. Discarding all uncommitted changes is not allowed without confirmation. To proceed, re-run the command with a '# CONFIRMED_DESTRUCTIVE' comment appended." >&2
  exit 2
fi

# 6. git clean -f (delete untracked files)
#    Matches: git clean -f, git clean -fd, git clean -fx, etc.
if echo "$COMMAND" | grep -qE 'git\s+clean\s+.*-[a-zA-Z]*f'; then
  echo "BLOCKED: 'git clean -f' detected. Deleting untracked files is not allowed without confirmation. To proceed, re-run the command with a '# CONFIRMED_DESTRUCTIVE' comment appended." >&2
  exit 2
fi

# All checks passed -- command is safe
exit 0

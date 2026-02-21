#!/bin/bash
# validate-deploy-command.sh -- PreToolUse hook for Bash (used by safe-deploy skill)
# Blocks dangerous commands during deployment workflows.
#
# This script is referenced in the safe-deploy SKILL.md frontmatter and runs
# automatically whenever the skill is active and Claude attempts a Bash command.
#
# Exit codes:
#   0 = allow the command
#   2 = block the command (stderr is fed back to Claude as feedback)

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Skip if no command
if [ -z "$COMMAND" ]; then
  exit 0
fi

# --- Dangerous pattern checks ---

# Block force pushes
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*(-f|--force)'; then
  echo "Blocked by deploy safety hook: force push is not allowed during deployments. Use a regular push instead." >&2
  exit 2
fi

# Block --no-verify (skipping pre-commit hooks, CI checks)
if echo "$COMMAND" | grep -q '\-\-no-verify'; then
  echo "Blocked by deploy safety hook: --no-verify is not allowed. Safety checks must not be skipped during deployments." >&2
  exit 2
fi

# Block destructive rm on common deployment directories
if echo "$COMMAND" | grep -qE 'rm\s+-rf\s+.*(deploy|dist|build|release|\.git)'; then
  echo "Blocked by deploy safety hook: destructive removal of deployment-related directories is not allowed." >&2
  exit 2
fi

# Block direct production database commands
if echo "$COMMAND" | grep -qiE '(production|prod).*(DROP|DELETE\s+FROM|TRUNCATE)'; then
  echo "Blocked by deploy safety hook: destructive database operations against production are not allowed." >&2
  exit 2
fi

if echo "$COMMAND" | grep -qiE '(DROP|TRUNCATE).*(production|prod)'; then
  echo "Blocked by deploy safety hook: destructive database operations against production are not allowed." >&2
  exit 2
fi

# All checks passed
exit 0

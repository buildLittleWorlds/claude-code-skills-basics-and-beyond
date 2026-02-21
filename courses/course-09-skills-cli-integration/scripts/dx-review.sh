#!/bin/bash
# dx-review.sh -- AI-powered code review of staged changes
#
# Demonstrates the non-interactive wrapper-command pattern:
# capture CLI output → construct a prompt → run AI one-shot → display result
#
# Usage:
#   ./dx-review.sh                  # Review staged changes with Claude
#   ./dx-review.sh --skill          # Use the /code-review-checklist skill instead of a raw prompt
#
# Requires: git, claude CLI

set -e

USE_SKILL=false
for arg in "$@"; do
  case "$arg" in
    --skill) USE_SKILL=true ;;
  esac
done

# ── Step 1: Capture CLI output ──────────────────────────────────────────────

DIFF=$(git diff --cached 2>/dev/null)

if [[ -z "$DIFF" ]]; then
  echo "No staged changes to review."
  echo ""
  echo "Stage changes first:"
  echo "  git add <files>"
  echo "  git add -p          # interactive staging"
  exit 1
fi

STAT=$(git diff --cached --stat 2>/dev/null)
FILE_COUNT=$(git diff --cached --name-only | wc -l | tr -d ' ')

echo "Reviewing $FILE_COUNT staged file(s)..."
echo "$STAT"
echo ""

# ── Step 2: Construct prompt and run AI ─────────────────────────────────────

if [[ "$USE_SKILL" == true ]]; then
  # Invoke Claude with the /code-review-checklist skill (from Course 2)
  # The skill provides structured review dimensions: correctness, readability,
  # performance, security, testing, and a verdict.
  echo "Using /code-review-checklist skill for structured review..."
  echo ""
  claude -p "/code-review-checklist

Here is the diff to review:

\`\`\`diff
$DIFF
\`\`\`"
else
  # Raw prompt -- functional but less structured than the skill version
  PROMPT="Review this git diff. Be concise and actionable. Cover:
1. Bugs or correctness issues
2. Security concerns
3. Readability and style
4. Missing error handling

If everything looks good, say 'LGTM' with a brief note on what's solid.

Files changed:
$STAT

Diff:
\`\`\`diff
$DIFF
\`\`\`"

  claude -p "$PROMPT"
fi

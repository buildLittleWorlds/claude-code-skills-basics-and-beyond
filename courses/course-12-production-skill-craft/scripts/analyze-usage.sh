#!/bin/bash
# analyze-usage.sh -- Parse skill usage logs and output statistics
#
# Reads from ~/.claude/logs/skill-usage.jsonl (produced by skill-usage-logger.sh)
# and outputs invocation counts, daily trends, and most/least used tools.
#
# Usage:
#   chmod +x analyze-usage.sh
#   ./analyze-usage.sh              # Analyze all time
#   ./analyze-usage.sh 7            # Analyze last 7 days only
#
# Requires: jq

set -euo pipefail

LOG_FILE="${HOME}/.claude/logs/skill-usage.jsonl"

if [[ ! -f "$LOG_FILE" ]]; then
  echo "Error: No usage log found at $LOG_FILE"
  echo ""
  echo "To start collecting data:"
  echo "  1. Install skill-usage-logger.sh as a PreToolUse hook"
  echo "  2. Use Claude Code normally -- invocations will be logged automatically"
  echo "  3. Run this script again after some usage"
  exit 1
fi

# Optional: filter to last N days
DAYS="${1:-}"
if [[ -n "$DAYS" ]]; then
  if [[ "$(uname)" == "Darwin" ]]; then
    CUTOFF_DATE=$(date -u -v-"${DAYS}d" +"%Y-%m-%d")
  else
    CUTOFF_DATE=$(date -u -d "${DAYS} days ago" +"%Y-%m-%d")
  fi
  FILTERED=$(jq -r "select(.date >= \"$CUTOFF_DATE\")" "$LOG_FILE")
  LABEL="last $DAYS days"
else
  FILTERED=$(cat "$LOG_FILE")
  LABEL="all time"
fi

TOTAL=$(echo "$FILTERED" | wc -l | tr -d ' ')

echo "========================================"
echo "  Skill Usage Report ($LABEL)"
echo "========================================"
echo "Log file: $LOG_FILE"
echo "Total invocations: $TOTAL"
echo ""

# --- Invocations per tool ---
echo "--- Invocations per tool (top 15) ---"
echo "$FILTERED" | jq -r '.tool' | sort | uniq -c | sort -rn | head -15
echo ""

# --- Most used ---
echo "--- Most used tools (top 3) ---"
MOST_USED=$(echo "$FILTERED" | jq -r '.tool' | sort | uniq -c | sort -rn | head -3)
echo "$MOST_USED"
echo ""

# --- Least used ---
echo "--- Least used tools (bottom 3) ---"
LEAST_USED=$(echo "$FILTERED" | jq -r '.tool' | sort | uniq -c | sort -rn | tail -3)
echo "$LEAST_USED"
echo ""

# --- Daily trend ---
echo "--- Daily trend (last 14 days) ---"
echo "$FILTERED" | jq -r '.date' | sort | uniq -c | tail -14
echo ""

# --- Hourly distribution ---
echo "--- Hourly distribution ---"
echo "$FILTERED" | jq -r '.timestamp' | cut -dT -f2 | cut -d: -f1 | sort | uniq -c | sort -k2 -n
echo ""

# --- Sessions with most activity ---
echo "--- Most active sessions (top 5) ---"
echo "$FILTERED" | jq -r '.session' | sort | uniq -c | sort -rn | head -5
echo ""

# --- Unique tools count ---
UNIQUE_TOOLS=$(echo "$FILTERED" | jq -r '.tool' | sort -u | wc -l | tr -d ' ')
echo "--- Summary ---"
echo "Unique tools invoked: $UNIQUE_TOOLS"
echo "Total invocations:    $TOTAL"
if [[ "$TOTAL" -gt 0 && "$UNIQUE_TOOLS" -gt 0 ]]; then
  AVG=$((TOTAL / UNIQUE_TOOLS))
  echo "Avg invocations/tool: $AVG"
fi
echo ""

# --- Under-triggering detection ---
echo "--- Potential under-triggering (tools used only once) ---"
echo "$FILTERED" | jq -r '.tool' | sort | uniq -c | sort -rn | awk '$1 == 1 {print "  " $2}'
SINGLE_USE=$(echo "$FILTERED" | jq -r '.tool' | sort | uniq -c | awk '$1 == 1' | wc -l | tr -d ' ')
if [[ "$SINGLE_USE" -eq 0 ]]; then
  echo "  (none -- all tools have multiple invocations)"
fi
echo ""
echo "========================================"

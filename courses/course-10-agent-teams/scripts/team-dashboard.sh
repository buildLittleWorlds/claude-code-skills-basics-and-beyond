#!/bin/bash
# team-dashboard.sh
#
# Creates a tmux monitoring layout for an agent team.
# Top row: one pane per agent with live-tailing via watch + capture-pane.
# Bottom pane: command center for manual interaction.
#
# Usage:
#   ./team-dashboard.sh <team-name> <agent-count>
#
# Example:
#   ./team-dashboard.sh my-review 3
#
# This expects agent sessions named: <team-name>-agent-1, <team-name>-agent-2, etc.
# If sessions don't exist yet, the watch command will show an error until they start.

set -euo pipefail

TEAM_NAME="${1:?Usage: team-dashboard.sh <team-name> <agent-count>}"
AGENT_COUNT="${2:?Usage: team-dashboard.sh <team-name> <agent-count>}"
DASHBOARD_SESSION="${TEAM_NAME}-dashboard"

# Validate agent count
if ! [[ "$AGENT_COUNT" =~ ^[0-9]+$ ]] || [ "$AGENT_COUNT" -lt 1 ] || [ "$AGENT_COUNT" -gt 8 ]; then
  echo "Error: agent-count must be between 1 and 8" >&2
  exit 1
fi

# Kill existing dashboard session if it exists
tmux has-session -t "$DASHBOARD_SESSION" 2>/dev/null && tmux kill-session -t "$DASHBOARD_SESSION"

# Create the dashboard session
tmux new-session -d -s "$DASHBOARD_SESSION"

# Split: top row for agents, bottom for command center
# -p 30 gives bottom pane 30% of height
tmux split-window -t "$DASHBOARD_SESSION" -v -p 30

# Select the top pane and split it horizontally for each agent
tmux select-pane -t "${DASHBOARD_SESSION}:0.0"

# Create horizontal splits for agents (first agent uses the existing top pane)
for ((i = 2; i <= AGENT_COUNT; i++)); do
  tmux split-window -t "${DASHBOARD_SESSION}:0.0" -h
  # Rebalance after each split to keep panes even
  tmux select-layout -t "${DASHBOARD_SESSION}:0" tiled 2>/dev/null || true
done

# Now set the layout: top row evenly split, bottom row full width
# Use tiled first, then manually adjust
if [ "$AGENT_COUNT" -le 4 ]; then
  # For small teams, use a simple top/bottom layout
  # Resize the bottom pane to 30%
  tmux select-pane -t "${DASHBOARD_SESSION}:0.$AGENT_COUNT"
fi

# Start watch commands in each top pane
for ((i = 1; i <= AGENT_COUNT; i++)); do
  PANE_INDEX=$((i - 1))
  AGENT_SESSION="${TEAM_NAME}-agent-${i}"
  tmux send-keys -t "${DASHBOARD_SESSION}:0.${PANE_INDEX}" \
    "watch -n 2 'echo \"=== Agent ${i}: ${AGENT_SESSION} ===\"; echo; tmux capture-pane -t ${AGENT_SESSION} -p 2>/dev/null | tail -15 || echo \"(session not running)\"'" Enter
done

# Bottom pane: show a welcome message
BOTTOM_PANE=$AGENT_COUNT
tmux send-keys -t "${DASHBOARD_SESSION}:0.${BOTTOM_PANE}" \
  "echo '=== Team Dashboard: ${TEAM_NAME} (${AGENT_COUNT} agents) ==='" Enter
tmux send-keys -t "${DASHBOARD_SESSION}:0.${BOTTOM_PANE}" \
  "echo 'Commands: tmux capture-pane -t <session> -p | tail -20'" Enter
tmux send-keys -t "${DASHBOARD_SESSION}:0.${BOTTOM_PANE}" \
  "echo 'Cleanup:  tmux kill-session -t <session>'" Enter

# Select the bottom pane (command center)
tmux select-pane -t "${DASHBOARD_SESSION}:0.${BOTTOM_PANE}"

# Attach to the dashboard
tmux attach -t "$DASHBOARD_SESSION"

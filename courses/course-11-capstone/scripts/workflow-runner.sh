#!/bin/bash
# workflow-runner.sh
#
# Launches the full engineering workflow monitoring environment.
# Creates tmux sessions for the CI monitor agent and quality gate agent,
# sets up a monitoring dashboard, and configures automatic log capture.
#
# Usage:
#   ./workflow-runner.sh [project-directory]
#
# If no directory is given, uses the current directory.

set -euo pipefail

PROJECT_DIR="${1:-$(pwd)}"
PROJECT_DIR=$(cd "$PROJECT_DIR" && pwd)

CI_SESSION="workflow-ci-monitor"
QG_SESSION="workflow-quality-gate"
DASHBOARD_SESSION="workflow-dashboard"
LOG_DIR="$PROJECT_DIR/.claude/workflow-logs"

echo "=== Engineering Workflow Runner ==="
echo "Project: $PROJECT_DIR"
echo ""

# --- Cleanup existing sessions ---
for session in "$CI_SESSION" "$QG_SESSION" "$DASHBOARD_SESSION"; do
  tmux has-session -t "$session" 2>/dev/null && tmux kill-session -t "$session"
done

# --- Create log directory ---
mkdir -p "$LOG_DIR"

# --- Launch CI monitor agent ---
echo "Starting CI monitor agent..."
tmux new-session -d -s "$CI_SESSION" -c "$PROJECT_DIR"
tmux send-keys -t "$CI_SESSION" "claude --dangerously-skip-permissions" Enter
sleep 3
tmux send-keys -t "$CI_SESSION" \
  "Use the ci-monitor agent to check the current CI and git status. Report any open PRs, recent workflow runs, and flag any issues that need attention." Enter

# --- Launch quality gate agent ---
echo "Starting quality gate agent..."
tmux new-session -d -s "$QG_SESSION" -c "$PROJECT_DIR"
tmux send-keys -t "$QG_SESSION" "claude --dangerously-skip-permissions" Enter
sleep 3
tmux send-keys -t "$QG_SESSION" \
  "Use the quality-gate agent to review any artifacts in this project (PR-REVIEW.md, CHANGELOG.md, RELEASE_NOTES.md, API.md). Run the test suite and lint checks. Produce a quality report." Enter

# --- Create monitoring dashboard ---
echo "Setting up monitoring dashboard..."
tmux new-session -d -s "$DASHBOARD_SESSION" -c "$PROJECT_DIR"

# Layout:
# ┌──────────────────┬──────────────────┐
# │  CI Monitor tail │ Quality Gate tail│
# ├──────────────────┴──────────────────┤
# │          Command Center             │
# └─────────────────────────────────────┘

tmux split-window -t "$DASHBOARD_SESSION" -v -p 35
tmux select-pane -t "${DASHBOARD_SESSION}:0.0"
tmux split-window -t "${DASHBOARD_SESSION}:0.0" -h

# Top-left: CI monitor tail
tmux send-keys -t "${DASHBOARD_SESSION}:0.0" \
  "watch -n 3 'echo \"=== CI Monitor ===\"; echo; tmux capture-pane -t $CI_SESSION -p 2>/dev/null | tail -15 || echo \"(not running)\"'" Enter

# Top-right: quality gate tail
tmux send-keys -t "${DASHBOARD_SESSION}:0.1" \
  "watch -n 3 'echo \"=== Quality Gate ===\"; echo; tmux capture-pane -t $QG_SESSION -p 2>/dev/null | tail -15 || echo \"(not running)\"'" Enter

# Bottom: command center with instructions
tmux send-keys -t "${DASHBOARD_SESSION}:0.2" \
  "echo '=== Workflow Dashboard ==='" Enter
tmux send-keys -t "${DASHBOARD_SESSION}:0.2" \
  "echo 'Sessions: $CI_SESSION, $QG_SESSION'" Enter
tmux send-keys -t "${DASHBOARD_SESSION}:0.2" \
  "echo ''" Enter
tmux send-keys -t "${DASHBOARD_SESSION}:0.2" \
  "echo 'Commands:'" Enter
tmux send-keys -t "${DASHBOARD_SESSION}:0.2" \
  "echo '  Attach to CI:      tmux attach -t $CI_SESSION'" Enter
tmux send-keys -t "${DASHBOARD_SESSION}:0.2" \
  "echo '  Attach to QG:      tmux attach -t $QG_SESSION'" Enter
tmux send-keys -t "${DASHBOARD_SESSION}:0.2" \
  "echo '  Capture logs:      tmux capture-pane -t SESSION -p -S -1000 > log.txt'" Enter
tmux send-keys -t "${DASHBOARD_SESSION}:0.2" \
  "echo '  Quick AI popup:    tmux display-popup -w 80% -h 80% -E \"claude -p \\\"your question\\\"\"'" Enter
tmux send-keys -t "${DASHBOARD_SESSION}:0.2" \
  "echo ''" Enter
tmux send-keys -t "${DASHBOARD_SESSION}:0.2" \
  "echo 'Cleanup:'" Enter
tmux send-keys -t "${DASHBOARD_SESSION}:0.2" \
  "echo '  for s in $CI_SESSION $QG_SESSION $DASHBOARD_SESSION; do tmux kill-session -t \$s 2>/dev/null; done'" Enter

# Select the command center pane
tmux select-pane -t "${DASHBOARD_SESSION}:0.2"

echo ""
echo "=== Workflow running ==="
echo ""
echo "Sessions:"
echo "  CI Monitor:    $CI_SESSION"
echo "  Quality Gate:  $QG_SESSION"
echo "  Dashboard:     $DASHBOARD_SESSION"
echo ""
echo "Attaching to dashboard..."
echo "(Detach with Ctrl+J d)"
echo ""

# --- Attach to the dashboard ---
tmux attach -t "$DASHBOARD_SESSION"

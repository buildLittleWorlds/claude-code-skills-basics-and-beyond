#!/usr/bin/env bash
# BROKEN: tmux startup script with wrong pane targeting
# BUG: Commands end up in the wrong panes. Find and fix the issue.

SESSION="debug-test"

tmux kill-session -t "$SESSION" 2>/dev/null

# Create session with first window
tmux new-session -d -s "$SESSION" -n "main"

# Split into left and right panes
tmux split-window -t "$SESSION:main" -h

# Now we have pane 0 (left) and pane 1 (right)
# We want to run "ls" in the LEFT pane and "date" in the RIGHT pane

tmux send-keys -t "$SESSION:main.1" "echo 'This should be in the LEFT pane'" Enter
tmux send-keys -t "$SESSION:main.0" "echo 'This should be in the RIGHT pane'" Enter

# Create a second window
tmux new-window -t "$SESSION" -n "monitor"

# Send a command to the monitor window
tmux send-keys -t "$SESSION:main" "echo 'This should be in the monitor window'" Enter

tmux select-window -t "$SESSION:main"

echo "Run: tmux attach -t $SESSION"
echo "Check if the messages are in the correct panes/windows."

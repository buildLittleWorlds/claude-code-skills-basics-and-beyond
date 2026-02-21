# Tmux Quick Reference for Courses 8-11

All commands assume `Ctrl+J` as the prefix key. Substitute your prefix if different.

---

## Session Management

| Command | What it does |
|---------|-------------|
| `tmux new -s name` | Start a new named session |
| `tmux new-session -d -s name` | Create a detached (background) session |
| `tmux new-session -d -s name "cmd"` | Create a detached session running a command |
| `tmux attach -t name` | Attach to a named session |
| `tmux ls` | List all sessions |
| `tmux has-session -t name 2>/dev/null` | Check if session exists (for scripts; check `$?`) |
| `tmux kill-session -t name` | Destroy a session |
| `Ctrl+J d` | Detach from current session |
| `Ctrl+J s` | Interactive session picker |
| `Ctrl+J (` / `Ctrl+J )` | Switch to previous / next session |

---

## Pane Management

| Command | What it does |
|---------|-------------|
| `Ctrl+J %` | Split vertically (left / right) |
| `Ctrl+J "` | Split horizontally (top / bottom) |
| `Ctrl+J arrow` | Move focus to adjacent pane |
| `Ctrl+J z` | Zoom pane to full screen (toggle) |
| `Ctrl+J x` | Close current pane |
| `exit` | Close pane by exiting its shell |

---

## Send-Keys and Capture-Pane

These two commands are how scripts interact with tmux sessions programmatically.

### Sending commands

```bash
# Send a command to a session's active pane
tmux send-keys -t session-name 'echo hello' Enter

# Send to a specific window and pane (window 0, pane 1)
tmux send-keys -t session-name:0.1 'echo hello' Enter
```

### Capturing output

```bash
# Print the visible pane contents
tmux capture-pane -t session-name -p

# Capture the last 30 lines of scrollback
tmux capture-pane -t session-name -p -S -30

# Capture from a specific window and pane
tmux capture-pane -t session-name:0.1 -p

# Common patterns
tmux capture-pane -t session-name -p | tail -5      # last 5 lines
tmux capture-pane -t session-name -p | grep "Error"  # find errors
```

---

## The Five Patterns (Courses 8-11)

### 1. Split panes -- monitor a subagent while testing

```bash
# Inside a session:
# Ctrl+J %          (split left/right)
# Ctrl+J arrow      (switch panes)
# Left pane: your testing shell
# Right pane: Claude or a subagent
```

### 2. Detached sessions -- run headless agents

```bash
tmux new-session -d -s agent "claude 'do something'"
tmux ls                          # confirm it's running
tmux attach -t agent             # check on it
# Ctrl+J d                       # detach when done watching
tmux kill-session -t agent       # clean up
```

### 3. Send commands -- scripted agent orchestration

```bash
tmux new-session -d -s worker
tmux send-keys -t worker 'claude' Enter
# wait for Claude to start...
tmux send-keys -t worker '/review-code' Enter
```

### 4. Capture output -- peek without interrupting

```bash
tmux capture-pane -t worker -p | tail -10
# See the last 10 lines of what the agent produced
```

### 5. List and switch -- manage multiple sessions

```bash
tmux ls                          # see everything
# Ctrl+J s                       # interactive picker
# Ctrl+J (  or  Ctrl+J )         # cycle through sessions
```

---

## Scripting Conventions

When writing tmux scripts (Courses 10-11), follow these patterns:

```bash
# Always check before creating a session
tmux has-session -t name 2>/dev/null && tmux kill-session -t name
tmux new-session -d -s name

# Always clean up on exit
cleanup() {
  tmux kill-session -t agent-1 2>/dev/null
  tmux kill-session -t agent-2 2>/dev/null
}
trap cleanup EXIT
```

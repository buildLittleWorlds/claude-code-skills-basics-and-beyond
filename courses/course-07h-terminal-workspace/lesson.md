# Course 7½: Your Terminal Workspace
**Level**: Intermediate | **Estimated time**: 20 min

## Prerequisites
- Courses 1-7 completed (skills fundamentals, hooks)
- tmux installed (`tmux -V` should show 3.0 or higher; install with `brew install tmux` on macOS)
- Basic command line familiarity

## Why This Course Exists

Courses 1-7 taught you to build skills, test them, and add hooks -- all within a single Claude Code session. The remaining courses go further:

- **Course 8** monitors custom subagents running in separate contexts
- **Course 9** wraps AI + CLI tools into reusable commands that launch in their own sessions
- **Course 10** orchestrates agent teams -- multiple Claude instances working in parallel
- **Course 11** ties everything together with session scripts and automated workflows

All of these require you to **see and manage multiple terminal processes at once**. That's what tmux does. This bridge course makes sure you have the specific tmux skills those courses need.

## Before You Continue

This course is **not** a tmux tutorial. It's a checkpoint.

If you haven't used tmux before, complete the beginner tutorial first:

```
/Users/familyplate/work/learning-tools/tmux-claude/tmux-claude-tutor.md
```

That tutorial teaches tmux from scratch across 10 lessons -- sessions, panes, windows, copy mode, and headless agents. Come back here once you've finished it (or if you already know tmux basics).

## The Ctrl+J Prefix Convention

This curriculum uses `Ctrl+J` as the tmux prefix key instead of the default `Ctrl+b`. All tmux commands in Courses 7½-11 assume this prefix.

**How prefix commands work:**
1. Press `Ctrl+J` (hold Ctrl, tap j, release both)
2. Then press the next key separately (don't hold Ctrl)

Example: `Ctrl+J %` means press `Ctrl+J`, release, then press `%`.

**To configure `Ctrl+J`**, add to `~/.tmux.conf`:

```bash
unbind C-b
unbind C-j
unbind C-a
set-option -g prefix C-j
bind-key C-j send-prefix
```

**Recommended additions** for working with AI CLIs:

```bash
# True color support (for syntax highlighting)
set -g default-terminal "xterm-256color"
set-option -ga terminal-overrides ",xterm-256color:Tc"

# Large scrollback (AI responses can be long)
set -g history-limit 50000

# Mouse support (easier scrolling)
set -g mouse on
```

Reload with: `tmux source ~/.tmux.conf`

If you prefer a different prefix key, that's fine -- mentally substitute it wherever you see `Ctrl+J` in these courses.

## Five Tmux Patterns You Need

Courses 8-11 use five specific tmux patterns. You don't need to memorize every tmux command -- just these five. A printable quick-reference lives alongside this lesson at `tmux-quickref.md`.

### Pattern 1: Split Panes

Split your terminal into side-by-side or stacked areas. Used in Course 8 to monitor a subagent in one pane while testing in another.

| Command | What it does |
|---------|-------------|
| `Ctrl+J %` | Split vertically (left/right) |
| `Ctrl+J "` | Split horizontally (top/bottom) |
| `Ctrl+J arrow` | Move focus between panes |
| `Ctrl+J x` | Close current pane |
| `Ctrl+J z` | Zoom current pane to full screen (toggle) |

**The workflow**: Claude runs in the right pane. You test and verify in the left pane. You can watch Claude's progress and switch over to test immediately.

### Pattern 2: Detached Sessions

Create sessions that run in the background, invisible until you attach. Used in Course 8 for headless agents and Course 10 for background teammates.

| Command | What it does |
|---------|-------------|
| `tmux new-session -d -s name` | Create a detached session |
| `tmux new-session -d -s name "command"` | Create a detached session running a command |
| `tmux attach -t name` | Attach to a session (enter it) |
| `Ctrl+J d` | Detach from current session |
| `tmux kill-session -t name` | Destroy a session |

**The workflow**: Start Claude in a detached session, continue working in your current terminal, then attach to check on it when needed.

### Pattern 3: Send Commands to Sessions

Inject commands into a running session from the outside. Used in Course 9 for scripted CLI workflows and Course 10 for orchestrating agent teams.

| Command | What it does |
|---------|-------------|
| `tmux send-keys -t session 'command' Enter` | Send a command to a session |
| `tmux send-keys -t session:0.1 'command' Enter` | Send to a specific pane (window 0, pane 1) |

**The workflow**: A control script creates agent sessions and sends each one its initial prompt -- no manual typing required.

### Pattern 4: Capture Session Output

Read what a session has produced without attaching to it. Used in Course 8 for checking subagent progress and Course 10 for building monitoring dashboards.

| Command | What it does |
|---------|-------------|
| `tmux capture-pane -t session -p` | Print the visible contents of a session's pane |
| `tmux capture-pane -t session -p -S -30` | Capture the last 30 lines |
| `tmux capture-pane -t session:0.1 -p` | Capture from a specific pane |

**The workflow**: Peek at an agent's output without interrupting it. Pipe into `tail` or `grep` to extract what you need:

```bash
tmux capture-pane -t agent -p | tail -5
tmux capture-pane -t agent -p | grep "Error"
```

### Pattern 5: Session Listing and Switching

See all running sessions and jump between them. Used whenever you're managing multiple agent sessions.

| Command | What it does |
|---------|-------------|
| `tmux ls` | List all sessions |
| `tmux has-session -t name 2>/dev/null` | Check if a session exists (for scripts) |
| `Ctrl+J s` | Interactive session picker |
| `Ctrl+J (` | Switch to previous session |
| `Ctrl+J )` | Switch to next session |

**The workflow**: You have a control session and three agent sessions. Use `Ctrl+J s` to see them all and jump to whichever needs attention.

## Exercises

Work through these four exercises to verify you can perform the patterns above. Each builds on the last.

### Exercise 1: Split Panes

1. Start a tmux session named "workspace":
   ```bash
   tmux new -s workspace
   ```

2. Split vertically into two panes:
   ```
   Ctrl+J %
   ```

3. In the left pane, run:
   ```bash
   echo "left pane"
   ```

4. Move to the right pane (`Ctrl+J right-arrow`) and run:
   ```bash
   echo "right pane"
   ```

5. Verify both outputs are visible side by side.

### Exercise 2: Detached Sessions

1. From inside your "workspace" session, create a detached background session:
   ```bash
   tmux new-session -d -s bg-test "sleep 30"
   ```

2. List sessions to confirm it's running:
   ```bash
   tmux ls
   ```
   You should see both `workspace` and `bg-test`.

3. Attach to the background session:
   ```bash
   tmux attach -t bg-test
   ```

4. Detach back to workspace:
   ```
   Ctrl+J d
   ```

5. Reattach to workspace:
   ```bash
   tmux attach -t workspace
   ```

### Exercise 3: Send Commands and Capture Output

1. Send a command into the background session from your workspace:
   ```bash
   tmux send-keys -t bg-test 'echo "hello from outside"' Enter
   ```

2. Capture the output without attaching:
   ```bash
   tmux capture-pane -t bg-test -p | tail -5
   ```

3. You should see `hello from outside` in the captured output.

### Exercise 4: Clean Up

1. Kill the background session:
   ```bash
   tmux kill-session -t bg-test
   ```

2. Verify it's gone:
   ```bash
   tmux ls
   ```
   Only `workspace` should remain.

3. (Optional) Kill workspace too when done:
   ```bash
   tmux kill-session -t workspace
   ```

## Verification Checklist

Run through this checklist to confirm you're ready for Courses 8-11:

- [ ] tmux is installed (`tmux -V` shows 3.0+)
- [ ] Your prefix key is configured (`Ctrl+J` or your preference)
- [ ] You can split panes and navigate between them
- [ ] You can create and attach to detached sessions
- [ ] You can send commands to a detached session with `send-keys`
- [ ] You can capture a session's output with `capture-pane`
- [ ] You can list sessions and switch between them

If any of these feel unfamiliar, work through the relevant lesson in the beginner tutorial before continuing.

## What's Next

You're ready for the advanced track. Course 8 introduces custom subagents -- specialized AI workers -- and you'll use tmux to monitor them in action.

# Lesson 2: Seeing What Claude Said Without Being There
**Phase**: 3 — Task Workflow Mastery | **Estimated time**: 20 min

## Prerequisites
- Completed **Lesson 1** (send-keys addressing, 3-window layout)
- The `tasks` tmux session from Lesson 1 (or recreate it)
- Claude Code installed (`claude` command available)

## What You'll Learn

Lesson 1 taught you to *send* commands to panes. This lesson teaches the opposite: **reading output** from panes you're not in.

In Phase 1 Lesson 8, you learned copy mode — scrolling back through a pane's history with `Ctrl+J [`. But copy mode requires you to *be in* the pane. What if Claude is running in pane 0 and you're working in pane 1? You want to check what Claude said without switching over, breaking your focus, and switching back.

That's `capture-pane`.

### The `capture-pane` Command

```bash
tmux capture-pane -t <target> -p -S <start-line>
```

| Flag | Meaning |
|------|---------|
| `-t <target>` | Which pane to read (same addressing as `send-keys`) |
| `-p` | Print to stdout (instead of paste buffer) |
| `-S <N>` | Start N lines from the bottom (negative = scrollback) |
| `-E <N>` | End N lines from the bottom |

Examples:

```bash
# Last 20 lines from pane 1 in the hq window
tmux capture-pane -t tasks:hq.1 -p -S -20

# Last 5 lines only
tmux capture-pane -t tasks:hq.1 -p -S -5

# Pipe through grep to find specific output
tmux capture-pane -t tasks:hq.0 -p -S -50 | grep "Error"
```

### Why This Matters for the Cockpit

The cockpit runs Claude in one pane and monitoring in others. `capture-pane` lets you:
- **Check Claude's progress** without switching panes
- **Grep for keywords** in Claude's output (errors, completions, file names)
- **Build monitoring scripts** that watch Claude's output and react to patterns
- **Log sessions** by capturing pane contents to files

The `/session-summary` skill (Lesson 14) uses this pattern to gather what happened during a work session.

## Exercise

### Part 1: Capture from a simple process

Attach to your `tasks` session if needed:

```bash
tmux attach -t tasks
```

Make sure you're in the `hq` window (`Ctrl+J 0`). If the window isn't split, split it now:

```
Ctrl+J %
```

From the left pane (pane 0), start a visible process in the right pane (pane 1):

```bash
tmux send-keys -t tasks:hq.1 "for i in 1 2 3 4 5; do echo \"Task \$i: $(date +%H:%M:%S)\"; sleep 1; done" Enter
```

Wait a few seconds for it to run, then capture the output:

```bash
tmux capture-pane -t tasks:hq.1 -p -S -10
```

You should see the numbered task output from the right pane, printed in your left pane.

### Part 2: Launch Claude and monitor it

Start Claude in the right pane:

```bash
tmux send-keys -t tasks:hq.1 "claude" Enter
```

Wait 3-4 seconds for Claude to initialize. Then send it a prompt:

```bash
tmux send-keys -t tasks:hq.1 "List the files in ~/work/_tasks/pending/ and tell me which one has the earliest due date" Enter
```

Wait 5-10 seconds for Claude to respond, then capture:

```bash
tmux capture-pane -t tasks:hq.1 -p -S -30
```

You should see Claude's response printed in your left pane. Claude is still running interactively in the right pane — you read its output without disturbing it.

### Part 3: Filtered monitoring

Capture and filter. This is the monitoring pattern:

```bash
# Look for any mention of "due" in Claude's output
tmux capture-pane -t tasks:hq.1 -p -S -50 | grep -i "due"

# Look for file paths
tmux capture-pane -t tasks:hq.1 -p -S -50 | grep "\.md"

# Count lines of output
tmux capture-pane -t tasks:hq.1 -p -S -50 | wc -l
```

### Part 4: Capture to a file

Save Claude's output to a log file:

```bash
tmux capture-pane -t tasks:hq.1 -p -S -100 > /tmp/claude-session.log
```

Now you can review it later:

```bash
cat /tmp/claude-session.log
```

This is how the workflow-runner script in the capstone (Course 11) captures agent output for review.

### Part 5: The monitor one-liner

Combine `watch` with `capture-pane` for live monitoring:

```bash
watch -n 2 'tmux capture-pane -t tasks:hq.1 -p -S -15'
```

This refreshes every 2 seconds, showing the last 15 lines of the right pane. Press `Ctrl+c` to stop.

You're now watching Claude's pane in real time from a completely different pane. This is the same pattern the cockpit dashboard uses for its watchers.

### Cleanup

Exit the `watch` command with `Ctrl+c`. Send `/exit` to Claude:

```bash
tmux send-keys -t tasks:hq.1 "/exit" Enter
```

## Checkpoint

- [ ] You can `capture-pane` output from a pane you're not in
- [ ] You can pipe `capture-pane` through `grep` to filter for specific patterns
- [ ] You can save `capture-pane` output to a log file
- [ ] You've used `watch` + `capture-pane` for live monitoring
- [ ] Claude ran in pane 1 and you read its output from pane 0

## Design Rationale

**Why `capture-pane` instead of tailing a log file?** Because Claude Code doesn't write to a log file by default — its output goes to the terminal. `capture-pane` reads the terminal buffer directly. No configuration, no file management, works with any process.

**Why `-S -N` (negative start)?** Positive numbers count from the top of the scrollback buffer. Negative numbers count from the bottom (current view). `-S -20` means "the last 20 lines," which is almost always what you want for monitoring.

## Phase 1 Callback

This lesson builds directly on:
- **Lesson 8** (Copy Mode): Copy mode lets you scroll manually with `Ctrl+J [`. `capture-pane` does the same thing programmatically — it reads the scrollback buffer without entering copy mode. Think of it as scriptable copy mode.

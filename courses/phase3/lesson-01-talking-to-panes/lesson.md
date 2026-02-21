# Lesson 1: Talking to Panes You Are Not In
**Phase**: 3 — Task Workflow Mastery | **Estimated time**: 20 min

## Prerequisites
- Completed **Phase 1** (tmux fundamentals: sessions, panes, windows, detach/reattach)
- Completed **Phase 2** (Claude Code skills: Courses 1-7 + Bridge 7½)
- Run `setup-tasks.sh` to bootstrap `~/work/_tasks/` with seed data
- tmux running with `Ctrl+J` as prefix

## What You'll Learn

In Phase 1, you learned to split panes and switch between them manually — `Ctrl+J ↑`, `Ctrl+J %`, `Ctrl+J o`. You were always *in* the pane you were working with.

Phase 3 flips that pattern. The cockpit has multiple panes running simultaneously — Claude in one, a file watcher in another, a shell in a third. You need to **send commands to panes you're not looking at**. This is the `send-keys` command, and it's the foundation of everything the cockpit automates.

### The `send-keys` Command

```bash
tmux send-keys -t <target> "<command>" Enter
```

The `-t` flag is a **target address**. tmux addressing works like a postal system:

| Address | Meaning | Example |
|---------|---------|---------|
| `session` | Target a session by name | `-t tasks` |
| `session:window` | Target a window by number or name | `-t tasks:1` |
| `session:window.pane` | Target a specific pane | `-t tasks:0.1` |

Pane numbering starts at 0. In a two-pane horizontal split, pane 0 is the top (or left) and pane 1 is the bottom (or right).

### Why This Matters for the Cockpit

The startup script you'll build in Lesson 7 creates a multi-window tmux session and then sends commands to specific panes — launching Claude in one, starting watchers in others, all without you manually switching to each pane. Every `send-keys` call in that script uses the addressing you'll practice here.

## Exercise

### Part 1: Set up your task data

If you haven't already, run the setup script:

```bash
bash skills/courses/phase3/setup-tasks.sh
```

Verify it worked:

```bash
ls ~/work/_tasks/inbox/
ls ~/work/_tasks/pending/
```

You should see 5 files in inbox and 6 in pending.

### Part 2: Build a 3-window layout

1. Create a new session called `tasks`:
   ```bash
   tmux new -s tasks
   ```

2. You're in window 0. Rename it:
   ```
   Ctrl+J ,
   ```
   Type `hq` and press Enter.

3. Create a second window:
   ```
   Ctrl+J c
   ```
   Rename it to `inbox`:
   ```
   Ctrl+J ,
   ```
   Type `inbox` and press Enter.

4. Create a third window:
   ```
   Ctrl+J c
   ```
   Rename it to `pending`.

5. Go back to the HQ window:
   ```
   Ctrl+J 0
   ```

You now have three windows: `hq` (0), `inbox` (1), `pending` (2).

### Part 3: Send commands to other windows

From the `hq` window, send a command to the `inbox` window *without leaving hq*:

```bash
tmux send-keys -t tasks:inbox "ls ~/work/_tasks/inbox/" Enter
```

Now send a command to the `pending` window:

```bash
tmux send-keys -t tasks:pending "ls -lt ~/work/_tasks/pending/" Enter
```

Switch to each window to verify the commands ran:

```
Ctrl+J 1    # Switch to inbox — should show the ls output
Ctrl+J 2    # Switch to pending — should show sorted listing
Ctrl+J 0    # Back to hq
```

### Part 4: Target panes within a window

Split the `hq` window into two vertical panes:

```
Ctrl+J %
```

Now you have `hq` with pane 0 (left) and pane 1 (right). Move to the left pane:

```
Ctrl+J ←
```

From the left pane, send a command to the right pane:

```bash
tmux send-keys -t tasks:hq.1 "echo 'Hello from pane 0!'" Enter
```

Look at the right pane — the echo command ran there.

Now try the reverse. From the left pane, send to the right:

```bash
tmux send-keys -t tasks:hq.1 "wc -l ~/work/_tasks/pending/*.md" Enter
```

The right pane now shows line counts for your pending tasks, while you stayed in the left pane the whole time.

### Part 5: Chain commands

Send multiple commands to a pane in sequence:

```bash
tmux send-keys -t tasks:inbox "echo '--- Inbox Status ---'" Enter
tmux send-keys -t tasks:inbox "echo 'Count:' && ls ~/work/_tasks/inbox/ | wc -l" Enter
tmux send-keys -t tasks:inbox "echo 'Files:' && ls ~/work/_tasks/inbox/" Enter
```

Switch to the inbox window (`Ctrl+J 1`) and you'll see all three commands executed in order.

## Checkpoint

- [ ] `~/work/_tasks/` has 4 subdirectories with seed files (5 inbox, 6 pending, 2 archive, 2 log)
- [ ] You have a `tasks` session with 3 named windows (`hq`, `inbox`, `pending`)
- [ ] From `hq`, you can `send-keys` to the `inbox` window and see results there
- [ ] From `hq`, you can `send-keys` to a specific pane (`.0` or `.1`) within a split window
- [ ] You can chain multiple `send-keys` calls to build up a sequence of commands in a remote pane

## Design Rationale

**Why `send-keys` instead of just running commands directly?** Because the cockpit startup script (Lesson 7) needs to configure multiple panes from a single shell script. It can't "be in" each pane — it creates them and then talks to them remotely. This is also how the `/done` skill triggers a `display-popup`: it sends a tmux command to the right target.

**Why named windows?** Names like `inbox` and `pending` are stable addresses. Window numbers can shift if you create or destroy windows. `tmux send-keys -t tasks:inbox "ls" Enter` works regardless of window ordering.

## Phase 1 Callback

This lesson builds directly on:
- **Lesson 3** (Split Panes): You learned to create panes. Now you're *addressing* them remotely.
- **Lesson 6** (Windows): You learned to create and switch windows. Now you're *sending commands* to them.
- **Lesson 9** (Headless Sessions): You launched Claude in detached sessions. `send-keys` is how the startup script sends the first prompt to those sessions.

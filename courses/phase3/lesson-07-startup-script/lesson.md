# Lesson 7: The Startup Script
**Phase**: 3 — Task Workflow Mastery | **Estimated time**: 25 min

## Prerequisites
- Completed **Lessons 1-6** (all manual operations + `/next`, `/done`, `/triage` skills)
- Completed **Phase 1 Lesson 9** (headless sessions, detached session creation)
- `~/work/_tasks/` populated with seed data (or data from your triage runs)
- The `/today` skill installed (Lesson 8 covers it — install it now for the startup script to work, or skip the auto-`/today` feature until after Lesson 8)

## What You'll Learn

Up to now, you've been manually creating tmux sessions, splitting panes, renaming windows, launching Claude, and switching between things. Every session starts with 2-3 minutes of setup before you can do real work.

This lesson replaces all of that with a single command: `tasks`.

The startup script creates a tmux session called `tasks` with three windows: an HQ window (Claude + shell), an inbox watcher, and a pending watcher. It launches Claude in the HQ pane and sends `/today` to get your morning briefing. If the session already exists, it reattaches instead of creating a duplicate.

This is the script that everything in Phase 3 has been building toward. Every tmux pattern from Lessons 1-3 appears here:
- **`send-keys`** (Lesson 1) to launch commands in other panes
- **`capture-pane`** pattern (Lesson 2) — the watchers use `watch` to continuously display task data
- **Session management** (Lesson 3) — `has-session` for reattach logic

### Script Architecture

```
tasks (startup script)
  │
  ├── Check: session exists? → reattach
  ├── Check: task directories exist? → error if not
  │
  ├── Create session "tasks"
  │   ├── Window 0 "hq": Claude (pane 0) + Shell (pane 1)
  │   ├── Window 1 "inbox": watch inbox directory
  │   └── Window 2 "pending": watch pending with metadata
  │
  ├── Launch Claude in hq.0
  ├── Send /today after 4-second delay
  └── Attach to session
```

## Exercise

### Step 1: Read the startup script

```bash
cat skills/courses/phase3/lesson-07-startup-script/bin/tasks
```

Walk through each section:
- **Reattach guard**: `tmux has-session -t tasks` checks if the session exists. If yes, attach and exit.
- **Directory check**: Verifies `~/work/_tasks/` exists before proceeding.
- **Session creation**: `tmux new-session -d -s tasks -n hq` creates a detached session with the first window named "hq".
- **Pane split**: `split-window -h` creates the Claude + shell layout.
- **Watcher windows**: Each uses `watch -n 5` to refresh every 5 seconds.
- **Claude launch**: `send-keys` starts Claude in hq pane 0.
- **Delayed `/today`**: A background subshell waits 4 seconds, then sends `/today` to Claude.

### Step 2: Install the script

```bash
mkdir -p ~/bin
cp skills/courses/phase3/lesson-07-startup-script/bin/tasks ~/bin/tasks
chmod +x ~/bin/tasks
```

Make sure `~/bin` is in your PATH. Add this to your `~/.zshrc` or `~/.bashrc` if it's not already:

```bash
export PATH="$HOME/bin:$PATH"
```

Reload your shell:

```bash
source ~/.zshrc  # or ~/.bashrc
```

Verify:

```bash
which tasks
```

Should output: `/Users/<you>/bin/tasks`

### Step 3: Kill any existing tasks session

If you have a `tasks` session from earlier lessons, kill it:

```bash
tmux kill-session -t tasks 2>/dev/null; echo "Ready"
```

### Step 4: Launch the cockpit

Make sure you're NOT inside tmux (the script creates its own session):

```bash
tasks
```

You should see:
1. A tmux session with three windows: `hq`, `inbox`, `pending`
2. The HQ window split into two panes (Claude on left, shell on right)
3. Claude starting up in the left pane
4. After ~4 seconds, `/today` is automatically sent to Claude

### Step 5: Explore the windows

Switch between windows to see the watchers:

```
Ctrl+J 1    # inbox watcher — shows inbox file listing, refreshes every 5s
Ctrl+J 2    # pending watcher — shows pending tasks with metadata
Ctrl+J 0    # back to HQ
```

The watchers update automatically. If you add a file to inbox, you'll see it appear in the inbox watcher within 5 seconds.

### Step 6: Test the reattach behavior

Detach from the session:

```
Ctrl+J d
```

Run the script again:

```bash
tasks
```

Instead of creating a new session, it should print "Session 'tasks' already exists. Reattaching..." and bring you back to your existing session with Claude still running.

### Step 7: Test the watcher live

From the HQ shell pane (pane 1), create a test inbox item:

```bash
cat > ~/work/_tasks/inbox/test-watcher.md << 'EOF'
---
title: Test the inbox watcher
status: inbox
created: 2026-02-21T15:00
---
This is a test to see if the watcher picks it up.
EOF
```

Switch to the inbox window (`Ctrl+J 1`). Within 5 seconds, you should see the new file appear in the listing.

Clean up:

```bash
rm ~/work/_tasks/inbox/test-watcher.md
```

### Step 8: Use the cockpit

Now use the cockpit for a real workflow cycle:

1. In the HQ Claude pane, run `/next` to see your pending tasks
2. Pick a task and run `/done <keyword> <summary>`
3. Switch to the pending watcher (`Ctrl+J 2`) — the completed task should disappear within 5 seconds
4. Switch back to HQ (`Ctrl+J 0`)

This is the daily rhythm the cockpit enables: glance at watchers, manage tasks through skills, never leave the terminal.

## Checkpoint

- [ ] `tasks` command launches a 3-window tmux session (hq, inbox, pending)
- [ ] HQ window has Claude in pane 0 and shell in pane 1
- [ ] Inbox and pending watchers refresh every 5 seconds
- [ ] Running `tasks` when a session exists reattaches instead of duplicating
- [ ] Claude receives `/today` automatically after startup
- [ ] The watcher reflects file changes in near-real-time

## Design Rationale

**Why a 4-second delay for `/today`?** Claude Code needs a few seconds to initialize after launch — loading skills, connecting to the API, etc. Sending `/today` immediately would fail because Claude isn't ready. The background subshell `(sleep 4 && tmux send-keys ...)` handles this timing without blocking the script.

**Why `watch` instead of a more sophisticated file watcher?** `watch` is universally available, requires zero dependencies, and does exactly what we need — periodic refresh. A tool like `fswatch` or `inotifywait` would give instant updates but adds a dependency. For a 5-second refresh on a local directory, `watch` is the right level of sophistication.

**Why three windows instead of more panes?** Watchers need vertical space to show meaningful output. Cramming inbox + pending into the HQ window as extra panes would make everything too small. Separate windows give each view full screen real estate, and switching windows (`Ctrl+J 1/2/0`) is fast. Lesson 12 revisits this with a 4-pane HQ layout that includes inline watchers.

## Phase 1 Callback

This lesson builds directly on:
- **Lesson 9** (Headless Sessions): The cockpit creates a detached session (`new-session -d`) and then configures it before attaching. Same pattern as headless Claude sessions, but with more complex setup.
- **Lesson 3** (Split Panes): The HQ split is a direct application of `split-window -h`.
- **Lesson 6** (Windows): Three named windows, each serving a distinct purpose.

## What's Next

The startup script sends `/today` on launch, but Lesson 8 hasn't been covered yet — that's next. You'll build the `/today` morning briefing skill that runs in a forked Explore agent, producing a daily overview without consuming your main conversation context.

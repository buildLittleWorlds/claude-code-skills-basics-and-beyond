# Lesson 3: Jumping Between Worlds
**Phase**: 3 — Task Workflow Mastery | **Estimated time**: 20 min

## Prerequisites
- Completed **Lessons 1-2** (send-keys, capture-pane)
- The `tasks` tmux session from previous lessons
- Seed data in `~/work/_tasks/`

## What You'll Learn

So far you've worked within a single session (`tasks`). But real work spans multiple contexts: your task cockpit in one session, a coding project in another, maybe a server log in a third. tmux handles this with **multiple simultaneous sessions**, and this lesson teaches the rapid-switching workflow that the cockpit is designed to support.

You'll also do a manual version of what the `/next` skill automates in Lesson 4 — querying your pending tasks from the command line. This gives you the "before" picture so you appreciate what skills replace.

### Multi-Session Architecture

```
┌──────────────────────────────┐
│ Session: tasks               │
│ ┌────────┬─────────────────┐ │
│ │ Claude │ Shell            │ │   ← Task management
│ └────────┴─────────────────┘ │
└──────────────────────────────┘

┌──────────────────────────────┐
│ Session: coding              │
│ ┌────────┬─────────────────┐ │
│ │ Editor │ Tests / Server   │ │   ← Development work
│ └────────┴─────────────────┘ │
└──────────────────────────────┘
```

You switch between sessions to change contexts. Detach from one, attach to another — or use the session switcher without detaching at all.

### Session Switching Commands

| Command | What it does |
|---------|-------------|
| `Ctrl+J s` | Interactive session list — select with arrow keys |
| `Ctrl+J (` | Switch to previous session |
| `Ctrl+J )` | Switch to next session |
| `tmux switch-client -t <name>` | Switch directly to a named session |

The session list (`Ctrl+J s`) is the most useful one. It shows all sessions with their windows, and you can expand each session to see its window contents.

## Exercise

### Part 1: Create dual sessions

You should still have the `tasks` session from Lessons 1-2. If not, recreate it:

```bash
tmux new -s tasks
```

Now create a second session for coding work. From within tmux, create a new detached session:

```bash
tmux new-session -d -s coding
```

Verify both exist:

```bash
tmux list-sessions
```

You should see:

```
coding: 1 windows (created ...)
tasks: 3 windows (created ...)
```

### Part 2: Practice rapid switching

Open the session switcher:

```
Ctrl+J s
```

You'll see both sessions listed. Use arrow keys to highlight `coding` and press Enter. You're now in the `coding` session.

Set it up with a split pane:

```
Ctrl+J %
```

In the left pane, create a dummy project file:

```bash
mkdir -p /tmp/my-project
echo 'console.log("hello")' > /tmp/my-project/app.js
cat /tmp/my-project/app.js
```

Now practice the rapid switch cycle:

```
Ctrl+J )    # → tasks session (check what you need to work on)
Ctrl+J )    # → coding session (back to work)
Ctrl+J (    # → tasks session (switched back)
Ctrl+J (    # → coding session (switched forward)
```

This is the **switch-check-switch** rhythm: jump to tasks, see what's next, jump back to coding. With the cockpit running, this becomes: jump to tasks, see your `/next` output, jump back.

### Part 3: The manual "next task" query

Switch to the `tasks` session (`Ctrl+J s`, select `tasks`). Go to the `hq` window if needed (`Ctrl+J 0`).

Manually query your next task — this is what the `/next` skill will automate in Lesson 4:

```bash
echo "=== Pending Tasks (sorted by due date) ==="
for f in ~/work/_tasks/pending/*.md; do
    title=$(grep "^title:" "$f" | sed 's/title: //')
    due=$(grep "^due:" "$f" | sed 's/due: //')
    priority=$(grep "^priority:" "$f" | sed 's/priority: //')
    echo "$due  $priority  $title"
done | sort
```

You should see something like:

```
2026-02-03  P3  Update team wiki with new deployment process
2026-02-14  P1  Fix API timeout on /users endpoint
2026-02-22  P3  Plan weekend hike at Mt. Tam
2026-02-28  P2  Write Q1 quarterly engineering report
2026-03-01  P2  Renew domain registration for myapp.dev
2026-04-15  P3  Gather documents and file taxes
```

The first entries are overdue (past today's date). That's your "next" task.

Now notice what that required: a multi-line bash script with `grep`, `sed`, and `sort`. It works, but it's brittle (no quoting, assumes exact YAML format, no color, no alignment). The `/next` skill replaces this with a single command that Claude handles properly.

### Part 4: Cross-session commands

From the `tasks` session, send a command to the `coding` session:

```bash
tmux send-keys -t coding "echo 'Reminder: fix API timeout before quarterly report'" Enter
```

Switch to `coding` (`Ctrl+J )`) and see the reminder appeared.

Now from `coding`, capture what's in the tasks HQ:

```bash
tmux capture-pane -t tasks:hq.0 -p -S -10
```

You're reading your task list output from the coding session. This cross-session communication is how the cockpit's monitoring scripts work: they reach into the tasks session to check on Claude's progress.

### Part 5: Direct session switching

For scripts (like the startup script in Lesson 7), you often want to switch sessions programmatically:

```bash
tmux switch-client -t tasks
```

This switches you to the `tasks` session instantly — no interactive menu, no key presses.

Switch back:

```bash
tmux switch-client -t coding
```

### Part 6: Kill the coding session

When you're done with a context, destroy the session:

```bash
tmux kill-session -t coding
```

Verify:

```bash
tmux list-sessions
```

Only `tasks` should remain. You can recreate `coding` anytime — sessions are lightweight.

## Checkpoint

- [ ] You can create multiple tmux sessions and switch between them
- [ ] `Ctrl+J s` opens the session switcher, `Ctrl+J (` and `)` cycle through sessions
- [ ] You can `send-keys` across sessions (e.g., from `tasks` to `coding`)
- [ ] You can `capture-pane` across sessions
- [ ] You ran the manual "next task" query and understand what the `/next` skill will replace
- [ ] You practiced the switch-check-switch rhythm between tasks and coding sessions

## Design Rationale

**Why separate sessions instead of separate windows?** Sessions represent distinct *contexts*. When you switch sessions, you get a completely different set of windows and panes — a clean mental separation. Windows within a session are related views of the same context (inbox, pending, HQ are all part of task management). The cockpit uses one session for task management and lets you run other sessions for actual work.

**Why show the manual query?** So you feel the pain that skills solve. Writing bash to parse YAML frontmatter is error-prone and unreadable. The `/next` skill in Lesson 4 does the same thing but handles edge cases, formats output cleanly, and runs with a single slash command.

## Phase 1 Callback

This lesson builds directly on:
- **Lesson 2** (Detach and Reattach): Detach/reattach is the foundation of multi-session work. Here you're managing multiple live sessions without needing to detach — tmux handles the switching.
- **Lesson 6** (Windows): You learned windows as multiple workspaces within one session. Now you have multiple *sessions*, each with their own windows. It's a level up in the hierarchy: terminal > session > window > pane.

## What's Next

Lessons 1-3 gave you the manual building blocks: addressing panes, reading output, switching contexts. Everything was done by hand with shell commands.

Starting in Lesson 4, you'll replace the manual query from Part 3 with a proper Claude Code skill. The transition from "bash one-liners" to "skill slash commands" is the same transition the cockpit makes — from manual tmux operations to automated, AI-powered workflows.

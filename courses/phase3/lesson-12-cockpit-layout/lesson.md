# Lesson 12: The Cockpit Layout
**Phase**: 3 — Task Workflow Mastery | **Estimated time**: 30 min

## Prerequisites
- Completed **Lessons 7-11** (startup script v1, all skills, both hooks)
- Completed **Phase 1 Lessons 3, 6** (pane splits, window management)
- All 5 skills installed (`/next`, `/done`, `/triage`, `/today`, `/overdue`)
- Both hooks installed (compound-reminder, file-protection)

## What You'll Learn

The Lesson 7 startup script created a basic cockpit: Claude + shell in HQ, separate windows for inbox and pending watchers. This lesson builds the full cockpit layout — a single HQ window with 4 panes and a custom status bar:

```
┌─────────────────────────┬──────────────────┐
│                         │                  │
│  Claude Code (pane 0)   │  Shell (pane 2)  │
│                         │                  │
│                         │                  │
├────────────┬────────────┤──────────────────┤
│  📬 Inbox  │  📋 Pending               │
│  watcher   │  watcher                   │
│  (pane 1)  │  (pane 3)                  │
└────────────┴─────────────────────────────┘
  Status bar: 📬 3 | 📋 8 | ⚠️ 2 | 14:30
```

The key improvements over v1:
- **Everything in one window**: No window switching needed for a quick glance
- **Custom status bar**: Inbox count, pending count, overdue count, and time — always visible
- **4-pane layout**: Claude gets the most space (top-left), shell for commands (top-right), watchers below (small, heads-up display)

### The Layout Build Sequence

Creating a 4-pane layout requires a specific split sequence:

```
Start: [──────────── full ────────────]

Step 1: Split horizontally (top/bottom, 70/30)
        [──────────── top ────────────]
        [─────────── bottom ──────────]

Step 2: Split top vertically (left/right, 60/40)
        [── Claude ──|── Shell ──]
        [──────── bottom ────────]

Step 3: Split bottom vertically (left/right, 50/50)
        [── Claude ──|── Shell ──]
        [── Inbox ───|── Pending ──]
```

The order matters because pane numbering shifts as you split. The script accounts for this.

## Exercise

### Step 1: Read the enhanced startup script

```bash
cat skills/courses/phase3/lesson-12-cockpit-layout/bin/tasks-v2
```

Compare with the Lesson 7 script. Key differences:
- 4-pane split sequence with percentage-based sizing (`-p 30`, `-p 40`, `-p 50`)
- Watchers embedded in HQ panes instead of separate windows
- Custom status bar with `tmux set status-right`
- Status bar uses shell commands to compute live counts

### Step 2: Install the enhanced script

```bash
cp skills/courses/phase3/lesson-12-cockpit-layout/bin/tasks-v2 ~/bin/tasks
chmod +x ~/bin/tasks
```

This replaces the v1 script. The command is still `tasks`.

### Step 3: Kill any existing session and launch

```bash
tmux kill-session -t tasks 2>/dev/null
tasks
```

You should see the 4-pane layout:
- **Top-left**: Claude Code initializing
- **Top-right**: Empty shell prompt (cursor here)
- **Bottom-left**: Inbox watcher refreshing every 5 seconds
- **Bottom-right**: Pending watcher with task list and overdue markers

### Step 4: Check the status bar

Look at the bottom of your terminal — the tmux status bar should show:
- `📬 N` — inbox count
- `📋 N` — pending count
- `⚠️ N` — overdue count
- Current time

The counts update every 10 seconds (configured via `status-interval`).

### Step 5: Work in the cockpit

From the shell pane (top-right), you can:
- Run validation scripts
- Check files manually
- Create new inbox items

From the Claude pane (top-left), you can:
- Run `/next`, `/done`, `/triage`, `/today`, `/overdue`
- Ask Claude questions about your tasks

The bottom panes give you constant awareness:
- Inbox watcher shows new items as they appear
- Pending watcher shows the current queue with overdue markers

### Step 6: Navigate between panes

```
Ctrl+J ↑    # Move to pane above
Ctrl+J ↓    # Move to pane below
Ctrl+J ←    # Move to pane left
Ctrl+J →    # Move to pane right
Ctrl+J o    # Cycle to next pane
Ctrl+J z    # Zoom current pane to full screen (toggle)
```

The zoom shortcut (`Ctrl+J z`) is especially useful: zoom into Claude's pane for reading long output, then zoom back to the 4-pane view.

### Step 7: Test live updates

Add an inbox item from the shell pane:

```bash
cat > ~/work/_tasks/inbox/test-layout.md << 'EOF'
---
title: Test the cockpit layout
status: inbox
created: 2026-02-21T16:00
---
This tests whether the inbox watcher picks up new files.
EOF
```

Watch the bottom-left pane — within 5 seconds, the new file should appear. Also check the status bar — the inbox count should increment.

Now complete a task from the Claude pane:

```
/done test-layout Verified cockpit watcher works
```

The inbox watcher should show the file disappear, and the pending watcher should reflect the change.

Clean up if needed:

```bash
rm ~/work/_tasks/inbox/test-layout.md 2>/dev/null
rm ~/work/_tasks/pending/test-layout.md 2>/dev/null
```

## Checkpoint

- [ ] `tasks` launches a 4-pane HQ layout (Claude, shell, inbox watcher, pending watcher)
- [ ] The status bar shows inbox count, pending count, overdue count, and time
- [ ] Watchers refresh automatically every 5 seconds
- [ ] Status bar counts update every 10 seconds
- [ ] `Ctrl+J z` zooms a pane to full screen and back
- [ ] Adding/removing files is reflected in watchers and status bar
- [ ] Claude receives `/today` automatically after startup

## Design Rationale

**Why 70/30 vertical split?** Claude Code produces verbose output that benefits from screen height. The watchers are heads-up displays — they show short lists that don't need much space. 70/30 gives Claude enough room while keeping the watchers visible.

**Why 60/40 horizontal split for the top?** Claude's output is wider (code blocks, tables, formatted text). The shell mostly runs short commands. 60/40 gives Claude more breathing room.

**Why embed watchers instead of separate windows?** Window switching breaks visual continuity. With embedded watchers, you always see your task state — no switching required. The tradeoff is less space for each element, but the `Ctrl+J z` zoom handles cases where you need full-screen for one pane.

**Why shell commands in the status bar?** The `#()` syntax in tmux status bar runs a shell command and inserts the output. It's evaluated every `status-interval` seconds. This is the simplest way to show live counts without a separate monitoring process.

## Phase 1 Callback

This lesson builds directly on:
- **Lesson 3** (Split Panes): Multiple splits in sequence to create the 4-pane layout
- **Lesson 6** (Windows): Understanding window vs pane tradeoffs
- **Phase 1 overall**: Every tmux concept from sessions through headless sessions is used in this script

## What's Next

The cockpit is now fully operational with 4 panes, live watchers, a status bar, and all skills. Lesson 13 tests the entire pipeline with a second domain (side-gigs) to verify everything works across multiple task types. This is the integration test before the final skills.

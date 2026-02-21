# Lesson 11: File Protection Hook
**Phase**: 3 — Task Workflow Mastery | **Estimated time**: 20 min

## Prerequisites
- Completed **Lesson 10** (Stop hook, `stop_hook_active`, settings.json configuration)
- Completed **Phase 2 Course 7** (PreToolUse hooks, matchers, JSON stdin, `jq`)
- `jq` installed
- Hook infrastructure from Lesson 10 in place

## What You'll Learn

The compound-reminder hook (Lesson 10) is reactive — it reminds you *after* Claude finishes. This lesson builds a **proactive** hook that intercepts tool calls *before* they execute.

The file-protection hook blocks any Edit or Write operation targeting files in `~/work/_tasks/log/` or `~/work/_tasks/archive/`. These directories are meant to be append-only (log) and read-only (archive). Without this hook, Claude might helpfully "fix" a log entry or "update" an archived task, corrupting the audit trail.

### PreToolUse vs Stop

| Aspect | Stop (Lesson 10) | PreToolUse (This lesson) |
|--------|------------------|--------------------------|
| When | After Claude responds | Before a tool executes |
| Can block | The end of a turn (exit 2 = feedback) | The tool call itself (exit 2 = blocked) |
| Input | None (no stdin) | JSON with tool name and parameters |
| Matcher | No matcher (fires on every Stop) | Matches on tool name (`Edit\|Write`) |
| Purpose | Post-action reminders | Pre-action guardrails |

### JSON Input Format

PreToolUse hooks receive JSON on stdin describing the tool call about to execute:

```json
{
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "/Users/you/work/_tasks/log/2026-02-21.md",
    "old_string": "...",
    "new_string": "..."
  }
}
```

The hook reads this, extracts `file_path` with `jq`, checks if it's a protected path, and either allows (exit 0) or blocks (exit 2 with error message on stderr).

## Exercise

### Step 1: Read the hook script

```bash
cat skills/courses/phase3/lesson-11-file-protection/hooks/protect-task-files.sh
```

Key sections:
1. **Read stdin**: `input=$(cat)` captures the JSON
2. **Extract path**: `jq -r '.tool_input.file_path // empty'` gets the target file
3. **Pattern match**: `case` statement checks if the path starts with the log or archive directory
4. **Block or allow**: Exit 2 with a specific error message, or exit 0

### Step 2: Install the hook

```bash
cp skills/courses/phase3/lesson-11-file-protection/hooks/protect-task-files.sh ~/.claude/hooks/protect-task-files.sh
chmod +x ~/.claude/hooks/protect-task-files.sh
```

Add it to your settings. Edit `~/.claude/settings.json` to include a PreToolUse hook:

```json
{
  "hooks": {
    "Stop": [
      {
        "type": "command",
        "command": "bash ~/.claude/hooks/compound-reminder.sh"
      }
    ],
    "PreToolUse": [
      {
        "type": "command",
        "command": "bash ~/.claude/hooks/protect-task-files.sh",
        "matcher": "Edit|Write"
      }
    ]
  }
}
```

Note the `matcher`: the hook only fires for Edit and Write tool calls. It never fires for Read, Glob, Grep, or Bash — those can safely access any file.

### Step 3: Test — block a log file edit

Ask Claude to edit a log file:

```
Edit the file ~/work/_tasks/log/2026-02-12.md and change "Status: done" to "Status: in progress"
```

Claude should attempt an Edit tool call, the hook should intercept it, and you should see the block message: "Cannot edit log files directly. Log files are append-only. New entries are created by the /done skill."

### Step 4: Test — block an archive file edit

```
Open ~/work/_tasks/archive/setup-ci-pipeline.md and change the status to pending
```

The hook should block this too: "Cannot edit archived tasks. If you need to reopen a task, move it back to pending/."

### Step 5: Test — allow a pending file edit

```
Read ~/work/_tasks/pending/write-quarterly-report.md and change the priority from P2 to P1
```

This should succeed — pending files are not protected. The hook checks the path, sees it's not log or archive, and exits 0 (allow).

### Step 6: Test — allow a read operation

```
Read ~/work/_tasks/log/2026-02-12.md
```

This should succeed. The hook only fires on Edit and Write (matcher: `Edit|Write`). Read operations aren't intercepted.

## Checkpoint

- [ ] Editing a log file is blocked with a clear error message
- [ ] Editing an archive file is blocked with a clear error message
- [ ] Editing a pending file is allowed
- [ ] Reading log/archive files is allowed (hook doesn't fire on Read)
- [ ] The error messages suggest the correct alternative (use `/done`, or move to pending)
- [ ] Both hooks (compound-reminder + file-protection) coexist in settings.json

## Design Rationale

**Why `case` pattern matching instead of `if` with string contains?** The `case "$path" in "$LOG_DIR"/*)` pattern is a bash idiom for prefix matching. It's more reliable than substring checks and doesn't require regex. It also handles edge cases like `$LOG_DIR` being a parent directory.

**Why specific error messages?** When Claude gets blocked, it relays the error to you. A generic "permission denied" doesn't help. A specific message like "Use /done to create log entries" teaches the workflow — the hook is a guardrail *and* a guide.

**Why protect archive but not inbox or pending?** Inbox and pending files are actively managed — triage modifies inbox files, priority changes modify pending files. Archive files are the historical record: they should only contain what was true at completion time. Log files are the audit trail: they're append-only by convention, and the hook enforces that convention.

## Phase 2 Callback

This lesson builds directly on:
- **Course 7** (Hooks): PreToolUse event, `Edit|Write` matcher, JSON stdin parsing with `jq`, exit code 2 for blocking with feedback. This is the exact pattern from Course 7's `protect-files.sh` example, applied to the task system.

## What's Next

With both hooks installed, the task system has guardrails: the reminder ensures documentation, and the file protection ensures data integrity. Lesson 12 builds the full cockpit layout — a 4-pane HQ with inline watchers, a custom status bar showing task counts, and the enhanced startup script that ties everything together.

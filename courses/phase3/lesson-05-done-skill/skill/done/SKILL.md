---
name: done
description: Marks a task as completed, moves it to the archive, and logs the completion. Use when the user says "done with", "finished", "completed", "mark done", or invokes /done. Accepts a task keyword and optional summary.
disable-model-invocation: true
argument-hint: "[task-keyword] [completion summary]"
---

# Complete a Task

Mark a pending task as done, move it to the archive, and create a log entry.

## Arguments

- `$0` — A keyword or partial filename matching a task in `~/work/_tasks/pending/` (required)
- Remaining arguments after the keyword — A brief completion summary (optional; if omitted, ask the user)

Example invocations:
- `/done fix-api-timeout Reduced default page size to 100, added cursor pagination`
- `/done wiki Updated all three deployment pages`
- `/done hike` (no summary — ask the user what was accomplished)

## Workflow

### Step 1: Find the task

Search `~/work/_tasks/pending/` for a file whose name contains `$0`.

- If exactly one match: proceed with that file
- If multiple matches: list them and ask the user to clarify
- If no match: tell the user no pending task matches that keyword and suggest running `/next` to see available tasks

### Step 2: Confirm with the user

Before making changes, show what will happen:

```
Completing: "Fix API timeout on /users endpoint"
  File: fix-api-timeout.md
  Moving: pending/ → archive/
  Log entry will be appended to: log/YYYY-MM-DD.md

Summary: Reduced default page size to 100, added cursor pagination

Proceed? (y/n)
```

Wait for confirmation. If the user says no, abort without changes.

### Step 3: Update the task file

Change the `status` field in the YAML frontmatter from `pending` to `done`:

```yaml
status: done
```

Do not modify any other frontmatter fields. Do not change the body content.

### Step 4: Move to archive

Move the file from `~/work/_tasks/pending/` to `~/work/_tasks/archive/`:

```bash
mv ~/work/_tasks/pending/<filename>.md ~/work/_tasks/archive/<filename>.md
```

### Step 5: Append log entry

Append a completion record to `~/work/_tasks/log/YYYY-MM-DD.md` (using today's date). Create the file if it doesn't exist.

Format:

```markdown
## HH:MM — <task title>

**Status**: done
**Summary**: <completion summary from arguments or user input>
**Time in pending**: <number of days between `created` date and today>

---
```

### Step 6: Show floating confirmation

After the task is completed, use `tmux display-popup` to show a brief confirmation:

```bash
tmux display-popup -d 3 -w 50 -h 6 "echo '✅ Done: <task title>'"
```

This displays a floating popup for 3 seconds confirming the completion.

### Step 7: Suggest next action

After completing, suggest:
- "Run `/next` to see your updated task list"
- If this was an overdue task, note that the overdue count decreased

## Rules

- Never delete task files — always move to archive
- Never modify log entries that already exist — only append new entries
- If the log file for today already exists, append to it (don't overwrite)
- The completion summary should be a single line (under 200 characters)
- Always calculate "time in pending" from the `created` field in frontmatter

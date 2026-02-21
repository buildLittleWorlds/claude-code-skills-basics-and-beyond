# Lesson 5: `/done` with Arguments
**Phase**: 3 — Task Workflow Mastery | **Estimated time**: 30 min

## Prerequisites
- Completed **Lesson 4** (`/next` skill installed and working)
- Completed **Phase 2 Course 5** (arguments, `$ARGUMENTS`, `argument-hint`)
- Completed **Phase 2 Course 6** (multi-step workflows, validation gates)
- Seed data in `~/work/_tasks/` with pending tasks visible via `/next`
- Claude Code running in your `tasks` tmux session

## What You'll Learn

`/next` showed you what to work on. `/done` closes the loop — it marks a task as completed, moves it to the archive, logs the completion, and shows a floating confirmation popup.

This skill introduces two new concepts from Phase 2:

1. **Arguments** (Course 5): `/done fix-api-timeout Reduced page size to 100` passes a task keyword and a completion summary. The skill uses `$0` for the keyword and the remaining text as the summary.

2. **Multi-step workflow** (Course 6): The skill follows a strict sequence — find → confirm → update → move → log → popup. Each step depends on the previous one. If the find step fails (no match), the whole workflow stops early with a helpful message.

Plus a new tmux concept: **`display-popup`** — a floating overlay window. Instead of printing a success message that scrolls away, `/done` shows a temporary popup that appears on top of whatever you're doing, then disappears.

### The `display-popup` Command

```bash
tmux display-popup -d <seconds> -w <width> -h <height> "<command>"
```

| Flag | Meaning |
|------|---------|
| `-d <seconds>` | Auto-close after N seconds (0 = stay until dismissed) |
| `-w <width>` | Width in columns (or percentage like `50%`) |
| `-h <height>` | Height in rows |
| `"<command>"` | Shell command whose output is shown in the popup |

The popup floats in the center of the current pane. It's modal — you can't interact with the pane behind it until it closes. With `-d 3`, it auto-closes after 3 seconds.

This is the same mechanism that `/overdue` (Lesson 9) uses for its Tier 3 escalation popup.

## Exercise

### Step 1: Read the SKILL.md

Examine the skill:

```bash
cat skills/courses/phase3/lesson-05-done-skill/skill/done/SKILL.md
```

Notice the key differences from `/next`:

| Feature | `/next` | `/done` |
|---------|---------|---------|
| Arguments | None | `$0` keyword + remaining text as summary |
| `argument-hint` | None | `[task-keyword] [completion summary]` |
| Workflow steps | 1 (read + display) | 7 (find → confirm → update → move → log → popup → suggest) |
| File modifications | None (read-only) | Moves file, edits frontmatter, appends to log |
| User confirmation | None | Explicit y/n before changes |

### Step 2: Read the validation script

```bash
cat skills/courses/phase3/lesson-05-done-skill/skill/done/scripts/validate-done.sh
```

This script checks 6 things after a `/done` operation:
1. File removed from `pending/`
2. File exists in `archive/`
3. Archive file has `status: done`
4. Today's log file exists
5. Log file mentions the task title
6. Log entry has required `Status` and `Summary` fields

You'll run this after testing to verify the skill worked correctly.

### Step 3: Install the skill

```bash
mkdir -p ~/.claude/skills/done
cp skills/courses/phase3/lesson-05-done-skill/skill/done/SKILL.md ~/.claude/skills/done/SKILL.md
```

Verify:

```bash
cat ~/.claude/skills/done/SKILL.md
```

### Step 4: Run `/next` to pick a target

Before completing a task, see what's available:

```
/next
```

Pick a task to complete. The `fix-api-timeout` task is a good choice — it's overdue, which will let you verify the overdue count changes.

### Step 5: Complete a task with full arguments

Run `/done` with both a keyword and a summary:

```
/done fix-api-timeout Reduced default page size to 100 and added cursor-based pagination
```

Claude should:
1. Find `fix-api-timeout.md` in pending
2. Show you a confirmation with the task title, file move, and summary
3. Wait for your confirmation
4. Update the status, move the file, append a log entry
5. Show a floating popup (if you're in tmux)
6. Suggest running `/next` again

Say "yes" when prompted to confirm.

### Step 6: Validate the completion

Run the validation script:

```bash
bash skills/courses/phase3/lesson-05-done-skill/skill/done/scripts/validate-done.sh fix-api-timeout.md
```

You should see 6 green checkmarks. If any fail, read the error and check what went wrong.

Manually inspect the results:

```bash
# Task should be gone from pending
ls ~/work/_tasks/pending/fix-api-timeout.md 2>/dev/null || echo "✓ Not in pending"

# Task should be in archive
cat ~/work/_tasks/archive/fix-api-timeout.md

# Log entry should exist for today
cat ~/work/_tasks/log/$(date +%Y-%m-%d).md
```

### Step 7: Test without a summary

Try completing another task without providing a summary:

```
/done wiki
```

Claude should find `update-team-wiki.md`, and since no summary was provided, it should ask you what you accomplished. Provide a summary when asked:

```
Updated deployment, hotfix, and onboarding wiki pages to reference GitHub Actions
```

Run validation again:

```bash
bash skills/courses/phase3/lesson-05-done-skill/skill/done/scripts/validate-done.sh update-team-wiki.md
```

### Step 8: Test the ambiguous match case

What happens with a vague keyword? Try:

```
/done plan
```

If you still have both `plan-weekend-hike.md` and any other task with "plan" in the name, Claude should list the matches and ask you to be more specific. If only one matches, it proceeds normally.

### Step 9: Test the no-match case

Try a keyword that doesn't match anything:

```
/done nonexistent-task
```

Claude should tell you no pending task matches and suggest running `/next`.

### Step 10: Verify `/next` reflects the changes

```
/next
```

The completed tasks should no longer appear. The overdue count should have decreased. Your pending list is shorter now.

### Step 11: Try `display-popup` manually (optional)

If you want to see the popup mechanism independently of the skill:

```bash
tmux display-popup -d 3 -w 40 -h 5 "echo '✅ Task completed!'"
```

A floating box should appear for 3 seconds and then vanish. This is what the `/done` skill triggers in Step 6 of its workflow.

Try a larger popup:

```bash
tmux display-popup -d 5 -w 60 -h 8 "echo '══════════════════════════════'; echo '  Task: Fix API timeout'; echo '  Status: ✅ Complete'; echo '  Archived: $(date +%Y-%m-%d)'; echo '══════════════════════════════'"
```

## Checkpoint

- [ ] `/done fix-api-timeout <summary>` finds the task, confirms, moves to archive, and logs
- [ ] `validate-done.sh fix-api-timeout.md` passes all 6 checks
- [ ] `/done wiki` (no summary) prompts you for a completion summary
- [ ] `/done nonexistent` returns a helpful "not found" message
- [ ] `/next` shows the updated task list with completed tasks removed
- [ ] `tmux display-popup` shows a floating overlay that auto-closes
- [ ] Today's log file contains entries for each completed task

## Design Rationale

**Why require confirmation before `/done` makes changes?** Destructive-ish operations (moving files, appending logs) should have a gate. If the keyword matched the wrong task, you want to catch it before the move happens. This follows the "validation gate" pattern from Phase 2 Course 6 — sequential workflows should verify before advancing to irreversible steps.

**Why `argument-hint` instead of a more structured argument parser?** Skills receive arguments as plain text. Claude is good at extracting meaning from natural language ("fix-api-timeout Reduced page size" → keyword: fix-api-timeout, summary: Reduced page size). Building a rigid parser would be over-engineering. The `argument-hint` field in frontmatter provides enough guidance for users without constraining the input format.

**Why append-only logs?** The log directory is an audit trail. You never edit past entries, only add new ones. This makes the data trustworthy — you can always reconstruct what happened on any day by reading its log file. The `/session-summary` skill (Lesson 14) reads these logs to produce end-of-day reports.

**Why `display-popup` instead of just printing a message?** A printed message scrolls away as more output appears. A popup is *interruptive* — it confirms the action in a way you can't miss, then disappears so it doesn't clutter your terminal. It's the same UX principle as a toast notification in a web app.

## Phase 2 Callback

This lesson builds directly on:
- **Course 5** (Advanced Features): `$ARGUMENTS` for the task keyword, `argument-hint` for autocomplete guidance. The `/done` skill is the first Phase 3 skill to use parameterized input.
- **Course 6** (Multi-Step Workflows): The 7-step workflow follows sequential orchestration with validation gates. Step 1 (find) must succeed before Step 2 (confirm). Step 2 must be approved before Steps 3-6 execute.
- **Course 3** (Full Skill Anatomy): The `scripts/validate-done.sh` file lives in the skill's `scripts/` directory, following the validation script pattern from Course 3.

## What's Next

You now have two skills: `/next` to see what's pending and `/done` to complete tasks. But new tasks still need to be triaged manually — moved from inbox to pending with proper metadata. Lesson 6 builds `/triage`, which uses dynamic context injection (`!`command``) to read the inbox live and route tasks with domain, priority, and due date assignment. It's the first skill that actually *creates* data rather than just reading or moving it.

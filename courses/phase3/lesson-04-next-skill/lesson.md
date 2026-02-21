# Lesson 4: First Skill — `/next`
**Phase**: 3 — Task Workflow Mastery | **Estimated time**: 25 min

## Prerequisites
- Completed **Lessons 1-3** (send-keys, capture-pane, multi-session switching)
- Completed **Phase 2 Courses 1-3** (skill anatomy, descriptions, full skill structure)
- Seed data in `~/work/_tasks/` (run `setup-tasks.sh` if needed)
- Claude Code running in your `tasks` session

## What You'll Learn

In Lesson 3, you wrote a manual bash script to query your pending tasks:

```bash
for f in ~/work/_tasks/pending/*.md; do
    title=$(grep "^title:" "$f" | sed 's/title: //')
    due=$(grep "^due:" "$f" | sed 's/due: //')
    priority=$(grep "^priority:" "$f" | sed 's/priority: //')
    echo "$due  $priority  $title"
done | sort
```

It worked, barely. No error handling, no color, fragile parsing, and you had to type (or remember) the whole thing each time.

This lesson replaces that with `/next` — a proper Claude Code skill that reads your pending tasks, sorts them by due date, highlights overdue items, and displays a clean formatted table. One slash command instead of a fragile one-liner.

### Design Decisions

Before building, let's think through the design choices. These map directly to concepts from Phase 2:

**Why `disable-model-invocation: true`?**
(Phase 2 Course 2) — `/next` is a query you run deliberately. You don't want Claude auto-triggering it every time you mention tasks in conversation. It should only run when you explicitly type `/next`.

**Why no `context: fork`?**
(Phase 2 Course 5) — The output is small (a formatted table with 5-10 rows). There's no reason to isolate this in a subagent — you *want* to see the table in your main conversation so you can say "let's work on the first one" and Claude has context.

**Why no `allowed-tools` restriction?**
Claude needs to read files from `~/work/_tasks/pending/`. The default tool set includes `Read`, `Glob`, and `Grep`, which is exactly what's needed. No writes, no Bash — the skill instructions say "do not modify any files" which is sufficient guardrailing for a read-only query.

**Why not a shell script?**
The YAML frontmatter parsing benefits from Claude's ability to handle edge cases: multi-line titles, missing fields, varied formatting. A bash script breaks on any deviation. Claude handles it naturally.

## Exercise

### Step 1: Read the SKILL.md

Open the skill file included with this lesson:

```bash
cat skills/courses/phase3/lesson-04-next-skill/skill/next/SKILL.md
```

Read through it. Notice the structure:
- **Frontmatter**: `name`, `description` with trigger phrases, `disable-model-invocation: true`
- **Steps**: Numbered sequence (read files → parse frontmatter → sort → display)
- **Output Format**: Explicit template showing exactly what the output should look like
- **Rules**: Constraints (read-only, overdue marking, empty-state handling)

This follows the pattern from Phase 2 Course 1 (skill anatomy) and Course 2 (description formula: `[What] + [When] + [Capabilities]`).

### Step 2: Install the skill

Copy the skill to your personal skills directory:

```bash
mkdir -p ~/.claude/skills/next
cp skills/courses/phase3/lesson-04-next-skill/skill/next/SKILL.md ~/.claude/skills/next/SKILL.md
```

Verify it's in place:

```bash
cat ~/.claude/skills/next/SKILL.md
```

### Step 3: Test with direct invocation

Open Claude Code (or use your existing session in the `tasks` tmux window):

```
/next
```

Claude should read the pending task files and display a formatted table sorted by due date. You should see:
- Overdue tasks marked with ⚠️ (like `fix-api-timeout` with a Feb 14 due date)
- Tasks sorted earliest-first
- A summary line at the bottom with counts

### Step 4: Verify the output

Check the results against your seed data. You should see all 6 pending tasks:

| Due Date | Expected Priority | Task |
|----------|------------------|------|
| 2026-02-03 | P3 | Update team wiki (overdue ⚠️) |
| 2026-02-14 | P1 | Fix API timeout (overdue ⚠️) |
| 2026-02-22 | P3 | Plan weekend hike |
| 2026-02-28 | P2 | Write quarterly report |
| 2026-03-01 | P2 | Renew domain registration |
| 2026-04-15 | P3 | File taxes |

If any tasks are missing or out of order, check:
- Does the file exist in `~/work/_tasks/pending/`?
- Does it have valid YAML frontmatter with a `due` field?
- Is the `status` field set to `pending`?

### Step 5: Test the empty state

Temporarily move all pending files to see the empty-state behavior:

```bash
mkdir -p /tmp/tasks-backup
mv ~/work/_tasks/pending/*.md /tmp/tasks-backup/
```

Run `/next` again. Claude should display the "No pending tasks" message.

Restore the files:

```bash
mv /tmp/tasks-backup/*.md ~/work/_tasks/pending/
rmdir /tmp/tasks-backup
```

### Step 6: Iterate on the output (optional)

If the output doesn't match what you'd like, this is a great chance to practice the iteration loop from Phase 2 Course 4. Try tweaking the SKILL.md:

- Change the output format (wider columns? different emoji?)
- Add a `--domain` filter idea to the description
- Adjust the summary line

Remember: the skill is just a markdown file. Edit `~/.claude/skills/next/SKILL.md`, then re-run `/next` to see the change.

## Checkpoint

- [ ] `/next` displays a sorted table of pending tasks from `~/work/_tasks/pending/`
- [ ] Overdue tasks (due date before today) are visually distinguished
- [ ] The summary line shows total count, overdue count, and due-today count
- [ ] An empty pending directory produces a helpful message
- [ ] The skill appears in `/help` output

## Design Rationale

**Why is this the first skill?** Because it's the simplest possible useful skill for the cockpit: read-only, no arguments, no dynamic context, no forking. It exercises only Phase 2 Courses 1-3 concepts (anatomy, description, structure). Each subsequent skill adds one more feature — `/done` adds arguments, `/triage` adds dynamic context, `/today` adds forking. The complexity ramp is deliberate.

**Why sort by due date instead of priority?** Due date creates urgency-first ordering. A P3 task due yesterday is more urgent than a P1 task due next month. Priority is a secondary signal shown in the table for context, not the sort key. If you disagree, change it — that's the point of building your own skills.

## Phase 2 Callback

This lesson builds directly on:
- **Course 1** (Your First Skill): You're building a SKILL.md with frontmatter and body, installed to `~/.claude/skills/`. Same structure as `daily-standup`.
- **Course 2** (Descriptions and Triggers): The description follows the `[What] + [When] + [Capabilities]` formula. `disable-model-invocation: true` prevents auto-triggering.
- **Course 3** (Full Skill Anatomy): The skill is simple enough that it needs no `scripts/`, `references/`, or `assets/` directories. But notice how the output format section acts like a built-in reference — it tells Claude exactly what "correct" looks like.

## What's Next

`/next` shows you what to work on. Lesson 5 builds `/done` — the skill that completes a task, moves it to the archive, and logs the completion. It introduces `$ARGUMENTS` (so you can say `/done fix-api-timeout Reduced page size`) and `tmux display-popup` for floating confirmation dialogs.

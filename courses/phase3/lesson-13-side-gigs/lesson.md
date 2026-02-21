# Lesson 13: Side-Gigs Domain
**Phase**: 3 — Task Workflow Mastery | **Estimated time**: 20 min

## Prerequisites
- Completed **Lessons 4-12** (all skills, hooks, and cockpit layout working)
- All 5 skills installed and tested with the original seed data

## What You'll Learn

This lesson isn't about building anything new — it's an **integration test**. You'll add a second batch of tasks (freelance work, personal projects, professional development) and verify that every skill in the pipeline handles them correctly.

The question being tested: does the system you built generalize, or does it only work for the specific seed data you started with?

### Why This Matters

Real task management spans multiple domains. Your original seed data was a mix of work tasks and personal errands. The side-gigs data adds:
- **Freelance**: Client invoicing, project deadlines
- **Content creation**: Blog posts, conference talks
- **Professional development**: Memberships, portfolio updates

If `/triage` correctly routes these, `/next` sorts them properly, `/done` archives them, and `/overdue` escalates them — then the system works. If something breaks, the exercise helps you find and fix the edge case.

## Exercise

### Step 1: Add the side-gigs seed data

Copy the additional task files:

```bash
cp skills/courses/phase3/lesson-13-side-gigs/seed-tasks-sidegigs/inbox/*.md ~/work/_tasks/inbox/
cp skills/courses/phase3/lesson-13-side-gigs/seed-tasks-sidegigs/pending/*.md ~/work/_tasks/pending/
```

Verify:

```bash
echo "Inbox:"
ls ~/work/_tasks/inbox/
echo ""
echo "Pending:"
ls ~/work/_tasks/pending/
```

You should see the new files alongside any existing ones.

### Step 2: Check the watchers

If your cockpit is running, switch to the inbox watcher (`Ctrl+J` → bottom-left pane or inbox window). The new inbox items should appear within 5 seconds. The pending watcher should show the new pending tasks.

Check the status bar — inbox and pending counts should have increased.

### Step 3: Triage the new inbox items

```
/triage
```

Claude should process the 2 new inbox items:
- `draft-blog-post.md` → Should route to `personal` (content creation) with appropriate tags
- `invoice-freelance-client.md` → Could go either way (work = consulting revenue, personal = side income). Check what the routing rules decide.

Verify the classifications make sense. If `/triage` routes something incorrectly, that's a signal to update `references/routing-rules.md` — the rules might not cover freelance work well.

### Step 4: Check `/next` with mixed data

```
/next
```

The pending list should now include original tasks *and* side-gigs tasks, all sorted by due date. Verify:
- Tasks from different domains intermix naturally
- Overdue tasks (if any) still show the ⚠️ marker
- The count in the summary line is correct

### Step 5: Complete a side-gigs task

```
/done invoice-freelance Generated invoice for 12 hours at $150/hr, emailed to client
```

Verify:
- File moved to `archive/`
- Log entry created with correct summary
- `/next` reflects the change
- The compound-reminder hook fires (did you update MEMORY.md?)
- The file-protection hook blocks any attempt to edit the archived invoice

### Step 6: Run `/overdue` with the expanded data

```
/overdue
```

Check that the overdue report includes both original and side-gigs tasks. The escalation tiers should still work correctly.

### Step 7: Run `/today` for the combined view

```
/today
```

The morning briefing should now reflect the larger task set — more items in each section, covering multiple domains.

### Step 8: Assess the routing rules

Review how `/triage` classified the side-gigs tasks. If any classification was wrong:

1. Open `~/.claude/skills/triage/references/routing-rules.md`
2. Add rules for the missed domain (e.g., freelance consulting → work)
3. Re-triage any misclassified items by moving them back to inbox and running `/triage` again

This iterative refinement of reference files is exactly how real skill development works — the first version handles the common cases, and edge cases teach you what rules to add.

## Checkpoint

- [ ] Side-gigs seed data added successfully (2 inbox + 3 pending)
- [ ] `/triage` correctly classifies freelance and personal project tasks
- [ ] `/next` shows all tasks (original + side-gigs) sorted by due date
- [ ] `/done` works correctly on a side-gigs task (archive, log, popup)
- [ ] `/overdue` includes both original and side-gigs overdue tasks
- [ ] `/today` briefing reflects the expanded task set
- [ ] Both hooks function correctly with the new data
- [ ] Watchers and status bar reflect accurate counts

## Design Rationale

**Why a separate lesson for integration testing?** Because building features in isolation is different from running them together with real-world data variety. Unit tests verify components; integration tests verify the system. This lesson is the integration test.

**Why not add "freelance" as a third domain?** The routing rules support `work` and `personal`. Adding a third domain would require updating every skill that filters by domain. It's a valid extension (see the Extensions guide after Lesson 15), but for now, the two-domain model is simpler and forces you to make routing decisions that test the rules.

## What's Next

Lesson 14 builds the last skill: `/session-summary`, which reads today's log entries and MEMORY.md to produce an end-of-session report. This closes the daily workflow loop: start with `/today`, work through tasks, end with `/session-summary`.

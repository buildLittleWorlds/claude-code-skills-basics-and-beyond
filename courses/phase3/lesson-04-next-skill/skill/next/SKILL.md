---
name: next
description: Shows pending tasks sorted by due date with priority and domain. Use when the user says "what's next", "next task", "show my tasks", "what should I work on", or invokes /next.
disable-model-invocation: true
---

# Show Next Tasks

Read all `.md` files in `~/work/_tasks/pending/` and display them as a sorted task list.

## Steps

1. List all `.md` files in `~/work/_tasks/pending/`
2. For each file, read the YAML frontmatter and extract: `title`, `due`, `priority`, `domain`, `tags`
3. Sort by `due` date ascending (earliest/most urgent first)
4. Display as a formatted table

## Output Format

```
📋 Pending Tasks (sorted by due date)
──────────────────────────────────────────────────────────────

  DUE         PRI   DOMAIN     TITLE
  ──────────  ────  ─────────  ──────────────────────────────
  2026-02-14  P1    work       Fix API timeout on /users endpoint
  2026-02-22  P3    personal   Plan weekend hike at Mt. Tam
  2026-02-28  P2    work       Write Q1 quarterly engineering report
  ...

──────────────────────────────────────────────────────────────
  Total: 6 tasks | Overdue: 2 | Due today: 0 | Due this week: 1
```

## Rules

- Mark overdue tasks (due date before today) with a ⚠️ prefix on the due date
- If no pending tasks exist, display: "No pending tasks. Run /triage to process your inbox."
- Do not modify any files — this is a read-only query
- Show the summary line with counts at the bottom
- Use today's actual date for overdue calculations

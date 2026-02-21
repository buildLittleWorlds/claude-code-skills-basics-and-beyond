---
name: triage
description: Processes inbox tasks by assigning domain, priority, due date, and tags, then moves them to pending. Use when the user says "triage my inbox", "process inbox", "sort my tasks", or invokes /triage.
disable-model-invocation: true
---

# Triage Inbox Tasks

Process all tasks in `~/work/_tasks/inbox/` by classifying each one and moving it to `~/work/_tasks/pending/`.

## Live Context

Current inbox contents:
!`ls ~/work/_tasks/inbox/ 2>/dev/null || echo "(empty)"`

Today's date: !`date +%Y-%m-%d`

Current pending count: !`ls ~/work/_tasks/pending/*.md 2>/dev/null | wc -l | tr -d ' '`

## Workflow

For each `.md` file in the inbox:

### Step 1: Read and understand
Read the task file. Understand the title, body context, and any hints about urgency or domain.

### Step 2: Classify domain
Assign `domain: work` or `domain: personal` based on the routing rules in the reference file `references/routing-rules.md`.

### Step 3: Assign priority
Assign `priority: P1` through `P4` based on:
- Explicit urgency cues in the task body ("urgent", "blocking", "ASAP" → P1-P2)
- Deadline mentions ("by Friday", "end of week" → P2)
- General importance and impact (default P3)
- Aspirational or "someday" tasks → P4

### Step 4: Set due date
Assign a `due: YYYY-MM-DD` date based on:
- Explicit dates mentioned in the body
- Priority-based defaults if no date mentioned:
  - P1: tomorrow
  - P2: end of this week (Friday)
  - P3: two weeks from today
  - P4: one month from today

### Step 5: Assign tags
Apply 1-3 tags using the taxonomy in `references/tagging-guide.md`.

### Step 6: Update frontmatter
Update the YAML frontmatter with all assigned fields. Change `status: inbox` to `status: pending`.

### Step 7: Move to pending
Move the file from `inbox/` to `pending/`.

### Step 8: Report
After processing all inbox items, display a summary:

```
📬 Triage Complete
─────────────────────────────────────
  Processed: 3 tasks
  → work: 2 | personal: 1
  → P1: 0 | P2: 1 | P3: 2 | P4: 0

  Moved to pending:
    • "Review onboarding docs" → work, P2, due 2026-02-28
    • "Replace kitchen light" → personal, P3, due 2026-03-07
    • "Upgrade Node.js" → work, P2, due 2026-03-07
─────────────────────────────────────
  Run /next to see your updated task list.
```

## Rules

- Process ALL inbox items in a single pass — don't leave partial work
- If an inbox item already has some metadata (e.g., domain already set), preserve it
- Never delete inbox files — always move to pending
- If the inbox is empty, display: "Inbox is empty. Nothing to triage."
- Ask for clarification only if a task is genuinely ambiguous (rare — most can be classified from context)

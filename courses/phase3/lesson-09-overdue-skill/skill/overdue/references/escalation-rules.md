# Overdue Escalation Rules

A 4-tier model for handling overdue tasks. Each tier increases the urgency of the response.

## Tier Definitions

### Tier 1: Gentle Reminder (1-3 days overdue)

**Response**: List the task in the overdue report with a green indicator.

This is normal — a task slipping by a day or two is part of real workflow. No special action needed beyond awareness.

### Tier 2: Highlighted (4-7 days overdue)

**Response**: List the task with a yellow indicator. Add a note suggesting the user either:
- Complete it this session
- Reschedule the due date to a realistic date

A week overdue means the original estimate was wrong or priorities shifted. Either fix it or adjust the plan.

### Tier 3: Decision Required (8-14 days overdue)

**Response**: List the task with an orange indicator. After the report, show a `tmux display-popup` for each Tier 3 task.

The popup must present three options:
1. **Complete now** — Do the task in this session
2. **Reschedule** — Set a new due date with a reason
3. **Drop** — Acknowledge it's not getting done and archive it

Two weeks without progress means the task needs a conscious decision, not continued deferral. The popup forces engagement.

### Tier 4: Must Address Now (15+ days overdue)

**Response**: List the task with a red indicator. Show a `tmux display-popup` that is modal (no auto-close).

At 15+ days, the task is either:
- Actually important and being chronically avoided → needs intervention
- Not important and should be dropped → archive it

The popup uses stronger language and blocks normal workflow until acknowledged.

## Priority Interaction

Escalation tiers are based purely on days overdue, not priority. A P4 task 20 days overdue is Tier 4 — the escalation model treats procrastination the same regardless of original priority.

However, the popup message should mention the original priority so the user can make an informed decision. A Tier 4 P4 task is a strong candidate for "drop."

## Edge Cases

- **Tasks with no due date**: Not overdue — skip them
- **Tasks due today**: Not overdue yet — skip them (they appear in `/today`)
- **Archived tasks**: Already done — never check archive/

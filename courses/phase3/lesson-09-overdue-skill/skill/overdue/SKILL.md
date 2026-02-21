---
name: overdue
description: Shows overdue tasks with tiered escalation based on how many days past due. Use when the user says "overdue tasks", "what's late", "check overdue", or invokes /overdue.
disable-model-invocation: true
---

# Overdue Task Escalation

Check all pending tasks for overdue status and apply tiered escalation.

## Live Context

Today's date: !`date +%Y-%m-%d`

Pending files:
!`ls ~/work/_tasks/pending/*.md 2>/dev/null || echo "(none)"`

## Instructions

1. Read all `.md` files in `~/work/_tasks/pending/`
2. For each file, parse the `due` date from YAML frontmatter
3. Calculate days overdue (today minus due date)
4. Apply the escalation tier from `references/escalation-rules.md`
5. Display results grouped by tier, most urgent first

## Output Format

```
⏰ Overdue Task Report
══════════════════════════════════════════════

🔴 TIER 4 — MUST ADDRESS NOW (15+ days overdue)
  None

🟠 TIER 3 — DECISION REQUIRED (8-14 days overdue)
  • Fix API timeout — 10 days overdue (P1, work)
    ⚡ Action required: complete, reschedule, or drop

🟡 TIER 2 — HIGHLIGHTED (4-7 days overdue)
  None

🟢 TIER 1 — GENTLE REMINDER (1-3 days overdue)
  • Plan weekend hike — 1 day overdue (P3, personal)

══════════════════════════════════════════════
  Total overdue: 2 | Tier 4: 0 | Tier 3: 1 | Tier 2: 0 | Tier 1: 1
```

## Tier 3+ Popup

For any task at Tier 3 or above, after displaying the report, show a tmux popup for each one demanding a decision:

```bash
tmux display-popup -w 60 -h 10 "echo '⚡ DECISION REQUIRED' && echo '─────────────────────────────' && echo '' && echo 'Task: <title>' && echo 'Overdue: <N> days (Tier <N>)' && echo '' && echo 'Options:' && echo '  /done <keyword> — Complete it now' && echo '  Reschedule — Update the due date' && echo '  Drop — Move to archive as abandoned' && echo '' && echo 'Press q to dismiss'"
```

This popup stays open until dismissed (no `-d` auto-close flag). The user must acknowledge it.

## Rules

- Do not modify any files — this is a read-only report
- If no tasks are overdue, display: "No overdue tasks. You're on track."
- Always show the tier summary counts at the bottom
- Tier 3+ popups are mandatory — don't skip them even if the user seems busy
- Only show popups for the most severe tier present (if Tier 4 exists, show Tier 4 popups; if only Tier 3, show Tier 3 popups)

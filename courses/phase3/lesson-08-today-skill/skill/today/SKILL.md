---
name: today
description: Generates a morning briefing showing overdue tasks, due-today items, this week's schedule, recent completions, and a suggested focus. Use when the user says "morning briefing", "what's on today", "daily overview", or invokes /today.
disable-model-invocation: true
context: fork
agent: Explore
allowed-tools: Read, Glob, Grep
---

# Morning Briefing

Generate a daily task briefing from the current state of `~/work/_tasks/`.

## Live Context

Today's date: !`date +%Y-%m-%d`
Day of week: !`date +%A`

Inbox count: !`ls ~/work/_tasks/inbox/*.md 2>/dev/null | wc -l | tr -d ' '`
Pending count: !`ls ~/work/_tasks/pending/*.md 2>/dev/null | wc -l | tr -d ' '`

Recent log files:
!`ls -t ~/work/_tasks/log/*.md 2>/dev/null | head -3`

## Instructions

Read all files in `~/work/_tasks/pending/` and `~/work/_tasks/log/` to produce this briefing:

### Section 1: Overdue
List any pending tasks where `due` is before today's date. Sort by how many days overdue (most overdue first). Show the task title, how many days overdue, and priority.

If none: "No overdue tasks."

### Section 2: Due Today
List pending tasks where `due` equals today. Show title, priority, and domain.

If none: "Nothing due today."

### Section 3: This Week
List pending tasks due within the next 7 days (excluding today and overdue). Show title, due date, priority.

If none: "Clear week ahead."

### Section 4: Recent Completions
Read the most recent 1-2 log files. List tasks completed in the last 2 days with their summaries.

If none: "No recent completions."

### Section 5: Suggested Focus
Based on the above, suggest 1-3 tasks to focus on today. Consider:
- Overdue P1/P2 tasks are highest priority
- Tasks due today come next
- Quick wins (tasks that seem small based on their description) are good for momentum

## Output Format

```
☀️ Morning Briefing — [Day], [Date]
══════════════════════════════════════════════

🔴 OVERDUE (2)
  • Fix API timeout (7 days overdue, P1, work)
  • Update team wiki (18 days overdue, P3, work)

📅 DUE TODAY (0)
  Nothing due today.

📆 THIS WEEK (1)
  • Plan weekend hike — due Sat Feb 22, P3

✅ RECENT COMPLETIONS (1)
  • Set up CI pipeline — "GitHub Actions pipeline live. PR #378 merged."

🎯 SUGGESTED FOCUS
  1. Fix API timeout — overdue P1, address this first
  2. Plan weekend hike — due Saturday, quick to finalize
  3. Start quarterly report outline — due next week, get ahead

══════════════════════════════════════════════
```

## Rules

- This is a READ-ONLY operation — do not modify any files
- Keep the briefing concise — no more than 30 lines total
- Use emoji section headers for visual scanning
- If the task system is completely empty (no pending, no log), say so and suggest running /triage

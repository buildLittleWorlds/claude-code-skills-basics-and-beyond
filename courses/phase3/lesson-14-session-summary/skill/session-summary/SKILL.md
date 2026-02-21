---
name: session-summary
description: Generates an end-of-session report summarizing tasks completed, decisions made, and notes for tomorrow. Use when the user says "session summary", "wrap up", "end of day", "what did I do today", or invokes /session-summary.
disable-model-invocation: true
context: fork
agent: Explore
allowed-tools: Read, Glob, Grep
---

# Session Summary

Generate an end-of-session report from today's task activity.

## Live Context

Today's date: !`date +%Y-%m-%d`
Session time: !`date +%H:%M`

Today's log file:
!`cat ~/work/_tasks/log/$(date +%Y-%m-%d).md 2>/dev/null || echo "(no log entries today)"`

MEMORY.md contents:
!`cat ~/MEMORY.md 2>/dev/null || echo "(no MEMORY.md found)"`

Current pending count: !`ls ~/work/_tasks/pending/*.md 2>/dev/null | wc -l | tr -d ' '`
Current archive count for today: !`find ~/work/_tasks/archive -name "*.md" -mtime 0 2>/dev/null | wc -l | tr -d ' '`

## Instructions

Read the log file and MEMORY.md to produce a session summary.

### Section 1: Tasks Completed
List every task that was completed today (from the log file). Include title and summary for each.

### Section 2: Tasks Added
If any tasks were triaged today (moved from inbox to pending), list them with their assigned metadata.

### Section 3: Decisions Made
Extract any decisions or notable context from MEMORY.md that was written today. Look for bullet points, action items, or context notes.

### Section 4: Current State
- Pending task count
- Overdue task count (read pending files, compare due dates to today)
- Inbox count

### Section 5: Notes for Tomorrow
Based on what was done and what remains:
- What should be the first priority tomorrow?
- Are any tasks becoming overdue soon?
- Any blockers or dependencies to resolve?

## Output Format

```
📝 Session Summary — [Date] at [Time]
══════════════════════════════════════════════

✅ COMPLETED (2)
  • Fix API timeout — "Reduced page size to 100, added cursor pagination"
  • Plan weekend hike — "Called the group, confirmed for Saturday"

📬 TRIAGED (3)
  • "Draft blog post" → personal, P3, due Mar 7
  • "Invoice freelance client" → work, P2, due Feb 28
  • "Upgrade Node.js" → work, P2, due Mar 15

💡 DECISIONS
  • Chose cursor-based pagination over offset pagination for scale
  • Deferred Node.js upgrade until after quarterly report

📊 CURRENT STATE
  Pending: 8 | Overdue: 1 | Inbox: 0

🔮 TOMORROW
  1. Start quarterly report outline (due Feb 28, 7 days away)
  2. Address wiki update (18 days overdue — consider dropping)
  3. Renew domain before March 1

══════════════════════════════════════════════
```

## Rules

- This is a READ-ONLY operation — do not modify any files
- If no tasks were completed today, say so (don't invent activity)
- If MEMORY.md is empty or absent, note that and suggest updating it
- Keep the summary under 40 lines — concise is better than comprehensive
- The "Notes for Tomorrow" section should be actionable, not vague

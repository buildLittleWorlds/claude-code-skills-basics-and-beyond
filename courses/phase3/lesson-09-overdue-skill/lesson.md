# Lesson 9: `/overdue` Escalation Rules
**Phase**: 3 — Task Workflow Mastery | **Estimated time**: 25 min

## Prerequisites
- Completed **Lessons 4-8** (all skills + startup script)
- Completed **Phase 2 Course 3** (reference files)
- Pending tasks in `~/work/_tasks/pending/` with at least 1-2 past-due dates
- Cockpit running (or Claude Code active in any terminal)

## What You'll Learn

`/today` mentions overdue tasks in its briefing, but it treats a 1-day-overdue task the same as a 20-day-overdue task. Real workflow needs *escalation* — the longer you ignore something, the louder the system should get about it.

`/overdue` implements a 4-tier escalation model:

| Tier | Days Overdue | Response |
|------|-------------|----------|
| 1 | 1-3 | Gentle reminder (listed in report) |
| 2 | 4-7 | Highlighted with suggestion to complete or reschedule |
| 3 | 8-14 | `display-popup` demanding a decision |
| 4 | 15+ | Modal popup — blocks workflow until acknowledged |

This is the first skill where tmux and skills interact during execution: the popup isn't just decorative (like `/done`'s 3-second confirmation), it's *functional* — it forces you to make a decision about chronically deferred tasks.

### The Escalation Philosophy

The key insight: **the escalation is time-based, not priority-based**. A P4 task that's 20 days overdue gets the same Tier 4 treatment as a P1 task that's 20 days overdue. Why? Because chronic deferral is the problem being addressed, not task importance. If a task isn't important enough to do, it should be dropped — not left in pending forever.

This is encoded in the reference file `references/escalation-rules.md`, which the skill reads at execution time.

## Exercise

### Step 1: Check your overdue situation

First, see what's overdue in your seed data:

```bash
echo "Today: $(date +%Y-%m-%d)"
echo "---"
for f in ~/work/_tasks/pending/*.md; do
    [ -f "$f" ] || continue
    due=$(grep "^due:" "$f" | sed 's/due: //')
    title=$(grep "^title:" "$f" | sed 's/title: //')
    echo "$due  $title"
done | sort
```

Tasks with due dates before today are overdue. With the original seed data, `fix-api-timeout` (Feb 14) and `update-team-wiki` (Feb 3) should be overdue — one in Tier 3 range, one in Tier 4 range (depending on today's date).

### Step 2: Read the skill and reference

```bash
cat skills/courses/phase3/lesson-09-overdue-skill/skill/overdue/SKILL.md
cat skills/courses/phase3/lesson-09-overdue-skill/skill/overdue/references/escalation-rules.md
```

Key things to notice in the SKILL.md:
- Dynamic context injects today's date and the pending file listing
- The output format uses color-coded tier indicators (🔴🟠🟡🟢)
- Tier 3+ triggers a `display-popup` — a real tmux command, not just formatted text
- The popup is modal (no `-d` auto-close) — you must dismiss it

Key things in the escalation rules:
- Tiers are purely time-based, not priority-based
- Each tier has specific response actions
- Tier 3 offers three options: complete, reschedule, or drop
- Edge cases handled: no due date, due today, already archived

### Step 3: Install the skill

```bash
mkdir -p ~/.claude/skills/overdue/references
cp skills/courses/phase3/lesson-09-overdue-skill/skill/overdue/SKILL.md ~/.claude/skills/overdue/SKILL.md
cp skills/courses/phase3/lesson-09-overdue-skill/skill/overdue/references/escalation-rules.md ~/.claude/skills/overdue/references/escalation-rules.md
```

### Step 4: Run the overdue check

```
/overdue
```

Claude should:
1. Read all pending tasks
2. Calculate days overdue for each
3. Group by tier
4. Display the formatted report
5. For any Tier 3+ tasks, show a `display-popup` demanding a decision

### Step 5: Handle the popup

If you have Tier 3+ tasks, a popup should appear. Read the options:
- **Complete now**: You could run `/done <keyword>` after dismissing
- **Reschedule**: Tell Claude to update the due date
- **Drop**: Tell Claude to archive it as abandoned

Press `q` (or `Ctrl+c`) to dismiss the popup. Then take action on the task — the popup's purpose is to force the decision, not to execute it.

### Step 6: Test with no overdue tasks

If you want to see the clean state, temporarily adjust due dates:

```bash
# Back up a file
cp ~/work/_tasks/pending/fix-api-timeout.md /tmp/

# Edit the due date to the future (if it exists)
# Then run /overdue — should show "No overdue tasks. You're on track."

# Restore
cp /tmp/fix-api-timeout.md ~/work/_tasks/pending/ 2>/dev/null
```

Or simply complete the overdue tasks with `/done` and then run `/overdue`.

### Step 7: Test popup manually (optional)

To experience the popup independently:

```bash
# Modal popup (stays until dismissed)
tmux display-popup -w 60 -h 10 "echo '⚡ DECISION REQUIRED'; echo '─────────────────────────────'; echo ''; echo 'Task: Fix API timeout'; echo 'Overdue: 7 days (Tier 3)'; echo ''; echo 'Options:'; echo '  /done fix-api — Complete it now'; echo '  Reschedule — Update the due date'; echo '  Drop — Archive as abandoned'; echo ''; echo 'Press q to dismiss'; read"
```

Notice this popup blocks input to the pane behind it until you dismiss it. That's the point — Tier 3+ overdue tasks demand attention.

Compare with an auto-close popup:

```bash
tmux display-popup -d 3 -w 40 -h 4 "echo 'This closes in 3 seconds'"
```

The difference in behavior is the difference between a gentle reminder (Tier 1-2) and a forced decision (Tier 3-4).

## Checkpoint

- [ ] `/overdue` displays a tiered report of overdue tasks
- [ ] Tasks are correctly assigned to tiers based on days overdue
- [ ] Tier 3+ tasks trigger a `display-popup` with decision options
- [ ] The popup is modal (doesn't auto-close)
- [ ] No files are modified by `/overdue` (it's read-only)
- [ ] "No overdue tasks" message appears when all tasks are current
- [ ] The tier summary counts at the bottom are accurate

## Design Rationale

**Why reference files instead of inline escalation rules?** The escalation model is a policy that you might want to tune. Maybe Tier 3 should start at 10 days instead of 8. Maybe you want to add a Tier 5. With rules in a reference file, you edit one file and the skill behavior changes. The SKILL.md stays focused on the workflow, not the policy.

**Why not auto-reschedule or auto-drop?** Automation should inform and prompt, not decide. A 20-day-overdue task might be worth doing (you were blocked by a dependency that just cleared) or worth dropping (priorities shifted). Only you know which. The popup forces the decision; you make it.

**Why time-based instead of priority-based tiers?** Priority is a planning input set during triage. Overdue duration is a behavioral signal — it tells you what you're actually avoiding. A P3 task you've been ignoring for 3 weeks is a bigger problem than a P1 task that just went overdue yesterday. The escalation model addresses the avoidance pattern, not the original importance estimate.

## Phase 2 Callback

This lesson builds directly on:
- **Course 3** (Full Skill Anatomy): `references/escalation-rules.md` is a classic reference file — domain knowledge that the skill reads at execution time. Same pattern as the `code-style.md` reference from Course 3.
- **Course 5** (Dynamic Context): `!`command`` injects today's date and the pending file listing. Same preprocessing pattern as `/triage`.
- **Lesson 5** (display-popup): `/done` introduced `display-popup` as a 3-second confirmation. `/overdue` uses the same mechanism but with modal behavior (no auto-close) for a different UX purpose — forcing engagement instead of confirming an action.

## What's Next

You've now built all 5 core skills: `/next`, `/done`, `/triage`, `/today`, `/overdue`. And you have a startup script that launches the cockpit.

**Challenge Lab 1** is your first unguided exercise: build a `/focus` skill that picks the single most important task to work on right now. No walkthrough — just acceptance criteria. Use everything you've learned in Lessons 4-9.

After the challenge lab, Lesson 10 begins the hooks phase — adding system-level guardrails that enforce behavior automatically, starting with a Stop hook that reminds you to update MEMORY.md after completing tasks.

# Challenge Lab 1: Build a `/focus` Skill

**Difficulty**: Intermediate | **Estimated time**: 30-45 min

## The Challenge

Build a `/focus` skill that picks the **single most important task** to work on right now and presents it in a `tmux display-popup`.

No walkthrough. No step-by-step instructions. Use what you learned in Lessons 4-9 to design and build this yourself.

## Acceptance Criteria

Your `/focus` skill must:

1. **Read all pending tasks** from `~/work/_tasks/pending/`
2. **Score each task** using a weighted algorithm that considers:
   - Days overdue (strongest signal — overdue tasks score highest)
   - Priority level (P1 > P2 > P3 > P4)
   - Due date proximity (sooner = higher score)
   - Time since last touched (older `created` date = stale, slight score bump)
3. **Select the top task** — the one with the highest composite score
4. **Present it in a `display-popup`** with:
   - The task title
   - Why it was chosen (e.g., "7 days overdue, P1")
   - The task body (first 3 lines for context)
   - A suggested next action
5. **Handle edge cases**:
   - No pending tasks → "Nothing to focus on. Your inbox might need /triage."
   - All tasks have equal scores → Pick the one with the earliest due date
6. **Be read-only** — do not modify any task files

## Design Questions to Consider

Before writing SKILL.md, think through these decisions:

- **Inline or forked?** Is the output small enough for inline? Or does the scoring analysis justify a fork?
- **`disable-model-invocation`?** Should Claude auto-trigger this, or is it slash-command only?
- **Dynamic context?** Would `!`command`` preprocessing help? What data would you inject?
- **Reference file?** Should the scoring weights be in a reference file (tunable) or inline in the SKILL.md?
- **Popup behavior?** Auto-close after N seconds, or modal until dismissed?

## Scoring Suggestion

Here's one possible scoring formula (you can design your own):

```
score = (days_overdue * 10) + (priority_weight) + (due_proximity) + (staleness_bonus)

where:
  priority_weight: P1=40, P2=30, P3=20, P4=10
  due_proximity: max(0, 14 - days_until_due) * 3
  staleness_bonus: min(10, days_since_created / 7)
```

This weights overdue status most heavily, then priority, then proximity, with a small bonus for older tasks. You're free to change this entirely.

## Verification Checklist

After building your skill, verify:

- [ ] `/focus` presents a single task in a popup
- [ ] The chosen task is defensible (an overdue P1 should beat a future P4)
- [ ] The popup shows the task title, reasoning, context, and next action
- [ ] Empty pending directory is handled gracefully
- [ ] The skill appears in `/help`
- [ ] No files are modified by running `/focus`

## Hints (only if stuck)

<details>
<summary>Hint 1: Structure</summary>

Look at how `/next` reads pending files. Your skill needs the same file-reading pattern, plus a scoring step before display.

</details>

<details>
<summary>Hint 2: Popup command</summary>

```bash
tmux display-popup -w 60 -h 12 "echo '🎯 FOCUS: <title>' && echo '...' "
```

Use `-d 0` (or omit `-d`) for modal, or `-d 10` for a 10-second display.

</details>

<details>
<summary>Hint 3: Keeping it simple</summary>

You don't have to implement the exact scoring formula above. A simpler approach: sort by overdue first, then by priority, then by due date. The top result is your focus task. The scoring formula is a refinement, not a requirement.

</details>

## What You're Practicing

- Designing a SKILL.md from scratch (no template provided)
- Making design decisions (inline vs fork, dynamic context vs not)
- Implementing a non-trivial algorithm in a skill prompt
- Testing and iterating without a walkthrough to follow
- Using `display-popup` for a UX purpose you defined

This is the closest thing to real skill development — you have a requirement, and you build the solution.

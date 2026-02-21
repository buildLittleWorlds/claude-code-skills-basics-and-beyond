# Challenge Lab 3: Build a `/weekly-review`

**Difficulty**: Advanced | **Estimated time**: 45-60 min

## The Challenge

Build a `/weekly-review` skill that synthesizes all log entries and session summaries from the past 7 days into a comprehensive weekly report.

This is the most complex skill in the curriculum. It combines everything: dynamic context, forked execution, reference files, date arithmetic, and multi-file analysis.

## Acceptance Criteria

Your `/weekly-review` skill must:

1. **Read all log files from the past 7 days** — `~/work/_tasks/log/YYYY-MM-DD.md` for each of the last 7 dates
2. **Produce a weekly report** with these sections:

### Completion Summary
- Total tasks completed this week
- Breakdown by domain (work vs personal)
- Average tasks per day

### Domain Analysis
- Which domain consumed the most completions?
- Which domain has the most pending tasks remaining?
- Any domain imbalance? (e.g., all work, no personal)

### Overdue Patterns
- Were any tasks completed that were overdue? How many days late on average?
- Are the same types of tasks consistently overdue? (tags, domains)
- What's the current overdue count?

### Deferral Analysis
- Which tasks have been in pending the longest without action?
- Any tasks that were rescheduled (if you can detect this from log entries)?
- Candidates for dropping (old + low priority + no recent activity)

### Weekly Insights
- What patterns emerge? (e.g., "You completed 5 work tasks but 0 personal tasks")
- What's trending? (Increasing overdue count? Decreasing inbox throughput?)
- Specific, actionable suggestions for next week

3. **Include a reference file** with your review methodology — the criteria and weights you use for analysis
4. **Handle edge cases**: weeks with no activity, partial weeks, missing log files
5. **Run in a forked context** (the analysis is read-heavy and produces verbose output)

## Design Questions

- How do you iterate over the last 7 dates in bash for the `!`command`` preprocessing?
- Should you inject all 7 log files via dynamic context, or let the agent read them via tools?
- What model should the agent use? (Haiku for speed? Sonnet for deeper analysis?)
- How do you detect "deferral patterns" from the available data?

## Verification Checklist

- [ ] `/weekly-review` produces a multi-section report
- [ ] Completion counts are accurate against log files
- [ ] Domain breakdown is correct
- [ ] Overdue patterns are identified (or noted as absent)
- [ ] At least 2 actionable suggestions are provided
- [ ] Reference file exists with review methodology
- [ ] Handles weeks with missing log files gracefully
- [ ] Runs in a forked agent (doesn't pollute main context)

## Hints (only if stuck)

<details>
<summary>Hint 1: Date iteration in bash</summary>

To list the last 7 dates:
```bash
for i in $(seq 0 6); do date -v-${i}d +%Y-%m-%d; done
```

On Linux:
```bash
for i in $(seq 0 6); do date -d "$i days ago" +%Y-%m-%d; done
```

You can use this in `!`command`` to inject which dates to check.

</details>

<details>
<summary>Hint 2: Dynamic context strategy</summary>

Inject the date list and file existence check via `!`command``:
```
Dates to review:
!`for i in $(seq 0 6); do d=$(date -v-${i}d +%Y-%m-%d); [ -f ~/work/_tasks/log/$d.md ] && echo "$d ✓" || echo "$d (no data)"; done`
```

Let the forked agent read the actual file contents — they could be large.

</details>

<details>
<summary>Hint 3: Deferral detection</summary>

You can't directly detect rescheduling (the frontmatter gets overwritten). But you *can* detect stale tasks: read `created` dates in pending files, compare to today, and flag any task that's been in pending for 14+ days without completion. That's a proxy for chronic deferral.

</details>

## What You're Practicing

- Complex multi-file analysis in a forked agent
- Date arithmetic in bash preprocessing
- Reference file design (review methodology)
- Synthesizing patterns from raw data
- Building a skill that produces genuine insights, not just data summaries
- The full build cycle at the highest complexity level in the curriculum

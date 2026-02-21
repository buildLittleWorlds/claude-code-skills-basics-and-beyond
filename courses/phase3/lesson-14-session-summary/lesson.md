# Lesson 14: `/session-summary`
**Phase**: 3 — Task Workflow Mastery | **Estimated time**: 20 min

## Prerequisites
- Completed **Lessons 8, 10, 13** (`/today`, compound-reminder hook, side-gigs integration)
- At least one task completed with `/done` today (a log entry exists for today)
- MEMORY.md updated at least once (the compound-reminder hook should have ensured this)

## What You'll Learn

`/today` opens your day. `/session-summary` closes it. It reads today's log entries, MEMORY.md, and the current state of your task directories to produce a report: what you completed, what was triaged, what decisions you made, and what to focus on tomorrow.

Like `/today`, this skill uses `context: fork` with an Explore agent. The reasoning is the same: the summary involves reading multiple files and producing a formatted report. Forking keeps the intermediate work (reading log files, counting tasks, comparing dates) out of your main conversation context.

### The Daily Workflow Loop

```
Morning:  tasks → /today → see briefing
During:   /next → work → /done → /triage (as needed)
Evening:  /session-summary → update MEMORY.md → done
```

`/session-summary` is the bookend. It captures what happened so that tomorrow's `/today` briefing has accurate recent-completion data and your MEMORY.md has context for the next session.

## Exercise

### Step 1: Ensure you have session data

Check that today's log file exists:

```bash
cat ~/work/_tasks/log/$(date +%Y-%m-%d).md
```

If it's empty or doesn't exist, complete a task first:

```
/done renew-professional Renewed ACM membership, auto-pay set up
```

Also check MEMORY.md:

```bash
cat ~/MEMORY.md
```

If it doesn't exist or is stale, add some notes:

```bash
cat >> ~/MEMORY.md << 'EOF'

## Session Notes
- Completed API timeout fix — chose cursor pagination for scale
- Side-gigs data integrated, routing rules working
- Conference talk due Mar 10, need to start slides
EOF
```

### Step 2: Read and install the skill

```bash
cat skills/courses/phase3/lesson-14-session-summary/skill/session-summary/SKILL.md
```

Notice:
- Heavy use of `!`command`` — injects today's log file, MEMORY.md contents, counts
- Five sections matching the `/today` structure (they're bookends)
- `context: fork` + `agent: Explore` — same pattern as `/today`
- Rules: read-only, concise, actionable tomorrow section

Install:

```bash
mkdir -p ~/.claude/skills/session-summary
cp skills/courses/phase3/lesson-14-session-summary/skill/session-summary/SKILL.md ~/.claude/skills/session-summary/SKILL.md
```

### Step 3: Run the summary

```
/session-summary
```

The Explore agent should produce a report covering:
1. Tasks completed today (from log file)
2. Tasks triaged (if you ran `/triage` today)
3. Decisions from MEMORY.md
4. Current state counts
5. Priority suggestions for tomorrow

### Step 4: Verify accuracy

Cross-reference each section:
- **Completed**: Match against `~/work/_tasks/log/$(date +%Y-%m-%d).md`
- **Current state**: Match against `ls ~/work/_tasks/pending/ | wc -l`
- **Tomorrow**: Are the suggestions actionable and based on actual data?

### Step 5: Test with no session data

To see the empty-state behavior, temporarily rename today's log file:

```bash
mv ~/work/_tasks/log/$(date +%Y-%m-%d).md /tmp/today-log-backup.md 2>/dev/null
```

Run `/session-summary` again. It should note that no tasks were completed today and suggest looking at the pending queue.

Restore:

```bash
mv /tmp/today-log-backup.md ~/work/_tasks/log/$(date +%Y-%m-%d).md 2>/dev/null
```

## Checkpoint

- [ ] `/session-summary` produces a multi-section end-of-session report
- [ ] Completed tasks section matches today's log entries
- [ ] Current state counts are accurate
- [ ] "Notes for Tomorrow" section provides actionable suggestions
- [ ] Handles missing log file or MEMORY.md gracefully
- [ ] Runs in a forked Explore agent (clean context)

## Design Rationale

**Why inject MEMORY.md via `!`command`` instead of letting the agent read it?** MEMORY.md is usually short (a few dozen lines) and is critical context for the "Decisions Made" section. Injecting it ensures the agent always sees it, even if it doesn't think to look for it. Task files in pending/ are left for the agent to read via tools because there could be dozens and the agent needs to selectively scan them.

**Why not combine `/today` and `/session-summary`?** They serve different purposes and optimal timing. `/today` is forward-looking (what should I do?). `/session-summary` is backward-looking (what did I do?). Combining them would produce a longer, unfocused output. Separate skills keep each one concise and purpose-built.

## Phase 2 Callback

This lesson builds directly on:
- **Course 5** (Advanced Features): `context: fork`, `agent: Explore`, `allowed-tools` — identical pattern to `/today`, applied to end-of-session instead of start-of-session.
- **Course 5** (Dynamic Context): Heavy `!`command`` usage to inject log files, MEMORY.md, and counts.
- **Lesson 10** (Compound Reminder): The hook ensures MEMORY.md is updated, which `/session-summary` then reads. The hook and skill work together as a system.

## What's Next

All 6 skills are built, both hooks are installed, and the cockpit is operational. Lesson 15 is the full integration test: run through the complete daily rhythm end-to-end and verify every piece works together. After that, Challenge Lab 3 asks you to build a `/weekly-review` that synthesizes an entire week's worth of sessions.

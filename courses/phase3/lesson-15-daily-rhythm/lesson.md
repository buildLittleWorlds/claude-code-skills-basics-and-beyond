# Lesson 15: The Full Daily Rhythm
**Phase**: 3 — Task Workflow Mastery | **Estimated time**: 30 min

## Prerequisites
- Completed **Lessons 1-14** (all skills, hooks, cockpit, side-gigs integration)
- All 6 skills installed: `/next`, `/done`, `/triage`, `/today`, `/overdue`, `/session-summary`
- Both hooks installed: compound-reminder, file-protection
- Cockpit startup script installed at `~/bin/tasks`

## What You'll Learn

This is the integration test. No new concepts, no new artifacts. Just the complete daily rhythm, end-to-end, verified by a test script.

The daily rhythm is the entire point of Phase 3:

```
┌─────────────────────────────────────────────┐
│            THE DAILY RHYTHM                 │
│                                             │
│  Morning:                                   │
│    $ tasks                   ← launch       │
│    → /today auto-runs        ← briefing     │
│                                             │
│  Work session:                              │
│    /triage                   ← process inbox│
│    /next                     ← pick task    │
│    (do the work)             ← actual work  │
│    /done <task> <summary>    ← complete     │
│    (repeat)                                 │
│                                             │
│  Periodic:                                  │
│    /overdue                  ← check health │
│                                             │
│  End of day:                                │
│    Update ~/MEMORY.md        ← reflect      │
│    /session-summary          ← wrap up      │
│    Ctrl+J d (detach)         ← leave        │
│                                             │
│  Hooks (automatic):                         │
│    compound-reminder ← nag about MEMORY.md  │
│    protect-task-files ← guard log/archive   │
│                                             │
│  Always visible:                            │
│    Status bar: 📬 inbox | 📋 pending | ⚠️   │
│    Watchers: inbox + pending (bottom panes) │
└─────────────────────────────────────────────┘
```

## Exercise

### Step 1: Run the pre-flight check

The integration test script checks that everything is installed before you start:

```bash
bash skills/courses/phase3/lesson-15-daily-rhythm/daily-rhythm-test.sh
```

Phase 1 of the script verifies:
- All 4 task directories exist
- All 6 skills are installed
- Both hooks are installed
- The startup script is in place

Fix any failing checks before proceeding.

### Step 2: Launch the cockpit

The script will prompt you to launch the cockpit. From a terminal outside tmux:

```bash
tasks
```

Wait for Claude to initialize and the `/today` briefing to appear automatically.

### Step 3: Run the full cycle

Follow the script's instructions in order:

1. **`/triage`** — Process the test inbox item the script created. It should get domain, priority, due date, and tags assigned, then move to pending.

2. **`/next`** — See the updated pending list. The test task should appear among your other tasks.

3. **`/overdue`** — Check for any escalated tasks. Handle any Tier 3+ popups.

4. **`/done integration-test Completed the daily rhythm test`** — Complete the test task. Watch for:
   - Confirmation popup (display-popup)
   - File moved to archive
   - Log entry created
   - Compound-reminder hook fires (reminds about MEMORY.md)

5. **Update MEMORY.md** — Write a few lines about what you did:
   ```bash
   echo "## $(date +%Y-%m-%d) — Daily rhythm integration test" >> ~/MEMORY.md
   echo "- Ran full cycle: triage → next → done" >> ~/MEMORY.md
   echo "- All skills working with side-gigs data" >> ~/MEMORY.md
   ```

6. **`/session-summary`** — Generate the end-of-session report. It should show the completed test task and your MEMORY.md notes.

### Step 4: Verify the results

Return to the terminal where the test script is waiting (press Enter). It will verify:
- Test task removed from inbox
- Test task removed from pending
- Test task in archive with `status: done` and `domain` assigned
- Today's log file contains the test task entry
- MEMORY.md was updated today

### Step 5: Review the results

If all checks pass: the daily rhythm works end-to-end. Every skill, hook, and tmux integration functions as designed.

If checks fail: the script tells you which ones. Common issues:
- **Task still in inbox**: `/triage` didn't run or didn't process this task
- **Task still in pending**: `/done` didn't complete or the keyword didn't match
- **No log entry**: `/done` ran but skipped the log step
- **MEMORY.md not updated**: The compound-reminder hook should have prompted you

## The Quick Reference Card

Once the integration test passes, here's the daily workflow you can run every day:

| Time | Action | Skill |
|------|--------|-------|
| Start | Launch cockpit | `$ tasks` |
| Start | Read briefing | `/today` (auto) |
| Morning | Process new tasks | `/triage` |
| During | Check queue | `/next` |
| During | Complete task | `/done <keyword> <summary>` |
| Periodic | Check overdue | `/overdue` |
| End | Write notes | Edit `~/MEMORY.md` |
| End | Session report | `/session-summary` |
| End | Leave | `Ctrl+J d` |

## Checkpoint

- [ ] Integration test script passes all pre-flight checks
- [ ] Full cycle works: triage → next → (work) → done → summary
- [ ] Watchers update in real-time as tasks move between directories
- [ ] Status bar reflects current counts
- [ ] Compound-reminder hook fires after completing a task
- [ ] File-protection hook blocks unauthorized edits
- [ ] Integration test script passes all verification checks

## Design Rationale

**Why a semi-automated test instead of fully automated?** The skills require Claude to run — you can't simulate Claude's output in a bash script. The test automates what it can (pre-flight checks, state verification) and guides you through what it can't (running skills interactively). This is realistic: in production, you'd test skills by running them, not by mocking them.

## What's Next

**Challenge Lab 3** is the final unguided exercise: build a `/weekly-review` skill that synthesizes a full week of log files and session summaries. It's the most complex skill in the curriculum.

After the challenge lab, Phase 3 is complete. The extension guides in the `extensions/` directory suggest directions for going further: MCP integration, multi-model optimization, and calendar sync.

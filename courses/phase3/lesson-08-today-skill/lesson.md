# Lesson 8: `/today` Morning Briefing
**Phase**: 3 — Task Workflow Mastery | **Estimated time**: 25 min

## Prerequisites
- Completed **Lesson 7** (startup script, cockpit running)
- Completed **Phase 2 Course 5** (`context: fork`, `agent: Explore`, `allowed-tools`)
- Pending tasks in `~/work/_tasks/pending/` (ideally some overdue)
- Log files in `~/work/_tasks/log/` (from previous `/done` operations)

## What You'll Learn

When you launch the cockpit with `tasks`, the first thing you want is a snapshot of your day: what's overdue, what's due today, what's coming this week, and what you recently completed. That's the `/today` morning briefing.

This skill introduces the most important Phase 2 feature for the cockpit: **forked subagent execution**.

### Why Fork?

Think about what `/today` does: it reads every pending task, every recent log file, computes date comparisons, and generates a multi-section report. That involves reading 10+ files and producing 20-30 lines of analysis. If this ran inline (like `/next`), all of that intermediate work — file reads, date calculations, draft output — would consume your main conversation context.

With `context: fork`, the work happens in an isolated Explore agent. The agent reads the files, produces the briefing, and returns only the final result to your main conversation. Your context stays clean for the actual work you do after reading the briefing.

### The Fork Tradeoff

| Aspect | Inline (`/next`) | Forked (`/today`) |
|--------|------------------|-------------------|
| Context cost | All intermediate steps visible | Only final result returned |
| Speed | Faster (no agent startup) | Slightly slower (agent initialization) |
| Follow-up | Can say "tell me more about task 2" | Agent is gone — can't follow up |
| Tool access | Full tool set | Only `allowed-tools` |
| Best for | Small queries, interactive work | Reports, analysis, read-heavy tasks |

The rule of thumb from Phase 2 Course 5: **fork when the task is self-contained and its intermediate output would clutter your main conversation.**

### The Agent and Tool Choices

```yaml
context: fork
agent: Explore
allowed-tools: Read, Glob, Grep
```

- **`agent: Explore`**: Uses Haiku (fast, cheap). The briefing is read-only — no file modifications needed. Explore is the right agent for "look at things and report."
- **`allowed-tools: Read, Glob, Grep`**: Explicitly restricts to read-only tools. Even though Explore is already read-only, specifying allowed tools makes the constraint visible in the SKILL.md.

## Exercise

### Step 1: Read the SKILL.md

```bash
cat skills/courses/phase3/lesson-08-today-skill/skill/today/SKILL.md
```

Notice:
- **Frontmatter**: `context: fork`, `agent: Explore`, `allowed-tools: Read, Glob, Grep`
- **Dynamic context**: Date, day of week, inbox count, pending count, recent log file names
- **Five sections**: Overdue, Due Today, This Week, Recent Completions, Suggested Focus
- **Output format**: Emoji-headed sections for visual scanning
- **Rules**: Read-only, concise (under 30 lines), empty-state handling

### Step 2: Install the skill

```bash
mkdir -p ~/.claude/skills/today
cp skills/courses/phase3/lesson-08-today-skill/skill/today/SKILL.md ~/.claude/skills/today/SKILL.md
```

### Step 3: Test manually

With Claude running in your cockpit HQ:

```
/today
```

Claude should spawn an Explore agent that reads your task files and returns a formatted briefing. You'll notice:
1. A brief pause while the agent initializes
2. The briefing appears as a single block of formatted output
3. Your conversation context is clean — no intermediate file-read messages

### Step 4: Check the briefing accuracy

Verify each section against your actual data:
- **Overdue**: Cross-reference with `ls ~/work/_tasks/pending/` — check due dates
- **Due Today**: Any task with `due: 2026-02-21` (or today's date)?
- **Recent Completions**: Match against `cat ~/work/_tasks/log/*.md`
- **Suggested Focus**: Does it prioritize overdue P1/P2 items?

### Step 5: Test the cockpit auto-briefing

Kill your existing session and relaunch:

```bash
tmux kill-session -t tasks
tasks
```

Watch the HQ left pane. After Claude initializes (~4 seconds), the startup script sends `/today` automatically. You should see the morning briefing appear without any manual input.

This is the daily experience: type `tasks`, get your briefing, start working.

### Step 6: Compare inline vs forked (optional)

To feel the difference between inline and forked execution, try asking Claude the same question directly (without the skill):

```
Read all my pending tasks in ~/work/_tasks/pending/ and tell me which ones are overdue and what I should focus on today.
```

Notice how much more context this consumes — you'll see individual file reads, intermediate reasoning, and the response is longer and less structured. The `/today` skill produces a cleaner result and keeps your context budget intact for real work.

## Checkpoint

- [ ] `/today` produces a multi-section morning briefing
- [ ] The briefing runs in a forked Explore agent (you can tell by the brief pause and clean output)
- [ ] Overdue, due-today, and this-week sections are accurate against your data
- [ ] Recent completions pulls from log files
- [ ] Suggested focus prioritizes overdue and high-priority items
- [ ] The cockpit startup script auto-sends `/today` after Claude initializes

## Design Rationale

**Why Explore agent instead of general-purpose?** Explore uses Haiku — faster and cheaper. The briefing is pure analysis: read files, compare dates, format output. No file modifications, no bash commands, no complex reasoning. Haiku handles this well, and the cost savings matter if you're running `/today` every morning.

**Why not cache the briefing?** The briefing should be fresh every time. Task due dates change, new tasks get triaged, tasks get completed. A cached briefing would quickly become stale. The forked Explore agent is fast enough (2-5 seconds) that caching isn't worth the complexity.

**Why dynamic context for counts but not file contents?** The `!`command`` preprocessing injects inbox/pending counts because they're one-line values that help Claude understand scale. But the actual file contents are left for the Explore agent to read — injecting all files via `!`command`` would bloat the prompt and risk truncation. This is the right split: metadata via preprocessing, content via agent tools.

## Phase 2 Callback

This lesson builds directly on:
- **Course 5** (Advanced Features): `context: fork` + `agent: Explore` + `allowed-tools` — this is the exact pattern from the `investigate-issue` example, applied to task data instead of GitHub issues.
- **Course 5** (Dynamic Context): `!`command`` preprocessing provides live data (date, counts, file listings) to the forked agent's prompt.
- **Course 1** (Progressive Disclosure): The briefing skill demonstrates Level 2 content loading — Claude loads the full SKILL.md body when `/today` is invoked, then the Explore agent reads Level 3 content (task files) as needed.

## What's Next

`/today` shows you what's overdue, but it treats all overdue tasks equally. Lesson 9 builds `/overdue` — a skill with a 4-tier escalation model that applies increasingly urgent treatment based on how far past due a task is. Light overdue? Gentle reminder. Two weeks overdue? A blocking popup that demands a decision.

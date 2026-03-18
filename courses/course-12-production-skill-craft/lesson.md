# Course 12: Production Skill Craft -- Gotchas, Setup, Memory & Measurement
**Level**: Intermediate | **Estimated time**: 45 min

## Prerequisites
- Completed **Course 1: Your First Skill in Five Minutes** (skill folder basics, YAML frontmatter, the `daily-standup` skill)
- Completed **Course 2: Crafting Descriptions and Trigger Phrases** (description formula, trigger phrases, under/over-triggering)
- Completed **Course 3: Full Skill Anatomy** (scripts, references, assets, progressive disclosure L3)
- Completed **Course 4: Testing, Iteration, and the Feedback Loop** (test plans, iteration rounds, performance comparison)
- You have the `daily-standup` skill from Course 1 installed
- Claude Code installed and working (`claude` command available)

## Concepts

### Don't State the Obvious

The single biggest mistake in production skills is telling Claude things it already knows. Claude is good at a lot of things out of the box -- writing clean code, following standard formats, being polite. When your skill restates these defaults, you waste tokens and dilute the instructions that actually matter.

The audit technique is simple: **remove a line, then test whether behavior changes.** If removing an instruction produces identical output, that instruction was dead weight.

Consider this example from a code review skill:

```markdown
## Instructions
- Read the code carefully before reviewing        ← Claude does this anyway
- Check for syntax errors                          ← Claude does this anyway
- Look for security vulnerabilities                ← Claude does this anyway
- Ensure all database queries use parameterized    ← THIS changes behavior
  statements, never string concatenation
- Flag any use of eval() or exec()                 ← THIS changes behavior
- Check that error messages don't leak stack traces ← THIS changes behavior
```

The first three lines are noise. Claude will read code carefully, check syntax, and look for security issues without being told. The last three lines push Claude to check specific things it might otherwise skip.

**The removal test:**

1. Pick a line in your skill
2. Comment it out or delete it
3. Run the same prompt 3 times with and without the line
4. If the outputs are substantively the same, the line is dead weight
5. Remove it permanently

A lean skill that contains only non-obvious instructions will outperform a verbose skill that buries the important parts in boilerplate.

### Build a Gotchas Section

Every skill develops failure modes over time. A user reports that the standup generator lists the same item twice. Another finds it crashes when there's no git history. These aren't bugs in the skill -- they're patterns that Claude needs explicit guidance to avoid.

A **gotchas file** is a first-class pattern for capturing these failure points. It lives alongside SKILL.md as `gotchas.md` and uses a consistent structure:

```markdown
# Gotchas

## Duplicate items from merge commits
- **Symptom**: Yesterday section lists the same work item twice
- **Wrong behavior**: Claude reads `git log` and includes both the feature commit and the merge commit
- **Correct behavior**: Use `git log --no-merges` to filter out merge commits, or deduplicate by commit message content before presenting items
```

Each gotcha follows the **symptom → wrong behavior → correct behavior** pattern. This structure works because:

- **Symptom** tells Claude *when* this gotcha applies (pattern matching)
- **Wrong behavior** tells Claude *what to avoid* (negative example)
- **Correct behavior** tells Claude *what to do instead* (positive example)

The gotchas file is iterative -- you add entries as you discover problems in production. It becomes the skill's institutional memory. Reference it from SKILL.md so Claude loads it when relevant:

```markdown
For known edge cases and failure patterns, see [gotchas.md](./gotchas.md).
```

### Setup & Config Pattern

Production skills often need user-specific context: which Slack channel to post to, what the team name is, what format the user prefers. Hardcoding these values means the skill only works for one person. The solution is a `config.json` in the skill directory.

```json
{
  "team_name": "Platform Engineering",
  "slack_channel": "#platform-standup",
  "standup_time": "09:30",
  "format_preference": "bullet"
}
```

The skill reads this config at runtime. But the config might not exist yet -- the user hasn't set it up. This is where the **check-on-first-run** pattern comes in:

```markdown
## Setup

Before generating output, check if `config.json` exists in this skill's directory.

If it does NOT exist:
1. Ask the user for the following information:
   - Team name (used in the standup header)
   - Slack channel (for posting context)
   - Preferred standup time (for greeting)
   - Format preference: "bullet" or "paragraph"
2. Create `config.json` with their responses
3. Confirm the config was saved

If it DOES exist:
1. Read the config silently
2. Use the values throughout the standup generation
3. Do NOT re-ask for config values unless the user says "reconfigure" or "update config"
```

This pattern gives you personalization without manual setup instructions. The first time a user runs the skill, they get prompted. Every subsequent run uses the saved config.

For plugin-distributed skills, use `${CLAUDE_PLUGIN_DATA}` as the storage path -- this directory survives plugin upgrades and is specific to the plugin installation:

```markdown
Check for config at `${CLAUDE_PLUGIN_DATA}/config.json`.
```

### Skill-Level Memory

Config handles static preferences. But what about dynamic state that changes every run? A standup skill that remembers what you reported yesterday can avoid duplicating items. A PR reviewer that remembers past feedback can track whether issues were addressed.

**Skill-level memory** stores execution history in persistent files. Three patterns, in order of complexity:

**1. Append-only log** -- Simplest. Each run appends a timestamped entry.

```markdown
After generating the standup, append the following to `${CLAUDE_PLUGIN_DATA}/standup-log.jsonl`:

{"date": "2025-01-15", "yesterday": ["Fixed auth bug", "Reviewed PR #42"], "today": ["Deploy auth fix", "Start feature X"], "blockers": []}
```

Use JSONL (one JSON object per line) rather than a JSON array. Appending to an array requires reading the whole file; appending a line doesn't.

**2. Structured JSON** -- For state that gets updated, not just appended.

```json
{
  "last_run": "2025-01-15T09:30:00Z",
  "streak": 5,
  "most_common_blockers": ["CI flakiness", "code review backlog"],
  "items_carried_over": ["Deploy auth fix"]
}
```

Read the file, update values, write it back. Good for statistics and carry-over tracking.

**3. SQLite** -- For complex queries across many runs. Overkill for most skills, but useful when you need to answer questions like "what did I work on in the last 30 days?" across hundreds of entries.

The key design principle: **memory should improve the skill's output, not just exist for its own sake.** If you log data but never read it, remove the logging. Every piece of stored state should directly feed back into better output.

### Measuring Skills

You've built a skill, tested it, deployed it. But how do you know it's actually being used? And when it is used, is it performing well?

**Measurement** answers two questions:
1. **Is the skill triggering?** (Invocation tracking)
2. **Is the skill helping?** (Quality assessment)

For invocation tracking, use a **PreToolUse hook** that logs every time Claude loads a skill. The hook intercepts tool calls, checks if a skill was invoked, and appends to a log file:

```bash
#!/bin/bash
# skill-usage-logger.sh -- PreToolUse hook
# Reads the hook JSON from stdin, extracts skill info, logs it

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Log all skill invocations
if [[ -n "$TOOL_NAME" ]]; then
  LOG_FILE="${HOME}/.claude/skill-usage.jsonl"
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "{\"timestamp\":\"$TIMESTAMP\",\"tool\":\"$TOOL_NAME\"}" >> "$LOG_FILE"
fi

# Always allow -- exit 0 with empty output means "proceed"
exit 0
```

Then write an analytics script that parses the log:

```bash
#!/bin/bash
# Show invocation counts per skill
jq -r '.tool' ~/.claude/skill-usage.jsonl | sort | uniq -c | sort -rn
```

**Detecting under-triggering** is the harder problem. If a skill never shows up in the log, either:
- Users aren't asking for that type of task (the skill isn't needed)
- Users are asking but the description doesn't match (the skill needs better triggers)

Compare your log against your expectations. If you built a standup skill and nobody invokes it during morning hours, investigate the description.

### Avoid Railroading Claude

The final production principle: **give information, not rigid steps.** Claude is an intelligent model that adapts to context. When you over-specify a workflow, you prevent Claude from making good decisions when the situation deviates from your script.

**Over-specified (railroading):**

```markdown
## Steps
1. Run `git log --oneline -10`
2. Parse the output to extract commit messages
3. Group commits by file path
4. For each group, write a bullet point starting with the file name
5. Format as a Markdown list under "## Yesterday"
```

This works for the exact scenario you imagined -- but breaks when the user has no git history, or when the commits span 50 files, or when the user wants a different grouping.

**Flexible (informing):**

```markdown
## Yesterday Section
Summarize recent work based on available context. Preferred sources, in order:
- Git history (`git log`) -- most reliable for recent commits
- Open files and editor state -- useful for in-progress work
- Conversation context -- what the user has mentioned

Group related items together. Aim for 2-4 bullets. If no context is available, ask the user.
```

The flexible version gives Claude the same intent (summarize recent work) but lets it adapt. If git history is empty, it falls back to other sources instead of failing at step 1.

The test for railroading: **imagine three different scenarios where a user would invoke this skill.** If your instructions would fail or produce poor results in any of them, you've over-specified. Rewrite to describe the *goal* and *constraints*, not the *steps*.

## Key References

| Concept | Source |
|---|---|
| Don't state the obvious | Production experience; token efficiency principles |
| Gotchas pattern | Error-driven development; iterative maintenance |
| Config pattern | `config.json` + `AskUserQuestion` for structured setup |
| Skill-level memory | `${CLAUDE_PLUGIN_DATA}` for persistent storage |
| Measuring skills | PreToolUse hooks for invocation logging |
| Avoiding railroading | Goal-oriented vs step-oriented instruction design |

## What You're Building

In this course, you'll refactor the `daily-standup` skill from Course 1 into a **production-quality** `daily-standup-v2` skill. The original skill was a great starting point -- clear format, specific instructions, good trigger phrases. But it lacks the patterns that make a skill robust in real-world use:

- No config -- it doesn't know your team name or Slack channel
- No gotchas -- it repeats the same mistakes every time
- No memory -- it can't remember what you reported yesterday
- No measurement -- you don't know if it's being used

By the end, you'll have:

```
daily-standup-v2/
├── SKILL.md          ← Production-quality skill with config, memory, gotchas
├── config.json       ← User-specific settings (team, channel, format)
└── gotchas.md        ← Known failure patterns with fixes
```

Plus two scripts for measuring skill usage across your entire skill library:

```
scripts/
├── skill-usage-logger.sh   ← PreToolUse hook for invocation logging
└── analyze-usage.sh        ← Analytics over the invocation log
```

## Walkthrough

### Step 1: Review the original daily-standup skill

Before refactoring, let's audit the original skill from Course 1. Open your installed skill:

```bash
cat ~/.claude/skills/daily-standup/SKILL.md
```

Read through it with the "Don't State the Obvious" lens. Ask yourself for each line:

- Would Claude do this anyway without being told?
- Does this instruction change Claude's behavior in a measurable way?

For example, "Keep each bullet point to one line (under 100 characters)" -- this is a non-obvious constraint that changes behavior. Claude's default might be longer bullets. Good, keep it.

But "Be specific" is borderline. Claude generally tries to be specific. The example after it ("Fixed auth token refresh bug in login.ts" not "Worked on auth") is the valuable part -- it shows *how specific* you mean.

### Step 2: Create the daily-standup-v2 directory

```bash
mkdir -p ~/.claude/skills/daily-standup-v2
```

We're creating a new skill rather than modifying the original. This lets you compare them side-by-side and keeps the Course 1 artifact intact.

### Step 3: Write the gotchas file

Start with `gotchas.md`. This file captures failure patterns you've likely already encountered with the original skill:

Create `~/.claude/skills/daily-standup-v2/gotchas.md` with these entries:

```markdown
# Gotchas

## Duplicate items from merge commits
- **Symptom**: Yesterday section lists the same work item twice with slightly different wording
- **Wrong behavior**: Claude reads `git log` and includes both the original commit and the merge commit that brought it into main
- **Correct behavior**: Use `git log --no-merges` to filter out merge commits, or deduplicate by comparing commit message content before presenting items

## Empty git history in new repos
- **Symptom**: Claude runs `git log` and gets an error or empty output, then produces a broken standup
- **Wrong behavior**: Claude proceeds with the git-based approach and outputs empty or error-filled Yesterday section
- **Correct behavior**: Detect when git history is unavailable or empty. Fall back to asking the user what they worked on. Never present an empty Yesterday section -- either populate it or ask.

## Weekend/Monday carry-over confusion
- **Symptom**: On Monday, the Yesterday section shows Friday's work but the user also did weekend work, or vice versa
- **Wrong behavior**: Claude assumes "yesterday" means the calendar day before today, missing weekend work or including stale Friday items
- **Correct behavior**: On Monday, check git history for Friday through Sunday. Present items from the most recent working period. If the user worked over the weekend, include that. Frame the section header as "Since Last Standup" when spanning multiple days.

## Standup is too long for Slack
- **Symptom**: Generated standup has 8+ bullet points per section and exceeds Slack message length norms
- **Wrong behavior**: Claude lists every commit individually, producing a standup that's more of a changelog than a summary
- **Correct behavior**: Group related commits into higher-level work items. Aim for 2-4 bullets per section. If there are more than 4 items, consolidate related work. A standup should take 30 seconds to read.
```

Each gotcha follows the symptom/wrong/correct pattern. These come from real-world experience with standup generators -- you'll add more as you use the skill.

### Step 4: Create the config file

Create `~/.claude/skills/daily-standup-v2/config.json`:

```json
{
  "team_name": "My Team",
  "slack_channel": "#team-standup",
  "standup_time": "09:30",
  "format_preference": "bullet"
}
```

This is the default config that gets created on first run. The skill will check for this file and prompt the user to customize it if needed.

### Step 5: Write the production SKILL.md

Now create `~/.claude/skills/daily-standup-v2/SKILL.md`. This is the core refactor. Here's what changes from the Course 1 version:

**Removed** (stating the obvious):
- Generic instructions like "be specific" without examples
- "List any blockers mentioned in conversation" -- Claude does this naturally

**Added** (production patterns):
- Config reading with check-on-first-run
- Gotchas reference for edge case handling
- Execution logging for cross-session memory
- Flexible fallback chain instead of rigid steps

Create the file with the content from the `skill/daily-standup-v2/SKILL.md` in this course's directory. The key sections are:

1. **YAML frontmatter** with an improved description that captures more trigger phrases
2. **Setup section** implementing the check-on-first-run config pattern
3. **Format section** that's goal-oriented rather than step-by-step
4. **Memory section** that logs each standup for cross-session awareness
5. **Gotchas reference** linking to the gotchas file

Compare the original and v2 side-by-side:

| Aspect | Course 1 Original | Course 12 v2 |
|---|---|---|
| Config | None | `config.json` with team info |
| Error handling | None | Gotchas file with 4 patterns |
| Memory | None | JSONL execution log |
| Fallback strategy | Single approach | Ordered source chain |
| Instruction style | Some rigid steps | Goal-oriented with constraints |
| Token efficiency | Some obvious lines | Audited for non-obvious only |

### Step 6: Build the usage logger hook

Create `scripts/skill-usage-logger.sh`:

```bash
#!/bin/bash
# skill-usage-logger.sh -- PreToolUse hook for measuring skill invocations
# Install: Add to .claude/hooks.json under PreToolUse
# Logs every tool invocation with timestamp and tool name

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

if [[ -n "$TOOL_NAME" ]]; then
  LOG_DIR="${HOME}/.claude/logs"
  mkdir -p "$LOG_DIR"
  LOG_FILE="${LOG_DIR}/skill-usage.jsonl"
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  DATE=$(date -u +"%Y-%m-%d")
  echo "{\"timestamp\":\"$TIMESTAMP\",\"date\":\"$DATE\",\"tool\":\"$TOOL_NAME\",\"session\":\"$SESSION_ID\"}" >> "$LOG_FILE"
fi

# Always allow the tool call to proceed
exit 0
```

Make it executable:

```bash
chmod +x scripts/skill-usage-logger.sh
```

To install this hook, add it to your `.claude/hooks.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "command": "~/.claude/hooks/skill-usage-logger.sh",
        "description": "Logs all tool invocations for usage analytics"
      }
    ]
  }
}
```

Copy the script to your hooks directory:

```bash
mkdir -p ~/.claude/hooks
cp scripts/skill-usage-logger.sh ~/.claude/hooks/
```

### Step 7: Build the analytics script

Create `scripts/analyze-usage.sh`:

```bash
#!/bin/bash
# analyze-usage.sh -- Parse skill usage logs and output statistics
# Reads from ~/.claude/logs/skill-usage.jsonl

LOG_FILE="${HOME}/.claude/logs/skill-usage.jsonl"

if [[ ! -f "$LOG_FILE" ]]; then
  echo "No usage log found at $LOG_FILE"
  echo "Install the skill-usage-logger.sh hook first."
  exit 1
fi

TOTAL=$(wc -l < "$LOG_FILE" | tr -d ' ')
echo "=== Skill Usage Report ==="
echo "Log file: $LOG_FILE"
echo "Total invocations: $TOTAL"
echo ""

echo "--- Invocations per tool (top 15) ---"
jq -r '.tool' "$LOG_FILE" | sort | uniq -c | sort -rn | head -15
echo ""

echo "--- Daily trend (last 14 days) ---"
jq -r '.date' "$LOG_FILE" | sort | uniq -c | tail -14
echo ""

echo "--- Most used (top 3) ---"
jq -r '.tool' "$LOG_FILE" | sort | uniq -c | sort -rn | head -3
echo ""

echo "--- Least used (bottom 3) ---"
jq -r '.tool' "$LOG_FILE" | sort | uniq -c | sort -rn | tail -3
echo ""

echo "--- Sessions with most activity ---"
jq -r '.session' "$LOG_FILE" | sort | uniq -c | sort -rn | head -5
echo ""

echo "--- Hourly distribution ---"
jq -r '.timestamp' "$LOG_FILE" | cut -dT -f2 | cut -d: -f1 | sort | uniq -c | sort -k2 -n
```

Make it executable:

```bash
chmod +x scripts/analyze-usage.sh
```

### Step 8: Test the refactored skill

Now test `daily-standup-v2` against the original. Open Claude Code in a project with git history:

**Test 1: First-run config setup**

```
standup
```

If you haven't created `config.json` yet, the skill should ask you for team name, Slack channel, standup time, and format preference. Verify it creates the config file.

**Test 2: Normal standup generation**

```
daily standup
```

Verify:
- It reads from `config.json` (team name appears in output)
- It handles git history correctly (no duplicates from merge commits)
- It logs the execution to the standup log

**Test 3: Monday edge case**

If it's Monday (or pretend it is), check whether the skill handles the weekend carry-over correctly -- it should look at Friday-Sunday git history.

**Test 4: Empty repo**

Create a fresh repo with no commits and run the standup. Verify it falls back to asking the user rather than showing errors.

**Test 5: Compare with original**

Run the original `daily-standup` skill and the new `daily-standup-v2` with the same context. Note differences in output quality, error handling, and personalization.

### Step 9: Review your measurement data

After running several tests, check if the usage logger captured the invocations:

```bash
cat ~/.claude/logs/skill-usage.jsonl
```

Then run the analytics:

```bash
./scripts/analyze-usage.sh
```

You should see your test invocations in the log. In a real deployment, this data accumulates over days and weeks, giving you insight into which skills are worth maintaining and which are dead weight.

### Step 10: Iterate on the gotchas

During testing, you likely discovered at least one new edge case. Add it to `gotchas.md` using the symptom/wrong/correct format. This is the production cycle:

1. Use the skill
2. Notice a failure
3. Document the gotcha
4. Update SKILL.md if needed to reference the pattern
5. Re-test

The gotchas file grows over time. A mature production skill might have 10-15 gotchas -- each one representing a failure that now gets handled correctly.

## Exercises

1. **Audit an existing skill**: Pick any skill you've built in Courses 1-11. Apply the "Don't State the Obvious" removal test to every line. Remove lines that don't change behavior, then verify the skill still works correctly. Document how many lines you removed and whether output quality changed.

2. **Add gotchas to another skill**: Pick a skill you've used at least 5 times. Write a `gotchas.md` with at least 3 entries based on real failures you've observed. Each entry must follow the symptom/wrong/correct format.

3. **Implement config for a different skill**: Add a `config.json` and check-on-first-run pattern to a skill of your choice. Choose at least 3 configurable values that meaningfully change the skill's behavior (not cosmetic changes).

4. **Run the usage logger for a full day**: Install `skill-usage-logger.sh` as a PreToolUse hook and use Claude Code normally for a full workday. At the end of the day, run `analyze-usage.sh` and answer:
   - Which skill was invoked most?
   - Were there any skills that were never invoked? Why?
   - What time of day do you use skills the most?

5. **Rewrite a railroaded skill**: Find a skill (yours or the examples in this course) that uses rigid step-by-step instructions. Rewrite it using goal-oriented instructions with fallback chains. Test both versions with 3 different scenarios and document which handles edge cases better.

6. **Build a memory-enabled skill**: Add JSONL execution logging to a skill. After 5+ runs, have Claude read the log and use past executions to improve current output (e.g., "You reported working on Feature X for the last 3 days -- is it complete?").

## Verification Checklist

- [ ] `~/.claude/skills/daily-standup-v2/SKILL.md` exists with correct casing
- [ ] YAML frontmatter has valid `---` delimiters with `name` and `description`
- [ ] `description` includes expanded trigger phrases beyond the original
- [ ] `~/.claude/skills/daily-standup-v2/config.json` exists with team_name, slack_channel, standup_time, format_preference
- [ ] `~/.claude/skills/daily-standup-v2/gotchas.md` exists with at least 3 entries
- [ ] Each gotcha follows the symptom → wrong behavior → correct behavior format
- [ ] SKILL.md references `gotchas.md` for edge case handling
- [ ] SKILL.md implements check-on-first-run config pattern
- [ ] SKILL.md includes execution logging instructions
- [ ] SKILL.md uses goal-oriented instructions (not rigid step lists)
- [ ] Running "standup" triggers the v2 skill
- [ ] First run prompts for config values (if config.json is absent)
- [ ] Subsequent runs use saved config silently
- [ ] Standup handles empty git history gracefully
- [ ] Standup handles Monday/weekend carry-over correctly
- [ ] `scripts/skill-usage-logger.sh` is executable and has correct shebang
- [ ] `scripts/analyze-usage.sh` is executable and has correct shebang
- [ ] Usage logger produces valid JSONL output
- [ ] Analytics script outputs invocation counts, daily trends, and most/least used
- [ ] You can articulate at least 2 lines you removed from the original skill for being "obvious"

## What's Next

In **Course 13: Distributing Skills -- Packaging, Sharing & Plugin Ecosystems**, you'll learn:
- Packaging skills as distributable plugins with `plugin.json` manifests
- Version management and upgrade strategies for published skills
- Sharing skills across teams with install-from-URL workflows
- Building plugin registries for organizational skill libraries
- Handling cross-platform compatibility (macOS, Linux, Windows WSL)
- You'll package `daily-standup-v2` and your other production skills into a team-ready plugin

# Course 15: Infrastructure Operations Skills -- Guardrails for Dangerous Work
**Level**: Advanced | **Estimated time**: 50 min

## Prerequisites
- Courses 1-7 completed (skill fundamentals, descriptions, anatomy, testing, advanced features, workflows, hooks)
- Course 12 completed (production craft and memory patterns)
- Familiarity with `jq` for JSON parsing
- A project with some accumulated cruft (stale branches, unused files) to test against

## Concepts

### Operations Skills Are Different

Most skills help Claude *build* things -- write code, create files, generate configurations. Operations skills help Claude *clean up* things -- remove stale branches, delete orphaned assets, prune unused dependencies. The difference matters because operations skills perform **destructive actions with real consequences**.

If a code-generation skill produces bad output, you delete it and try again. If a cleanup skill deletes the wrong branch, that work is gone. This asymmetry demands a different design philosophy: operations skills must be **safe by default** and **dangerous only by explicit request**.

The core principle:

> An operations skill should never destroy anything the first time you run it. It should *report* what it found, *wait* for you to review, and *act* only after you confirm.

This course teaches you four patterns that enforce this principle: on-demand safety hooks, soak periods, dry-run defaults, and audit logging.

### The On-Demand Hook Pattern

In Course 7, you learned about hooks -- shell scripts that fire at specific points in Claude's lifecycle. Those hooks were configured globally or per-project. They're always active.

Operations skills need a different approach: **session-scoped hooks** that activate only when a specific skill is called. You don't want destructive-command blocking running during normal development. You want it running *only* during a cleanup operation, when the stakes are high.

This is the on-demand hook pattern. A skill declares hooks in its YAML frontmatter:

```yaml
---
name: resource-cleanup
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: ".claude/hooks/block-destructive.sh"
---
```

When Claude loads this skill, the hook activates. When the skill completes, the hook deactivates. The hook exists only for the duration of the operation.

Two important variations of this pattern:

| Pattern | What it does | Example |
|---|---|---|
| `/careful` | Blocks destructive commands for the session | `rm -rf`, `git push --force`, `DROP TABLE` |
| `/freeze` | Blocks file edits outside a specific directory | Only allows changes in `src/feature-x/` |

Both are "pure hook-as-skill" patterns -- the entire skill is just a safety activation. The `/careful` pattern is one of the skills you'll build in this course.

### Soak Periods and Confirmation Gates

A soak period is a deliberate pause between *detecting* a problem and *acting* on it. The flow looks like this:

```
Phase 1: DETECT
    Scan for orphaned resources
    Build a report of what was found
        |
        v
Phase 2: REPORT
    Present findings to the user
    Show what would be deleted/changed
    Show resource age, size, dependencies
        |
        v
Phase 3: WAIT (the soak period)
    Pause for user review
    User can ask questions about specific items
    User can exclude items from the action list
        |
        v
Phase 4: CONFIRM
    Explicitly ask: "Proceed with cleanup?"
    Require affirmative response
    No timeout-based auto-proceed
        |
        v
Phase 5: EXECUTE
    Perform the destructive actions
    Log every action taken
    Report results
```

The soak period (Phase 3) is the critical safety feature. It gives the user time to:
- Spot items that shouldn't be deleted
- Ask Claude for more context about specific resources
- Modify the action list before proceeding

**Never skip the soak period.** Even if the user says "just clean everything up," the skill should still report first. The user might not realize what "everything" includes.

### Dry-Run as Default

Dry-run mode is the soak period's complement. Where soak periods add a pause, dry-run mode changes the skill's *default behavior* entirely:

- **Default mode (dry-run)**: Scan, detect, and report. Do not modify anything.
- **Execute mode**: Scan, detect, report, confirm, and then actually perform the actions.

The user switches from dry-run to execute mode with an explicit flag:

```
# Dry run (default) -- just report
/resource-cleanup

# Actually do the cleanup
/resource-cleanup --execute
```

This is safer than a confirmation prompt alone. A confirmation prompt asks "do you want to proceed?" when the user has *already expressed intent* to clean up. Dry-run mode requires the user to *re-invoke the skill with a different argument*, which is a stronger signal of intent.

Design rule: **if your skill can delete, overwrite, or irreversibly modify anything, it should default to dry-run.**

### Audit Logging

When an operations skill performs destructive actions, it should record what happened. Audit logs answer three questions:
- **What** was changed or deleted?
- **When** did it happen?
- **What was the context** (which skill, what arguments, what was the state before the change)?

The simplest audit pattern writes a structured log entry to a file:

```bash
# Append to audit log
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | resource-cleanup | deleted branch: feature/old-experiment | age: 47 days | last commit: abc1234" >> .claude/audit.log
```

For skills that run repeatedly, structure the log as one entry per operation with nested details:

```
## 2026-03-18T14:30:00Z -- resource-cleanup --execute
- Deleted branch: feature/old-experiment (47 days stale, last commit abc1234)
- Deleted branch: fix/typo-in-readme (92 days stale, last commit def5678)
- Removed orphaned config: .eslintrc.legacy (not referenced by any script)
- Skipped: feature/maybe-later (excluded by user)
```

You can also use the skill memory patterns from Course 12 to store audit data in `.claude/memory/` for retrieval in future sessions. This creates a persistent operational history that Claude can reference when making decisions.

### Combining the Patterns

In practice, you combine all four patterns. Here's how they fit together for a resource-cleanup skill:

```
User invokes /resource-cleanup
    |
    v
On-demand hook activates (blocks rm -rf, force-push, etc.)
    |
    v
Dry-run mode: scan and report orphaned resources
    |
    v
User reviews report, asks questions (soak period)
    |
    v
User re-invokes with /resource-cleanup --execute
    |
    v
On-demand hook still active (destructive commands blocked
UNLESS the skill explicitly confirms each one)
    |
    v
Execute with confirmation gates for each destructive action
    |
    v
Audit log records everything that was changed
    |
    v
Hook deactivates when skill completes
```

This layered approach means that even if one safety mechanism fails, the others catch the problem. The hook blocks accidental destructive commands. The dry-run default prevents accidental execution. The confirmation gate requires explicit approval. The audit log creates accountability.

## Key References
- Hooks reference: `~/.claude-code-docs/docs/hooks.md` -- Full event schemas, JSON I/O, decision control
- Hooks guide: `~/.claude-code-docs/docs/hooks-guide.md` -- Setup walkthrough, common patterns, troubleshooting
- Course 7: Hooks -- Deterministic Control over Claude's Behavior
- Course 12: Production Craft -- Memory patterns for audit trails

## What You're Building

You'll create two skills that demonstrate operations guardrails:

1. **`resource-cleanup`** -- A full-featured operations skill that finds orphaned resources (stale git branches, unused config files, orphaned assets), reports them with a soak period, and cleans up only after explicit user confirmation. Includes an on-demand `PreToolUse` hook that blocks destructive commands unless the user has confirmed. Defaults to dry-run mode.

2. **`careful`** -- A minimal on-demand safety hook skill. When invoked, it activates destructive-command blocking for the duration of the session. Demonstrates the "pure hook-as-skill" pattern -- a skill whose entire purpose is to activate a safety hook.

The file structure:

```
skill/
├── resource-cleanup/
│   ├── SKILL.md
│   └── hooks/
│       └── block-destructive.sh
└── careful/
    └── SKILL.md
```

## Walkthrough

### Step 1: Build the block-destructive hook

This is the shared safety hook used by both skills. It intercepts every Bash command and checks for dangerous patterns.

Create `skill/resource-cleanup/hooks/block-destructive.sh`:

```bash
#!/bin/bash
# block-destructive.sh -- PreToolUse hook for Bash
# Blocks destructive commands unless a CONFIRMED marker is present.
#
# Dangerous patterns blocked:
#   - rm -rf (recursive forced deletion)
#   - git push --force / git push -f (force push)
#   - DROP TABLE / DROP DATABASE (SQL destruction)
#   - DELETE FROM (SQL mass deletion)
#   - git reset --hard (discard uncommitted changes)
#   - git clean -f (delete untracked files)
#
# To proceed with a legitimate destructive command, the skill must
# include CONFIRMED_DESTRUCTIVE in a comment within the command.
# Example: rm -rf old-dir/ # CONFIRMED_DESTRUCTIVE

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# If the command contains the confirmation marker, allow it
if echo "$COMMAND" | grep -q 'CONFIRMED_DESTRUCTIVE'; then
  exit 0
fi

# --- Check for destructive patterns ---

# rm -rf
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|(-[a-zA-Z]*f[a-zA-Z]*r))\b'; then
  echo "BLOCKED: 'rm -rf' detected. Recursive forced deletion is not allowed without confirmation. If this is intentional, re-run the command with a '# CONFIRMED_DESTRUCTIVE' comment." >&2
  exit 2
fi

# git push --force / -f
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*(-f|--force)\b'; then
  echo "BLOCKED: 'git push --force' detected. Force pushing is not allowed without confirmation. If this is intentional, re-run the command with a '# CONFIRMED_DESTRUCTIVE' comment." >&2
  exit 2
fi

# DROP TABLE / DROP DATABASE
if echo "$COMMAND" | grep -qiE '\bDROP\s+(TABLE|DATABASE)\b'; then
  echo "BLOCKED: 'DROP TABLE/DATABASE' detected. SQL destruction is not allowed without confirmation. If this is intentional, re-run the command with a '# CONFIRMED_DESTRUCTIVE' comment." >&2
  exit 2
fi

# DELETE FROM
if echo "$COMMAND" | grep -qiE '\bDELETE\s+FROM\b'; then
  echo "BLOCKED: 'DELETE FROM' detected. SQL mass deletion is not allowed without confirmation. If this is intentional, re-run the command with a '# CONFIRMED_DESTRUCTIVE' comment." >&2
  exit 2
fi

# git reset --hard
if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
  echo "BLOCKED: 'git reset --hard' detected. Discarding uncommitted changes is not allowed without confirmation. If this is intentional, re-run the command with a '# CONFIRMED_DESTRUCTIVE' comment." >&2
  exit 2
fi

# git clean -f
if echo "$COMMAND" | grep -qE 'git\s+clean\s+.*-[a-zA-Z]*f'; then
  echo "BLOCKED: 'git clean -f' detected. Deleting untracked files is not allowed without confirmation. If this is intentional, re-run the command with a '# CONFIRMED_DESTRUCTIVE' comment." >&2
  exit 2
fi

# All checks passed
exit 0
```

Key design decisions:
- **Confirmation marker**: The `CONFIRMED_DESTRUCTIVE` pattern lets the skill bypass the hook when the user has explicitly confirmed. The hook blocks *accidental* destructive commands, not *confirmed* ones.
- **Broad pattern matching**: `rm -rf` catches both `rm -rf` and `rm -rfi` and other flag orderings. The regex handles flag combinations like `-rf`, `-fr`, `-rfi`, etc.
- **Case-insensitive SQL matching**: `DROP TABLE` catches `drop table`, `Drop Table`, etc.
- **Descriptive error messages**: Each blocked command explains *what* was detected and *how* to proceed. This feedback goes to Claude, who can then ask the user for confirmation.

Make it executable:

```bash
chmod +x skill/resource-cleanup/hooks/block-destructive.sh
```

### Step 2: Build the resource-cleanup skill

This is the main operations skill. It uses all four patterns: on-demand hooks, dry-run default, soak period, and audit logging.

Create `skill/resource-cleanup/SKILL.md`:

```yaml
---
name: resource-cleanup
description: |
  Find and clean up orphaned resources: stale git branches, unused config files,
  orphaned assets, and other project cruft. Use when the user says "clean up",
  "find stale branches", "remove unused files", "orphaned resources", or
  "project hygiene". Defaults to dry-run (report only). Pass --execute to
  actually perform cleanup.
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./hooks/block-destructive.sh"
---
```

The frontmatter wires up the `block-destructive.sh` hook. It activates automatically when this skill loads and deactivates when it completes.

Below the frontmatter, write the skill instructions:

```markdown
# Resource Cleanup

Find orphaned resources, report them, and clean up after user confirmation.
**Default mode is dry-run** -- no resources are modified unless `--execute` is passed.

## Arguments

- (no args): Dry-run mode. Scan and report only.
- `--execute`: Execute mode. Scan, report, confirm, then clean up.

## Dry-Run Mode (default)

1. **Scan for orphaned resources** in this order:

   ### Stale Git Branches
   Find local branches with no activity in the last 30 days:
   ...
```

The full SKILL.md content is in the file you'll create. Here's what matters about its structure:

**Dry-run mode** (the default) scans and reports. It never deletes anything. The report includes resource type, name, age, and why it's considered orphaned.

**Execute mode** (`--execute`) follows the full soak-period flow:
1. Scan and build the same report as dry-run
2. Present the report and wait for user review
3. Ask the user to confirm or exclude items
4. Execute deletions one at a time, appending `# CONFIRMED_DESTRUCTIVE` to each command so the hook allows it
5. Write an audit log entry

The audit log goes to `.claude/audit.log` with timestamps, resource names, and the action taken.

### Step 3: Build the careful skill

This is the "pure hook-as-skill" pattern. The skill exists solely to activate destructive-command blocking.

Create `skill/careful/SKILL.md`:

```yaml
---
name: careful
description: |
  Activate careful mode -- block dangerous Bash commands for this session.
  Use when the user says "be careful", "careful mode", "safety mode",
  or "block dangerous commands".
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "../resource-cleanup/hooks/block-destructive.sh"
---
```

The `careful` skill reuses the same `block-destructive.sh` hook from `resource-cleanup`. It doesn't need its own copy -- it references the shared hook.

The skill body is minimal:

```markdown
# Careful Mode Activated

Dangerous Bash commands are now blocked for this session. The following
patterns will be intercepted and stopped:
...
```

This demonstrates an important design principle: **a skill can be pure infrastructure**. It doesn't need to perform a task. It can exist solely to modify Claude's environment for the duration of a session.

### Step 4: Test the hook in isolation

Before testing with Claude, verify the hook script works correctly by piping sample JSON:

```bash
# Should pass (exit 0) -- safe command
echo '{"tool_input":{"command":"git branch -a"}}' | ./skill/resource-cleanup/hooks/block-destructive.sh
echo "Exit: $?"

# Should block (exit 2) -- rm -rf
echo '{"tool_input":{"command":"rm -rf old-directory/"}}' | ./skill/resource-cleanup/hooks/block-destructive.sh
echo "Exit: $?"

# Should block (exit 2) -- force push
echo '{"tool_input":{"command":"git push --force origin main"}}' | ./skill/resource-cleanup/hooks/block-destructive.sh
echo "Exit: $?"

# Should block (exit 2) -- DROP TABLE
echo '{"tool_input":{"command":"psql -c \"DROP TABLE users\""}}' | ./skill/resource-cleanup/hooks/block-destructive.sh
echo "Exit: $?"

# Should pass (exit 0) -- confirmed destructive command
echo '{"tool_input":{"command":"rm -rf old-directory/ # CONFIRMED_DESTRUCTIVE"}}' | ./skill/resource-cleanup/hooks/block-destructive.sh
echo "Exit: $?"

# Should block (exit 2) -- git reset --hard
echo '{"tool_input":{"command":"git reset --hard HEAD~3"}}' | ./skill/resource-cleanup/hooks/block-destructive.sh
echo "Exit: $?"

# Should block (exit 2) -- git clean -f
echo '{"tool_input":{"command":"git clean -fd"}}' | ./skill/resource-cleanup/hooks/block-destructive.sh
echo "Exit: $?"
```

Verify: safe commands exit 0, destructive commands exit 2 with a "BLOCKED:" message, and confirmed destructive commands exit 0.

### Step 5: Install and test with Claude

Install the skills where Claude can find them:

```bash
# Option A: Project-local (recommended for testing)
cp -r skill/resource-cleanup/ .claude/skills/resource-cleanup/
cp -r skill/careful/ .claude/skills/careful/

# Option B: Global
cp -r skill/resource-cleanup/ ~/.claude/skills/resource-cleanup/
cp -r skill/careful/ ~/.claude/skills/careful/
```

Test the `careful` skill:

```
You: /careful
Claude: Careful mode activated. Dangerous commands are now blocked.

You: Delete the entire src directory
Claude: [attempts rm -rf src/]
Hook: BLOCKED: 'rm -rf' detected...
Claude: I can't delete the directory because careful mode is blocking
        destructive commands. Would you like me to proceed anyway?
```

Test the `resource-cleanup` skill:

```
You: /resource-cleanup
Claude: [scans for stale branches, unused configs, orphaned assets]
Claude: Found 3 orphaned resources:
        1. Branch: feature/old-experiment (47 days stale)
        2. Config: .eslintrc.legacy (not referenced)
        3. Asset: public/old-logo.png (not imported)
        No changes made (dry-run mode).

You: /resource-cleanup --execute
Claude: [shows same report, then asks for confirmation]
Claude: Proceed with cleanup of these 3 resources? (y/n)
You: y
Claude: [deletes each resource with CONFIRMED_DESTRUCTIVE marker]
Claude: Cleanup complete. Audit log written to .claude/audit.log
```

## Exercises

### Exercise 1: Test the hook against edge cases

Run these additional test cases against `block-destructive.sh`:

```bash
# Edge case: rm with -r and -f as separate flags
echo '{"tool_input":{"command":"rm -r -f old-dir/"}}' | ./skill/resource-cleanup/hooks/block-destructive.sh
echo "Exit: $?"

# Edge case: command buried in a pipeline
echo '{"tool_input":{"command":"find . -name old | xargs rm -rf"}}' | ./skill/resource-cleanup/hooks/block-destructive.sh
echo "Exit: $?"

# Edge case: DELETE FROM in a heredoc
echo '{"tool_input":{"command":"psql <<EOF\nDELETE FROM users WHERE active=false;\nEOF"}}' | ./skill/resource-cleanup/hooks/block-destructive.sh
echo "Exit: $?"
```

Which of these does the hook catch? Which does it miss? What changes would you make to improve coverage?

### Exercise 2: Add a new blocked pattern

Add a check for `truncate` (SQL table truncation) to `block-destructive.sh`. Follow the same pattern as the existing checks:
1. Add a regex match for `TRUNCATE TABLE` (case-insensitive)
2. Print a descriptive "BLOCKED:" message to stderr
3. Exit with code 2

Test your addition:

```bash
echo '{"tool_input":{"command":"psql -c \"TRUNCATE TABLE sessions\""}}' | ./skill/resource-cleanup/hooks/block-destructive.sh
echo "Exit: $?"
```

### Exercise 3: Build a /freeze skill

Create a new skill called `freeze` that blocks file edits outside a specified directory. The skill should:
1. Accept a directory path as an argument (e.g., `/freeze src/feature-x/`)
2. Register a `PreToolUse` hook on `Edit|Write` that checks the `file_path`
3. Block any edit to a file outside the specified directory

Hint: the hook needs access to the directory argument. One approach is to write the directory to a temp file that the hook reads.

### Exercise 4: Add age thresholds to resource-cleanup

Modify the `resource-cleanup` skill to accept a `--days` argument that controls the staleness threshold:

```
/resource-cleanup --days 90     # Only flag branches older than 90 days
/resource-cleanup --days 7      # Flag anything older than a week
```

Update the scanning logic to use this threshold instead of the hardcoded 30-day default.

### Exercise 5: Implement persistent audit logging

Extend the audit logging to use the memory pattern from Course 12. Instead of writing to a flat file, write structured audit entries to `.claude/memory/audit/`:

```
.claude/memory/audit/
├── 2026-03-18-cleanup.md
├── 2026-03-15-cleanup.md
└── summary.md
```

Each entry should be a Markdown file with frontmatter containing structured data (timestamp, resources affected, outcome). The `summary.md` file should be updated after each operation with running totals.

## Verification Checklist

- [ ] `skill/resource-cleanup/hooks/block-destructive.sh` exists and is executable
- [ ] `block-destructive.sh` blocks `rm -rf` commands (exit 2 with stderr message)
- [ ] `block-destructive.sh` blocks `git push --force` commands (exit 2)
- [ ] `block-destructive.sh` blocks `DROP TABLE` commands (exit 2)
- [ ] `block-destructive.sh` blocks `DELETE FROM` commands (exit 2)
- [ ] `block-destructive.sh` blocks `git reset --hard` commands (exit 2)
- [ ] `block-destructive.sh` blocks `git clean -f` commands (exit 2)
- [ ] `block-destructive.sh` allows confirmed commands with `CONFIRMED_DESTRUCTIVE` marker (exit 0)
- [ ] `block-destructive.sh` allows safe commands like `git branch -a` (exit 0)
- [ ] `skill/resource-cleanup/SKILL.md` has valid YAML frontmatter with `hooks` field
- [ ] `skill/resource-cleanup/SKILL.md` defaults to dry-run mode
- [ ] `skill/resource-cleanup/SKILL.md` requires `--execute` flag for actual cleanup
- [ ] `skill/resource-cleanup/SKILL.md` includes audit logging instructions
- [ ] `skill/careful/SKILL.md` has valid YAML frontmatter with `hooks` field
- [ ] `skill/careful/SKILL.md` references the shared `block-destructive.sh` hook
- [ ] You can explain the difference between dry-run mode and soak periods
- [ ] You can explain why operations skills need on-demand hooks rather than global hooks
- [ ] You understand the confirmation marker pattern (`CONFIRMED_DESTRUCTIVE`)

## What's Next

You've now built operations skills with layered safety: on-demand hooks that activate per-session, dry-run defaults that prevent accidental execution, soak periods that create space for review, and audit logs that record what happened.

These patterns apply to any skill that performs destructive or irreversible actions -- database migrations, infrastructure provisioning, dependency upgrades, and more. The key principle is always the same: **safe by default, dangerous only by explicit request**.

With Courses 12-15 complete, you've covered the full range of Phase 3 production patterns: memory and context management, runbook automation, and infrastructure operations. You're ready to tackle the **Course 11 Capstone**, where you'll combine skills, hooks, subagents, and teams into a complete production system. The capstone is the culmination of everything you've learned across all three phases.

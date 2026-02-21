# Course 5: Advanced Skill Features -- Arguments, Dynamic Context, Subagent Execution
**Level**: Intermediate | **Estimated time**: 45 min

## Prerequisites
- Completed **Course 1: Your First Skill in Five Minutes** (skill folder basics, YAML frontmatter, naming rules)
- Completed **Course 2: Crafting Descriptions and Trigger Phrases** (description formula, `disable-model-invocation`, `user-invocable`)
- Completed **Course 3: Full Skill Anatomy** (scripts, references, assets, progressive disclosure L3)
- Completed **Course 4: Testing, Iteration, and the Feedback Loop** (test plans, iteration signals, performance baselines)
- You have the `daily-standup`, `code-review-checklist`, `meeting-to-actions`, and `pr-description` skills installed
- You have the GitHub CLI (`gh`) installed and authenticated (for the investigate-issue skill)

## Concepts

### Moving Beyond Static Skills

In Courses 1-4, every skill you built was static -- the same instructions ran the same way every time. The `daily-standup` skill always generates Yesterday/Today/Blockers. The `pr-description` skill always reads git diff. The instructions are fixed at authoring time.

But real workflows need flexibility:
- "Investigate issue **#42**" -- the issue number changes every time
- "Summarize PR **#187**" -- the skill needs live data from GitHub, not a hardcoded prompt
- "Research the auth module" -- this exploration task shouldn't pollute your main conversation context

Course 5 introduces three features that make skills dynamic and isolated: **arguments** for parameterized input, **dynamic context injection** for live data preprocessing, and **subagent execution** for isolated contexts. Together, they transform skills from static recipes into flexible, reusable tools.

### Passing Arguments with `$ARGUMENTS`

Skills can accept arguments when invoked. The skills docs describe three substitution patterns:

| Syntax | Description | Example |
|---|---|---|
| `$ARGUMENTS` | All arguments as a single string | `/fix-issue 123` → `$ARGUMENTS` becomes `123` |
| `$ARGUMENTS[N]` | Access argument by 0-based index | `/migrate SearchBar React Vue` → `$ARGUMENTS[1]` becomes `React` |
| `$N` | Shorthand for `$ARGUMENTS[N]` | `/migrate SearchBar React Vue` → `$1` becomes `React` |

Here's the fix-issue example from the skills docs:

```yaml
---
name: fix-issue
description: Fix a GitHub issue
disable-model-invocation: true
---

Fix GitHub issue $ARGUMENTS following our coding standards.

1. Read the issue description
2. Understand the requirements
3. Implement the fix
4. Write tests
5. Create a commit
```

When you run `/fix-issue 123`, Claude receives "Fix GitHub issue 123 following our coding standards..."

**Positional arguments** let you pass multiple distinct values. The skills docs show a migration skill:

```yaml
---
name: migrate-component
description: Migrate a component from one framework to another
---

Migrate the $0 component from $1 to $2.
Preserve all existing behavior and tests.
```

Running `/migrate-component SearchBar React Vue` replaces `$0` with `SearchBar`, `$1` with `React`, and `$2` with `Vue`.

**Important behavior**: If you invoke a skill with arguments but the skill content doesn't include `$ARGUMENTS`, Claude Code appends `ARGUMENTS: <your input>` to the end of the skill content. Claude still sees what you typed -- it's just appended rather than substituted inline.

#### The `argument-hint` Frontmatter Field

The `argument-hint` field shows users what arguments are expected during autocomplete:

```yaml
---
name: investigate-issue
argument-hint: "[issue-number]"
---
```

When a user types `/investigate-issue` and pauses, the autocomplete shows `[issue-number]` as a hint. This guides usage without enforcing a specific format.

### Dynamic Context Injection with `!`command``

The `` !`command` `` syntax runs shell commands **before** the skill content is sent to Claude. The command output replaces the placeholder, so Claude receives actual data, not the command itself.

This is the skills docs example -- a PR summary skill that fetches live data:

```yaml
---
name: pr-summary
description: Summarize changes in a pull request
context: fork
agent: Explore
allowed-tools: Bash(gh *)
---

## Pull request context
- PR diff: !`gh pr diff`
- PR comments: !`gh pr view --comments`
- Changed files: !`gh pr diff --name-only`

## Your task
Summarize this pull request...
```

When this skill runs:
1. Each `` !`command` `` executes immediately (before Claude sees anything)
2. The output replaces the placeholder in the skill content
3. Claude receives the fully-rendered prompt with actual PR data

**This is preprocessing, not something Claude executes.** Claude only sees the final result. The distinction matters: if you write `` !`gh issue view 42` ``, the `gh` command runs in your terminal and the output gets pasted into the skill prompt. Claude never runs `gh issue view 42` itself.

You can combine arguments with dynamic context for powerful parameterized queries:

```
!`gh issue view $0`
```

This runs `gh issue view` with whatever the user passed as the first argument. If the user types `/investigate-issue 42`, the command becomes `gh issue view 42`, runs in your terminal, and the output replaces the entire `` !`...` `` placeholder.

### Running Skills in a Subagent with `context: fork`

Adding `context: fork` to your frontmatter runs the skill in an isolated subagent context. The skill content becomes the prompt that drives the subagent. The subagent does **not** have access to your conversation history.

From the skills docs:

> `context: fork` only makes sense for skills with explicit instructions. If your skill contains guidelines like "use these API conventions" without a task, the subagent receives the guidelines but no actionable prompt, and returns without meaningful output.

This is the key insight: **reference content** (Course 2) should run inline. **Task content** with explicit steps benefits from forking when the task is self-contained and you don't want its output consuming your main conversation context.

#### Why Fork?

The subagents docs explain the core benefits:

- **Preserve context**: Keep exploration and implementation out of your main conversation
- **Enforce constraints**: Limit which tools a subagent can use
- **Specialize behavior**: Use focused system prompts for specific domains
- **Control costs**: Route tasks to faster, cheaper models like Haiku

This is your first taste of a recurring design decision: **should this work happen in the main session (as a skill) or in an isolated context (as a subagent)?** For a full decision framework covering skills, sub-agents, and agent teams, see [`courses/references/choosing-the-right-mode.md`](../references/choosing-the-right-mode.md). For now, the rule of thumb is: fork when the task is self-contained and its intermediate output would clutter your main conversation.

For the `investigate-issue` skill, forking makes sense because:
1. Issue investigation involves reading many files, running commands, and generating verbose output -- you don't want all that in your main context
2. The investigation is self-contained: give it an issue number, get back a summary
3. You can restrict tools to read-only operations for safety

#### The `agent` Field

The `agent` field specifies which subagent configuration to use:

```yaml
---
context: fork
agent: Explore
---
```

Options include built-in agents (`Explore`, `Plan`, `general-purpose`) or any custom subagent from `.claude/agents/`. If omitted, uses `general-purpose`.

From the subagents docs, the built-in agents have different capabilities:

| Agent | Model | Tools | Best for |
|---|---|---|---|
| **Explore** | Haiku (fast) | Read-only (no Write/Edit) | File discovery, code search, codebase exploration |
| **Plan** | Inherits | Read-only (no Write/Edit) | Codebase research for planning |
| **general-purpose** | Inherits | All tools | Complex research, multi-step operations, code modifications |

For the `investigate-issue` skill, we use `Explore` because investigation is a read-only operation: we're gathering information, not making changes.

#### How `context: fork` + `agent` Work Together

The skills docs provide a table showing how skills and subagents relate:

| Approach | System prompt | Task | Also loads |
|---|---|---|---|
| Skill with `context: fork` | From agent type (`Explore`, `Plan`, etc.) | SKILL.md content | CLAUDE.md |
| Subagent with `skills` field | Subagent's markdown body | Claude's delegation message | Preloaded skills + CLAUDE.md |

With `context: fork`, you write the task in your skill and pick an agent type to execute it. The agent's built-in system prompt provides the base behavior, and your SKILL.md content becomes the task it executes.

### Controlling Tools with `allowed-tools`

The `allowed-tools` field limits which tools Claude can use when a skill is active. From the skills docs:

```yaml
---
name: safe-reader
description: Read files without making changes
allowed-tools: Read, Grep, Glob
---
```

For skills that run in a forked context, `allowed-tools` restricts what the subagent can do. This is important for safety: an investigation skill shouldn't be able to edit files or make commits.

The `allowed-tools` field supports parameterized tool access. For example:

```yaml
allowed-tools: Bash(gh *), Read, Grep, Glob
```

This allows the subagent to run any `gh` command via Bash, plus read, search, and glob operations -- but blocks file writes, edits, and arbitrary Bash commands.

### String Substitutions

Skills support string substitution for dynamic values beyond arguments. From the skills docs:

| Variable | Description |
|---|---|
| `$ARGUMENTS` | All arguments passed when invoking the skill |
| `$ARGUMENTS[N]` | Access a specific argument by 0-based index |
| `$N` | Shorthand for `$ARGUMENTS[N]` |
| `${CLAUDE_SESSION_ID}` | The current session ID |

The `${CLAUDE_SESSION_ID}` substitution is useful for logging or creating session-specific files:

```yaml
---
name: session-logger
description: Log activity for this session
---

Log the following to logs/${CLAUDE_SESSION_ID}.log:

$ARGUMENTS
```

### Controlling Invocation: The Full Picture

Course 2 introduced `disable-model-invocation` and `user-invocable`. Now let's see all the invocation controls together, since advanced skills often combine several:

| Field | Effect | Use case |
|---|---|---|
| `disable-model-invocation: true` | Only user can invoke via `/name` | Skills with side effects (deploy, send-message) |
| `user-invocable: false` | Only Claude can invoke | Background knowledge (legacy-system-context) |
| `context: fork` | Runs in isolated subagent | Self-contained tasks that produce verbose output |
| `allowed-tools` | Restricts available tools | Safety constraints (read-only investigation) |
| `agent` | Chooses execution environment | Match agent capabilities to the task |

The `investigate-issue` skill you'll build combines most of these:
- `disable-model-invocation: true` -- user controls when to investigate
- `context: fork` -- investigation runs in isolation
- `agent: Explore` -- uses the fast, read-only Explore agent
- `allowed-tools: Bash(gh *), Read, Grep, Glob` -- can read files and run `gh`, but can't edit anything

### Permission Rules for Skills

The skills docs describe how to control which skills Claude can invoke using permission rules:

```
# Allow only specific skills
Skill(commit)
Skill(review-pr *)

# Deny specific skills
Skill(deploy *)
```

Permission syntax: `Skill(name)` for exact match, `Skill(name *)` for prefix match with any arguments. This is useful in team settings where you want to limit which skills are available.

## Key References
- Skills docs: "Pass arguments to skills" section -- `$ARGUMENTS`, `$ARGUMENTS[N]`, `$N` shorthand
- Skills docs: "Inject dynamic context" section -- `` !`command` `` preprocessing syntax
- Skills docs: "Run skills in a subagent" section -- `context: fork`, `agent` field, capability table
- Skills docs: "Restrict tool access" section -- `allowed-tools` field
- Skills docs: "Available string substitutions" section -- `${CLAUDE_SESSION_ID}`
- Subagents docs: "Built-in subagents" section -- Explore, Plan, general-purpose agents
- Skills docs: "Restrict Claude's skill access" section -- Permission rules for skills

## What You're Building

An **investigate-issue** skill that investigates GitHub issues in a forked Explore agent. This demonstrates Course 5 concepts because:

- It accepts **arguments** (`$0` for the issue number) -- parameterized invocation
- It uses **dynamic context injection** (`` !`gh issue view $0` ``) -- live GitHub data preprocessing
- It runs in a **forked subagent** (`context: fork` + `agent: Explore`) -- isolated execution
- It restricts **tools** (`allowed-tools: Bash(gh *), Read, Grep, Glob`) -- read-only safety
- It uses `disable-model-invocation: true` -- user-controlled invocation only
- It includes a **reference file** with an investigation checklist -- building on Course 3's pattern
- It uses `argument-hint` -- guiding users on expected input

Here's the file structure:

```
investigate-issue/
├── SKILL.md                              # Investigation workflow with dynamic context
└── references/
    └── investigation-checklist.md        # Structured investigation methodology
```

## Walkthrough

### Step 1: Understand the design decisions

Each frontmatter field serves a specific purpose:

| Field | Value | Why |
|---|---|---|
| `name` | `investigate-issue` | Matches folder name, kebab-case |
| `description` | Investigates GitHub issues... | Follows `[What] + [When] + [Capabilities]` formula |
| `disable-model-invocation` | `true` | User controls when to investigate -- Claude shouldn't auto-trigger |
| `context` | `fork` | Investigation is verbose; keep it out of main conversation |
| `agent` | `Explore` | Read-only exploration; fast Haiku model for cost efficiency |
| `allowed-tools` | `Bash(gh *), Read, Grep, Glob` | Can read files and query GitHub, but can't edit anything |
| `argument-hint` | `[issue-number]` | Shows users what to pass |

### Step 2: Study the dynamic context pattern

The SKILL.md uses `` !`gh issue view $0 --json title,body,labels,assignees,comments` `` to fetch live issue data. When the user runs `/investigate-issue 42`:

1. `$0` is replaced with `42`
2. The command `gh issue view 42 --json title,body,labels,assignees,comments` runs in the user's terminal
3. The JSON output replaces the `` !`...` `` placeholder
4. Claude (in the forked Explore agent) receives the skill content with the actual issue data embedded
5. Claude follows the investigation steps using that data as context

This means Claude never has to run `gh issue view` itself -- the data is already there. This is faster and more reliable than having Claude discover and run the command.

### Step 3: Study the reference file

Open `courses/course-05-advanced-features/skill/investigate-issue/references/investigation-checklist.md`. This contains a structured methodology for investigating issues -- categories of investigation, what to look for, how to organize findings.

The SKILL.md references it: "For a structured investigation approach, consult `references/investigation-checklist.md`." This keeps the main instructions focused on the workflow while the detailed methodology lives in a separate file (Course 3's progressive disclosure Level 3 pattern).

### Step 4: Install the skill

Copy the skill to your personal skills directory:

```bash
cp -r courses/course-05-advanced-features/skill/investigate-issue ~/.claude/skills/investigate-issue
```

Verify the structure:

```bash
ls -R ~/.claude/skills/investigate-issue/
```

You should see:
```
SKILL.md
references/

references:
investigation-checklist.md
```

### Step 5: Test argument passing

Open Claude Code in a GitHub repository (or any directory where `gh` is authenticated).

**Test basic invocation with an argument:**

```
/investigate-issue 1
```

Replace `1` with an actual issue number from your repo. Watch for:
1. The skill loads (you can see the skill name in the output header)
2. The issue data appears in the context (from the dynamic `` !`gh issue view` `` preprocessing)
3. Claude investigates the issue using the Explore agent's read-only tools
4. A summary is returned to your main conversation

**Test with a non-existent issue:**

```
/investigate-issue 99999
```

The `gh` command will fail or return an error. Watch how the skill handles this -- the preprocessed output will contain the error message, and Claude should report it rather than crashing.

### Step 6: Verify forked context

After running the investigation, notice:
- Your main conversation context is clean -- the investigation details (file reads, grep searches) are not in your history
- You received a summary of findings, not the raw verbose output
- The investigation used the Explore agent (Haiku model -- fast and cheap)

To confirm it ran in a fork, try running the investigation and then asking Claude in your main conversation: "What files did you just read?" Claude shouldn't know -- the file reads happened in the subagent's isolated context.

### Step 7: Verify tool restrictions

The skill sets `allowed-tools: Bash(gh *), Read, Grep, Glob`. This means the subagent:
- **Can**: Read files, search code, run `gh` commands
- **Cannot**: Edit files, write new files, run arbitrary bash commands

The investigation should be purely read-only. If the issue suggests a code fix, the investigation should describe what to fix and where -- but the actual editing happens in your main conversation after you review the findings.

### Step 8: Test the argument-hint

Start typing `/investigate-issue` in Claude Code and pause. The autocomplete should show `[issue-number]` as a hint, guiding you on what to pass.

### Step 9: Build a second dynamic skill (guided exercise)

To solidify the concepts, create a simpler skill that uses arguments and dynamic context. Create `~/.claude/skills/pr-review/SKILL.md`:

```yaml
---
name: pr-review
description: Review a specific pull request by number
disable-model-invocation: true
context: fork
agent: Explore
allowed-tools: Bash(gh *), Read, Grep, Glob
argument-hint: "[pr-number]"
---

# Pull Request Review

## Context
PR details: !`gh pr view $0 --json title,body,additions,deletions,changedFiles`
PR diff: !`gh pr diff $0`
PR review comments: !`gh pr view $0 --comments`

## Task
Review this pull request thoroughly:

1. **Summary**: What does this PR do? (2-3 sentences)
2. **Changes**: List the key changes by file
3. **Concerns**: Flag any potential issues (bugs, security, performance)
4. **Questions**: What would you ask the author?
5. **Verdict**: Approve, request changes, or needs discussion
```

Test with `/pr-review 1` (replace with a real PR number). Compare this to the `code-review-checklist` from Course 2 -- this version is parameterized and isolated.

## Exercises

1. **Add a second dynamic context command**: Modify the `investigate-issue` skill to also fetch related PRs with `` !`gh pr list --search "issue:$0" --json number,title,state` ``. Test that related PRs appear in the investigation context when they exist.

2. **Create a multi-argument skill**: Build a `compare-branches` skill at `~/.claude/skills/compare-branches/SKILL.md` that takes two branch names:
   ```yaml
   ---
   name: compare-branches
   description: Compare two git branches
   disable-model-invocation: true
   argument-hint: "[base-branch] [compare-branch]"
   ---

   Compare branches $0 and $1:
   Diff stats: !`git diff --stat $0...$1`
   Commit log: !`git log --oneline $0...$1`
   ```
   Test with `/compare-branches main feature-branch`.

3. **Test `context: fork` vs inline**: Take the `investigate-issue` skill and create a copy without `context: fork` (remove the `context` and `agent` fields). Run both versions against the same issue. Compare: How does your main conversation context differ? Which produces a more focused result? This demonstrates why forking matters for verbose, exploratory tasks.

4. **Experiment with different agents**: Change the `agent` field from `Explore` to `general-purpose`. Run the investigation again. Note the differences: `general-purpose` inherits your current model (likely Opus or Sonnet -- more capable but slower and more expensive) and has access to all tools including Write and Edit. Which agent is more appropriate for read-only investigation?

5. **Build a `session-logger` skill**: Create a skill that uses `${CLAUDE_SESSION_ID}`:
   ```yaml
   ---
   name: session-logger
   description: Log notable findings from this session
   disable-model-invocation: true
   ---

   Append the following entry to `session-logs/${CLAUDE_SESSION_ID}.md`:

   ## Entry: $ARGUMENTS

   Timestamp: Current date and time
   Context: What we were working on
   Finding: The notable item described above
   ```
   Test with `/session-logger Found race condition in auth middleware`. Verify the log file is created with the session ID in the filename.

6. **Permission rules experiment**: Add a deny rule for the investigate-issue skill in your permissions (via `/permissions`):
   ```
   Skill(investigate-issue *)
   ```
   Verify that Claude can no longer invoke it even if you ask explicitly. Remove the rule when done. This demonstrates how teams can control skill access.

## Verification Checklist

- [ ] `~/.claude/skills/investigate-issue/SKILL.md` exists with correct casing
- [ ] `~/.claude/skills/investigate-issue/references/investigation-checklist.md` exists
- [ ] YAML frontmatter has valid `---` delimiters
- [ ] `name` field is `investigate-issue` (kebab-case, matches folder)
- [ ] `description` follows `[What] + [When] + [Capabilities]` formula
- [ ] No XML angle brackets in frontmatter
- [ ] `context: fork` is set in frontmatter
- [ ] `agent: Explore` is set in frontmatter
- [ ] `allowed-tools` restricts to read-only + `gh` commands
- [ ] `disable-model-invocation: true` prevents automatic triggering
- [ ] `argument-hint: "[issue-number]"` is set
- [ ] SKILL.md is under 500 lines
- [ ] SKILL.md references the investigation checklist with clear "when to consult" instructions
- [ ] Running `/investigate-issue <number>` invokes the skill with the issue data
- [ ] Dynamic context (`` !`gh issue view $0` ``) preprocesses actual GitHub data
- [ ] The skill runs in a forked Explore agent (main conversation context stays clean)
- [ ] Tool restrictions prevent file editing within the investigation
- [ ] Invalid issue numbers are handled gracefully (error message, not crash)
- [ ] The investigation returns a structured summary to the main conversation

## What's Next

In **Course 6: Multi-Step Workflows with Error Handling**, you'll learn:
- Sequential workflow orchestration (the PDF's Pattern 1) with explicit step ordering and dependencies
- Iterative refinement (the PDF's Pattern 3) with draft-validate-fix-re-validate loops
- Validation gates: proceeding only if the previous step succeeded
- Robust error handling with specific diagnostics, not generic "validation failed" messages
- Using `allowed-tools` for safety in automated workflows
- You'll build a `project-scaffolder` skill with validation scripts and multiple project templates

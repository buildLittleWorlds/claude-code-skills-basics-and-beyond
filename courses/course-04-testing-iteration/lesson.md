# Course 4: Testing, Iteration, and the Feedback Loop
**Level**: Intermediate | **Estimated time**: 40 min

## Prerequisites
- Completed **Course 1: Your First Skill in Five Minutes** (skill folder basics, YAML frontmatter)
- Completed **Course 2: Crafting Descriptions and Trigger Phrases** (description formula, trigger phrases, under/over-triggering)
- Completed **Course 3: Full Skill Anatomy** (scripts, references, assets, progressive disclosure L3)
- You have the `daily-standup`, `code-review-checklist`, and `meeting-to-actions` skills installed
- You're comfortable creating and installing skills from scratch

## Concepts

### Why Testing Matters for Skills

In Courses 1-3, you built skills and tested them informally -- try a prompt, see if it works, move on. That's fine for getting started, but real-world skills need systematic testing. The PDF guide (Chapter 3) frames the problem clearly:

> Skills can be tested at varying levels of rigor depending on your needs.

It then lists three testing approaches:

1. **Manual testing in Claude.ai** -- Run queries directly and observe behavior. Fast iteration, no setup required.
2. **Scripted testing in Claude Code** -- Automate test cases for repeatable validation across changes.
3. **Programmatic testing via skills API** -- Build evaluation suites that run systematically against defined test sets.

For this course, you'll focus on manual testing with a structured approach. The key insight is that "testing" doesn't mean writing Python unit tests for your SKILL.md. It means designing a suite of queries that verify your skill behaves correctly across three distinct areas.

### The Three Testing Areas

The PDF guide (Chapter 3, p.15-16) defines three areas that every skill should be tested against. These aren't optional categories -- each catches different classes of problems.

#### Area 1: Triggering Tests

**Goal**: Ensure your skill loads at the right times.

This area tests whether your description is properly tuned. You're testing the *first level* of progressive disclosure from Course 1 -- the frontmatter that Claude reads to decide whether to load the skill.

The PDF provides three specific test cases:

- **Triggers on obvious tasks** -- The exact phrases in your description
- **Triggers on paraphrased requests** -- Reworded versions of those phrases
- **Doesn't trigger on unrelated topics** -- Queries that shouldn't activate the skill

Here's the example test suite from the PDF:

```
Should trigger:
- "Help me set up a new ProjectHub workspace"
- "I need to create a project in ProjectHub"
- "Initialize a ProjectHub project for Q4 planning"

Should NOT trigger:
- "What's the weather in San Francisco?"
- "Help me write Python code"
- "Create a spreadsheet" (unless ProjectHub skill handles sheets)
```

Notice the structure: **Should trigger** includes both exact matches and paraphrases. **Should NOT trigger** includes completely unrelated queries AND edge cases (the spreadsheet example might or might not be relevant depending on the skill's scope).

#### Area 2: Functional Tests

**Goal**: Verify the skill produces correct outputs.

Once the skill triggers, does it actually do the right thing? The PDF lists four test cases:

- **Valid outputs generated** -- Does the output match the expected format and content?
- **API calls succeed** -- Do any tool invocations (git commands, scripts) work correctly?
- **Error handling works** -- Does the skill handle bad input gracefully?
- **Edge cases covered** -- Does it handle unusual but valid inputs?

The PDF gives a structured example using Given/When/Then format:

```
Test: Create project with 5 tasks
Given: Project name "Q4 Planning", 5 task descriptions
When: Skill executes workflow
Then:
    - Project created in ProjectHub
    - 5 tasks created with correct properties
    - All tasks linked to project
    - No API errors
```

For the `pr-description` skill you'll build in this course, functional tests verify things like: Does it read the git diff correctly? Does the output follow the PR template? Does it handle an empty diff without crashing?

#### Area 3: Performance Comparison

**Goal**: Prove the skill improves results vs. a baseline.

This is the test area most people skip, but it's the one that demonstrates value. The PDF provides a concrete baseline comparison format:

```
Without skill:
- User provides instructions each time
- 15 back-and-forth messages
- 3 failed API calls requiring retry
- 12,000 tokens consumed

With skill:
- Automatic workflow execution
- 2 clarifying questions only
- 0 failed API calls
- 6,000 tokens consumed
```

You don't need to measure exact token counts for this course. The important metrics to observe are:

| Metric | What to watch |
|---|---|
| **Message count** | How many back-and-forth messages before you get a useful result? |
| **Failed tool calls** | Does Claude try commands that don't work? Retry things? |
| **Output quality** | Is the output consistent? Does it follow your template? |
| **Manual corrections** | How many things do you have to fix by hand after the skill runs? |

### The Pro Tip: Iterate on a Single Task First

The PDF guide highlights a critical workflow tip:

> We've found that the most effective skill creators iterate on a single challenging task until Claude succeeds, then extract the winning approach into a skill. This leverages Claude's in-context learning and provides faster signal than broad testing. Once you have a working foundation, expand to multiple test cases for coverage.

This means: before writing 15 test cases, pick ONE hard case and get it working perfectly. Then formalize the approach into your SKILL.md. Then expand your test coverage.

For the `pr-description` skill, this means: first manually write one excellent PR description with Claude's help, then capture that process as a skill, then test it across different types of PRs.

### Diagnosing Under-Triggering vs Over-Triggering

The PDF guide (Chapter 3, p.17) provides a diagnostic framework. These are the signals to watch for after your initial round of testing.

**Under-triggering signals:**
- Skill doesn't load when it should
- Users manually enabling it (typing `/skill-name` because automatic triggering misses)
- Support questions about when to use it

**Solution from the PDF:**
> Add more detail and nuance to the description -- this may include keywords particularly for technical terms.

In practice this means: go back to the description formula from Course 2 (`[What] + [When] + [Capabilities]`) and add more trigger phrases to the `[When]` component. If users are saying "write a PR summary" but your description only mentions "PR description", add "PR summary" to the description.

**Over-triggering signals:**
- Skill loads for irrelevant queries
- Users disabling it
- Confusion about purpose

**Solution from the PDF:**
> Add negative triggers, be more specific.

The skills docs echo this with two specific fixes:

1. "Make the description more specific" (from the Troubleshooting section)
2. "Add `disable-model-invocation: true` if you only want manual invocation"

### Execution Issues and Iteration

The PDF also identifies a third category of problems -- the skill triggers correctly but produces poor results:

**Execution issue signals:**
- Inconsistent results across invocations
- API call failures or tool errors
- User corrections needed after the skill runs

**Solution from the PDF:**
> Improve instructions, add error handling.

This maps directly to Course 2's lesson on specific instructions: replace vague directives with exact commands and expected outputs. If Claude keeps running the wrong git command, don't write "get the diff" -- write "run `git diff --cached --stat` to get a summary of staged changes."

### The `disable-model-invocation` Field

The skills docs describe this frontmatter field in detail:

```yaml
---
name: deploy
description: Deploy the application to production
disable-model-invocation: true
---
```

When `disable-model-invocation: true` is set:

| Behavior | Effect |
|---|---|
| Description in system prompt | **No** -- Claude doesn't even see it |
| Claude can invoke automatically | **No** -- skill is invisible to Claude |
| User can invoke with `/name` | **Yes** -- still works as a slash command |

Use this for skills with side effects -- deployment, sending messages, publishing -- where you want to control the timing. The `pr-description` skill you'll build is a good candidate for this field if you find it over-triggers during testing, since generating PR descriptions has context requirements (you need to be in a git repo with staged changes).

### The Character Budget

From the skills docs Troubleshooting section:

> Skill descriptions are loaded into context so Claude knows what's available. If you have many skills, they may exceed the character budget. The budget scales dynamically at 2% of the context window, with a fallback of 16,000 characters.

This means if you have 20 skills with 800-character descriptions, you're at 16,000 characters -- the fallback limit. If you install more skills, some get excluded entirely. You can check this:

```
Run /context in Claude Code and look for a warning about excluded skills.
```

If you hit this limit, override it by setting the `SLASH_COMMAND_TOOL_CHAR_BUDGET` environment variable. But the better fix is to keep descriptions concise.

### The Iteration Loop

Putting it all together, here's the testing and iteration process:

```
1. Write initial SKILL.md
2. Run triggering tests (5-8 queries)
   ├── Under-triggers? → Expand description keywords
   └── Over-triggers? → Narrow description, add specificity
3. Run functional tests (5-8 queries)
   ├── Wrong output? → Fix instructions, add examples
   └── Tool errors? → Fix commands, add error handling
4. Run performance comparison (with vs without)
   ├── No improvement? → Rethink the skill's value
   └── Clear improvement? → Document the baseline
5. Repeat steps 2-4 for each iteration round
```

The PDF recommends at least two iteration rounds before considering a skill "ready."

## Key References
- PDF Guide: Chapter 3 "Testing and Iteration" (pp. 14-17) -- Three testing areas, baseline comparison, iteration signals
- Skills docs: "Troubleshooting" section -- Skill not triggering, triggers too often, character budget
- Skills docs: "Control who invokes a skill" section -- `disable-model-invocation` field
- Course 2 lesson: Description formula and trigger phrases (foundation for triggering tests)

## What You're Building

A **pr-description** skill that generates pull request descriptions from git diffs. This demonstrates Course 4 concepts because:

- It has **clear triggering criteria** -- easy to design should/shouldn't trigger tests
- It depends on **git tool calls** -- functional tests can verify the right commands run
- It produces **structured output** -- you can objectively compare output quality with vs without the skill
- It benefits from **performance comparison** -- without the skill, users write PR descriptions manually or get inconsistent results from Claude
- The test plan exercises all three testing areas systematically

You'll also create a **test-plan.md** with 15+ organized test queries -- this is the main deliverable that demonstrates the testing concepts.

## Walkthrough

### Step 1: Understand the skill design

The `pr-description` skill reads git changes and generates a formatted PR description. It uses:

- `git diff --cached` (or `git diff` if nothing is staged) to read changes
- `git log` to understand recent commit context
- A template in `assets/pr-template.md` for consistent output formatting

Study the SKILL.md in `courses/course-04-testing-iteration/skill/pr-description/SKILL.md` and notice:

1. **Description**: Includes trigger phrases like "PR description", "pull request", "describe my changes"
2. **Instructions**: Specific git commands with fallback behavior
3. **Template reference**: Points to `assets/pr-template.md`
4. **Error handling**: What to do when there's no diff, no git repo, etc.

### Step 2: Install the skill

Copy the skill to your personal skills directory:

```bash
cp -r courses/course-04-testing-iteration/skill/pr-description ~/.claude/skills/pr-description
```

Verify the structure:

```bash
ls -R ~/.claude/skills/pr-description/
```

You should see:
```
SKILL.md
assets/

assets:
pr-template.md
```

### Step 3: Study the test plan

Open `courses/course-04-testing-iteration/test-plan.md`. This is the core deliverable of the course -- a structured test plan organized by the three testing areas.

Notice how the test plan is organized:

1. **Triggering tests** -- Split into "Should trigger" and "Should NOT trigger" with expected behavior for each
2. **Functional tests** -- Specific scenarios with Given/When/Then structure
3. **Edge case tests** -- Unusual inputs and error conditions
4. **Performance comparison** -- Before/after metrics to track

### Step 4: Run triggering tests

Open Claude Code in a git repository with some changes (staged or unstaged).

**Should-trigger tests** -- try each of these and record whether the skill activates:

```
Write a PR description for my changes
```

```
Generate a pull request description
```

```
Describe my changes for a PR
```

```
Help me write a description for this pull request
```

```
Summarize my changes
```

For each query, note:
- Did the skill trigger? (Look for structured output following the PR template)
- If not, why? (Description mismatch? No git changes available?)

**Should-NOT-trigger tests** -- verify these don't activate the skill:

```
Write a Python function that adds two numbers
```

```
Review this code for bugs
```

```
Help me fix this merge conflict
```

Record any false triggers. If the skill activates on "review this code," your description overlaps with the `code-review-checklist` skill from Course 2.

### Step 5: Run functional tests

For these, you need a git repo with actual changes. The simplest approach:

1. Create a test repo: `mkdir /tmp/test-pr && cd /tmp/test-pr && git init`
2. Create a file, commit it, then make changes
3. Run the skill against those changes

**Test: Simple one-file change**

```bash
# Setup (run in terminal, not in Claude Code)
mkdir -p /tmp/test-pr && cd /tmp/test-pr && git init
echo "hello" > app.py && git add . && git commit -m "initial"
echo "hello world" > app.py && git add .
```

Then in Claude Code (from `/tmp/test-pr`):
```
Write a PR description for my staged changes
```

Verify: Does the output follow the template? Does it mention `app.py`? Does it describe the change accurately?

**Test: Multi-file change**

Make changes across 3+ files and verify the skill summarizes all of them, not just the first.

**Test: No changes available**

In a clean repo with no changes:
```
Write a PR description
```

Verify: Does the skill handle this gracefully? It should tell you there are no changes to describe, not crash or produce an empty template.

### Step 6: Run your first iteration round

Based on your triggering and functional test results, identify problems:

**If under-triggering**: Add more keywords to the description. Common phrases users say that the skill should catch:
- "PR summary"
- "what should I put in the PR"
- "describe these changes"
- "write up my changes"

**If over-triggering**: Make the description more specific. Add context like "for a git pull request" to distinguish from general "describe my changes" requests.

**If functional issues**: Fix the instructions. Common problems:
- Claude runs `git diff` when changes are staged (should use `git diff --cached`)
- Output doesn't follow the template format
- Claude doesn't summarize -- it just dumps the diff

Make your changes to the SKILL.md, then re-run the failing tests.

### Step 7: Run a second iteration round

After fixing the issues from round 1, re-run ALL tests (not just the ones that failed). This is important because:

- Fixing under-triggering might cause over-triggering
- Fixing instructions might break the output format
- Changes to one step might affect downstream steps

Document what changed between rounds 1 and 2. The PDF recommends at least two rounds before considering a skill ready.

### Step 8: Run the performance comparison

Do the same task with and without the skill. In a repo with real changes:

**Without the skill** (temporarily rename the folder):
```bash
mv ~/.claude/skills/pr-description ~/.claude/skills/_pr-description-disabled
```

Ask Claude: "Write a PR description for my changes." Note:
- How many messages before you get a usable result?
- Does Claude ask for the right context, or do you have to guide it?
- Is the output format consistent with how you'd write a PR?

**With the skill** (restore it):
```bash
mv ~/.claude/skills/_pr-description-disabled ~/.claude/skills/pr-description
```

Ask the same question. Compare:
- Message count (likely fewer with the skill)
- Output format consistency (template vs freeform)
- Whether Claude reads the right git information without prompting

## Exercises

1. **Complete the test plan**: Run every query in `test-plan.md` and fill in the "Actual Result" column. Document any surprises -- queries that triggered when they shouldn't have, or output that didn't match expectations.

2. **Two iteration rounds**: Based on your test results, make at least two rounds of changes to the `pr-description` SKILL.md. For each round, document:
   - What problem you found
   - What change you made (description? instructions? template?)
   - Whether the fix worked (re-test the failing queries)
   - Whether the fix broke anything else (re-test passing queries)

3. **Test the `disable-model-invocation` field**: Add `disable-model-invocation: true` to the pr-description skill's frontmatter. Verify that:
   - Typing "write a PR description" no longer triggers the skill
   - Typing `/pr-description` still works
   - Remove the field when done (or keep it if you prefer manual-only invocation)

4. **Apply testing to an earlier skill**: Pick either `daily-standup` or `code-review-checklist` from earlier courses. Write a test plan with at least 10 queries (5 triggering, 5 functional). Run all tests and document one iteration round of improvements.

5. **Measure the character budget**: Install all four skills from courses 1-4. Ask Claude "What skills are available?" and verify all four appear. Then run `/context` and check if there are any warnings about excluded skills. Calculate the total character count of all your descriptions combined -- are you approaching the 16,000-character fallback limit?

## Verification Checklist

- [ ] `~/.claude/skills/pr-description/SKILL.md` exists with correct casing
- [ ] `~/.claude/skills/pr-description/assets/pr-template.md` exists
- [ ] YAML frontmatter has valid `---` delimiters
- [ ] `name` field is `pr-description` (kebab-case, matches folder)
- [ ] `description` follows `[What] + [When] + [Capabilities]` formula
- [ ] No XML angle brackets in frontmatter
- [ ] SKILL.md is under 500 lines
- [ ] `test-plan.md` has 15+ test queries organized by the three testing areas
- [ ] All triggering tests (should-trigger) activate the skill
- [ ] All triggering tests (should-NOT-trigger) do NOT activate the skill
- [ ] Functional tests produce output matching the PR template
- [ ] The skill handles "no changes" gracefully (no crash, clear message)
- [ ] You've completed at least two iteration rounds with documented changes
- [ ] Performance comparison shows improvement with the skill vs without
- [ ] The skill appears when you ask "What skills are available?"

## What's Next

In **Course 5: Advanced Skill Features -- Arguments, Dynamic Context, Subagent Execution**, you'll learn:
- Passing arguments to skills with `$ARGUMENTS`, `$ARGUMENTS[N]`, and `$N` shorthand
- Injecting dynamic context with `!`command`` preprocessing syntax
- Running skills in isolated subagent contexts with `context: fork` and the `agent` field
- Controlling tools with `allowed-tools`
- String substitutions like `${CLAUDE_SESSION_ID}`
- You'll build an `investigate-issue` skill that uses a forked Explore agent to research GitHub issues

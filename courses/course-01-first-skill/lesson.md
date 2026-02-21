# Course 1: Your First Skill in Five Minutes
**Level**: Beginner | **Estimated time**: 15 min

## Prerequisites
- Claude Code installed and working (`claude` command available in your terminal)
- A text editor
- No prior skill-building experience needed -- this is where you start

## Concepts

### What is a Skill?

A skill is a set of instructions -- packaged as a simple folder -- that teaches Claude how to handle specific tasks or workflows. Instead of re-explaining your preferences, processes, and domain expertise in every conversation, you teach Claude once and benefit every time.

From the official guide:

> Skills are powerful when you have repeatable workflows: generating frontend designs from specs, conducting research with consistent methodology, creating documents that follow your team's style guide, or orchestrating multi-step processes.

At its simplest, a skill is just a folder containing one required file:

```
your-skill-name/
└── SKILL.md          # Required - main skill file
```

That's it. One folder, one file. Later courses will add scripts, references, and assets -- but every skill starts here.

### The Kitchen Analogy: MCP vs Skills

The PDF guide introduces a useful mental model:

- **MCP provides the professional kitchen**: access to tools, ingredients, and equipment. MCP connects Claude to external services (Notion, Asana, Linear, GitHub, etc.) and provides real-time data access and tool invocation.

- **Skills provide the recipes**: step-by-step instructions on how to create something valuable. Skills teach Claude *how* to use those tools effectively, capturing workflows and best practices.

Together they enable users to accomplish complex tasks without figuring out every step themselves. Here's how they compare:

| MCP (Connectivity) | Skills (Knowledge) |
|---|---|
| Connects Claude to your service (Notion, Asana, Linear, etc.) | Teaches Claude how to use your service effectively |
| Provides real-time data access and tool invocation | Captures workflows and best practices |
| What Claude *can* do | How Claude *should* do it |

**Important**: You don't need MCP to build skills. Skills work perfectly as standalone instructions for Claude. The kitchen analogy just shows how the two systems complement each other.

### Progressive Disclosure: How Claude Loads Skills

Skills use a three-level system to minimize token usage while maintaining specialized expertise:

1. **First level (YAML frontmatter)**: Always loaded in Claude's system prompt. Provides just enough information for Claude to know *when* each skill should be used without loading all of it into context. This is the `name` and `description` you write between the `---` markers.

2. **Second level (SKILL.md body)**: Loaded when Claude thinks the skill is relevant to the current task. Contains the full instructions and guidance.

3. **Third level (Linked files)**: Additional files bundled within the skill directory that Claude can choose to navigate and discover only as needed. (Covered in Course 3.)

For this first course, you only need to worry about levels 1 and 2: write a good frontmatter description so Claude knows when to load your skill, and write clear instructions in the body.

### Where Skills Live

Where you store a skill determines who can use it:

| Location | Path | Applies to |
|---|---|---|
| Personal | `~/.claude/skills/<skill-name>/SKILL.md` | All your projects |
| Project | `.claude/skills/<skill-name>/SKILL.md` | This project only |
| Plugin | `<plugin>/skills/<skill-name>/SKILL.md` | Where plugin is enabled |

For this course, you'll install to the **personal** location (`~/.claude/skills/`) so the skill works across all your projects.

### Critical Naming Rules

The PDF guide is explicit about these -- get them wrong and Claude won't find your skill:

**SKILL.md naming**:
- Must be exactly `SKILL.md` (case-sensitive)
- No variations: ~~SKILL.MD~~, ~~skill.md~~, ~~Skill.md~~ -- none of these work

**Skill folder naming** -- kebab-case only:
- `daily-standup` -- correct
- ~~Daily Standup~~ -- no spaces
- ~~daily_standup~~ -- no underscores
- ~~DailyStandup~~ -- no capitals

**No README.md inside skill folders**. All documentation goes in SKILL.md or in a `references/` subdirectory.

### YAML Frontmatter: The Most Important Part

The YAML frontmatter is how Claude decides whether to load your skill. It sits between `---` markers at the top of SKILL.md:

```yaml
---
name: your-skill-name
description: What it does. Use when user asks to [specific phrases].
---
```

Two key fields for your first skill:

**`name`** (recommended):
- kebab-case only (lowercase letters, numbers, hyphens)
- Should match the folder name
- Max 64 characters
- Becomes the `/slash-command` name

**`description`** (recommended):
- Follows the formula: `[What it does] + [When to use it] + [Key capabilities]`
- Under 1024 characters
- No XML angle brackets (`<` or `>`) -- these are forbidden in frontmatter for security reasons
- Include specific tasks users might say to trigger it

## Key References
- PDF Guide: Chapter 1 "Fundamentals" (pp. 4-6) -- What a skill is, progressive disclosure, kitchen analogy
- PDF Guide: Chapter 2 "Planning and Design" (pp. 10-11) -- Technical requirements, YAML frontmatter, naming rules
- Skills docs: "Getting started" and "Where skills live" sections

## What You're Building

A **daily-standup** skill that generates Yesterday/Today/Blockers standup notes. This demonstrates the concepts because:

- It's a simple, self-contained workflow (no external tools needed)
- It has a clear trigger: when someone says "standup" or "daily update"
- It produces structured output from a predictable template
- You can test it immediately by invoking `/daily-standup`

## Walkthrough

### Step 1: Create the skill directory

Create a folder for the skill in your personal skills directory:

```bash
mkdir -p ~/.claude/skills/daily-standup
```

### Step 2: Write the SKILL.md

Create the file `~/.claude/skills/daily-standup/SKILL.md` with the following content:

```yaml
---
name: daily-standup
description: Generates a structured daily standup update in Yesterday/Today/Blockers format. Use when the user says "standup", "daily update", "what did I work on", or "standup notes".
---

# Daily Standup Generator

Generate a daily standup update using the following structure.

## Format

Present the standup in this exact format:

### Yesterday
- List 2-4 completed items based on recent git activity, open files, or conversation context
- Each item should be a concrete accomplishment, not a vague status
- If no context is available, ask the user what they worked on

### Today
- List 2-4 planned items based on open issues, TODOs, or conversation context
- Frame as intentions: "Will implement...", "Plan to review...", "Going to fix..."
- If no context is available, ask the user what they plan to work on

### Blockers
- List any blockers mentioned in conversation or discovered in the project
- If none are apparent, write "No blockers" rather than inventing issues

## Rules
- Keep each bullet point to one line (under 100 characters)
- Use past tense for Yesterday, future-oriented language for Today
- Be specific: "Fixed auth token refresh bug in login.ts" not "Worked on auth"
- If you have access to git history, use `git log --oneline -10` to inform Yesterday items
- If you have access to GitHub issues, check for assigned open issues to inform Today items
```

### Step 3: Verify the file structure

Confirm your skill is in the right place:

```bash
ls -la ~/.claude/skills/daily-standup/
```

You should see exactly one file: `SKILL.md`.

### Step 4: Test with automatic triggering

Open Claude Code in any project and type a natural request that should trigger the skill:

```
Can you write my standup for today?
```

Claude should recognize the skill from the description keywords ("standup") and load it automatically. You'll see the Yesterday/Today/Blockers format in the output.

### Step 5: Test with direct invocation

You can also invoke the skill explicitly using the slash command:

```
/daily-standup
```

This loads the full skill content regardless of how you phrase the request.

### Step 6: Verify skill visibility

Ask Claude to confirm it can see your skill:

```
What skills are available?
```

You should see `daily-standup` in the list with its description.

## Exercises

1. **Modify the description**: Change the description to add a new trigger phrase (e.g., "scrum update" or "morning sync"). Re-test to confirm the new phrase triggers the skill.

2. **Change the format**: Edit the standup template to use a format your team prefers. For example, replace "Blockers" with "Risks & Dependencies", or add a "Wins" section. Test that the new format appears in output.

3. **Create a second skill**: Build a `quick-summary` skill from scratch that summarizes the current conversation in 3 bullet points. Place it in `~/.claude/skills/quick-summary/SKILL.md`. Verify it appears alongside `daily-standup` when you ask what skills are available.

4. **Test non-triggering**: Verify that unrelated prompts like "What's the weather?" or "Help me write a Python function" do NOT trigger the daily-standup skill. This confirms your description is specific enough.

## Verification Checklist

- [ ] `~/.claude/skills/daily-standup/SKILL.md` exists with exactly that casing
- [ ] The file has valid YAML frontmatter between `---` markers
- [ ] `name` field is `daily-standup` (kebab-case, matches folder)
- [ ] `description` field includes what it does AND when to use it
- [ ] No XML angle brackets (`<` or `>`) appear in the frontmatter
- [ ] Typing "write my standup" in Claude Code triggers the skill automatically
- [ ] Running `/daily-standup` invokes the skill directly
- [ ] Output follows the Yesterday/Today/Blockers format
- [ ] The skill appears when you ask "What skills are available?"

## What's Next

In **Course 2: Crafting Descriptions and Trigger Phrases**, you'll learn:
- The description formula in depth: `[What it does] + [When to use it] + [Key capabilities]`
- How to diagnose under-triggering vs over-triggering
- The difference between reference content and task content
- Progressive disclosure Level 1 vs Level 2 in detail
- You'll build a `code-review-checklist` skill with a rich description and multi-step review instructions

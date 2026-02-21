# Course 2: Crafting Descriptions and Trigger Phrases
**Level**: Beginner | **Estimated time**: 25 min

## Prerequisites
- Completed **Course 1: Your First Skill in Five Minutes**
- You have the `daily-standup` skill installed at `~/.claude/skills/daily-standup/SKILL.md`
- You understand the basics: YAML frontmatter, skill folder structure, kebab-case naming

## Concepts

### The Description Field: Your Skill's First Impression

In Course 1, you learned that the description sits in the YAML frontmatter and that Claude uses it to decide when to load a skill. Now let's understand *why* it matters so much.

From the PDF guide:

> "This metadata...provides just enough information for Claude to know when each skill should be used without loading all of it into context." This is the first level of progressive disclosure.

The description is the **only** thing Claude sees about your skill until it decides to load the full body. Every skill you install adds its description to Claude's system prompt. If you have 20 skills, Claude reads 20 descriptions at the start of every conversation. That's why the description must be:

1. **Precise enough** to trigger on the right queries
2. **Specific enough** to avoid triggering on unrelated queries
3. **Concise enough** to not waste token budget

The skills docs confirm there's a character budget: descriptions are loaded into context at 2% of the context window, with a fallback of 16,000 characters. If you have too many skills with bloated descriptions, some get excluded entirely. You can check for this by running `/context` in Claude Code.

### The Description Formula

The PDF guide provides a specific structure for effective descriptions:

```
[What it does] + [When to use it] + [Key capabilities]
```

Each piece serves a distinct purpose:

| Component | Purpose | Example |
|---|---|---|
| **What it does** | Tells Claude the skill's function | "Analyzes Figma design files and generates developer handoff documentation" |
| **When to use it** | Provides trigger conditions | "Use when user uploads .fig files, asks for 'design specs', 'component documentation', or 'design-to-code handoff'" |
| **Key capabilities** | Scopes what the skill can handle | "Handles account creation, payment setup, and subscription management" |

### Good vs Bad Descriptions: Real Examples from the PDF

The PDF guide gives concrete examples. Study these carefully -- the difference between a skill that triggers reliably and one that never fires often comes down to the description.

**Good -- specific and actionable:**
```yaml
description: Analyzes Figma design files and generates developer handoff
  documentation. Use when user uploads .fig files, asks for "design specs",
  "component documentation", or "design-to-code handoff".
```
Why it works: States what it does (analyzes Figma, generates docs), when to use it (specific file types and phrases), and scopes the capability (handoff documentation).

**Good -- includes trigger phrases:**
```yaml
description: Manages Linear project workflows including sprint planning,
  task creation, and status tracking. Use when user mentions "sprint",
  "Linear tasks", "project planning", or asks to "create tickets".
```
Why it works: Lists the actual words a user would type. Claude matches on "sprint", "Linear tasks", "create tickets" -- all natural requests.

**Good -- clear value proposition:**
```yaml
description: End-to-end customer onboarding workflow for PayFlow. Handles
  account creation, payment setup, and subscription management. Use when
  user says "onboard new customer", "set up subscription", or
  "create PayFlow account".
```
Why it works: Combines scope (what steps it handles) with specific phrases a user would say.

**Bad -- too vague:**
```yaml
# Too vague
description: Helps with projects.
```
Claude can't distinguish this from any other skill. Every request "helps with projects."

**Bad -- missing triggers:**
```yaml
# Missing triggers
description: Creates sophisticated multi-page documentation systems.
```
Tells Claude *what* but never *when*. A user asking "write me some docs" won't match because there's no trigger phrase connecting user language to the skill.

**Bad -- too technical, no user triggers:**
```yaml
# Too technical
description: Implements the Project entity model with hierarchical relationships.
```
Written for developers reading code, not for Claude matching user requests. No user says "implement the Project entity model."

### Progressive Disclosure: Level 1 vs Level 2

Course 1 introduced the three levels. Now let's understand the first two deeply, because they're what you control with descriptions and instructions.

**Level 1: Frontmatter (always loaded)**

The `name` and `description` fields are loaded into Claude's system prompt at the start of every conversation. Claude reads all skill descriptions before you even type your first message. This is the "menu" Claude uses to decide which skills might be relevant.

**Level 2: SKILL.md body (loaded when relevant)**

The markdown content below the frontmatter -- your actual instructions -- only loads when Claude decides the skill is relevant to the current request. This is triggered either by:
- Claude matching your description to the user's query (automatic invocation)
- The user typing `/skill-name` (direct invocation)

Here's the key insight from the skills docs on how this affects what Claude sees:

| Frontmatter setting | You can invoke | Claude can invoke | When loaded into context |
|---|---|---|---|
| (default) | Yes | Yes | Description always in context, full skill loads when invoked |
| `disable-model-invocation: true` | Yes | No | Description not in context, full skill loads when you invoke |
| `user-invocable: false` | No | Yes | Description always in context, full skill loads when invoked |

Notice: when `disable-model-invocation: true` is set, the description isn't even loaded into Claude's system prompt. The skill becomes invisible to Claude until you explicitly invoke it with `/name`. This is useful for skills with side effects (like deployment) that you don't want Claude triggering on its own.

### Reference Content vs Task Content

The skills docs draw a distinction between two types of skill content that affects how you write instructions:

**Reference content** adds knowledge Claude applies to your current work -- conventions, patterns, style guides, domain knowledge. This content runs inline so Claude can use it alongside your conversation context.

```yaml
---
name: api-conventions
description: API design patterns for this codebase
---

When writing API endpoints:
- Use RESTful naming conventions
- Return consistent error formats
- Include request validation
```

**Task content** gives Claude step-by-step instructions for a specific action. These are often skills you invoke directly with `/skill-name`.

```yaml
---
name: deploy
description: Deploy the application to production
context: fork
disable-model-invocation: true
---

Deploy the application:
1. Run the test suite
2. Build the application
3. Push to the deployment target
```

The code-review-checklist skill you'll build in this course is **task content** -- it gives Claude a structured procedure to follow. The daily-standup from Course 1 was also task content. Reference skills become more important as you build library-style skills in later courses.

### Writing Specific, Actionable Instructions

The PDF guide is emphatic: vague instructions produce vague results. Compare:

**Good -- specific and actionable:**
```
Run `python scripts/validate.py --input {filename}` to check data format.
If validation fails, common issues include:
- Missing required fields (add them to the CSV)
- Invalid date formats (use YYYY-MM-DD)
```

**Bad -- vague directive:**
```
Validate the data before proceeding.
```

The good example tells Claude *exactly* what command to run, what tool to use, and what to do when things go wrong. The bad example leaves Claude guessing about what "validate" means, what tool to use, and what success looks like.

This principle applies to every instruction in your SKILL.md body:
- Name specific files, commands, and tools
- Define what "success" looks like for each step
- Anticipate common failure modes and provide specific fixes
- Use concrete examples of good vs bad output

### The Recommended SKILL.md Structure

The PDF guide provides a template for structuring skill instructions:

```markdown
---
name: your-skill
description: [...]
---

# Your Skill Name

## Instructions

### Step 1: [First Major Step]
Clear explanation of what happens.

Example:
```bash
python scripts/fetch_data.py --project-id PROJECT_ID
```
Expected output: [describe what success looks like]

### Step 2: [Second Major Step]
...

## Examples

### Example 1: [common scenario]
User says: "Set up a new marketing campaign"
Actions:
1. Fetch existing campaigns via MCP
2. Create new campaign with provided parameters
Result: Campaign created with confirmation link

## Troubleshooting

### Error: [Common error message]
Cause: [Why it happens]
Solution: [How to fix it]
```

This structure ensures:
- **Steps** give Claude a clear sequence to follow
- **Examples** show Claude what "good" looks like for common cases
- **Troubleshooting** prevents Claude from getting stuck on known issues

## Key References
- PDF Guide: Chapter 2 "Planning and Design" (pp. 7-13) -- Description formula, good/bad examples, instruction best practices
- Skills docs: "Types of skill content" section -- Reference vs task content
- Skills docs: "Control who invokes a skill" section -- The invocation/context loading table
- Skills docs: "Troubleshooting" section -- Under-triggering and over-triggering diagnosis

## What You're Building

A **code-review-checklist** skill that performs structured code reviews across six dimensions: correctness, readability, performance, security, testing, and a final verdict. This demonstrates the concepts because:

- It needs a **rich description** with multiple trigger phrases ("review this code", "code review", "check this PR")
- It contains **task content** with clear, numbered steps for each review dimension
- Each dimension has **specific, actionable criteria** -- not vague directives
- It includes an **example output format** so Claude knows what "good" looks like
- It's immediately testable on any code file or diff

## Walkthrough

### Step 1: Create the skill directory

```bash
mkdir -p ~/.claude/skills/code-review-checklist
```

### Step 2: Analyze the description

Before writing any code, let's design the description using the formula:

| Component | Content |
|---|---|
| **What it does** | Performs a structured code review across six quality dimensions |
| **When to use it** | When user says "review this code", "code review", "check this PR", "review my changes" |
| **Key capabilities** | Evaluates correctness, readability, performance, security, testing, and provides a verdict |

Combined:
```
Performs a structured code review covering correctness, readability,
performance, security, and testing. Use when the user says "review this
code", "code review", "check this PR", "review my changes", or asks for
feedback on code quality. Produces a checklist with per-dimension
verdicts and an overall assessment.
```

Notice how this follows every principle:
- States function clearly (structured code review)
- Lists 5 trigger phrases a user would naturally say
- Scopes capabilities (the six dimensions)
- Describes output format (checklist with verdicts)

### Step 3: Write the SKILL.md

Create `~/.claude/skills/code-review-checklist/SKILL.md` with the following content.

You can copy the file directly from this course's skill directory:

```bash
cp courses/course-02-descriptions-and-triggers/skill/code-review-checklist/SKILL.md \
   ~/.claude/skills/code-review-checklist/SKILL.md
```

Or create it manually -- the full content is in the `skill/code-review-checklist/SKILL.md` file in this course directory.

Study the SKILL.md and notice how it applies the concepts from this lesson:

1. **Description formula**: All three components present -- what, when, capabilities
2. **Trigger phrases**: Five natural phrases a user would say
3. **Specific instructions**: Each dimension has concrete criteria, not vague guidance
4. **Output format example**: Claude can see exactly what the review should look like
5. **Conditional logic**: "If no tests exist, note this as a gap" -- handles edge cases

### Step 4: Test automatic triggering with different phrases

Open Claude Code in a project with some code files and try each of these phrases:

```
Review this code
```

```
Can you do a code review of src/auth.ts?
```

```
Check this PR for issues
```

```
Give me feedback on my changes
```

Each phrase should trigger the skill because the description includes matching keywords. If any phrase doesn't trigger, look at your description -- does it contain words close enough to what you typed?

### Step 5: Test with direct invocation

```
/code-review-checklist src/auth.ts
```

This bypasses the description matching and loads the skill directly. The output should follow the six-dimension checklist format.

### Step 6: Test non-triggering phrases

These should NOT trigger the code review skill:

```
Write a Python function to sort a list
```

```
Explain how React hooks work
```

```
Help me set up a database
```

If any of these trigger the code review skill, your description is too broad. You'd need to make the trigger phrases more specific.

### Step 7: Compare with and without the skill

Try running a code review *without* the skill active (rename the folder temporarily):

```bash
mv ~/.claude/skills/code-review-checklist ~/.claude/skills/_code-review-checklist-disabled
```

Ask Claude: "Review this code" -- notice Claude gives a generic, unstructured review.

Now restore it:

```bash
mv ~/.claude/skills/_code-review-checklist-disabled ~/.claude/skills/code-review-checklist
```

Ask the same question -- now you get the structured six-dimension checklist. This is the value of a well-crafted skill: consistent, thorough output every time.

## Exercises

1. **Rewrite a bad description**: Take this bad description and rewrite it using the formula:
   ```yaml
   description: Reviews code.
   ```
   Your rewrite should include what it does, when to use it (with at least 3 trigger phrases), and what capabilities it offers. Compare your version with the one in the code-review-checklist skill.

2. **Add a seventh dimension**: Add a new review dimension to the code-review-checklist skill -- for example, "Documentation" or "Accessibility" or "Error Handling". Follow the pattern of the existing dimensions: give it specific criteria, not vague guidance. Test that the new dimension appears in review output.

3. **Build a reference-style skill**: Create a new skill called `coding-standards` at `~/.claude/skills/coding-standards/SKILL.md` that provides **reference content** (not task content). It should contain your team's coding conventions (naming, file structure, error handling patterns). Set `user-invocable: false` so only Claude loads it when relevant. Verify that Claude applies these standards when you ask it to write code -- without you invoking the skill directly.

4. **Trigger phrase audit**: Install the code-review-checklist skill. Write down 10 phrases you think a user might say when they want a code review. Test each one. Record which triggered the skill and which didn't. For any misses, update the description to improve coverage. Aim for at least 8 out of 10 triggering correctly.

5. **Diagnose over-triggering**: If your skill triggers on unrelated requests, narrow the description. The skills docs suggest: "Make the description more specific" or "Add `disable-model-invocation: true` if you only want manual invocation." Practice this by temporarily making your description overly broad (e.g., "Helps with code"), observing the over-triggering, then narrowing it back down.

## Verification Checklist

- [ ] `~/.claude/skills/code-review-checklist/SKILL.md` exists with correct casing
- [ ] YAML frontmatter has valid `---` delimiters
- [ ] `name` field is `code-review-checklist` (kebab-case, matches folder)
- [ ] `description` follows the `[What] + [When] + [Capabilities]` formula
- [ ] Description includes at least 3 trigger phrases
- [ ] No XML angle brackets in frontmatter
- [ ] Body instructions are specific and actionable (not "review the code")
- [ ] Each review dimension has concrete criteria
- [ ] Example output format is included in the body
- [ ] Typing "review this code" triggers the skill automatically
- [ ] Running `/code-review-checklist` invokes it directly
- [ ] Output covers all six dimensions with per-dimension verdicts
- [ ] Unrelated prompts ("write a function", "explain hooks") do NOT trigger it
- [ ] The skill appears when you ask "What skills are available?"

## What's Next

In **Course 3: Full Skill Anatomy -- Scripts, References, and Assets**, you'll learn:
- How to add supporting files to a skill: `scripts/`, `references/`, and `assets/` directories
- Progressive disclosure Level 3: linked files loaded only when needed
- Running executable scripts from within a skill
- Keeping SKILL.md under 500 lines by extracting detail into references
- The `compatibility` frontmatter field
- You'll build a `meeting-to-actions` skill with a validation script, reference guide, and output template

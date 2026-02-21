---
name: pr-description
description: Generates a structured pull request description from git diffs and commit history. Use when the user says "PR description", "pull request description", "describe my changes", "write a PR", "summarize my changes for a PR", or "help me write a pull request". Reads staged or unstaged changes and formats them into a consistent PR template with summary, change details, and testing notes.
---

# PR Description Generator

Generate a pull request description from the current git changes.

## Step 1: Gather Context

Run these git commands to understand the changes. Try staged changes first, fall back to unstaged.

**Check for staged changes:**

```bash
git diff --cached --stat
```

If there are staged changes, use those. If the output is empty, fall back to unstaged changes:

```bash
git diff --stat
```

If both are empty, check if there are commits not yet pushed:

```bash
git log --oneline origin/HEAD..HEAD 2>/dev/null || git log --oneline -5
```

**If no changes are found at all:**
Tell the user: "No staged changes, unstaged changes, or unpushed commits found. Stage your changes with `git add` or make some changes first."
Do NOT generate a PR description from nothing.

**Get the detailed diff:**

For staged changes:
```bash
git diff --cached
```

For unstaged changes:
```bash
git diff
```

**Get recent commit context (if there are commits on the branch):**

```bash
git log --oneline -10
```

**Get the current branch name:**

```bash
git branch --show-current
```

## Step 2: Analyze the Changes

Before writing the description, categorize the changes:

1. **Type of change** -- Is this a new feature, bug fix, refactor, documentation update, test addition, or configuration change? Look at what files changed and the nature of the diff.
2. **Scope** -- How many files changed? Is this a focused change or a broad one?
3. **Key modifications** -- What are the 2-4 most important things that changed? Focus on behavior changes, not line-by-line diffs.
4. **Breaking changes** -- Could this change break existing functionality? Look for changed function signatures, removed exports, modified API contracts, or database schema changes.

## Step 3: Write the PR Description

Use the template in `assets/pr-template.md` to format the output.

Fill in each section following these rules:

**Title**: One line, under 72 characters. Start with a verb: "Add", "Fix", "Update", "Refactor", "Remove". Include the scope if it's not obvious. Examples:
- "Add email validation to signup form"
- "Fix timeout in payment processing webhook"
- "Refactor user service to use repository pattern"

**Summary**: 2-3 sentences explaining WHAT changed and WHY. Don't describe HOW -- the diff shows that. Focus on the motivation and impact.

**Changes**: Bulleted list of the key modifications. Group by file or component if there are many changes. Each bullet should be a complete thought, not just a filename.

**Testing**: What the reviewer should do to verify the changes work. Be specific: "Run `npm test` and verify the auth tests pass" not "Test it."

**Notes for reviewers**: Optional. Include if there are non-obvious decisions, known limitations, or follow-up work planned.

## Step 4: Present the Result

Output the completed PR description in a markdown code block so the user can copy it directly.

After the code block, add a brief note:
- How many files were changed
- Whether there are any items the user should double-check (e.g., "I noticed a TODO comment in line 42 of auth.ts -- you may want to resolve that before opening the PR")

## Error Handling

**Not in a git repository:**
If `git diff` fails with "not a git repository", tell the user and suggest they navigate to their project directory.

**Binary files in diff:**
If the diff includes binary files, note them in the Changes section as "Binary file changed: [filename]" rather than trying to describe the diff content.

**Very large diffs (50+ files):**
If the diff touches more than 50 files, summarize at the directory/component level rather than listing every file. Suggest the user consider splitting the PR.

## Rules

- Never invent changes that aren't in the diff
- If the branch name contains a ticket number (e.g., `feat/PROJ-123-add-auth`), include it in the title
- Keep the summary focused on user-visible impact, not implementation details
- If you can't determine the motivation for a change from the diff alone, ask the user rather than guessing

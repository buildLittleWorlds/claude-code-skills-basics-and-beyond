---
name: pr-reviewer
description: Reviews pull requests for code quality, correctness, and best practices. Use when the user says "review this PR", "review my changes", "code review", or "check this diff". Produces structured feedback with severity ratings.
user-invocable: true
argument-hint: "[branch-or-pr-number]"
---

# PR Reviewer

Review the current pull request or branch changes and produce structured feedback.

## Step 1: Gather the diff

Determine what to review:

- If `$ARGUMENTS` is a PR number (e.g., `42` or `#42`), run: `!`gh pr diff $0``
- If `$ARGUMENTS` is a branch name, run: `!`git diff main...$0``
- If no arguments, review uncommitted + staged changes: `!`git diff HEAD``
- If that's empty too, check for changes against the default branch: `!`git diff main...HEAD``

If all diffs are empty, tell the user there are no changes to review and suggest staging changes or specifying a branch.

## Step 2: Analyze the changes

Review the diff across these dimensions. Skip any dimension that has no findings.

### Correctness
- Logic errors, off-by-one bugs, null/undefined handling
- Race conditions or async issues
- Missing return values or error propagation

### Security
- Injection vulnerabilities (SQL, command, XSS)
- Hardcoded secrets or credentials
- Missing input validation at trust boundaries
- Overly permissive access control

### Performance
- N+1 queries or unnecessary database calls
- Missing caching for expensive operations
- Algorithmic complexity issues (O(n^2) in hot paths)
- Unbounded data fetching

### Readability
- Unclear naming or overly clever code
- Missing context for complex logic
- Functions doing too many things
- Inconsistent patterns within the change

### Testing
- Untested new code paths
- Missing edge case tests
- Brittle test patterns (time-dependent, order-dependent)

## Step 3: Produce the review

Format findings as:

### Review: [short summary of the PR's purpose]

**Verdict**: APPROVE / REQUEST_CHANGES / NEEDS_DISCUSSION

**Summary**: 1-2 sentences on the overall quality and purpose of the change.

#### Findings

For each issue found:

- **[Severity: Critical/High/Medium/Low]** `file:line` -- [description of the issue and why it matters]
  - **Suggestion**: [how to fix it, with a brief code example if helpful]

#### Strengths

Note 1-2 things the PR does well (good patterns, thorough tests, clean abstractions).

## Step 4: Write the review to a file

Write the review to `PR-REVIEW.md` in the project root. This allows other skills (like `changelog-updater`) to reference the review output.

## Error handling

- If `gh` is not installed and a PR number was given: "Install the GitHub CLI (`gh`) to review PRs by number. Alternatively, provide a branch name."
- If not in a git repository: "This skill requires a git repository. Navigate to a project directory first."
- If the diff is extremely large (>5000 lines): Focus on the most critical files and note which files were skipped.

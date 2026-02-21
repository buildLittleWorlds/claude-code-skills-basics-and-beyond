---
name: investigate-issue
description: Investigates a GitHub issue by gathering context from the issue tracker and codebase. Use when the user says "investigate issue", "look into issue #N", "research issue", or "what's going on with issue #N". Fetches issue details, searches relevant code, and produces a structured investigation report.
disable-model-invocation: true
context: fork
agent: Explore
allowed-tools: Bash(gh *), Read, Grep, Glob
argument-hint: "[issue-number]"
---

# Investigate GitHub Issue

You are investigating a GitHub issue. Your goal is to gather as much context as possible and produce a structured investigation report.

## Issue Context

Issue data:
!`gh issue view $0 --json number,title,body,labels,assignees,state,comments,createdAt,updatedAt 2>&1`

Related pull requests:
!`gh pr list --search "issue:$0" --json number,title,state,url --limit 5 2>&1`

## Investigation Steps

### Step 1: Understand the Issue

Read the issue title, body, and comments above. Identify:
- What is being reported (bug, feature request, question)?
- What is the expected behavior vs actual behavior?
- Are there reproduction steps?
- What components or files are mentioned?

### Step 2: Search the Codebase

Based on the issue description, search for relevant code:

1. **Find mentioned files**: If the issue mentions specific files or paths, read them directly
2. **Search for keywords**: Use Grep to find code related to the issue's topic (error messages, function names, component names mentioned in the issue)
3. **Trace the code path**: If the issue describes a flow (e.g., "when I click submit, the form fails"), trace through the relevant handlers and functions
4. **Check recent changes**: Run `gh api repos/{owner}/{repo}/commits --jq '.[0:10] | .[] | .sha[:7] + " " + .commit.message' 2>/dev/null` to see if recent commits relate to the issue

### Step 3: Identify Root Cause (if possible)

Based on your code exploration:
- Can you identify the specific code causing the issue?
- Is this a logic error, missing handling, configuration issue, or dependency problem?
- If you can't identify the root cause, note what you checked and what remains unclear

### Step 4: Check for Related Issues

Run `gh issue list --search "is:issue <key-terms-from-issue>" --limit 5 --json number,title,state` to find potentially related or duplicate issues. Replace `<key-terms-from-issue>` with 2-3 relevant keywords from the issue.

### Step 5: Produce Investigation Report

Structure your findings as:

```
## Investigation Report: Issue #<number>

### Summary
One-paragraph summary of the issue and what you found.

### Issue Classification
- **Type**: Bug / Feature Request / Question / Documentation
- **Severity**: Critical / High / Medium / Low
- **Components**: List of affected files or modules

### Findings
Detailed description of what you discovered during investigation.
Include specific file paths and line numbers where relevant.

### Root Cause
Your assessment of the root cause (or "Undetermined" with notes on what was checked).

### Suggested Next Steps
Concrete, actionable recommendations for resolving the issue.

### Related
- Related issues (if found)
- Related PRs (if found)
- Related code areas that may need attention
```

## References

- For a structured investigation methodology, consult `references/investigation-checklist.md` -- it contains categories of things to check for different issue types (bugs, performance, security)

## Error Handling

- If the `gh` command above returned an error (e.g., "issue not found", "authentication required"), report the error clearly and stop -- do not attempt to investigate without issue data
- If the repository has no GitHub remote, report that this skill requires a GitHub repository with the `gh` CLI authenticated
- If the issue has no body or description, note this and focus investigation on the title and any comments

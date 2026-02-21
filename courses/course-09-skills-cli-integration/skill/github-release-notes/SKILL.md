---
name: github-release-notes
description: Generates release notes from merged pull requests since the last git tag. Use when the user says "release notes", "changelog", "what changed since last release", or "prepare a release".
disable-model-invocation: true
argument-hint: "[version-tag]"
---

# GitHub Release Notes Generator

Generate structured release notes based on merged pull requests since the last git tag.

## Context

Latest tag: !`git describe --tags --abbrev=0 2>/dev/null || echo "no-tags-found"`
PRs since last tag: !`gh pr list --state merged --search "merged:>=$(git log -1 --format=%ci $(git describe --tags --abbrev=0 2>/dev/null || echo HEAD~20) 2>/dev/null | cut -d' ' -f1)" --json number,title,labels,author,body --limit 50 2>/dev/null || echo "ERROR: Could not fetch PRs. Check that gh is authenticated and you are in a git repo with a GitHub remote."`
Current branch: !`git branch --show-current 2>/dev/null || echo "unknown"`
Repo: !`gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || echo "unknown"`

## Instructions

### Step 1: Validate prerequisites

Check the dynamic context above. If any errors appear:
- **"no-tags-found"**: No git tags exist. Ask the user if they want to generate notes from all commits, or specify a starting point.
- **"ERROR: Could not fetch PRs"**: The `gh` CLI is not authenticated, or this directory is not a GitHub repo. Tell the user exactly what failed and how to fix it (`gh auth login`, verify the remote with `git remote -v`).
- **"unknown" repo**: Not connected to a GitHub remote. Tell the user to add one.

### Step 2: Categorize PRs

Classify each PR using the rules in `references/pr-categories.md`:
1. Check the PR title for conventional commit prefixes (`feat:`, `fix:`, `docs:`, `chore:`, etc.)
2. Check PR labels for category signals (`bug`, `enhancement`, `breaking-change`, etc.)
3. Read the PR body for keywords ("fixes #", "breaking change", "new feature")
4. When ambiguous, classify by primary intent from the title

### Step 3: Determine version

If the user provided a version tag as `$ARGUMENTS`, use it.

Otherwise, suggest a version based on the changes:
- **Patch** (x.y.Z): Only bug fixes, no new features
- **Minor** (x.Y.0): New features, no breaking changes
- **Major** (X.0.0): Any breaking changes

Base the suggestion on the latest tag found in Step 1.

### Step 4: Generate release notes

Format the output using the template in `assets/release-template.md`:
- Include a one-sentence summary line describing the release theme
- Group entries under the appropriate changelog headings (Added, Changed, Fixed, Security)
- Each entry references its PR number in parentheses
- Omit empty sections entirely
- Follow the conventions in `references/changelog-conventions.md`

### Step 5: Generate comparison link

At the bottom, include a GitHub comparison link:

```
**Full changelog**: https://github.com/OWNER/REPO/compare/PREVIOUS_TAG...NEW_TAG
```

## Error Handling

- If `gh` commands fail mid-execution, report which command failed and why
- If a PR has no title or is clearly a bot PR (dependabot, renovate), include it under Chores and note it's automated
- If there are more than 50 PRs, note that the list was truncated and suggest narrowing the date range

## Additional Resources

- For changelog format rules, see [references/changelog-conventions.md](references/changelog-conventions.md)
- For PR classification rules, see [references/pr-categories.md](references/pr-categories.md)
- For the output template, see [assets/release-template.md](assets/release-template.md)

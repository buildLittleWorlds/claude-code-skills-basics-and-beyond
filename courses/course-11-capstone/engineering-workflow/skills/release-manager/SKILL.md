---
name: release-manager
description: Orchestrates the release process -- version bump, changelog finalization, git tag, and release notes. Use when the user says "create a release", "bump the version", "prepare release", or "tag a release". Coordinates the output of pr-reviewer and changelog-updater.
user-invocable: true
argument-hint: "[major|minor|patch] or [version-number]"
---

# Release Manager

Orchestrate a complete release: version bump, changelog, tag, and release notes.

## Step 1: Determine the version bump

Parse the requested version:

- If `$ARGUMENTS` is `major`, `minor`, or `patch`: calculate from the current version
- If `$ARGUMENTS` is a specific version (e.g., `2.0.0`): use that directly
- If no arguments: default to `patch`

Find the current version:

1. Check `package.json` → `.version` field
2. Check `pyproject.toml` → `[project] version` or `[tool.poetry] version`
3. Check `Cargo.toml` → `[package] version`
4. Check the latest git tag: `!`git describe --tags --abbrev=0 2>/dev/null``
5. If no version found anywhere, start at `1.0.0`

Calculate the new version using semver rules:
- `major`: 1.2.3 → 2.0.0
- `minor`: 1.2.3 → 1.3.0
- `patch`: 1.2.3 → 1.2.4

## Step 2: Verify preconditions

Before proceeding, check:

1. **Clean working tree**: `git status --porcelain` should be empty. If not, warn: "You have uncommitted changes. Commit or stash them before releasing."
2. **On the correct branch**: Check that you're on `main` or `master`. If not, warn: "You're on branch [name]. Releases are typically made from main/master."
3. **Changelog exists**: If `CHANGELOG.md` doesn't exist, suggest running `/engineering-workflow:changelog-updater` first.
4. **Tests pass**: If a test runner is detected, suggest running tests first: "Consider running your test suite before releasing."

Report precondition status but don't block -- the user may have reasons to proceed.

## Step 3: Update version numbers

Update the version in all relevant files:

- `package.json`: Update the `version` field
- `pyproject.toml`: Update the `version` field
- `Cargo.toml`: Update the `version` field
- Any other files containing the old version string (search carefully, don't blindly replace)

## Step 4: Finalize the changelog

Update `CHANGELOG.md`:
- Replace `## [Unreleased]` with `## [X.Y.Z] - YYYY-MM-DD` (today's date)
- Add a new empty `## [Unreleased]` section above it
- If there's a comparison link section at the bottom, update it

## Step 5: Generate release notes

Create release notes for GitHub/GitLab by summarizing the changelog section for this version. Format:

```markdown
## What's New in vX.Y.Z

### Highlights
- [Most important 2-3 changes in plain language]

### All Changes
[Full changelog section for this version]

### Contributors
[List contributors from git log if available]
```

Write the release notes to `RELEASE_NOTES.md`.

## Step 6: Create the release commit and tag

Execute the following commands:

```bash
git add -A
git commit -m "chore: release vX.Y.Z"
git tag -a vX.Y.Z -m "Release vX.Y.Z"
```

## Step 7: Summarize and suggest next steps

Report:
- Previous version → new version
- Files modified
- Tag created
- Changelog entries included

Suggest next steps:
- "Review the changes: `git show HEAD`"
- "Push the release: `git push && git push --tags`"
- "Create a GitHub release: `gh release create vX.Y.Z --notes-file RELEASE_NOTES.md`"
- "Publish the package (if applicable): `npm publish` / `cargo publish` / etc."

**Do not push or publish automatically.** Always let the user review and push manually.

## Error handling

- If version calculation fails: Show the current version and ask the user to specify the new version explicitly.
- If the changelog has no [Unreleased] section: "No unreleased changes found in CHANGELOG.md. Run `/engineering-workflow:changelog-updater` to generate entries, or add them manually."
- If git tag already exists: "Tag vX.Y.Z already exists. Choose a different version or delete the existing tag with `git tag -d vX.Y.Z`."

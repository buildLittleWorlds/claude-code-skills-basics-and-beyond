---
name: changelog-updater
description: Updates CHANGELOG.md based on merged PRs or recent commits. Use when the user says "update the changelog", "add changelog entry", "what changed since last release", or after completing a PR review. Follows Keep a Changelog conventions.
user-invocable: true
argument-hint: "[since-tag-or-date]"
---

# Changelog Updater

Update the project's CHANGELOG.md based on recent changes.

## Step 1: Determine the range of changes

Figure out what's new:

- If `$ARGUMENTS` is a git tag (e.g., `v1.2.0`), get changes since that tag: `!`git log $0..HEAD --oneline``
- If `$ARGUMENTS` is a date (e.g., `2024-01-15`), get changes since that date: `!`git log --since="$0" --oneline``
- If no arguments, detect the latest tag: `!`git describe --tags --abbrev=0 2>/dev/null``
  - If a tag exists, use changes since that tag
  - If no tags exist, use all commits: `!`git log --oneline -50``

Also check for a PR review file that may have been left by `pr-reviewer`:
- Read `PR-REVIEW.md` if it exists -- this provides context about the latest changes

## Step 2: Categorize changes

Classify each commit/PR into one of these categories based on its content:

| Category | Prefix patterns | Description |
|---|---|---|
| **Added** | `feat:`, `add:`, `new:` | New features or capabilities |
| **Changed** | `update:`, `change:`, `refactor:` | Changes to existing functionality |
| **Deprecated** | `deprecate:` | Features marked for removal |
| **Removed** | `remove:`, `delete:` | Removed features or code |
| **Fixed** | `fix:`, `bugfix:`, `patch:` | Bug fixes |
| **Security** | `security:`, `vuln:` | Security-related changes |

If a commit doesn't match any prefix, classify by its content:
- Code changes to existing files → **Changed**
- New files → **Added**
- Deleted files → **Removed**
- Test fixes → **Fixed**

## Step 3: Format the changelog entry

Follow the [Keep a Changelog](https://keepachangelog.com/) format:

```markdown
## [Unreleased]

### Added
- Description of new feature (#PR-number)

### Changed
- Description of change (#PR-number)

### Fixed
- Description of bug fix (#PR-number)
```

Rules:
- Each entry is one line, starting with `- `
- Include PR numbers or commit hashes as references where available
- Write entries from the user's perspective ("Add dark mode support") not the developer's ("Implement ThemeProvider component")
- Group related commits into single entries when they're part of the same logical change
- Skip merge commits, version bumps, and changelog-only commits

## Step 4: Update CHANGELOG.md

- If `CHANGELOG.md` exists, insert the new `[Unreleased]` section after the header
- If `CHANGELOG.md` doesn't exist, create it with the standard Keep a Changelog header:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- ...
```

- Preserve all existing entries below the new section
- If an `[Unreleased]` section already exists, merge new entries into it (don't create a duplicate)

## Step 5: Summarize

Report what was added to the changelog:
- Number of entries per category
- Date range covered
- Reminder to review before committing: "Review CHANGELOG.md and edit entries as needed before committing."

## Error handling

- If not in a git repository: "This skill requires a git repository."
- If there are no new changes since the reference point: "No new changes found since [tag/date]. The changelog is up to date."
- If the specified tag doesn't exist: "Tag '$ARGUMENTS' not found. Available tags: [list recent tags]"

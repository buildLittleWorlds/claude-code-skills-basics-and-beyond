# Changelog Conventions

Based on the [Keep a Changelog](https://keepachangelog.com/) format.

## Guiding Principles

- Changelogs are for **humans**, not machines
- There should be an entry for **every single version**
- The same types of changes should be **grouped**
- Versions and sections should be **linkable**
- The **latest version** comes first
- The **release date** of each version is displayed

## Change Types

Group changes under these headings, in this order:

| Heading | What it covers |
|---------|----------------|
| **Added** | New features |
| **Changed** | Changes to existing functionality |
| **Deprecated** | Features that will be removed in upcoming releases |
| **Removed** | Features removed in this release |
| **Fixed** | Bug fixes |
| **Security** | Vulnerability patches |

Only include headings that have entries. Don't include empty sections.

## Version Format

```
## [X.Y.Z] - YYYY-MM-DD
```

- Use [Semantic Versioning](https://semver.org/): MAJOR.MINOR.PATCH
- Always include the release date in ISO 8601 format
- Link the version number to the comparison URL on GitHub

## Entry Format

Each entry should:
- Start with a verb in past tense ("Added", "Fixed", "Removed")
- Reference the PR number in parentheses: `(#123)`
- Be a single line, concise but descriptive
- Focus on the **user impact**, not the implementation detail

### Good entries

```
- Added dark mode support for the settings page (#142)
- Fixed crash when uploading files larger than 10MB (#156)
- Removed deprecated `v1/users` API endpoint (#160)
```

### Bad entries

```
- Updated auth.ts (too vague, no PR, no user impact)
- Refactored the codebase (not useful to users)
- Various bug fixes (not specific)
```

## Unreleased Section

Always maintain an `[Unreleased]` section at the top for tracking changes not yet in a release:

```markdown
## [Unreleased]

### Added
- New feature being developed (#170)
```

## Comparison Links

At the bottom of the changelog, include comparison links:

```markdown
[Unreleased]: https://github.com/user/repo/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/user/repo/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/user/repo/releases/tag/v1.0.0
```

# PR Category Classification Rules

When categorizing pull requests for release notes, use the following rules to assign each PR to exactly one category. Process rules top-to-bottom; the **first match** wins.

## Categories

### Breaking Changes
A PR is **breaking** if it:
- Removes or renames a public API endpoint, function, class, or method
- Changes the type signature of a public function or return value
- Removes a configuration option or CLI flag
- Changes default behavior in a way that could break existing users
- Requires migration steps (database changes, config updates)

**Changelog heading**: `Changed` (with a `BREAKING:` prefix on each entry)

### Features
A PR is a **feature** if it:
- Adds a new API endpoint, command, page, or capability
- Introduces a new configuration option
- Adds a new integration or plugin
- Implements a user-facing behavior that didn't exist before

**Changelog heading**: `Added`

### Fixes
A PR is a **fix** if it:
- Resolves a bug, error, or incorrect behavior
- Fixes a regression from a prior release
- Corrects a typo in user-facing text that affects behavior
- Addresses an edge case that caused failures

**Changelog heading**: `Fixed`

### Security
A PR is a **security** fix if it:
- Patches a vulnerability (CVE or otherwise)
- Updates a dependency to fix a security issue
- Adds security hardening (rate limiting, input validation, CSP headers)
- Fixes authentication or authorization bypass

**Changelog heading**: `Security`

### Documentation
A PR is **documentation** if it:
- Only changes files in `docs/`, `*.md`, or documentation-specific directories
- Updates code comments without changing behavior
- Adds or updates type definitions / JSDoc without changing runtime behavior

**Changelog heading**: Omit from changelog (or include in a separate `Documentation` section if the project tracks docs changes)

### Chores / Internal
A PR is a **chore** if it:
- Updates CI/CD configuration
- Bumps dependency versions (non-security)
- Refactors code without changing external behavior
- Updates linting rules or formatting
- Modifies dev-only tooling

**Changelog heading**: Omit from changelog (internal changes don't affect users)

## Ambiguous Cases

When a PR spans multiple categories:
1. **Breaking + anything**: Always classify as Breaking
2. **Security + fix**: Classify as Security
3. **Feature + fix**: Classify based on the PR title and primary intent
4. **Docs + code**: Classify based on the code change, ignore the docs portion

## Signals to Check

Use these signals from the PR metadata to help classify:
- **PR title prefix**: `feat:`, `fix:`, `docs:`, `chore:`, `BREAKING:`, `security:`
- **Labels**: `bug`, `enhancement`, `breaking-change`, `documentation`, `security`
- **Files changed**: which directories and file types dominate
- **PR body**: look for keywords like "fixes #", "closes #", "breaking change", "new feature"

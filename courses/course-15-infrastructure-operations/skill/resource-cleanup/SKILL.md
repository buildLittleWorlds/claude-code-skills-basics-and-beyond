---
name: resource-cleanup
description: |
  Find and clean up orphaned resources: stale git branches, unused config files,
  orphaned assets, and other project cruft. Use when the user says "clean up",
  "find stale branches", "remove unused files", "orphaned resources", "unused
  configs", "project hygiene", or "dead code cleanup". Defaults to dry-run
  (report only). Pass --execute to actually perform cleanup.
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./hooks/block-destructive.sh"
---

# Resource Cleanup

Find orphaned resources, report them, and clean up after explicit user confirmation.

**Default mode is dry-run** -- no resources are modified unless `--execute` is passed.

## Arguments

- **(no args)**: Dry-run mode. Scan and report only. Nothing is deleted or modified.
- **`--execute`**: Execute mode. Scan, report, wait for confirmation, then clean up.

## Phase 1: Scan for Orphaned Resources

Scan the project for orphaned resources in this order. For each resource found, record its name, type, age, and reason it's considered orphaned.

### Stale Git Branches

Find local branches with no commits in the last 30 days:

```bash
# List branches sorted by last commit date
git for-each-ref --sort=committerdate --format='%(refname:short) %(committerdate:relative)' refs/heads/
```

A branch is "stale" if:
- Its last commit is older than 30 days
- It is not `main`, `master`, or the current branch
- It has been fully merged into the default branch (check with `git branch --merged`)

### Unused Config Files

Look for configuration files that are not referenced by any code or script:
- `.eslintrc.*`, `.prettierrc.*`, `.babelrc.*` files that may be leftover from removed tooling
- Config files in the root directory that don't match any `devDependency` in `package.json`
- Duplicate or conflicting configs (e.g., both `.eslintrc.js` and `.eslintrc.json`)

### Orphaned Assets

Find assets (images, fonts, data files) in common asset directories that are not imported or referenced anywhere:

```bash
# Example: find images not referenced in any source file
for img in public/images/*; do
  basename=$(basename "$img")
  if ! grep -r "$basename" src/ --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' --include='*.css' --include='*.html' -q; then
    echo "Orphaned: $img"
  fi
done
```

Adapt the search patterns to the project's actual structure.

## Phase 2: Report

Present findings as a numbered list. For each resource, show:

| Field | Example |
|---|---|
| Number | 1 |
| Type | Stale branch |
| Name | `feature/old-experiment` |
| Age | 47 days since last commit |
| Reason | Fully merged into main, no recent activity |
| Size/Impact | 12 commits, no unique files |

**In dry-run mode (default)**: After presenting the report, print:

```
No changes made (dry-run mode).
To perform cleanup, re-run with: /resource-cleanup --execute
```

Then stop. Do not proceed to Phase 3.

**In execute mode** (`--execute`): Continue to Phase 3.

## Phase 3: Soak Period (execute mode only)

After presenting the report, pause and ask:

```
Review the resources listed above.
- To exclude items, tell me which numbers to skip.
- To ask about a specific item, refer to it by number.
- When ready, say "proceed" to begin cleanup.
- Say "cancel" to abort without changes.
```

Wait for the user to respond. Do not proceed automatically. Do not set a timeout.

If the user excludes items, remove them from the action list and re-display the updated list for final confirmation.

## Phase 4: Execute (execute mode only, after user says "proceed")

For each confirmed resource, perform the cleanup action. **Always append `# CONFIRMED_DESTRUCTIVE` to destructive Bash commands** so the `block-destructive.sh` hook allows them through.

### Deleting stale branches

```bash
git branch -d feature/old-experiment # CONFIRMED_DESTRUCTIVE
```

Use `-d` (not `-D`) for merged branches. If a branch is not merged, warn the user and skip it unless they explicitly request `-D`.

### Removing orphaned files

```bash
rm orphaned-file.txt # CONFIRMED_DESTRUCTIVE
```

Never use `rm -rf` for individual files. Only use `rm` (no flags) or `rm -r` for directories, always with the `# CONFIRMED_DESTRUCTIVE` marker.

### Removing unused configs

```bash
rm .eslintrc.legacy # CONFIRMED_DESTRUCTIVE
```

## Phase 5: Audit Log

After all actions are complete, write an audit log entry to `.claude/audit.log`. Create the file if it doesn't exist.

Format:

```
## YYYY-MM-DDTHH:MM:SSZ -- resource-cleanup --execute
- Deleted branch: feature/old-experiment (47 days stale, merged into main)
- Deleted branch: fix/typo-in-readme (92 days stale, merged into main)
- Removed orphaned config: .eslintrc.legacy (not referenced by any script)
- Skipped: feature/maybe-later (excluded by user)
- Total: 3 resources cleaned, 1 skipped
```

Also print a summary to the user:

```
Cleanup complete.
  Cleaned: 3 resources
  Skipped: 1 resource
  Audit log: .claude/audit.log
```

## Gotchas

1. **Never delete unmerged branches without explicit user confirmation.** Even in execute mode, unmerged branches require a separate warning: "This branch has not been merged. Deleting it will lose N commits. Proceed?"

2. **The `CONFIRMED_DESTRUCTIVE` marker is required.** The `block-destructive.sh` hook will block any `rm`, `git branch -D`, or other destructive command that doesn't include this marker. Don't forget it.

3. **Adapt scanning to the project.** Not every project has a `public/images/` directory or uses npm. Check what package manager, asset structure, and config patterns the project actually uses before scanning.

4. **Don't delete `.git/` contents.** The cleanup targets branches (via `git branch -d`), not raw git objects. Never run `rm` on anything inside `.git/`.

5. **Respect `.gitignore` patterns.** Files that are gitignored may look "orphaned" but are intentionally excluded. Check gitignore status before flagging files.

6. **Large repositories may have many stale branches.** If there are more than 20 stale branches, group them by age range and ask the user which groups to clean rather than listing all individually.

7. **Config files may be referenced indirectly.** A `.babelrc` might be loaded by a framework's default behavior rather than explicitly imported. Check framework documentation before flagging framework-standard configs.

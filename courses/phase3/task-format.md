# Task File Format Specification

This document defines the format for task files used throughout the Task Workflow cockpit.

## Overview

Each task is a single Markdown file with YAML frontmatter. Files live in `~/work/_tasks/` organized by status:

```
~/work/_tasks/
├── inbox/       # Uncategorized items awaiting triage
├── pending/     # Active tasks with metadata assigned
├── archive/     # Completed tasks (moved here by /done)
└── log/         # Append-only session logs and completion records
```

## File Naming

Task files use kebab-case with a `.md` extension:

```
fix-api-timeout.md
write-quarterly-report.md
renew-domain-registration.md
```

No dates or IDs in filenames. The filename is a human-readable slug derived from the title. This keeps `ls` output scannable.

## YAML Frontmatter

Every task file starts with YAML frontmatter between `---` markers:

```yaml
---
title: Fix API timeout on /users endpoint
status: inbox | pending | done
domain: work | personal
due: 2026-02-28
priority: P1 | P2 | P3 | P4
tags: [bug, backend, api]
created: 2026-02-15T09:30
---
```

### Field Reference

| Field | Required | Values | Description |
|-------|----------|--------|-------------|
| `title` | Yes | Free text | Short descriptive title (appears in `/next` output) |
| `status` | Yes | `inbox`, `pending`, `done` | Current lifecycle stage |
| `domain` | No | `work`, `personal` | Set during triage; absent for inbox items |
| `due` | No | `YYYY-MM-DD` | Due date; absent for inbox items, required for pending |
| `priority` | No | `P1`-`P4` | Set during triage; absent for inbox items |
| `tags` | No | YAML list | Category tags for filtering |
| `created` | Yes | `YYYY-MM-DDTHH:MM` | When the task was captured |

### Priority Levels

| Priority | Meaning | Typical due range |
|----------|---------|-------------------|
| P1 | Critical / blocking | Today or tomorrow |
| P2 | Important / time-sensitive | This week |
| P3 | Normal / scheduled | This month |
| P4 | Low / someday | No hard deadline |

### Status Lifecycle

```
inbox → pending → done
  ↑                 |
  |                 ↓
  |             archive/
  |                 |
  |                 ↓
  |              log/ (append entry)
```

1. **inbox**: Raw capture. Only `title`, `status`, and `created` are required. Everything else gets filled in during triage.
2. **pending**: Fully triaged. Has `domain`, `due`, `priority`, and `tags` assigned. File lives in `pending/`.
3. **done**: Completed. The `/done` skill updates `status`, moves the file to `archive/`, and appends a completion record to `log/`.

## Body Content

Below the frontmatter, the body contains free-form Markdown:

```markdown
---
title: Fix API timeout on /users endpoint
status: pending
domain: work
due: 2026-02-28
priority: P2
tags: [bug, backend, api]
created: 2026-02-15T09:30
---

The /users endpoint times out when the result set exceeds 500 records.
Pagination was added in v2.1 but the default page size is still 1000.

## Notes
- Reproduce: `curl localhost:3000/api/users?org=large-corp`
- Related PR: #342
- Ask Sarah about the caching layer before changing defaults
```

The body is for context: notes, links, reproduction steps, decisions. Skills read it for context but don't impose structure on it.

## Log Entry Format

Log files in `log/` are append-only Markdown. Each entry records a completion:

```markdown
## 2026-02-21 14:30 — Fix API timeout on /users endpoint

**Status**: done
**Summary**: Reduced default page size to 100 and added cursor-based pagination. PR #389 merged.
**Time in pending**: 6 days

---
```

The `/done` skill appends these entries. The `/session-summary` skill reads them. Log files are named by date: `log/2026-02-21.md`.

## Validation Rules

A valid task file must have:
1. YAML frontmatter between `---` markers
2. A `title` field (non-empty string)
3. A `status` field with value `inbox`, `pending`, or `done`
4. A `created` field with ISO-ish datetime
5. If `status` is `pending`: `domain`, `due`, and `priority` must be present

Skills that read task files should handle missing optional fields gracefully (treat as "not set" rather than erroring).

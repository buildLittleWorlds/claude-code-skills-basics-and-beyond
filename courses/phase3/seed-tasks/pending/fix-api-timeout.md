---
title: Fix API timeout on /users endpoint
status: pending
domain: work
due: 2026-02-14
priority: P1
tags: [bug, backend, api]
created: 2026-02-08T09:30
---

The /users endpoint times out when the result set exceeds 500 records. Pagination was added in v2.1 but the default page size is still 1000.

## Notes
- Reproduce: `curl localhost:3000/api/users?org=large-corp`
- Related PR: #342
- Ask Sarah about the caching layer before changing defaults

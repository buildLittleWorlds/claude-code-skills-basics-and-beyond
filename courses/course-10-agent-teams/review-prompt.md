# Parallel Code Review -- Team Prompt

Copy and paste this into Claude Code to spawn a 3-reviewer agent team using the built-in API.

---

## The Prompt

```
Create an agent team called "code-review" to review the current project.
Spawn three reviewers:

- "security-reviewer": Review for security vulnerabilities. Check for injection
  flaws (SQL, command, XSS), authentication and session issues, sensitive data
  exposure (hardcoded secrets, API keys in logs), access control gaps, security
  misconfigurations, and input validation problems. Report each finding with
  severity, OWASP category, file:line, description, and fix recommendation.

- "perf-reviewer": Review for performance issues. Check for N+1 queries,
  unnecessary allocations, missing caching, O(n^2) algorithms, blocking I/O in
  async code, bundle size problems, and unbounded data fetching. Report each
  finding with impact level, category, file:line, description, and fix.

- "test-reviewer": Review test coverage. Check for untested code paths, missing
  edge cases, brittle tests (time/order-dependent, external calls), test
  isolation problems, missing error path tests, and integration gaps. Report
  each finding with priority, category, file:line, what's missing, and a
  suggested test.

Have each reviewer work independently, then report their findings.
Use delegate mode so you focus on coordination, not implementation.
Wait for all teammates to finish before synthesizing a final summary.
```

---

## What Happens

1. Claude creates a team named "code-review" with a shared task list
2. Three teammates spawn, each with their review specialty
3. Each reviewer independently scans the codebase through their lens
4. Findings arrive at the lead via the mailbox
5. The lead synthesizes all findings into a unified summary

## Variations

**Focused review** -- limit scope to specific directories:

```
Create an agent team to review src/auth/ and src/api/.
Spawn a security reviewer and a performance reviewer.
```

**Adversarial review** -- teammates challenge each other:

```
Create an agent team to investigate the login timeout bug.
Spawn 3 investigators with different hypotheses.
Have them debate and try to disprove each other's theories.
```

**Plan-first review** -- require approval before deep analysis:

```
Create an agent team to review the database migration.
Spawn a schema reviewer and a data integrity reviewer.
Require plan approval before they start their analysis.
```

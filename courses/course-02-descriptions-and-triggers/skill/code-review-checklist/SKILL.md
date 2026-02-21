---
name: code-review-checklist
description: Performs a structured code review covering correctness, readability, performance, security, and testing. Use when the user says "review this code", "code review", "check this PR", "review my changes", or asks for feedback on code quality. Produces a checklist with per-dimension verdicts and an overall assessment.
---

# Code Review Checklist

Perform a structured code review of the provided code, file, or diff. Evaluate each of the six dimensions below in order, then provide a final verdict.

## How to Review

1. If the user provides a file path, read the file first
2. If the user says "review my changes" or "check this PR", run `git diff` or `git diff --cached` to get the relevant changes
3. Evaluate each dimension below against the code
4. For each dimension, assign a verdict: PASS, WARN, or FAIL
5. Provide the overall verdict at the end

## Dimension 1: Correctness

Check whether the code does what it claims to do.

- Does the logic match the stated intent (function name, comments, PR description)?
- Are edge cases handled (empty input, null values, boundary conditions)?
- Are return types and values correct for all code paths?
- Do loops terminate correctly? Are off-by-one errors present?
- Are error conditions caught and handled, not silently swallowed?

Verdict: PASS if logic is sound with edge cases covered. WARN if minor gaps exist. FAIL if there are logic bugs or unhandled error paths.

## Dimension 2: Readability

Check whether another developer can understand this code quickly.

- Are variable and function names descriptive of their purpose?
- Is the code structure clear (small functions, logical grouping)?
- Are complex operations broken into named steps rather than nested one-liners?
- Is there unnecessary complexity that could be simplified?
- Are magic numbers or strings replaced with named constants?

Verdict: PASS if a new team member could follow the code without help. WARN if minor naming or structure issues. FAIL if the code is difficult to follow or uses misleading names.

## Dimension 3: Performance

Check for performance problems that would matter at the expected scale.

- Are there O(n^2) or worse operations on collections that could grow large?
- Are database queries or API calls made inside loops (N+1 problem)?
- Are large objects created unnecessarily in hot paths?
- Is there redundant computation that could be cached or memoized?
- For frontend code: are there unnecessary re-renders or layout thrashing?

Verdict: PASS if no performance concerns at expected scale. WARN if potential issues at higher scale. FAIL if there are clear performance bugs (N+1 queries, quadratic loops on unbounded input).

## Dimension 4: Security

Check for security vulnerabilities relevant to the code's context.

- Is user input validated and sanitized before use?
- Are SQL queries parameterized (no string concatenation)?
- Is sensitive data (passwords, tokens, keys) excluded from logs and error messages?
- Are authentication and authorization checks in place for protected operations?
- For web code: is output escaped to prevent XSS? Are CSRF tokens used for state-changing operations?

Verdict: PASS if no security concerns found. WARN if minor hardening opportunities exist. FAIL if there are exploitable vulnerabilities (SQL injection, XSS, exposed secrets).

## Dimension 5: Testing

Check whether the code has adequate test coverage for its risk level.

- Do tests exist for the core functionality being added or changed?
- Do tests cover the happy path AND at least one error/edge case?
- Are tests testing behavior (what the code does) not implementation (how it does it)?
- If this is a bug fix, is there a regression test that would have caught the original bug?
- If no tests exist for this code, note this as a gap

Verdict: PASS if tests adequately cover the changes. WARN if tests exist but miss edge cases. FAIL if no tests exist for non-trivial logic, or if existing tests are broken.

## Dimension 6: Overall Verdict

Synthesize the five dimensions into a final assessment.

- Summarize the 1-2 most important findings across all dimensions
- List specific action items the author should address before merging
- Note any strengths worth calling out (good patterns, thorough error handling, clean abstractions)

Final verdict:
- **APPROVE**: All dimensions PASS, or only minor WARNs that don't need changes before merge
- **REQUEST CHANGES**: Any dimension is FAIL, or multiple WARNs that together indicate risk
- **NEEDS DISCUSSION**: Architectural or design concerns that need team input before proceeding

## Output Format

Present the review in this format:

```
## Code Review: [filename or description]

### Correctness: [PASS/WARN/FAIL]
[1-3 bullet points with specific findings]

### Readability: [PASS/WARN/FAIL]
[1-3 bullet points with specific findings]

### Performance: [PASS/WARN/FAIL]
[1-3 bullet points with specific findings]

### Security: [PASS/WARN/FAIL]
[1-3 bullet points with specific findings]

### Testing: [PASS/WARN/FAIL]
[1-3 bullet points with specific findings]

---

### Verdict: [APPROVE / REQUEST CHANGES / NEEDS DISCUSSION]

**Summary**: [1-2 sentence summary of overall code quality]

**Action items**:
- [ ] [Specific thing to fix, with file and line reference]
- [ ] [Another specific thing to fix]

**Strengths**:
- [Something done well worth acknowledging]
```

## Rules

- Be specific: reference exact line numbers, variable names, and function names
- Be constructive: suggest fixes, not just problems
- Be proportional: a 5-line utility function doesn't need the same scrutiny as a payment processor
- If reviewing a diff, focus on the changed lines but note if surrounding context has issues
- If a dimension is not applicable (e.g., no security relevance in a CSS change), mark it PASS with "Not applicable for this change"

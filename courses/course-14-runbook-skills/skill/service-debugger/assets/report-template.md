# Investigation Findings Report

## Summary

{{One-line description of the finding. Be specific: what is broken, what is affected, and what is the likely cause. Example: "Auth middleware throws unhandled exception on expired JWT tokens after async refactor in commit abc1234."}}

## Severity

{{Assign one of the following severity levels and justify the classification.}}

| Level | Definition | Response |
|---|---|---|
| **P0 — Critical** | Service completely unavailable, data loss or corruption, security breach | Immediate response required, all hands on deck |
| **P1 — High** | Major feature broken, significant user impact, no workaround | Respond within 1 hour, dedicate resources |
| **P2 — Medium** | Feature degraded, workaround available, limited user impact | Respond within 4 hours, schedule fix |
| **P3 — Low** | Minor issue, cosmetic, edge case, minimal user impact | Respond within 1 business day |
| **P4 — Informational** | Observation, potential future issue, technical debt | Add to backlog, address when convenient |

**Assigned severity**: {{P0/P1/P2/P3/P4}}
**Justification**: {{Why this severity level? What is the scope of impact?}}

## Symptom

**Reported symptom**: {{The original symptom or alert as described by the user.}}

**Observed behavior**: {{What was actually observed during investigation. Include specific error messages, status codes, or metrics if found.}}

**Expected behavior**: {{What should be happening instead.}}

## Investigation Steps

{{List every step taken during the investigation, in order. Include the tool or command used and what was found. This creates an audit trail that others can follow.}}

1. **{{Step name}}**: {{What was done}}
   - Tool/Command: `{{command or tool used}}`
   - Finding: {{What was discovered}}

2. **{{Step name}}**: {{What was done}}
   - Tool/Command: `{{command or tool used}}`
   - Finding: {{What was discovered}}

3. **{{Step name}}**: {{What was done}}
   - Tool/Command: `{{command or tool used}}`
   - Finding: {{What was discovered}}

{{Continue numbering for all investigation steps. Do not omit steps even if they yielded no useful results -- negative findings ("checked X, found nothing wrong") are valuable for ruling out causes.}}

## Root Cause

**Status**: {{Determined / Probable / Undetermined}}

{{If Determined: Describe the exact root cause with specificity. Reference the file, line number, commit, or configuration that caused the issue.}}

{{If Probable: State the hypothesis and the evidence supporting it. Describe what additional data would confirm the hypothesis.}}

{{If Undetermined: List what was checked and eliminated. Describe what additional access, tools, or information would be needed to continue the investigation.}}

## Evidence

{{List specific evidence supporting the root cause determination. Each item should be independently verifiable.}}

1. **{{Evidence type}}**: {{Description}}
   - Source: `{{file path, log location, or command}}`
   - Detail: {{Exact content -- quote log lines, code snippets, or metric values}}

2. **{{Evidence type}}**: {{Description}}
   - Source: `{{file path, log location, or command}}`
   - Detail: {{Exact content}}

{{Include at minimum:}}
- {{Relevant code snippets with file paths and line numbers}}
- {{Git commits that introduced or relate to the issue}}
- {{Configuration values that are relevant}}
- {{Log excerpts if available}}
- {{Timeline correlations (e.g., "deploy at 14:00, first errors at 14:03")}}

## Recommended Actions

### Immediate (fix the active issue)

1. {{First immediate action — be specific and actionable}}
2. {{Second immediate action, if needed}}
3. {{Additional immediate actions}}

### Follow-up (prevent recurrence)

1. {{First follow-up action — address root cause permanently}}
2. {{Second follow-up action — add monitoring, tests, or guardrails}}
3. {{Additional follow-up actions}}

{{Each action should be specific enough that someone can execute it without additional context. "Fix the auth bug" is not actionable. "Add error handling for expired tokens in src/middleware/auth.ts:142, wrapping the jwt.verify() call in a try-catch that returns 401 instead of crashing" is actionable.}}

## Timeline

{{Reconstruct the timeline of events. Include timestamps where available, relative times where not.}}

| Time | Event |
|---|---|
| {{timestamp or relative time}} | {{What happened}} |
| {{timestamp or relative time}} | {{What happened}} |
| {{timestamp or relative time}} | {{What happened}} |
| {{timestamp or relative time}} | {{Investigation started}} |
| {{timestamp or relative time}} | {{Root cause identified / report generated}} |

{{If exact timestamps aren't available, use relative markers: "~2 days ago", "before latest deploy", "after commit abc1234".}}

## Additional Notes

{{Any observations, caveats, or context that doesn't fit the sections above. Examples:}}
- {{Areas that were not investigated and why}}
- {{Related issues that were noticed but are out of scope}}
- {{Assumptions made during the investigation}}
- {{Confidence level in the findings}}

{{If there are no additional notes, remove this section from the final report.}}

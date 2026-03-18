# Gotchas

## Duplicate items from merge commits
- **Symptom**: Yesterday section lists the same work item twice with slightly different wording
- **Wrong behavior**: Claude reads `git log` and includes both the original commit and the merge commit that brought it into main, producing entries like "Implemented login validation" and "Merge: Implemented login validation"
- **Correct behavior**: Use `git log --no-merges` to filter out merge commits. If merge commits have already been read, deduplicate by comparing the core content of commit messages before presenting items. Two entries about the same work should become one.

## Empty git history in new repos
- **Symptom**: Claude runs `git log` in a repo with no commits (or a freshly cloned repo with no local history) and gets an error or empty output
- **Wrong behavior**: Claude proceeds with the git-based approach and outputs an empty Yesterday section, or worse, shows the raw git error message in the standup output
- **Correct behavior**: Detect when `git log` returns empty or errors. Immediately fall back to asking the user: "I don't see recent git history. What did you work on since your last standup?" Never present an empty Yesterday section — either populate it from available context or ask explicitly.

## Weekend and Monday carry-over confusion
- **Symptom**: On Monday morning, the Yesterday section only shows Friday's final commits, missing any weekend work. Or it shows 3 days of commits as an overwhelming list.
- **Wrong behavior**: Claude uses `git log --since="yesterday"` which on Monday only captures Sunday, or uses a fixed `-10` count that may not span the full weekend
- **Correct behavior**: On Monday (or after any multi-day gap), use `git log --no-merges --since="last friday"` to capture the full weekend range. Change the section header from "Yesterday" to "Since Last Standup" to accurately reflect the time span. Consolidate the multi-day history into 2-4 high-level items rather than listing every commit across 3 days.

## Standup is too long for Slack posting
- **Symptom**: Generated standup has 6-8+ bullet points per section and would be an overwhelming wall of text in Slack
- **Wrong behavior**: Claude lists every individual commit as its own bullet point, treating the standup as a detailed changelog rather than a summary for humans
- **Correct behavior**: Group related commits into higher-level work items. "Fixed auth token refresh, updated token expiry logic, added token refresh tests" becomes "Completed auth token refresh feature (implementation + tests)". Aim for 2-4 bullets per section. If a section would exceed 4 items, step back and ask: "What are the 3 most important things?" and consolidate.

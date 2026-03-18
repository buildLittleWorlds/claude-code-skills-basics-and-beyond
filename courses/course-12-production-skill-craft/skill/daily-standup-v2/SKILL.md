---
name: daily-standup-v2
description: Generates a production-quality daily standup update with team context, cross-session memory, and edge case handling. Use when the user says "standup", "daily update", "what did I work on", "standup notes", "morning update", "scrum update", "what's my status", or "daily sync".
---

# Daily Standup Generator v2

Generate a daily standup update tailored to the user's team context, with awareness of past standups and known failure patterns.

## Setup

Before generating output, check if `config.json` exists in this skill's directory.

If it does NOT exist:
1. Ask the user for the following:
   - **Team name** — used in the standup header (e.g., "Platform Engineering")
   - **Slack channel** — for posting context (e.g., "#platform-standup")
   - **Standup time** — for greeting context (e.g., "09:30")
   - **Format preference** — "bullet" for bullet points, "paragraph" for prose summaries
2. Create `config.json` in this skill's directory with their responses
3. Confirm: "Config saved. Future standups will use these settings."

If it DOES exist:
1. Read the config silently
2. Apply the values throughout generation
3. Do NOT re-ask unless the user says "reconfigure standup", "update standup config", or "change standup settings"

## Format

Present the standup with the team name from config as a header:

### 📋 {team_name} Standup — {today's date}

**Since Last Standup**
- Summarize 2-4 completed items based on available context
- Each item should be a concrete accomplishment: "Fixed auth token refresh bug in login.ts" not "Worked on auth"
- Group related commits into single items rather than listing each commit

**Today**
- List 2-4 planned items based on available context
- Frame as intentions: "Will implement...", "Plan to review...", "Going to fix..."

**Blockers**
- List real blockers only — never invent issues to fill the section
- If none are apparent, write "No blockers" and move on

If `format_preference` in config is "paragraph", present each section as a 2-3 sentence prose summary instead of bullet points.

## Context Sources

Gather information from these sources in priority order. Use the best available source — do not fail if a higher-priority source is unavailable.

1. **Git history** — Run `git log --oneline --no-merges -15` for recent commits. If today is Monday, expand the range to cover Friday through Sunday: `git log --oneline --no-merges --since="last friday"`.
2. **Conversation context** — What the user has mentioned working on in the current session.
3. **Previous standup log** — Read `${CLAUDE_PLUGIN_DATA}/standup-log.jsonl` (if it exists) for carry-over items from the last standup. Items that appeared in "Today" last time but not in git history since then may still be in progress.
4. **Open issues** — If GitHub CLI is available, check `gh issue list --assignee=@me --state=open` for planned work.
5. **User input** — If none of the above sources yield enough context, ask the user directly. Never present an empty section.

## Rules

- Keep each bullet point to one line (under 100 characters)
- Use past tense for "Since Last Standup", future-oriented language for "Today"
- Provide a concrete example with every accomplishment — file names, function names, or issue numbers
- On Mondays, use "Since Last Standup" header instead of "Yesterday" and cover Friday-Sunday
- If standup exceeds 4 items per section, consolidate related items — a standup should take 30 seconds to read

## Execution Log

After generating the standup, append an entry to `${CLAUDE_PLUGIN_DATA}/standup-log.jsonl`:

```json
{"date": "YYYY-MM-DD", "yesterday": ["item1", "item2"], "today": ["item1", "item2"], "blockers": [], "team": "{team_name}"}
```

Create the file if it doesn't exist. Use JSONL format (one JSON object per line).

This log enables cross-session awareness: the next standup can reference what was planned today to check progress.

## Edge Cases

For known failure patterns and their correct handling, see [gotchas.md](./gotchas.md).

Key patterns to watch for:
- Duplicate items from merge commits (use `--no-merges` flag)
- Empty git history in new repos (fall back to asking the user)
- Monday carry-over spanning the weekend (expand date range)
- Overly long standups (consolidate, don't enumerate)

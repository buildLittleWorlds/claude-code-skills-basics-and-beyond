---
name: daily-standup
description: Generates a structured daily standup update in Yesterday/Today/Blockers format. Use when the user says "standup", "daily update", "what did I work on", or "standup notes".
---

# Daily Standup Generator

Generate a daily standup update using the following structure.

## Format

Present the standup in this exact format:

### Yesterday
- List 2-4 completed items based on recent git activity, open files, or conversation context
- Each item should be a concrete accomplishment, not a vague status
- If no context is available, ask the user what they worked on

### Today
- List 2-4 planned items based on open issues, TODOs, or conversation context
- Frame as intentions: "Will implement...", "Plan to review...", "Going to fix..."
- If no context is available, ask the user what they plan to work on

### Blockers
- List any blockers mentioned in conversation or discovered in the project
- If none are apparent, write "No blockers" rather than inventing issues

## Rules
- Keep each bullet point to one line (under 100 characters)
- Use past tense for Yesterday, future-oriented language for Today
- Be specific: "Fixed auth token refresh bug in login.ts" not "Worked on auth"
- If you have access to git history, use `git log --oneline -10` to inform Yesterday items
- If you have access to GitHub issues, check for assigned open issues to inform Today items

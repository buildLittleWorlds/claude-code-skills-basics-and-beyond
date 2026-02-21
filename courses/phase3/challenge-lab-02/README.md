# Challenge Lab 2: Session Transcript Hook + `/review-transcript`

**Difficulty**: Advanced | **Estimated time**: 45-60 min

## The Challenge

Build a two-part system:

1. **A `UserPromptSubmit` hook** that logs every prompt you send to a session transcript file
2. **A `/review-transcript` skill** that reads the transcript and suggests workflow improvements

No walkthrough. Design and build both pieces yourself.

## Part 1: The Transcript Hook

### Requirements

Create a hook that fires on `UserPromptSubmit` and appends each prompt to a session transcript file.

- **File location**: `~/work/_tasks/log/session-YYYY-MM-DD.md`
- **Entry format**:
  ```markdown
  ## HH:MM — Prompt
  > The user's prompt text here

  ---
  ```
- The hook receives JSON on stdin with the prompt text
- Create the file if it doesn't exist
- Always exit 0 (never block prompts — this is logging only)
- Must be fast (under 100ms) since it runs on every prompt

### Design Questions

- What's the JSON structure for `UserPromptSubmit`? (Hint: check the hooks docs or experiment)
- How do you extract the prompt text with `jq`?
- Should the hook use `>>` (append) or a temp file approach?
- What about multi-line prompts?

## Part 2: The `/review-transcript` Skill

### Requirements

Create a skill that reads today's session transcript and provides workflow analysis.

- Read `~/work/_tasks/log/session-YYYY-MM-DD.md`
- Analyze patterns:
  - Which skills did you invoke most? (count `/next`, `/done`, `/triage`, etc.)
  - How many prompts were task-management vs. freeform questions?
  - Did you follow the intended workflow rhythm (triage → next → work → done)?
  - Were there repeated or redundant prompts?
- Produce a short report with:
  - Prompt count and skill usage breakdown
  - Workflow adherence score (1-10)
  - Specific suggestions for improvement
  - Time distribution if timestamps allow

### Design Questions

- Should this be inline or forked? (Consider: the transcript could be long)
- Should it use dynamic context to inject the transcript, or read it via tools?
- Would a reference file with "ideal workflow patterns" improve the analysis?

## Acceptance Criteria

### Transcript Hook
- [ ] Every prompt is logged to `~/work/_tasks/log/session-YYYY-MM-DD.md`
- [ ] Entries include timestamp and full prompt text
- [ ] Multi-line prompts are captured correctly
- [ ] The hook never blocks or slows down prompt submission
- [ ] The log file is append-only (never overwritten)

### Review Transcript Skill
- [ ] `/review-transcript` reads today's session log
- [ ] Output includes skill usage counts
- [ ] Output includes workflow adherence assessment
- [ ] Output includes specific improvement suggestions
- [ ] Handles the case where no transcript exists for today

## Hints (only if stuck)

<details>
<summary>Hint 1: UserPromptSubmit JSON</summary>

The `UserPromptSubmit` hook receives JSON like:
```json
{
  "prompt": "the text the user typed",
  "session_id": "..."
}
```

Extract with: `jq -r '.prompt'`

</details>

<details>
<summary>Hint 2: Hook settings</summary>

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "type": "command",
        "command": "bash ~/.claude/hooks/log-prompt.sh"
      }
    ]
  }
}
```

No matcher needed — log all prompts.

</details>

<details>
<summary>Hint 3: Review skill approach</summary>

Fork it. The transcript could be hundreds of lines, and the analysis involves counting patterns across all entries. Use `context: fork` with `agent: Explore` so the analysis doesn't clutter your main conversation.

</details>

## What You're Practicing

- Building a hook for a new lifecycle event (`UserPromptSubmit`)
- Designing a hook + skill that work together (hook writes data, skill reads it)
- JSON parsing with `jq` in a hook context
- Analysis-focused skill design (reading data and producing insights)
- The full build cycle: design → implement → test → iterate

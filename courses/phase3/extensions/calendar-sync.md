# Extension: Calendar Sync

Sync task due dates with an actual calendar for time-aware scheduling.

## What It Enables

- **Visual timeline**: See tasks alongside meetings and events
- **Smart scheduling**: `/triage` assigns due dates based on available time
- **Conflict detection**: Warn when a task is due on a day full of meetings
- **Reminder integration**: Calendar reminders for high-priority task deadlines

## Architecture

```
Calendar API (Google Calendar / Apple Calendar)
        ↕ MCP server or CLI tool
Claude Code with skills
        ↕
~/work/_tasks/pending/*.md (due dates)
```

Two possible implementations:
1. **MCP approach**: Use a calendar MCP server for read/write access
2. **CLI approach**: Use `gcalcli` or `icalBuddy` via Bash tool calls

## Implementation Sketch

### 1. Calendar-Aware Triage

Modify `/triage` to consider calendar availability when assigning due dates:

Add to the SKILL.md dynamic context:
```
This week's calendar:
!`gcalcli agenda --nocolor $(date +%Y-%m-%d) $(date -v+7d +%Y-%m-%d) 2>/dev/null || echo "(no calendar access)"`
```

Add to the workflow: "When assigning due dates, check the calendar. Avoid setting due dates on days with 4+ hours of meetings."

### 2. `/calendar` Skill

New skill that shows a merged view:

```yaml
---
name: calendar
description: Shows today's calendar alongside task deadlines. Use when the user says "what's my day look like", "calendar", or invokes /calendar.
context: fork
agent: Explore
allowed-tools: Read, Glob, Grep, Bash(gcalcli *)
---
```

Output format:
```
📅 Today's Schedule — Wednesday, Feb 21
═══════════════════════════════════════════
  09:00-09:30  Team standup (calendar)
  10:00-11:00  Sprint planning (calendar)
  ── 11:00-12:00  Available ──
  📋 Fix API timeout (overdue, P1)
  12:00-13:00  Lunch
  ── 13:00-15:00  Available ──
  📋 Write quarterly report (due today, P2)
  15:00-16:00  1:1 with manager (calendar)
  ── 16:00-17:00  Available ──
  📋 Review onboarding docs (due tomorrow, P2)
```

### 3. Due Date Sync to Calendar

Create a `/sync-calendar` skill that:
- Reads all pending tasks with due dates
- Creates calendar events for P1 and P2 task deadlines
- Sets reminders: P1 tasks get a 1-day-before reminder, P2 get a 3-day-before
- Avoids duplicates by checking for existing events with matching titles

### 4. Startup Integration

Modify the `tasks` startup script to run `/calendar` instead of (or alongside) `/today` on launch, giving you a time-aware morning view.

## Phase 2 Skills Needed

- **Course 5**: Dynamic context (`!`command``) for calendar data injection
- **Course 5**: `allowed-tools: Bash(gcalcli *)` for CLI calendar access
- **Course 5**: `context: fork` for heavy calendar queries
- **Course 3**: Reference file with calendar preferences (work hours, meeting buffer time)

## Considerations

- **Privacy**: Calendar data may contain sensitive information — be careful about what gets logged
- **API rate limits**: Cache calendar queries, don't re-fetch on every skill invocation
- **Time zones**: Ensure date comparisons account for local time zone
- **Offline**: Skills should work without calendar access (fall back to date-only view)
- **Authentication**: Calendar CLI tools need separate auth setup (not part of skill config)

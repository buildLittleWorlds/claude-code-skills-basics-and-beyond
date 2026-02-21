# Extension: MCP Integration

Connect the task cockpit to external services via Model Context Protocol.

## What It Enables

- **Notion sync**: Tasks created in Notion appear in your inbox automatically
- **Slack integration**: Mark tasks done from Slack, get overdue alerts in a channel
- **Calendar views**: See task due dates alongside calendar events

## Architecture

```
External services (Notion, Slack, Calendar)
        ↕ MCP servers
Claude Code with skills
        ↕ File system
~/work/_tasks/{inbox, pending, archive, log}
```

MCP servers provide the connectivity. Your skills provide the workflow logic. The task files remain the source of truth.

## Implementation Sketch

### 1. Notion → Inbox Pipeline

Install a Notion MCP server. Create a `/sync-notion` skill that:
- Queries a Notion database for items tagged "task-cockpit"
- For each item, creates a markdown file in `~/work/_tasks/inbox/`
- Uses the Notion page content as the task body
- Marks the Notion item as "synced" to prevent duplicates

Key SKILL.md feature: `allowed-tools` should include the Notion MCP tools.

### 2. Slack Notifications

Install a Slack MCP server. Modify `/overdue` to:
- After displaying the overdue report, send Tier 3+ items to a Slack channel
- Use `tmux display-popup` locally AND post to Slack for mobile awareness

Alternatively, create a new `/slack-report` skill that formats the `/today` output for Slack.

### 3. Calendar View

Install a Google Calendar (or similar) MCP server. Create a `/calendar` skill that:
- Reads pending tasks with due dates
- Queries today's calendar events
- Produces a merged timeline view showing both tasks and meetings
- Highlights scheduling conflicts (task due at 5pm but you have meetings 3-5pm)

## Phase 2 Skills Needed

- **Course 3**: Reference files for MCP server configuration
- **Course 5**: `allowed-tools` to grant MCP tool access to specific skills
- **Course 5**: `context: fork` for heavy data-fetching operations
- **Course 7**: Hooks could auto-sync on `PostToolUse` after `/done`

## Considerations

- MCP servers add API call latency — fork heavy operations
- Rate limits: batch Notion/Slack operations, don't call per-task
- Offline mode: skills should degrade gracefully if MCP server is unavailable
- Security: MCP credentials stay in server config, never in skill files

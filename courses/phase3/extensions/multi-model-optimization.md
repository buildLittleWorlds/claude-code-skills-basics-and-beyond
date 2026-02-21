# Extension: Multi-Model Optimization

Route different skills to different models based on task complexity and cost.

## What It Enables

- **Faster responses**: Simple queries (like `/next`) use Haiku
- **Lower costs**: Read-only operations don't need Sonnet's capabilities
- **Better quality where it matters**: Complex skills (like `/triage`) use Sonnet

## Current State

The cockpit already uses model selection for forked skills:
- `/today` uses `agent: Explore` (Haiku)
- `/session-summary` uses `agent: Explore` (Haiku)

But inline skills (`/next`, `/done`, `/triage`, `/overdue`) use whatever model your Claude Code session is running.

## Implementation Sketch

### 1. Fork Simple Skills

Convert `/next` to a forked skill:

```yaml
---
name: next
context: fork
agent: Explore
allowed-tools: Read, Glob, Grep
---
```

Trade-off: `/next` currently runs inline so you can say "tell me more about task 2." Forking loses that follow-up ability but saves context and uses Haiku.

Recommendation: Keep `/next` inline (it's small) but fork `/overdue` (its analysis is self-contained).

### 2. Create a Custom Agent for Triage

Create `.claude/agents/triage-agent.md`:

```yaml
---
name: triage-agent
model: sonnet
tools: [Read, Write, Glob, Grep, Bash]
---

You are a task triage specialist. You read inbox items and classify them
with domain, priority, due date, and tags based on reference files.
```

Then update `/triage` to use `agent: triage-agent` with `context: fork`. This ensures triage uses Sonnet for better classification quality while keeping the work isolated.

### 3. Cost Tracking

Create a simple cost-tracking approach:
- Log which model each skill invocation uses
- Track invocations per day in the session log
- Review in `/weekly-review` to identify optimization opportunities

## Model Selection Guide

| Skill | Recommended Model | Reasoning |
|-------|------------------|-----------|
| `/next` | Inherit (inline) | Small output, interactive follow-up useful |
| `/done` | Inherit (inline) | Needs file modification tools, interactive |
| `/triage` | Sonnet (forked) | Classification quality matters |
| `/today` | Haiku (forked) | Read-only report generation |
| `/overdue` | Haiku (forked) | Read-only, self-contained analysis |
| `/session-summary` | Haiku (forked) | Read-only report generation |

## Phase 2 Skills Needed

- **Course 5**: `context: fork` and `agent` field
- **Course 8**: Custom subagents with explicit model selection
- **Course 5**: `allowed-tools` for tool restriction per model

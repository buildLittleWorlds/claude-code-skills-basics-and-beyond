# Prioritization Guide: Eisenhower Matrix for Action Items

Use this guide to classify action items extracted from meeting notes into priority levels.

## The Eisenhower Matrix

Classify each action item along two axes:
- **Urgency**: How time-sensitive is this? Is there a hard deadline or external pressure?
- **Importance**: How much does this impact business goals, customers, or team productivity?

```
                    URGENT              NOT URGENT
              ┌──────────────────┬──────────────────┐
  IMPORTANT   │  P1: Do First    │  P2: Schedule     │
              │                  │                    │
              │  Act immediately │  Plan and allocate │
              │  High impact +   │  High impact,      │
              │  time pressure   │  flexible timing   │
              ├──────────────────┼──────────────────┤
  NOT         │  P3: Delegate    │  P4: Defer         │
  IMPORTANT   │                  │                    │
              │  Time-sensitive   │  Low impact,       │
              │  but lower impact│  no time pressure  │
              └──────────────────┴──────────────────┘
```

## Classification Rules

### P1 - Urgent + Important (Do First)

Assign P1 when ANY of these conditions apply:
- Deadline is within 3 calendar days
- Action item blocks other team members' work
- Keywords present: "blocker", "critical", "release", "outage", "customer-facing", "before launch"
- Action relates to an active incident or production issue
- External stakeholder or customer is waiting on this

Examples:
- "Fix payment timeout bug before Friday release" (deadline + release keyword)
- "Unblock the frontend team by providing the API spec" (blocking others)
- "Respond to customer escalation about data export" (customer-facing)

### P2 - Important, Not Urgent (Schedule)

Assign P2 when:
- The work has significant business or technical value
- Deadline is more than 3 days away OR is flexible ("by end of month", "this quarter")
- Keywords present: "spec", "architecture", "refactor", "strategy", "roadmap", "design"
- The work builds foundation for future priorities
- No one is actively blocked waiting for this

Examples:
- "Write technical spec for notification system by end of month" (important, flexible deadline)
- "Plan the Q2 migration strategy" (strategic, no hard deadline)
- "Refactor auth module to support SSO" (important but not urgent)

### P3 - Urgent, Not Important (Delegate)

Assign P3 when:
- There is a hard deadline within a week
- But the impact is operational/administrative rather than strategic
- Keywords present: "update", "report", "sync", "admin", "meeting", "schedule"
- The work is routine or process-related
- Could be handled by any team member (not specialized)

Examples:
- "Update the sprint board before standup tomorrow" (time-sensitive, routine)
- "Send the weekly status report by Friday" (deadline, administrative)
- "Schedule the design review meeting this week" (time-sensitive, operational)

### P4 - Neither Urgent nor Important (Defer)

Assign P4 when:
- No clear deadline or deadline is far out (more than 2 weeks)
- The work is exploratory, nice-to-have, or aspirational
- Keywords present: "look into", "explore", "consider", "nice to have", "when we get time"
- No one is blocked and no customer impact
- Could be dropped without immediate consequences

Examples:
- "Look into upgrading to the latest framework version" (exploratory)
- "Consider adding dark mode support" (nice-to-have)
- "Explore better monitoring options when we get time" (aspirational)

## Tie-Breaking Rules

When an item could fit multiple categories:

1. **Deadline takes precedence**: If the deadline is within 3 days, it's at least P3 regardless of importance signals.
2. **Blocking takes precedence**: If the item blocks other team members, escalate by one level (P3 -> P2, P2 -> P1).
3. **Customer-facing takes precedence**: Anything that affects customers directly gets an importance boost.
4. **When in doubt, choose the higher priority**: It's better to over-prioritize than to miss something critical. The owner can always re-prioritize later.

## Handling Ambiguity

If you cannot determine urgency or importance from the meeting notes:
- Assign P2 as a safe default (important enough to track, not panic-inducing)
- Note "Priority assigned with limited context" in the output
- Suggest the team review and adjust priorities

# Skills vs Sub-agents vs Agent Teams: Decision Guide

**Cross-reference**: This document supplements Course 8 (Custom Subagents) and Course 10 (Agent Teams). Read those lessons first for the technical details of each mode.

---

## The Default Rule

Start with a skill. Escalate only when you observe specific pain signals.

Skills are faster to build, cheaper to run, simpler to debug, and avoid all orchestration overhead. Sub-agents and agent teams are powerful but carry complexity costs that must justify themselves. Most workflows that people reach for sub-agents or teams to solve would be better served by a well-built skill.

---

## Three-Way Comparison

| Criteria | Skill | Sub-agent | Agent Team |
|---|---|---|---|
| **Context** | Shared -- everything in the main session | Isolated -- each agent has its own window | Isolated -- each teammate has its own window |
| **Communication** | Same conversation | Agent reports to orchestrator only (bottleneck) | Teammates message each other and the lead |
| **Parallelism** | None -- sequential only | Parallel spawning, but orchestrator collects all results | Full -- teammates work independently and collaborate |
| **Token cost** | Lowest | Moderate (orchestration overhead per agent) | Highest (coordination messages, shared task list, concurrent sessions) |
| **Independent critique** | Weak (self-critic bias -- see below) | Strong (separate context reviews the work) | Strong (peers can challenge each other) |
| **Iteration style** | Rereads files and context in the same session | Orchestrator manages iteration (tedious bottleneck) | Teammates iterate directly with each other |
| **Setup complexity** | Just the skill folder | Agent definition + orchestration pipeline + context passing | Team orchestration + task design + ownership boundaries |
| **Memory** | Main session memory (CLAUDE.md, memory files) | `memory` field in agent frontmatter | No standard mechanism yet (CLAUDE.md workarounds) |
| **Best pipeline type** | Sequential, one-shot, context-rich | Chain pipelines, verbose/isolated work, result-focused | Collaborative, creative, iterative feedback loops |

---

## Self-Critic Bias

When a skill runs in the main session, the same context window that produced the work also evaluates it. This creates a **self-critic bias**: Claude tends to be lenient when reviewing its own prior output within the same conversation.

This matters when your workflow includes a review or critique step. If the quality of self-review is critical to your pipeline, delegate the review to a sub-agent or agent team member with its own isolated context. A separate agent reviewing another agent's output produces more honest, rigorous feedback.

**When self-critic bias is acceptable**: Low-stakes refinement loops, formatting checks, simple validation where a script handles the real verification.

**When self-critic bias is a problem**: Code review, security audits, content quality gates, any workflow where the critique step materially affects the outcome.

---

## Decision Framework

Work through these questions in order. Stop at the first "yes":

```
1. Can one main session handle the full workflow
   without filling the context window?
   ├── YES → Use a skill
   └── NO or UNSURE → Continue...

2. Do the workers need to talk to each other
   for the work to succeed?
   ├── YES → Agent team
   └── NO → Continue...

3. Is the output verbose or context-heavy
   enough to pollute the main session?
   ├── YES → Sub-agent
   └── NO → Continue...

4. Do you need different tool restrictions
   or permission isolation per phase?
   ├── YES → Sub-agent
   └── NO → Continue...

5. Do you need parallel work where the workers
   don't need to cross-communicate?
   ├── YES → Sub-agent
   └── NO → Use a skill
```

If none of the escalation signals apply, stay with a skill (or a combination of skills) as long as the context window can sustain it.

---

## Escalation Signals: When to Level Up

### Skill --> Sub-agent

Observe these signals in your skill-based workflow:

| Signal | What you see | Why sub-agents help |
|---|---|---|
| Context window filling up | Compaction warnings, loss of detail, Claude forgetting earlier steps | Sub-agent does heavy work in its own window, returns only the summary |
| Self-critic bias is a problem | Claude is too lenient reviewing its own output | Separate context provides independent evaluation |
| Need tool restrictions per phase | Some steps should be read-only, others need write access | Sub-agents have per-agent `tools` and `permissionMode` fields |
| Verbose intermediate output | Steps produce large output that clutters the main session | Sub-agent contains all intermediate steps; main session gets the result |
| Complex process you know will cause context issues | Long multi-step pipeline with heavy file reads | Offload to sub-agents before you hit the wall |

### Sub-agent --> Agent Team

Observe these signals in your sub-agent pipeline:

| Signal | What you see | Why teams help |
|---|---|---|
| Orchestrator is a bottleneck | Main session spends most of its time relaying context between sub-agents | Teammates communicate directly without passing through the lead |
| Workers need to challenge each other | A reviewer should push back on an implementer's choices | Teammates can have back-and-forth discussions |
| Feedback loops are tedious | Orchestrator gives feedback to sub-agent, sub-agent revises, sends back, repeat | Teammates iterate directly with each other |
| Sustained parallel exploration | Research tasks where each agent builds its own context over time | Teammates maintain persistent context and share findings organically |
| Creative work needs direct collaboration | Design, brainstorming, or synthesis tasks | Teammates can build on and challenge each other's ideas |

---

## De-escalation Signals: When to Level Down

Escalation isn't permanent. Watch for signals that a simpler mode would work better.

### Agent Team --> Sub-agent

| Signal | Action |
|---|---|
| Token cost is disproportionate to value | Teams consume significantly more tokens than sub-agents for the same outcome |
| Tasks are mostly sequential | If one agent must finish before the next can start, parallelism isn't helping |
| Teammates aren't actually communicating | If no meaningful inter-agent messages occur, the team overhead is wasted |
| Coordination overhead exceeds parallelism benefits | More time spent coordinating than working |

### Sub-agent --> Skill

| Signal | Action |
|---|---|
| Task is quick and well-scoped | If a sub-agent finishes in seconds, the spawn overhead isn't worth it |
| Context passing is the main difficulty | If most effort goes into ensuring the sub-agent has the right context, a single session avoids the problem entirely |
| You don't need isolation | If tool restrictions and separate context aren't adding value, the simpler path is better |

---

## Emergent Behavior in Teams

Agent teams can exhibit emergent collaboration -- teammates autonomously opening discussions with each other, going beyond their assigned scope when they notice relevant patterns, or converging on solutions through peer discussion that wasn't explicitly orchestrated.

This is both a strength and a risk:
- **Strength**: Teams can produce insights that no single agent or orchestrated pipeline would surface, because peer interaction stimulates deeper analysis.
- **Risk**: Emergent behavior means less predictability and control. If you need tight control over the workflow, the orchestration overhead to constrain teams can be significant.

If you observe valuable emergent behavior, lean into it. If you observe wasteful tangents, tighten the task definitions and ownership boundaries (see Course 10's ownership boundaries section).

---

## Quick Reference: Mode Selection by Pipeline Type

| Pipeline type | Recommended mode | Why |
|---|---|---|
| Sequential 3-5 step workflow | Skill | Context continuity, no orchestration overhead |
| One-shot task with structured output | Skill | Fast, cheap, consistent |
| Verbose analysis you need a summary of | Sub-agent | Keeps main session clean |
| Chain pipeline (A feeds B feeds C) | Sub-agent | Each link is isolated; pass results between stages |
| Review + critique of generated work | Sub-agent or Team | Avoids self-critic bias |
| Parallel independent research | Sub-agent | Spawn multiple, collect results |
| Parallel research with discussion | Agent team | Teammates share and challenge findings |
| Feature with frontend + backend + tests | Agent team | Each teammate owns a layer, can coordinate at boundaries |
| Competing hypotheses to evaluate | Agent team | Parallel exploration with convergence discussion |
| Creative iteration with feedback loops | Agent team | Direct peer feedback without orchestrator bottleneck |

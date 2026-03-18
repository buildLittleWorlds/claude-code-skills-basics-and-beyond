# Course 14: Runbook Skills — Symptom-Driven Investigation
**Level**: Advanced | **Estimated time**: 50 min

## Prerequisites
- Completed **Courses 1-5** (skills fundamentals, descriptions, anatomy, testing, advanced features including `context: fork` and `agent: Explore`)
- Completed **Course 8: Custom Subagents** (forked investigation, agent delegation, tool restrictions)
- Familiarity with basic debugging workflows (reading logs, checking metrics, tracing errors)
- Claude Code installed and working (`claude` command available)

## Concepts

### What Is a Runbook?

A **runbook** is a structured procedure for investigating and resolving operational issues. In traditional operations, runbooks are wiki pages or PDF documents that on-call engineers follow when an alert fires. They capture institutional knowledge: "When you see symptom X, check Y, then Z, then escalate if..."

As a Claude Code skill, a runbook becomes something more powerful: an **executable investigation procedure** that combines human judgment with automated data gathering. Instead of an engineer manually running commands and interpreting output, the skill orchestrates the investigation -- querying logs, checking metrics, reading code, and synthesizing findings into a structured report.

### Runbooks vs Scripts: Why Judgment Matters

A common mistake is treating runbooks as scripts. They are fundamentally different:

| Aspect | Script | Runbook Skill |
|---|---|---|
| **Execution** | Linear, top-to-bottom | Branching, based on findings |
| **Decision making** | None -- follows fixed steps | Interprets results, chooses next step |
| **Input** | Fixed parameters | Symptoms that need interpretation |
| **Output** | Raw command output | Structured findings with analysis |
| **Adaptability** | Fails on unexpected input | Adjusts investigation path based on evidence |
| **Knowledge** | Encoded in conditionals | Encoded in natural language guidance |

A script says: "Run `kubectl get pods`, parse the output, check if any pod is in CrashLoopBackOff." A runbook skill says: "Check pod status. If you see crash loops, investigate the logs of the crashing pod. If you see pending pods, check node resources and scheduling constraints. If everything looks healthy, move to the next layer."

The branching is the key difference. Scripts handle known paths with conditionals. Runbook skills handle unknown paths with judgment -- Claude reads the symptom map, gathers data, interprets what it finds, and decides what to investigate next.

### Concept 1: Runbook Anatomy

Every runbook skill follows a four-part structure:

```
Symptom → Tools → Query Patterns → Structured Report
```

1. **Symptom**: The starting point. An error message, an alert, a user report. The skill accepts this as input via `$ARGUMENTS`.

2. **Tools**: The instruments available for investigation. CLI commands (`git log`, `grep`, `curl`), MCP tools (if connected to observability platforms), file reading, and code search.

3. **Query Patterns**: What to look for with each tool. Not just "run this command" but "run this command and look for this pattern in the output." The symptom map in `references/` stores these patterns.

4. **Structured Report**: The output format. A template in `assets/` ensures every investigation produces consistent, actionable findings.

The SKILL.md orchestrates these four parts. It tells Claude: "Read the symptom, consult the symptom map to determine your investigation path, use the listed tools to gather evidence, and produce a report using the template."

### Concept 2: Symptom Routing

Symptom routing is the decision tree that maps symptoms to investigation paths. It answers the question: "Given this symptom, what should I check first?"

A symptom map is a reference file (`references/symptom-map.md`) that contains entries like:

```markdown
## High Latency / Slow Responses

### Tools to Use
- `git log --since="2 days ago" --oneline` -- check recent deployments
- `grep -r "timeout" --include="*.yaml"` -- find timeout configurations
- Check application logs for slow query warnings

### What to Look For
- Recent code changes to hot paths
- Database query changes
- New middleware or interceptors
- Changed timeout or pool configurations

### Common Root Causes
- N+1 query introduced in recent commit
- Missing database index after schema change
- Connection pool exhaustion
- External service degradation
```

The skill reads this map and matches the user's symptom description to the most relevant category. This is where Claude's judgment comes in -- a symptom like "API responses are slow after yesterday's deploy" maps to both "High Latency" and "Deployment-Related Issues." Claude reads both sections and synthesizes an investigation plan.

**Why a reference file instead of inline content?** Three reasons:

1. **Maintainability**: The symptom map grows as your team encounters new failure modes. A separate file is easier to update than editing the SKILL.md.
2. **Progressive disclosure**: The SKILL.md stays focused on the investigation workflow. The symptom map provides depth when needed.
3. **Reusability**: Multiple skills can reference the same symptom map. A `service-debugger` skill and an `incident-responder` skill might share the same diagnostic knowledge.

### Concept 3: Multi-Tool Investigation

Real investigations require multiple tools working together. A single `grep` or a single log query rarely tells the whole story. The power of a runbook skill is composing tools in sequence, where each tool's output informs what you check next.

**The investigation funnel pattern:**

```
Wide sweep (what's happening?)
    ↓ narrow based on findings
Targeted search (where is it happening?)
    ↓ narrow based on findings
Deep dive (why is it happening?)
    ↓ confirm with evidence
Root cause (what specifically broke?)
```

At each level, different tools are appropriate:

| Investigation Phase | Tools | Purpose |
|---|---|---|
| **Wide sweep** | `git log`, service status, recent alerts | Establish timeline, identify changes |
| **Targeted search** | `grep`, `Glob`, log queries | Find specific error patterns |
| **Deep dive** | `Read` specific files, trace analysis | Understand the code path |
| **Root cause** | `git diff`, `git blame`, config comparison | Pinpoint the exact change |

**Ordering matters.** Always gather context before diving deep. A common anti-pattern is jumping straight to reading code without first establishing when the problem started and what changed. The timeline often reveals the root cause faster than code analysis.

**Example investigation sequence:**

```
1. git log --since="3 days ago" --oneline
   → Found: deploy abc123 "Refactor auth middleware" 2 days ago

2. grep -rn "AuthMiddleware" src/
   → Found: src/middleware/auth.ts, src/routes/api.ts

3. git diff abc123~1..abc123 -- src/middleware/auth.ts
   → Found: Changed from sync to async, added new await

4. Read src/middleware/auth.ts (current version)
   → Found: Missing error handling on the new async path

5. Root cause: Unhandled promise rejection in auth middleware
   after async refactor in commit abc123
```

Each step narrows the investigation. The skill guides Claude through this funnel, but Claude decides when to move to the next phase based on what it finds.

### Concept 4: Structured Report Output

Investigations are only useful if the findings are communicated clearly. A template in `assets/report-template.md` ensures every investigation produces consistent output that the team can act on.

The template includes:

- **Summary**: One sentence describing the finding. Forces clarity.
- **Severity**: P0-P4 classification. Tells the team how urgently to respond.
- **Symptom**: What was observed. Links the finding back to the original alert.
- **Investigation Steps**: What was checked, in order. Creates an audit trail.
- **Root Cause**: Determined or suspected. Honest about uncertainty.
- **Evidence**: Specific log lines, code references, metrics. Backs up the finding.
- **Recommended Actions**: Immediate fixes and follow-up tasks. Actionable, not vague.
- **Timeline**: When things happened. Essential for incident reviews.

**Why templates matter for AI-driven investigations:**

Without a template, Claude produces free-form text that varies in structure and completeness with every run. With a template, every report has the same sections, making it easy to scan, compare across incidents, and ensure nothing is missed.

The template also acts as a **completeness check**. If Claude can't fill in the "Evidence" section, the investigation isn't done. If the "Root Cause" is "Undetermined," the report should explain what was checked and what remains.

### Concept 5: Forked Investigation

Investigations are verbose. They involve reading many files, running many commands, and generating intermediate output that clutters the main conversation. This is exactly the use case for `context: fork` from Course 5.

When `service-debugger` runs in a forked context:

1. The main conversation sends the symptom to the skill
2. A subagent (Explore) spins up with its own context window
3. The subagent reads the symptom map, runs tools, gathers evidence
4. The subagent produces the structured report
5. Only the final report returns to the main conversation
6. All intermediate work (file reads, grep results, log output) stays in the subagent's context

**Why this matters:**

- **Context preservation**: Your main conversation stays focused on the problem, not filled with raw grep output and log lines
- **Isolation**: The investigation can't accidentally modify files (Explore agent is read-only)
- **Cost efficiency**: The Explore agent uses Haiku, which is faster and cheaper for the data-gathering phase
- **Repeatability**: You can run the same investigation multiple times without context buildup

**The fork + report pattern:**

```yaml
context: fork
agent: Explore
```

Combined with the report template, this creates a clean separation:
- The **subagent** does the messy work (reading files, running commands, interpreting output)
- The **main conversation** receives a clean, structured report
- The **template** ensures the report contains everything needed to act

This pattern -- forked investigation with structured output -- is reusable across many runbook skills. An incident responder, a performance analyzer, a dependency auditor, and a security scanner all follow the same shape: gather data in isolation, return structured findings.

## Key References
- Course 5: `context: fork`, `agent: Explore`, `allowed-tools` -- the isolation primitives used by runbook skills
- Course 8: Custom subagents, tool restrictions, the delegation pattern
- Course 3: `references/` and `assets/` directories -- progressive disclosure for investigation knowledge
- Skills docs: "Run skills in a subagent" section -- how forked execution works
- Skills docs: "Pass arguments to skills" section -- `$ARGUMENTS` for symptom input

## What You're Building

A **service-debugger** skill that investigates operational issues using a symptom-driven approach. The skill:

1. Accepts an error signature, alert description, or symptom as input via `$ARGUMENTS`
2. Reads `references/symptom-map.md` to determine the investigation path
3. Uses multiple tools (git log, grep, file reading, CLI commands) to gather evidence
4. Produces a structured findings report using `assets/report-template.md`
5. Runs in a forked Explore agent to keep the main conversation clean

Here's the file structure:

```
service-debugger/
├── SKILL.md                        # Investigation orchestration
├── references/
│   └── symptom-map.md              # Symptom-to-investigation mappings
└── assets/
    └── report-template.md          # Structured findings report template
```

This skill demonstrates all five concepts from this course:
- **Runbook anatomy**: Symptom → tools → query patterns → structured report
- **Symptom routing**: The symptom map drives the investigation path
- **Multi-tool investigation**: Composed tool usage with progressive narrowing
- **Structured report output**: Template-driven consistent findings
- **Forked investigation**: Isolated execution with clean report return

## Walkthrough

### Step 1: Understand the design decisions

Before writing code, understand why each piece exists:

| Component | Purpose | Design Choice |
|---|---|---|
| `SKILL.md` | Orchestrate investigation | Fork into Explore agent for isolation |
| `references/symptom-map.md` | Map symptoms to tools | Separate file for maintainability |
| `assets/report-template.md` | Structure output | Template ensures completeness |
| `$ARGUMENTS` | Accept symptom input | Free-form text, not structured params |
| `context: fork` | Isolate investigation | Keeps main context clean |

The symptom input is deliberately free-form. Users might say "API is returning 500 errors" or paste an alert like `CRITICAL: service-auth response time >5s`. Claude interprets the symptom and matches it against the symptom map categories. This is judgment-based routing, not keyword matching.

### Step 2: Create the symptom map

The symptom map is the knowledge base that drives investigation routing. Create `references/symptom-map.md` with categories for common failure modes.

Study the provided symptom map file. Notice the structure of each category:

```markdown
## Category Name

### Tools to Use
- Specific commands with explanations

### What to Look For
- Patterns that indicate this category

### Common Root Causes
- Known causes from past incidents

### Escalation Criteria
- When to stop investigating and escalate
```

Each category is a mini-runbook within the larger map. When Claude reads a symptom like "users are getting 503 errors," it finds the "5xx Errors / Service Crashes" category and follows that section's guidance.

**Key design principle**: The symptom map should be exhaustive enough to cover common cases but not so detailed that it overwhelms. Seven to eight categories with 10-15 items each is a good balance. You can always add more categories as your team encounters new failure modes.

### Step 3: Create the report template

The report template defines the output structure. Create `assets/report-template.md` with placeholder markers that Claude fills in during the investigation.

Study the provided template file. Notice the placeholder format:

```markdown
**Summary**: {{one-line finding}}
**Severity**: {{P0-P4 with justification}}
```

The `{{placeholder}}` markers serve two purposes:
1. They tell Claude exactly what to fill in
2. They create a visual distinction between template structure and content

The severity scale (P0-P4) is defined in the template itself, so Claude can classify consistently without needing external context.

### Step 4: Create the SKILL.md

The SKILL.md orchestrates the entire investigation. Study the provided file and note the key sections:

1. **Frontmatter**: Sets up forked execution with Explore agent
2. **Investigation Workflow**: Step-by-step procedure with decision points
3. **Symptom Matching**: Instructions to read and match against the symptom map
4. **Tool Usage**: Ordered data gathering from broad to narrow
5. **Report Generation**: Instructions to use the template
6. **Gotchas**: Common pitfalls and how to avoid them

The SKILL.md doesn't contain the investigation knowledge (that's in the symptom map) or the output format (that's in the template). It contains the **procedure** -- how to connect input symptoms to the right knowledge and produce the right output.

### Step 5: Install the skill

Copy the skill to your personal skills directory:

```bash
cp -r courses/course-14-runbook-skills/skill/service-debugger ~/.claude/skills/service-debugger
```

Verify the structure:

```bash
ls -R ~/.claude/skills/service-debugger/
```

You should see:

```
SKILL.md
assets/
references/

assets:
report-template.md

references:
symptom-map.md
```

### Step 6: Test with a simulated symptom

Open Claude Code in any project directory and test the skill:

```
/service-debugger API responses are returning 500 errors after this morning's deployment
```

Watch for:
1. The skill loads and forks into an Explore agent
2. Claude reads `references/symptom-map.md` and matches to "5xx Errors / Service Crashes"
3. Claude runs investigation tools: `git log`, `grep` for error patterns, reads relevant files
4. Claude produces a report following the template structure
5. The report returns to your main conversation -- clean and structured

### Step 7: Test with different symptom categories

Try several different symptoms to exercise different paths in the symptom map:

```
/service-debugger Memory usage is climbing steadily and the service restarts every few hours
```

```
/service-debugger Users are reporting stale data -- changes they make don't appear for several minutes
```

```
/service-debugger Connection timeouts to the database started appearing 30 minutes ago
```

Each should route through a different section of the symptom map and produce a report with different investigation steps. Verify that:
- The investigation steps match the symptom category (not a generic checklist)
- The tools used are appropriate for the symptom type
- The report severity makes sense for the symptom described

### Step 8: Test the forked context isolation

After running an investigation, test that the main context is clean:

```
What files did you just read?
```

Claude should not know the details of the investigation -- file reads, grep results, and intermediate findings all happened in the forked Explore agent's context. Your main conversation only has the final report.

### Step 9: Customize the symptom map

Add a new symptom category specific to your project. For example, if you work with a message queue:

```markdown
## Message Queue Backlog / Consumer Lag

### Tools to Use
- Check queue depth metrics
- `grep -rn "consumer" --include="*.ts"` -- find consumer implementations
- `git log --since="2 days ago" -- src/consumers/` -- recent consumer changes

### What to Look For
- Increased message processing time
- Consumer error rates
- Partition rebalancing events
- Memory pressure on consumer instances

### Common Root Causes
- Slow downstream dependency blocking consumers
- Deserialization error causing message retry loops
- Consumer group rebalancing after deployment
- Message schema change without consumer update

### Escalation Criteria
- Consumer lag exceeding 1 hour
- Dead letter queue growing rapidly
- Multiple consumer instances crashing
```

Run the skill with a queue-related symptom and verify it picks up your new category.

### Step 10: Extend the report template

Add a section to the report template for your team's needs. Common additions:

- **Affected Customers**: Scope of impact
- **Related Incidents**: Links to past similar incidents
- **Rollback Assessment**: Whether a rollback is appropriate and how to do it
- **Communication**: Who needs to be notified

Edit `assets/report-template.md` to add these sections and test that the skill includes them in its output.

## Exercises

1. **Build and test the service-debugger skill**. Install the skill from the walkthrough. Test it with at least three different symptom descriptions that route through different categories in the symptom map. Verify that each investigation follows a different path and the reports are structured consistently.

2. **Extend the symptom map**. Add two new symptom categories specific to your tech stack or domain. If you use a specific database, add a "Database Performance" category with the right CLI tools. If you use Kubernetes, add a "Pod Scheduling Failures" category. Test that the skill correctly routes to your new categories.

3. **Customize the report template**. Modify the report template to include a "Rollback Assessment" section that evaluates whether the issue can be resolved by rolling back a recent deployment. Include fields for: rollback candidate (commit/version), estimated rollback time, rollback risk, and recommendation. Test with a deployment-related symptom.

4. **Create a parallel runbook skill**. Build a second runbook skill -- for example, a `performance-profiler` or `dependency-auditor` -- that reuses the same symptom map but produces a different report format. This demonstrates the reusability of the reference file pattern. The new skill should have its own `SKILL.md` and `assets/report-template.md` but share or extend the symptom map.

5. **Compare forked vs inline investigation**. Make a copy of the `service-debugger` skill without `context: fork` (remove the `context` and `agent` fields). Run both versions with the same symptom. Compare: How does the main conversation differ after each? Which is more practical for a quick investigation vs a thorough one? Document your findings.

6. **Build an investigation chain**. Create a workflow where the `service-debugger` skill's output feeds into a follow-up action. For example: run the investigation, then based on the severity in the report, either create a GitHub issue (`gh issue create`), page the on-call engineer, or add it to the backlog. This extends the single-skill runbook into a multi-step incident response workflow.

## Verification Checklist

- [ ] `~/.claude/skills/service-debugger/SKILL.md` exists with valid YAML frontmatter
- [ ] `~/.claude/skills/service-debugger/references/symptom-map.md` exists with 5+ symptom categories
- [ ] `~/.claude/skills/service-debugger/assets/report-template.md` exists with all required sections
- [ ] SKILL.md has `context: fork` and `agent: Explore` in frontmatter
- [ ] SKILL.md references the symptom map and report template by path
- [ ] Running `/service-debugger <symptom>` invokes the skill and forks into an Explore agent
- [ ] The investigation reads the symptom map and routes to the correct category
- [ ] Multiple tools are used during investigation (git log, grep, file reads)
- [ ] The investigation narrows progressively (broad sweep → targeted search → deep dive)
- [ ] The output report follows the template structure with all sections filled in
- [ ] Severity classification (P0-P4) matches the symptom described
- [ ] The main conversation context stays clean after investigation (forked context works)
- [ ] Different symptoms route through different investigation paths (not a generic checklist)
- [ ] The report includes specific evidence (file paths, log excerpts, commit references)
- [ ] Running the investigation a second time with a different symptom produces a differently structured investigation

## What's Next

In **Course 15: Infrastructure Operations Skills -- Guardrails for Dangerous Work**, you'll learn:
- Building skills for tasks with real consequences: orphan cleanup, dependency management, cost investigation
- On-demand safety hooks that activate only when a skill is called (the `/careful` pattern)
- Soak periods and confirmation gates for multi-phase operations
- Dry-run mode as the default, with explicit `--execute` flags for destructive actions
- Audit logging for recording what was changed, by whom, and when
- You'll build a `resource-cleanup` skill with safety guardrails and a `careful` hook-as-skill

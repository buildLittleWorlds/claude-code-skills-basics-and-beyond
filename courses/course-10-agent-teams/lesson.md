# Course 10: Agent Teams -- Orchestrating Parallel Work
**Level**: Advanced | **Estimated time**: 60 min

## Prerequisites
- Completed **Courses 1-9** (skills fundamentals through CLI integration)
- Completed **Course 7½: Your Terminal Workspace** (tmux prerequisite -- split panes, detached sessions, send-keys, capture-pane)
- Completed **Course 8: Custom Subagents** (subagent config, tool restrictions, monitoring)
- You're comfortable with `Ctrl+J` as your tmux prefix key
- Claude Code installed and working (`claude` command available)

## Concepts

### What Are Agent Teams?

In Course 8, you built subagents -- isolated AI workers that run a task and return results. Subagents are powerful, but they have a limitation: they can only talk to the agent that spawned them. A security reviewer can't ask a test runner to verify a fix. A frontend developer can't coordinate with a backend developer. Each subagent is a one-way street.

**Agent teams** remove that limitation. A team is a group of Claude Code instances that:
- **Communicate with each other** through a mailbox messaging system
- **Share a task list** so they can claim, coordinate, and track work
- **Work in parallel** -- each teammate has its own context window and works independently
- **Self-coordinate** -- teammates can pick up tasks, share findings, and challenge each other's conclusions

Think of it this way: subagents are like sending an email and waiting for a reply. Agent teams are like putting three people in a room with a whiteboard.

### When to Use Teams vs Subagents

This is a critical design decision. Teams add coordination overhead and use significantly more tokens. Use the right tool for the job:

| Use subagents when... | Use agent teams when... |
|---|---|
| The task is focused and isolated | Workers need to communicate and collaborate |
| Only the final result matters | The process of discussion adds value |
| One worker can handle it | Parallel exploration beats sequential work |
| You want to minimize cost | The extra tokens are worth the speed/quality |

**Strong team use cases:**
- **Research and review**: multiple teammates investigate different aspects simultaneously, then share and challenge findings
- **New modules or features**: teammates each own a separate piece without stepping on each other
- **Debugging with competing hypotheses**: teammates test different theories in parallel and converge faster
- **Cross-layer coordination**: changes spanning frontend, backend, and tests, each owned by a different teammate

**Stick with subagents for:**
- Sequential tasks with dependencies
- Same-file edits
- Simple, well-scoped work
- Cost-sensitive workflows

**Or stick with skills entirely** -- if the work fits in one session without filling the context window, a skill is always simpler and cheaper. For the full three-way comparison (skills vs sub-agents vs agent teams), the unified decision flowchart, and signals for when to de-escalate back to a simpler mode, see [`courses/references/choosing-the-right-mode.md`](../references/choosing-the-right-mode.md).

### Team Architecture

An agent team has four components:

| Component | Role |
|---|---|
| **Team lead** | The main Claude Code session. Creates the team, spawns teammates, coordinates work |
| **Teammates** | Separate Claude Code instances. Each works on assigned tasks independently |
| **Task list** | Shared work tracker. Teammates claim tasks, mark completion, manage dependencies |
| **Mailbox** | Messaging system for direct communication between agents |

```
┌─────────────────────────────────────────────────┐
│  Team Lead                                      │
│  - Creates team and tasks                       │
│  - Spawns teammates                             │
│  - Synthesizes results                          │
├─────────────┬──────────────┬────────────────────┤
│ Teammate A  │ Teammate B   │ Teammate C         │
│ (security)  │ (performance)│ (test coverage)    │
├─────────────┴──────────────┴────────────────────┤
│  Shared: Task List + Mailbox                    │
└─────────────────────────────────────────────────┘
```

Each teammate loads the same project context as a regular session (CLAUDE.md, MCP servers, skills) plus the spawn prompt from the lead. Teammates do **not** inherit the lead's conversation history -- they start fresh with their assigned task.

Teams and tasks are stored locally:
- **Team config**: `~/.claude/teams/{team-name}/config.json`
- **Task list**: `~/.claude/tasks/{team-name}/`

### Enabling Agent Teams

Agent teams are experimental and disabled by default. Enable them by adding the feature flag to your settings:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

This goes in `~/.claude/settings.json` (all projects) or `.claude/settings.json` (single project). See `team-config/settings-snippet.json` in this course's directory for a complete configuration example.

### Starting a Team

Tell Claude what you need and describe the team structure in natural language:

```
Create an agent team to review PR #142. Spawn three reviewers:
- One focused on security implications
- One checking performance impact
- One validating test coverage
Have them each review and report findings.
```

Claude creates the team, spawns teammates, assigns tasks, and coordinates. You stay in control -- Claude won't create a team without your approval.

### Task Coordination

The shared task list is the backbone of team coordination. Tasks have three states: **pending**, **in progress**, and **completed**. Tasks can also depend on other tasks -- a pending task with unresolved dependencies can't be claimed until those dependencies complete.

The lead creates tasks, and teammates work through them:
- **Lead assigns**: the lead explicitly gives a task to a specific teammate
- **Self-claim**: after finishing a task, a teammate picks up the next unassigned, unblocked task on its own

Task claiming uses file locking to prevent race conditions when multiple teammates try to claim the same task simultaneously.

### Inter-Agent Communication

Teammates communicate through the mailbox system:

| Message type | When to use |
|---|---|
| **message** | Send to one specific teammate (default for most communication) |
| **broadcast** | Send to all teammates simultaneously. Use sparingly -- costs scale with team size |
| **shutdown_request** | Ask a teammate to gracefully shut down |

Messages are delivered automatically. The lead doesn't need to poll for updates -- teammate messages and idle notifications arrive as they happen.

### Delegate Mode

Without delegate mode, the lead sometimes starts implementing tasks itself instead of waiting for teammates. **Delegate mode** restricts the lead to coordination-only: spawning teammates, messaging, managing tasks, and shutting down the team. No code edits, no file writes, no implementation.

Enable it by pressing `Shift+Tab` to cycle into delegate mode after starting a team. This is useful when you want the lead to focus entirely on orchestration.

### Requiring Plan Approval

For complex or risky tasks, you can require teammates to plan before implementing:

```
Spawn an architect teammate to refactor the auth module.
Require plan approval before they make any changes.
```

The teammate works in read-only plan mode until the lead approves their approach. If the lead rejects the plan, the teammate revises and resubmits.

## Display Modes

Agent teams support two display modes, and this is where tmux becomes essential.

### In-Process Display

All teammates run inside your main terminal. Navigate with:
- **Shift+Up/Down**: select a teammate
- **Enter**: view a teammate's session
- **Escape**: interrupt a teammate's current turn
- **Ctrl+T**: toggle the task list

This works in any terminal with no extra setup. But you can only see one teammate at a time.

### Split-Pane Display (tmux)

Each teammate gets its own pane. You see everyone's output simultaneously and can click into any pane to interact directly. This is the real-world way to monitor multiple agents working in parallel.

The default display is `"auto"` -- Claude uses split panes if you're already in a tmux session, and in-process otherwise. Override in settings:

```json
{
  "teammateMode": "in-process"
}
```

Or per-session:

```bash
claude --teammate-mode in-process
```

To force tmux split panes:

```json
{
  "teammateMode": "tmux"
}
```

**Key insight**: Agent teams run as background processes. Tmux gives you eyes on what they're doing.

## Quality Gates with Hooks

Two hook events are designed specifically for agent teams:

### TeammateIdle

Fires when a teammate is about to go idle after finishing its turn. Exit code 2 sends feedback and keeps the teammate working:

```bash
#!/bin/bash
# Check that the teammate actually produced output
if [ ! -f "./dist/output.js" ]; then
  echo "Build artifact missing. Run the build before stopping." >&2
  exit 2
fi
exit 0
```

### TaskCompleted

Fires when a task is being marked as completed. Exit code 2 prevents completion and sends feedback to the model:

```bash
#!/bin/bash
INPUT=$(cat)
TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject')

if ! npm test 2>&1; then
  echo "Tests failing. Fix before completing: $TASK_SUBJECT" >&2
  exit 2
fi
exit 0
```

These hooks enforce completion criteria automatically. A teammate can't mark a task done if the test suite is broken.

## The tmux Orchestration Layer

This section merges Claude's built-in agent teams API with the tmux patterns from Course 7½ and the parallel-agents tutorial. When you use split-pane mode (`teammateMode: "tmux"`), Claude handles the tmux layout automatically. But understanding the tmux layer gives you debugging tools and the ability to build custom orchestration scripts.

### Multi-Session Architecture

When agent teams run in tmux, each teammate gets its own session. The lead's terminal manages the layout, but behind the scenes:

```
┌─────────────────────────────────────────────┐
│ Session: control (team lead -- you are here)│
│ ┌───────────────┬───────────────────────┐   │
│ │ Agent status  │ Integration testing   │   │
│ └───────────────┴───────────────────────┘   │
├─────────────────────────────────────────────┤
│ (Background sessions)                       │
│ [teammate-1]  [teammate-2]  [teammate-3]    │
└─────────────────────────────────────────────┘
```

### The Control Dashboard

For manual orchestration outside of Claude's built-in display, you can build your own monitoring layout. The `scripts/team-dashboard.sh` included in this course creates a tmux session with:
- **Top row**: one pane per agent, using `watch` + `capture-pane` for live tailing
- **Bottom pane**: your command center

```bash
# Create the monitoring layout
./scripts/team-dashboard.sh my-team 3
```

This creates:
```
┌─────────────┬─────────────┬─────────────┐
│ Agent 1     │ Agent 2     │ Agent 3     │
│ (live tail) │ (live tail) │ (live tail) │
├─────────────┴─────────────┴─────────────┤
│            Command Center               │
└─────────────────────────────────────────┘
```

### Launching Agents from a Control Session

The key tmux patterns for agent orchestration:

**Start an agent without leaving your terminal:**
```bash
tmux send-keys -t session-name 'claude "Your task prompt here"' Enter
```

**Peek at agent progress:**
```bash
tmux capture-pane -t session-name -p | tail -20
```

**Live-tail an agent's output:**
```bash
watch -n 2 'tmux capture-pane -t session-name -p | tail -15'
```

**Send a command to all agents simultaneously:**
```bash
for session in agent-1 agent-2 agent-3; do
  tmux send-keys -t $session "Summarize your current progress" Enter
done
```

**Capture and compare outputs:**
```bash
echo "=== Agent 1 ===" && tmux capture-pane -t agent-1 -p | tail -10
echo "=== Agent 2 ===" && tmux capture-pane -t agent-2 -p | tail -10
```

### Ownership Boundaries and Conflict Prevention

When multiple agents work on the same codebase, file conflicts are the biggest risk. Establish clear ownership:

| Owner | Responsibility |
|---|---|
| **Agent A** | Specific directories/files (e.g., `src/auth/`) |
| **Agent B** | Different directories/files (e.g., `src/api/`) |
| **Human** | Shared config files, integration decisions |

**Best practices:**
- Each agent owns specific directories -- never have two agents edit the same file
- Shared configuration files are human-owned
- Use the task list to make ownership explicit
- If agents need to coordinate on a shared interface, define the contract first, then let each agent implement their side independently

Refer to the tmux quick-reference from Course 7½ for the exact tmux commands.

## Key References
- Agent teams docs: Full API reference (spawning, tasks, messaging, display modes, hooks)
- Hooks docs: TeammateIdle and TaskCompleted hook events
- Course 7½ tmux-quickref.md: Quick reference for tmux commands used in this course
- Course 8: Custom subagents (subagent comparison point)
- [Choosing the Right Mode](../references/choosing-the-right-mode.md): Three-way comparison table, decision flowchart, escalation and de-escalation signals

## What You're Building

Five deliverables that demonstrate agent teams from configuration through orchestration:

1. **settings-snippet.json** -- Configuration to enable agent teams and set up quality gate hooks
2. **verify-task-completion.sh** -- A TaskCompleted hook that runs the test suite and blocks completion if tests fail
3. **team-dashboard.sh** -- A reusable tmux script that creates a monitoring layout for any number of agents
4. **launch-review-team.sh** -- A tmux script that launches a 3-reviewer parallel code review (security, performance, test coverage)
5. **review-prompt.md** -- A prompt template for spawning the 3-reviewer team inside Claude Code

Together, these cover: enabling the feature, enforcing quality, monitoring teams visually, scripting team launches, and using the built-in API.

## Walkthrough

### Step 1: Enable agent teams

Copy the settings snippet into your Claude Code settings:

```bash
# View the configuration
cat courses/course-10-agent-teams/team-config/settings-snippet.json
```

The file contains:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "teammateMode": "auto",
  "hooks": {
    "TaskCompleted": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/hooks/verify-task-completion.sh",
            "timeout": 120,
            "statusMessage": "Running quality gate..."
          }
        ]
      }
    ]
  }
}
```

Key settings:
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`: enables the feature
- `teammateMode`: `"auto"` uses tmux split panes if available, in-process otherwise
- `TaskCompleted` hook: runs the verification script whenever any agent marks a task done

To install, merge these settings into your project's `.claude/settings.json`:

```bash
# If you don't have a project settings file yet
mkdir -p .claude
cp courses/course-10-agent-teams/team-config/settings-snippet.json .claude/settings.json

# If you already have settings, merge the keys manually
```

Start a new Claude Code session for the settings to take effect.

### Step 2: Install the quality gate hook

The `hooks/verify-task-completion.sh` script enforces a simple rule: **a task can't be marked complete if the test suite is failing**.

```bash
# Copy the hook into your project
cp courses/course-10-agent-teams/hooks/verify-task-completion.sh .claude/hooks/
chmod +x .claude/hooks/verify-task-completion.sh
```

The script:
1. Reads the JSON input from stdin (task ID, subject, description, teammate name)
2. Detects the test framework (npm, pytest, cargo, go, make)
3. Runs the test suite
4. Exits 0 if tests pass (task completion allowed)
5. Exits 2 if tests fail (task completion blocked, stderr fed back to the agent)

Read the script to understand the flow:

```bash
cat courses/course-10-agent-teams/hooks/verify-task-completion.sh
```

This hook fires for **all** task completions -- not just in agent teams. Any time any agent (or Claude itself) marks a task done, the hook runs. This is intentional: quality gates should apply universally.

### Step 3: Set up the team dashboard script

The dashboard script creates a tmux monitoring layout for any number of agents:

```bash
# Make it executable
chmod +x courses/course-10-agent-teams/scripts/team-dashboard.sh
```

Usage:

```bash
# Create a dashboard for 3 agents
./courses/course-10-agent-teams/scripts/team-dashboard.sh my-review 3
```

This creates a tmux session called `my-review-dashboard` with:
- Top row split into 3 panes, each running `watch` on a corresponding tmux session
- Bottom pane as your command center

The script expects agent sessions to be named `{team-name}-agent-1`, `{team-name}-agent-2`, etc. It handles cleanup of existing dashboard sessions and works if agent sessions aren't running yet (the watch command will just show "no session" until they start).

### Step 4: Set up the review team launcher

The launcher script automates the entire 3-reviewer workflow:

```bash
chmod +x courses/course-10-agent-teams/scripts/launch-review-team.sh
```

Usage:

```bash
# Launch a 3-reviewer team for the current directory
./courses/course-10-agent-teams/scripts/launch-review-team.sh

# Or specify a project directory
./courses/course-10-agent-teams/scripts/launch-review-team.sh /path/to/project
```

The script:
1. Creates 3 detached tmux sessions (security-reviewer, perf-reviewer, test-reviewer)
2. Starts Claude Code in each session
3. Sends a review prompt to each agent, focused on their specialty
4. Launches the team dashboard for monitoring
5. Includes a cleanup function to kill all sessions when done

### Step 5: Test with the built-in API (in-process)

Before using the tmux scripts, try agent teams through Claude Code's built-in API. Start Claude Code and paste the prompt from `review-prompt.md`:

```bash
claude
```

Then type (or paste) the review prompt:

```
Create an agent team called "code-review" to review the current project.
Spawn three reviewers:
- "security-reviewer": focused on security vulnerabilities -- injection,
  auth issues, data exposure, access control
- "perf-reviewer": focused on performance -- N+1 queries, unnecessary
  allocations, missing caching, algorithmic complexity
- "test-reviewer": focused on test coverage -- untested paths, missing
  edge cases, brittle tests, test isolation

Have each reviewer work independently, then report their findings.
Use delegate mode so you focus on coordination, not implementation.
```

Watch how Claude:
1. Creates the team and shared task list
2. Spawns three teammates
3. Assigns review tasks
4. Waits for results
5. Synthesizes findings

Use **Shift+Up/Down** to cycle through teammates and see their output. Press **Ctrl+T** to toggle the task list.

### Step 6: Test with tmux monitoring

Now run the same review with the tmux orchestration layer:

1. Start a tmux session:
   ```bash
   tmux new -s review-control
   ```

2. Run the launcher:
   ```bash
   ./courses/course-10-agent-teams/scripts/launch-review-team.sh
   ```

3. Watch all three reviewers work simultaneously in the dashboard. Compare this experience to the in-process display -- you can see more detail and monitor all agents at once.

4. When reviews are done, capture the outputs:
   ```bash
   for session in review-security-reviewer review-perf-reviewer review-test-reviewer; do
     echo "=== $session ===" >> review-results.txt
     tmux capture-pane -t $session -p -S -1000 >> review-results.txt 2>/dev/null
   done
   ```

5. Clean up:
   ```bash
   # The dashboard script's cleanup function, or manually:
   tmux kill-session -t review-security-reviewer 2>/dev/null
   tmux kill-session -t review-perf-reviewer 2>/dev/null
   tmux kill-session -t review-test-reviewer 2>/dev/null
   tmux kill-session -t review-dashboard 2>/dev/null
   ```

### Step 7: Test the quality gate

To verify the TaskCompleted hook works:

1. In a project with tests, use Claude Code with agent teams enabled
2. Spawn a team where one agent writes code and another runs tests:
   ```
   Create a team. Spawn "coder" to add a new utility function with
   tests, and "tester" to verify the tests pass. The coder should
   mark their task complete when done.
   ```
3. If the coder's tests are failing, the TaskCompleted hook should prevent the task from being marked done
4. The coder receives the stderr feedback ("Tests failing...") and must fix the tests before completing

## Exercises

1. **API-only team** (no tmux). Using Claude Code, spawn a 2-agent team with the built-in API. Assign one agent to review a file for security issues and another for performance issues. Observe the shared task list with Ctrl+T. Use Shift+Up/Down to view teammate output in-process. Compare how the two reviewers approach the same code differently.

2. **tmux monitoring**. Run the same 2-agent team, but this time set up `team-dashboard.sh` to monitor both agents in split panes. Compare the experience: can you see more detail through the tmux dashboard than through in-process display? When would you choose one over the other?

3. **Full workflow**. Run `launch-review-team.sh` to launch a 3-reviewer parallel code review (security, performance, test coverage). Monitor the dashboard. When all three finish, compare their findings in the control pane. Resolve any conflicting recommendations -- for example, if the performance reviewer suggests removing a validation that the security reviewer flagged as critical.

4. **Quality gate**. Configure the `verify-task-completion.sh` hook in a project with tests. Spawn a team where one agent writes code and another runs tests. Introduce a deliberate test failure. Verify that the TaskCompleted hook prevents the coding agent from marking its task done. Fix the failure and verify the task can then be completed.

## Verification Checklist

- [ ] `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is set in your settings
- [ ] Running `claude` and asking for a team spawns teammates correctly
- [ ] You can see teammate output with Shift+Up/Down in in-process mode
- [ ] `team-config/settings-snippet.json` contains valid JSON with the feature flag and hooks
- [ ] `hooks/verify-task-completion.sh` is executable and handles the JSON input correctly
- [ ] `scripts/team-dashboard.sh` creates a multi-pane tmux layout with live-tailing
- [ ] `scripts/launch-review-team.sh` launches 3 Claude sessions and the dashboard
- [ ] The TaskCompleted hook blocks task completion when tests fail
- [ ] The TaskCompleted hook allows task completion when tests pass
- [ ] You can monitor multiple agents simultaneously via the tmux dashboard
- [ ] You can capture session output with `tmux capture-pane` for post-review analysis
- [ ] You understand when to use teams vs subagents

## What's Next

**Course 11: The Capstone -- An Orchestrated Skill Ecosystem** ties everything together. You'll build a complete plugin that bundles skills, agents, hooks, and automation scripts into a distributable package -- a full engineering workflow with PR review, changelog updates, release management, and CI monitoring, all orchestrated through tmux session scripts.

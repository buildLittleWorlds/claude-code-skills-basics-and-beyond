# Course 11: The Capstone -- An Orchestrated Skill Ecosystem
**Level**: Advanced | **Estimated time**: 75 min

## Prerequisites
- Completed **Courses 1-10** (the full curriculum)
- Comfortable with skills (YAML frontmatter, scripts, references, arguments, dynamic context)
- Comfortable with hooks (PreToolUse, PostToolUse, TaskCompleted, exit codes, JSON I/O)
- Comfortable with subagents (tools, model, memory, skills preloading)
- Comfortable with agent teams (spawning, task lists, messaging, delegate mode)
- Comfortable with tmux orchestration (split panes, detached sessions, send-keys, capture-pane, dashboards)
- Claude Code installed and working (`claude` command available)

## Concepts

### Multi-Skill Ecosystems

Throughout this curriculum, you've built individual skills that each do one thing well. Course 1's standup writer, Course 4's PR description generator, Course 6's project scaffolder -- each is self-contained.

But real engineering workflows aren't self-contained. A PR review naturally leads to a changelog update. A changelog update is part of a release. A release should include updated documentation. These skills form a **pipeline**: the output of one becomes the input of the next.

```
PR Review → Changelog Update → Release → Documentation
    ↓              ↓               ↓           ↓
PR-REVIEW.md   CHANGELOG.md   RELEASE_NOTES.md  API.md
```

The key design principle: **skills communicate through shared files and git state**, not through direct invocation. Each skill reads files in the project and writes files to the project. This keeps skills loosely coupled -- you can run them independently or compose them into a pipeline.

### Skill-to-Skill Data Flow

How do skills pass data between each other? Through artifacts in the project:

| Producer Skill | Artifact | Consumer Skill |
|---|---|---|
| pr-reviewer | `PR-REVIEW.md` | changelog-updater (reads review context) |
| changelog-updater | `CHANGELOG.md` | release-manager (finalizes for release) |
| release-manager | `RELEASE_NOTES.md` | (user publishes to GitHub) |
| docs-generator | `API.md` | (user reviews and commits) |

Each skill checks for artifacts from upstream skills. If `PR-REVIEW.md` exists when you run the changelog updater, it uses the review findings to write better entries. If it doesn't exist, the changelog updater still works -- it just uses git log directly. This is **graceful degradation**: the pipeline enhances quality when skills run in sequence, but each skill works standalone.

### Coordinating Agents with Hooks

Hooks automate what would otherwise be manual coordination:

- **PostToolUse on Edit|Write**: The `auto-format.sh` hook runs the project's formatter after every file change. This means agents never commit unformatted code.
- **TaskCompleted**: The `verify-completion.sh` hook runs tests and lint before any task can close. This applies to both human work and agent work.

Together, these hooks create a safety net: no matter how the code changes -- manual edit, skill execution, agent work, or team collaboration -- the formatting and quality checks run automatically.

### The Quality Gate Agent

The `quality-gate` agent is a meta-agent: it reviews the output of other agents and skills. Instead of checking code for bugs (that's the pr-reviewer's job), it checks whether the pr-reviewer did a good job.

This creates a two-layer quality system:
1. **Skills produce artifacts** (reviews, changelogs, docs)
2. **Quality gate reviews the artifacts** (are they complete, accurate, well-formatted?)

The quality gate uses persistent memory (`memory: project`) to learn project-specific quality standards over time. The more you use it, the more it knows about your project's conventions.

### Plugin Packaging

Until now, all your skills, agents, and hooks lived in `~/.claude/` (personal) or `.claude/` (project). A **plugin** bundles them into a distributable package that anyone can install.

The plugin structure is:

```
engineering-workflow/
├── .claude-plugin/
│   └── plugin.json          ← Manifest: name, version, description
├── skills/                   ← Skills (auto-discovered)
│   ├── pr-reviewer/SKILL.md
│   ├── changelog-updater/SKILL.md
│   ├── release-manager/SKILL.md
│   └── docs-generator/SKILL.md
├── agents/                   ← Agents (auto-discovered)
│   ├── ci-monitor.md
│   └── quality-gate.md
└── hooks/                    ← Hooks
    ├── hooks.json            ← Hook configuration
    └── scripts/
        ├── auto-format.sh
        └── verify-completion.sh
```

The `plugin.json` manifest is minimal:

```json
{
  "name": "engineering-workflow",
  "version": "1.0.0",
  "description": "PR review, changelog, release, and docs workflow"
}
```

That's it. Claude Code auto-discovers components in the standard directories. The `name` field becomes the namespace: skills are invoked as `/engineering-workflow:pr-reviewer`, `/engineering-workflow:changelog-updater`, etc.

### Plugin Distribution

Plugins can be installed at different scopes:

| Scope | Settings file | Use case |
|---|---|---|
| **user** | `~/.claude/settings.json` | Personal plugins, available everywhere |
| **project** | `.claude/settings.json` | Team plugins, shared via version control |
| **local** | `.claude/settings.local.json` | Project-specific, gitignored |

For local development and testing, use `--plugin-dir`:

```bash
claude --plugin-dir ./engineering-workflow
```

For distribution, place the plugin in a marketplace repository and install with:

```bash
claude plugin install engineering-workflow@my-marketplace
```

### Automation with Session Scripts

The final piece is tmux session scripts that set up an entire automated workflow with a single command. The `workflow-runner.sh` script in this course:

1. Launches a CI monitor agent in a detached tmux session
2. Launches a quality gate agent in another detached session
3. Creates a monitoring dashboard with live-tailing of both agents
4. Provides a command center for manual interaction

This draws from two patterns you've seen:
- **Session scripts** (from the parallel-agents tutorial): automate multi-session setup
- **Background watchers** (from the dx-workflow tutorial): agents that run continuously and respond to events

### Tmux Popup Mode

For quick AI interactions without disrupting the dashboard layout, tmux 3.2+ supports floating popup windows:

```bash
tmux display-popup -w 80% -h 80% -E 'claude -p "explain this test failure"'
```

The popup appears over the current panes, runs the command, and disappears when done. This is ideal for quick questions while monitoring -- you don't need to switch panes or create new sessions.

## Key References
- Plugins docs: Plugin creation, manifest schema, distribution
- Plugins reference: Complete technical specifications, CLI commands, debugging
- Hooks docs: PostToolUse, TaskCompleted, async hooks
- Course 7½ tmux-quickref.md: tmux commands used in this course
- Course 10: Agent teams (team coordination patterns)
- [Choosing the Right Mode](../references/choosing-the-right-mode.md): Decision framework for when to use skills, sub-agents, or agent teams in your pipelines

## What You're Building

A complete **engineering-workflow** plugin containing:

**4 skills** that compose into a release pipeline:
1. **pr-reviewer** -- Reviews PRs with structured feedback across 5 dimensions
2. **changelog-updater** -- Updates CHANGELOG.md following Keep a Changelog format
3. **release-manager** -- Orchestrates version bump, changelog finalization, tag, and release notes
4. **docs-generator** -- Generates API documentation from source code

**2 agents** for monitoring and quality:
1. **ci-monitor** -- Checks CI status, open PRs, and recent workflow runs (uses Haiku for speed)
2. **quality-gate** -- Meta-reviewer that validates other skills' output (uses Sonnet with persistent memory)

**2 hooks** for automated quality:
1. **auto-format.sh** -- PostToolUse hook that formats files on every Edit/Write
2. **verify-completion.sh** -- TaskCompleted hook that blocks incomplete work

Plus a **workflow-runner.sh** tmux script that launches the monitoring environment.

Together, these demonstrate the capstone pattern: **skills compose into pipelines, agents provide monitoring and quality gates, hooks enforce standards automatically, and tmux scripts orchestrate the whole thing**.

## Walkthrough

### Step 1: Explore the plugin structure

Start by understanding what's in the `engineering-workflow/` directory:

```bash
find courses/course-11-capstone/engineering-workflow -type f | sort
```

You should see:
```
.claude-plugin/plugin.json
agents/ci-monitor.md
agents/quality-gate.md
hooks/hooks.json
hooks/scripts/auto-format.sh
hooks/scripts/verify-completion.sh
skills/changelog-updater/SKILL.md
skills/docs-generator/SKILL.md
skills/pr-reviewer/SKILL.md
skills/release-manager/SKILL.md
```

Read the `plugin.json` to see the manifest. Read each skill's frontmatter to see how they're configured. Read the agents to see their tool restrictions and model choices.

### Step 2: Test the plugin locally

Load the plugin with `--plugin-dir`:

```bash
claude --plugin-dir ./courses/course-11-capstone/engineering-workflow
```

Verify all components are available:

1. Run `/help` and look for commands under the `engineering-workflow` namespace
2. Run `/agents` and check that `ci-monitor` and `quality-gate` appear

You should see:
- `/engineering-workflow:pr-reviewer`
- `/engineering-workflow:changelog-updater`
- `/engineering-workflow:release-manager`
- `/engineering-workflow:docs-generator`

### Step 3: Test the skill pipeline

Navigate to a project with git history (or create a test project). Run the skills in pipeline order:

**3a. Run the PR reviewer:**

```
/engineering-workflow:pr-reviewer
```

This generates `PR-REVIEW.md` with structured feedback. Read it:

```
Read PR-REVIEW.md
```

**3b. Run the changelog updater:**

```
/engineering-workflow:changelog-updater
```

It reads `PR-REVIEW.md` (if present) for context, then scans git history and produces changelog entries in `CHANGELOG.md`.

**3c. Run the release manager:**

```
/engineering-workflow:release-manager patch
```

It reads `CHANGELOG.md`, bumps the version, finalizes the changelog entry with today's date, creates `RELEASE_NOTES.md`, and makes a tagged commit.

**3d. Run the docs generator:**

```
/engineering-workflow:docs-generator
```

It scans source code and produces `API.md`.

Observe how each skill's output feeds into the next. The pipeline works because each skill reads and writes standard project files.

### Step 4: Test the hooks

The plugin's hooks run automatically when it's loaded.

**4a. Test auto-format:**

Make a code change (stage a file or ask Claude to edit one). After the Edit or Write tool completes, the `auto-format.sh` hook runs. If the project has prettier, black, rustfmt, or gofmt installed, the file is formatted automatically.

To verify: make an intentionally poorly-formatted change and check that it's reformatted after Claude writes it.

**4b. Test verify-completion:**

If you're using task lists (from Course 10's agent teams or standalone), try marking a task as completed. The `verify-completion.sh` hook checks:
- Test suite passes
- Lint passes (if configured)
- No merge conflict markers in tracked files

If any check fails, the task completion is blocked and the agent receives feedback about what to fix.

### Step 5: Test the agents

**5a. CI monitor:**

```
Use the ci-monitor agent to check the current CI status
```

The agent uses Haiku (fast and cheap) and is restricted to git and gh commands plus read-only tools. It reports open PRs, recent workflow runs, and flags any issues.

**5b. Quality gate:**

After running the skill pipeline (Step 3), invoke the quality gate:

```
Use the quality-gate agent to review the artifacts in this project
```

The agent uses Sonnet (deeper reasoning), checks `PR-REVIEW.md`, `CHANGELOG.md`, `RELEASE_NOTES.md`, and `API.md`, runs the test suite, and produces a quality report. It also updates its project-level memory with what it learned.

Run it again later. It should reference findings from its first run.

### Step 6: Run the workflow monitoring environment

Make the script executable and run it:

```bash
chmod +x courses/course-11-capstone/scripts/workflow-runner.sh
./courses/course-11-capstone/scripts/workflow-runner.sh
```

This creates a tmux dashboard showing:
- **Top-left**: CI monitor agent output (live-tailing)
- **Top-right**: Quality gate agent output (live-tailing)
- **Bottom**: Command center with quick-reference commands

From the command center, you can:
- Attach to either agent's session for direct interaction
- Capture logs to files for review
- Use `tmux display-popup` for quick AI questions without leaving the dashboard

### Step 7: Try the popup pattern

From within the dashboard's command center pane, open a quick AI popup:

```bash
tmux display-popup -w 80% -h 80% -E 'claude -p "Explain what a quality gate agent does in 3 sentences"'
```

The popup floats over the dashboard, shows the response, and closes when done. Your dashboard panes are undisturbed.

This is useful during monitoring: if you see a test failure in the quality gate output, pop up a quick explanation without navigating away.

### Step 8: Install the plugin for real use

When you're satisfied with the plugin, install it for ongoing use:

**Option A: Personal installation** (available in all your projects):

```bash
# Copy the plugin directory
cp -r courses/course-11-capstone/engineering-workflow ~/.claude/plugins/engineering-workflow

# Or use --plugin-dir in your shell profile
echo 'alias claude-ew="claude --plugin-dir ~/path/to/engineering-workflow"' >> ~/.zshrc
```

**Option B: Project installation** (available to your team):

```bash
# Copy into the project's plugin directory
cp -r courses/course-11-capstone/engineering-workflow .claude/plugins/engineering-workflow
# Commit to version control so teammates get it too
```

**Option C: Marketplace distribution** (for broader sharing):

Create a marketplace repository, add the plugin, and teammates install with:

```bash
claude plugin install engineering-workflow@your-marketplace
```

Start a new Claude Code session and verify:
- `/help` shows the engineering-workflow commands
- `/agents` shows ci-monitor and quality-gate
- Running `/engineering-workflow:pr-reviewer` works without `--plugin-dir`

## Exercises

1. **Install and compose**. Load the engineering-workflow plugin with `--plugin-dir`. Navigate to a project with git history. Run `/engineering-workflow:pr-reviewer` and `/engineering-workflow:changelog-updater` in sequence. Verify the changelog updater references findings from the PR review. Then run `/engineering-workflow:docs-generator`. Confirm that all four skills produce their respective artifacts.

2. **Test the hooks**. With the plugin loaded, make a code change in a JavaScript or Python project. Verify `auto-format.sh` runs after the file is written (check the formatting). Then, if using task lists, try to complete a task while the test suite is failing. Verify `verify-completion.sh` blocks completion. Fix the tests and confirm the task can then complete.

3. **Full orchestration**. Run `workflow-runner.sh` to launch the monitoring environment. Watch the CI monitor and quality gate in the dashboard. While monitoring, run the skill pipeline in a separate tmux session (or attach to the quality gate session). Use `tmux display-popup` from the command center for a quick question. Capture logs from both sessions when done.

4. **Package and distribute**. Copy the `engineering-workflow/` directory to a new location. Install it as a plugin in a different project (using `--plugin-dir` or by placing it in `.claude/plugins/`). Verify all 4 skills and 2 agents are available. Run the PR reviewer and confirm it works in the new context. This validates that the plugin is self-contained and portable.

## Verification Checklist

- [ ] `engineering-workflow/.claude-plugin/plugin.json` is valid JSON with name, version, description
- [ ] All 4 skills appear when loading the plugin (`/help` shows them under the namespace)
- [ ] Both agents appear in `/agents`
- [ ] `/engineering-workflow:pr-reviewer` produces `PR-REVIEW.md` with structured findings
- [ ] `/engineering-workflow:changelog-updater` produces formatted `CHANGELOG.md` entries
- [ ] The changelog updater uses `PR-REVIEW.md` context when available
- [ ] `/engineering-workflow:release-manager patch` bumps version, finalizes changelog, creates tag
- [ ] `/engineering-workflow:docs-generator` produces `API.md` from source code
- [ ] `auto-format.sh` runs after Edit/Write and formats the file
- [ ] `verify-completion.sh` blocks task completion when tests fail
- [ ] `verify-completion.sh` allows completion when tests pass
- [ ] The ci-monitor agent uses Haiku and reports CI status
- [ ] The quality-gate agent uses Sonnet and produces a quality report
- [ ] The quality-gate agent updates its memory between runs
- [ ] `workflow-runner.sh` creates the monitoring dashboard with live-tailing
- [ ] The plugin works when installed via `--plugin-dir` in a different project
- [ ] `tmux display-popup` works for quick AI interactions from the dashboard

## What's Next

Congratulations -- you've completed the entire curriculum. You now know how to:

- **Build skills** from simple instructions to multi-step workflows with validation gates
- **Write hooks** that enforce quality standards automatically
- **Configure subagents** with tool restrictions, model selection, and persistent memory
- **Orchestrate agent teams** with shared tasks, messaging, and delegate mode
- **Monitor and manage** agents through tmux dashboards and session scripts
- **Package everything** as a distributable plugin

From here, consider:
- **Build your own workflow plugin** tailored to your team's process
- **Contribute to plugin marketplaces** to share your tools with the community
- **Combine patterns** from across the curriculum in new ways -- the skills, agents, hooks, and orchestration patterns are building blocks for whatever workflow you need

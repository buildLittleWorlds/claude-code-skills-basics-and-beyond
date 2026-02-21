# Course 8: Custom Subagents -- Specialized AI Workers
**Level**: Advanced | **Estimated time**: 50 min

## Prerequisites
- Completed **Courses 1-7** (skills fundamentals, hooks, the full build-up)
- Completed **Course 7½: Your Terminal Workspace** (tmux prerequisite -- split panes, detached sessions, send-keys, capture-pane)
- You're comfortable with `Ctrl+J` as your tmux prefix key
- Claude Code installed and working (`claude` command available)

## Concepts

### What Are Subagents?

In Course 5, you learned that a skill can run in a forked context using `context: fork` and `agent: Explore`. That was your first brush with subagents -- isolated AI workers that run in their own context window.

Now you're going to build them from scratch.

A **subagent** is a standalone AI assistant with:
- Its own **system prompt** (the markdown body of the agent file)
- Its own **tool access** (which tools it can use)
- Its own **context window** (isolated from your main conversation)
- Optionally, its own **model**, **permissions**, **hooks**, **skills**, and **memory**

When Claude encounters a task that matches a subagent's description, it delegates to that subagent. The subagent works independently and returns results to the main conversation. Think of it as a specialist you can call on -- a security expert, a test runner, a documentation writer -- each with exactly the tools and knowledge they need.

**When do you need a subagent instead of a skill?** Not always. Skills are simpler, faster, and cheaper. Subagents earn their keep when the context window is filling up, when you need tool restrictions per phase, when intermediate output is too verbose for the main session, or when you need independent critique free from self-critic bias. For the full decision framework -- including when to escalate further to agent teams -- see [`courses/references/choosing-the-right-mode.md`](../references/choosing-the-right-mode.md).

### Built-in vs Custom Subagents

Claude Code comes with several built-in subagents:

| Subagent | Model | Purpose |
|---|---|---|
| **Explore** | Haiku (fast) | Read-only codebase search and analysis |
| **Plan** | Inherits | Research agent for plan mode |
| **general-purpose** | Inherits | Complex multi-step tasks requiring all tools |
| **Bash** | Inherits | Terminal commands in a separate context |

You've already used Explore (Course 5's `agent: Explore` field). These built-in subagents handle common patterns, but real projects need specialized workers. That's what custom subagents are for.

### Where Subagent Files Live

Like skills, subagents live at different levels depending on scope:

| Location | Scope | Priority |
|---|---|---|
| `--agents` CLI flag | Current session only | 1 (highest) |
| `.claude/agents/` | Current project | 2 |
| `~/.claude/agents/` | All your projects | 3 |
| Plugin `agents/` directory | Where plugin is enabled | 4 (lowest) |

When multiple subagents share the same name, the higher-priority location wins.

**Project subagents** (`.claude/agents/`) are ideal for project-specific workflows. Check them into version control so your team benefits. **User subagents** (`~/.claude/agents/`) are personal -- available everywhere you use Claude Code.

### The Subagent File Format

Subagent files are Markdown with YAML frontmatter -- just like skills, but with different fields:

```markdown
---
name: my-agent
description: When Claude should delegate to this agent
tools: Read, Grep, Glob
model: haiku
---

You are a specialist. When invoked, do the following:
1. Step one
2. Step two
3. Return your findings
```

The frontmatter defines configuration. The body becomes the **system prompt** -- the only instructions the subagent receives (it doesn't get the full Claude Code system prompt, just yours plus basic environment info like the working directory).

### Configuration Fields

Here's the full set of frontmatter fields:

| Field | Required | Description |
|---|---|---|
| `name` | Yes | Unique identifier, lowercase letters and hyphens |
| `description` | Yes | When Claude should delegate to this subagent |
| `tools` | No | Tools the subagent can use (inherits all if omitted) |
| `disallowedTools` | No | Tools to deny, removed from inherited or specified list |
| `model` | No | `sonnet`, `opus`, `haiku`, or `inherit` (default: `inherit`) |
| `permissionMode` | No | `default`, `acceptEdits`, `delegate`, `dontAsk`, `bypassPermissions`, `plan` |
| `maxTurns` | No | Maximum agentic turns before the subagent stops |
| `skills` | No | Skills to preload into the subagent's context |
| `mcpServers` | No | MCP servers available to this subagent |
| `hooks` | No | Lifecycle hooks scoped to this subagent |
| `memory` | No | Persistent memory scope: `user`, `project`, or `local` |

Let's walk through the most important fields.

### Controlling Tool Access

The `tools` field is an allowlist -- only listed tools are available:

```yaml
tools: Read, Grep, Glob
```

This creates a read-only agent. Compare with the `disallowedTools` field, which is a denylist:

```yaml
disallowedTools: Write, Edit
```

This inherits all tools *except* Write and Edit. Both achieve similar results, but the allowlist (`tools`) is more explicit and safer -- if new tools are added to Claude Code, an allowlist agent won't accidentally gain access.

For fine-grained control, use tool patterns:

```yaml
tools: Bash(git *), Read, Grep, Glob
```

This allows Bash but only for `git` commands. The `Bash(pattern)` syntax restricts which commands the subagent can run.

### Choosing a Model

The `model` field controls cost and speed:

| Model | Tradeoff |
|---|---|
| `haiku` | Fastest, cheapest -- good for routine tasks like running tests, simple searches |
| `sonnet` | Balanced -- good for analysis, code review, moderate complexity |
| `opus` | Most capable -- good for complex reasoning, architecture decisions |
| `inherit` | Uses the same model as the main conversation (default) |

Use haiku for high-volume, well-scoped tasks. Use sonnet or opus when the subagent needs deeper reasoning.

### Preloading Skills

The `skills` field injects skill content into the subagent's context at startup:

```yaml
skills:
  - security-patterns
  - error-handling-patterns
```

This is different from skills in the main conversation. The full content of each listed skill is injected directly -- the subagent doesn't discover and load them on demand. It has the knowledge from the start.

**Important**: Subagents don't inherit skills from the parent conversation. You must list them explicitly.

### Persistent Memory

The `memory` field gives the subagent a directory that persists across conversations:

```yaml
memory: project
```

| Scope | Location | Use when |
|---|---|---|
| `user` | `~/.claude/agent-memory/<name>/` | Knowledge applies across all projects |
| `project` | `.claude/agent-memory/<name>/` | Knowledge is project-specific, shareable via VCS |
| `local` | `.claude/agent-memory-local/<name>/` | Project-specific, not checked into VCS |

When memory is enabled:
- The subagent's system prompt includes instructions for reading and writing to the memory directory
- The first 200 lines of `MEMORY.md` in that directory are included in the prompt
- Read, Write, and Edit tools are automatically enabled so the subagent can manage its memory

This means a security reviewer can accumulate project-specific patterns over time -- each invocation gets smarter because it builds on previous findings.

### Hooks in Subagent Frontmatter

Subagents can define their own lifecycle hooks:

```yaml
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-command.sh"
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/run-linter.sh"
```

These hooks only run while that specific subagent is active. Common events:

| Event | Matcher input | When it fires |
|---|---|---|
| `PreToolUse` | Tool name | Before the subagent uses a tool |
| `PostToolUse` | Tool name | After the subagent uses a tool |
| `Stop` | (none) | When the subagent finishes |

You can also configure hooks in `settings.json` that respond to subagent lifecycle events in the main session:

| Event | Matcher input | When it fires |
|---|---|---|
| `SubagentStart` | Agent type name | When a subagent begins execution |
| `SubagentStop` | Agent type name | When a subagent completes |

### Foreground vs Background Execution

Subagents can run two ways:

- **Foreground** (blocking): The main conversation waits for the subagent to finish. Permission prompts and clarifying questions pass through to you.
- **Background** (concurrent): The subagent runs while you continue working. Permissions are pre-approved upfront; if the subagent needs to ask a question, that call fails but work continues.

Claude decides based on the task, or you can ask: "run this in the background." You can also press `Ctrl+B` to background a running task.

If a background subagent fails due to missing permissions, you can resume it in the foreground to retry with interactive prompts.

### The /agents Command

Run `/agents` in Claude Code to manage subagents interactively:
- View all available subagents (built-in, user, project, plugin)
- Create new subagents with guided setup or Claude generation
- Edit existing subagent configuration
- Delete custom subagents
- See which subagents are active when duplicates exist

This is the recommended way to manage subagents day-to-day.

### Monitoring Subagents with tmux

Here's where your tmux skills from Course 7½ come in.

**The problem**: When a subagent runs in the background or in a forked context, you can't see what it's doing from your main session. You see the final result, but not the process -- which tools it called, what files it read, whether it hit a permissions issue.

**The pattern**: Use tmux split panes to watch a subagent work in real time.

#### The Headless Agent Monitoring Setup

This draws directly from the tmux-claude tutorial's Lesson 9 (headless Claude sessions). The idea is to run Claude in a detached tmux session and monitor from another pane:

1. **Create a monitoring session** (or use your existing session):
   ```bash
   tmux new-session -d -s agent-monitor
   ```

2. **Set up split panes** -- left pane for your main Claude session, right pane for tailing the agent's work:
   ```
   Ctrl+J %
   ```

3. **In the right pane, peek at agent progress**:
   ```bash
   tmux capture-pane -t agent-session -p | tail -20
   ```

4. Or use `watch` for continuous monitoring:
   ```bash
   watch -n 2 'tmux capture-pane -t agent-session -p | tail -15'
   ```

#### When to Use tmux Monitoring vs In-Process Execution

| Use tmux monitoring when... | Use in-process execution when... |
|---|---|
| Debugging tool restrictions | The subagent is working correctly |
| Watching the agent's raw output | You only need the final result |
| Running multiple agents in parallel | The task is quick and focused |
| Developing/testing a new subagent | Using a well-tested subagent |

**Important**: Tmux monitoring is a **development/debugging workflow**. Once your subagent works correctly, you typically run it in-process and just review the returned results. The split-pane approach is for when you need visibility into the agent's process, not its output.

Refer to the tmux quick-reference from Course 7½ for the exact commands.

## Key References
- Subagents docs: Full configuration reference (fields, tools, models, hooks, memory)
- tmux-claude tutorial Lesson 9: Headless Claude sessions (the detached-session pattern)
- Course 7½ tmux-quickref.md: Quick reference for tmux commands used in this course
- [Choosing the Right Mode](../references/choosing-the-right-mode.md): Decision framework for skills vs sub-agents vs agent teams -- when to escalate and when to step back down

## What You're Building

Two custom subagents and a supporting skill:

1. **test-runner** -- A fast, cheap agent using Haiku that runs your test suite and reports results. Demonstrates model selection and tool restrictions.

2. **security-reviewer** -- A read-only agent with persistent memory that reviews code for security issues. Demonstrates memory, skill preloading, and the read-only pattern.

3. **security-patterns** skill -- Preloaded into the security-reviewer, giving it OWASP Top 10 knowledge without needing to discover it at runtime.

Together, these demonstrate the core subagent patterns: cost optimization (haiku), safety constraints (read-only tools), domain knowledge injection (preloaded skills), and cross-session learning (persistent memory).

## Walkthrough

### Step 1: Create the security-patterns skill

The security-reviewer subagent needs domain knowledge about common vulnerabilities. Instead of putting all that content in the agent's system prompt (which would be too long), you'll create a skill that the agent preloads.

Create the skill directory:

```bash
mkdir -p ~/.claude/skills/security-patterns/references
```

Create `~/.claude/skills/security-patterns/SKILL.md`:

```yaml
---
name: security-patterns
description: Reference material for common security vulnerabilities and secure coding patterns. Use when reviewing code for security issues or implementing security-sensitive features.
---

# Security Patterns Reference

When reviewing code for security issues, check for the following categories.

## Injection Flaws
- **SQL Injection**: Look for string concatenation in SQL queries. Require parameterized queries or prepared statements.
- **Command Injection**: Look for user input passed to shell commands, `exec()`, `eval()`, or `system()` calls. Require input sanitization and allowlists.
- **XSS (Cross-Site Scripting)**: Look for unsanitized user input rendered in HTML. Require output encoding and Content Security Policy headers.

## Authentication and Session Management
- Hardcoded credentials, API keys, or secrets in source code
- Missing or weak password hashing (look for MD5, SHA1 without salt)
- Session tokens in URLs or logs
- Missing session expiration or rotation after login

## Sensitive Data Exposure
- Secrets in environment variables without `.env` in `.gitignore`
- API keys or tokens committed to version control
- Logging of sensitive data (passwords, tokens, PII)
- Missing encryption for data in transit (HTTP instead of HTTPS)

## Access Control
- Missing authorization checks on endpoints or functions
- Direct object references without ownership validation
- Privilege escalation through parameter manipulation
- Missing rate limiting on sensitive operations

## Security Misconfiguration
- Debug mode enabled in production
- Default credentials left unchanged
- Overly permissive CORS settings
- Missing security headers (HSTS, X-Frame-Options, CSP)

## Input Validation
- Missing or client-side-only validation
- Path traversal vulnerabilities (`../` in file paths)
- Unrestricted file upload (type, size, content)
- Integer overflow or type confusion

For detailed descriptions, see `references/owasp-top-10.md`.
```

Create the OWASP reference at `~/.claude/skills/security-patterns/references/owasp-top-10.md`:

```markdown
# OWASP Top 10 Quick Reference

## A01: Broken Access Control
- Violation of least privilege or deny-by-default
- Bypassing access checks by modifying URLs, API requests, or internal state
- Accessing another user's records by providing their identifier (IDOR)
- Missing access control for POST, PUT, DELETE
- **Check for**: Authorization middleware on every route, ownership validation on data access

## A02: Cryptographic Failures
- Data transmitted in clear text (HTTP, SMTP, FTP)
- Use of old or weak cryptographic algorithms (MD5, SHA1, DES)
- Default or missing encryption keys
- **Check for**: TLS everywhere, strong hashing (bcrypt, argon2), proper key management

## A03: Injection
- User-supplied data not validated, filtered, or sanitized
- Dynamic queries without parameterization
- Hostile data used in ORM search parameters
- **Check for**: Parameterized queries, input validation, ORM safe methods

## A04: Insecure Design
- Missing threat modeling
- No rate limiting on high-value transactions
- Missing input validation at the business logic level
- **Check for**: Design-level security controls, abuse case testing

## A05: Security Misconfiguration
- Missing security hardening across the application stack
- Unnecessary features enabled (ports, services, pages, accounts)
- Default accounts and passwords unchanged
- Error handling reveals stack traces or sensitive information
- **Check for**: Hardened defaults, minimal attack surface, no stack traces in production

## A06: Vulnerable and Outdated Components
- Dependencies with known CVEs
- Unmaintained libraries
- **Check for**: `npm audit`, `pip-audit`, dependabot alerts, lock file freshness

## A07: Identification and Authentication Failures
- Permits brute force or credential stuffing
- Uses default, weak, or well-known passwords
- Missing or ineffective multi-factor authentication
- **Check for**: Rate limiting on auth endpoints, strong password policies, MFA support

## A08: Software and Data Integrity Failures
- Dependencies from untrusted sources without integrity verification
- CI/CD pipelines without integrity checks
- Auto-update without signature verification
- **Check for**: Lock files with integrity hashes, signed releases, CI/CD access controls

## A09: Security Logging and Monitoring Failures
- Auditable events not logged (logins, failed logins, high-value transactions)
- Logs not monitored for suspicious activity
- Logs only stored locally
- **Check for**: Centralized logging, alerting on auth failures, audit trails

## A10: Server-Side Request Forgery (SSRF)
- Fetching remote resources without validating user-supplied URLs
- No allowlist for destination addresses
- **Check for**: URL validation, allowlists for external requests, blocking internal network access
```

### Step 2: Create the test-runner subagent

This agent uses Haiku for speed and cost efficiency. It runs tests, captures output, and reports results.

Create `~/.claude/agents/test-runner.md`:

```markdown
---
name: test-runner
description: Fast test runner that executes test suites and reports results. Use when the user says "run tests", "run the test suite", "check if tests pass", or "fix failing tests". Use proactively after code changes.
tools: Bash, Read, Grep
model: haiku
---

You are a fast, focused test runner. Your job is to execute test suites and report results clearly.

When invoked:

1. **Detect the test framework** by looking for:
   - `package.json` with test scripts → `npm test` or `npx jest` or `npx vitest`
   - `pytest.ini`, `pyproject.toml`, or `tests/` directory → `pytest`
   - `Cargo.toml` → `cargo test`
   - `go.mod` → `go test ./...`
   - `Makefile` with a test target → `make test`

2. **Run the test suite** using the detected framework.

3. **Report results** in this format:

   ### Test Results
   - **Status**: PASS / FAIL
   - **Total**: N tests
   - **Passed**: N
   - **Failed**: N
   - **Skipped**: N

   If any tests failed:
   ### Failures
   For each failure:
   - **Test name**: `test_name_here`
   - **File**: `path/to/test/file.py:line`
   - **Error**: Brief description of what went wrong
   - **Relevant code**: The failing assertion or error

4. **Do not fix code**. Your job is to report, not repair. If asked to fix failures, explain what went wrong but defer the actual fix to the main conversation.

## Rules
- Run the full suite unless the user specifies a subset
- If no test framework is detected, say so and ask what command to use
- Keep output concise -- summarize, don't dump raw terminal output
- If tests take longer than 60 seconds, note the runtime
```

### Step 3: Create the security-reviewer subagent

This agent is read-only, preloads the security-patterns skill, and uses persistent project-level memory to accumulate knowledge about the codebase's security profile over time.

Create `~/.claude/agents/security-reviewer.md`:

```markdown
---
name: security-reviewer
description: Reviews code for security vulnerabilities and insecure patterns. Use when the user says "review for security", "security audit", "check for vulnerabilities", or "is this code secure". Use proactively when reviewing authentication, authorization, or data handling code.
tools: Read, Grep, Glob
model: sonnet
memory: project
skills:
  - security-patterns
---

You are a security-focused code reviewer. You have read-only access to the codebase. Your job is to identify vulnerabilities, insecure patterns, and security risks.

When invoked:

1. **Check your memory** for previously identified patterns in this project. Review your MEMORY.md to see if you've noted recurring issues, security-sensitive files, or architectural patterns.

2. **Identify scope**. If a specific file or directory was mentioned, focus there. Otherwise, prioritize:
   - Authentication and authorization code
   - API endpoints and route handlers
   - Database queries and data access layers
   - Configuration files and environment handling
   - Input validation and output encoding
   - Dependency manifests (package.json, requirements.txt, etc.)

3. **Scan for vulnerabilities** using the security-patterns skill as your checklist. For each issue found, report:

   ### Finding: [Short Title]
   - **Severity**: Critical / High / Medium / Low
   - **Category**: [OWASP category, e.g., A03: Injection]
   - **File**: `path/to/file.ext:line`
   - **Issue**: What's wrong and why it matters
   - **Evidence**: The specific code that's vulnerable
   - **Recommendation**: How to fix it, with a code example if helpful

4. **Summarize** at the end:
   - Total findings by severity
   - Top priority items to fix first
   - Overall security posture assessment (1-2 sentences)

5. **Update your memory** with what you learned:
   - Security-sensitive files and directories in this project
   - Recurring patterns (good or bad) you've observed
   - Framework-specific security notes
   - Any custom security middleware or utilities the project uses

## Rules
- You are read-only. Never suggest running commands that modify code.
- Be specific: "Line 42 of auth.ts concatenates user input into a SQL query" not "there might be SQL injection somewhere".
- Don't report theoretical vulnerabilities -- only flag what you can see in the code.
- If you find no issues, say so. Don't invent problems.
- Always check your memory first to see if you've reviewed this area before.
```

### Step 4: Verify the file structure

Confirm everything is in the right place:

```bash
# Check the agents
ls -la ~/.claude/agents/test-runner.md
ls -la ~/.claude/agents/security-reviewer.md

# Check the skill
ls -la ~/.claude/skills/security-patterns/SKILL.md
ls -la ~/.claude/skills/security-patterns/references/owasp-top-10.md
```

You should see all four files. If `~/.claude/agents/` doesn't exist, create it:

```bash
mkdir -p ~/.claude/agents
```

### Step 5: Verify agent visibility

Open a new Claude Code session (subagents are loaded at session start) and run:

```
/agents
```

You should see `test-runner` and `security-reviewer` listed alongside the built-in subagents (Explore, Plan, general-purpose, etc.).

### Step 6: Test the test-runner agent

In any project that has tests, ask Claude:

```
Run the test suite
```

Claude should recognize the test-runner agent from its description and delegate to it. Watch for:
- Claude says it's delegating to the test-runner subagent
- The agent uses **Haiku** (you'll see this in the subagent header)
- It only uses **Bash, Read, and Grep** (no Edit or Write)
- Results come back in the structured format from the agent's prompt

You can also invoke it explicitly:

```
Use the test-runner subagent to check if all tests pass
```

### Step 7: Test the security-reviewer agent

Ask Claude to review a file:

```
Review src/auth.ts for security issues
```

Or for a broader scan:

```
Do a security audit of this project
```

Watch for:
- Claude delegates to the security-reviewer subagent
- The agent uses **Sonnet** (more capable model for deeper analysis)
- It only uses **Read, Grep, and Glob** (read-only -- no Bash, Edit, or Write)
- The security-patterns skill content is available immediately (the agent doesn't need to discover it)
- Findings follow the structured format with severity, category, and OWASP references

Run it a second time. The agent should check its memory for patterns from the first invocation. Over multiple runs, it builds up a project-specific security knowledge base.

### Step 8: Monitor a subagent with tmux

This is the development/debugging workflow from Part 2 of the concepts section.

1. **Start a tmux session** (or use your existing one):
   ```bash
   tmux new -s dev
   ```

2. **Split vertically** -- left pane for your main Claude session, right pane for monitoring:
   ```
   Ctrl+J %
   ```

3. **In the left pane**, start Claude:
   ```bash
   claude
   ```

4. **In the left pane**, trigger the security-reviewer:
   ```
   Review this project for security vulnerabilities
   ```

5. **In the right pane** (`Ctrl+J →`), watch what Claude Code is doing. Since subagents run within the Claude process, you'll see the agent's work in the same pane. The real power of tmux monitoring comes when you run Claude headless in a separate session:

   ```bash
   # From the right pane, start a headless Claude in a detached session
   tmux new-session -d -s security-review "cd $(pwd) && claude 'Use the security-reviewer to audit this project'"
   ```

6. **Peek at the headless agent's progress** from the right pane:
   ```bash
   tmux capture-pane -t security-review -p | tail -20
   ```

7. Or **attach to watch live**:
   ```bash
   tmux attach -t security-review
   ```
   (Detach with `Ctrl+J d` when you've seen enough)

8. **Clean up** the headless session when done:
   ```bash
   tmux kill-session -t security-review
   ```

This pattern is essential when you're developing a new subagent and need to see exactly what tools it's calling, what files it's reading, and where it gets stuck.

## Exercises

1. **Create and test both agents**. Install the test-runner and security-reviewer agents as described in the walkthrough. Run the test-runner against a project with tests and verify it uses Haiku and restricted tools. Run the security-reviewer and verify it uses Sonnet, read-only tools, and the preloaded security-patterns skill. Confirm that the security-reviewer's memory accumulates across invocations.

2. **Test the security-reviewer's memory**. Run the security-reviewer on the same project twice. After the first run, check that `MEMORY.md` was created in `.claude/agent-memory/security-reviewer/`. Read it. On the second run, verify the agent references its prior findings. Add a deliberately insecure pattern to a file (e.g., string concatenation in a SQL query) and run the reviewer again -- does it catch it and relate it to prior findings?

3. **Monitor a subagent with tmux**. Set up the split-pane layout from Step 8. In the left pane, start Claude and trigger the security-reviewer agent. In the right pane, launch a headless Claude session running the same review, then use `tmux capture-pane` to peek at its progress. Verify you can see which tools the agent is calling and what files it's reading. Compare the experience of watching the agent work in real time vs just seeing the final output.

4. **Build your own subagent**. Create a custom subagent for a task you do frequently. Some ideas:
   - A **doc-writer** (tools: Read, Grep, Glob, Write; model: sonnet) that generates or updates documentation
   - A **dependency-checker** (tools: Bash, Read; model: haiku) that audits outdated packages
   - A **log-analyzer** (tools: Read, Grep, Glob; model: haiku) that scans log files for errors and patterns

   Give it a clear description, appropriate tool restrictions, and test that Claude delegates to it correctly.

## Verification Checklist

- [ ] `~/.claude/agents/test-runner.md` exists with valid YAML frontmatter
- [ ] `~/.claude/agents/security-reviewer.md` exists with valid YAML frontmatter
- [ ] `~/.claude/skills/security-patterns/SKILL.md` exists with the vulnerability checklist
- [ ] `~/.claude/skills/security-patterns/references/owasp-top-10.md` exists
- [ ] Running `/agents` shows both custom agents alongside the built-ins
- [ ] The test-runner uses Haiku and is restricted to Bash, Read, Grep
- [ ] The security-reviewer uses Sonnet and is restricted to Read, Grep, Glob
- [ ] The security-reviewer's findings reference OWASP categories from the preloaded skill
- [ ] The security-reviewer creates/updates `MEMORY.md` in `.claude/agent-memory/security-reviewer/`
- [ ] Running the security-reviewer a second time shows it consulting memory from the first run
- [ ] You can monitor a headless agent via `tmux capture-pane` from a separate pane

## What's Next

In **Course 9: Skills + CLI Tool Integration**, you'll learn:
- How to build skills that wrap CLI tools like `gh` and `git`
- Dynamic context injection with live CLI output
- The wrapper-command pattern: shell scripts that combine AI + CLI tools into standalone commands
- You'll build a `github-release-notes` skill and a `dx-review.sh` wrapper script

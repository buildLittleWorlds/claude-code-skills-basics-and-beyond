# Course 7: Hooks -- Deterministic Control over Claude's Behavior
**Level**: Intermediate | **Estimated time**: 35 min

## Prerequisites
- Courses 1-6 completed (skill fundamentals, descriptions, anatomy, testing, advanced features, workflows)
- `jq` installed for JSON parsing (`brew install jq` on macOS, `apt-get install jq` on Linux)
- A text editor and a project directory with some files to test against

## Concepts

### What Are Hooks?

Every skill you've built so far gives Claude *instructions* -- but instructions are suggestions. Claude decides whether to follow them based on context and judgment. Sometimes you need guarantees: "always format code after editing", "never touch .env files", "block destructive shell commands." These aren't judgment calls -- they're rules.

Hooks are shell commands (or LLM prompts) that execute automatically at specific points in Claude Code's lifecycle. They provide **deterministic control** -- the hook runs every time, regardless of what the LLM decides to do.

Think of it this way:
- **Skills** = "Here's how to do this task" (Claude decides when/whether to follow)
- **Hooks** = "This code runs every time this event happens" (no LLM judgment involved)

### Hook Lifecycle: Where Hooks Fire

Hooks fire at specific points during a Claude Code session. Here are the key events, grouped by when they occur:

**Session boundaries:**
| Event | When it fires |
|---|---|
| `SessionStart` | When a session begins or resumes |
| `SessionEnd` | When a session terminates |

**User input:**
| Event | When it fires |
|---|---|
| `UserPromptSubmit` | When you submit a prompt, before Claude processes it |

**Tool execution (the agentic loop):**
| Event | When it fires |
|---|---|
| `PreToolUse` | Before a tool call executes -- can block it |
| `PostToolUse` | After a tool call succeeds |
| `PostToolUseFailure` | After a tool call fails |
| `PermissionRequest` | When a permission dialog appears |

**Agent lifecycle:**
| Event | When it fires |
|---|---|
| `SubagentStart` | When a subagent is spawned |
| `SubagentStop` | When a subagent finishes |
| `Stop` | When Claude finishes responding |

**Team coordination:**
| Event | When it fires |
|---|---|
| `TeammateIdle` | When a teammate is about to go idle |
| `TaskCompleted` | When a task is being marked as completed |

**Context management:**
| Event | When it fires |
|---|---|
| `PreCompact` | Before context compaction |
| `Notification` | When Claude Code sends a notification |

The two events you'll use most often are `PreToolUse` (to intercept actions before they happen) and `PostToolUse` (to react after they succeed).

### Matchers: Filtering When Hooks Fire

Without a matcher, a hook fires on **every** occurrence of its event. Matchers let you narrow that down using regex patterns. For tool events, the matcher filters on the tool name:

```
"matcher": "Bash"           -- only Bash tool calls
"matcher": "Edit|Write"     -- Edit or Write tool calls
"matcher": "mcp__.*"        -- any MCP tool
```

Different events match on different fields:
- **Tool events** (`PreToolUse`, `PostToolUse`, etc.) match on tool name
- **`SessionStart`** matches on how the session started: `startup`, `resume`, `clear`, `compact`
- **`Notification`** matches on notification type: `permission_prompt`, `idle_prompt`
- **`UserPromptSubmit`** and **`Stop`** don't support matchers -- they always fire

Omitting the matcher or using `"*"` matches everything for that event.

### Hook I/O: How Hooks Communicate

Hooks communicate with Claude Code through a simple protocol:

**Input** (JSON on stdin): Claude Code sends event-specific data as JSON. Every event includes common fields like `session_id`, `cwd`, and `hook_event_name`. Tool events add `tool_name` and `tool_input`:

```json
{
  "session_id": "abc123",
  "cwd": "/Users/you/project",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "npm test"
  }
}
```

**Output** (exit codes + stdout/stderr):

| Exit code | Meaning | Effect |
|---|---|---|
| `0` | Success | Action proceeds. Stdout is parsed for optional JSON output |
| `2` | Block | Action is blocked. Stderr is fed back to Claude as feedback |
| Other | Non-blocking error | Action proceeds. Stderr logged in verbose mode only |

For finer control, exit 0 and print a JSON object to stdout. For `PreToolUse`, this lets you allow, deny, or escalate to the user:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Destructive command blocked"
  }
}
```

The three `permissionDecision` values for `PreToolUse`:
- `"allow"` -- proceed without showing a permission prompt
- `"deny"` -- cancel the tool call, send the reason to Claude
- `"ask"` -- show the permission prompt to the user as normal

### Three Hook Types

#### 1. Command Hooks (`type: "command"`)

The most common type. Runs a shell command that reads JSON from stdin and communicates through exit codes and stdout:

```json
{
  "type": "command",
  "command": ".claude/hooks/my-script.sh"
}
```

This is what you'll use for deterministic rules like "block edits to .env" or "run prettier after writes."

#### 2. Prompt Hooks (`type: "prompt"`)

Instead of running a shell command, sends the hook input to a Claude model (Haiku by default) for a single-turn evaluation. The model returns `{"ok": true}` to allow or `{"ok": false, "reason": "..."}` to block:

```json
{
  "type": "prompt",
  "prompt": "Check if all tasks are complete. If not, respond with what remains. $ARGUMENTS"
}
```

Use `$ARGUMENTS` as a placeholder for the hook's JSON input. The model's only job is to return a yes/no decision.

Use prompt hooks when the decision requires **judgment** rather than a deterministic rule -- for example, "has Claude addressed all parts of the user's request?"

#### 3. Agent Hooks (`type: "agent"`)

Like prompt hooks, but the model gets multi-turn tool access (Read, Grep, Glob). The agent can inspect files and code before making its decision:

```json
{
  "type": "agent",
  "prompt": "Verify all unit tests pass. Run the test suite and check results. $ARGUMENTS",
  "timeout": 120
}
```

Use agent hooks when verification requires inspecting the actual state of the codebase, not just evaluating the hook input data. Agent hooks have a longer default timeout (60s) and can run up to 50 tool-use turns.

### Hook Configuration: Where Hooks Live

Hooks are defined in JSON settings files. The configuration has three levels of nesting:

1. Choose a **hook event** (`PreToolUse`, `PostToolUse`, etc.)
2. Add a **matcher group** to filter when it fires
3. Define one or more **hook handlers** to run

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/check-command.sh"
          }
        ]
      }
    ]
  }
}
```

Where you store this configuration determines its scope:

| Location | Scope |
|---|---|
| `~/.claude/settings.json` | All your projects (personal) |
| `.claude/settings.json` | Single project (shareable, committable) |
| `.claude/settings.local.json` | Single project (gitignored, local-only) |
| Plugin `hooks/hooks.json` | When plugin is enabled |
| Skill or agent frontmatter | While the component is active |

Use `$CLAUDE_PROJECT_DIR` in your commands to reference scripts relative to the project root:

```json
{
  "type": "command",
  "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/my-script.sh"
}
```

### Async Hooks: Non-Blocking Background Tasks

By default, hooks block Claude's execution until they complete. For long-running tasks, set `"async": true` to run in the background:

```json
{
  "type": "command",
  "command": "/path/to/run-tests.sh",
  "async": true,
  "timeout": 300
}
```

Claude continues working immediately while the script runs. When it finishes, results are delivered on the next conversation turn via `systemMessage` or `additionalContext`.

Async hooks **cannot** block or control Claude's behavior (the action already proceeded). They're useful for test suites, deployments, or notifications that shouldn't slow down the workflow.

### Hooks in Skills and Agents

This is where hooks and skills come together. You can define hooks directly in a skill's YAML frontmatter. These hooks are **scoped to the skill's lifecycle** -- they activate when the skill loads and are cleaned up when it finishes.

```yaml
---
name: secure-operations
description: Perform operations with security checks
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/security-check.sh"
---
```

This is powerful: a skill can carry its own guardrails. When a deployment skill activates, its hooks automatically enforce safety rules. When the skill finishes, the hooks are removed.

The `once` field (skills only) lets a hook run just once per session:

```yaml
hooks:
  SessionStart:
    - hooks:
        - type: command
          command: "./scripts/setup.sh"
          once: true
```

### The `/hooks` Menu

Type `/hooks` in Claude Code to open the interactive hooks manager. You can view, add, and delete hooks without editing JSON files. Each hook is labeled with its source: `[User]`, `[Project]`, `[Local]`, or `[Plugin]`.

To temporarily disable all hooks: set `"disableAllHooks": true` in your settings, or use the toggle in the `/hooks` menu.

### Debugging Hooks

- **`Ctrl+O`**: Toggle verbose mode to see hook output in the transcript
- **`claude --debug`**: Full execution details including which hooks matched and their exit codes
- **Manual testing**: Pipe sample JSON to your script to test it in isolation:
  ```bash
  echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | ./my-hook.sh
  echo $?
  ```

### Common Pitfalls

1. **Stop hook infinite loop**: If your `Stop` hook always blocks, Claude never stops. Check `stop_hook_active` in the input:
   ```bash
   if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
     exit 0  # Allow Claude to stop this time
   fi
   ```

2. **JSON parsing errors from shell profile**: If your `~/.zshrc` prints text on startup, it contaminates hook stdout. Wrap echo statements in an interactive check:
   ```bash
   if [[ $- == *i* ]]; then
     echo "Shell ready"
   fi
   ```

3. **Hook not firing**: Check that your matcher is case-sensitive and matches the exact tool name. Run `/hooks` to verify the hook appears.

4. **Exit code confusion**: Exit 2 = block (stderr becomes feedback). Exit 0 with JSON = structured control. Don't mix them -- JSON is ignored on exit 2.

## Key References
- Hooks reference: `~/.claude-code-docs/docs/hooks.md` -- Full event schemas, JSON I/O, decision control
- Hooks guide: `~/.claude-code-docs/docs/hooks-guide.md` -- Setup walkthrough, common patterns, troubleshooting

## What You're Building

You'll create three hook scripts and a skill that uses hooks in its frontmatter:

1. **`hooks/auto-format.sh`** -- A `PostToolUse` hook that runs Prettier on any file Claude edits or creates. Demonstrates the most common hook pattern: react after a tool completes.

2. **`hooks/protect-files.sh`** -- A `PreToolUse` hook that blocks edits to sensitive files (`.env`, `package-lock.json`, `.git/`). Demonstrates blocking with exit code 2.

3. **`hooks/settings-snippet.json`** -- A complete `.claude/settings.json` example with both hooks configured, ready to copy into any project.

4. **`skill/safe-deploy/`** -- A deployment skill with hooks embedded in its frontmatter. When the skill activates, its `PreToolUse` hook validates every Bash command against a list of dangerous patterns. This demonstrates hooks scoped to a skill's lifecycle.

## Walkthrough

### Step 1: Create the auto-format hook

This hook runs after every `Edit` or `Write` tool call and formats the affected file with Prettier.

Create `hooks/auto-format.sh` in the course directory (you'll copy it to a real project later):

```bash
#!/bin/bash
# auto-format.sh -- PostToolUse hook for Edit|Write
# Runs prettier on files after Claude edits or creates them.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file path (shouldn't happen for Edit/Write, but be safe)
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only format files prettier understands
case "$FILE_PATH" in
  *.js|*.jsx|*.ts|*.tsx|*.json|*.css|*.scss|*.md|*.html|*.yaml|*.yml)
    npx prettier --write "$FILE_PATH" 2>/dev/null
    ;;
esac

exit 0
```

Key points:
- Reads JSON from stdin, extracts `file_path` with `jq`
- Only formats file types Prettier handles (avoids errors on binary files)
- Always exits 0 -- formatting failure shouldn't block Claude's work
- Uses `2>/dev/null` to suppress Prettier's verbose output

### Step 2: Create the protect-files hook

This hook runs before every `Edit` or `Write` tool call and blocks changes to sensitive files.

Create `hooks/protect-files.sh`:

```bash
#!/bin/bash
# protect-files.sh -- PreToolUse hook for Edit|Write
# Blocks edits to sensitive files like .env, lock files, and .git/.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file path
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# List of protected patterns
PROTECTED_PATTERNS=(
  ".env"
  "package-lock.json"
  "yarn.lock"
  "pnpm-lock.yaml"
  ".git/"
)

for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "Blocked: '$FILE_PATH' matches protected pattern '$pattern'. This file should not be modified by Claude." >&2
    exit 2
  fi
done

exit 0
```

Key points:
- Exits with code **2** to block the action -- this is the critical difference from auto-format
- Writes the reason to **stderr** -- Claude receives this as feedback and adjusts its approach
- Checks multiple patterns in a loop -- easy to add new protected paths
- The feedback message is specific ("matches protected pattern '.env'") not generic ("file blocked")

### Step 3: Create the settings snippet

This file shows how to wire both hooks into a project's `.claude/settings.json`:

Create `hooks/settings-snippet.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/protect-files.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/auto-format.sh"
          }
        ]
      }
    ]
  }
}
```

Notice the ordering: `PreToolUse` fires *before* the edit (can block it), `PostToolUse` fires *after* (reacts to it). Both use the same `Edit|Write` matcher but serve completely different purposes.

To install these hooks in a real project:
1. Copy `protect-files.sh` and `auto-format.sh` to your project's `.claude/hooks/` directory
2. Make them executable: `chmod +x .claude/hooks/*.sh`
3. Merge the JSON from `settings-snippet.json` into your project's `.claude/settings.json`

### Step 4: Build the safe-deploy skill

This skill demonstrates **hooks in frontmatter** -- the hook activates only while the skill is running.

Create `skill/safe-deploy/SKILL.md`:

```yaml
---
name: safe-deploy
description: Safely deploy an application with guardrails. Use when the user says "deploy", "ship it", "push to production", or "release to staging". Validates all commands against a safety checklist before execution.
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-deploy-command.sh"
---

# Safe Deploy

Deploy the application with built-in safety checks. Every Bash command is validated
against a list of dangerous patterns before execution.

## Steps

1. **Confirm the deployment target** -- Ask the user which environment to deploy to
   (staging, production, etc.). Never assume production.

2. **Run pre-deployment checks**:
   - Verify the working directory is clean: `git status --porcelain`
   - Confirm you're on the expected branch: `git branch --show-current`
   - Run the test suite: `npm test` (or the project's equivalent)
   - Check for uncommitted migrations or config changes

3. **Execute the deployment** -- Run the project's deployment command.
   Common patterns:
   - `npm run deploy -- --env staging`
   - `git push origin main` (for Heroku-style deploys)
   - `fly deploy` / `railway up` / `vercel --prod`

4. **Verify the deployment**:
   - Check the deployment URL or health endpoint
   - Review deployment logs for errors
   - Confirm the expected version is running

5. **Report results** -- Summarize what was deployed, to which environment,
   and any issues encountered.

## Safety Rules

The embedded `PreToolUse` hook on Bash commands validates every command against these rules:
- **No force pushes**: `git push --force` and `git push -f` are blocked
- **No direct production database access**: Commands containing `production` + `db` or `DROP` are blocked
- **No deleting deployment infrastructure**: `rm -rf` on deployment directories is blocked
- **No skipping CI**: `--no-verify` flags are blocked

If a command is blocked, you'll receive feedback explaining why. Adjust the command
to comply with the safety rules and try again.

## Troubleshooting

- **"Command blocked by deploy safety hook"**: Read the specific reason in the error message. The hook blocks commands that match dangerous patterns. Rephrase the command to avoid the pattern.
- **Tests failing before deploy**: Fix the failing tests first. Never skip the test step.
- **Wrong branch**: Switch to the correct branch before deploying. The skill checks but does not auto-switch.
```

### Step 5: Create the deploy validation script

Create `skill/safe-deploy/scripts/validate-deploy-command.sh`:

```bash
#!/bin/bash
# validate-deploy-command.sh -- PreToolUse hook for Bash (used by safe-deploy skill)
# Blocks dangerous commands during deployment workflows.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Skip if no command
if [ -z "$COMMAND" ]; then
  exit 0
fi

# --- Dangerous pattern checks ---

# Block force pushes
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*(-f|--force)'; then
  echo "Blocked by deploy safety hook: force push is not allowed during deployments. Use a regular push instead." >&2
  exit 2
fi

# Block --no-verify (skipping pre-commit hooks, CI checks)
if echo "$COMMAND" | grep -q '\-\-no-verify'; then
  echo "Blocked by deploy safety hook: --no-verify is not allowed. Safety checks must not be skipped during deployments." >&2
  exit 2
fi

# Block destructive rm on common deployment directories
if echo "$COMMAND" | grep -qE 'rm\s+-rf\s+.*(deploy|dist|build|release|\.git)'; then
  echo "Blocked by deploy safety hook: destructive removal of deployment-related directories is not allowed." >&2
  exit 2
fi

# Block direct production database commands
if echo "$COMMAND" | grep -qiE '(production|prod).*(DROP|DELETE\s+FROM|TRUNCATE)'; then
  echo "Blocked by deploy safety hook: destructive database operations against production are not allowed." >&2
  exit 2
fi

if echo "$COMMAND" | grep -qiE '(DROP|TRUNCATE).*(production|prod)'; then
  echo "Blocked by deploy safety hook: destructive database operations against production are not allowed." >&2
  exit 2
fi

# All checks passed
exit 0
```

### Step 6: Make the scripts executable

After creating the files, make the hook scripts executable:

```bash
chmod +x hooks/auto-format.sh hooks/protect-files.sh
chmod +x skill/safe-deploy/scripts/validate-deploy-command.sh
```

## Exercises

### Exercise 1: Test the protect-files hook manually

Before wiring hooks into Claude Code, test them in isolation by piping sample JSON:

```bash
# This should exit 0 (allowed)
echo '{"tool_input":{"file_path":"/project/src/app.ts"}}' | ./hooks/protect-files.sh
echo "Exit code: $?"

# This should exit 2 (blocked) and print a reason to stderr
echo '{"tool_input":{"file_path":"/project/.env"}}' | ./hooks/protect-files.sh
echo "Exit code: $?"

# This should also be blocked
echo '{"tool_input":{"file_path":"/project/.git/config"}}' | ./hooks/protect-files.sh
echo "Exit code: $?"
```

Verify: the first command exits 0 silently. The second and third exit 2 and print a "Blocked:" message to stderr.

### Exercise 2: Test the deploy validation script

```bash
# Should be allowed
echo '{"tool_input":{"command":"git push origin main"}}' | ./skill/safe-deploy/scripts/validate-deploy-command.sh
echo "Exit code: $?"

# Should be blocked (force push)
echo '{"tool_input":{"command":"git push --force origin main"}}' | ./skill/safe-deploy/scripts/validate-deploy-command.sh
echo "Exit code: $?"

# Should be blocked (--no-verify)
echo '{"tool_input":{"command":"git commit --no-verify -m fix"}}' | ./skill/safe-deploy/scripts/validate-deploy-command.sh
echo "Exit code: $?"

# Should be blocked (destructive rm)
echo '{"tool_input":{"command":"rm -rf dist/"}}' | ./skill/safe-deploy/scripts/validate-deploy-command.sh
echo "Exit code: $?"
```

### Exercise 3: Install hooks in a real project

Pick a test project (or create one) and install the hooks:

```bash
# Create the hooks directory in your project
mkdir -p /path/to/project/.claude/hooks

# Copy the scripts
cp hooks/auto-format.sh /path/to/project/.claude/hooks/
cp hooks/protect-files.sh /path/to/project/.claude/hooks/
chmod +x /path/to/project/.claude/hooks/*.sh

# Copy the settings (or merge into existing settings)
cp hooks/settings-snippet.json /path/to/project/.claude/settings.json
```

Then open Claude Code in that project and:
1. Ask Claude to edit a `.js` file -- verify it gets formatted after the edit
2. Ask Claude to edit `.env` -- verify the edit is blocked with a clear message
3. Run `/hooks` to see both hooks listed under their events

### Exercise 4: Test the safe-deploy skill with hooks

Install the skill and test its embedded hooks:

```bash
mkdir -p ~/.claude/skills/safe-deploy/scripts
cp skill/safe-deploy/SKILL.md ~/.claude/skills/safe-deploy/
cp skill/safe-deploy/scripts/validate-deploy-command.sh ~/.claude/skills/safe-deploy/scripts/
chmod +x ~/.claude/skills/safe-deploy/scripts/validate-deploy-command.sh
```

In Claude Code, invoke:
```
/safe-deploy
```

Then, during the deployment workflow, try asking Claude to run a force push. The embedded hook should block it and explain why. Ask Claude to proceed with a regular push instead -- it should work.

### Exercise 5: Write a prompt-based Stop hook

Create a `Stop` hook that uses an LLM to verify Claude completed all tasks before stopping. Add this to your project's `.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Review the conversation and determine if all user-requested tasks are complete. If something was requested but not done, respond with {\"ok\": false, \"reason\": \"Still need to: [what's missing]\"}. If everything is done, respond with {\"ok\": true}."
          }
        ]
      }
    ]
  }
}
```

Test it: ask Claude to do two things (e.g., "create a file called test.txt and then list the directory"). Observe whether the Stop hook detects incomplete work.

## Verification Checklist

- [ ] `hooks/auto-format.sh` exists and is executable
- [ ] `hooks/protect-files.sh` exists and is executable
- [ ] `hooks/settings-snippet.json` is valid JSON with both `PreToolUse` and `PostToolUse` hooks
- [ ] `skill/safe-deploy/SKILL.md` has valid YAML frontmatter with a `hooks` field
- [ ] `skill/safe-deploy/scripts/validate-deploy-command.sh` exists and is executable
- [ ] Piping `.env` file path JSON to `protect-files.sh` exits with code 2
- [ ] Piping a normal file path to `protect-files.sh` exits with code 0
- [ ] Piping `git push --force` JSON to `validate-deploy-command.sh` exits with code 2
- [ ] Piping `git push origin main` JSON to `validate-deploy-command.sh` exits with code 0
- [ ] You understand the difference between exit 2 (block with stderr) and exit 0 with JSON (structured control)
- [ ] You can explain when to use command hooks vs prompt hooks vs agent hooks

## What's Next

The remaining courses involve monitoring AI agents in separate terminal sessions, orchestrating multi-agent workflows, and building automation tooling. **Course 7.5: Your Terminal Workspace** prepares your terminal environment for that work by introducing tmux -- the tool you'll use to observe and manage multiple Claude instances running in parallel.

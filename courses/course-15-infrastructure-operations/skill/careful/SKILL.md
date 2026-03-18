---
name: careful
description: |
  Activate careful mode -- block dangerous Bash commands for this session.
  Use when the user says "be careful", "careful mode", "safety mode",
  "block dangerous commands", or "safe mode". Activates a PreToolUse hook
  that intercepts destructive patterns like rm -rf, force push, DROP TABLE,
  and git reset --hard.
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "../resource-cleanup/hooks/block-destructive.sh"
---

# Careful Mode Activated

Dangerous Bash commands are now blocked for this session. The following patterns will be intercepted and stopped before execution:

| Blocked Pattern | What It Prevents |
|---|---|
| `rm -rf` | Recursive forced file deletion |
| `git push --force` / `git push -f` | Force pushing to remote branches |
| `DROP TABLE` / `DROP DATABASE` | SQL table or database destruction |
| `DELETE FROM` | SQL mass row deletion |
| `git reset --hard` | Discarding all uncommitted changes |
| `git clean -f` | Deleting untracked files |

## What Happens When a Command Is Blocked

When you attempt a blocked command, the hook will:
1. Stop the command from executing
2. Return a "BLOCKED" message explaining what was detected
3. Suggest how to proceed if the command is truly needed

## If You Need to Run a Legitimate Destructive Command

Ask the user for explicit confirmation first. Then append `# CONFIRMED_DESTRUCTIVE` as a comment to the command:

```bash
rm -rf build/ # CONFIRMED_DESTRUCTIVE
```

The hook recognizes this marker and allows the command through. **Never add this marker without the user's explicit approval.**

## Scope

This safety hook is active for the current session only. It does not persist across sessions or affect other projects. To activate it again, re-invoke `/careful`.

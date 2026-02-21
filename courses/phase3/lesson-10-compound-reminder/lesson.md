# Lesson 10: Compound Reminder Hook
**Phase**: 3 — Task Workflow Mastery | **Estimated time**: 25 min

## Prerequisites
- Completed **Lessons 4-9** (all skills working, tasks being completed with `/done`)
- Completed **Phase 2 Course 7** (hooks lifecycle, exit codes, JSON I/O, `jq`)
- `jq` installed (`brew install jq` or `apt-get install jq`)
- At least one task recently completed with `/done` (archive file with recent timestamp)

## What You'll Learn

Skills are instructions — Claude follows them when it chooses to. Hooks are rules — they execute automatically, every time. This lesson introduces your first hook for the task cockpit: a **Stop event hook** that reminds you to update MEMORY.md after completing tasks.

### The Problem

You complete a task with `/done`, archive it, log it — everything works. Then you end your session. Tomorrow, you start a new session and can't remember what decisions you made or what the context was. Why? Because you didn't update `~/MEMORY.md` with session notes.

The compound-reminder hook solves this by checking at every Stop event: "Did you complete tasks this session? Did you update MEMORY.md? If not, here's a reminder."

### The `Stop` Event

The `Stop` event fires every time Claude finishes responding — after every single turn, not just at session end. This means the hook runs frequently, so it needs to be fast and have a clear "do nothing" path for the 95% of turns where no reminder is needed.

### The Infinite Loop Trap

Here's the critical subtlety: when a Stop hook exits with code 2 (block with feedback), Claude receives the feedback message and responds to it. But responding triggers *another* Stop event, which fires the hook again, which exits 2 again...

The solution is the `stop_hook_active` environment variable:

```bash
if [ "${stop_hook_active}" = "1" ]; then
    exit 0
fi
export stop_hook_active=1
```

This guard ensures the hook only fires once per cycle. Without it, you get an infinite loop that eats your API credits.

## Exercise

### Step 1: Read the hook script

```bash
cat skills/courses/phase3/lesson-10-compound-reminder/hooks/compound-reminder.sh
```

Walk through the logic:
1. **Guard**: Check `stop_hook_active` — exit immediately if already fired
2. **Archive check**: Use `find` with `-mmin -10` to see if any archive files were modified in the last 10 minutes
3. **MEMORY.md check**: Use `find` similarly to see if MEMORY.md was updated recently
4. **Decision**: If archives changed but MEMORY.md didn't → exit 2 with reminder on stderr
5. **Otherwise**: exit 0 (allow, no reminder)

### Step 2: Understand the settings configuration

The hook needs to be registered in your Claude settings. Create a settings snippet:

```json
{
  "hooks": {
    "Stop": [
      {
        "type": "command",
        "command": "bash ~/.claude/hooks/compound-reminder.sh"
      }
    ]
  }
}
```

This goes in `~/.claude/settings.json` (or the project-level `.claude/settings.json`).

### Step 3: Install the hook

```bash
mkdir -p ~/.claude/hooks
cp skills/courses/phase3/lesson-10-compound-reminder/hooks/compound-reminder.sh ~/.claude/hooks/compound-reminder.sh
chmod +x ~/.claude/hooks/compound-reminder.sh
```

Now add the hook to your settings. If you don't already have a `~/.claude/settings.json`, create one:

```bash
cat > ~/.claude/settings.json << 'EOF'
{
  "hooks": {
    "Stop": [
      {
        "type": "command",
        "command": "bash ~/.claude/hooks/compound-reminder.sh"
      }
    ]
  }
}
EOF
```

If you already have a settings file, merge the hooks section manually.

### Step 4: Test the hook

First, ensure you have a recently completed task. If not, complete one now:

```
/done plan-weekend Called the group, confirmed for Saturday
```

Now ask Claude something simple:

```
What time is it?
```

After Claude responds (triggering the Stop event), the hook should fire. If MEMORY.md hasn't been updated recently, you should see Claude relay the reminder: "You completed task(s) but haven't updated MEMORY.md yet."

### Step 5: Satisfy the hook

Create or update MEMORY.md:

```bash
echo "## $(date +%Y-%m-%d) Session Notes" >> ~/MEMORY.md
echo "- Completed: Plan weekend hike" >> ~/MEMORY.md
echo "- Context: Group confirmed for Saturday, Steep Ravine trail" >> ~/MEMORY.md
```

Now ask Claude something again:

```
What's 2 + 2?
```

This time, the hook should fire and exit 0 (no reminder), because MEMORY.md was updated within the last 10 minutes.

### Step 6: Test the guard

To verify the infinite loop guard works, temporarily remove the guard (DON'T do this in production — just understand why it's there):

The guard is these lines:
```bash
if [ "${stop_hook_active}" = "1" ]; then
    exit 0
fi
export stop_hook_active=1
```

Without them, each reminder would trigger another Stop → another reminder → another Stop, forever. The guard breaks the cycle after one reminder.

## Checkpoint

- [ ] The hook fires after Claude responds (Stop event)
- [ ] When a task was recently completed but MEMORY.md wasn't updated, the reminder appears
- [ ] When MEMORY.md was updated recently, no reminder appears
- [ ] When no tasks were completed recently, no reminder appears
- [ ] The `stop_hook_active` guard prevents infinite loops
- [ ] The hook is registered in `~/.claude/settings.json`

## Design Rationale

**Why a 10-minute window?** The `find -mmin -10` check creates a sliding window. If you completed a task 15 minutes ago and haven't updated MEMORY.md, the hook stops reminding — you probably moved on to something else. 10 minutes is enough time to finish a task and write notes, but not so long that you get reminded about tasks from an hour ago.

**Why stderr for feedback?** When a hook exits with code 2, Claude reads stderr as the feedback message. Stdout is ignored for hook feedback. This is a Claude Code convention — same mechanism used in PreToolUse hooks to explain why a tool call was blocked.

**Why not just check at session end?** The `Stop` event fires after every response, not just at session end. This means the reminder appears while you're still in the session and can act on it. A session-end-only reminder would fire after you've already moved on.

## Phase 2 Callback

This lesson builds directly on:
- **Course 7** (Hooks): Stop event, exit codes (0=allow, 2=block+feedback), stderr for feedback messages, the `stop_hook_active` guard pattern. This is a direct application of everything Course 7 taught.

## What's Next

Lesson 11 builds the second hook: a PreToolUse guard that blocks edits to log and archive files. Together, these two hooks enforce the integrity of the task system — the reminder ensures documentation, and the file protection ensures the audit trail stays clean.

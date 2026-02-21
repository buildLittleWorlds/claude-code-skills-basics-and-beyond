# Lesson 6: `/triage` with Dynamic Context
**Phase**: 3 — Task Workflow Mastery | **Estimated time**: 30 min

## Prerequisites
- Completed **Lessons 4-5** (`/next` and `/done` skills working)
- Completed **Phase 2 Course 5** (dynamic context injection with `!`command``)
- Completed **Phase 2 Course 3** (reference files, `references/` directory)
- Inbox files in `~/work/_tasks/inbox/` (at least 3 from seed data, or add your own)

## What You'll Learn

`/next` reads pending tasks. `/done` completes them. But how do tasks get into pending in the first place? Right now, they sit in `inbox/` with minimal metadata — no domain, no priority, no due date. Someone has to classify them.

That's `/triage`. It reads every file in the inbox, classifies each one (domain, priority, due date, tags), updates the frontmatter, and moves it to pending. After triage, `/next` shows the newly classified tasks alongside existing ones.

This skill introduces two Phase 2 concepts working together:

1. **Dynamic context injection** (Course 5): The `!`command`` syntax runs shell commands *before* Claude sees the skill prompt. `/triage` uses this to inject the current inbox file listing, today's date, and the pending count — all live data that changes between invocations.

2. **Reference files** (Course 3): The `references/` directory contains `routing-rules.md` (domain classification rules) and `tagging-guide.md` (tag taxonomy). Claude reads these to make consistent decisions. Without references, Claude would invent its own classification scheme each time. References make the output predictable.

### How Dynamic Context Works

In the SKILL.md, you'll see lines like:

```
Current inbox contents:
!`ls ~/work/_tasks/inbox/ 2>/dev/null || echo "(empty)"`
```

When you invoke `/triage`:
1. The shell command `ls ~/work/_tasks/inbox/` runs in your terminal
2. The output replaces the entire `` !`...` `` placeholder
3. Claude receives the rendered prompt with actual file names

Claude never runs `ls` itself — it sees the *result*. This is preprocessing, not execution. The distinction matters because it means the data is always fresh and the skill doesn't need Bash tool access to get the listing.

## Exercise

### Step 1: Check your inbox

See what's waiting to be triaged:

```bash
ls ~/work/_tasks/inbox/
```

You should have 3-5 files from the seed data (assuming you completed some tasks with `/done` in Lesson 5, the inbox is untouched).

Read one to see the minimal metadata:

```bash
cat ~/work/_tasks/inbox/research-state-management.md
```

Notice: only `title`, `status: inbox`, and `created` are set. No domain, priority, due date, or tags.

### Step 2: Examine the skill and references

Read the SKILL.md:

```bash
cat skills/courses/phase3/lesson-06-triage-skill/skill/triage/SKILL.md
```

Key things to notice:
- Three `!`command`` injections (inbox listing, today's date, pending count)
- Seven-step workflow with clear sequencing
- References to `references/routing-rules.md` and `references/tagging-guide.md`
- Output format template showing the expected summary

Read the reference files:

```bash
cat skills/courses/phase3/lesson-06-triage-skill/skill/triage/references/routing-rules.md
cat skills/courses/phase3/lesson-06-triage-skill/skill/triage/references/tagging-guide.md
```

The routing rules define what makes a task "work" vs "personal." The tagging guide provides a controlled vocabulary. These are the kind of reference files the PDF guide recommends — they encode business logic that should be consistent across invocations.

### Step 3: Install the skill

```bash
mkdir -p ~/.claude/skills/triage/references
cp skills/courses/phase3/lesson-06-triage-skill/skill/triage/SKILL.md ~/.claude/skills/triage/SKILL.md
cp skills/courses/phase3/lesson-06-triage-skill/skill/triage/references/routing-rules.md ~/.claude/skills/triage/references/routing-rules.md
cp skills/courses/phase3/lesson-06-triage-skill/skill/triage/references/tagging-guide.md ~/.claude/skills/triage/references/tagging-guide.md
```

Verify the full structure:

```bash
find ~/.claude/skills/triage -type f
```

You should see three files: `SKILL.md`, `references/routing-rules.md`, `references/tagging-guide.md`.

### Step 4: Run triage

```
/triage
```

Claude should:
1. Read each inbox file
2. Apply the routing rules to assign domains
3. Assign priorities and due dates based on context
4. Apply tags from the taxonomy
5. Update each file's frontmatter
6. Move each file from `inbox/` to `pending/`
7. Display a summary showing what was classified

### Step 5: Verify the results

Check that the inbox is empty:

```bash
ls ~/work/_tasks/inbox/
```

Should return nothing (or show an error that the directory is empty).

Check that the files moved to pending:

```bash
ls ~/work/_tasks/pending/
```

You should see the newly triaged files alongside any remaining original pending tasks.

Read one of the triaged files to verify the metadata:

```bash
cat ~/work/_tasks/pending/research-state-management.md
```

It should now have `domain`, `priority`, `due`, and `tags` fields filled in — plus `status: pending`.

### Step 6: Verify with `/next`

```
/next
```

The newly triaged tasks should appear in the sorted list alongside existing pending tasks.

### Step 7: Test the empty inbox case

Run triage again:

```
/triage
```

Since the inbox is now empty, Claude should display the "Inbox is empty. Nothing to triage." message.

### Step 8: Add a new task and re-triage (optional)

Create a new inbox item to test the full flow:

```bash
cat > ~/work/_tasks/inbox/review-pull-request-401.md << 'EOF'
---
title: Review PR #401 for auth refactor
status: inbox
created: 2026-02-21T11:00
---

Large PR from Maria refactoring the auth middleware. She asked for review by end of day. About 400 lines changed across 8 files.
EOF
```

Run `/triage` again. Claude should process just this one new item and move it to pending with appropriate metadata (likely: work, P2, due today or tomorrow, tags: [review, security]).

## Checkpoint

- [ ] `/triage` processes all inbox files in a single pass
- [ ] Each triaged file has domain, priority, due, and tags assigned
- [ ] Files are moved from `inbox/` to `pending/`
- [ ] The triage summary shows counts by domain and priority
- [ ] Running `/triage` on an empty inbox produces a helpful message
- [ ] Routing decisions are consistent with `routing-rules.md`
- [ ] Tags come from the taxonomy in `tagging-guide.md`
- [ ] `/next` shows the newly triaged tasks

## Design Rationale

**Why dynamic context instead of letting Claude run `ls` itself?** Two reasons: (1) The `!`command`` preprocessing is faster — it runs before Claude's context loads, so Claude sees the data immediately without a tool-call round trip. (2) It's more reliable — Claude doesn't need Bash tool access, and the listing format is predictable. The dynamic context pattern is best for small, predictable data that informs the prompt.

**Why reference files instead of inline rules?** Reference files are maintainable. When you want to add a new domain (like "freelance") or new tags, you edit one file instead of rewriting the SKILL.md. They also get loaded as Level 3 content (progressive disclosure from Course 1) — Claude reads them only when the skill is active, keeping them out of the system prompt otherwise.

**Why not `context: fork` for triage?** Triage modifies files (updates frontmatter, moves files). A forked Explore agent is read-only. A forked general-purpose agent *could* work, but the output (a summary table) is useful to have in your main conversation context — you might want to ask follow-up questions about the classifications. Inline execution is the right call here.

## Phase 2 Callback

This lesson builds directly on:
- **Course 5** (Advanced Features): `!`command`` dynamic context injection is the core mechanism. Three preprocessing commands provide live data without tool calls.
- **Course 3** (Full Skill Anatomy): The `references/` directory holds routing rules and tagging guides — exactly the kind of supplementary knowledge files Course 3 introduced.
- **Course 6** (Multi-Step Workflows): The 8-step triage workflow is sequential with dependencies. Classification must happen before file moves.

## What's Next

You now have the core task pipeline: `/triage` (inbox → pending), `/next` (view pending), `/done` (pending → archive). Lesson 7 wraps all of this into a startup script that launches the cockpit with a single command — a tmux session with Claude, watchers, and your skills pre-loaded.

# Course 9: Skills + CLI Tool Integration
**Level**: Advanced | **Estimated time**: 50 min

## Prerequisites
- Completed **Courses 1-8** (skills fundamentals through custom subagents)
- Completed **Course 7½: Your Terminal Workspace** (tmux prerequisite)
- The GitHub CLI (`gh`) installed and authenticated (`gh auth status` shows logged in)
- Git installed and configured
- You have the `code-review-checklist` skill from Course 2 installed (we'll use it in Exercise 3)

## Concepts

### Skills That Wrap CLI Tools

In Course 5, you learned that `!`command`` runs shell commands before the skill content reaches Claude. You used it to fetch a single GitHub issue. Now you'll take that pattern further -- building skills that orchestrate multiple CLI commands and embed domain expertise about the output.

The PDF guide calls this **Category 3: Workflow Automation / MCP Enhancement**. The idea: your organization already has CLI tools (`gh`, `git`, `npm`, `docker`, `kubectl`, etc.) that do specific things well. Skills wrap those tools with:

1. **Preprocessing** -- `!`command`` fetches live data before Claude sees the prompt
2. **Domain expertise** -- reference files teach Claude how to interpret the data (PR categorization rules, changelog conventions, etc.)
3. **Structured output** -- templates ensure consistent formatting
4. **Error handling** -- specific diagnostics for CLI failures, not generic "something went wrong"

This is the MCP + Skills relationship from Course 1's kitchen analogy in action. MCP (or in this case, CLI tools accessible via Bash) provides the kitchen -- access to GitHub, git, and other services. The skill provides the recipe -- how to categorize PRs, format changelogs, and handle edge cases.

### The Dynamic Context Pattern at Scale

In Course 5, your `investigate-issue` skill had one `!`command`` call:

```
!`gh issue view $0 --json title,body,labels,assignees,comments`
```

The `github-release-notes` skill you'll build in this course has **four**:

```
Latest tag: !`git describe --tags --abbrev=0 2>/dev/null || echo "no-tags-found"`
PRs since last tag: !`gh pr list --state merged --search "merged:>=..." --json ... 2>/dev/null || echo "ERROR: ..."`
Current branch: !`git branch --show-current 2>/dev/null || echo "unknown"`
Repo: !`gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || echo "unknown"`
```

Each command serves a purpose:
- `git describe` finds the baseline (what's the last release?)
- `gh pr list` fetches the changes (what happened since then?)
- `git branch` provides context (which branch are we on?)
- `gh repo view` gets the repo identifier (for comparison links)

Two key patterns to notice:

**Defensive commands**: Every command uses `2>/dev/null || echo "FALLBACK"`. This is critical. If `gh` isn't authenticated or there's no git remote, the command still produces output -- an error string that the skill instructions can check for and handle gracefully. Without this, a failed preprocessing command would inject an empty string (or worse, a raw error message) into the prompt.

**Chained context**: The `gh pr list` command uses the output of `git describe` to compute a date range. This works because `!`command`` runs in a normal shell where subshell nesting is valid. You can use `$(...)` inside `!`...`` to compose commands.

### Error Handling for CLI Failures

Skills that wrap CLI tools fail in predictable ways. Good error handling means **specific diagnostics** for each failure mode:

| Failure | Symptom | Diagnosis |
|---------|---------|-----------|
| `gh` not installed | `command not found: gh` | "Install the GitHub CLI: `brew install gh`" |
| `gh` not authenticated | `gh auth login` prompt | "Authenticate first: `gh auth login`" |
| No git remote | Empty repo name | "Add a GitHub remote: `git remote add origin URL`" |
| No git tags | `no-tags-found` sentinel | "No releases yet. Want to generate notes from all commits?" |
| API rate limit | 403 / rate limit message | "GitHub API rate limited. Wait or use `gh auth refresh`" |
| Private repo without access | 404 / not found | "Check your `gh` auth scope includes repo access" |

The skill's instructions check for each sentinel value and provide the specific fix. This is the robust error handling pattern from Course 6 applied to CLI tool integration.

### The Wrapper-Command Pattern

Skills run inside Claude Code. But sometimes you want a **standalone shell command** that combines AI + CLI tools into something you can run from any terminal, script into CI, or alias in your shell config.

The dx-workflow tutor introduces this pattern with its `dx` toolkit -- a bash dispatcher that invokes AI CLIs with pre-built prompts. The key insight is that there are **three interaction modes** for AI+CLI wrappers:

#### Mode 1: Non-Interactive

```bash
claude -p "prompt"
```

One-shot: feed input, get output, exit. Best for:
- Code review (`dx review`) -- you want a result, not a conversation
- Standup generation (`dx standup`) -- summarize and done
- Release notes -- generate and paste into GitHub

The `dx-review.sh` script you'll build uses this mode.

#### Mode 2: Interactive Session

```bash
tmux new-session -d -s ai-session
tmux send-keys -t ai-session "claude" Enter
sleep 2
tmux send-keys -t ai-session "explain this code..." Enter
tmux attach -t ai-session
```

Starts an AI session with context preloaded, then hands control to the user for follow-up questions. Best for:
- Code explanation (`dx explain file.ts`) -- you'll want to ask "what about this part?"
- Debugging sessions -- iterative back-and-forth

#### Mode 3: Split-Pane

```bash
tmux split-window -h "claude -p 'analyze these test failures...'"
```

Opens AI output alongside your current work. Best for:
- Test failure analysis (`dx test`) -- see failures on the left, AI analysis on the right
- Monitoring -- watch AI output while continuing to work

### How Wrapper Scripts and Skills Relate

The wrapper-command pattern and skills are complementary, not competing:

| Approach | Invocation | Context | Best for |
|----------|-----------|---------|----------|
| **Skill** | `/skill-name` inside Claude Code | Full Claude Code environment | Tasks during a Claude conversation |
| **Wrapper script** | `./script.sh` from any terminal | Standalone, no Claude session needed | Automation, CI, shell aliases |
| **Script invoking a skill** | `claude -p "/skill-name ..."` | Wrapper launches Claude with skill | Best of both worlds |

The third row is the connection point. A wrapper script can invoke Claude with a skill reference:

```bash
claude -p "/code-review-checklist
Here is the diff:
$(git diff --cached)"
```

This gives you the wrapper's convenience (run from any terminal) plus the skill's structured instructions (Course 2's review dimensions). Exercise 3 explores this connection.

## Key References
- Skills docs: "Inject dynamic context" section -- `!`command`` preprocessing syntax
- PDF Guide: Chapter 2 "Category 3: MCP Enhancement" -- workflow automation patterns
- dx-workflow-tutor: Lessons 1-5 (dx skeleton, AI selection, review/PR/explain commands)
- dx-workflow-tutor: Lessons 8-9 (popup mode, background watchers)
- Course 5 lesson: Dynamic context injection, `$ARGUMENTS` substitution
- Course 7½ tmux-quickref.md: tmux commands for interactive and split-pane modes

## What You're Building

Two deliverables that demonstrate CLI tool integration from both sides:

### 1. `github-release-notes` Skill

A skill that generates structured release notes by fetching PRs from GitHub, categorizing them, and formatting a changelog. This demonstrates:

- **Multiple dynamic context commands** -- four `!`command`` calls for git/gh data
- **Domain expertise in reference files** -- PR categorization rules and changelog conventions
- **Structured output via template** -- consistent release notes format
- **Defensive error handling** -- sentinel values and specific diagnostics for each failure mode

File structure:

```
github-release-notes/
├── SKILL.md                              # Workflow with dynamic CLI context
├── references/
│   ├── changelog-conventions.md          # Keep a Changelog format rules
│   └── pr-categories.md                  # Feature/fix/breaking/docs/chore rules
└── assets/
    └── release-template.md               # Output format template
```

### 2. `dx-review.sh` Wrapper Script

A standalone shell script (~40 lines) that captures `git diff --cached`, constructs a review prompt, and runs `claude -p` for a one-shot code review. Demonstrates:

- **The non-interactive wrapper pattern** -- capture CLI output, construct prompt, run AI
- **Edge case handling** -- no staged changes
- **Skill integration** -- `--skill` flag invokes the `/code-review-checklist` skill from Course 2

## Walkthrough

### Step 1: Understand the skill's dynamic context

Open `courses/course-09-skills-cli-integration/skill/github-release-notes/SKILL.md` and study the Context section. Four `!`command`` calls run before Claude sees the prompt:

```
Latest tag: !`git describe --tags --abbrev=0 2>/dev/null || echo "no-tags-found"`
```

This command:
1. `git describe --tags --abbrev=0` -- finds the most recent tag
2. `2>/dev/null` -- suppresses stderr (no tag warnings)
3. `|| echo "no-tags-found"` -- if the command fails, outputs a sentinel string

The skill's Step 1 ("Validate prerequisites") checks for this sentinel and tells the user what to do. This is the defensive preprocessing pattern: every command produces useful output even on failure.

### Step 2: Study the reference files

Open the two reference files:

**`references/pr-categories.md`** defines classification rules with a clear priority order:
- Breaking > Security > Feature/Fix > Docs > Chores
- Uses signals from PR titles (conventional commit prefixes), labels, and body text
- Handles ambiguous cases (PR touches both feature and fix code)

**`references/changelog-conventions.md`** codifies the Keep a Changelog format:
- Section ordering (Added, Changed, Deprecated, Removed, Fixed, Security)
- Entry format (past tense, PR reference, user-impact focus)
- Good vs bad entry examples

These reference files are why skills produce better output than raw prompts. A prompt like "generate release notes from these PRs" works, but it produces inconsistent formatting. The skill embeds your team's specific conventions.

### Step 3: Study the output template

Open `assets/release-template.md`. It defines the exact structure Claude should produce, with placeholder instructions for each field. The skill's Step 4 points Claude to this template.

This is the pattern from Course 3 (Full Skill Anatomy): SKILL.md stays focused on the workflow, reference files carry the domain expertise, and asset files define the output format.

### Step 4: Install the skill

Copy the skill to your personal skills directory:

```bash
cp -r courses/course-09-skills-cli-integration/skill/github-release-notes ~/.claude/skills/github-release-notes
```

Verify the structure:

```bash
ls -R ~/.claude/skills/github-release-notes/
```

You should see:

```
SKILL.md
assets/
references/

assets:
release-template.md

references:
changelog-conventions.md
pr-categories.md
```

### Step 5: Test the skill against a real repo

Navigate to a repository that has git tags and merged PRs. If you don't have one handy, you can test against any open-source project you've cloned:

```
/github-release-notes
```

Watch for:
1. The dynamic context commands preprocess -- you should see actual data, not the `!`command`` placeholders
2. PRs are categorized into Added/Changed/Fixed/Security headings
3. The output follows the changelog conventions (past tense, PR references)
4. A comparison link appears at the bottom
5. If a version argument was provided, it uses that; otherwise, it suggests one

### Step 6: Test error handling

Test the skill's error paths:

**No tags**: In a repo with no tags, verify the skill detects "no-tags-found" and offers alternatives.

**No GitHub remote**: In a local-only repo (no `origin` pointing to GitHub), verify the skill detects "unknown" repo and tells you to add a remote.

**No staged PRs**: In a repo where the latest tag is very recent (no PRs since), verify the skill handles an empty PR list gracefully.

### Step 7: Study the wrapper script

Open `courses/course-09-skills-cli-integration/scripts/dx-review.sh`. This script follows the non-interactive wrapper pattern:

```
1. Capture CLI output    → git diff --cached
2. Check for edge cases  → empty diff → exit with help message
3. Construct prompt      → review instructions + diff content
4. Run AI one-shot       → claude -p "$PROMPT"
```

Key implementation details:

- `set -e` at the top: the script exits on any error
- `$DIFF` check: handles the "no staged changes" edge case with a helpful message
- `$STAT` and `$FILE_COUNT`: displayed to the user before the review starts (so they see what's being reviewed)
- `--skill` flag: switches from a raw prompt to invoking the `/code-review-checklist` skill

### Step 8: Test the wrapper script

Stage some changes in any git repo:

```bash
# Make a change
echo "// TODO: clean this up" >> some-file.js
git add some-file.js

# Run the review
bash courses/course-09-skills-cli-integration/scripts/dx-review.sh
```

You should see:
1. The file count and diff stat printed
2. Claude's review output (from the raw prompt)

Test the edge case:

```bash
git reset HEAD some-file.js   # Unstage
bash courses/course-09-skills-cli-integration/scripts/dx-review.sh
```

You should see the "No staged changes" message with instructions.

### Step 9: Compare raw prompt vs skill

Run the review both ways:

```bash
# Stage changes first
git add some-file.js

# Raw prompt (default)
bash courses/course-09-skills-cli-integration/scripts/dx-review.sh

# With the skill
bash courses/course-09-skills-cli-integration/scripts/dx-review.sh --skill
```

Compare the outputs. The skill version (using `code-review-checklist` from Course 2) should produce a more structured review with explicit dimensions: correctness, readability, performance, security, testing, and a verdict. The raw prompt version is functional but less consistent.

This demonstrates why the wrapper-script-invoking-a-skill pattern produces the best results: the wrapper handles CLI mechanics (capturing the diff, checking edge cases), and the skill provides the structured review methodology.

## Exercises

1. **Build and test the github-release-notes skill against a real repo**. Install the skill as described in Step 4. Navigate to a repo with tags and merged PRs. Run `/github-release-notes` and verify:
   - PRs are categorized correctly (check against the PR titles/labels)
   - The changelog follows Keep a Changelog format
   - A comparison link is generated
   - Test error paths: no tags, no remote, no recent PRs

2. **Build and test the `dx-review.sh` wrapper script**. Stage some changes in a test repo, run the script, and verify it produces a code review. Test the edge case of no staged changes. Then install the script somewhere on your PATH:
   ```bash
   cp courses/course-09-skills-cli-integration/scripts/dx-review.sh ~/.local/bin/dx-review
   chmod +x ~/.local/bin/dx-review
   ```
   Now you can run `dx-review` from any git repo.

3. **Connect the two: raw prompt vs skill**. Run `dx-review.sh` with and without the `--skill` flag against the same staged changes. Compare:
   - Which produces more structured output?
   - Which covers more review dimensions?
   - Which is more consistent across runs?
   The skill version leverages Course 2's structured review dimensions. This is the power of wrapper scripts invoking skills.

4. **Build a `dx-standup` wrapper**. Create a new wrapper script at `scripts/dx-standup.sh` that:
   - Captures `git log --author="$(git config user.email)" --since="yesterday" --oneline`
   - Constructs a standup prompt
   - Runs `claude -p` in non-interactive mode
   - Bonus: add a `--skill` flag that invokes the `/daily-standup` skill from Course 1

5. **Add an interactive mode**. Create a variant of `dx-review.sh` that uses tmux interactive mode (Mode 2 from the Concepts section). Instead of `claude -p`, launch Claude in a tmux session with the diff pre-loaded, so you can ask follow-up questions about the review. Hint:
   ```bash
   tmux new-session -d -s dx-review
   tmux send-keys -t dx-review "claude" Enter
   sleep 2
   tmux send-keys -t dx-review "$PROMPT" Enter
   tmux attach -t dx-review
   ```

6. **Extend the release notes skill**. Add a new dynamic context command to `github-release-notes/SKILL.md` that fetches the GitHub milestone associated with the latest tag:
   ```
   Milestone: !`gh api repos/{owner}/{repo}/milestones --jq '.[] | select(.title == "TAG") | .description' 2>/dev/null || echo "no-milestone"`
   ```
   Update the skill instructions to include the milestone description in the release summary.

## Verification Checklist

- [ ] `~/.claude/skills/github-release-notes/SKILL.md` exists with valid YAML frontmatter
- [ ] `name` field is `github-release-notes` (kebab-case, matches folder)
- [ ] `description` follows the `[What] + [When] + [Capabilities]` formula
- [ ] `disable-model-invocation: true` is set (user-controlled invocation)
- [ ] `argument-hint: "[version-tag]"` is set
- [ ] No XML angle brackets in frontmatter
- [ ] SKILL.md is under 500 lines
- [ ] SKILL.md references all three supporting files with "when to consult" guidance
- [ ] Four `!`command`` dynamic context calls are present with defensive `|| echo` fallbacks
- [ ] `references/changelog-conventions.md` exists with Keep a Changelog format rules
- [ ] `references/pr-categories.md` exists with classification rules and priority ordering
- [ ] `assets/release-template.md` exists with placeholder instructions
- [ ] Running `/github-release-notes` in a repo with tags produces categorized release notes
- [ ] Error handling works: no-tags, no-remote, and no-recent-PRs cases produce helpful messages
- [ ] `scripts/dx-review.sh` is executable and runs correctly with staged changes
- [ ] `scripts/dx-review.sh` handles the no-staged-changes edge case gracefully
- [ ] `scripts/dx-review.sh --skill` invokes the `/code-review-checklist` skill and produces structured output
- [ ] The raw-prompt and skill versions produce noticeably different (skill is better) output

## What's Next

In **Course 10: Agent Teams -- Orchestrating Parallel Work**, you'll learn:
- What agent teams are: multiple Claude Code instances with shared tasks and messaging
- When to use teams vs subagents
- Team architecture: lead agent, teammates, shared task list, mailbox messaging
- The tmux orchestration layer: control sessions, dashboards, and synchronized status checks
- You'll build monitoring scripts and run a parallel code review with three specialized reviewers

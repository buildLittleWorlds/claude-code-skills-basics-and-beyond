# Course 3: Full Skill Anatomy -- Scripts, References, and Assets
**Level**: Beginner-Intermediate | **Estimated time**: 35 min

## Prerequisites
- Completed **Course 1: Your First Skill in Five Minutes** (skill folder basics, YAML frontmatter, naming rules)
- Completed **Course 2: Crafting Descriptions and Trigger Phrases** (description formula, progressive disclosure L1/L2, specific instructions)
- You understand the three-level progressive disclosure model (frontmatter, body, linked files)
- You have the `daily-standup` and `code-review-checklist` skills installed

## Concepts

### The Complete Skill Folder Structure

In Courses 1 and 2, your skills were single files -- a folder with only `SKILL.md`. That's enough for simple skills, but real-world workflows often need more: validation scripts, reference documentation, output templates.

The PDF guide (Chapter 1, p.10) lays out the full structure:

```
your-skill-name/
├── SKILL.md                    # Required - main skill file
├── scripts/                    # Optional - executable code
│   ├── process_data.py
│   └── validate.sh
├── references/                 # Optional - documentation loaded as needed
│   ├── api-guide.md
│   └── examples/
└── assets/                     # Optional - templates, fonts, icons
    └── report-template.md
```

Each directory serves a specific purpose:

| Directory | Purpose | When Claude loads it |
|---|---|---|
| `scripts/` | Executable code (Python, Bash, etc.) that Claude runs during the workflow | When SKILL.md tells Claude to run a script |
| `references/` | Documentation, guides, domain knowledge that Claude reads for context | When Claude needs additional information referenced in SKILL.md |
| `assets/` | Templates, output formats, static files Claude uses to shape output | When Claude needs a template to fill in or a format to follow |

The skills docs confirm this structure with the same layout:

```
my-skill/
├── SKILL.md           # Main instructions (required)
├── template.md        # Template for Claude to fill in
├── examples/
│   └── sample.md      # Example output showing expected format
└── scripts/
    └── validate.sh    # Script Claude can execute
```

### Progressive Disclosure Level 3: Linked Files

In Course 1, you learned the three levels of progressive disclosure. Courses 1 and 2 focused on Levels 1 and 2. Now it's time for Level 3.

From the PDF guide (Chapter 1, p.5):

> **Third level (Linked files):** Additional files bundled within the skill directory that Claude can choose to navigate and discover only as needed.

This is the key architectural insight for building complex skills. Instead of cramming everything into SKILL.md (which would bloat every invocation with unnecessary tokens), you link to supporting files and let Claude load them only when relevant.

The skills docs explain the rationale:

> Skills can include multiple files in their directory. This keeps SKILL.md focused on the essentials while letting Claude access detailed reference material only when needed. Large reference docs, API specifications, or example collections don't need to load into context every time the skill runs.

### Referencing Supporting Files from SKILL.md

Claude won't discover files in your skill directory unless you tell it they exist. The skills docs provide the pattern:

```markdown
## Additional resources

- For complete API details, see [reference.md](reference.md)
- For usage examples, see [examples.md](examples.md)
```

This is a simple but critical pattern. Each reference should tell Claude:
1. **What** the file contains (so Claude can decide whether to load it)
2. **When** to consult it (so Claude doesn't load everything by default)

Here's a more concrete example from a real skill:

```markdown
## References

- Before writing queries, consult `references/api-patterns.md` for:
  - Rate limiting guidance
  - Pagination patterns
  - Error codes and handling
```

This tells Claude what's in the file *and* when to read it ("before writing queries"). Claude can skip the reference entirely if the current task doesn't involve queries.

### Keeping SKILL.md Under 500 Lines

The skills docs give a clear guideline:

> Keep SKILL.md under 500 lines. Move detailed reference material to separate files.

This matters for two reasons from the PDF's troubleshooting section (Chapter 5, p.27):

1. **Large context issues**: "Skill content too large" causes slow or degraded responses
2. **Instructions not followed**: When instructions are too verbose, Claude may ignore parts. The fix is: "Keep instructions concise. Use bullet points and numbered lists. Move detailed reference to separate files."

The solution from the troubleshooting guide:

> **Optimize SKILL.md size**: Move detailed docs to references/. Link to references instead of inline. Keep SKILL.md under 5,000 words.

Your SKILL.md should contain:
- Core workflow steps (the "what to do" sequence)
- Pointers to references (the "where to learn more")
- Error handling for common cases

Everything else goes into `references/` or `assets/`.

### Running Scripts from Within a Skill

The PDF guide's Iterative Refinement pattern (Chapter 5, p.23) shows how scripts integrate into a skill workflow:

```
### Quality Check
1. Run validation script: `scripts/check_report.py`
2. Identify issues:
   - Missing sections
   - Inconsistent formatting
   - Data validation errors

### Refinement Loop
1. Address each identified issue
2. Regenerate affected sections
3. Re-validate
4. Repeat until quality threshold met
```

The key insight: scripts provide **deterministic validation** that doesn't depend on Claude's judgment. As the PDF notes (Chapter 5, p.26):

> For critical validations, consider bundling a script that performs the checks programmatically rather than relying on language instructions. Code is deterministic; language interpretation isn't.

This is why the `meeting-to-actions` skill you'll build includes a Python validation script -- rather than asking Claude to "make sure every action item has an owner", the script checks programmatically and reports exactly what's missing.

### The `compatibility` Frontmatter Field

The PDF guide (Chapter 1, p.11) describes an optional frontmatter field for specifying environment requirements:

> **compatibility** (optional): 1-500 characters. Indicates environment requirements: e.g. intended product, required system packages, network access needs, etc.

From the PDF's Reference B section:

```yaml
name: skill-name
description: [required description]
license: MIT
allowed-tools: "Bash(python:*) Bash(npm:*) WebFetch"
metadata:
  author: Company Name
  version: 1.0.0
  mcp-server: server-name
  category: productivity
  tags: [project-management, automation]
```

Use `compatibility` when your skill requires specific tools to be available. For the meeting-to-actions skill, we'll note it requires Python 3, since the validation script is written in Python.

### The `metadata` Frontmatter Field

The PDF guide (Chapter 1, p.11) also describes `metadata`:

> **metadata** (optional): Any custom key-value pairs. Suggested: author, version, mcp-server.

This is useful for tracking versions and authorship as skills evolve. When you distribute a skill to a team, the metadata helps users know which version they're running and who to contact for issues.

## Key References
- PDF Guide: Chapter 1 "Fundamentals" (p.5) -- Three-level progressive disclosure, linked files
- PDF Guide: Chapter 1 "Technical Requirements" (p.10) -- File structure diagram, compatibility field
- PDF Guide: Chapter 5 "Patterns" (p.23) -- Iterative refinement pattern with scripts
- PDF Guide: Chapter 5 "Troubleshooting" (pp.26-27) -- Large context issues, SKILL.md sizing
- Skills docs: "Add supporting files" section -- File layout, referencing pattern
- Skills docs: "Frontmatter reference" section -- All optional fields

## What You're Building

A **meeting-to-actions** skill that extracts action items from meeting notes, validates them with a script, and classifies them by urgency. This demonstrates Course 3 concepts because:

- It uses **all four directories**: SKILL.md + `scripts/` + `references/` + `assets/`
- The `scripts/validate_actions.py` script provides **deterministic validation** -- checking that every action item has an owner and deadline without relying on Claude's judgment
- The `references/prioritization-guide.md` contains **domain knowledge** (Eisenhower matrix) that Claude consults only when classifying urgency -- not loaded by default
- The `assets/action-template.md` provides an **output template** that ensures consistent formatting across invocations
- SKILL.md stays **focused and concise** -- the workflow steps, with pointers to supporting files

Here's how the pieces fit together:

```
meeting-to-actions/
├── SKILL.md                          # Workflow: extract -> validate -> classify -> format
├── scripts/
│   └── validate_actions.py           # Checks: owner + deadline on every item
├── references/
│   └── prioritization-guide.md       # Eisenhower matrix for urgency classification
└── assets/
    └── action-template.md            # Output format template
```

## Walkthrough

### Step 1: Understand the directory structure

Each file in the skill has a clear responsibility:

| File | Role | When loaded |
|---|---|---|
| `SKILL.md` | Orchestrates the 4-step workflow | When skill is invoked (Level 2) |
| `scripts/validate_actions.py` | Validates each action has owner + deadline | When Step 2 runs the script |
| `references/prioritization-guide.md` | Eisenhower matrix classification rules | When Step 3 needs urgency criteria |
| `assets/action-template.md` | Markdown template for final output | When Step 4 formats the results |

### Step 2: Study the SKILL.md

Open `courses/course-03-full-anatomy/skill/meeting-to-actions/SKILL.md` and notice:

1. **Frontmatter**: Uses the description formula from Course 2, plus `compatibility` and `metadata`
2. **Workflow steps**: Four clear numbered steps -- extract, validate, classify, format
3. **Script invocation**: Step 2 tells Claude exactly what command to run and what the output means
4. **Reference links**: Step 3 points to `references/prioritization-guide.md` with a clear "when to consult" instruction
5. **Asset usage**: Step 4 points to `assets/action-template.md` for the output format
6. **Troubleshooting**: Common issues with specific fixes

The body is well under 500 lines because the classification rules and template are in separate files.

### Step 3: Study the validation script

Open `courses/course-03-full-anatomy/skill/meeting-to-actions/scripts/validate_actions.py` and notice:

- It reads JSON from stdin (Claude pipes action items to it)
- It checks each item for required fields: `owner` and `deadline`
- It validates deadline format (YYYY-MM-DD)
- It outputs clear, structured results that Claude can parse
- It exits with code 0 (all valid) or 1 (issues found) -- Claude can branch on this

This is the "deterministic validation" pattern from the PDF. Instead of asking Claude "does every item have an owner?", the script checks and returns a precise answer.

### Step 4: Study the reference guide

Open `courses/course-03-full-anatomy/skill/meeting-to-actions/references/prioritization-guide.md`. This contains the Eisenhower matrix classification rules -- domain knowledge Claude consults only during the classification step.

Notice that SKILL.md doesn't inline these rules. Instead, it says: "Consult `references/prioritization-guide.md` for the classification criteria." This keeps SKILL.md focused on the workflow while making the classification rules available when needed.

### Step 5: Study the asset template

Open `courses/course-03-full-anatomy/skill/meeting-to-actions/assets/action-template.md`. This is the output format Claude fills in at Step 4.

Templates serve two purposes:
1. **Consistency**: Every invocation produces the same structure
2. **Completeness**: The template reminds Claude to include all required sections

### Step 6: Install and test

Copy the skill to your personal skills directory:

```bash
cp -r courses/course-03-full-anatomy/skill/meeting-to-actions ~/.claude/skills/meeting-to-actions
```

Verify the structure:

```bash
ls -R ~/.claude/skills/meeting-to-actions/
```

You should see:
```
SKILL.md
assets/
references/
scripts/

assets:
action-template.md

references:
prioritization-guide.md

scripts:
validate_actions.py
```

Make the script executable:

```bash
chmod +x ~/.claude/skills/meeting-to-actions/scripts/validate_actions.py
```

### Step 7: Test with sample meeting notes

Open Claude Code and paste sample meeting notes:

```
Extract action items from these meeting notes:

Sprint Planning - Feb 10
Attendees: Sarah, Mike, Alex, Jordan

Sarah presented the Q1 roadmap. We agreed to prioritize the auth
refactor over the dashboard redesign.

Mike will migrate the user service to the new API by Feb 21.
Alex needs to fix the payment timeout bug before the release on Friday.
Sarah volunteered to write the technical spec for the notification
system - no hard deadline but ideally by end of month.
Jordan will set up the staging environment for the new auth flow
by next Wednesday.

We also discussed the flaky test suite but didn't assign anyone yet.
The team agreed we need to address it soon.

Next meeting: Feb 17
```

Watch for:
1. Claude extracts action items from the prose
2. Claude runs `validate_actions.py` to check each item
3. Claude consults the prioritization guide to classify urgency
4. Claude formats output using the action template

### Step 8: Test with missing data

Try meeting notes where some action items are vague:

```
Extract actions from this meeting:

Quick sync - Feb 11
Someone should update the docs.
We need to look into the performance issue.
Bob will handle the deployment.
```

The validation script should flag issues:
- "Update the docs" has no owner and no deadline
- "Performance issue" has no owner and no deadline
- "Bob will handle the deployment" has no deadline

Claude should report these validation failures and either ask you for clarification or make reasonable suggestions.

## Exercises

1. **Add a new reference file**: Create `references/meeting-formats.md` that describes common meeting types (standup, sprint planning, retro, 1-on-1) and what kinds of action items to expect from each. Update SKILL.md to point to it with instructions like "If the meeting type is identifiable, consult `references/meeting-formats.md` for extraction heuristics." Test with different meeting types.

2. **Add a second script**: Create `scripts/export_actions.py` that takes the validated action items (JSON from stdin) and outputs them in CSV format (owner, action, deadline, priority). Update SKILL.md to add a Step 5: "If the user requests CSV export, run `python scripts/export_actions.py`." Test by asking Claude to export the action items as CSV.

3. **Test the 500-line principle**: Open SKILL.md and count its lines. Now imagine inlining the entire prioritization guide and the template. How many lines would that be? Compare the two versions -- the linked version stays focused on workflow, while the inlined version buries the steps in reference material.

4. **Build a stripped-down skill**: Create a `quick-actions` skill at `~/.claude/skills/quick-actions/SKILL.md` that does the same extraction but with NO supporting files -- everything in SKILL.md. Compare the experience: how does output consistency compare? How does Claude's behavior differ when classification rules are inline vs in a reference? This demonstrates why the multi-file pattern exists.

5. **Modify the validation script**: Add a new validation check to `validate_actions.py` that flags action items with deadlines in the past. Test with meeting notes that include expired deadlines. This demonstrates how script changes improve skill quality without touching SKILL.md.

## Verification Checklist

- [ ] `~/.claude/skills/meeting-to-actions/SKILL.md` exists with correct casing
- [ ] `~/.claude/skills/meeting-to-actions/scripts/validate_actions.py` exists and is executable
- [ ] `~/.claude/skills/meeting-to-actions/references/prioritization-guide.md` exists
- [ ] `~/.claude/skills/meeting-to-actions/assets/action-template.md` exists
- [ ] YAML frontmatter has valid `---` delimiters
- [ ] `name` field is `meeting-to-actions` (kebab-case, matches folder)
- [ ] `description` follows `[What] + [When] + [Capabilities]` formula
- [ ] No XML angle brackets in frontmatter
- [ ] `compatibility` field mentions Python 3 requirement
- [ ] SKILL.md references all three supporting files with clear "when to consult" instructions
- [ ] SKILL.md is well under 500 lines
- [ ] Pasting meeting notes triggers the skill automatically
- [ ] Running `/meeting-to-actions` invokes the skill directly
- [ ] Claude runs `validate_actions.py` during the workflow
- [ ] Claude consults the prioritization guide for classification
- [ ] Output follows the action template format
- [ ] Action items with missing owners or deadlines are flagged by the script
- [ ] The skill appears when you ask "What skills are available?"

## What's Next

In **Course 4: Testing, Iteration, and the Feedback Loop**, you'll learn:
- The three testing areas: triggering tests, functional tests, performance comparison
- How to design "should trigger" and "should NOT trigger" test suites
- Diagnosing under-triggering vs over-triggering with iteration
- Performance baselines: message count, token usage, failed tool calls
- The `disable-model-invocation: true` field for manual-only skills
- You'll build a `pr-description` skill with a comprehensive test plan of 15+ queries

# Course 6: Multi-Step Workflows with Error Handling
**Level**: Intermediate | **Estimated time**: 45 min

## Prerequisites

- **Course 1**: Skill structure basics (SKILL.md, frontmatter, installation locations)
- **Course 2**: Description formula (`[What] + [When] + [Capabilities]`), reference vs task content
- **Course 3**: Supporting files (scripts/, references/, assets/), progressive disclosure Level 3
- **Course 4**: Testing methodology (triggering, functional, performance tests), iteration signals
- **Course 5**: `$ARGUMENTS`, dynamic context (`!`command``), `context: fork`, `allowed-tools`

You should be comfortable building skills with supporting files and running validation scripts. This course focuses on *orchestrating multi-step processes* where steps depend on each other and errors must be handled gracefully.

## Concepts

### Pattern 1: Sequential Workflow Orchestration

The PDF guide (Chapter 5, p.22) identifies this as the first major skill pattern:

> **Use when:** Your users need multi-step processes in a specific order.

The PDF provides this example structure:

```
## Workflow: Onboard New Customer

### Step 1: Create Account
Call MCP tool: `create_customer`
Parameters: name, email, company

### Step 2: Setup Payment
Call MCP tool: `setup_payment_method`
Wait for: payment method verification

### Step 3: Create Subscription
Call MCP tool: `create_subscription`
Parameters: plan_id, customer_id (from Step 1)

### Step 4: Send Welcome Email
Call MCP tool: `send_email`
Template: welcome_email_template
```

The key techniques the PDF calls out are:

- **Explicit step ordering** -- each step is numbered and named
- **Dependencies between steps** -- Step 3 uses `customer_id (from Step 1)`
- **Validation at each stage** -- Step 2 has an explicit `Wait for: payment method verification`
- **Rollback instructions for failures** -- what to do if Step 3 fails after Step 1 succeeded

This differs from Course 3's `meeting-to-actions` skill, which also had numbered steps. The distinction is that *sequential workflow orchestration* explicitly encodes dependencies and validation gates between steps, not just order. In Course 3, each step was relatively independent -- if classification failed, you could still produce output. In a sequential workflow, if Step 1 fails, Step 2 cannot proceed.

### Pattern 3: Iterative Refinement

The PDF (Chapter 5, p.23) describes this second pattern we'll use:

> **Use when:** Output quality improves with iteration.

The PDF's example for iterative report generation:

```
## Iterative Report Creation

### Initial Draft
1. Fetch data via MCP
2. Generate first draft report
3. Save to temporary file

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

### Finalization
1. Apply final formatting
2. Generate summary
3. Save final version
```

The key techniques:

- **Explicit quality criteria** -- the validation script defines what "good" means
- **Iterative improvement** -- a structured loop, not open-ended revision
- **Validation scripts** -- deterministic checks, not subjective judgment
- **Know when to stop iterating** -- "repeat until quality threshold met" prevents infinite loops

### Combining Both Patterns

The most powerful skills combine sequential orchestration with iterative refinement. Your workflow proceeds step-by-step (Pattern 1), and at validation checkpoints, you loop until quality criteria are met (Pattern 3) before advancing to the next step.

```
Step 1: Gather requirements
Step 2: Generate structure
Step 3: Create files
Step 4: Validate          ─┐
Step 5: Refine             │  (iterative loop)
        └── Re-validate  ──┘
Step 6: Summarize
```

This is exactly what our `project-scaffolder` skill does.

### Validation Gates

A validation gate is a checkpoint between workflow steps. The rule is simple: **proceed only if the previous step produced valid output.** But the implementation details matter.

**Specific diagnostics vs. generic failures:**

| Bad (generic)                        | Good (specific)                                                  |
|--------------------------------------|------------------------------------------------------------------|
| "Validation failed"                  | "Missing pyproject.toml in project root"                         |
| "Error in project structure"         | "tests/ directory exists but contains no test files"             |
| "Fix the issues and try again"       | "src/__init__.py is empty -- add package docstring and version"  |
| "Something went wrong"              | "Expected 'python-api' or 'node-api' but got 'ruby-api'"        |

The PDF emphasizes this in Pattern 1's key techniques: validation at each stage should produce actionable output that tells Claude *exactly* what to fix. This is critical because Claude uses the validation output to decide what to do next. If the output says "validation failed," Claude doesn't know what to fix. If it says "missing pyproject.toml in project root," Claude knows exactly what to create.

In Course 3, we built `validate_actions.py` which checked individual fields and reported specific issues. In this course, we'll build `validate_structure.py` which checks an entire file tree against a template and reports every discrepancy.

### Error Handling in Multi-Step Workflows

When a workflow spans multiple steps, errors become more complex. You need to handle:

1. **Step failure** -- a step can't complete (e.g., validation script not found)
2. **Partial output** -- a step produces incomplete results (e.g., some files created but not all)
3. **Refinement exhaustion** -- the iterative loop doesn't converge after N attempts

For each, your skill should provide specific guidance:

```markdown
### If validation fails:
1. Read the validation output carefully -- it lists every missing or incorrect item
2. Fix ONLY the items listed as issues (do not regenerate files that passed)
3. Re-run validation
4. If validation fails a second time on the SAME issues, stop and report
   the persistent problems to the user
```

Notice the three principles at work:
- **Specific**: "fix ONLY the items listed" not "fix the issues"
- **Bounded**: "if validation fails a second time on the SAME issues, stop" prevents infinite loops
- **Transparent**: "report the persistent problems to the user" keeps the human informed

### The `allowed-tools` Field for Workflow Safety

From the skills docs, `allowed-tools` limits which tools Claude can use when a skill is active. In multi-step workflows, this provides a safety boundary:

```yaml
allowed-tools: Bash(python *), Read, Write, Edit, Glob
```

This means Claude can:
- Run Python scripts (for validation)
- Read existing files (for verification)
- Write and edit files (for scaffolding)
- Search with Glob (for structure checking)

But Claude *cannot*:
- Run arbitrary bash commands (no `rm -rf`, no `curl`)
- Use `Grep` (not needed for scaffolding)

For workflow skills that create files, restricting tools prevents Claude from accidentally running destructive commands during the generate-validate-refine loop. This is especially important because the iterative refinement loop means Claude is taking multiple autonomous actions without user confirmation at each step.

### Problem-First vs. Tool-First Design

The PDF (Chapter 5, p.22) introduces an important design distinction:

> **Problem-first:** "I need to set up a project workspace" -- Your skill orchestrates the right calls in the right sequence. Users describe outcomes; the skill handles the tools.

> **Tool-first:** "I have Notion MCP connected" -- Your skill teaches Claude the optimal workflows and best practices. Users have access; the skill provides expertise.

Our `project-scaffolder` is a *problem-first* skill. Users say "scaffold a new project" and the skill handles the multi-step orchestration. This framing helps you decide what goes in the skill:

- Problem-first skills need **explicit steps**, **validation gates**, and **error handling** (because you're orchestrating)
- Tool-first skills need **best practices**, **examples**, and **domain knowledge** (because you're advising)

## Key References

- **PDF Guide Chapter 5** (pp.21-24): Pattern 1 (Sequential Workflow Orchestration), Pattern 3 (Iterative Refinement), problem-first vs tool-first design
- **Skills docs, "Types of skill content"**: Reference content vs task content, when to use `disable-model-invocation: true`
- **Skills docs, "Restrict tool access"**: The `allowed-tools` field for limiting Claude's tools during skill execution

## What You're Building

A `project-scaffolder` skill that demonstrates both Pattern 1 and Pattern 3 in a single workflow. When invoked, it:

1. **Gathers requirements** from the user (project name, template type)
2. **Generates the directory structure** based on a template
3. **Creates all files** with appropriate starter content
4. **Validates the structure** using a Python script that checks every expected file
5. **Refines** any issues found by the validator (iterative loop)
6. **Summarizes** what was created

The skill includes:

| Component | Purpose |
|-----------|---------|
| `SKILL.md` | 6-step orchestrated workflow with validation gates and refinement loop |
| `scripts/validate_structure.py` | Deterministic validation -- checks file tree against template expectations |
| `assets/templates/python-api/` | Template files for a Python API project (pyproject.toml, src/, tests/) |
| `assets/templates/node-api/` | Template files for a Node.js API project (package.json, src/, tests/) |

This is more complex than any skill we've built so far. It combines concepts from every previous course:
- YAML frontmatter and description formula (Course 1-2)
- Supporting files with scripts, references, assets (Course 3)
- Validation-driven iteration (Course 4)
- Arguments and tool restrictions (Course 5)
- Sequential orchestration + iterative refinement (this course)

## Walkthrough

### Step 1: Understand the Skill Structure

Look at the complete file tree:

```
project-scaffolder/
├── SKILL.md
├── scripts/
│   └── validate_structure.py
└── assets/
    └── templates/
        ├── python-api/
        │   ├── pyproject.toml
        │   ├── README.md
        │   ├── src/
        │   │   └── __init__.py
        │   └── tests/
        │       └── test_placeholder.py
        └── node-api/
            ├── package.json
            ├── README.md
            ├── src/
            │   └── index.ts
            └── tests/
                └── index.test.ts
```

Each template directory contains the *expected* structure for a project. The validation script compares the scaffolded project against the template to verify completeness.

### Step 2: Read the SKILL.md

Open `skill/project-scaffolder/SKILL.md` and notice how the workflow is structured:

**Frontmatter:**
```yaml
---
name: project-scaffolder
description: >-
  Scaffolds a new project from a template with validation.
  Use when the user says "scaffold a project", "create a new project",
  "set up a python project", or "initialize a node project".
  Supports python-api and node-api templates with full structure validation.
disable-model-invocation: true
allowed-tools: Bash(python *), Read, Write, Edit, Glob
argument-hint: "[project-name] [template: python-api|node-api]"
---
```

Notice:
- `disable-model-invocation: true` -- this is a task-content skill with side effects (creates files). You don't want Claude deciding to scaffold a project without being asked.
- `allowed-tools` restricts Claude to file operations and Python scripts. No arbitrary bash.
- `argument-hint` tells users the expected arguments in autocomplete.
- The description follows the `[What] + [When] + [Capabilities]` formula from Course 2.

**Workflow body** has 6 numbered steps, each with:
- Clear instructions for what to do
- Success criteria (what must be true before proceeding)
- Failure handling (what to do if the step fails)

### Step 3: Read the Validation Script

Open `scripts/validate_structure.py`. This is the heart of the validation gate.

The script takes two arguments:
```bash
python scripts/validate_structure.py <project-directory> <template-name>
```

It compares the actual project directory against the expected template structure and reports:
- Missing files or directories
- Empty files that should have content
- Extra files that aren't in the template (as informational warnings, not errors)

The output is structured JSON:
```json
{
  "valid": false,
  "project_dir": "/path/to/my-project",
  "template": "python-api",
  "errors": [
    "MISSING: pyproject.toml",
    "EMPTY: src/__init__.py (expected content)"
  ],
  "warnings": [
    "EXTRA: .gitignore (not in template, keeping)"
  ],
  "summary": "2 errors, 1 warning"
}
```

This structured output is what makes the refinement loop work. Claude reads the `errors` array and knows exactly what to fix. Compare this with a generic "validation failed" message -- Claude would have no idea what to do next.

### Step 4: Examine the Templates

Look at `assets/templates/python-api/pyproject.toml`:

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.backends"

[project]
name = "{{PROJECT_NAME}}"
version = "0.1.0"
description = "{{PROJECT_DESCRIPTION}}"
requires-python = ">=3.10"
dependencies = []

[project.optional-dependencies]
dev = ["pytest>=7.0", "ruff>=0.1.0"]
```

The `{{PROJECT_NAME}}` and `{{PROJECT_DESCRIPTION}}` placeholders are replaced by Claude during scaffolding. These aren't processed by a template engine -- they're markers that tell Claude what to substitute. This is a key pattern: **use simple placeholders that Claude can understand and replace**, not complex templating syntax.

### Step 5: Install and Test

Copy the skill to your personal skills directory:

```bash
cp -r skill/project-scaffolder ~/.claude/skills/project-scaffolder
```

Start a Claude Code session and test the full workflow:

```
/project-scaffolder my-service python-api
```

Watch for the 6-step workflow:
1. Claude reads your arguments and identifies the template
2. Claude reads the template files from the assets directory
3. Claude creates the project directory and all files
4. Claude runs `validate_structure.py` to check the result
5. If validation finds issues, Claude fixes them and re-validates
6. Claude prints a summary of everything created

### Step 6: Test the Refinement Loop

To see the iterative refinement in action, you need to trigger a validation failure. After scaffolding completes, manually break the project:

```bash
rm my-service/pyproject.toml
```

Then ask Claude to re-validate:

```
Can you validate the my-service project structure?
```

Claude should run the validation script, detect the missing file, and offer to fix it. This demonstrates the draft-validate-fix-re-validate loop from Pattern 3.

## Exercises

### Exercise 1: Trace the Dependency Chain

Read through the SKILL.md and identify every point where one step depends on output from a previous step. Write down each dependency:

- Step 2 depends on Step 1 because: ___
- Step 3 depends on Step 2 because: ___
- Step 4 depends on Step 3 because: ___
- Step 5 depends on Step 4 because: ___

*Expected:* You should find 4 dependencies. Each step uses specific output (project name, template choice, file list, validation results) from the preceding step.

### Exercise 2: Add a New Template

Create a new template at `assets/templates/fastapi-app/` with these files:
- `pyproject.toml` (with fastapi and uvicorn as dependencies)
- `src/main.py` (FastAPI app with a health endpoint)
- `src/routes/__init__.py` (empty)
- `tests/test_main.py` (test for the health endpoint)
- `README.md`

Then update `validate_structure.py` to recognize the new template. Test it:

```
/project-scaffolder my-api fastapi-app
```

*Success criteria:* The validation script should pass on the first try if Claude used your template correctly.

### Exercise 3: Improve Error Specificity

Modify `validate_structure.py` to also check file *content* for the python-api template. Specifically:
- `pyproject.toml` must contain a `[project]` section
- `src/__init__.py` must define `__version__`
- `tests/test_placeholder.py` must import `pytest`

Run the scaffolder and see if the content validation catches anything.

*Success criteria:* The script should report specific content issues like `"CONTENT: src/__init__.py missing __version__ definition"`.

### Exercise 4: Build Your Own Sequential Workflow Skill

Design a skill that uses Pattern 1 for a workflow you actually do. Ideas:
- A `setup-dev-environment` skill (install deps -> configure env -> create .env -> verify)
- A `new-api-endpoint` skill (create route -> add handler -> add tests -> validate -> register)
- A `database-migration` skill (generate migration -> validate SQL -> run -> verify -> rollback plan)

Write just the SKILL.md with the workflow steps, validation gates, and error handling. You don't need to build the full supporting files -- focus on getting the workflow structure right.

*Evaluation:* Check your skill against these criteria:
- Does every step have a clear success condition?
- Are dependencies between steps explicit?
- Does validation produce specific, actionable diagnostics?
- Is the refinement loop bounded (max iterations)?

## Verification Checklist

- [ ] `skill/project-scaffolder/SKILL.md` has valid YAML frontmatter with `---` delimiters
- [ ] `name` field is `project-scaffolder` (kebab-case, matches folder)
- [ ] `description` follows `[What] + [When] + [Capabilities]` formula
- [ ] `disable-model-invocation: true` is set (task-content skill with side effects)
- [ ] `allowed-tools` restricts available tools during execution
- [ ] `argument-hint` documents expected arguments
- [ ] SKILL.md has 6 clearly numbered steps with dependencies
- [ ] Each step has a success condition and failure handling
- [ ] The refinement loop (Steps 4-5) is bounded with a max iteration count
- [ ] `scripts/validate_structure.py` is a functional Python script (not a stub)
- [ ] Running `python scripts/validate_structure.py --help` prints usage information
- [ ] Validation output is structured JSON with `errors` and `warnings` arrays
- [ ] Template files exist in both `assets/templates/python-api/` and `assets/templates/node-api/`
- [ ] Template files contain `{{PROJECT_NAME}}` placeholders, not hardcoded values
- [ ] Copying to `~/.claude/skills/project-scaffolder/` and running `/project-scaffolder test-app python-api` produces a valid project directory

## What's Next

In **Course 7: Hooks -- Deterministic Control over Claude's Behavior**, you'll learn:

- What hooks are: shell commands that run at specific lifecycle points (PreToolUse, PostToolUse, Stop)
- Matchers for filtering by tool name and session type
- Hook I/O: JSON stdin, exit codes (0 = allow, 2 = block), JSON stdout
- Three hook types: command hooks, prompt hooks, and agent hooks
- How to embed hooks in skill frontmatter for skill-scoped automation
- You'll build a `safe-deploy` skill with an embedded hook that validates bash commands before they execute

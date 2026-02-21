---
name: project-scaffolder
description: >-
  Scaffolds a new project from a template with full structure validation.
  Use when the user says "scaffold a project", "create a new project",
  "set up a python project", "initialize a node project", or "new project from template".
  Supports python-api and node-api templates with iterative validation and refinement.
disable-model-invocation: true
allowed-tools: Bash(python *), Read, Write, Edit, Glob
argument-hint: "[project-name] [template: python-api|node-api]"
---

# Project Scaffolder

Scaffold a new project from a template with validation and iterative refinement.

This workflow follows 6 sequential steps. Each step depends on the previous one.
Do not skip steps or reorder them.

## Step 1: Gather Requirements

Parse the user's arguments to determine:
- **Project name**: `$ARGUMENTS[0]` (e.g., `my-service`)
- **Template**: `$ARGUMENTS[1]` (must be `python-api` or `node-api`)

If the project name is missing, ask the user for it before proceeding.

If the template is missing or unrecognized, show the available options:
```
Available templates:
  python-api  - Python project with pyproject.toml, src/, tests/
  node-api    - Node.js project with package.json, src/, tests/
```

Ask the user to choose one. Do not guess.

Also ask the user for a short project description (one sentence). This will be used
in the generated README and config files.

**Success condition**: You have a project name, a valid template name, and a description.
**Failure handling**: If the user provides an invalid template, list valid options. Do not proceed until you have all three values.

## Step 2: Read the Template

Read the template files from the skill's assets directory:

```
~/.claude/skills/project-scaffolder/assets/templates/<template-name>/
```

Use Glob to list all files in the template directory, then Read each one. These files
contain `{{PROJECT_NAME}}` and `{{PROJECT_DESCRIPTION}}` placeholders that you will
replace with the actual values from Step 1.

Mentally map out the full directory tree you need to create. For example, for `python-api`:

```
<project-name>/
├── pyproject.toml
├── README.md
├── src/
│   └── __init__.py
└── tests/
    └── test_placeholder.py
```

**Success condition**: You have read all template files and know the complete directory structure.
**Failure handling**: If the template directory doesn't exist, report: "Template '<name>' not found at expected path. Available templates: python-api, node-api." Stop and ask the user which template to use.

## Step 3: Create the Project

Create the project directory and all files. For each template file:

1. Create the target directory path if it doesn't exist
2. Read the template file content
3. Replace `{{PROJECT_NAME}}` with the actual project name
4. Replace `{{PROJECT_DESCRIPTION}}` with the user's description
5. Write the file to the target location

Create files in the current working directory under `<project-name>/`.

Do NOT overwrite an existing directory. If `<project-name>/` already exists:
- Report: "Directory '<project-name>' already exists."
- Ask the user whether to overwrite, choose a different name, or cancel.

**Success condition**: All files from the template exist in the new project directory with placeholders replaced.
**Failure handling**: If file creation fails for any individual file, report which file failed and why. Continue creating the remaining files, then report the full list of failures at the end.

## Step 4: Validate the Structure

Run the validation script to verify the project was created correctly:

```bash
python ~/.claude/skills/project-scaffolder/scripts/validate_structure.py <project-name> <template-name>
```

The script outputs JSON with this structure:
```json
{
  "valid": true/false,
  "errors": ["list of specific issues"],
  "warnings": ["informational notes"],
  "summary": "N errors, M warnings"
}
```

**Success condition**: The `valid` field is `true` and the `errors` array is empty. Proceed to Step 6.
**Failure condition**: The `valid` field is `false`. Read the `errors` array carefully. Proceed to Step 5.

## Step 5: Refine (if validation failed)

For each error reported by the validation script:

1. Read the error message to understand exactly what is wrong
2. Fix the specific issue:
   - `MISSING: <file>` -- create the missing file using the template as reference
   - `EMPTY: <file>` -- read the template version and write appropriate content
   - `CONTENT: <file> <issue>` -- edit the file to fix the specific content problem
3. Do NOT regenerate files that passed validation

After fixing all reported issues, go back to Step 4 and re-run validation.

**Iteration limit**: If validation fails 3 times in a row, stop the refinement loop.
Report the persistent issues to the user:
```
Validation still failing after 3 attempts. Remaining issues:
- <list each remaining error>

These may require manual attention. The project has been partially created at ./<project-name>/
```

## Step 6: Summarize

After validation passes (or after reporting persistent issues), provide a summary:

```
Project '<project-name>' scaffolded successfully using '<template-name>' template.

Created files:
  <list each file with a one-line description>

Next steps:
  cd <project-name>
  <template-specific instructions>
```

For `python-api` next steps:
```
  python -m venv .venv
  source .venv/bin/activate
  pip install -e ".[dev]"
  pytest
```

For `node-api` next steps:
```
  npm install
  npm run build
  npm test
```

## Troubleshooting

### Validation script not found

If you get "No such file or directory" when running the validation script:
1. Check the script exists: `ls ~/.claude/skills/project-scaffolder/scripts/validate_structure.py`
2. Verify it's the installed copy. If running from the course directory, adjust the path.
3. Check Python is available: `python3 --version` or `python --version`

### Template directory not found

If template files can't be read:
1. Check that the skill was copied to `~/.claude/skills/project-scaffolder/` including the `assets/` directory
2. Verify template exists: `ls ~/.claude/skills/project-scaffolder/assets/templates/`
3. The `cp -r` command must have included all subdirectories

### Permission errors creating files

If file creation fails with permission errors:
1. Check you have write permission in the current directory
2. Check the target directory isn't read-only
3. Try a different output location

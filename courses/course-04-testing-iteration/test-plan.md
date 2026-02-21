# Test Plan: pr-description skill

This test plan covers 18 queries organized by the three testing areas from PDF Chapter 3.
Run each query in Claude Code, record the actual result, and compare against the expected behavior.

## How to Use This Plan

1. Install the skill: `cp -r courses/course-04-testing-iteration/skill/pr-description ~/.claude/skills/pr-description`
2. Open Claude Code in a git repository with changes
3. Run each test query below
4. Record the actual result in the "Actual" column
5. Mark each test PASS or FAIL
6. After all tests, review failures and iterate on the SKILL.md

---

## Area 1: Triggering Tests

**Goal**: Verify the skill loads at the right times -- and doesn't load when it shouldn't.

### Should Trigger (5 tests)

These queries should activate the pr-description skill. Look for output that follows the PR template format (title, summary, changes, testing sections).

| # | Query | Expected | Actual | Pass? |
|---|-------|----------|--------|-------|
| T1 | "Write a PR description for my changes" | Skill triggers, reads git diff, produces template-formatted output | | |
| T2 | "Generate a pull request description" | Skill triggers, produces PR description | | |
| T3 | "Describe my changes for a pull request" | Skill triggers, paraphrased version still matches | | |
| T4 | "Help me write a PR" | Skill triggers on abbreviated "PR" | | |
| T5 | "Summarize my changes for a PR" | Skill triggers on "summarize...PR" | | |

### Should NOT Trigger (5 tests)

These queries should NOT activate the pr-description skill. Look for generic Claude responses without the PR template format.

| # | Query | Expected | Actual | Pass? |
|---|-------|----------|--------|-------|
| T6 | "Write a Python function that sorts a list" | No skill trigger, Claude writes code normally | | |
| T7 | "Review this code for bugs" | Should trigger code-review-checklist (Course 2), NOT pr-description | | |
| T8 | "Help me resolve this merge conflict" | No skill trigger, Claude helps with merge normally | | |
| T9 | "Summarize this README file" | No skill trigger, "summarize" alone isn't enough -- needs PR context | | |
| T10 | "What's in my git history?" | No skill trigger, asking about history is not asking for a PR description | | |

### Boundary Cases (2 tests)

These are edge cases where triggering behavior could reasonably go either way. Document the behavior and decide if it's acceptable.

| # | Query | Expected | Actual | Pass? |
|---|-------|----------|--------|-------|
| T11 | "Describe my changes" | Might trigger -- "describe my changes" without "PR" context. Acceptable either way, but document the behavior. | | |
| T12 | "What should I put in the PR?" | Might trigger -- indirect request for PR description content. Acceptable either way. | | |

---

## Area 2: Functional Tests

**Goal**: Verify the skill produces correct, complete output when it triggers.

**Setup**: You need a git repository with known changes. Create one:

```bash
mkdir -p /tmp/pr-test && cd /tmp/pr-test && git init
echo 'def greet(name):\n    return f"Hello, {name}"' > app.py
echo '# My App\nA simple greeting app.' > README.md
git add . && git commit -m "Initial commit"
```

### Single-File Change

| # | Setup | Query | Expected | Actual | Pass? |
|---|-------|-------|----------|--------|-------|
| F1 | Modify `app.py`: add input validation (`if not name: raise ValueError`) then `git add .` | "Write a PR description" | Output mentions app.py, describes the validation addition, title starts with a verb, follows template format | | |

### Multi-File Change

| # | Setup | Query | Expected | Actual | Pass? |
|---|-------|-------|----------|--------|-------|
| F2 | Modify both `app.py` (add new function) and `README.md` (update docs), then `git add .` | "PR description for my staged changes" | Output mentions BOTH files, groups changes logically, doesn't miss any files | | |

### Template Compliance

| # | Setup | Query | Expected | Actual | Pass? |
|---|-------|-------|----------|--------|-------|
| F3 | Any staged changes | "Write a PR description" | Output includes ALL template sections: Title, Summary, Changes, Testing. Each section has real content, not placeholders. | | |

### Branch Name Extraction

| # | Setup | Query | Expected | Actual | Pass? |
|---|-------|-------|----------|--------|-------|
| F4 | `git checkout -b feat/PROJ-42-add-validation`, stage some changes | "Generate a PR description" | Title includes "PROJ-42" ticket reference extracted from the branch name | | |

---

## Area 3: Edge Cases and Error Handling

**Goal**: Verify the skill handles unusual inputs gracefully without crashing or producing nonsense.

| # | Setup | Query | Expected | Actual | Pass? |
|---|-------|-------|----------|--------|-------|
| E1 | Clean repo, no changes (`git status` shows nothing to commit) | "Write a PR description" | Skill tells user there are no changes to describe. Does NOT produce an empty template. | | |
| E2 | Run from a non-git directory (e.g., `/tmp/not-a-repo/`) | "Write a PR description" | Skill reports "not a git repository" and suggests navigating to a project directory | | |
| E3 | Stage a change that only adds a binary file (e.g., an image) | "Write a PR description" | Skill notes the binary file by name, doesn't try to show binary diff content | | |
| E4 | Stage a very small change (single character fix, like a typo) | "Write a PR description" | Produces a proportional description -- doesn't over-explain a typo fix | | |

---

## Performance Comparison

Run this test WITH and WITHOUT the skill to measure improvement.

**Setup**: In a repo with 3-5 meaningful file changes staged.

### Without the skill

```bash
mv ~/.claude/skills/pr-description ~/.claude/skills/_pr-description-disabled
```

Ask Claude: "Write a PR description for my changes."

| Metric | Measurement |
|---|---|
| Messages until usable PR description | |
| Did Claude read the git diff without prompting? | |
| Did the output follow a consistent template? | |
| Did Claude include testing instructions? | |
| Manual edits needed before using the description? | |

### With the skill

```bash
mv ~/.claude/skills/_pr-description-disabled ~/.claude/skills/pr-description
```

Ask Claude the same question: "Write a PR description for my changes."

| Metric | Measurement |
|---|---|
| Messages until usable PR description | |
| Did Claude read the git diff without prompting? | |
| Did the output follow a consistent template? | |
| Did Claude include testing instructions? | |
| Manual edits needed before using the description? | |

### Comparison Summary

| Metric | Without Skill | With Skill | Improved? |
|---|---|---|---|
| Message count | | | |
| Reads diff automatically | | | |
| Consistent template | | | |
| Includes testing section | | | |
| Manual edits needed | | | |

---

## Iteration Log

After running all tests, document your iteration rounds here.

### Round 1

**Date**: ___

**Failures found**:
- [ ] T__: [describe what went wrong]
- [ ] F__: [describe what went wrong]

**Changes made**:
- [What you changed in SKILL.md and why]

**Re-test results**:
- [Which tests now pass? Did any new tests break?]

### Round 2

**Date**: ___

**Failures found**:
- [ ] T__: [describe what went wrong]
- [ ] F__: [describe what went wrong]

**Changes made**:
- [What you changed in SKILL.md and why]

**Re-test results**:
- [Which tests now pass? Did any new tests break?]

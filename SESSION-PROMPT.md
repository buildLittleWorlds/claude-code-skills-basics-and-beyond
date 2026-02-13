# Session Prompt — Build a Course Page

Copy the prompt below into a new Claude Code session. Replace the bracketed placeholders with the appropriate values for the course you're building.

---

## Prompt

```
I'm building the companion website for the Claude Code Skills curriculum.

## Context files — read all of these first:

1. **Site plan** (architecture, content transformation rules, navigation):
   /Users/familyplate/work/learning-tools/skills/skills-basics-and-beyond/SITE-PLAN.md
   (If this doesn't exist, the full plan is in the conversation transcript at:
   /Users/familyplate/.claude/projects/-Users-familyplate-work-learning-tools-skills/c1c7e485-9f55-4be6-95b7-f597f84e2c6a.jsonl
   — search for "Plan: Claude Code Skills — GitHub Pages Companion Site")

2. **Source lesson** (the content to transform):
   /Users/familyplate/work/learning-tools/skills/courses/[COURSE-DIRECTORY]/lesson.md

3. **Styling reference** (CSS with all component classes):
   /Users/familyplate/work/learning-tools/skills/skills-basics-and-beyond/style.css

4. **Template** (HTML structure with placeholders and transformation table):
   /Users/familyplate/work/learning-tools/skills/skills-basics-and-beyond/_template.html

5. **Gems reference site** (for visual/structural inspiration):
   /Users/familyplate/classes/ENGL17000/ENGL17000-spring-2026-course/gems-intellectual-map/index.html

## What to build

Create: `/Users/familyplate/work/learning-tools/skills/skills-basics-and-beyond/[FILENAME].html`

This is **[COURSE TITLE]** — course [N] of 12.

## Content transformation rules

Transform the lesson.md content into HTML using these mappings:

| lesson.md Section | HTML Component |
|---|---|
| `## Prerequisites` | `<div class="callout info">` with bulleted list |
| `## Concepts` / `### Sub-concept` | `<h2>` / `<h3>` + paragraphs, tables, code blocks |
| Code blocks (```yaml) | `.yaml-block` or `.skill-file` depending on context |
| Code blocks (```bash) | `.terminal-block` (commands) or `<pre>` (output) |
| Code blocks (```plain with tree structure) | `.file-tree` |
| Markdown tables | `<table class="tool-table">` |
| Blockquotes | `<blockquote>` with `<cite>` |
| `## Key References` | `<div class="callout insight">` |
| `## What You're Building` | Paragraph + info callout |
| `## Walkthrough` / `### Step N` | `.step-card` with `.step-number` + `.step-content` |
| Walkthrough bash commands | `.terminal-block` inside step cards |
| `## Exercises` | Numbered `<ol>` |
| `## Verification Checklist` | `<ul class="checklist">` |
| `## What's Next` | `<div class="callout success">` with link to next course |

## Navigation

- **Prev**: [PREV-FILENAME].html — "[PREV TITLE]"
- **Next**: [NEXT-FILENAME].html — "[NEXT TITLE]"
- **Bottom nav**: Use the phase-grouped nav from `_template.html`, mark this course as `current`

## Quality standards

- Valid HTML5 (no unclosed tags)
- All internal links use correct filenames
- Copy buttons work on terminal-block, yaml-block, skill-file pre, prompt-box-dark
- Responsive at 600px breakpoint
- EB Garamond + JetBrains Mono fonts loaded
- Script tag for copy-code.js at bottom of body
- Course metadata bar shows correct course number, level, and time
```

---

## Session lookup table

| Session | Course Directory | Filename | N | Title | Level | Time | Prev | Next |
|---|---|---|---|---|---|---|---|---|
| 2 | — | `index.html` | — | Curriculum Overview | — | — | — | `course-01-first-skill` |
| 3 | `course-01-first-skill` | `course-01-first-skill.html` | 1 | Your First Skill | Beginner | 20 min | `index` | `course-02-descriptions-and-triggers` |
| 4 | `course-02-descriptions-and-triggers` | `course-02-descriptions-and-triggers.html` | 2 | Descriptions and Triggers | Beginner | 25 min | `course-01-first-skill` | `course-03-full-anatomy` |
| 5 | `course-03-full-anatomy` | `course-03-full-anatomy.html` | 3 | Full Skill Anatomy | Beginner | 30 min | `course-02-descriptions-and-triggers` | `course-04-testing-iteration` |
| 6 | `course-04-testing-iteration` | `course-04-testing-iteration.html` | 4 | Testing and Iteration | Intermediate | 35 min | `course-03-full-anatomy` | `course-05-advanced-features` |
| 7 | `course-05-advanced-features` | `course-05-advanced-features.html` | 5 | Advanced Features | Intermediate | 40 min | `course-04-testing-iteration` | `course-06-multi-step-workflows` |
| 8 | `course-06-multi-step-workflows` | `course-06-multi-step-workflows.html` | 6 | Multi-Step Workflows | Intermediate | 35 min | `course-05-advanced-features` | `course-07-hooks` |
| 9 | `course-07-hooks` | `course-07-hooks.html` | 7 | Hooks | Intermediate | 45 min | `course-06-multi-step-workflows` | `course-07h-terminal-workspace` |
| 10 | `course-07h-terminal-workspace` | `course-07h-terminal-workspace.html` | 7&frac12; | Terminal Workspace | Intermediate | 20 min | `course-07-hooks` | `course-08-custom-subagents` |
| 11 | `course-08-custom-subagents` | `course-08-custom-subagents.html` | 8 | Custom Subagents | Advanced | 40 min | `course-07h-terminal-workspace` | `course-09-skills-cli-integration` |
| 12 | `course-09-skills-cli-integration` | `course-09-skills-cli-integration.html` | 9 | CLI Integration | Advanced | 40 min | `course-08-custom-subagents` | `course-10-agent-teams` |
| 13 | `course-10-agent-teams` | `course-10-agent-teams.html` | 10 | Agent Teams | Advanced | 50 min | `course-09-skills-cli-integration` | `course-11-capstone` |
| 14 | `course-11-capstone` | `course-11-capstone.html` | 11 | Capstone | Advanced | 60 min | `course-10-agent-teams` | — |

---

## Special notes

- **Session 2 (index.html)**: The landing page doesn't follow the standard course template. Instead, build it as a curriculum overview with card grids for each phase, a "Getting Started" section, and a "How It Works" section. Use the gems `index.html` as a structural reference.

- **Session 9 (course-07-hooks)**: This is the longest lesson (685 lines). Pay attention to long-page readability — use dividers between major sections and ensure the table of contents (if any) is clear.

- **Session 10 (course-07h-terminal-workspace)**: Short bridge course. The content is lighter — focus on the verification exercises being clear and the tmux quick-reference being easy to scan.

- **Session 14 (course-11-capstone)**: No "Next" link in page-nav — use `<span></span>` as a placeholder for the empty prev/next slot.

- **Session 2 (index.html)**: No "Prev" link — use `<span></span>` as a placeholder.

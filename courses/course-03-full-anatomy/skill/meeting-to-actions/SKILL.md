---
name: meeting-to-actions
description: Extracts structured action items from meeting notes, validates each item has an owner and deadline, and classifies by urgency. Use when the user says "extract action items", "meeting notes", "action items from this meeting", "what did we agree to do", or pastes meeting minutes. Handles extraction, validation, prioritization, and formatted output.
compatibility: Requires Python 3.6+ for the validation script.
metadata:
  author: skills-curriculum
  version: 1.0.0
  category: productivity
---

# Meeting to Actions

Extract, validate, and classify action items from meeting notes.

## Workflow

Follow these four steps in order. Do not skip the validation step.

### Step 1: Extract Action Items

Read the meeting notes provided by the user and identify every action item. An action item is any commitment, task, or follow-up where someone agreed to do something.

For each action item, extract:
- **action**: What needs to be done (specific and concise)
- **owner**: Who is responsible (use the name from the meeting notes)
- **deadline**: When it's due (convert relative dates like "next Friday" to YYYY-MM-DD format using today's date as reference)

Look for signals like:
- Direct assignments: "Mike will...", "Sarah is going to..."
- Volunteering: "I'll take care of...", "I can handle..."
- Group decisions: "We agreed to...", "The team decided..."
- Implicit tasks: "We need to..." followed by discussion of who

If an action item has no clear owner, set owner to "UNASSIGNED".
If an action item has no clear deadline, set deadline to "TBD".

Compile the extracted items as a JSON array:

```json
[
  {
    "action": "Migrate user service to new API",
    "owner": "Mike",
    "deadline": "2025-02-21"
  }
]
```

### Step 2: Validate Action Items

Run the validation script to check that every action item has the required fields:

```bash
echo '<JSON_ARRAY>' | python ~/.claude/skills/meeting-to-actions/scripts/validate_actions.py
```

Replace `<JSON_ARRAY>` with the actual JSON from Step 1.

**Interpreting results:**

- **Exit code 0**: All items are valid. Proceed to Step 3.
- **Exit code 1**: Issues found. The script outputs a JSON report listing each problem.

**If validation fails:**
1. Review the script's output to see which items have issues
2. Present the issues to the user: "I found these action items need clarification:"
3. List each issue with the specific problem (missing owner, missing deadline, invalid date format)
4. Ask the user to provide the missing information, OR suggest reasonable defaults based on meeting context
5. After fixing, re-run validation to confirm all items pass

### Step 3: Classify by Urgency

Consult `references/prioritization-guide.md` for the Eisenhower matrix classification criteria.

Classify each validated action item into one of four categories:
- **P1 - Urgent + Important**: Must be done immediately, has business impact
- **P2 - Important, Not Urgent**: Important work with flexible timing
- **P3 - Urgent, Not Important**: Time-sensitive but lower impact
- **P4 - Neither**: Can be deferred or delegated

Apply the classification rules from the reference guide. Consider:
- Deadline proximity (items due within 3 days are more likely urgent)
- Keywords suggesting importance (release, customer, blocker, critical)
- Dependencies (items that block other work get higher priority)

### Step 4: Format Output

Use the template in `assets/action-template.md` to format the final output.

Fill in all sections of the template:
- Meeting metadata (title, date, attendees)
- Action items grouped by priority level (P1 first, then P2, P3, P4)
- Each item showing owner, action, deadline
- Summary statistics at the bottom

If any items had validation issues that were resolved with assumptions, note these in the "Notes" section of the output.

## Troubleshooting

### Script not found
If you get "No such file or directory" when running the validation script:
1. Check the script exists: `ls ~/.claude/skills/meeting-to-actions/scripts/validate_actions.py`
2. Check it's executable: `chmod +x ~/.claude/skills/meeting-to-actions/scripts/validate_actions.py`
3. Check Python is available: `python3 --version`

### Invalid JSON from extraction
If the validation script reports JSON parsing errors:
1. Ensure the JSON array is properly formatted with double quotes (not single quotes)
2. Check that special characters in action descriptions are escaped
3. Verify the JSON is passed as a single string, not split across lines

### No action items found
If the meeting notes don't contain any action items:
1. Inform the user that no explicit action items were identified
2. Suggest potential action items based on discussion topics mentioned
3. Ask the user if they'd like to create action items for the discussed topics

## Performance Notes

- Quality is more important than speed for this workflow
- Do not skip the validation step, even if the items look correct
- When in doubt about an owner or deadline, flag it rather than guess

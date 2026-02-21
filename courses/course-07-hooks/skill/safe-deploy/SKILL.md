---
name: safe-deploy
description: Safely deploy an application with guardrails. Use when the user says "deploy", "ship it", "push to production", or "release to staging". Validates all commands against a safety checklist before execution.
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-deploy-command.sh"
---

# Safe Deploy

Deploy the application with built-in safety checks. Every Bash command is validated
against a list of dangerous patterns before execution.

## Steps

1. **Confirm the deployment target** -- Ask the user which environment to deploy to
   (staging, production, etc.). Never assume production.

2. **Run pre-deployment checks**:
   - Verify the working directory is clean: `git status --porcelain`
   - Confirm you're on the expected branch: `git branch --show-current`
   - Run the test suite: `npm test` (or the project's equivalent)
   - Check for uncommitted migrations or config changes

3. **Execute the deployment** -- Run the project's deployment command.
   Common patterns:
   - `npm run deploy -- --env staging`
   - `git push origin main` (for Heroku-style deploys)
   - `fly deploy` / `railway up` / `vercel --prod`

4. **Verify the deployment**:
   - Check the deployment URL or health endpoint
   - Review deployment logs for errors
   - Confirm the expected version is running

5. **Report results** -- Summarize what was deployed, to which environment,
   and any issues encountered.

## Safety Rules

The embedded `PreToolUse` hook on Bash commands validates every command against these rules:
- **No force pushes**: `git push --force` and `git push -f` are blocked
- **No direct production database access**: Commands containing `production` + `DROP`/`DELETE FROM`/`TRUNCATE` are blocked
- **No deleting deployment infrastructure**: `rm -rf` on deployment directories is blocked
- **No skipping CI**: `--no-verify` flags are blocked

If a command is blocked, you'll receive feedback explaining why. Adjust the command
to comply with the safety rules and try again.

## Troubleshooting

- **"Command blocked by deploy safety hook"**: Read the specific reason in the error message. The hook blocks commands that match dangerous patterns. Rephrase the command to avoid the pattern.
- **Tests failing before deploy**: Fix the failing tests first. Never skip the test step.
- **Wrong branch**: Switch to the correct branch before deploying. The skill checks but does not auto-switch.

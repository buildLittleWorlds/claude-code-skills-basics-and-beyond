# Domain Routing Rules

Rules for classifying tasks into `domain: work` or `domain: personal`.

## Work Domain Indicators

A task is `domain: work` if it involves any of:
- Code, programming, development, debugging, deployment
- Team members mentioned by name (colleagues, manager, reports)
- Company tools (Jira, Slack, GitHub, CI/CD, wiki)
- Meetings, reviews, standups, retros
- Documentation for a team or project
- Infrastructure, servers, databases, APIs
- Customer or client requests
- Reporting to leadership or stakeholders

## Personal Domain Indicators

A task is `domain: personal` if it involves any of:
- Health, medical, dental appointments
- Home maintenance, repairs, errands
- Personal finance (taxes, bills, insurance)
- Travel planning (non-work conferences count as personal logistics)
- Family, friends, social events
- Hobbies, exercise, outdoor activities
- Shopping, groceries, household items

## Ambiguous Cases

Some tasks straddle both domains. Use these tiebreakers:
- **Conference travel**: Personal if it's logistics (flights, hotel). Work if it's preparing a talk.
- **Learning/training**: Work if employer-required or directly job-related. Personal if self-directed.
- **Hardware/equipment**: Work if company-provided. Personal if you're buying it yourself.

When genuinely ambiguous, default to `work` — it's better to over-track work tasks than to miss them.

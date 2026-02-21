# Release Notes Template

Use this template for the output format.

---

## [VERSION] - DATE

SUMMARY_LINE

### Added
- FEATURE_ENTRY (#PR_NUMBER)

### Changed
- BREAKING: BREAKING_ENTRY (#PR_NUMBER)
- CHANGE_ENTRY (#PR_NUMBER)

### Fixed
- FIX_ENTRY (#PR_NUMBER)

### Security
- SECURITY_ENTRY (#PR_NUMBER)

---

## Placeholder Instructions

- **VERSION**: The new version tag (e.g., `v1.2.0`). If not specified by the user, suggest one based on the changes (patch for fixes only, minor for features, major for breaking changes).
- **DATE**: Today's date in `YYYY-MM-DD` format.
- **SUMMARY_LINE**: A single sentence summarizing the release theme. Example: "This release adds dark mode and fixes several auth-related bugs."
- **FEATURE_ENTRY**: Past-tense description of what was added. Example: "Added dark mode toggle to settings page"
- **BREAKING_ENTRY**: Past-tense description prefixed with `BREAKING:`. Example: "BREAKING: Renamed `/api/users` to `/api/v2/users`"
- **CHANGE_ENTRY**: Past-tense description of what changed. Example: "Updated rate limiting from 100 to 50 requests per minute"
- **FIX_ENTRY**: Past-tense description of what was fixed. Example: "Fixed crash when uploading files over 10MB"
- **SECURITY_ENTRY**: Past-tense description of what was patched. Example: "Patched XSS vulnerability in comment rendering"
- **PR_NUMBER**: The pull request number. Always include for traceability.

Only include sections that have entries. Omit empty sections entirely.

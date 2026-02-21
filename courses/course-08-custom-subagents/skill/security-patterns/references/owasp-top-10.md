# OWASP Top 10 Quick Reference

## A01: Broken Access Control
- Violation of least privilege or deny-by-default
- Bypassing access checks by modifying URLs, API requests, or internal state
- Accessing another user's records by providing their identifier (IDOR)
- Missing access control for POST, PUT, DELETE
- **Check for**: Authorization middleware on every route, ownership validation on data access

## A02: Cryptographic Failures
- Data transmitted in clear text (HTTP, SMTP, FTP)
- Use of old or weak cryptographic algorithms (MD5, SHA1, DES)
- Default or missing encryption keys
- **Check for**: TLS everywhere, strong hashing (bcrypt, argon2), proper key management

## A03: Injection
- User-supplied data not validated, filtered, or sanitized
- Dynamic queries without parameterization
- Hostile data used in ORM search parameters
- **Check for**: Parameterized queries, input validation, ORM safe methods

## A04: Insecure Design
- Missing threat modeling
- No rate limiting on high-value transactions
- Missing input validation at the business logic level
- **Check for**: Design-level security controls, abuse case testing

## A05: Security Misconfiguration
- Missing security hardening across the application stack
- Unnecessary features enabled (ports, services, pages, accounts)
- Default accounts and passwords unchanged
- Error handling reveals stack traces or sensitive information
- **Check for**: Hardened defaults, minimal attack surface, no stack traces in production

## A06: Vulnerable and Outdated Components
- Dependencies with known CVEs
- Unmaintained libraries
- **Check for**: `npm audit`, `pip-audit`, dependabot alerts, lock file freshness

## A07: Identification and Authentication Failures
- Permits brute force or credential stuffing
- Uses default, weak, or well-known passwords
- Missing or ineffective multi-factor authentication
- **Check for**: Rate limiting on auth endpoints, strong password policies, MFA support

## A08: Software and Data Integrity Failures
- Dependencies from untrusted sources without integrity verification
- CI/CD pipelines without integrity checks
- Auto-update without signature verification
- **Check for**: Lock files with integrity hashes, signed releases, CI/CD access controls

## A09: Security Logging and Monitoring Failures
- Auditable events not logged (logins, failed logins, high-value transactions)
- Logs not monitored for suspicious activity
- Logs only stored locally
- **Check for**: Centralized logging, alerting on auth failures, audit trails

## A10: Server-Side Request Forgery (SSRF)
- Fetching remote resources without validating user-supplied URLs
- No allowlist for destination addresses
- **Check for**: URL validation, allowlists for external requests, blocking internal network access

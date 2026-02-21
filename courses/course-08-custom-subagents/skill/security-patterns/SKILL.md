---
name: security-patterns
description: Reference material for common security vulnerabilities and secure coding patterns. Use when reviewing code for security issues or implementing security-sensitive features.
---

# Security Patterns Reference

When reviewing code for security issues, check for the following categories.

## Injection Flaws
- **SQL Injection**: Look for string concatenation in SQL queries. Require parameterized queries or prepared statements.
- **Command Injection**: Look for user input passed to shell commands, `exec()`, `eval()`, or `system()` calls. Require input sanitization and allowlists.
- **XSS (Cross-Site Scripting)**: Look for unsanitized user input rendered in HTML. Require output encoding and Content Security Policy headers.

## Authentication and Session Management
- Hardcoded credentials, API keys, or secrets in source code
- Missing or weak password hashing (look for MD5, SHA1 without salt)
- Session tokens in URLs or logs
- Missing session expiration or rotation after login

## Sensitive Data Exposure
- Secrets in environment variables without `.env` in `.gitignore`
- API keys or tokens committed to version control
- Logging of sensitive data (passwords, tokens, PII)
- Missing encryption for data in transit (HTTP instead of HTTPS)

## Access Control
- Missing authorization checks on endpoints or functions
- Direct object references without ownership validation
- Privilege escalation through parameter manipulation
- Missing rate limiting on sensitive operations

## Security Misconfiguration
- Debug mode enabled in production
- Default credentials left unchanged
- Overly permissive CORS settings
- Missing security headers (HSTS, X-Frame-Options, CSP)

## Input Validation
- Missing or client-side-only validation
- Path traversal vulnerabilities (`../` in file paths)
- Unrestricted file upload (type, size, content)
- Integer overflow or type confusion

For detailed descriptions, see `references/owasp-top-10.md`.

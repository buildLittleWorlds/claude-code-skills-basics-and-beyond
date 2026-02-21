# Investigation Checklist

Use this checklist to guide a thorough investigation based on the issue type. Not every item applies to every issue -- use the relevant section.

## Bug Reports

### Reproduction Context
- [ ] Can you identify the exact code path described in the bug?
- [ ] Are there error messages? Search for them verbatim in the codebase with Grep
- [ ] Is the bug environment-specific (OS, browser, version)?
- [ ] Are there existing tests that should have caught this?

### Code Inspection
- [ ] Read the file(s) mentioned in the issue
- [ ] Check the function/method where the bug likely occurs
- [ ] Look for off-by-one errors, null/undefined handling, type mismatches
- [ ] Check recent git history for the affected files -- was something recently changed?
- [ ] Look for TODO or FIXME comments near the affected code

### Dependency Check
- [ ] Is this in code we own, or in a dependency?
- [ ] If a dependency, check the version in package.json / requirements.txt / go.mod
- [ ] Search for known issues with that dependency version

## Feature Requests

### Scope Assessment
- [ ] Does similar functionality already exist in the codebase?
- [ ] Which modules would need to change?
- [ ] Are there architectural patterns in the codebase that this should follow?
- [ ] Would this require new dependencies?

### Impact Analysis
- [ ] What existing code would be affected?
- [ ] Are there tests that would need updating?
- [ ] Does this touch any public APIs or interfaces?
- [ ] Could this break backward compatibility?

## Performance Issues

### Measurement
- [ ] Is there a specific operation or endpoint mentioned?
- [ ] Are there benchmarks or performance tests in the repo?
- [ ] Look for N+1 queries, unbounded loops, or missing pagination
- [ ] Check for missing indexes if database-related

### Common Causes
- [ ] Synchronous operations that should be async
- [ ] Missing caching for expensive computations
- [ ] Unnecessary data loading (fetching entire records when only IDs needed)
- [ ] Memory leaks (event listeners not cleaned up, growing caches)

## Security Issues

### Severity Assessment
- [ ] Does this expose user data?
- [ ] Does this allow unauthorized access?
- [ ] Is user input properly sanitized at the boundary?
- [ ] Are there hardcoded secrets or credentials?

### Common Patterns
- [ ] SQL injection: Check for string concatenation in queries
- [ ] XSS: Check for unescaped user input in HTML output
- [ ] Authentication bypass: Check middleware ordering
- [ ] Path traversal: Check file path construction from user input

## General Investigation Tactics

### Search Strategies
1. **Exact match**: Search for error messages, function names, or identifiers from the issue
2. **Broader search**: If exact match fails, search for related terms (e.g., if issue mentions "login fails", search for "login", "auth", "authenticate")
3. **File structure**: Use Glob to find relevant files by naming pattern (e.g., `**/*auth*`, `**/*login*`)
4. **Test files**: Check test files for the affected module -- test names often describe expected behavior

### When You're Stuck
- Read the README or CONTRIBUTING docs for project-specific guidance
- Check if there's a docs/ directory with architecture documentation
- Look at similar issues that were already resolved for patterns
- Note what you checked and what remains unclear -- incomplete information is still valuable

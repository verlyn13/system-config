---
description: Comprehensive pull request review
argument-hint: PR number or branch
---

# Autonomous PR Review

Review: $ARGUMENTS

## Review Checklist
1. **Code Quality**:
   - Readability and maintainability
   - Follows project conventions
   - No code smells or anti-patterns
   - Appropriate abstractions
   - Biome formatting applied (JS/TS)

2. **Functionality**:
   - Implements requirements correctly
   - Handles edge cases
   - Error handling is robust
   - No regressions

3. **Testing**:
   - Adequate test coverage
   - Tests are meaningful and not brittle
   - Tests follow project patterns
   - Edge cases covered

4. **Security** (use @security agent):
   - No SQL injection, XSS, CSRF vulnerabilities
   - Input validation
   - Authentication/authorization correct
   - Secrets not exposed (check for .env, keys)

5. **Performance**:
   - No obvious performance issues
   - Efficient algorithms and data structures
   - Database queries optimized
   - Appropriate caching

6. **Documentation**:
   - Code comments where needed
   - API docs updated
   - README updated if needed
   - Breaking changes documented
   - Proper frontmatter in markdown files

## Output Format
Provide structured feedback:
- **Summary**: High-level assessment
- **Critical Issues**: Must fix before merge
- **Suggestions**: Nice-to-have improvements
- **Praise**: Highlight good practices

Be constructive and specific.

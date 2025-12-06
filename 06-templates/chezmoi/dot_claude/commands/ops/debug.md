---
description: Systematic debugging workflow
argument-hint: issue description
---

# Autonomous Debugging

Debug: $ARGUMENTS

## Systematic Approach
1. **Reproduce**:
   - Create minimal reproduction
   - Write failing test if possible
   - Document steps to reproduce

2. **Isolate**:
   - Binary search (comment out code sections)
   - Check recent changes (`git log`, `git diff`)
   - Verify environment (`mise current`, env vars)
   - Check dependencies (outdated packages?)
   - Check container status (`orbstatus`, `dps`)

3. **Investigate**:
   - Add logging/console statements
   - Use debugger if available
   - Check error messages and stack traces
   - Search for similar issues (WebSearch)

4. **Hypothesize**:
   - Form theories about root cause
   - Test each hypothesis
   - Eliminate impossible causes

5. **Fix**:
   - Implement fix
   - Verify test now passes
   - Check for similar issues elsewhere
   - Add regression test
   - Apply Biome formatting (JS/TS)

6. **Document**:
   - Explain root cause in commit
   - Update documentation if needed
   - Share learnings if novel

## Common Issue Categories
- Logic errors
- Race conditions
- Memory leaks
- Off-by-one errors
- Null/undefined values
- Type mismatches
- Configuration issues
- Environment differences
- Container/Docker issues

Be methodical and thorough.

---
description: Safe incremental refactoring
argument-hint: target file or module
---

# Autonomous Refactoring

Refactor: $ARGUMENTS

## Safety-First Approach
1. **Pre-flight**:
   - Ensure test coverage exists
   - Run tests to establish baseline
   - Create git checkpoint

2. **Analysis**:
   - Identify code smells
   - Find duplication
   - Check complexity metrics
   - Note dependencies

3. **Planning**:
   - Break into small, safe steps
   - Define success criteria per step
   - Identify rollback points

4. **Execute** (incrementally):
   - Make one change at a time
   - Run tests after each change
   - Use `/rewind` if tests fail
   - Keep commits atomic
   - Apply Biome formatting (JS/TS)

5. **Validation**:
   - All tests pass
   - No behavioral changes
   - Performance maintained or improved
   - Code is more maintainable

## Refactoring Patterns
- Extract function/method
- Extract constant/variable
- Rename for clarity
- Eliminate duplication
- Simplify conditionals
- Replace magic numbers
- Improve type safety

Work autonomously but conservatively. Preserve functionality.

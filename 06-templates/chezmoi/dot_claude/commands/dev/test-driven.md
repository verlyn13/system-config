---
description: Test-driven development workflow
argument-hint: feature or function to implement
---

# Test-Driven Development

Implement: $ARGUMENTS

## TDD Cycle (Red-Green-Refactor)
1. **Red**: Write failing test
   - Test describes desired behavior
   - Run test to confirm it fails
   - Commit test

2. **Green**: Implement minimum code to pass
   - Write simplest solution
   - Run test to confirm it passes
   - Apply Biome formatting (JS/TS)
   - Commit implementation

3. **Refactor**: Improve code quality
   - Remove duplication
   - Improve names
   - Extract functions
   - Keep tests passing
   - Commit improvements

4. **Repeat**: Next test case

Execute each cycle completely before moving to next.

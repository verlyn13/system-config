---
description: Autonomous feature development workflow
argument-hint: feature description
---

# Autonomous Feature Development

Develop feature: $ARGUMENTS

## Workflow
1. **Analysis**: Review codebase structure, identify integration points
2. **Planning**: Create implementation plan with checkpoints
3. **Branch**: Create feature branch with conventional naming
4. **Implement**:
   - Write code following project patterns
   - Add comprehensive tests (unit, integration)
   - Update documentation
   - Add type safety where applicable
   - Use Biome for TypeScript/JavaScript formatting
5. **Quality**:
   - Run test suite
   - Check code coverage
   - Lint and format (auto-applied via hooks)
6. **Review**:
   - Use @reviewer agent for self-review
   - Check security implications with @security agent
7. **Commit**: Generate conventional commit message
8. **PR**: Create detailed pull request description

## Success Criteria
- All tests pass
- Code coverage maintained or improved
- Documentation updated (with proper frontmatter if applicable)
- No security vulnerabilities introduced
- Follows project conventions
- Biome formatting applied to all JS/TS files

Execute autonomously with minimal intervention. Use `/rewind` if issues arise.

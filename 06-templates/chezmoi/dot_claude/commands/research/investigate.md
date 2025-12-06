---
description: Deep technical investigation with research
argument-hint: topic or question
---

# Technical Investigation

Investigate: $ARGUMENTS

## Research Process
1. **Current Understanding**:
   - Review existing codebase knowledge
   - Check internal documentation
   - Identify knowledge gaps

2. **External Research** (use WebSearch):
   - Official documentation
   - Best practices articles
   - GitHub issues and discussions
   - Stack Overflow solutions
   - Recent blog posts and papers
   - npm/package registries for library info

3. **Analysis**:
   - Compare approaches
   - Evaluate trade-offs
   - Consider context and constraints
   - Check compatibility with stack (Node 24, Biome, etc.)

4. **Recommendation**:
   - Suggest best approach
   - Provide implementation guidance
   - List prerequisites and dependencies
   - Highlight potential issues

5. **Document**:
   - Create decision record
   - Save to `docs/` with proper frontmatter
   - Include references and citations

## Output Format
```markdown
---
title: Investigation [Topic]
category: research
component: investigation
status: draft
version: 1.0.0
last_updated: YYYY-MM-DD
tags: [research, investigation]
priority: medium
---

# Investigation: [Topic]

## Summary
[One-paragraph executive summary]

## Current State
[What we have now]

## Options Considered
### Option 1: [Name]
- Pros: ...
- Cons: ...
- Complexity: ...
- Compatibility: Node 24, Biome, etc.

### Option 2: [Name]
...

## Recommendation
[Detailed recommendation with reasoning]

## Implementation Steps
1. ...
2. ...

## References
- [Link to resource]
- [Link to documentation]
```

Execute thoroughly and autonomously.

# Warning Protocol

When identifying potential problems, use this format:

```markdown
**WARNING: [Problem Type]**

**Problem:** [Clear description]
**Impact:** [Consequences]
**Fix difficulty:** Trivial / Easy / Moderate / Difficult / Very Difficult

**Alternatives:**
1. [Option A] - Pros/Cons
2. [Option B] - Pros/Cons

**Recommendation:** [Your technical opinion]
```

## Problem Types to Flag
| Category | Examples |
|----------|----------|
| Architecture | SOLID violations, excessive coupling, tech debt |
| Performance | O(n²) loops, memory leaks, blocking main thread |
| Security | Vulnerabilities, missing validation |
| Maintainability | Duplicated code, missing tests, hardcoded values |
| Scalability | Non-scalable solutions, rigid limits |

## When Unsure
- **ASK** before implementing
- Propose options with pros/cons
- Don't guess if you can ask

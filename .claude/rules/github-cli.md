# GitHub CLI Guidelines

## Issue-First Development
**ALWAYS create issue BEFORE coding.** Flow:
1. Create Issue → 2. Create Branch → 3. Develop → 4. PR to development → 5. Close Issue

## Labels
| Category | Values |
|----------|--------|
| Priority | `priority:critical`, `priority:high`, `priority:medium`, `priority:low` |
| Difficulty | `difficulty:easy`, `difficulty:medium`, `difficulty:hard`, `difficulty:expert` |
| Component | `gdextension`, `editor`, `core`, `memory`, `tts`, `localization`, `csharp` |

## Commands
```bash
# Create branch linked to issue
gh issue develop <number> --base development --checkout

# Create PR (always to development!)
gh pr create --base development --title "Title" --body "Closes #XX"

# Close issue with dates
gh project item-edit --project-id PVT_kwHOAVGx6s4BLOYT --id <ITEM_ID> \
  --field-id PVTF_lAHOAVGx6s4BLOYTzg63ghM --date YYYY-MM-DD  # Start
gh project item-edit --project-id PVT_kwHOAVGx6s4BLOYT --id <ITEM_ID> \
  --field-id PVTF_lAHOAVGx6s4BLOYTzg63ghQ --date YYYY-MM-DD  # End
```

## Critical Rules
- NO coding without issue
- NO working directly on `development` or `main`
- NO closing issues without updating Start/End dates

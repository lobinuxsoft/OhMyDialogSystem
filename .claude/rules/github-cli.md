# GitHub CLI Guidelines

## Issue-First Development
**ALWAYS create issue BEFORE coding.**

Flow: `Create Issue → Create Branch → Develop → PR to development → Pre-close Check → Close Issue`

## Pre-Close Checklist
Before closing ANY issue:
1. **Check body for checkboxes/sub-issues** → Mark completed ones as `[x]`
2. **Verify sub-issues are closed** → Close them first if done
3. **Out-of-scope work?** → Add comment listing extra items implemented
4. **Update project dates** → Set Start/End fields

## Labels
| Category | Values |
|----------|--------|
| Priority | `priority:critical`, `priority:high`, `priority:medium`, `priority:low` |
| Difficulty | `difficulty:easy`, `difficulty:medium`, `difficulty:hard`, `difficulty:expert` |
| Component | `gdextension`, `editor`, `core`, `memory`, `tts`, `localization`, `csharp` |
| Session | `next-session` |

## Session Management
Use `next-session` label to mark issues for the next work session.

**At session START:**
```bash
gh issue list --label next-session
```

**At session END:**
- Remove `next-session` from completed issues
- Add `next-session` to issues queued for next session
```bash
gh issue edit <number> --remove-label next-session
gh issue edit <number> --add-label next-session
```

## Commands
```bash
# Branch from issue
gh issue develop <number> --base development --checkout

# PR (always to development!)
gh pr create --base development --title "Title" --body "Closes #XX"

# Update issue body (checkboxes)
gh issue edit <number> --body "updated markdown"

# Add out-of-scope comment
gh issue comment <number> --body "Additional work: ..."

# Project dates
gh project item-edit --project-id PVT_kwHOAVGx6s4BLOYT --id <ITEM_ID> \
  --field-id PVTF_lAHOAVGx6s4BLOYTzg63ghM --date YYYY-MM-DD  # Start
gh project item-edit --project-id PVT_kwHOAVGx6s4BLOYT --id <ITEM_ID> \
  --field-id PVTF_lAHOAVGx6s4BLOYTzg63ghQ --date YYYY-MM-DD  # End
```

## Critical Rules
- NO coding without issue
- NO working on `development` or `main` directly
- NO closing without pre-close checklist
- NO PRs to `main` (except MAJOR releases)

# GitHub CLI

## Rules
- **Issue-First:** Create Issue -> Project -> Branch -> PR -> Close.
- **Projects:** Add to `OhMyDialogSystem Development` (ID: 5).
- **Pre-Close:** Check sub-issues, update dates.

## Labels
- `priority:*`, `difficulty:*`, `component:*`
- `next-session`: Queue for next work session.

## Commands
```bash
# Add to Project (ID 5)
gh project item-add 5 --owner lobinuxsoft --url <ISSUE_URL>

# Branch & PR
gh issue develop <NUM> --base development --checkout
gh pr create --base development --title "Title" --body "Closes #XX"

# Session Mgmt
gh issue list --label next-session
gh issue edit <NUM> --add-label next-session
gh issue edit <NUM> --remove-label next-session

# Dates
gh project item-edit --id <ID> --field-id <START/END_ID> --date YYYY-MM-DD
```

## Critical
- NO direct `development`/`main` work.
- NO PRs to `main` (except MAJOR).

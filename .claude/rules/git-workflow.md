# Git Workflow

## Commits
| Rule | Value |
|------|-------|
| Language | Spanish |
| Format | Conventional Commits (feat:, fix:, docs:, refactor:) |
| Signatures | **NEVER** include Claude signatures or Co-Authored-By |

## Branching Strategy
```
main (production - stable releases only)
└── development (integration)
     └── feature/issue-XX-description
     └── fix/issue-XX-description
     └── docs/issue-XX-description
```

## Semantic Versioning
| Type | When | Merge to main? |
|------|------|----------------|
| MAJOR (X.0.0) | Breaking changes, major features | YES + tag |
| MINOR (0.X.0) | New backwards-compatible features | NO |
| PATCH (0.0.X) | Bug fixes | NO |

**Critical:** Only merge to `main` for MAJOR version increments with tag `vX.0.0`

## Release Workflow
```bash
# 1. PR from development -> main
gh pr create --base main --head development --title "Release vX.0.0"
# 2. Merge
gh pr merge <number> --merge
# 3. Tag
git tag -a vX.0.0 origin/main -m "Release vX.0.0: [description]"
git push origin vX.0.0
```

## Safety
- NEVER force push to main/master
- NEVER skip hooks (--no-verify)
- ALWAYS verify before amend

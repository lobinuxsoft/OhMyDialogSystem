# Git Workflow

## Commits
- **Lang:** Spanish.
- **Fmt:** Conventional (`feat:`, `fix:`, `docs:`).
- **Sig:** NO Claude signatures.

## Branches
`main` (releases) ← `development` (integration) ← `feat/issue-ID`

## Versioning (SemVer)
- **MAJOR (X.0.0):** Breaks. Merge to `main` + Tag.
- **MINOR (0.X.0):** Features.
- **PATCH (0.0.X):** Fixes.

## Release
1. PR `development` -> `main`.
2. Merge.
3. Tag `vX.0.0` & Push.

## Safety
- NO Force Push `main`.
- NO `--no-verify`.
- Verify before amend.

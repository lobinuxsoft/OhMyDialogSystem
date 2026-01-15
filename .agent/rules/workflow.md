# Workflow

## Git & SemVer
- **Commits:** Spanish, Conventional (`feat:`, `fix:`, `docs:`). NO signatures.
- **Branches:** `main` (rel) ← `development` (int) ← `feat/issue-ID`.
- **SemVer:** MAJOR (Breaks, Tag `vX.0.0`), MINOR (Feat), PATCH (Fix).
- **Process:** PR `dev` -> `main`, Tag, Push. NO Force Push.

## GitHub CLI & Project
- **Flow:** Issue -> Project (ID 5: `OhMyDialogSystem Development`) -> Branch -> PR -> Close.
- **Labels:** `priority:*`, `difficulty:*`, `next-session`.
- **Ops:**
  - `gh issue develop <NUM> --base development --checkout`
  - `gh pr create --base development --title "Title" --body "Closes #XX"`
  - `gh issue edit <NUM> --add-label next-session`

## Build
- **Policy:** ALWAYS use scripts (`build.sh` / `build.bat`). NEVER manual `scons`/`cmake`.
- **Scripts:** Must check deps, platform, targets. Missing? Create it.

# Build Workflow
**ALWAYS use build scripts. NEVER run tools manually.**

## Process
1. Find `build.sh` / `build.bat`.
2. Run it.
3. Missing? Create it.

## Scripts
- **Linux (`build.sh`):** Check deps, platform, targets, usage.
- **Windows (`build.bat`):** Same.

## Why
Reproducibility. Documentation. No "works on my machine".

## Anti-Patterns
- Manual `scons`/`cmake`/`msbuild`.
- Assuming config.
- Hardcoded paths.

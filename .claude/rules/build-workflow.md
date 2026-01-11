# Build Workflow

## Golden Rule
**ALWAYS use build scripts. NEVER run build tools directly.**

## Build Process
1. **First:** Look for `build.sh` (Linux/macOS) or `build.bat` (Windows)
2. **If exists:** Use it with appropriate arguments
3. **If not exists:** Create the build script before proceeding

## Script Requirements
When creating build scripts:

### build.sh (Linux/macOS)
```bash
#!/bin/bash
set -e
# Must include:
# - Dependency checks (compilers, tools)
# - Platform detection
# - Configurable targets (debug, release, editor)
# - Parallel jobs support (-j flag)
# - Clear usage/help output
```

### build.bat (Windows)
```batch
@echo off
:: Must include:
:: - Dependency checks
:: - Configurable targets
:: - Clear usage output
```

## Why This Matters
- Reproducible builds across environments
- Documents build requirements and options
- Prevents "works on my machine" issues
- Easier onboarding for new contributors

## Anti-Patterns (DO NOT)
- Run `scons`, `cmake`, `msbuild` directly
- Assume build configuration from memory
- Skip dependency checks
- Hardcode paths or settings

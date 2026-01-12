# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.3.x (dev) | Yes |
| < 0.3 | No |

As an early-stage project, only the latest development version receives updates.

## Reporting a Concern

If you discover a potential security issue, please report it responsibly:

1. **Do NOT** open a public issue
2. **Do** contact the maintainer privately via [GitHub Discussions](https://github.com/lobinuxsoft/OhMyDialogSystem/discussions) (private message) or email
3. Include as much detail as possible to help reproduce and understand the issue

## Response Timeline

- **Acknowledgment**: Within 72 hours
- **Initial assessment**: Within 1 week
- **Resolution timeline**: Depends on complexity, communicated after assessment

## Scope

This policy applies to:
- The OhMyDialogSystem addon code
- GDExtension native binaries
- Official documentation

**Out of scope**:
- Third-party dependencies (llama.cpp, godot-cpp) - report to their respective projects
- User-provided LLM models
- Game implementations using this addon

## Recognition

Contributors who responsibly report valid issues will be credited in release notes (unless they prefer anonymity).

## Important Note

This is a game development tool that runs local LLM inference. It does not handle sensitive user data, authentication, or network services by default. The primary concern is ensuring the native code (GDExtension) is stable and does not introduce issues into host applications.

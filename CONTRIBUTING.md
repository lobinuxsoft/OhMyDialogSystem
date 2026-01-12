# Contributing to OhMyDialogSystem

Thank you for your interest in contributing! This document outlines our development workflow and standards.

## Quick Reference

| Item | Value |
|------|-------|
| PRs target | `development` branch (NEVER `main`) |
| Commit language | Spanish |
| Commit format | [Conventional Commits](https://www.conventionalcommits.org/) |
| Code comments | English |

## Issue-First Development

**Always create an issue before coding.**

```
Create Issue → Create Branch → Develop → PR to development → Close Issue
```

This ensures work is tracked, discussed, and properly scoped before implementation begins.

## Branch Naming

Create branches from issues using this pattern:

```
feature/issue-XX-short-description
fix/issue-XX-short-description
docs/issue-XX-short-description
refactor/issue-XX-short-description
```

Example: `feature/issue-42-add-memory-search`

## Commit Messages

Write commits in **Spanish** using Conventional Commits format:

```
feat: agregar búsqueda semántica de memorias
fix: corregir leak de memoria en LlamaInterface
docs: actualizar guía de instalación
refactor: simplificar GraphRunner
test: agregar tests para DialogueManager
chore: actualizar dependencias de godot-cpp
```

### Types

| Type | Use for |
|------|---------|
| `feat` | New features |
| `fix` | Bug fixes |
| `docs` | Documentation only |
| `refactor` | Code changes that neither fix bugs nor add features |
| `test` | Adding or updating tests |
| `chore` | Maintenance tasks |

## Pull Requests

1. **Target branch**: Always `development` (never `main`)
2. **Title**: Clear description of the change
3. **Body**: Reference the issue with `Closes #XX`
4. **Size**: Keep PRs focused and reviewable

```bash
# Example PR creation
gh pr create --base development --title "feat: add semantic memory search" --body "Closes #42"
```

## Code Standards

### Naming Conventions

| Language | Classes | Functions/Variables | Private Members |
|----------|---------|---------------------|-----------------|
| C++ | PascalCase | snake_case | m_prefix |
| GDScript | PascalCase | snake_case | _prefix |
| C# | PascalCase | camelCase | _camelCase |

### General Guidelines

- **Comments**: Write in English
- **Type hints**: Always use them (GDScript, C#)
- **Documentation**: Doxygen for C++, XML docs for C#
- Use signals over direct node references
- Prefer `[Export]` for editor configuration

## Building the Project

**Always use the build scripts. Never run build tools directly.**

```bash
# Linux/macOS
./build.sh

# Windows
build.bat
```

See [GDExtension Build Guide](https://lobinuxsoft.github.io/OhMyDialogSystem/Technical/gdextension.html) for details.

## Labels

When creating issues, use appropriate labels:

| Category | Labels |
|----------|--------|
| Priority | `priority:critical`, `priority:high`, `priority:medium`, `priority:low` |
| Difficulty | `difficulty:easy`, `difficulty:medium`, `difficulty:hard`, `difficulty:expert` |
| Component | `gdextension`, `editor`, `core`, `memory`, `tts`, `localization`, `csharp` |

## Getting Help

- **Questions**: Open a [Discussion](https://github.com/lobinuxsoft/OhMyDialogSystem/discussions)
- **Bugs**: Create an [Issue](https://github.com/lobinuxsoft/OhMyDialogSystem/issues)
- **Documentation**: Check the [Wiki](https://lobinuxsoft.github.io/OhMyDialogSystem/)

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.

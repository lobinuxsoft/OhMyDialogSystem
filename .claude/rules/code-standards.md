# Code Standards

## Naming Conventions
| Language | Classes | Functions/Vars | Private Members | Comments |
|----------|---------|----------------|-----------------|----------|
| C++ | PascalCase | snake_case | m_prefix | English |
| GDScript | PascalCase | snake_case | _prefix | English |
| C# | PascalCase | camelCase (local) | _camelCase | English |

## C++ (GDExtension)
- Doxygen for public APIs
- RAII for resource management
- Smart pointers when appropriate

## GDScript
- Type hints always
- Signals for node communication
- Avoid GetNode() in loops

## C#
- XML docs for public APIs
- async/await for async ops
- IDisposable for native resources

## Architecture (Godot)
- Signals over direct calls
- Singleton only when strictly necessary
- [Export] for editor configuration
- Resources for configurable data

## Editor vs Runtime Separation (CRITICAL)
**NEVER couple editor-only code with runtime code.**

| Code Type | Location | Runs in Export? |
|-----------|----------|-----------------|
| Runtime | `core/`, `ai/`, `resources/` | YES |
| Editor-only | `editor/` | NO |

### Rules
1. **Runtime code MUST NOT instantiate editor classes**
   - Bad: `ModelManager` creates `ModelDownloader`
   - Good: `ModelManagerWindow` creates `ModelDownloader`

2. **Editor classes should be in `editor/` directory**
   - Model download UI, visual graph editor, inspector plugins

3. **Use `@tool` only when necessary**
   - For resources that need editor preview
   - For inspector plugins
   - NOT for runtime logic

4. **Check context when mixing is unavoidable**
   ```gdscript
   if OS.has_feature("editor"):
       # Editor-only code
   ```

### Why This Matters
- Exported builds include ALL instantiated classes
- Editor code in runtime = bloat + errors in exports
- `res://` is read-only in exports (no file creation)

## Testing
- Unit tests for complex business logic
- Integration tests for critical systems
- **Flag when something needs tests but doesn't have them**

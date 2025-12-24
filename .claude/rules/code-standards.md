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

## Testing
- Unit tests for complex business logic
- Integration tests for critical systems
- **Flag when something needs tests but doesn't have them**

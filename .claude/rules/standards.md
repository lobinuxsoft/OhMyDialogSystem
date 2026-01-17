# Standards

## Naming
| Lang | Class | Func/Var | Priv |
|------|-------|----------|------|
| C++  | Pascal| snake    | m_   |
| GD   | Pascal| snake    | _    |
| C#   | Pascal| camel    | _camel|

## Patterns
- **Godot:** Singleton (AutoLoad), Observer (Signals), Strategy (Resources), Factory (`create()`).
- **CRITICAL:** `core/`, `ai/` MUST NOT init `editor/` classes. Use `OS.has_feature("editor")`.

## Tech
- **C++:** RAII, Smart Pointers, Doxygen.
- **GDScript:** Typed, Signals, No `GetNode` in loops.
- **C#:** XML Docs, async/await, `IDisposable`.
- **SOLID:** No God Classes, No Feature Envy.

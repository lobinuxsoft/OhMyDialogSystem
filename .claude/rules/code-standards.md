# Code Standards

## Naming
| Lang | Class | Func/Var | Priv |
|---|---|---|---|
| C++ | Pascal | snake | m_ |
| GD | Pascal | snake | _ |
| C# | Pascal | camel | _camel |

## Lang Specifics
- **C++:** RAII, Smart Pointers, Doxygen.
- **GDScript:** Typed, Signals, No `GetNode` in loops.
- **C#:** XML Docs, async/await, `IDisposable`.

## SOLID
Apply S.O.L.I.D. Avoid God Classes, Feature Envy, Shotgun Surgery.

## Patterns (Godot)
- **Singleton:** `Engine.register_singleton` / AutoLoad.
- **Observer:** Signals.
- **Strategy:** Resources.
- **Factory:** Static `create()`.

## Editor vs Runtime (CRITICAL)
**Separation mandatory.**
- `core/`, `ai/`: Runtime (Exported).
- `editor/`: Editor-only (NO Export).
- **Rule:** Runtime MUST NOT init Editor classes.
- **Safety:** Use `OS.has_feature("editor")` if mixed.

## Testing
Unit/Integration tests for complexity. Flag missing tests.

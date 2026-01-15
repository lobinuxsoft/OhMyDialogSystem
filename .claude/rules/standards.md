# Standards

## Naming & Patterns
| Lang | Class | Func/Var | Priv |
|---|---|---|---|
| C++ | Pascal | snake | m_ |
| GD | Pascal | snake | _ |
| C# | Pascal | camel | _camel |

- **Godot:** Singleton (AutoLoad), Observer (Signals), Strategy (Resources), Factory (`create()`).
- **CRITICAL:** `core/`, `ai/` (Runtime) MUST NOT init `editor/` (Editor-only) classes. Use `OS.has_feature("editor")` if mixed.

## Tech Specs
- **C++:** RAII, Smart Pointers, Doxygen.
- **GDScript:** Typed, Signals, No `GetNode` in loops.
- **C#:** XML Docs, async/await, `IDisposable`.
- **SOLID:** Apply S.O.L.I.D. Avoid God Classes, Feature Envy.

## Wiki & Visuals
- **UI:** HTML+CSS ONLY (No images/ASCII). Use `styles.css`. Inline allowed.
- **Colors:** Start/End (`#10b981`/`#ef4444`), AI/Static (`#3b82f6`/`#6b7280`), Choice/Cond (`#eab308`/`#f97316`), Event/Var (`#a855f7`/`#06b6d4`).
- **Lang:** Content (Spanish), Code (English).
